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
  freertos/FreeRTOS, esp_partition, esp_system, esp_event, esp_event_loop, nvs_flash,
  atom, avmpack, bif, context, globalcontext, iff, module, socket_driver, utils, term,
  esp32_sys, nvs_flash

proc avm_partition*(size: ptr cint): pointer {.cdecl.}
proc app_main*() {.cdecl.} =
  nvs_flash_init()
  tcpip_adapter_init()
  esp32_sys_queue_init()
  var err: esp_err_t = nvs_flash_init()
  if err == ESP_ERR_NVS_NO_FREE_PAGES or err == ESP_ERR_NVS_NEW_VERSION_FOUND:
    fprintf(stderr, "Warning: Erasing flash...\n")
    ESP_ERROR_CHECK(nvs_flash_erase())
    err = nvs_flash_init()
  ESP_ERROR_CHECK(err)
  var size: cint
  var flashed_avm: pointer = avm_partition(addr(size))
  var startup_beam_size: uint32_t
  var startup_beam: pointer
  var startup_module_name: string
  printf("Booting file mapped at: %p, size: %i\n", flashed_avm, size)
  var glb: ptr GlobalContext = globalcontext_new()
  socket_driver_init(glb)
  if not avmpack_is_valid(flashed_avm, size) or
      not avmpack_find_section_by_flag(flashed_avm, BEAM_START_FLAG,
                                      addr(startup_beam),
                                      addr(startup_beam_size),
                                      addr(startup_module_name)):
    fprintf(stderr, "error: invalid AVM Pack\n")
    abort()
  glb.avmpack_data = flashed_avm
  glb.avmpack_platform_data = nil
  var `mod`: ptr Module = module_new_from_iff_binary(glb, startup_beam,
      startup_beam_size)
  globalcontext_insert_module_with_filename(glb, `mod`, startup_module_name)
  var ctx: ptr Context = context_new(glb)
  ctx.leader = 1
  printf("Starting: %s...\n", startup_module_name)
  printf("---\n")
  context_execute_loop(ctx, `mod`, "start", 0)
  var ret_value: term = ctx.x[0]
  fprintf(stderr, "AtomVM finished with return value = ")
  term_display(stderr, ret_value, ctx)
  fprintf(stderr, "\n")
  fprintf(stderr, "going to sleep forever..\n")
  while 1:
    ##  avoid task_wdt: Task watchdog got triggered. The following tasks did not reset the watchdog in time
    ##  ..
    vTaskDelay(5000 div portTICK_PERIOD_MS)

proc avm_partition*(size: ptr cint): pointer {.cdecl.} =
  var partition: ptr esp_partition_t = esp_partition_find_first(
      ESP_PARTITION_TYPE_DATA, ESP_PARTITION_SUBTYPE_ANY, "main.avm")
  if not partition:
    printf("AVM partition not found.\n")
    size[] = 0
    return nil
  else:
    printf("Found AVM partition: size: %i, address: 0x%x\n", partition.size,
           partition.address)
    size[] = partition.size
  var mapped_memory: pointer
  var unmap_handle: spi_flash_mmap_handle_t
  if esp_partition_mmap(partition, 0, partition.size, SPI_FLASH_MMAP_DATA,
                       addr(mapped_memory), addr(unmap_handle)) != ESP_OK:
    printf("Failed to map BEAM partition\n")
    abort()
    return nil
  UNUSED(unmap_handle)
  return mapped_memory
