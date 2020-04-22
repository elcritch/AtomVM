## **************************************************************************
##    Copyright 2018 by Fred Dushin <fred@dushin.net>                       *
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
  port, context, globalcontext, mailbox, defaultatoms

proc port_create_tuple2*(ctx: ptr Context; a: term; b: term): term {.cdecl.} =
  var terms: array[2, term]
  terms[0] = a
  terms[1] = b
  return port_create_tuple_n(ctx, 2, terms)

proc port_create_tuple3*(ctx: ptr Context; a: term; b: term; c: term): term {.cdecl.} =
  var terms: array[3, term]
  terms[0] = a
  terms[1] = b
  terms[2] = c
  return port_create_tuple_n(ctx, 3, terms)

proc port_create_tuple_n*(ctx: ptr Context; num_terms: csize; terms: ptr term): term {.
    cdecl.} =
  var ret: term = term_alloc_tuple(num_terms, ctx)
  var i: csize = 0
  while i < num_terms:
    term_put_tuple_element(ret, i, terms[i])
    inc(i)
  return ret

proc port_create_error_tuple*(ctx: ptr Context; reason: term): term {.cdecl.} =
  return port_create_tuple2(ctx, ERROR_ATOM, reason)

proc port_create_sys_error_tuple*(ctx: ptr Context; syscall: term; errno: cint): term {.
    cdecl.} =
  var reason: term = port_create_tuple2(ctx, syscall, term_from_int32(errno))
  return port_create_error_tuple(ctx, reason)

proc port_create_ok_tuple*(ctx: ptr Context; t: term): term {.cdecl.} =
  return port_create_tuple2(ctx, OK_ATOM, t)

proc port_send_reply*(ctx: ptr Context; pid: term; `ref`: term; reply: term) {.cdecl.} =
  var msg: term = port_create_tuple2(ctx, `ref`, reply)
  port_send_message(ctx, pid, msg)

proc port_send_message*(ctx: ptr Context; pid: term; msg: term) {.cdecl.} =
  var local_process_id: cint = term_to_local_process_id(pid)
  var target: ptr Context = globalcontext_get_process(ctx.global, local_process_id)
  mailbox_send(target, msg)

proc port_ensure_available*(ctx: ptr Context; size: csize) {.cdecl.} =
  if context_avail_free_memory(ctx) < size:
    case memory_ensure_free(ctx, size)
    of MEMORY_GC_OK:
      nil
    of MEMORY_GC_ERROR_FAILED_ALLOCATION: ##  TODO Improve error handling
      fprintf(stderr, "Failed to allocate additional heap storage: [%s:%i]\n",
              __FILE__, __LINE__)
      abort()
    of MEMORY_GC_DENIED_ALLOCATION: ##  TODO Improve error handling
      fprintf(stderr,
              "Not permitted to allocate additional heap storage: [%s:%i]\n",
              __FILE__, __LINE__)
      abort()

proc port_is_standard_port_command*(t: term): cint {.cdecl.} =
  if not term_is_tuple(t):
    return 0
  elif term_get_tuple_arity(t) != 3:
    return 0
  else:
    var pid: term = term_get_tuple_element(t, 0)
    var `ref`: term = term_get_tuple_element(t, 1)
    if not term_is_pid(pid):
      return 0
    elif not term_is_reference(`ref`):
      return 0
    else:
      return 1
