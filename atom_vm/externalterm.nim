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
  externalterm, context, list, utils

const
  EXTERNAL_TERM_TAG* = 131
  NEW_FLOAT_EXT* = 70
  SMALL_INTEGER_EXT* = 97
  INTEGER_EXT* = 98
  ATOM_EXT* = 100
  SMALL_TUPLE_EXT* = 104
  NIL_EXT* = 106
  STRING_EXT* = 107
  LIST_EXT* = 108
  BINARY_EXT* = 109
  EXPORT_EXT* = 113

proc parse_external_terms*(external_term_buf: ptr uint8_t; eterm_size: ptr cint;
                          ctx: ptr Context; copy: cint): term {.cdecl.}
proc calculate_heap_usage*(external_term_buf: ptr uint8_t; eterm_size: ptr cint;
                          copy: bool; ctx: ptr Context): cint {.cdecl.}
proc compute_external_size*(ctx: ptr Context; t: term): csize {.cdecl.}
proc externalterm_from_term*(ctx: ptr Context; buf: ptr ptr uint8_t; len: ptr csize;
                            t: term): cint {.cdecl.}
proc serialize_term*(ctx: ptr Context; buf: ptr uint8_t; t: term): cint {.cdecl.}
## *
##  @brief
##  @param   external_term   buffer containing external term
##  @param   ctx             current context in which terms may be stored
##  @param   use_heap_fragment whether to store parsed terms in a heap fragement.  If 0, terms
##                           are stored in the context heap.
##  @param   bytes_read      the number of bytes read off external_term in order to yeild a term
##  @return  the parsed term
##

proc externalterm_to_term_internal*(external_term: pointer; ctx: ptr Context;
                                   use_heap_fragment: cint; bytes_read: ptr csize): term {.
    cdecl.} =
  var external_term_buf: ptr uint8_t = cast[ptr uint8_t](external_term)
  if UNLIKELY(external_term_buf[0] != EXTERNAL_TERM_TAG):
    fprintf(stderr, "External term format not supported\n")
    abort()
  var eterm_size: cint
  var heap_usage: cint = calculate_heap_usage(external_term_buf + 1, addr(eterm_size),
      false, ctx)
  if use_heap_fragment:
    var heap_fragment: ptr ListHead = malloc(heap_usage * sizeof((term)) +
        sizeof(ListHead))
    if IS_NULL_PTR(heap_fragment):
      return term_invalid_term()
    list_append(addr(ctx.heap_fragments), heap_fragment)
    inc(ctx.heap_fragments_size, heap_usage)
    var external_term_heap: ptr term = cast[ptr term]((heap_fragment + 1))
    ##  save the heap pointer and temporary switch to the newly created heap fragment
    ##  so all existing functions can be used on the heap fragment without any change.
    var main_heap: ptr term = ctx.heap_ptr
    ctx.heap_ptr = external_term_heap
    var result: term = parse_external_terms(external_term_buf + 1, addr(eterm_size),
                                        ctx, 0)
    bytes_read[] = eterm_size + 1
    ctx.heap_ptr = main_heap
    return result
  else:
    if UNLIKELY(memory_ensure_free(ctx, heap_usage) != MEMORY_GC_OK):
      fprintf(stderr, "Unable to ensure %i free words in heap\n", eterm_size)
      return term_invalid_term()
    var result: term = parse_external_terms(external_term_buf + 1, addr(eterm_size),
                                        ctx, 1)
    bytes_read[] = eterm_size + 1
    return result

proc externalterm_to_term*(external_term: pointer; ctx: ptr Context;
                          use_heap_fragment: cint): term =
  var bytes_read: csize = 0
  return externalterm_to_term_internal(external_term, ctx, use_heap_fragment,
                                      addr(bytes_read))

proc externalterm_from_binary*(ctx: ptr Context; dst: ptr term; binary: term;
                              bytes_read: ptr csize; num_extra_terms: csize): ExternalTermResult {.
    cdecl.} =
  if not term_is_binary(binary):
    return EXTERNAL_TERM_BAD_ARG
  var len: csize = term_binary_size(binary)
  var data: ptr uint8_t = cast[ptr uint8_t](term_binary_data(binary))
  var buf: ptr uint8_t = malloc(len)
  if UNLIKELY(IS_NULL_PTR(buf)):
    fprintf(stderr, "Unable to allocate %zu bytes for binary buffer.\n", len)
    return EXTERNAL_TERM_MALLOC
  memcpy(buf, data, len)
  ##
  ##  convert
  ##
  dst[] = externalterm_to_term_internal(buf, ctx, 0, bytes_read)
  free(buf)
  return EXTERNAL_TERM_OK

