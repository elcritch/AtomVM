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
  interop, tempstack

proc interop_term_to_string*(t: term; ok: ptr cint): cstring {.cdecl.} =
  if term_is_list(t):
    return interop_list_to_string(t, ok)
  elif term_is_binary(t):
    var str: cstring = interop_binary_to_string(t)
    ok[] = str != nil
    return str
  else:
    ## TODO: implement also for other types?
    ok[] = 0
    return nil

proc interop_binary_to_string*(binary: term): cstring {.cdecl.} =
  var len: cint = term_binary_size(binary)
  var str: cstring = malloc(len + 1)
  if IS_NULL_PTR(str):
    return nil
  memcpy(str, term_binary_data(binary), len)
  str[len] = 0
  return str

proc interop_list_to_string*(list: term; ok: ptr cint): cstring {.cdecl.} =
  var proper: cint
  var len: cint = term_list_length(list, addr(proper))
  if UNLIKELY(not proper):
    ok[] = 0
    return nil
  var str: cstring = malloc(len + 1)
  if IS_NULL_PTR(str):
    return nil
  var t: term = list
  var i: cint = 0
  while i < len:
    var byte_value_term: term = term_get_list_head(t)
    if UNLIKELY(not term_is_integer(byte_value_term)):
      ok[] = 0
      free(str)
      return nil
    if UNLIKELY(not term_is_uint8(byte_value_term)):
      ok[] = 0
      free(str)
      return nil
    var byte_value: uint8_t = term_to_uint8(byte_value_term)
    str[i] = cast[char](byte_value)
    t = term_get_list_tail(t)
    inc(i)
  str[len] = 0
  ok[] = 1
  return str

proc interop_proplist_get_value*(list: term; key: term): term {.cdecl.} =
  return interop_proplist_get_value_default(list, key, term_nil())

proc interop_proplist_get_value_default*(list: term; key: term; default_value: term): term {.
    cdecl.} =
  var t: term = list
  while not term_is_nil(t):
    var t_ptr: ptr term = term_get_list_ptr(t)
    var head: term = t_ptr[1]
    if term_is_tuple(head) and term_get_tuple_element(head, 0) == key:
      if UNLIKELY(term_get_tuple_arity(head) != 2):
        break
      return term_get_tuple_element(head, 1)
    t = t_ptr[]
  return default_value

proc interop_iolist_size*(t: term; ok: ptr cint): cint {.cdecl.} =
  if term_is_binary(t):
    ok[] = 1
    return term_binary_size(t)
  if UNLIKELY(not term_is_list(t)):
    ok[] = 0
    return 0
  var acc: culong = 0
  var temp_stack: TempStack
  temp_stack_init(addr(temp_stack))
  temp_stack_push(addr(temp_stack), t)
  while not temp_stack_is_empty(addr(temp_stack)):
    if term_is_integer(t):
      inc(acc)
      t = temp_stack_pop(addr(temp_stack))
    elif term_is_nil(t):
      t = temp_stack_pop(addr(temp_stack))
    elif term_is_nonempty_list(t):
      temp_stack_push(addr(temp_stack), term_get_list_tail(t))
      t = term_get_list_head(t)
    elif term_is_binary(t):
      inc(acc, term_binary_size(t))
      t = temp_stack_pop(addr(temp_stack))
    else:
      temp_stack_destory(addr(temp_stack))
      ok[] = 0
      return 0
  temp_stack_destory(addr(temp_stack))
  ok[] = 1
  return acc

proc interop_write_iolist*(t: term; p: cstring): cint {.cdecl.} =
  if term_is_binary(t):
    var len: cint = term_binary_size(t)
    memcpy(p, term_binary_data(t), len)
    return 1
  var temp_stack: TempStack
  temp_stack_init(addr(temp_stack))
  temp_stack_push(addr(temp_stack), t)
  while not temp_stack_is_empty(addr(temp_stack)):
    if term_is_integer(t):
      p[] = term_to_int(t)
      inc(p)
      t = temp_stack_pop(addr(temp_stack))
    elif term_is_nil(t):
      t = temp_stack_pop(addr(temp_stack))
    elif term_is_nonempty_list(t):
      temp_stack_push(addr(temp_stack), term_get_list_tail(t))
      t = term_get_list_head(t)
    elif term_is_binary(t):
      var len: cint = term_binary_size(t)
      memcpy(p, term_binary_data(t), len)
      inc(p, len)
      t = temp_stack_pop(addr(temp_stack))
    else:
      temp_stack_destory(addr(temp_stack))
      return 0
  temp_stack_destory(addr(temp_stack))
  return 1
