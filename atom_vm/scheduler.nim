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
  debug, list, scheduler, sys, utils

proc scheduler_execute_native_handlers*(global: ptr GlobalContext) {.cdecl.}
proc update_timer_wheel*(global: ptr GlobalContext) =
  var tw: ptr TimerWheel = global.timer_wheel
  var last_seen_millis: uint32 = global.last_seen_millis
  if timer_wheel_is_empty(tw):
    sys_stop_millis_timer()
    return
  var millis_now: uint32 = sys_millis()
  if millis_now < last_seen_millis:
    var i: uint32 = last_seen_millis
    while i < UINT32_MAX:
      timer_wheel_tick(tw)
      inc(i)
  var i: uint32 = last_seen_millis
  while i < millis_now:
    timer_wheel_tick(tw)
    inc(i)
  global.last_seen_millis = millis_now

proc scheduler_wait*(global: ptr GlobalContext; c: ptr Context): ptr Context =
  when defined(DEBUG_PRINT_READY_PROCESSES):
    debug_print_processes_list(global.ready_processes)
  scheduler_make_waiting(global, c)
  while true:
    update_timer_wheel(global)
    sys_consume_pending_events(global)
    scheduler_execute_native_handlers(global)
    update_timer_wheel(global)
    if list_is_empty(addr(global.ready_processes)):
      sys_sleep(global)
    if not list_is_empty(addr(global.ready_processes)):
      break
  var next_ready: ptr ListHead = list_first(addr(global.ready_processes))
  list_remove(next_ready)
  list_append(addr(global.ready_processes), next_ready)
  return GET_LIST_ENTRY(next_ready, Context, processes_list_head)

proc scheduler_execute_native_handler*(global: ptr GlobalContext; c: ptr Context) {.
    inline, cdecl.} =
  scheduler_make_waiting(global, c)
  ##  context might terminate itself
  ##  so call to native_handler must be the last action here.
  c.native_handler(c)

proc scheduler_next*(global: ptr GlobalContext; c: ptr Context): ptr Context =
  inc(c.reductions, DEFAULT_REDUCTIONS_AMOUNT)
  update_timer_wheel(global)
  sys_consume_pending_events(global)
  ## TODO: improve scheduling here
  var item: ptr ListHead
  var tmp: ptr ListHead
  ##  TODO: FIXME
  ##  MUTABLE_LIST_FOR_EACH(item, tmp, &global->ready_processes) {
  item = (addr(global.ready_processes)).next
  tmp = item.next
  while item != (addr(global.ready_processes)):
    var next_context: ptr Context = GET_LIST_ENTRY(item, Context, processes_list_head)
    if next_context.native_handler:
      scheduler_execute_native_handler(global, next_context)
    elif not next_context.native_handler and (next_context != c):
      return next_context
    item = tmp
    tmp = item.next
  return c

proc scheduler_make_ready*(global: ptr GlobalContext; c: ptr Context) =
  list_remove(addr(c.processes_list_head))
  list_append(addr(global.ready_processes), addr(c.processes_list_head))

proc scheduler_make_waiting*(global: ptr GlobalContext; c: ptr Context) =
  list_remove(addr(c.processes_list_head))
  list_append(addr(global.waiting_processes), addr(c.processes_list_head))

proc scheduler_terminate*(c: ptr Context) =
  list_remove(addr(c.processes_list_head))
  if not c.leader:
    context_destroy(c)

proc scheduler_timeout_callback*(it: ptr TimerWheelItem) =
  timer_wheel_item_init(it, nil, 0)
  var ctx: ptr Context = GET_LIST_ENTRY(it, Context, timer_wheel_head)
  ctx.flags = (ctx.flags or WaitingTimeoutExpired) and not WaitingTimeout
  scheduler_make_ready(ctx.global, ctx)

proc scheduler_set_timeout*(ctx: ptr Context; timeout: uint32) =
  var glb: ptr GlobalContext = ctx.global
  ctx.flags = ctx.flags or WaitingTimeout
  var tw: ptr TimerWheel = glb.timer_wheel
  if timer_wheel_is_empty(tw):
    sys_start_millis_timer()
  var twi: ptr TimerWheelItem = addr(ctx.timer_wheel_head)
  if UNLIKELY(twi.callback):
    abort()
  var expiry: uint64 = timer_wheel_expiry_to_monotonic(tw, timeout)
  timer_wheel_item_init(twi, scheduler_timeout_callback, expiry)
  timer_wheel_insert(tw, twi)

proc scheduler_cancel_timeout*(ctx: ptr Context) =
  var glb: ptr GlobalContext = ctx.global
  ctx.flags = ctx.flags and not (WaitingTimeout or WaitingTimeoutExpired)
  var tw: ptr TimerWheel = glb.timer_wheel
  var twi: ptr TimerWheelItem = addr(ctx.timer_wheel_head)
  if twi.callback:
    timer_wheel_remove(tw, twi)
    timer_wheel_item_init(twi, nil, 0)

proc scheduler_execute_native_handlers*(global: ptr GlobalContext) =
  var item: ptr ListHead
  var tmp: ptr ListHead
  ##  TODO: FIXME
  ##  MUTABLE_LIST_FOR_EACH(item, tmp, &global->ready_processes) {
  item = (addr(global.ready_processes)).next
  tmp = item.next
  while item != (addr(global.ready_processes)):
    var context: ptr Context = GET_LIST_ENTRY(item, Context, processes_list_head)
    if context.native_handler:
      scheduler_execute_native_handler(global, context)
    item = tmp
    tmp = item.next

proc schudule_processes_count*(global: ptr GlobalContext): cint =
  if not global.processes_table:
    return 0
  var count: cint = 0
  var contexts: ptr Context = GET_LIST_ENTRY(global.processes_table, Context,
                                        processes_list_head)
  var context: ptr Context = contexts
  while true:
    context = GET_LIST_ENTRY(context.processes_list_head.next, Context,
                           processes_list_head)
    inc(count)
    if not (context != contexts):
      break
  return count
