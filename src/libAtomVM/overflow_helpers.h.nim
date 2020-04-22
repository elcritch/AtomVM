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

when defined(__GNUC__):
  when __GNUC__ >= 5:
    const
      BUILTIN_ADD_OVERFLOW* = __builtin_add_overflow
      BUILTIN_SUB_OVERFLOW* = __builtin_sub_overflow
      BUILTIN_MUL_OVERFLOW* = __builtin_mul_overflow
      BUILTIN_ADD_OVERFLOW_INT* = __builtin_add_overflow
      BUILTIN_SUB_OVERFLOW_INT* = __builtin_sub_overflow
      BUILTIN_MUL_OVERFLOW_INT* = __builtin_mul_overflow
      BUILTIN_ADD_OVERFLOW_INT64* = __builtin_add_overflow
      BUILTIN_SUB_OVERFLOW_INT64* = __builtin_sub_overflow
      BUILTIN_MUL_OVERFLOW_INT64* = __builtin_mul_overflow
when defined(__has_builtin):
  when __has_builtin(__builtin_add_overflow):
    const
      BUILTIN_ADD_OVERFLOW* = __builtin_add_overflow
      BUILTIN_ADD_OVERFLOW_INT* = __builtin_add_overflow
      BUILTIN_ADD_OVERFLOW_INT64* = __builtin_add_overflow
  when __has_builtin(__builtin_sub_overflow):
    const
      BUILTIN_SUB_OVERFLOW* = __builtin_sub_overflow
      BUILTIN_SUB_OVERFLOW_INT* = __builtin_sub_overflow
      BUILTIN_SUB_OVERFLOW_INT64* = __builtin_sub_overflow
  when __has_builtin(__builtin_mul_overflow):
    const
      BUILTIN_MUL_OVERFLOW* = __builtin_mul_overflow
      BUILTIN_MUL_OVERFLOW_INT* = __builtin_mul_overflow
      BUILTIN_MUL_OVERFLOW_INT64* = __builtin_mul_overflow
const
  BUILTIN_ADD_OVERFLOW_INT* = atomvm_add_overflow_int
  BUILTIN_ADD_OVERFLOW_INT64* = atomvm_add_overflow_int64

import
  term

proc atomvm_add_overflow*(a: avm_int_t; b: avm_int_t; res: ptr avm_int_t): cint {.inline,
    cdecl.} =
  ##  a and b are shifted integers
  var sum: avm_int_t = (a shr 4) + (b shr 4)
  res[] = sum shl 4
  return (sum > MAX_NOT_BOXED_INT) or (sum < MIN_NOT_BOXED_INT)

proc atomvm_add_overflow_int*(a: avm_int_t; b: avm_int_t; res: ptr avm_int_t): cint {.
    inline, cdecl.} =
  var sum: avm_int64_t = cast[avm_int64_t](a) + cast[avm_int64_t](b)
  res[] = sum
  return (sum < AVM_INT_MIN) or (sum > AVM_INT_MAX)

proc atomvm_add_overflow_int64*(a: avm_int64_t; b: avm_int64_t; res: ptr avm_int64_t): cint {.
    inline, cdecl.} =
  res[] = a + b
  return 0

const
  BUILTIN_SUB_OVERFLOW_INT* = atomvm_sub_overflow_int
  BUILTIN_SUB_OVERFLOW_INT64* = atomvm_sub_overflow_int64

proc atomvm_sub_overflow*(a: avm_int_t; b: avm_int_t; res: ptr avm_int_t): cint {.inline,
    cdecl.} =
  ##  a and b are shifted integers
  var diff: avm_int_t = (a shr 4) - (b shr 4)
  res[] = diff shl 4
  return (diff > MAX_NOT_BOXED_INT) or (diff < MIN_NOT_BOXED_INT)

proc atomvm_sub_overflow_int*(a: avm_int_t; b: avm_int_t; res: ptr avm_int_t): cint {.
    inline, cdecl.} =
  var diff: avm_int64_t = cast[avm_int64_t](a) - cast[avm_int64_t](b)
  res[] = diff
  return (diff > AVM_INT_MAX) or (diff < AVM_INT_MIN)

proc atomvm_sub_overflow_int64*(a: avm_int64_t; b: avm_int64_t; res: ptr avm_int64_t): cint {.
    inline, cdecl.} =
  var diff: avm_int64_t = a - b
  res[] = diff
  return 0

const
  BUILTIN_MUL_OVERFLOW_INT* = atomvm_mul_overflow_int
  BUILTIN_MUL_OVERFLOW_INT64* = atomvm_mul_overflow_int64

import
  term

proc atomvm_mul_overflow_int*(a: avm_int_t; b: avm_int_t; res: ptr avm_int_t): cint {.
    inline, cdecl.} =
  var mul: avm_int64_t = cast[avm_int64_t](a * cast[avm_int64_t](b))
  res[] = mul
  return (mul < AVM_INT_MIN) or (mul > AVM_INT_MAX)

proc atomvm_mul_overflow_int64*(a: avm_int64_t; b: avm_int64_t; res: ptr avm_int64_t): cint {.
    inline, cdecl.} =
  if (a == 0) or (b == 0):
    res[] = 0
    return 0
  else:
    var mul_res: avm_int64_t = a * b
    res[] = mul_res
    return a != mul_res div b

proc atomvm_mul_overflow*(a: avm_int_t; b: avm_int_t; res: ptr avm_int_t): cint {.inline,
    cdecl.} =
  when AVM_INT_MAX < INT64_MAX:
    var mul: avm_int64_t = (avm_int64_t)(a shr 2) * (avm_int64_t)(b shr 2)
    res[] = mul shl 4
    return (mul > MAX_NOT_BOXED_INT) or (mul < MIN_NOT_BOXED_INT)
  elif AVM_INT_MAX == INT64_MAX:
    var mul: int64_t
    var ovf: cint = atomvm_mul_overflow_int64(a shr 2, b shr 2, addr(mul))
    res[] = mul shl 4
    return ovf or ((mul > MAX_NOT_BOXED_INT) or (mul < MIN_NOT_BOXED_INT))
  else:
