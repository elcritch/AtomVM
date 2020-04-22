## **************************************************************************
##    Copyright 2018 by Davide Bettio <davide@uninstall.it>                 *
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
  context, list, debug, memory, tempstack

## #define ENABLE_TRACE

import
  trace

const
  MIN_FREE_SPACE_SIZE* = 16

template MAX*(a, b: untyped): untyped =
  (if (a) > (b): (a) else: (b))

proc memory_scan_and_copy*(mem_start: ptr term; mem_end: ptr term;
                          new_heap_pos: ptr ptr term; move: cint) {.cdecl.}
proc memory_shallow_copy_term*(t: term; new_heap: ptr ptr term; move: cint): term {.cdecl.}
##  TODO: FIXME
##  HOT_FUNC term *memory_heap_alloc(Context *c, uint32_t size)

proc memory_heap_alloc*(c: ptr Context; size: uint32_t): ptr term =
  var allocated: ptr term = c.heap_ptr
  inc(c.heap_ptr, size)
  return allocated

proc memory_ensure_free*(c: ptr Context; size: uint32_t): MemoryGCResult =
  var free_space: csize = context_avail_free_memory(c)
  if free_space < size + MIN_FREE_SPACE_SIZE:
    var memory_size: csize = context_memory_size(c)
    if UNLIKELY(memory_gc(c, memory_size + size + MIN_FREE_SPACE_SIZE) !=
        MEMORY_GC_OK):
      ## TODO: handle this more gracefully
      TRACE("Unable to allocate memory for GC\n")
      return MEMORY_GC_ERROR_FAILED_ALLOCATION
    var new_free_space: csize = context_avail_free_memory(c)
    var new_minimum_free_space: csize = 2 * (size + MIN_FREE_SPACE_SIZE)
    if new_free_space > new_minimum_free_space:
      var new_memory_size: csize = context_memory_size(c)
      if UNLIKELY(memory_gc(c, (new_memory_size - new_free_space) +
          new_minimum_free_space) != MEMORY_GC_OK):
        TRACE("Unable to allocate memory for GC shrink\n")
        return MEMORY_GC_ERROR_FAILED_ALLOCATION
  return MEMORY_GC_OK

proc memory_gc_and_shrink*(c: ptr Context): MemoryGCResult =
  if context_avail_free_memory(c) >= MIN_FREE_SPACE_SIZE * 2:
    if UNLIKELY(memory_gc(c, context_memory_size(c) -
        context_avail_free_memory(c) div 2) != MEMORY_GC_OK):
      fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
  return MEMORY_GC_OK

proc push_to_stack*(stack: ptr ptr term; value: term)  =
  stack[] = (stack[]) - 1
  stack[][] = value

proc memory_gc*(ctx: ptr Context; new_size: cint): MemoryGCResult =
  TRACE("Going to perform gc\n")
  inc(new_size, ctx.heap_fragments_size)
  ctx.heap_fragments_size = 0
  if UNLIKELY(ctx.has_max_heap_size and (new_size > ctx.max_heap_size)):
    return MEMORY_GC_DENIED_ALLOCATION
  var new_heap: ptr term = calloc(new_size, sizeof((term)))
  if IS_NULL_PTR(new_heap):
    return MEMORY_GC_ERROR_FAILED_ALLOCATION
  var new_stack: ptr term = new_heap + new_size
  var heap_ptr: ptr term = new_heap
  var stack_ptr: ptr term = new_stack
  TRACE("- Running copy GC on registers\n")
  var i: cint = 0
  while i < ctx.avail_registers:
    var new_root: term = memory_shallow_copy_term(ctx.x[i], addr(heap_ptr), 1)
    ctx.x[i] = new_root
    inc(i)
  var stack: ptr term = ctx.e
  var stack_size: cint = ctx.stack_base - ctx.e
  TRACE("- Running copy GC on stack (stack size: %i)\n", stack_size)
  var i: cint = stack_size - 1
  while i >= 0:
    var new_root: term = memory_shallow_copy_term(stack[i], addr(heap_ptr), 1)
    push_to_stack(addr(stack_ptr), new_root)
    dec(i)
  var temp_start: ptr term = new_heap
  var temp_end: ptr term = heap_ptr
  while true:
    var next_end: ptr term = temp_end
    memory_scan_and_copy(temp_start, temp_end, addr(next_end), 1)
    temp_start = temp_end
    temp_end = next_end
    if not (temp_start != temp_end):
      break
  heap_ptr = temp_end
  free(ctx.heap_start)
  var fragment: ptr ListHead
  var tmp: ptr ListHead
  ##  TODO: FIXME
  ##  MUTABLE_LIST_FOR_EACH(fragment, tmp, &ctx->heap_fragments) {
  fragment = (addr(ctx.heap_fragments)).next
  tmp = fragment.next
  while fragment != (addr(ctx.heap_fragments)):
    free(fragment)
    fragment = tmp
    tmp = fragment.next
  list_init(addr(ctx.heap_fragments))
  ctx.heap_start = new_heap
  ctx.stack_base = ctx.heap_start + new_size
  ctx.heap_ptr = heap_ptr
  ctx.e = stack_ptr
  return MEMORY_GC_OK

