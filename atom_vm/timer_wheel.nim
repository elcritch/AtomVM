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
  sequtils

type

  TimerWheel* = ref object
    slots*: seq[seq[TimerWheelItem]]
    monotonic_time*: uint64

  TimerWheelItem* = ref object
    expiry_time*: uint64
    callback*: proc (a1: var TimerWheelItem)

proc slot(tw: var TimerWheel, item: var TimerWheelItem): uint64 =
  var expiry_time = item.expiry_time
  return expiry_time mod len(tw.slots).uint32

proc insert*(tw: var TimerWheel; item: var TimerWheelItem)  =
  var slot = tw.slot(item)
  tw.slots[slot].add item

proc remove*(tw: var TimerWheel; item: var TimerWheelItem) =
  var timer_slot = tw.slots[tw.slot(item)]
  timer_slot.delete(timer_slot.find(item))

proc len*(tw: var TimerWheel): int =
  result = 0
  for timer_slot in tw.slots:
    result += len(timer_slot)

proc timer_wheel_item_init*(it: ptr TimerWheelItem; cb: proc (a1: var TimerWheelItem);
                          expiry: uint64)  =
  it.expiry_time = expiry
  it.callback = cb

proc timer_wheel_expiry_to_monotonic*(tw: ptr TimerWheel; expiry: uint32): uint64 =
  return tw.monotonic_time + expiry

proc timer_wheel_create*(slots_count: int): TimerWheel =
  result = new(TimerWheel)
  result.monotonic_time = 0
  result.slots = newSeq[seq[TimerWheelItem]](slots_count)

  for i in 0..slots_count:
    result.slots[i] = @[]

proc timer_wheel_tick*(tw: var TimerWheel) =
  inc(tw.monotonic_time)
  var monotonic_time: uint64 = tw.monotonic_time
  var pos = tw.monotonic_time mod len(tw.slots).uint32
  ##  TODO: FIXME
  ##  MUTABLE_LIST_FOR_EACH(item, tmp, &tw->slots[pos]) {
  var timer_slot = tw.slots[pos]

  var is_expired = proc (ti: TimerWheelItem): bool =
    ti.expiry_time <= monotonic_time

  keepIf(timer_slot, proc (it: TimerWheelItem): bool = not is_expired(it) )
