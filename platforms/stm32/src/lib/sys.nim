## **************************************************************************
##    Copyright 2018 by Riccardo Binetti <rbino@gmx.com>                    *
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
  defaultatoms

##  Monotonically increasing number of milliseconds from reset
##  Overflows every 49 days
##  TODO: use 64 bit (remember to take into account atomicity)

var system_millis*: uint32

##  Called when systick fires

proc sys_tick_handler*() =
  inc(system_millis)

##  Sleep for delay milliseconds

proc msleep*(delay: uint32) =
  ##  TODO: use a smarter sleep instead of busy waiting
  var wake: uint32 = system_millis + delay
  while wake > system_millis:
    nil

proc sys_clock_gettime*(t: ptr timespec)  =
  t.tv_sec = system_millis div 1000
  t.tv_nsec = (system_millis mod 1000) * 1000000

proc timespec_diff_to_ms*(timespec1: ptr timespec; timespec2: ptr timespec): int32 {.
    cdecl.} =
  return (timespec1.tv_sec - timespec2.tv_sec) * 1000 +
      (timespec1.tv_nsec - timespec2.tv_nsec) div 1000000

proc sys_init_platform*(glb: ptr GlobalContext) =
  UNUSED(glb)

proc sys_consume_pending_events*(glb: ptr GlobalContext) =
  UNUSED(glb)

proc sys_set_timestamp_from_relative_to_abs*(t: ptr timespec; millis: int32) =
  sys_clock_gettime(t)
  inc(t.tv_sec, millis div 1000)
  inc(t.tv_nsec, (millis mod 1000) * 1000000)

proc sys_time*(t: ptr timespec) =
  sys_clock_gettime(t)

proc sys_millis*(): uint32 =
  return system_millis

proc sys_start_millis_timer*() =
  discard

proc sys_stop_millis_timer*() =
  discard

proc sys_load_module*(global: ptr GlobalContext; module_name: cstring): ptr Module {.
    cdecl.} =
  var beam_module: pointer = nil
  var beam_module_size: uint32 = 0
  if not (global.avmpack_data and
      avmpack_find_section_by_name(global.avmpack_data, module_name,
                                   addr(beam_module), addr(beam_module_size))):
    fprintf(stderr, "Failed to open module: %s\n", module_name)
    return nil
  var new_module: ptr Module = module_new_from_iff_binary(global, beam_module,
      beam_module_size)
  new_module.module_platform_data = nil
  return new_module

proc sys_create_port*(glb: ptr GlobalContext; driver_name: cstring; opts: term): ptr Context {.
    cdecl.} =
  var new_ctx: ptr Context = context_new(glb)
  if not strcmp(driver_name, "gpio"):
    gpiodriver_init(new_ctx)
  else:
    context_destroy(new_ctx)
    return nil
  return new_ctx

proc sys_get_info*(ctx: ptr Context; key: term): term =
  return UNDEFINED_ATOM

proc sys_sleep*(glb: ptr GlobalContext) =
  UNUSED(glb)
