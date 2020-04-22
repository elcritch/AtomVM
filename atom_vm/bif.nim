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
  bif

when not defined(AVM_NO_FP):
import
  atom, defaultatoms, overflow_helpers, trace, utils

## Ignore warning caused by gperf generated code

import
  bifs_hash

template RAISE_ERROR*(error_type_atom: untyped): void =
  nil

##  #define RAISE_ERROR(error_type_atom) \
##      ctx->x[0] = ERROR_ATOM; \
##      ctx->x[1] = (error_type_atom); \
##      return term_invalid_term();

template VALIDATE_VALUE*(value, verify_function: untyped): void =
  nil

##  #define VALIDATE_VALUE(value, verify_function) \
##      if (UNLIKELY(!verify_function((value)))) { \
##          RAISE_ERROR(BADARG_ATOM); \
##      }

proc bif_registry_get_handler*(module: AtomString; function: AtomString; arity: cint): BifImpl {.
    cdecl.} =
  var bifname: array[MAX_BIF_NAME_LEN, char]
  atom_write_mfa(bifname, MAX_BIF_NAME_LEN, module, function, arity)
  var nameAndPtr: ptr BifNameAndPtr = in_word_set(bifname, strlen(bifname))
  if not nameAndPtr:
    return nil
  return nameAndPtr.function

proc bif_erlang_self_0*(ctx: ptr Context): term =
  return term_from_local_process_id(ctx.process_id)

proc bif_erlang_byte_size_1*(ctx: ptr Context; live: cint; arg1: term): term =
  UNUSED(live)
  VALIDATE_VALUE(arg1, term_is_binary)
  return term_from_int32(term_binary_size(arg1))

proc bif_erlang_bit_size_1*(ctx: ptr Context; live: cint; arg1: term): term =
  UNUSED(live)
  VALIDATE_VALUE(arg1, term_is_binary)
  return term_from_int32(term_binary_size(arg1) * 8)

proc bif_erlang_is_atom_1*(ctx: ptr Context; arg1: term): term =
  UNUSED(ctx)
  return if term_is_atom(arg1): TRUE_ATOM else: FALSE_ATOM

proc bif_erlang_is_binary_1*(ctx: ptr Context; arg1: term): term =
  UNUSED(ctx)
  return if term_is_binary(arg1): TRUE_ATOM else: FALSE_ATOM

proc bif_erlang_is_integer_1*(ctx: ptr Context; arg1: term): term =
  UNUSED(ctx)
  return if term_is_any_integer(arg1): TRUE_ATOM else: FALSE_ATOM

proc bif_erlang_is_list_1*(ctx: ptr Context; arg1: term): term =
  UNUSED(ctx)
  return if term_is_list(arg1): TRUE_ATOM else: FALSE_ATOM

proc bif_erlang_is_number_1*(ctx: ptr Context; arg1: term): term =
  UNUSED(ctx)
  ## TODO: change to term_is_number
  return if term_is_any_integer(arg1): TRUE_ATOM else: FALSE_ATOM

proc bif_erlang_is_pid_1*(ctx: ptr Context; arg1: term): term =
  UNUSED(ctx)
  return if term_is_pid(arg1): TRUE_ATOM else: FALSE_ATOM

proc bif_erlang_is_reference_1*(ctx: ptr Context; arg1: term): term =
  UNUSED(ctx)
  return if term_is_reference(arg1): TRUE_ATOM else: FALSE_ATOM

proc bif_erlang_is_tuple_1*(ctx: ptr Context; arg1: term): term =
  UNUSED(ctx)
  return if term_is_tuple(arg1): TRUE_ATOM else: FALSE_ATOM

proc bif_erlang_length_1*(ctx: ptr Context; live: cint; arg1: term): term =
  UNUSED(live)
  VALIDATE_VALUE(arg1, term_is_list)
  var proper: cint
  var len: avm_int_t = term_list_length(arg1, addr(proper))
  if UNLIKELY(not proper):
    RAISE_ERROR(BADARG_ATOM)
  return term_from_int(len)

proc bif_erlang_hd_1*(ctx: ptr Context; arg1: term): term =
  VALIDATE_VALUE(arg1, term_is_nonempty_list)
  return term_get_list_head(arg1)

proc bif_erlang_tl_1*(ctx: ptr Context; arg1: term): term =
  VALIDATE_VALUE(arg1, term_is_nonempty_list)
  return term_get_list_tail(arg1)

proc bif_erlang_element_2*(ctx: ptr Context; arg1: term; arg2: term): term =
  VALIDATE_VALUE(arg1, term_is_integer)
  VALIDATE_VALUE(arg2, term_is_tuple)
  ##  indexes are 1 based
  var elem_index: cint = term_to_int32(arg1) - 1
  if LIKELY((elem_index >= 0) and (elem_index < term_get_tuple_arity(arg2))):
    return term_get_tuple_element(arg2, elem_index)
  else:
    RAISE_ERROR(BADARG_ATOM)

proc bif_erlang_tuple_size_1*(ctx: ptr Context; arg1: term): term =
  VALIDATE_VALUE(arg1, term_is_tuple)
  return term_from_int32(term_get_tuple_arity(arg1))

proc make_boxed_int*(ctx: ptr Context; value: avm_int_t): term {.inline, cdecl.} =
  if UNLIKELY(memory_ensure_free(ctx, BOXED_INT_SIZE) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  return term_make_boxed_int(value, ctx)

when BOXED_TERMS_REQUIRED_FOR_INT64 > 1:
  proc make_boxed_int64*(ctx: ptr Context; value: avm_int64_t): term {.inline, cdecl.} =
    if UNLIKELY(memory_ensure_free(ctx, BOXED_INT64_SIZE) != MEMORY_GC_OK):
      RAISE_ERROR(OUT_OF_MEMORY_ATOM)
    return term_make_boxed_int64(value, ctx)

proc make_maybe_boxed_int*(ctx: ptr Context; value: avm_int_t): term {.inline, cdecl.} =
  if (value < MIN_NOT_BOXED_INT) or (value > MAX_NOT_BOXED_INT):
    return make_boxed_int(ctx, value)
  else:
    return term_from_int(value)

when BOXED_TERMS_REQUIRED_FOR_INT64 > 1:
  proc make_maybe_boxed_int64*(ctx: ptr Context; value: avm_int64_t): term {.inline,
      cdecl.} =
    if (value < AVM_INT_MIN) or (value > AVM_INT_MAX):
      return make_boxed_int64(ctx, value)
    elif (value < MIN_NOT_BOXED_INT) or (value > MAX_NOT_BOXED_INT):
      return make_boxed_int(ctx, value)
    else:
      return term_from_int(value)

proc add_overflow_helper*(ctx: ptr Context; arg1: term; arg2: term): term =
  var val1: avm_int_t = term_to_int(arg1)
  var val2: avm_int_t = term_to_int(arg2)
  return make_boxed_int(ctx, val1 + val2)

proc add_boxed_helper*(ctx: ptr Context; arg1: term; arg2: term): term =
  ##  TODO: FIXME
  when not defined(AVM_NO_FP):
    var use_float: cint = 0
  var size: cint = 0
  if term_is_boxed_integer(arg1):
    size = term_boxed_size(arg1)
  when not defined(AVM_NO_FP):
    proc `if`(arg1: term_is_float): `else` =
      use_float = 1

  proc `if`(term_is_integer: `not`): `else` =
    TRACE("error: arg1: 0x%lx, arg2: 0x%lx\n", arg1, arg2)
    RAISE_ERROR(BADARITH_ATOM)

  if term_is_boxed_integer(arg2):
    size = size or term_boxed_size(arg2)
  when not defined(AVM_NO_FP):
    proc `if`(arg2: term_is_float): `else` =
      use_float = 1

  proc `if`(term_is_integer: `not`): `else` =
    TRACE("error: arg1: 0x%lx, arg2: 0x%lx\n", arg1, arg2)
    RAISE_ERROR(BADARITH_ATOM)

  when not defined(AVM_NO_FP):
    if use_float:
      var farg1: avm_float_t = term_conv_to_float(arg1)
      var farg2: avm_float_t = term_conv_to_float(arg2)
      var fresult: avm_float_t = farg1 + farg2
      if UNLIKELY(not isfinite(fresult)):
        RAISE_ERROR(BADARITH_ATOM)
      if UNLIKELY(memory_ensure_free(ctx, FLOAT_SIZE) != MEMORY_GC_OK):
        RAISE_ERROR(OUT_OF_MEMORY_ATOM)
      return term_from_float(fresult, ctx)
  case size
  of 0:
    ## BUG
    abort()
  of 1:
    var val1: avm_int_t = term_maybe_unbox_int(arg1)
    var val2: avm_int_t = term_maybe_unbox_int(arg2)
    var res: avm_int_t
    if BUILTIN_ADD_OVERFLOW_INT(val1, val2, addr(res)):
      when BOXED_TERMS_REQUIRED_FOR_INT64 == 2:
        var res64: avm_int64_t = cast[avm_int64_t](val1) + cast[avm_int64_t](val2)
        return make_boxed_int64(ctx, res64)
      elif BOXED_TERMS_REQUIRED_FOR_INT64 == 1:
        TRACE("overflow: arg1: ", AVM_INT64_FMT, ", arg2: ", AVM_INT64_FMT, "\n",
              arg1, arg2)
        RAISE_ERROR(OVERFLOW_ATOM)
      else:
    return make_maybe_boxed_int(ctx, res)
    ##  TODO: FIXME
    ##  #if BOXED_TERMS_REQUIRED_FOR_INT64 == 2
    ##      case 2:
    ##      case 3: {
    ##          avm_int64_t val1 = term_maybe_unbox_int64(arg1);
    ##          avm_int64_t val2 = term_maybe_unbox_int64(arg2);
    ##          avm_int64_t res;
    ##          if (BUILTIN_ADD_OVERFLOW_INT64(val1, val2, &res)) {
    ##              TRACE("overflow: val1: " AVM_INT64_FMT ", val2: " AVM_INT64_FMT "\n", arg1, arg2);
    ##              RAISE_ERROR(OVERFLOW_ATOM);
    ##          }
    ##          return make_maybe_boxed_int64(ctx, res);
    ##      }
    ##  #endif
  else:
    RAISE_ERROR(OVERFLOW_ATOM)

proc bif_erlang_add_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term =
  UNUSED(live)
  if LIKELY(term_is_integer(arg1) and term_is_integer(arg2)):
    ## TODO: use long integer instead, and term_to_longint
    var res: avm_int_t
    if not BUILTIN_ADD_OVERFLOW((avm_int_t)(arg1 and not TERM_INTEGER_TAG),
                              (avm_int_t)(arg2 and not TERM_INTEGER_TAG), addr(res)):
      return res or TERM_INTEGER_TAG
    else:
      return add_overflow_helper(ctx, arg1, arg2)
  else:
    return add_boxed_helper(ctx, arg1, arg2)

proc sub_overflow_helper*(ctx: ptr Context; arg1: term; arg2: term): term =
  var val1: avm_int_t = term_to_int(arg1)
  var val2: avm_int_t = term_to_int(arg2)
  return make_boxed_int(ctx, val1 - val2)

proc sub_boxed_helper*(ctx: ptr Context; arg1: term; arg2: term): term =
  when not defined(AVM_NO_FP):
    var use_float: cint = 0
  var size: cint = 0
  if term_is_boxed_integer(arg1):
    size = term_boxed_size(arg1)
  when not defined(AVM_NO_FP):
    proc `if`(arg1: term_is_float): `else` =
      use_float = 1

  proc `if`(term_is_integer: `not`): `else` =
    TRACE("error: arg1: 0x%lx, arg2: 0x%lx\n", arg1, arg2)
    RAISE_ERROR(BADARITH_ATOM)

  if term_is_boxed_integer(arg2):
    size = size or term_boxed_size(arg2)
  when not defined(AVM_NO_FP):
    proc `if`(arg2: term_is_float): `else` =
      use_float = 1

  proc `if`(term_is_integer: `not`): `else` =
    TRACE("error: arg1: 0x%lx, arg2: 0x%lx\n", arg1, arg2)
    RAISE_ERROR(BADARITH_ATOM)

  when not defined(AVM_NO_FP):
    if use_float:
      var farg1: avm_float_t = term_conv_to_float(arg1)
      var farg2: avm_float_t = term_conv_to_float(arg2)
      var fresult: avm_float_t = farg1 - farg2
      if UNLIKELY(not isfinite(fresult)):
        RAISE_ERROR(BADARITH_ATOM)
      if UNLIKELY(memory_ensure_free(ctx, FLOAT_SIZE) != MEMORY_GC_OK):
        RAISE_ERROR(OUT_OF_MEMORY_ATOM)
      return term_from_float(fresult, ctx)
  case size
  of 0:
    ## BUG
    abort()
  of 1:
    var val1: avm_int_t = term_maybe_unbox_int(arg1)
    var val2: avm_int_t = term_maybe_unbox_int(arg2)
    var res: avm_int_t
    if BUILTIN_SUB_OVERFLOW_INT(val1, val2, addr(res)):
      when BOXED_TERMS_REQUIRED_FOR_INT64 == 2:
        var res64: avm_int64_t = cast[avm_int64_t](val1) - cast[avm_int64_t](val2)
        return make_boxed_int64(ctx, res64)
      elif BOXED_TERMS_REQUIRED_FOR_INT64 == 1:
        TRACE("overflow: arg1: ", AVM_INT64_FMT, ", arg2: ", AVM_INT64_FMT, "\n",
              arg1, arg2)
        RAISE_ERROR(OVERFLOW_ATOM)
      else:
    return make_maybe_boxed_int(ctx, res)
    ##  TODO: FIXME
    ##  #if BOXED_TERMS_REQUIRED_FOR_INT64 == 2
    ##      case 2:
    ##      case 3: {
    ##          avm_int64_t val1 = term_maybe_unbox_int64(arg1);
    ##          avm_int64_t val2 = term_maybe_unbox_int64(arg2);
    ##          avm_int64_t res;
    ##          if (BUILTIN_SUB_OVERFLOW_INT64(val1, val2, &res)) {
    ##              TRACE("overflow: val1: " AVM_INT64_FMT ", val2: " AVM_INT64_FMT "\n", arg1, arg2);
    ##              RAISE_ERROR(OVERFLOW_ATOM);
    ##          }
    ##          return make_maybe_boxed_int64(ctx, res);
    ##      }
  else:
    RAISE_ERROR(OVERFLOW_ATOM)

proc bif_erlang_sub_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term =
  UNUSED(live)
  if LIKELY(term_is_integer(arg1) and term_is_integer(arg2)):
    ## TODO: use long integer instead, and term_to_longint
    var res: avm_int_t
    if not BUILTIN_SUB_OVERFLOW((avm_int_t)(arg1 and not TERM_INTEGER_TAG),
                              (avm_int_t)(arg2 and not TERM_INTEGER_TAG), addr(res)):
      return res or TERM_INTEGER_TAG
    else:
      return sub_overflow_helper(ctx, arg1, arg2)
  else:
    return sub_boxed_helper(ctx, arg1, arg2)

proc mul_overflow_helper*(ctx: ptr Context; arg1: term; arg2: term): term =
  var val1: avm_int_t = term_to_int(arg1)
  var val2: avm_int_t = term_to_int(arg2)
  var res: avm_int_t
  when BOXED_TERMS_REQUIRED_FOR_INT64 == 2:
    var res64: avm_int64_t
  if not BUILTIN_MUL_OVERFLOW_INT(val1, val2, addr(res)):
    return make_boxed_int(ctx, res)
  else:
    RAISE_ERROR(OVERFLOW_ATOM)

proc mul_boxed_helper*(ctx: ptr Context; arg1: term; arg2: term): term =
  when not defined(AVM_NO_FP):
    var use_float: cint = 0
  var size: cint = 0
  if term_is_boxed_integer(arg1):
    size = term_boxed_size(arg1)
  when not defined(AVM_NO_FP):
    proc `if`(arg1: term_is_float): `else` =
      use_float = 1

  proc `if`(term_is_integer: `not`): `else` =
    TRACE("error: arg1: 0x%lx, arg2: 0x%lx\n", arg1, arg2)
    RAISE_ERROR(BADARITH_ATOM)

  if term_is_boxed_integer(arg2):
    size = size or term_boxed_size(arg2)
  when not defined(AVM_NO_FP):
    proc `if`(arg2: term_is_float): `else` =
      use_float = 1

  proc `if`(term_is_integer: `not`): `else` =
    TRACE("error: arg1: 0x%lx, arg2: 0x%lx\n", arg1, arg2)
    RAISE_ERROR(BADARITH_ATOM)

  when not defined(AVM_NO_FP):
    if use_float:
      var farg1: avm_float_t = term_conv_to_float(arg1)
      var farg2: avm_float_t = term_conv_to_float(arg2)
      var fresult: avm_float_t = farg1 * farg2
      if UNLIKELY(not isfinite(fresult)):
        RAISE_ERROR(BADARITH_ATOM)
      if UNLIKELY(memory_ensure_free(ctx, FLOAT_SIZE) != MEMORY_GC_OK):
        RAISE_ERROR(OUT_OF_MEMORY_ATOM)
      return term_from_float(fresult, ctx)
  case size
  of 0:
    ## BUG
    abort()
  of 1:
    var val1: avm_int_t = term_maybe_unbox_int(arg1)
    var val2: avm_int_t = term_maybe_unbox_int(arg2)
    var res: avm_int_t
    if BUILTIN_MUL_OVERFLOW_INT(val1, val2, addr(res)):
      when BOXED_TERMS_REQUIRED_FOR_INT64 == 2:
        var res64: avm_int64_t = cast[avm_int64_t](val1 * cast[avm_int64_t](val2))
        return make_boxed_int64(ctx, res64)
      elif BOXED_TERMS_REQUIRED_FOR_INT64 == 1:
        TRACE("overflow: arg1: ", AVM_INT64_FMT, ", arg2: ", AVM_INT64_FMT, "\n",
              arg1, arg2)
        RAISE_ERROR(OVERFLOW_ATOM)
      else:
    return make_maybe_boxed_int(ctx, res)
    ##  TODO: FIXME
    ##  #if BOXED_TERMS_REQUIRED_FOR_INT64 == 2
    ##      case 2:
    ##      case 3: {
    ##          avm_int64_t val1 = term_maybe_unbox_int64(arg1);
    ##          avm_int64_t val2 = term_maybe_unbox_int64(arg2);
    ##          avm_int64_t res;
    ##          if (BUILTIN_MUL_OVERFLOW_INT64(val1, val2, &res)) {
    ##              TRACE("overflow: arg1: 0x%lx, arg2: 0x%lx\n", arg1, arg2);
    ##              RAISE_ERROR(OVERFLOW_ATOM);
    ##          }
    ##          return make_maybe_boxed_int64(ctx, res);
    ##      }
    ##  #endif
  else:
    RAISE_ERROR(OVERFLOW_ATOM)

proc bif_erlang_mul_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term =
  UNUSED(live)
  if LIKELY(term_is_integer(arg1) and term_is_integer(arg2)):
    var res: avm_int_t
    var a: avm_int_t = ((avm_int_t)(arg1 and not TERM_INTEGER_TAG)) shr 2
    var b: avm_int_t = ((avm_int_t)(arg2 and not TERM_INTEGER_TAG)) shr 2
    if not BUILTIN_MUL_OVERFLOW(a, b, addr(res)):
      return res or TERM_INTEGER_TAG
    else:
      return mul_overflow_helper(ctx, arg1, arg2)
  else:
    return mul_boxed_helper(ctx, arg1, arg2)

proc div_boxed_helper*(ctx: ptr Context; arg1: term; arg2: term): term =
  var size: cint = 0
  if term_is_boxed_integer(arg1):
    size = term_boxed_size(arg1)
  elif UNLIKELY(not term_is_integer(arg1)):
    TRACE("error: arg1: 0x%lx, arg2: 0x%lx\n", arg1, arg2)
    RAISE_ERROR(BADARITH_ATOM)
  if term_is_boxed_integer(arg2):
    size = size or term_boxed_size(arg2)
  elif UNLIKELY(not term_is_integer(arg2)):
    TRACE("error: arg1: 0x%lx, arg2: 0x%lx\n", arg1, arg2)
    RAISE_ERROR(BADARITH_ATOM)
  case size
  of 0:
    ## BUG
    abort()
  of 1:
    var val1: avm_int_t = term_maybe_unbox_int(arg1)
    var val2: avm_int_t = term_maybe_unbox_int(arg2)
    if UNLIKELY(val2 == 0):
      RAISE_ERROR(BADARITH_ATOM)
    elif UNLIKELY((val2 == -1) and (val1 == AVM_INT_MIN)):
      when BOXED_TERMS_REQUIRED_FOR_INT64 == 2:
        return make_boxed_int64(ctx, -(cast[avm_int64_t](AVM_INT_MIN)))
      elif BOXED_TERMS_REQUIRED_FOR_INT64 == 1:
        TRACE("overflow: arg1: 0x%lx, arg2: 0x%lx\n", arg1, arg2)
        RAISE_ERROR(OVERFLOW_ATOM)
    else:
      return make_maybe_boxed_int(ctx, val1 div val2)
    ##  TODO: FIXME
    ##  #if BOXED_TERMS_REQUIRED_FOR_INT64 == 2
    ##  case 2:
    ##  case 3: {
    ##      avm_int64_t val1 = term_maybe_unbox_int64(arg1);
    ##      avm_int64_t val2 = term_maybe_unbox_int64(arg2);
    ##      if (UNLIKELY(val2 == 0)) {
    ##          RAISE_ERROR(BADARITH_ATOM);
    ##      } else if (UNLIKELY((val2 == -1) && (val1 == INT64_MIN))) {
    ##          TRACE("overflow: arg1: 0x%lx, arg2: 0x%lx\n", arg1, arg2);
    ##          RAISE_ERROR(OVERFLOW_ATOM);
    ##      } else {
    ##          return make_maybe_boxed_int64(ctx, val1 / val2);
    ##      }
    ##  }
    ##  #endif
  else:
    RAISE_ERROR(OVERFLOW_ATOM)

proc bif_erlang_div_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term =
  UNUSED(live)
  if LIKELY(term_is_integer(arg1) and term_is_integer(arg2)):
    var operand_b: avm_int_t = term_to_int(arg2)
    if operand_b != 0:
      var res: avm_int_t = term_to_int(arg1) div operand_b
      if UNLIKELY(res == -MIN_NOT_BOXED_INT):
        return make_boxed_int(ctx, -MIN_NOT_BOXED_INT)
      else:
        return term_from_int(res)
    else:
      RAISE_ERROR(BADARITH_ATOM)
  else:
    return div_boxed_helper(ctx, arg1, arg2)

proc neg_boxed_helper*(ctx: ptr Context; arg1: term): term =
  when not defined(AVM_NO_FP):
    if term_is_float(arg1):
      var farg1: avm_float_t = term_conv_to_float(arg1)
      var fresult: avm_float_t = -farg1
      if UNLIKELY(not isfinite(fresult)):
        RAISE_ERROR(BADARITH_ATOM)
      if UNLIKELY(memory_ensure_free(ctx, FLOAT_SIZE) != MEMORY_GC_OK):
        RAISE_ERROR(OUT_OF_MEMORY_ATOM)
      return term_from_float(fresult, ctx)
  if term_is_boxed_integer(arg1):
    case term_boxed_size(arg1)
    of 0:                      ## BUG
      abort()
    of 1:
      var val: avm_int_t = term_unbox_int(arg1)
      case val
      of (MAX_NOT_BOXED_INT + 1):
        return term_from_int(MIN_NOT_BOXED_INT)
      of AVM_INT_MIN:
        when BOXED_TERMS_REQUIRED_FOR_INT64 == 2:
          return make_boxed_int64(ctx, -(cast[avm_int64_t](val)))
        elif BOXED_TERMS_REQUIRED_FOR_INT64 == 1:
          TRACE("overflow: val: ", AVM_INT_FMT, "\n", val)
          RAISE_ERROR(OVERFLOW_ATOM)
        else:
      else:
        return make_boxed_int(ctx, -val)
      ##  TODO: FIXME
      ##  #if BOXED_TERMS_REQUIRED_FOR_INT64 == 2
      ##  case 2: {
      ##      avm_int64_t val = term_unbox_int64(arg1);
      ##      if (val == INT64_MIN) {
      ##          TRACE("overflow: arg1: " AVM_INT64_FMT "\n", arg1);
      ##          RAISE_ERROR(OVERFLOW_ATOM);
      ##      } else {
      ##          return make_boxed_int64(ctx, -val);
      ##      }
      ##  }
      ##  #endif
    else:
      RAISE_ERROR(OVERFLOW_ATOM)
  else:
    TRACE("error: arg1: 0x%lx\n", arg1)
    RAISE_ERROR(BADARITH_ATOM)

proc bif_erlang_neg_1*(ctx: ptr Context; live: cint; arg1: term): term =
  UNUSED(live)
  if LIKELY(term_is_integer(arg1)):
    var int_val: avm_int_t = term_to_int(arg1)
    if UNLIKELY(int_val == MIN_NOT_BOXED_INT):
      return make_boxed_int(ctx, -MIN_NOT_BOXED_INT)
    else:
      return term_from_int(-int_val)
  else:
    return neg_boxed_helper(ctx, arg1)

proc abs_boxed_helper*(ctx: ptr Context; arg1: term): term =
  when not defined(AVM_NO_FP):
    if term_is_float(arg1):
      var farg1: avm_float_t = term_conv_to_float(arg1)
      var fresult: avm_float_t
      when AVM_USE_SINGLE_PRECISION:
        fresult = fabsf(farg1)
      else:
        fresult = fabs(farg1)
      if UNLIKELY(not isfinite(fresult)):
        RAISE_ERROR(BADARITH_ATOM)
      if UNLIKELY(memory_ensure_free(ctx, FLOAT_SIZE) != MEMORY_GC_OK):
        RAISE_ERROR(OUT_OF_MEMORY_ATOM)
      return term_from_float(fresult, ctx)
  if term_is_boxed_integer(arg1):
    case term_boxed_size(arg1)
    of 0:                      ## BUG
      abort()
    of 1:
      var val: avm_int_t = term_unbox_int(arg1)
      if val >= 0:
        return arg1
      if val == AVM_INT_MIN:
        when BOXED_TERMS_REQUIRED_FOR_INT64 == 2:
          return make_boxed_int64(ctx, -(cast[avm_int64_t](val)))
        elif BOXED_TERMS_REQUIRED_FOR_INT64 == 1:
          TRACE("overflow: val: ", AVM_INT_FMT, "\n", val)
          RAISE_ERROR(OVERFLOW_ATOM)
        else:
      else:
        return make_boxed_int(ctx, -val)
      ##  TODO: FIXME
      ##  #if BOXED_TERMS_REQUIRED_FOR_INT64 == 2
      ##  case 2: {
      ##      avm_int64_t val = term_unbox_int64(arg1);
      ##      if (val >= 0) {
      ##          return arg1;
      ##      }
      ##      if (val == INT64_MIN) {
      ##          TRACE("overflow: val:" AVM_INT64_FMT "\n", val);
      ##          RAISE_ERROR(OVERFLOW_ATOM);
      ##      } else {
      ##          return make_boxed_int64(ctx, -val);
      ##      }
      ##  }
      ##  #endif
    else:
      RAISE_ERROR(OVERFLOW_ATOM)
  else:
    TRACE("error: arg1: 0x%lx\n", arg1)
    RAISE_ERROR(BADARG_ATOM)

proc bif_erlang_abs_1*(ctx: ptr Context; live: cint; arg1: term): term =
  UNUSED(live)
  if LIKELY(term_is_integer(arg1)):
    var int_val: avm_int_t = term_to_int(arg1)
    if int_val < 0:
      if UNLIKELY(int_val == MIN_NOT_BOXED_INT):
        return make_boxed_int(ctx, -MIN_NOT_BOXED_INT)
      else:
        return term_from_int(-int_val)
    else:
      return arg1
  else:
    return abs_boxed_helper(ctx, arg1)

proc rem_boxed_helper*(ctx: ptr Context; arg1: term; arg2: term): term =
  var size: cint = 0
  if term_is_boxed_integer(arg1):
    size = term_boxed_size(arg1)
  elif UNLIKELY(not term_is_integer(arg1)):
    TRACE("error: arg1: 0x%lx, arg2: 0x%lx\n", arg1, arg2)
    RAISE_ERROR(BADARITH_ATOM)
  if term_is_boxed_integer(arg2):
    size = size or term_boxed_size(arg2)
  elif UNLIKELY(not term_is_integer(arg2)):
    TRACE("error: arg1: 0x%lx, arg2: 0x%lx\n", arg1, arg2)
    RAISE_ERROR(BADARITH_ATOM)
  case size
  of 0:
    ## BUG
    abort()
  of 1:
    var val1: avm_int_t = term_maybe_unbox_int(arg1)
    var val2: avm_int_t = term_maybe_unbox_int(arg2)
    if UNLIKELY(val2 == 0):
      RAISE_ERROR(BADARITH_ATOM)
    return make_maybe_boxed_int(ctx, val1 mod val2)
    ##  TODO: FIXME
    ##  #if BOXED_TERMS_REQUIRED_FOR_INT64 == 2
    ##  case 2:
    ##  case 3: {
    ##      avm_int64_t val1 = term_maybe_unbox_int64(arg1);
    ##      avm_int64_t val2 = term_maybe_unbox_int64(arg2);
    ##      if (UNLIKELY(val2 == 0)) {
    ##          RAISE_ERROR(BADARITH_ATOM);
    ##      }
    ##      return make_maybe_boxed_int64(ctx, val1 % val2);
    ##  }
    ##  #endif
  else:
    RAISE_ERROR(OVERFLOW_ATOM)

proc bif_erlang_rem_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term =
  UNUSED(live)
  if LIKELY(term_is_integer(arg1) and term_is_integer(arg2)):
    var operand_b: avm_int_t = term_to_int(arg2)
    if LIKELY(operand_b != 0):
      return term_from_int(term_to_int(arg1) mod operand_b)
    else:
      RAISE_ERROR(BADARITH_ATOM)
  else:
    return rem_boxed_helper(ctx, arg1, arg2)

proc bif_erlang_ceil_1*(ctx: ptr Context; live: cint; arg1: term): term =
  UNUSED(live)
  when not defined(AVM_NO_FP):
    if term_is_float(arg1):
      var fvalue: avm_float_t = term_to_float(arg1)
      if (fvalue < INT64_MIN) or (fvalue > INT64_MAX):
        RAISE_ERROR(OVERFLOW_ATOM)
      var result: avm_int64_t
      when AVM_USE_SINGLE_PRECISION:
        result = ceilf(fvalue)
      else:
        result = ceil(fvalue)
      when BOXED_TERMS_REQUIRED_FOR_INT64 > 1:
        return make_maybe_boxed_int64(ctx, result)
      else:
        return make_maybe_boxed_int(ctx, result)
  if term_is_any_integer(arg1):
    return arg1
  else:
    RAISE_ERROR(BADARG_ATOM)

proc bif_erlang_floor_1*(ctx: ptr Context; live: cint; arg1: term): term =
  UNUSED(live)
  when not defined(AVM_NO_FP):
    if term_is_float(arg1):
      var fvalue: avm_float_t = term_to_float(arg1)
      if (fvalue < INT64_MIN) or (fvalue > INT64_MAX):
        RAISE_ERROR(OVERFLOW_ATOM)
      var result: avm_int64_t
      when AVM_USE_SINGLE_PRECISION:
        result = floorf(fvalue)
      else:
        result = floor(fvalue)
      when BOXED_TERMS_REQUIRED_FOR_INT64 > 1:
        return make_maybe_boxed_int64(ctx, result)
      else:
        return make_maybe_boxed_int(ctx, result)
  if term_is_any_integer(arg1):
    return arg1
  else:
    RAISE_ERROR(BADARG_ATOM)

proc bif_erlang_round_1*(ctx: ptr Context; live: cint; arg1: term): term =
  UNUSED(live)
  when not defined(AVM_NO_FP):
    if term_is_float(arg1):
      var fvalue: avm_float_t = term_to_float(arg1)
      if (fvalue < INT64_MIN) or (fvalue > INT64_MAX):
        RAISE_ERROR(OVERFLOW_ATOM)
      var result: avm_int64_t
      when AVM_USE_SINGLE_PRECISION:
        result = llroundf(fvalue)
      else:
        result = llround(fvalue)
      when BOXED_TERMS_REQUIRED_FOR_INT64 > 1:
        return make_maybe_boxed_int64(ctx, result)
      else:
        return make_maybe_boxed_int(ctx, result)
  if term_is_any_integer(arg1):
    return arg1
  else:
    RAISE_ERROR(BADARG_ATOM)

proc bif_erlang_trunc_1*(ctx: ptr Context; live: cint; arg1: term): term =
  UNUSED(live)
  when not defined(AVM_NO_FP):
    if term_is_float(arg1):
      var fvalue: avm_float_t = term_to_float(arg1)
      if (fvalue < INT64_MIN) or (fvalue > INT64_MAX):
        RAISE_ERROR(OVERFLOW_ATOM)
      var result: avm_int64_t
      when AVM_USE_SINGLE_PRECISION:
        result = truncf(fvalue)
      else:
        result = trunc(fvalue)
      when BOXED_TERMS_REQUIRED_FOR_INT64 > 1:
        return make_maybe_boxed_int64(ctx, result)
      else:
        return make_maybe_boxed_int(ctx, result)
  if term_is_any_integer(arg1):
    return arg1
  else:
    RAISE_ERROR(BADARG_ATOM)

type
  bitwise_op* = proc (a: int64_t; b: int64_t): int64_t {.cdecl.}

proc bitwise_helper*(ctx: ptr Context; live: cint; arg1: term; arg2: term; op: bitwise_op): term {.
    inline, cdecl.} =
  UNUSED(live)
  if UNLIKELY(not term_is_any_integer(arg1) or not term_is_any_integer(arg2)):
    RAISE_ERROR(BADARITH_ATOM)
  var a: int64_t = term_maybe_unbox_int64(arg1)
  var b: int64_t = term_maybe_unbox_int64(arg2)
  var result: int64_t = op(a, b)
  when BOXED_TERMS_REQUIRED_FOR_INT64 > 1:
    return make_maybe_boxed_int64(ctx, result)
  else:
    return make_maybe_boxed_int(ctx, result)

proc bor*(a: int64_t; b: int64_t): int64_t {.inline, cdecl.} =
  return a or b

proc bif_erlang_bor_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term =
  if LIKELY(term_is_integer(arg1) and term_is_integer(arg2)):
    return arg1 or arg2
  else:
    return bitwise_helper(ctx, live, arg1, arg2, bor)

proc band*(a: int64_t; b: int64_t): int64_t {.inline, cdecl.} =
  return a and b

proc bif_erlang_band_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term =
  if LIKELY(term_is_integer(arg1) and term_is_integer(arg2)):
    return arg1 and arg2
  else:
    return bitwise_helper(ctx, live, arg1, arg2, band)

proc bxor*(a: int64_t; b: int64_t): int64_t {.inline, cdecl.} =
  return a xor b

proc bif_erlang_bxor_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term =
  if LIKELY(term_is_integer(arg1) and term_is_integer(arg2)):
    return (arg1 xor arg2) or TERM_INTEGER_TAG
  else:
    return bitwise_helper(ctx, live, arg1, arg2, bxor)

proc bif_erlang_bsl_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term =
  UNUSED(live)
  if LIKELY(term_is_integer(arg1) and term_is_integer(arg2)):
    return term_from_int32(term_to_int32(arg1) shl term_to_int32(arg2))
  else:
    RAISE_ERROR(BADARITH_ATOM)

proc bif_erlang_bsr_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term =
  UNUSED(live)
  if LIKELY(term_is_integer(arg1) and term_is_integer(arg2)):
    return term_from_int32(term_to_int32(arg1) shr term_to_int32(arg2))
  else:
    RAISE_ERROR(BADARITH_ATOM)

proc bif_erlang_bnot_1*(ctx: ptr Context; live: cint; arg1: term): term =
  UNUSED(live)
  if LIKELY(term_is_integer(arg1)):
    return not arg1 or TERM_INTEGER_TAG
  else:
    RAISE_ERROR(BADARITH_ATOM)

proc bif_erlang_not_1*(ctx: ptr Context; arg1: term): term =
  if arg1 == TRUE_ATOM:
    return FALSE_ATOM
  elif arg1 == FALSE_ATOM:
    return TRUE_ATOM
  else:
    RAISE_ERROR(BADARG_ATOM)

proc bif_erlang_and_2*(ctx: ptr Context; arg1: term; arg2: term): term =
  if (arg1 == FALSE_ATOM) and (arg2 == FALSE_ATOM):
    return FALSE_ATOM
  elif (arg1 == FALSE_ATOM) and (arg2 == TRUE_ATOM):
    return FALSE_ATOM
  elif (arg1 == TRUE_ATOM) and (arg2 == FALSE_ATOM):
    return FALSE_ATOM
  elif (arg1 == TRUE_ATOM) and (arg2 == TRUE_ATOM):
    return TRUE_ATOM
  else:
    RAISE_ERROR(BADARG_ATOM)

proc bif_erlang_or_2*(ctx: ptr Context; arg1: term; arg2: term): term =
  if (arg1 == FALSE_ATOM) and (arg2 == FALSE_ATOM):
    return FALSE_ATOM
  elif (arg1 == FALSE_ATOM) and (arg2 == TRUE_ATOM):
    return TRUE_ATOM
  elif (arg1 == TRUE_ATOM) and (arg2 == FALSE_ATOM):
    return TRUE_ATOM
  elif (arg1 == TRUE_ATOM) and (arg2 == TRUE_ATOM):
    return TRUE_ATOM
  else:
    RAISE_ERROR(BADARG_ATOM)

proc bif_erlang_xor_2*(ctx: ptr Context; arg1: term; arg2: term): term =
  if (arg1 == FALSE_ATOM) and (arg2 == FALSE_ATOM):
    return FALSE_ATOM
  elif (arg1 == FALSE_ATOM) and (arg2 == TRUE_ATOM):
    return TRUE_ATOM
  elif (arg1 == TRUE_ATOM) and (arg2 == FALSE_ATOM):
    return TRUE_ATOM
  elif (arg1 == TRUE_ATOM) and (arg2 == TRUE_ATOM):
    return FALSE_ATOM
  else:
    RAISE_ERROR(BADARG_ATOM)

proc bif_erlang_equal_to_2*(ctx: ptr Context; arg1: term; arg2: term): term =
  UNUSED(ctx)
  if term_equals(arg1, arg2, ctx):
    return TRUE_ATOM
  else:
    return FALSE_ATOM

proc bif_erlang_not_equal_to_2*(ctx: ptr Context; arg1: term; arg2: term): term =
  UNUSED(ctx)
  ## TODO: fix this implementation
  ## it should compare any kind of type, and 5.0 != 5 is false
  if not term_equals(arg1, arg2, ctx):
    return TRUE_ATOM
  else:
    return FALSE_ATOM

proc bif_erlang_exactly_equal_to_2*(ctx: ptr Context; arg1: term; arg2: term): term {.
    cdecl.} =
  UNUSED(ctx)
  ## TODO: 5.0 != 5
  if term_equals(arg1, arg2, ctx):
    return TRUE_ATOM
  else:
    return FALSE_ATOM

proc bif_erlang_exactly_not_equal_to_2*(ctx: ptr Context; arg1: term; arg2: term): term {.
    cdecl.} =
  UNUSED(ctx)
  ## TODO: 5.0 != 5
  if not term_equals(arg1, arg2, ctx):
    return TRUE_ATOM
  else:
    return FALSE_ATOM

proc bif_erlang_greater_than_2*(ctx: ptr Context; arg1: term; arg2: term): term =
  UNUSED(ctx)
  if term_compare(arg1, arg2, ctx) > 0:
    return TRUE_ATOM
  else:
    return FALSE_ATOM

proc bif_erlang_less_than_2*(ctx: ptr Context; arg1: term; arg2: term): term =
  UNUSED(ctx)
  if term_compare(arg1, arg2, ctx) < 0:
    return TRUE_ATOM
  else:
    return FALSE_ATOM

proc bif_erlang_less_than_or_equal_2*(ctx: ptr Context; arg1: term; arg2: term): term {.
    cdecl.} =
  UNUSED(ctx)
  if term_compare(arg1, arg2, ctx) <= 0:
    return TRUE_ATOM
  else:
    return FALSE_ATOM

proc bif_erlang_greater_than_or_equal_2*(ctx: ptr Context; arg1: term; arg2: term): term {.
    cdecl.} =
  UNUSED(ctx)
  if term_compare(arg1, arg2, ctx) >= 0:
    return TRUE_ATOM
  else:
    return FALSE_ATOM
