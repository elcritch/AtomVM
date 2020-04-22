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
  context, globalcontext, list, mailbox

const
  IMPL_EXECUTE_LOOP* = true

import
  opcodesswitch

const
  DEFAULT_STACK_SIZE* = 8
  BYTES_PER_TERM* = (TERM_BITS div 8)

proc context_new*(glb: ptr GlobalContext): ptr Context =
  var ctx: ptr Context = malloc(sizeof((Context)))
  if IS_NULL_PTR(ctx):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    return nil
  ctx.cp = 0
  ctx.heap_start = cast[ptr term](calloc(DEFAULT_STACK_SIZE, sizeof((term))))
  if IS_NULL_PTR(ctx.heap_start):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    free(ctx)
    return nil
  ctx.stack_base = ctx.heap_start + DEFAULT_STACK_SIZE
  ctx.e = ctx.stack_base
  ctx.heap_ptr = ctx.heap_start
  ctx.avail_registers = 16
  context_clean_registers(ctx, 0)
  ctx.min_heap_size = 0
  ctx.max_heap_size = 0
  ctx.has_min_heap_size = 0
  ctx.has_max_heap_size = 0
  list_append(addr(glb.ready_processes), addr(ctx.processes_list_head))
  list_init(addr(ctx.mailbox))
  ctx.global = glb
  ctx.process_id = globalcontext_get_new_process_id(glb)
  linkedlist_append(addr(glb.processes_table), addr(ctx.processes_table_head))
  ctx.native_handler = nil
  ctx.saved_ip = nil
  ctx.jump_to_on_restore = nil
  ctx.leader = 0
  timer_wheel_item_init(addr(ctx.timer_wheel_head), nil, 0)
  when defined(ENABLE_ADVANCED_TRACE):
    ctx.trace_calls = 0
    ctx.trace_call_args = 0
    ctx.trace_returns = 0
    ctx.trace_send = 0
    ctx.trace_receive = 0
  list_init(addr(ctx.heap_fragments))
  ctx.heap_fragments_size = 0
  ctx.flags = 0
  ctx.platform_data = nil
  ctx.bs = term_invalid_term()
  ctx.bs_offset = 0
  return ctx

proc context_destroy*(ctx: ptr Context) =
  linkedlist_remove(addr(ctx.global.processes_table),
                    addr(ctx.processes_table_head))
  free(ctx.heap_start)
  free(ctx)

proc context_message_queue_len*(ctx: ptr Context): csize =
  var num_messages: csize = 0
  var item: ptr ListHead
  ##  TODO: FIXME
  ##  LIST_FOR_EACH(item, &ctx->mailbox) {
  item = (addr(ctx.mailbox)).next
  while item != (addr(ctx.mailbox)):
    inc(num_messages)
    item = item.next
  return num_messages

proc context_size*(ctx: ptr Context): csize =
  var messages_size: csize = 0
  var item: ptr ListHead
  ##  TODO: FIXME
  ##  LIST_FOR_EACH(item, &ctx->mailbox) {
  item = (addr(ctx.mailbox)).next
  while item != (addr(ctx.mailbox)):
    var msg: ptr Message = GET_LIST_ENTRY(item, Message, mailbox_list_head)
    inc(messages_size, sizeof((Message)) + msg.msg_memory_size)
    item = item.next
  ##  TODO include ctx->platform_data
  return sizeof((Context)) + messages_size +
      context_memory_size(ctx) * BYTES_PER_TERM
