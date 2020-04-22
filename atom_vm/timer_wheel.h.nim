## **************************************************************************
##    Copyright 2019 by Davide Bettio <davide@uninstall.it>                 *
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
  list

type
  TimerWheelItem* = object

  timer_wheel_callback_t* = proc (a1: ptr TimerWheelItem) {.cdecl.}
  TimerWheel* = object
    slots*: ptr ListHead
    slots_count*: cint
    timers*: cint
    monotonic_time*: uint64_t

  TimerWheelItem* = object
    expiry_time*: uint64_t
    head*: ListHead
    callback*: ptr timer_wheel_callback_t


proc timer_wheel_new*(slots_count: cint): ptr TimerWheel {.cdecl.}
proc timer_wheel_tick*(tw: ptr TimerWheel) {.cdecl.}
proc timer_wheel_insert*(tw: ptr TimerWheel; item: ptr TimerWheelItem)  =
  var expiry_time: uint64_t = item.expiry_time
  var slot: cint = expiry_time mod tw.slots_count
  inc(tw.timers)
  list_append(addr(tw.slots[slot]), addr(item.head))

proc timer_wheel_remove*(tw: ptr TimerWheel; item: ptr TimerWheelItem)  =
  dec(tw.timers)
  list_remove(addr(item.head))

proc timer_wheel_is_empty*(tw: ptr TimerWheel): bool  =
  return tw.timers == 0

proc timer_wheel_timers_count*(tw: ptr TimerWheel): cint  =
  return tw.timers

proc timer_wheel_item_init*(it: ptr TimerWheelItem; cb: timer_wheel_callback_t;
                           expiry: uint64_t)  =
  it.expiry_time = expiry
  it.callback = cb

proc timer_wheel_expiry_to_monotonic*(tw: ptr TimerWheel; expiry: uint32_t): uint64_t {.
    inline, cdecl.} =
  return tw.monotonic_time + expiry
