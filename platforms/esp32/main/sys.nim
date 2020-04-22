## **************************************************************************
##    Copyright 2017 by Davide Bettio <davide@uninstall.it>                 *
##                                                                          *
##    This program is free software; you can redistribute it and/or modify  *
##    it under the terms of the GNU Lesser General Public License as        *
##    published by the Free Software Foundation; either version 2 of the    *
##    License, or (at your option) any later version.                       *
##                                                                          *
##    This program is distributed in the hope that it will be useful,       *
##    but WITHOUT ANY WARRANTY; without even the implied warranty of        *
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
##    GNU General Public License for more details.                          *
##                                                                          *
##    You should have received a copy of the GNU General Public License     *
##    along with this program; if not, write to the                         *
##    Free Software Foundation, Inc.,                                       *
##    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
## *************************************************************************

import
  sys, esp32_sys, avmpack, i2cdriver, scheduler, globalcontext, gpio_driver, spidriver,
  network, uart_driver, defaultatoms, trace, freertos/FreeRTOS, esp_system, esp_event,
  esp_event_loop

const
  EVENT_QUEUE_LEN* = 16

var esp_free_heap_size_atom*: cstring = "\x14esp32_free_heap_size"

var esp_chip_info_atom*: cstring = "\x0Fesp32_chip_info"

var esp_idf_version_atom*: cstring = "\x0Fesp_idf_version"

var esp32_atom*: cstring = "\x05esp32"

var event_queue*: xQueueHandle = nil

proc esp32_sys_queue_init*() =
  event_queue = xQueueCreate(EVENT_QUEUE_LEN, sizeof(pointer))

proc sys_clock_gettime*(t: ptr timespec) {.inline, cdecl.} =
  var ticks: TickType_t = xTaskGetTickCount()
  t.tv_sec = (ticks * portTICK_PERIOD_MS) div 1000
  t.tv_nsec = ((ticks * portTICK_PERIOD_MS) mod 1000) * 1000000

proc receive_events*(glb: ptr GlobalContext; wait_ticks: TickType_t) =
  var platform: ptr ESP32PlatformData = glb.platform_data
  var sender: pointer = nil
  while xQueueReceive(event_queue, addr(sender), wait_ticks) == pdTRUE:
    if UNLIKELY(list_is_empty(addr(platform.listeners))):
      fprintf(stderr, "warning: no listeners.\n")
      return
    var listener_lh: ptr ListHead
    ##  TODO: FIXME
    listener_lh = (addr(platform.listeners)).next
    while listener_lh != (addr(platform.listeners)):
      var listener: ptr EventListener = GET_LIST_ENTRY(listener_lh, EventListener,
          listeners_list_head)
      if listener.sender == sender:
        TRACE("sys: handler found for: %p\n", cast[pointer](sender))
        listener.handler(listener)
        TRACE("sys: handler executed\n")
        return
      listener_lh = listener_lh.next
    TRACE("sys: handler not found for: %p\n", cast[pointer](sender))

proc sys_consume_pending_events*(glb: ptr GlobalContext) =
  receive_events(glb, 0)

proc sys_event_listener_init*(listener: ptr EventListener; sender: pointer;
                             handler: event_handler_t; data: pointer) =
  list_init(addr(listener.listeners_list_head))
  listener.sender = sender
  listener.handler = handler
  listener.data = data

proc sys_time*(t: ptr timespec) =
  var tv: timeval
  if UNLIKELY(gettimeofday(addr(tv), nil)):
    fprintf(stderr, "Failed gettimeofday.\n")
    abort()
  t.tv_sec = tv.tv_sec
  t.tv_nsec = tv.tv_usec * 1000

proc sys_init_platform*(glb: ptr GlobalContext) =
  var platform: ptr ESP32PlatformData = malloc(sizeof(ESP32PlatformData))
  list_init(addr(platform.listeners))
  glb.platform_data = platform

proc sys_start_millis_timer*() =
  discard

proc sys_stop_millis_timer*() =
  discard

proc sys_millis*(): uint32_t =
  var ticks: TickType_t = xTaskGetTickCount()
  return ticks * portTICK_PERIOD_MS

proc sys_load_module*(global: ptr GlobalContext; module_name: cstring): ptr Module {.
    cdecl.} =
  var beam_module: pointer = nil
  var beam_module_size: uint32_t = 0
  if not (global.avmpack_data and
      avmpack_find_section_by_name(global.avmpack_data, module_name,
                                   addr(beam_module), addr(beam_module_size))):
    fprintf(stderr, "Failed to open module: %s\n", module_name)
    return nil
  var new_module: ptr Module = module_new_from_iff_binary(global, beam_module,
      beam_module_size)
  new_module.module_platform_data = nil
  return new_module

##  TODO: FIXME
##  This function allows to use AtomVM as a component on ESP32 and customize it
##  __attribute__ ((weak)) Context *sys_create_port_fallback(Context *new_ctx, const char *driver_name, term opts)

proc sys_create_port_fallback*(new_ctx: ptr Context; driver_name: cstring; opts: term): ptr Context {.
    cdecl.} =
  UNUSED(driver_name)
  UNUSED(opts)
  context_destroy(new_ctx)
  return nil

proc sys_create_port*(glb: ptr GlobalContext; driver_name: cstring; opts: term): ptr Context {.
    cdecl.} =
  var new_ctx: ptr Context = context_new(glb)
  if not strcmp(driver_name, "socket"):
    socket_init(new_ctx, opts)
  elif not strcmp(driver_name, "network"):
    network_init(new_ctx, opts)
  elif not strcmp(driver_name, "gpio"):
    gpiodriver_init(new_ctx)
  elif not strcmp(driver_name, "spi"):
    spidriver_init(new_ctx, opts)
  elif not strcmp(driver_name, "i2c"):
    i2cdriver_init(new_ctx, opts)
  elif not strcmp(driver_name, "uart"):
    uart_driver_init(new_ctx, opts)
  else:
    return sys_create_port_fallback(new_ctx, driver_name, opts)
  return new_ctx

proc sys_get_info*(ctx: ptr Context; key: term): term =
  if key == context_make_atom(ctx, esp_free_heap_size_atom):
    return term_from_int32(esp_get_free_heap_size())
  if key == context_make_atom(ctx, esp_chip_info_atom):
    var info: esp_chip_info_t
    esp_chip_info(addr(info))
    if memory_ensure_free(ctx, 5) != MEMORY_GC_OK:
      return OUT_OF_MEMORY_ATOM
    var ret: term = term_alloc_tuple(4, ctx)
    term_put_tuple_element(ret, 0, context_make_atom(ctx, esp32_atom))
    term_put_tuple_element(ret, 1, term_from_int32(info.features))
    term_put_tuple_element(ret, 2, term_from_int32(info.cores))
    term_put_tuple_element(ret, 3, term_from_int32(info.revision))
    return ret
  if key == context_make_atom(ctx, esp_idf_version_atom):
    var str: cstring = esp_get_idf_version()
    var n: csize = strlen(str)
    if memory_ensure_free(ctx, 2 * n) != MEMORY_GC_OK:
      return OUT_OF_MEMORY_ATOM
    return term_from_string(cast[ptr uint8_t](str), n, ctx)
  return UNDEFINED_ATOM

proc sys_sleep*(glb: ptr GlobalContext) =
  UNUSED(glb)
  vTaskDelay(1)