proc externalterm_from_term*(ctx: ptr Context; buf: ptr ptr uint8_t; len: ptr csize;
                            t: term): cint =
  len[] = compute_external_size(ctx, t) + 1
  buf[] = malloc(len[])
  if UNLIKELY(IS_NULL_PTR(buf[])):
    fprintf(stderr, "Unable to allocate %zu bytes for externalized term.\n", len[])
    abort()
  var k: csize = serialize_term(ctx, buf[] + 1, t)
  buf[0][] = EXTERNAL_TERM_TAG
  return k + 1

proc externalterm_to_binary*(ctx: ptr Context; t: term): term =
  ##
  ##  convert
  ##
  var buf: ptr uint8_t
  var len: csize
  externalterm_from_term(ctx, addr(buf), addr(len), t)
  ##
  ##  Ensure enough free space in heap for binary
  ##
  var size_in_terms: cint = term_binary_data_size_in_terms(len)
  if UNLIKELY(memory_ensure_free(ctx, size_in_terms + 1) != MEMORY_GC_OK):
    fprintf(stderr, "Unable to ensure %i free words in heap\n", size_in_terms)
    return term_invalid_term()
  var binary: term = term_from_literal_binary(cast[pointer](buf), len, ctx)
  free(buf)
  return binary

proc compute_external_size*(ctx: ptr Context; t: term): csize =
  return serialize_term(ctx, nil, t)

proc serialize_term*(ctx: ptr Context; buf: ptr uint8_t; t: term): cint =
  if term_is_uint8(t):
    if not IS_NULL_PTR(buf):
      buf[0] = SMALL_INTEGER_EXT
      buf[1] = term_to_uint8(t)
    return 2
  elif term_is_integer(t):
    if not IS_NULL_PTR(buf):
      var val: int32_t = term_to_int32(t)
      buf[0] = INTEGER_EXT
      WRITE_32_UNALIGNED(buf + 1, val)
    return 5
  elif term_is_atom(t):
    var atom_string: AtomString = globalcontext_atomstring_from_term(ctx.global, t)
    var atom_len: csize = atom_string_len(atom_string)
    if not IS_NULL_PTR(buf):
      buf[0] = ATOM_EXT
      WRITE_16_UNALIGNED(buf + 1, atom_len)
      var atom_data: ptr int8_t = cast[ptr int8_t](atom_string_data(atom_string))
      var i: csize = 3
      while i < atom_len + 3:
        buf[i] = cast[int8_t](atom_data[i - 3])
        inc(i)
    return 3 + atom_len
  elif term_is_tuple(t):
    var arity: csize = term_get_tuple_arity(t)
    if arity > 255:
      fprintf(stderr, "Tuple arity greater than 255: %zu\n", arity)
      abort()
    if not IS_NULL_PTR(buf):
      buf[0] = SMALL_TUPLE_EXT
      buf[1] = cast[int8_t](arity)
    var k: csize = 2
    var i: csize = 0
    while i < arity:
      var e: term = term_get_tuple_element(t, i)
      inc(k, serialize_term(ctx, if IS_NULL_PTR(buf): nil else: buf + k, e))
      inc(i)
    return k
  elif term_is_nil(t):
    if not IS_NULL_PTR(buf):
      buf[0] = NIL_EXT
    return 1
  elif term_is_string(t):
    if not IS_NULL_PTR(buf):
      buf[0] = STRING_EXT
    var len: csize = 0
    var k: csize = 3
    var i: term = t
    while not term_is_nil(i):
      var e: term = term_get_list_head(i)
      if not IS_NULL_PTR(buf):
        (buf + k)[] = term_to_uint8(e)
      inc(k)
      i = term_get_list_tail(i)
      inc(len)
    if not IS_NULL_PTR(buf):
      WRITE_16_UNALIGNED(buf + 1, len)
    return k
  elif term_is_list(t):
    if not IS_NULL_PTR(buf):
      buf[0] = LIST_EXT
    var len: csize = 0
    var k: csize = 5
    var i: term = t
    while term_is_nonempty_list(i):
      var e: term = term_get_list_head(i)
      inc(k, serialize_term(ctx, if IS_NULL_PTR(buf): nil else: buf + k, e))
      i = term_get_list_tail(i)
      inc(len)
    inc(k, serialize_term(ctx, if IS_NULL_PTR(buf): nil else: buf + k, i))
    if not IS_NULL_PTR(buf):
      WRITE_32_UNALIGNED(buf + 1, len)
    return k
  elif term_is_binary(t):
    if not IS_NULL_PTR(buf):
      buf[0] = BINARY_EXT
    var len: csize = term_binary_size(t)
    if not IS_NULL_PTR(buf):
      var data: ptr uint8_t = cast[ptr uint8_t](term_binary_data(t))
      WRITE_32_UNALIGNED(buf + 1, len)
      memcpy(buf + 5, data, len)
    return 5 + len
  else:
    fprintf(stderr, "Unknown term type: %li\n", t)
    abort()

