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
  gpio_driver, atom, bif, context, debug, defaultatoms, platform_defaultatoms,
  globalcontext, mailbox, module, utils, term, trace, sys, esp32_sys

var global_gpio_ctx*: ptr Context = nil

proc consume_gpio_mailbox*(ctx: ptr Context) {.cdecl.}
##  TODO: FIXME
##  static void IRAM_ATTR gpio_isr_handler(void *arg);

proc gpio_isr_handler*(arg: pointer) {.cdecl.}
type
  GPIOListenerData* = object
    target_context*: ptr Context
    gpio*: cint


proc gpiodriver_init*(ctx: ptr Context) =
  if LIKELY(not global_gpio_ctx):
    global_gpio_ctx = ctx
    ctx.native_handler = consume_gpio_mailbox
    ctx.platform_data = nil
  else:
    fprintf(stderr, "Only a single GPIO driver can be opened.\n")
    abort()

proc gpio_interrupt_callback*(listener: ptr EventListener) =
  var data: ptr GPIOListenerData = listener.data
  var listening_ctx: ptr Context = data.target_context
  var gpio_num: cint = data.gpio
  ##  1 header + 2 elements
  if UNLIKELY(memory_ensure_free(global_gpio_ctx, 3) != MEMORY_GC_OK):
    ## TODO: it must not fail
    abort()
  var int_msg: term = term_alloc_tuple(2, global_gpio_ctx)
  term_put_tuple_element(int_msg, 0, GPIO_INTERRUPT_ATOM)
  term_put_tuple_element(int_msg, 1, term_from_int32(gpio_num))
  mailbox_send(listening_ctx, int_msg)

proc gpiodriver_set_level*(msg: term): term =
  var gpio_num: int32_t = term_to_int32(term_get_tuple_element(msg, 2))
  var level: int32_t = term_to_int32(term_get_tuple_element(msg, 3))
  gpio_set_level(gpio_num, level != 0)
  TRACE("gpio: set_level: %i %i\n", gpio_num, level != 0)
  return OK_ATOM

proc gpiodriver_set_direction*(msg: term): term =
  var gpio_num: int32_t = term_to_int32(term_get_tuple_element(msg, 2))
  var direction: term = term_get_tuple_element(msg, 3)
  if direction == INPUT_ATOM:
    gpio_set_direction(gpio_num, GPIO_MODE_INPUT)
    TRACE("gpio: set_direction: %i INPUT\n", gpio_num)
    return OK_ATOM
  elif direction == OUTPUT_ATOM:
    gpio_set_direction(gpio_num, GPIO_MODE_OUTPUT)
    TRACE("gpio: set_direction: %i OUTPUT\n", gpio_num)
    return OK_ATOM
  else:
    TRACE("gpio: unrecognized direction\n")
    return ERROR_ATOM

proc gpiodriver_read*(msg: term): term =
  var gpio_num: int32_t = term_to_int32(term_get_tuple_element(msg, 2))
  var level: cint = gpio_get_level(gpio_num)
  return term_from_int11(level)

proc gpiodriver_set_int*(ctx: ptr Context; target: ptr Context; msg: term): term =
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr ESP32PlatformData = glb.platform_data
  var gpio_num: int32_t = term_to_int32(term_get_tuple_element(msg, 2))
  var trigger: term = term_get_tuple_element(msg, 3)
  var interrupt_type: gpio_int_type_t
  case trigger
  of NONE_ATOM:
    interrupt_type = GPIO_INTR_DISABLE
  of RISING_ATOM:
    interrupt_type = GPIO_INTR_POSEDGE
  of FALLING_ATOM:
    interrupt_type = GPIO_INTR_NEGEDGE
  of BOTH_ATOM:
    interrupt_type = GPIO_INTR_ANYEDGE
  of LOW_ATOM:
    interrupt_type = GPIO_INTR_LOW_LEVEL
  of HIGH_ATOM:
    interrupt_type = GPIO_INTR_HIGH_LEVEL
  else:
    return ERROR_ATOM
  TRACE("going to install interrupt for %i.\n", gpio_num)
  ## TODO: ugly workaround here, write a real implementation
  gpio_install_isr_service(0)
  TRACE("installed ISR service 0.\n")
  var data: ptr GPIOListenerData = malloc(sizeof(GPIOListenerData))
  if IS_NULL_PTR(data):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    abort()
  data.gpio = gpio_num
  data.target_context = target
  var listener: ptr EventListener = malloc(sizeof((EventListener)))
  if IS_NULL_PTR(listener):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    abort()
  list_append(addr(platform.listeners), addr(listener.listeners_list_head))
  listener.sender = data
  listener.data = data
  listener.handler = gpio_interrupt_callback
  gpio_set_direction(gpio_num, GPIO_MODE_INPUT)
  gpio_set_intr_type(gpio_num, interrupt_type)
  gpio_isr_handler_add(gpio_num, gpio_isr_handler, data)
  return OK_ATOM

proc consume_gpio_mailbox*(ctx: ptr Context) =
  var message: ptr Message = mailbox_dequeue(ctx)
  var msg: term = message.message
  var pid: term = term_get_tuple_element(msg, 0)
  var cmd: term = term_get_tuple_element(msg, 1)
  var local_process_id: cint = term_to_local_process_id(pid)
  var target: ptr Context = globalcontext_get_process(ctx.global, local_process_id)
  var ret: term
  case cmd
  of SET_LEVEL_ATOM:
    ret = gpiodriver_set_level(msg)
  of SET_DIRECTION_ATOM:
    ret = gpiodriver_set_direction(msg)
  of READ_ATOM:
    ret = gpiodriver_read(msg)
  of SET_INT_ATOM:
    ret = gpiodriver_set_int(ctx, target, msg)
  else:
    TRACE("gpio: unrecognized command\n")
    ret = ERROR_ATOM
  free(message)
  mailbox_send(target, ret)

##  TODO: FIXME
##  static void IRAM_ATTR gpio_isr_handler(void *arg)

proc gpio_isr_handler*(arg: pointer) =
  xQueueSendFromISR(event_queue, addr(arg), nil)