proc memory_is_moved_marker*(t: ptr term): cint  =
  ##  0x2B is an unused tag
  return t[] == 0x0000002B

proc memory_replace_with_moved_marker*(to_be_replaced: ptr term; replace_with: term) {.
    inline, cdecl.} =
  to_be_replaced[0] = 0x0000002B
  to_be_replaced[1] = replace_with

proc memory_dereference_moved_marker*(moved_marker: ptr term): term  =
  return moved_marker[1]

proc memory_copy_term_tree*(new_heap: ptr ptr term; t: term): term =
  TRACE("Copy term tree: 0x%lx, heap: 0x%p\n", t, new_heap[])
  var temp_start: ptr term = new_heap[]
  var copied_term: term = memory_shallow_copy_term(t, new_heap, 0)
  var temp_end: ptr term = new_heap[]
  while true:
    var next_end: ptr term = temp_end
    memory_scan_and_copy(temp_start, temp_end, addr(next_end), 0)
    temp_start = temp_end
    temp_end = next_end
    if not (temp_start != temp_end):
      break
  new_heap[] = temp_end
  return copied_term

proc memory_estimate_usage*(t: term): culong =
  var acc: culong = 0
  var temp_stack: TempStack
  temp_stack_init(addr(temp_stack))
  temp_stack_push(addr(temp_stack), t)
  while not temp_stack_is_empty(addr(temp_stack)):
    if term_is_atom(t):
      t = temp_stack_pop(addr(temp_stack))
    elif term_is_integer(t):
      t = temp_stack_pop(addr(temp_stack))
    elif term_is_nil(t):
      t = temp_stack_pop(addr(temp_stack))
    elif term_is_pid(t):
      t = temp_stack_pop(addr(temp_stack))
    elif term_is_nonempty_list(t):
      inc(acc, 2)
      temp_stack_push(addr(temp_stack), term_get_list_tail(t))
      t = term_get_list_head(t)
    elif term_is_tuple(t):
      var tuple_size: cint = term_get_tuple_arity(t)
      inc(acc, tuple_size + 1)
      if tuple_size > 0:
        var i: cint = 1
        while i < tuple_size:
          temp_stack_push(addr(temp_stack), term_get_tuple_element(t, i))
          inc(i)
        t = term_get_tuple_element(t, 0)
      else:
        t = term_nil()
    elif term_is_boxed(t):
      inc(acc, term_boxed_size(t) + 1)
      t = temp_stack_pop(addr(temp_stack))
    else:
      fprintf(stderr, "bug: found unknown term type: 0x%lx\n", t)
      if term_is_boxed(t):
        var boxed_value: ptr term = term_to_const_term_ptr(t)
        var boxed_size: cint = term_boxed_size(t) + 1
        fprintf(stderr, "boxed header: 0x%lx, size: %i\n", boxed_value[0],
                boxed_size)
      abort()
  temp_stack_destory(addr(temp_stack))
  return acc

