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


type
  # TODO: Fixme
  timer_wheel_callback* = proc (a1: ptr TimerWheelItem) {.cdecl.}

  TimerWheel* = ref object
    slots*: seq[seq[TimerWheelItem]]
    timers*: int
    monotonic_time*: uint64

  TimerWheelItem* = ref object
    expiry_time*: uint64
    head*: ListHead
    callback*: ptr timer_wheel_callback

proc timer_wheel_insert*(tw: var TimerWheel; item: sink var TimerWheelItem)  =
  var expiry_time: uint64 = item.expiry_time
  var slot: int = expiry_time mod tw.slots_count
  inc(tw.timers)
  tw.slots[slot].add item

proc timer_wheel_remove*(tw: ptr TimerWheel; item: ptr TimerWheelItem)  =
  dec(tw.timers)
  list_remove(addr(item.head))
  tw.slots[slot].remove item

proc timer_wheel_is_empty*(tw: ptr TimerWheel): bool  =
  return tw.timers == 0

proc timer_wheel_timers_count*(tw: ptr TimerWheel): cint  =
  return tw.timers

proc timer_wheel_item_init*(it: ptr TimerWheelItem; cb: timer_wheel_callback;
                          expiry: uint64)  =
  it.expiry_time = expiry
  it.callback = cb

proc timer_wheel_expiry_to_monotonic*(tw: ptr TimerWheel; expiry: uint32): uint64 {.
    inline, cdecl.} =
  return tw.monotonic_time + expiry

proc timer_wheel_new*(slots_count: cint): ptr TimerWheel =
  var tw: ptr TimerWheel = malloc(sizeof(TimerWheel))
  tw.slots = malloc(sizeof(cast[ListHead](slots_count[])))
  var i: cint = 0
  while i < slots_count:
    list_init(addr(tw.slots[i]))
    inc(i)
  tw.slots_count = slots_count
  tw.timers = 0
  tw.monotonic_time = 0
  return tw

proc timer_wheel_tick*(tw: ptr TimerWheel) =
  inc(tw.monotonic_time)
  var monotonic_time: uint64 = tw.monotonic_time
  var pos: cint = tw.monotonic_time mod tw.slots_count
  var item: ptr ListHead
  var tmp: ptr ListHead
  ##  TODO: FIXME
  ##  MUTABLE_LIST_FOR_EACH(item, tmp, &tw->slots[pos]) {
  item = (addr(tw.slots[pos])).next
  tmp = item.next
  while item != (addr(tw.slots[pos])):
    var ti: ptr TimerWheelItem = GET_LIST_ENTRY(item, struct, TimerWheelItem, head)
    if ti.expiry_time <= monotonic_time:
      dec(tw.timers)
      list_remove(item)
      ti.callback(ti)
    item = tmp
    tmp = item.next