proc parse_external_terms*(external_term_buf: ptr uint8_t; eterm_size: ptr cint;
                          ctx: ptr Context; copy: cint): term =
  case external_term_buf[0]
  of NEW_FLOAT_EXT:
    when not defined(AVM_NO_FP):
      var v: tuple[intvalue: uint64_t, doublevalue: cdouble]
      v.intvalue = READ_64_UNALIGNED(external_term_buf + 1)
      eterm_size[] = 9
      return term_from_float(v.doublevalue, ctx)
    else:
      fprintf(stderr, "floating point support not enabled.\n")
      abort()
  of SMALL_INTEGER_EXT:
    eterm_size[] = 2
    return term_from_int11(external_term_buf[1])
  of INTEGER_EXT:
    var value: int32_t = READ_32_UNALIGNED(external_term_buf + 1)
    eterm_size[] = 5
    return term_from_int32(value)
  of ATOM_EXT:
    var atom_len: uint16_t = READ_16_UNALIGNED(external_term_buf + 1)
    var global_atom_id: cint = globalcontext_insert_atom_maybe_copy(ctx.global,
        (AtomString)(external_term_buf + 2), copy)
    eterm_size[] = 3 + atom_len
    return term_from_atom_index(global_atom_id)
  of SMALL_TUPLE_EXT:
    var arity: uint8_t = external_term_buf[1]
    var `tuple`: term = term_alloc_tuple(arity, ctx)
    var buf_pos: cint = 2
    var i: cint = 0
    while i < arity:
      var element_size: cint
      var put_value: term = parse_external_terms(external_term_buf + buf_pos,
          addr(element_size), ctx, copy)
      term_put_tuple_element(`tuple`, i, put_value)
      inc(buf_pos, element_size)
      inc(i)
    eterm_size[] = buf_pos
    return `tuple`
  of NIL_EXT:
    eterm_size[] = 1
    return term_nil()
  of STRING_EXT:
    var string_size: uint16_t = READ_16_UNALIGNED(external_term_buf + 1)
    eterm_size[] = 3 + string_size
    return term_from_string(cast[ptr uint8_t](external_term_buf) + 3, string_size, ctx)
  of LIST_EXT:
    var list_len: uint32_t = READ_32_UNALIGNED(external_term_buf + 1)
    var list_begin: term = term_nil()
    var prev_term: ptr term = nil
    var buf_pos: cint = 5
    var i: cuint = 0
    while i < list_len:
      var item_size: cint
      var head: term = parse_external_terms(external_term_buf + buf_pos,
                                        addr(item_size), ctx, copy)
      var new_list_item: ptr term = term_list_alloc(ctx)
      if prev_term:
        prev_term[0] = term_list_from_list_ptr(new_list_item)
      else:
        list_begin = term_list_from_list_ptr(new_list_item)
      prev_term = new_list_item
      new_list_item[1] = head
      inc(buf_pos, item_size)
      inc(i)
    if prev_term:
      var tail_size: cint
      var tail: term = parse_external_terms(external_term_buf + buf_pos,
                                        addr(tail_size), ctx, copy)
      prev_term[0] = tail
      inc(buf_pos, tail_size)
    eterm_size[] = buf_pos
    return list_begin
  of BINARY_EXT:
    var binary_size: uint32_t = READ_32_UNALIGNED(external_term_buf + 1)
    eterm_size[] = 5 + binary_size
    if copy:
      return term_from_literal_binary(cast[ptr uint8_t](external_term_buf) + 5,
                                     binary_size, ctx)
    else:
      return term_from_const_binary(cast[ptr uint8_t](external_term_buf) + 5,
                                   binary_size, ctx)
  of EXPORT_EXT:
    var heap_usage: cint = 1
    var buf_pos: cint = 1
    var element_size: cint
    var m: term = parse_external_terms(external_term_buf + buf_pos, addr(element_size),
                                   ctx, copy)
    inc(buf_pos, element_size)
    var f: term = parse_external_terms(external_term_buf + buf_pos, addr(element_size),
                                   ctx, copy)
    inc(buf_pos, element_size)
    var a: term = parse_external_terms(external_term_buf + buf_pos, addr(element_size),
                                   ctx, copy)
    inc(buf_pos, element_size)
    eterm_size[] = buf_pos
    return term_make_function_reference(m, f, a, ctx)
  else:
    fprintf(stderr, "Unknown term type: %i\n", cast[cint](external_term_buf[0]))
    abort()

