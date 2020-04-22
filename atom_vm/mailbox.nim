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
  mailbox, memory, scheduler, trace

const
  ADDITIONAL_PROCESSING_MEMORY_SIZE* = 4

proc mailbox_message_memory*(msg: ptr Message): ptr term  =
  return addr(msg.message) + 1

proc mailbox_send*(c: ptr Context; t: term) =
  TRACE("Sending 0x%lx to pid %i\n", t, c.process_id)
  var estimated_mem_usage: culong = memory_estimate_usage(t)
  var m: ptr Message = malloc(sizeof((Message)) +
      estimated_mem_usage * sizeof((term)))
  if IS_NULL_PTR(m):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    return
  var heap_pos: ptr term = mailbox_message_memory(m)
  m.message = memory_copy_term_tree(addr(heap_pos), t)
  m.msg_memory_size = estimated_mem_usage
  list_append(addr(c.mailbox), addr(m.mailbox_list_head))
  if c.jump_to_on_restore:
    c.saved_ip = c.jump_to_on_restore
    c.jump_to_on_restore = nil
  scheduler_make_ready(c.global, c)

proc mailbox_receive*(c: ptr Context): term =
  var m: ptr Message = GET_LIST_ENTRY(list_first(addr(c.mailbox)), Message,
                                 mailbox_list_head)
  list_remove(addr(m.mailbox_list_head))
  if c.e - c.heap_ptr < m.msg_memory_size:
    ## ADDITIONAL_PROCESSING_MEMORY_SIZE: ensure some additional memory for message processing, so there is
    ## no need to run GC again.
    if UNLIKELY(memory_gc(c, context_memory_size(c) + m.msg_memory_size +
        ADDITIONAL_PROCESSING_MEMORY_SIZE) != MEMORY_GC_OK):
      fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
  var rt: term = memory_copy_term_tree(addr(c.heap_ptr), m.message)
  free(m)
  TRACE("Pid %i is receiving 0x%lx.\n", c.process_id, rt)
  return rt

proc mailbox_dequeue*(c: ptr Context): ptr Message =
  var m: ptr Message = GET_LIST_ENTRY(list_first(addr(c.mailbox)), Message,
                                 mailbox_list_head)
  list_remove(addr(m.mailbox_list_head))
  TRACE("Pid %i is dequeueing 0x%lx.\n", c.process_id, m.message)
  return m

proc mailbox_peek*(c: ptr Context): term =
  var m: ptr Message = GET_LIST_ENTRY(list_first(addr(c.mailbox)), Message,
                                 mailbox_list_head)
  TRACE("Pid %i is peeking 0x%lx.\n", c.process_id, m.message)
  if c.e - c.heap_ptr < m.msg_memory_size:
    ## ADDITIONAL_PROCESSING_MEMORY_SIZE: ensure some additional memory for message processing, so there is
    ## no need to run GC again.
    if UNLIKELY(memory_gc(c, context_memory_size(c) + m.msg_memory_size +
        ADDITIONAL_PROCESSING_MEMORY_SIZE) != MEMORY_GC_OK):
      fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
  var rt: term = memory_copy_term_tree(addr(c.heap_ptr), m.message)
  return rt

proc mailbox_remove*(c: ptr Context) =
  if UNLIKELY(list_is_empty(addr(c.mailbox))):
    TRACE("Pid %i tried to remove a message from an empty mailbox.\n",
          c.process_id)
    return
  var m: ptr Message = GET_LIST_ENTRY(list_first(addr(c.mailbox)), Message,
                                 mailbox_list_head)
  list_remove(addr(m.mailbox_list_head))
  TRACE("Pid %i is removing a message.\n", c.process_id)
  free(m)