proc memory_scan_and_copy*(mem_start: ptr term; mem_end: ptr term;
                          new_heap_pos: ptr ptr term; move: cint) =
  var `ptr`: ptr term = mem_start
  var new_heap: ptr term = new_heap_pos[]
  while `ptr` < mem_end:
    var t: term = `ptr`[]
    if term_is_atom(t):
      TRACE("Found atom (%lx)\n", t)
      inc(`ptr`)
    elif term_is_integer(t):
      TRACE("Found integer (%lx)\n", t)
      inc(`ptr`)
    elif term_is_nil(t):
      TRACE("Found NIL (%lx)\n", t)
      inc(`ptr`)
    elif term_is_pid(t):
      TRACE("Found PID (%lx)\n", t)
      inc(`ptr`)
    elif (t and 0x00000003) == 0x00000000:
      TRACE("Found boxed header (%lx)\n", t)
      case t and TERM_BOXED_TAG_MASK
      of TERM_BOXED_TUPLE:
        var arity: cint = term_get_size_from_boxed_header(t)
        TRACE("- Boxed is tuple (%lx), arity: %i\n", t, arity)
        var i: cint = 1
        while i <= arity:
          TRACE("-- Elem: %lx\n", `ptr`[i])
          `ptr`[i] = memory_shallow_copy_term(`ptr`[i], addr(new_heap), move)
          inc(i)
        break
      of TERM_BOXED_BIN_MATCH_STATE:
        TRACE("- Found bin match state.\n")
        `ptr`[1] = memory_shallow_copy_term(`ptr`[1], addr(new_heap), move)
        break
      of TERM_BOXED_POSITIVE_INTEGER:
        TRACE("- Found boxed pos int.\n")
      of TERM_BOXED_REF:
        TRACE("- Found ref.\n")
      of TERM_BOXED_FUN:
        var fun_size: cint = term_get_size_from_boxed_header(t)
        TRACE("- Found fun, size: %i.\n", fun_size)
        ##  first term is the boxed header, followed by module and fun index.
        var i: cint = 3
        while i <= fun_size:
          TRACE("-- Frozen: %lx\n", `ptr`[i])
          `ptr`[i] = memory_shallow_copy_term(`ptr`[i], addr(new_heap), move)
          inc(i)
        break
      of TERM_BOXED_FLOAT:
        TRACE("- Found float.\n")
      of TERM_BOXED_REFC_BINARY:
        TRACE("- Found binary.\n")
      of TERM_BOXED_HEAP_BINARY:
        TRACE("- Found binary.\n")
      else:
        fprintf(stderr, "- Found unknown boxed type: %lx\n",
                (t shr 2) and 0x0000000F)
        abort()
      inc(`ptr`, term_get_size_from_boxed_header(t) + 1)
    elif term_is_nonempty_list(t):
      TRACE("Found nonempty list (%lx)\n", t)
      `ptr`[] = memory_shallow_copy_term(t, addr(new_heap), move)
      inc(`ptr`)
    elif term_is_boxed(t):
      TRACE("Found boxed (%lx)\n", t)
      `ptr`[] = memory_shallow_copy_term(t, addr(new_heap), move)
      inc(`ptr`)
    else:
      fprintf(stderr, "bug: found unknown term type: 0x%lx\n", t)
      abort()
  new_heap_pos[] = new_heap

##  TODO: FIXME
##  HOT_FUNC static term memory_shallow_copy_term(term t, term **new_heap, int move)

proc memory_shallow_copy_term*(t: term; new_heap: ptr ptr term; move: cint): term =
  if term_is_atom(t):
    return t
  elif term_is_integer(t):
    return t
  elif term_is_nil(t):
    return t
  elif term_is_pid(t):
    return t
  elif term_is_cp(t):
    ##  CP is valid only on stack
    return t
  elif term_is_catch_label(t):
    ##  catch label is valid only on stack
    return t
  elif term_is_boxed(t):
    var boxed_value: ptr term = term_to_term_ptr(t)
    if memory_is_moved_marker(boxed_value):
      return memory_dereference_moved_marker(boxed_value)
    var boxed_size: cint = term_boxed_size(t) + 1
    ##  It must be an empty tuple, so we are not going to use moved markers.
    ##  Emtpy tuples memory is too small to store moved markers.
    ##  However it is also required to avoid boxed terms duplication.
    ##  So instead all empty tuples will reference the same boxed term.
    if boxed_size == 1:
      return ((term) and empty_tuple) or TERM_BOXED_VALUE_TAG
    var dest: ptr term = new_heap[]
    var i: cint = 0
    while i < boxed_size:
      dest[i] = boxed_value[i]
      inc(i)
    inc(new_heap[], boxed_size)
    var new_term: term = (cast[term](dest)) or TERM_BOXED_VALUE_TAG
    if move:
      memory_replace_with_moved_marker(boxed_value, new_term)
    return new_term
  elif term_is_nonempty_list(t):
    var list_ptr: ptr term = term_get_list_ptr(t)
    if memory_is_moved_marker(list_ptr):
      return memory_dereference_moved_marker(list_ptr)
    var dest: ptr term = new_heap[]
    dest[0] = list_ptr[0]
    dest[1] = list_ptr[1]
    inc(new_heap[], 2)
    var new_term: term = (cast[term](dest)) or 0x00000001
    if move:
      memory_replace_with_moved_marker(list_ptr, new_term)
    return new_term
  else:
    fprintf(stderr, "Unexpected term. Term is: %lx\n", t)
    abort()