proc calculate_heap_usage*(external_term_buf: ptr uint8_t; eterm_size: ptr cint;
                          copy: bool; ctx: ptr Context): cint =
  case external_term_buf[0]
  of NEW_FLOAT_EXT:
    when not defined(AVM_NO_FP):
      eterm_size[] = 9
      return FLOAT_SIZE
    else:
      fprintf(stderr, "floating point support not enabled.\n")
      abort()
  of SMALL_INTEGER_EXT:
    eterm_size[] = 2
    return 0
  of INTEGER_EXT:
    eterm_size[] = 5
    return 0
  of ATOM_EXT:
    var atom_len: uint16_t = READ_16_UNALIGNED(external_term_buf + 1)
    eterm_size[] = 3 + atom_len
    return 0
  of SMALL_TUPLE_EXT:
    var arity: uint8_t = external_term_buf[1]
    var heap_usage: cint = 1
    var buf_pos: cint = 2
    var i: cint = 0
    while i < arity:
      var element_size: cint
      inc(heap_usage, calculate_heap_usage(external_term_buf + buf_pos,
          addr(element_size), copy, ctx) + 1)
      inc(buf_pos, element_size)
      inc(i)
    eterm_size[] = buf_pos
    return heap_usage
  of NIL_EXT:
    eterm_size[] = 1
    return 0
  of STRING_EXT:
    var string_size: uint16_t = READ_16_UNALIGNED(external_term_buf + 1)
    eterm_size[] = 3 + string_size
    return string_size * 2
  of LIST_EXT:
    var list_len: uint32_t = READ_32_UNALIGNED(external_term_buf + 1)
    var buf_pos: cint = 5
    var heap_usage: cint = 0
    var i: cuint = 0
    while i < list_len:
      var item_size: cint
      inc(heap_usage, calculate_heap_usage(external_term_buf + buf_pos,
          addr(item_size), copy, ctx) + 2)
      inc(buf_pos, item_size)
      inc(i)
    var tail_size: cint
    inc(heap_usage, calculate_heap_usage(external_term_buf + buf_pos,
                                        addr(tail_size), copy, ctx))
    inc(buf_pos, tail_size)
    eterm_size[] = buf_pos
    return heap_usage
  of BINARY_EXT:
    var binary_size: uint32_t = READ_32_UNALIGNED(external_term_buf + 1)
    eterm_size[] = 5 + binary_size
    when TERM_BYTES == 4:
      var size_in_terms: cint = ((binary_size + 4 - 1) shr 2)
    elif TERM_BYTES == 8:
      var size_in_terms: cint = ((binary_size + 8 - 1) shr 3)
    else:
    if copy:
      return 2 + size_in_terms
    else:
      return TERM_BOXED_REFC_BINARY_SIZE
  of EXPORT_EXT:
    var heap_usage: cint = 1
    var buf_pos: cint = 1
    var i: cint = 0
    while i < 3:
      var element_size: cint
      inc(heap_usage, calculate_heap_usage(external_term_buf + buf_pos,
          addr(element_size), copy, ctx) + 1)
      inc(buf_pos, element_size)
      inc(i)
    eterm_size[] = buf_pos
    return FUNCTION_REFERENCE_SIZE
  else:
    fprintf(stderr, "Unknown term type: %i\n", cast[cint](external_term_buf[0]))
    abort()
