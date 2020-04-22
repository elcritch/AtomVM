## **************************************************************************
##    Copyright 2018,2019 by Davide Bettio <davide@uninstall.it>            *
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
  term, atom, context, interop, valueshashtable, tempstack

when defined(__clang__):
  const
    REF_CONST_FMT* = "#Ref<0.0.0.%llu>"
else:
  const
    REF_CONST_FMT* = "#Ref<0.0.0.%lu>"
when defined(__clang__):
  const
    FUN_FMT* = "#Fun<erl_eval.%lu.%llu>"
else:
  const
    FUN_FMT* = "#Fun<erl_eval.%lu.%llu>"
var empty_tuple*: term = 0

proc term_display*(fd: ptr FILE; t: term; ctx: ptr Context) {.cdecl.} =
  if term_is_atom(t):
    var atom_index: cint = term_to_atom_index(t)
    var atom_string: AtomString = cast[AtomString](valueshashtable_get_value(
        ctx.global.atoms_ids_table, atom_index, cast[culong](nil)))
    fprintf(fd, "%.*s", cast[cint](atom_string_len(atom_string)),
            cast[string](atom_string_data(atom_string)))
  elif term_is_integer(t):
    var iv: avm_int_t = term_to_int(t)
    fprintf(fd, AVM_INT_FMT, iv)
  elif term_is_nil(t):
    fprintf(fd, "[]")
  elif term_is_nonempty_list(t):
    var is_printable: cint = 1
    var list_item: term = t
    while term_is_nonempty_list(list_item):
      var head: term = term_get_list_head(list_item)
      is_printable = is_printable and term_is_uint8(head) and
          isprint(term_to_uint8(head))
      list_item = term_get_list_tail(list_item)
    ##  improper lists are not printable
    if not term_is_nil(list_item):
      is_printable = 0
    if is_printable:
      var ok: cint
      var printable: string = interop_list_to_string(t, addr(ok))
      if LIKELY(ok):
        fprintf(fd, "\"%s\"", printable)
        free(printable)
      else:
        fprintf(fd, "???")
    else:
      fputc('[', fd)
      var display_separator: cint = 0
      while term_is_nonempty_list(t):
        if display_separator:
          fputc(',', fd)
        else:
          display_separator = 1
        term_display(fd, term_get_list_head(t), ctx)
        t = term_get_list_tail(t)
      if not term_is_nil(t):
        fputc('|', fd)
        term_display(fd, t, ctx)
      fputc(']', fd)
  elif term_is_pid(t):
    fprintf(fd, "<0.%i.0>", term_to_local_process_id(t))
  elif term_is_function(t):
    var boxed_value: ptr term = term_to_const_term_ptr(t)
    var fun_module: ptr Module = cast[ptr Module](boxed_value[1])
    var fun_index: uint32_t = boxed_value[2]
    ##  TODO: FIXME
    var format: string = FUN_FMT
    fprintf(fd, format, fun_index, cast[culong](fun_module))
  elif term_is_tuple(t):
    fputc('{', fd)
    var tuple_size: cint = term_get_tuple_arity(t)
    var i: cint = 0
    while i < tuple_size:
      if i != 0:
        fputc(',', fd)
      term_display(fd, term_get_tuple_element(t, i), ctx)
      inc(i)
    fputc('}', fd)
  elif term_is_binary(t):
    var len: cint = term_binary_size(t)
    var binary_data: string = term_binary_data(t)
    var is_printable: cint = 1
    var i: cint = 0
    while i < len:
      if not isprint(binary_data[i]):
        is_printable = 0
        break
      inc(i)
    fprintf(fd, "<<")
    if is_printable:
      fprintf(fd, "\"%.*s\"", len, binary_data)
    else:
      var display_separator: cint = 0
      var i: cint = 0
      while i < len:
        if display_separator:
          fputc(',', fd)
        else:
          display_separator = 1
        var c: uint8_t = cast[uint8_t](binary_data[i])
        fprintf(fd, "%i", cast[cint](c))
        inc(i)
    fprintf(fd, ">>")
  elif term_is_reference(t):
    ##  TODO: FIXME
    var format: string = REF_CONST_FMT
    fprintf(fd, format, term_to_ref_ticks(t))
  elif term_is_boxed_integer(t): ##  TODO: FIXME
                               ##  #ifdef AVM_NO_FP
                               ##      else if (term_is_float(t)) {
                               ##          avm_float_t f = term_to_float(t);
                               ##          fprintf(fd, AVM_FLOAT_FMT, f);
                               ##      }
                               ##  #endif
    var size: cint = term_boxed_size(t)
    case size
    of 1:
      fprintf(fd, AVM_INT_FMT, term_unbox_int(t))
    else:
      abort()
  else:
    fprintf(fd, "Unknown term type: %li", t)

proc term_type_to_index*(t: term): cint {.cdecl.} =
  if term_is_invalid_term(t):
    return 0
  elif term_is_number(t):
    return 1
  elif term_is_atom(t):
    return 2
  elif term_is_reference(t):
    return 3
  elif term_is_function(t):
    return 4
  elif term_is_pid(t):
    return 6
  elif term_is_tuple(t):
    return 7
  elif term_is_nil(t):
    return 8
  elif term_is_nonempty_list(t):
    return 9
  elif term_is_binary(t):
    return 10
  else:
    abort()

proc term_compare*(t: term; other: term; ctx: ptr Context): cint {.cdecl.} =
  var temp_stack: TempStack
  temp_stack_init(addr(temp_stack))
  temp_stack_push(addr(temp_stack), t)
  temp_stack_push(addr(temp_stack), other)
  var result: cint = 0
  while not temp_stack_is_empty(addr(temp_stack)):
    if t == other:
      other = temp_stack_pop(addr(temp_stack))
      t = temp_stack_pop(addr(temp_stack))
    elif term_is_integer(t) and term_is_integer(other):
      var t_int: avm_int_t = term_to_int(t)
      var other_int: avm_int_t = term_to_int(other)
      ## They cannot be equal
      result = if (t_int > other_int): 1 else: -1
      break
    elif term_is_reference(t) and term_is_reference(other):
      var t_ticks: int64_t = term_to_ref_ticks(t)
      var other_ticks: int64_t = term_to_ref_ticks(other)
      if t_ticks == other_ticks:
        other = temp_stack_pop(addr(temp_stack))
        t = temp_stack_pop(addr(temp_stack))
      else:
        result = if (t_ticks > other_ticks): 1 else: -1
        break
    elif term_is_nonempty_list(t) and term_is_nonempty_list(other):
      var t_tail: term = term_get_list_tail(t)
      var other_tail: term = term_get_list_tail(other)
      ##  invalid term is used as a term lower than any other
      ##  so "a" < "ab" -> true can be implemented.
      if term_is_nil(t_tail):
        t_tail = term_invalid_term()
      if term_is_nil(other_tail):
        other_tail = term_invalid_term()
      temp_stack_push(addr(temp_stack), t_tail)
      temp_stack_push(addr(temp_stack), other_tail)
      t = term_get_list_head(t)
      other = term_get_list_head(other)
    elif term_is_tuple(t) and term_is_tuple(other):
      var tuple_size: cint = term_get_tuple_arity(t)
      var other_tuple_size: cint = term_get_tuple_arity(other)
      if tuple_size != other_tuple_size:
        result = if (tuple_size > other_tuple_size): 1 else: -1
        break
      if tuple_size > 0:
        var i: cint = 1
        while i < tuple_size:
          temp_stack_push(addr(temp_stack), term_get_tuple_element(t, i))
          temp_stack_push(addr(temp_stack), term_get_tuple_element(other, i))
          inc(i)
        t = term_get_tuple_element(t, 0)
        other = term_get_tuple_element(other, 0)
      else:
        other = temp_stack_pop(addr(temp_stack))
        t = temp_stack_pop(addr(temp_stack))
    elif term_is_binary(t) and term_is_binary(other):
      var t_size: cint = term_binary_size(t)
      var other_size: cint = term_binary_size(other)
      var t_data: string = term_binary_data(t)
      var other_data: string = term_binary_data(other)
      var cmp_size: cint = if (t_size > other_size): other_size else: t_size
      var memcmp_result: cint = memcmp(t_data, other_data, cmp_size)
      if memcmp_result == 0:
        if t_size == other_size:
          other = temp_stack_pop(addr(temp_stack))
          t = temp_stack_pop(addr(temp_stack))
        else:
          result = if (t_size > other_size): 1 else: -1
          break
      else:
        result = if (memcmp_result > 0): 1 else: -1
        break
    elif term_is_any_integer(t) and term_is_any_integer(other):
      var t_int: avm_int64_t = term_maybe_unbox_int64(t)
      var other_int: avm_int64_t = term_maybe_unbox_int64(other)
      if t_int == other_int:
        other = temp_stack_pop(addr(temp_stack))
        t = temp_stack_pop(addr(temp_stack))
      else:
        result = if (t_int > other_int): 1 else: -1
        break
      ##  TODO: FIXME
      ##  #ifndef AVM_NO_FP
      ##          } else if (term_is_number(t) && term_is_number(other)) {
      ##              avm_float_t t_float = term_conv_to_float(t);
      ##              avm_float_t other_float = term_conv_to_float(other);
      ##              if (t_float == other_float) {
      ##                  other = temp_stack_pop(&temp_stack);
      ##                  t = temp_stack_pop(&temp_stack);
      ##              } else {
      ##                  result = (t_float > other_float) ? 1 : -1;
      ##                  break;
      ##              }
      ##  #endif
    elif term_is_atom(t) and term_is_atom(other):
      var t_atom_index: cint = term_to_atom_index(t)
      var t_atom_string: AtomString = cast[AtomString](valueshashtable_get_value(
          ctx.global.atoms_ids_table, t_atom_index, cast[culong](nil)))
      var t_atom_len: cint = atom_string_len(t_atom_string)
      var t_atom_data: string = cast[string](atom_string_data(t_atom_string))
      var other_atom_index: cint = term_to_atom_index(other)
      var other_atom_string: AtomString = cast[AtomString](valueshashtable_get_value(
          ctx.global.atoms_ids_table, other_atom_index, cast[culong](nil)))
      var other_atom_len: cint = atom_string_len(other_atom_string)
      var other_atom_data: string = cast[string](atom_string_data(
          other_atom_string))
      var cmp_size: cint = if (t_atom_len > other_atom_len): other_atom_len else: t_atom_len
      var memcmp_result: cint = memcmp(t_atom_data, other_atom_data, cmp_size)
      if memcmp_result == 0:
        result = if (t_atom_len > other_atom_len): 1 else: -1
        break
      else:
        result = if memcmp_result > 0: 1 else: -1
        break
    elif term_is_pid(t) and term_is_pid(other):
      ## TODO: handle ports
      result = if (t > other): 1 else: -1
      break
    else:
      result = if (term_type_to_index(t) > term_type_to_index(other)): 1 else: -1
      break
  temp_stack_destory(addr(temp_stack))
  return result
