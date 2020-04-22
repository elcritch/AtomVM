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

const
  _GNU_SOURCE* = true

import
  nifs, atomshashtable, avmpack, context, defaultatoms, interop, mailbox, module, port,
  platform_nifs, scheduler, term, utils, sys, version, externalterm

const
  MAX_NIF_NAME_LEN* = 260
  FLOAT_BUF_SIZE* = 64

##  TODO: FIXME

template VALIDATE_VALUE*(value, verify_function: untyped): void =
  nil

##  #define VALIDATE_VALUE(value, verify_function) \
##      if (UNLIKELY(!verify_function((value)))) { \
##          argv[0] = ERROR_ATOM; \
##          argv[1] = BADARG_ATOM; \
##          return term_invalid_term(); \
##      } \
##  TODO: FIXME

template RAISE_ERROR*(error_type_atom: untyped): void =
  nil

##  #define RAISE_ERROR(error_type_atom) \
##      ctx->x[0] = ERROR_ATOM; \
##      ctx->x[1] = (error_type_atom); \
##      return term_invalid_term();

template MAX*(x, y: untyped): untyped =
  (if ((x) > (y)): (x) else: (y))

when defined(ENABLE_ADVANCED_TRACE):
  var trace_calls_atom*: cstring = "\vtrace_calls"
  var trace_call_args_atom*: cstring = "\x0Ftrace_call_args"
  var trace_returns_atom*: cstring = "\ctrace_returns"
  var trace_send_atom*: cstring = "\ntrace_send"
  var trace_receive_atom*: cstring = "\ctrace_receive"
proc process_echo_mailbox*(ctx: ptr Context) {.cdecl.}
proc process_console_mailbox*(ctx: ptr Context) {.cdecl.}
proc binary_to_atom*(ctx: ptr Context; argc: cint; argv: ptr term; create_new: cint): term {.
    cdecl.}
proc list_to_atom*(ctx: ptr Context; argc: cint; argv: ptr term; create_new: cint): term {.
    cdecl.}
proc nif_binary_at_2*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_binary_first_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_binary_last_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_binary_part_3*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_binary_split_2*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_delete_element_2*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_atom_to_binary_2*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_atom_to_list_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_binary_to_atom_2*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_binary_to_float_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_binary_to_integer_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_binary_to_list_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_binary_to_existing_atom_2*(ctx: ptr Context; argc: cint;
    argv: ptr term): term {.cdecl.}
proc nif_erlang_concat_2*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_display_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_error*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_make_fun_3*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_make_ref_0*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_make_tuple_2*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_insert_element_3*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_integer_to_binary_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_integer_to_list_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_is_process_alive_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_float_to_binary*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_float_to_list*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_list_to_binary_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_list_to_integer_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_list_to_float_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_list_to_atom_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_list_to_existing_atom_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_iolist_size_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_iolist_to_binary_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_open_port_2*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_register_2*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_send_2*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_setelement_3*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_spawn*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_spawn_fun*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_whereis_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_system_time_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_tuple_to_list_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_universaltime_0*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_timestamp_0*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erts_debug_flat_size*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_process_flag*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_processes*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_process_info*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_system_info*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_binary_to_term*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_term_to_binary*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.}
proc nif_erlang_throw*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_pid_to_list*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_ref_to_list*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_erlang_fun_to_list*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
proc nif_atomvm_read_priv*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
##  TODO: FIXME
##
## static const struct Nif binary_at_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_binary_at_2
## };
##
## static const struct Nif binary_first_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_binary_first_1
## };
##
## static const struct Nif binary_last_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_binary_last_1
## };
##
## static const struct Nif binary_part_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_binary_part_3
## };
##
## static const struct Nif binary_split_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_binary_split_2
## };
##
## static const struct Nif make_ref_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_make_ref_0
## };
##
## static const struct Nif atom_to_binary_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_atom_to_binary_2
## };
##
## static const struct Nif atom_to_list_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_atom_to_list_1
## };
##
## static const struct Nif binary_to_atom_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_binary_to_atom_2
## };
##
## static const struct Nif binary_to_float_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_binary_to_float_1
## };
##
## static const struct Nif binary_to_integer_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_binary_to_integer_1
## };
##
## static const struct Nif binary_to_list_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_binary_to_list_1
## };
##
## static const struct Nif binary_to_existing_atom_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_binary_to_existing_atom_2
## };
##
## static const struct Nif delete_element_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_delete_element_2
## };
##
## static const struct Nif display_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_display_1
## };
##
## static const struct Nif error_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_error
## };
##
## static const struct Nif insert_element_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_insert_element_3
## };
##
## static const struct Nif integer_to_binary_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_integer_to_binary_1
## };
##
## static const struct Nif integer_to_list_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_integer_to_list_1
## };
##
## static const struct Nif float_to_binary_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_float_to_binary
## };
##
## static const struct Nif float_to_list_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_float_to_list
## };
##
## static const struct Nif is_process_alive_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_is_process_alive_1
## };
##
## static const struct Nif list_to_atom_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_list_to_atom_1
## };
##
## static const struct Nif list_to_existing_atom_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_list_to_existing_atom_1
## };
##
## static const struct Nif list_to_binary_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_list_to_binary_1
## };
##
## static const struct Nif list_to_integer_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_list_to_integer_1
## };
##
## static const struct Nif list_to_float_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_list_to_float_1
## };
##
## static const struct Nif iolist_size_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_iolist_size_1
## };
##
## static const struct Nif iolist_to_binary_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_iolist_to_binary_1
## };
##
## static const struct Nif open_port_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_open_port_2
## };
##
## static const struct Nif make_tuple_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_make_tuple_2
## };
##
## static const struct Nif register_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_register_2
## };
##
## static const struct Nif spawn_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_spawn
## };
##
## static const struct Nif spawn_opt_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_spawn
## };
##
## static const struct Nif spawn_fun_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_spawn_fun
## };
##
## static const struct Nif spawn_fun_opt_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_spawn_fun
## };
##
## static const struct Nif send_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_send_2
## };
##
## static const struct Nif setelement_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_setelement_3
## };
##
## static const struct Nif whereis_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_whereis_1
## };
##
## static const struct Nif concat_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_concat_2
## };
##
## static const struct Nif system_time_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_system_time_1
## };
##
## static const struct Nif universaltime_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_universaltime_0
## };
##
## static const struct Nif timestamp_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_timestamp_0
## };
##
## static const struct Nif tuple_to_list_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_tuple_to_list_1
## };
##
## static const struct Nif flat_size_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erts_debug_flat_size
## };
##
## static const struct Nif process_flag_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_process_flag
## };
##
## static const struct Nif processes_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_processes
## };
##
## static const struct Nif process_info_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_process_info
## };
##
## static const struct Nif system_info_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_system_info
## };
##
## static const struct Nif binary_to_term_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_binary_to_term
## };
##
## static const struct Nif term_to_binary_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_term_to_binary
## };
##
## static const struct Nif throw_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_throw
## };
##
## static const struct Nif pid_to_list_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_pid_to_list
## };
##
## static const struct Nif ref_to_list_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_ref_to_list
## };
##
## static const struct Nif fun_to_list_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_fun_to_list
## };
##
## static const struct Nif make_fun_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_erlang_make_fun_3
## };
##
## static const struct Nif atomvm_read_priv_nif =
## {
##     .base.type = NIFFunctionType,
##     .nif_ptr = nif_atomvm_read_priv
## };
##
## Ignore warning caused by gperf generated code

import
  nifs_hash

proc nifs_get*(module: AtomString; function: AtomString; arity: cint): ptr Nif =
  var nifname: array[MAX_NIF_NAME_LEN, char]
  var module_name_len: cint = atom_string_len(module)
  memcpy(nifname, atom_string_data(module), module_name_len)
  nifname[module_name_len] = ':'
  var function_name_len: cint = atom_string_len(function)
  if UNLIKELY((arity > 9) or
      (module_name_len + function_name_len + 4 > MAX_NIF_NAME_LEN)):
    abort()
  memcpy(nifname + module_name_len + 1, atom_string_data(function), function_name_len)
  ## TODO: handle NIFs with more than 9 parameters
  nifname[module_name_len + function_name_len + 1] = '/'
  nifname[module_name_len + function_name_len + 2] = '0' + arity
  nifname[module_name_len + function_name_len + 3] = 0
  var nameAndPtr: ptr NifNameAndNifPtr = nif_in_word_set(nifname, strlen(nifname))
  if not nameAndPtr:
    return platform_nifs_get_nif(nifname)
  return nameAndPtr.nif

proc make_maybe_boxed_int64*(ctx: ptr Context; value: avm_int64): term  =
  when BOXED_TERMS_REQUIRED_FOR_INT64 == 2:
    if (value < AVM_INT_MIN) or (value > AVM_INT_MAX):
      if UNLIKELY(memory_ensure_free(ctx, BOXED_INT64_SIZE) != MEMORY_GC_OK):
        RAISE_ERROR(OUT_OF_MEMORY_ATOM)
      return term_make_boxed_int64(value, ctx)
  if (value < MIN_NOT_BOXED_INT) or (value > MAX_NOT_BOXED_INT):
    if UNLIKELY(memory_ensure_free(ctx, BOXED_INT_SIZE) != MEMORY_GC_OK):
      RAISE_ERROR(OUT_OF_MEMORY_ATOM)
    return term_make_boxed_int(value, ctx)
  else:
    return term_from_int(value)

proc nif_erlang_iolist_size_1*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var ok: cint
  var size: avm_int = interop_iolist_size(argv[0], addr(ok))
  if ok:
    return term_from_int(size)
  else:
    RAISE_ERROR(BADARG_ATOM)

proc nif_erlang_iolist_to_binary_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  var t: term = argv[0]
  if term_is_binary(t):
    return t
  var ok: cint
  var bin_size: cint = interop_iolist_size(t, addr(ok))
  if not ok:
    RAISE_ERROR(BADARG_ATOM)
  var bin_buf: cstring = malloc(bin_size)
  if IS_NULL_PTR(bin_buf):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  if UNLIKELY(not interop_write_iolist(t, bin_buf)):
    RAISE_ERROR(BADARG_ATOM)
  if UNLIKELY(memory_ensure_free(ctx, term_binary_data_size_in_terms(bin_size) +
      BINARY_HEADER_SIZE) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var bin_res: term = term_from_literal_binary(bin_buf, bin_size, ctx)
  free(bin_buf)
  return bin_res

proc nif_erlang_open_port_2*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var port_name_tuple: term = argv[0]
  VALIDATE_VALUE(port_name_tuple, term_is_tuple)
  var opts: term = argv[1]
  VALIDATE_VALUE(opts, term_is_list)
  if UNLIKELY(term_get_tuple_arity(port_name_tuple) != 2):
    RAISE_ERROR(BADARG_ATOM)
  var t: term = term_get_tuple_element(port_name_tuple, 1)
  ## TODO: validate port name
  var ok: cint
  var driver_name: cstring = interop_term_to_string(t, addr(ok))
  if UNLIKELY(not ok):
    ## TODO: handle atoms here
    RAISE_ERROR(BADARG_ATOM)
  var new_ctx: ptr Context = nil
  if not strcmp("echo", driver_name):
    new_ctx = context_new(ctx.global)
    new_ctx.native_handler = process_echo_mailbox
  elif not strcmp("console", driver_name):
    new_ctx = context_new(ctx.global)
    new_ctx.native_handler = process_console_mailbox
  if not new_ctx:
    new_ctx = sys_create_port(ctx.global, driver_name, opts)
  free(driver_name)
  if not new_ctx:
    RAISE_ERROR(BADARG_ATOM)
  else:
    scheduler_make_waiting(ctx.global, new_ctx)
    return term_from_local_process_id(new_ctx.process_id)

proc nif_erlang_register_2*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var reg_name_term: term = argv[0]
  VALIDATE_VALUE(reg_name_term, term_is_atom)
  var pid_or_port_term: term = argv[1]
  VALIDATE_VALUE(pid_or_port_term, term_is_pid)
  var atom_index: cint = term_to_atom_index(reg_name_term)
  var pid: cint = term_to_local_process_id(pid_or_port_term)
  ##  TODO: pid must be existing, not already registered.
  ##  TODO: reg_name_term must not be the atom undefined and not already registered.
  globalcontext_register_process(ctx.global, atom_index, pid)
  return term_nil()

proc nif_erlang_whereis_1*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var reg_name_term: term = argv[0]
  VALIDATE_VALUE(reg_name_term, term_is_atom)
  var atom_index: cint = term_to_atom_index(reg_name_term)
  var local_process_id: cint = globalcontext_get_registered_process(ctx.global,
      atom_index)
  if local_process_id:
    return term_from_local_process_id(local_process_id)
  else:
    return UNDEFINED_ATOM

proc process_echo_mailbox*(ctx: ptr Context) =
  var msg: ptr Message = mailbox_dequeue(ctx)
  var pid: term = term_get_tuple_element(msg.message, 0)
  var val: term = term_get_tuple_element(msg.message, 1)
  var local_process_id: cint = term_to_local_process_id(pid)
  var target: ptr Context = globalcontext_get_process(ctx.global, local_process_id)
  mailbox_send(target, val)
  free(msg)

proc process_console_mailbox*(ctx: ptr Context) =
  var message: ptr Message = mailbox_dequeue(ctx)
  var msg: term = message.message
  port_ensure_available(ctx, 12)
  if port_is_standard_port_command(msg):
    var pid: term = term_get_tuple_element(msg, 0)
    var `ref`: term = term_get_tuple_element(msg, 1)
    var cmd: term = term_get_tuple_element(msg, 2)
    if term_is_atom(cmd) and cmd == FLUSH_ATOM:
      fflush(stdout)
      port_send_reply(ctx, pid, `ref`, OK_ATOM)
    elif term_is_tuple(cmd) and term_get_tuple_arity(cmd) == 2:
      var cmd_name: term = term_get_tuple_element(cmd, 0)
      if cmd_name == PUTS_ATOM:
        var ok: cint
        var str: cstring = interop_term_to_string(term_get_tuple_element(cmd, 1),
            addr(ok))
        if UNLIKELY(not ok):
          var error: term = port_create_error_tuple(ctx, BADARG_ATOM)
          port_send_reply(ctx, pid, `ref`, error)
        else:
          printf("%s", str)
          port_send_reply(ctx, pid, `ref`, OK_ATOM)
        free(str)
      else:
        var error: term = port_create_error_tuple(ctx, BADARG_ATOM)
        port_send_reply(ctx, pid, `ref`, error)
    else:
      port_send_reply(ctx, pid, `ref`, port_create_error_tuple(ctx, BADARG_ATOM))
  else:
    fprintf(stderr, "WARNING: Invalid port command.  Unable to send reply")
  free(message)

proc nif_erlang_spawn_fun*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  var fun_term: term = argv[0]
  var opts_term: term = argv[1]
  VALIDATE_VALUE(fun_term, term_is_function)
  if argc == 2:
    ##  spawn_opt has been called
    VALIDATE_VALUE(opts_term, term_is_list)
  else:
    ##  regular spawn
    opts_term = term_nil()
  var new_ctx: ptr Context = context_new(ctx.global)
  var boxed_value: ptr term = term_to_const_term_ptr(fun_term)
  var fun_module: ptr Module = cast[ptr Module](boxed_value[1])
  var index_or_module: term = boxed_value[2]
  if term_is_atom(index_or_module):
    ##  it is not possible to spawn a function reference except for those having
    ##  0 arity, however right now they are not supported.
    ##  TODO: implement for funs having arity 0.
    abort()
  var fun_index: uint32 = term_to_int32(index_or_module)
  var label: uint32
  var arity: uint32
  var n_freeze: uint32
  module_get_fun(fun_module, fun_index, addr(label), addr(arity), addr(n_freeze))
  ##  TODO: new process should fail with badarity if arity != 0
  var size: cint = 0
  var i: uint32 = 0
  while i < n_freeze:
    inc(size, memory_estimate_usage(boxed_value[i + 3]))
    inc(i)
  if UNLIKELY(memory_ensure_free(new_ctx, size) != MEMORY_GC_OK):
    ## TODO: new process should be terminated, however a new pid is returned anyway
    fprintf(stderr, "Unable to allocate sufficient memory to spawn process.\n")
    abort()
  var i: uint32 = 0
  while i < n_freeze:
    new_ctx.x[i + arity - n_freeze] = memory_copy_term_tree(addr(new_ctx.heap_ptr),
        boxed_value[i + 3])
    inc(i)
  new_ctx.saved_module = fun_module
  new_ctx.saved_ip = fun_module.labels[label]
  new_ctx.cp = module_address(fun_module.module_index,
                            fun_module.end_instruction_ii)
  var max_heap_size_term: term = interop_proplist_get_value(opts_term,
      MAX_HEAP_SIZE_ATOM)
  if max_heap_size_term != term_nil():
    new_ctx.has_max_heap_size = 1
    ## TODO: check type, make sure max_heap_size_term is an int32
    new_ctx.max_heap_size = term_to_int(max_heap_size_term)
  return term_from_local_process_id(new_ctx.process_id)

proc nif_erlang_spawn*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  var module_term: term = argv[0]
  var function_term: term = argv[1]
  var args_term: term = argv[2]
  var opts_term: term = argv[3]
  VALIDATE_VALUE(module_term, term_is_atom)
  VALIDATE_VALUE(function_term, term_is_atom)
  VALIDATE_VALUE(args_term, term_is_list)
  if argc == 4:
    ##  TODO: FIXME
    ##  spawn_opt has been called
    VALIDATE_VALUE(opts_term, term_is_list)
  else:
    ##  TODO: FIXME
    ##  regular spawn
    opts_term = term_nil()
  var new_ctx: ptr Context = context_new(ctx.global)
  var module_string: AtomString = globalcontext_atomstring_from_term(ctx.global,
      argv[0])
  var function_string: AtomString = globalcontext_atomstring_from_term(ctx.global,
      argv[1])
  var found_module: ptr Module = globalcontext_get_module(ctx.global, module_string)
  if UNLIKELY(not found_module):
    return UNDEFINED_ATOM
  var proper: cint
  var args_len: cint = term_list_length(argv[2], addr(proper))
  if UNLIKELY(not proper):
    RAISE_ERROR(BADARG_ATOM)
  var label: cint = module_search_exported_function(found_module, function_string,
      args_len)
  ## TODO: fail here if no function has been found
  new_ctx.saved_module = found_module
  new_ctx.saved_ip = found_module.labels[label]
  new_ctx.cp = module_address(found_module.module_index,
                            found_module.end_instruction_ii)
  var min_heap_size_term: term = interop_proplist_get_value(opts_term,
      MIN_HEAP_SIZE_ATOM)
  var max_heap_size_term: term = interop_proplist_get_value(opts_term,
      MAX_HEAP_SIZE_ATOM)
  if min_heap_size_term != term_nil():
    if UNLIKELY(not term_is_integer(min_heap_size_term)):
      ## TODO: gracefully handle this error
      abort()
    new_ctx.has_min_heap_size = 1
    new_ctx.min_heap_size = term_to_int(min_heap_size_term)
  else:
    min_heap_size_term = term_from_int(0)
  if max_heap_size_term != term_nil():
    if UNLIKELY(not term_is_integer(max_heap_size_term)):
      ## TODO: gracefully handle this error
      abort()
    new_ctx.has_max_heap_size = 1
    new_ctx.max_heap_size = term_to_int(max_heap_size_term)
  if new_ctx.has_min_heap_size and new_ctx.has_max_heap_size:
    if term_to_int(min_heap_size_term) > term_to_int(max_heap_size_term):
      RAISE_ERROR(BADARG_ATOM)
  var reg_index: cint = 0
  var t: term = argv[2]
  var size: avm_int = MAX(cast[culong](term_to_int(min_heap_size_term)),
                        memory_estimate_usage(t))
  if UNLIKELY(memory_ensure_free(new_ctx, size) != MEMORY_GC_OK):
    ## TODO: new process should be terminated, however a new pid is returned anyway
    fprintf(stderr, "Unable to allocate sufficient memory to spawn process.\n")
    abort()
  while term_is_nonempty_list(t):
    new_ctx.x[reg_index] = memory_copy_term_tree(addr(new_ctx.heap_ptr),
        term_get_list_head(t))
    inc(reg_index)
    t = term_get_list_tail(t)
    if not term_is_list(t):
      RAISE_ERROR(BADARG_ATOM)
  return term_from_local_process_id(new_ctx.process_id)

proc nif_erlang_send_2*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var pid_term: term = argv[0]
  VALIDATE_VALUE(pid_term, term_is_pid)
  var local_process_id: cint = term_to_local_process_id(pid_term)
  var target: ptr Context = globalcontext_get_process(ctx.global, local_process_id)
  mailbox_send(target, argv[1])
  return argv[1]

proc nif_erlang_is_process_alive_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  var local_process_id: cint = term_to_local_process_id(argv[0])
  var target: ptr Context = globalcontext_get_process(ctx.global, local_process_id)
  return if target: TRUE_ATOM else: FALSE_ATOM

proc nif_erlang_concat_2*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var prepend_list: term = argv[0]
  if UNLIKELY(not term_is_nonempty_list(prepend_list)):
    if term_is_nil(prepend_list):
      return argv[1]
    else:
      RAISE_ERROR(BADARG_ATOM)
  var proper: cint
  var len: cint = term_list_length(prepend_list, addr(proper))
  if UNLIKELY(not proper):
    RAISE_ERROR(BADARG_ATOM)
  if UNLIKELY(memory_ensure_free(ctx, len * 2) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  prepend_list = argv[0]
  var append_list: term = argv[1]
  var t: term = prepend_list
  var list_begin: term = term_nil()
  var prev_term: ptr term = nil
  while term_is_nonempty_list(t):
    var head: term = term_get_list_head(t)
    var new_list_item: ptr term = term_list_alloc(ctx)
    if prev_term:
      prev_term[0] = term_list_from_list_ptr(new_list_item)
    else:
      list_begin = term_list_from_list_ptr(new_list_item)
    prev_term = new_list_item
    new_list_item[1] = head
    t = term_get_list_tail(t)
  if prev_term:
    prev_term[0] = append_list
  return list_begin

proc nif_erlang_make_ref_0*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  UNUSED(argv)
  ##  a ref is 64 bits, hence 8 bytes
  if UNLIKELY(memory_ensure_free(ctx, (8 div TERM_BYTES) + 1) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var ref_ticks: uint64 = globalcontext_get_ref_ticks(ctx.global)
  return term_from_ref_ticks(ref_ticks, ctx)

proc nif_erlang_system_time_1*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(ctx)
  UNUSED(argc)
  var ts: timespec
  sys_time(addr(ts))
  var second_atom: term = context_make_atom(ctx, "\x06second")
  if argv[0] == second_atom:
    return make_maybe_boxed_int64(ctx, ts.tv_sec)
  elif argv[0] == context_make_atom(ctx, "\vmillisecond"):
    return make_maybe_boxed_int64(ctx, (cast[int64](ts.tv_sec)) * 1000 +
        ts.tv_nsec div 1000000)
  else:
    RAISE_ERROR(BADARG_ATOM)

proc nif_erlang_universaltime_0*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(ctx)
  UNUSED(argc)
  UNUSED(argv)
  ##  4 = size of date/time tuple, 3 size of date time tuple
  if UNLIKELY(memory_ensure_free(ctx, 3 + 4 + 4) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var date_tuple: term = term_alloc_tuple(3, ctx)
  var time_tuple: term = term_alloc_tuple(3, ctx)
  var date_time_tuple: term = term_alloc_tuple(2, ctx)
  var ts: timespec
  sys_time(addr(ts))
  var broken_down_time: tm
  gmtime_r(addr(ts.tv_sec), addr(broken_down_time))
  term_put_tuple_element(date_tuple, 0,
                         term_from_int32(1900 + broken_down_time.tm_year))
  term_put_tuple_element(date_tuple, 1,
                         term_from_int32(broken_down_time.tm_mon + 1))
  term_put_tuple_element(date_tuple, 2, term_from_int32(broken_down_time.tm_mday))
  term_put_tuple_element(time_tuple, 0, term_from_int32(broken_down_time.tm_hour))
  term_put_tuple_element(time_tuple, 1, term_from_int32(broken_down_time.tm_min))
  term_put_tuple_element(time_tuple, 2, term_from_int32(broken_down_time.tm_sec))
  term_put_tuple_element(date_time_tuple, 0, date_tuple)
  term_put_tuple_element(date_time_tuple, 1, time_tuple)
  return date_time_tuple

proc nif_erlang_timestamp_0*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(ctx)
  UNUSED(argc)
  UNUSED(argv)
  if UNLIKELY(memory_ensure_free(ctx, 4) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var timestamp_tuple: term = term_alloc_tuple(3, ctx)
  var ts: timespec
  sys_time(addr(ts))
  term_put_tuple_element(timestamp_tuple, 0,
                         term_from_int32(ts.tv_sec div 1000000))
  term_put_tuple_element(timestamp_tuple, 1,
                         term_from_int32(ts.tv_sec mod 1000000))
  term_put_tuple_element(timestamp_tuple, 2, term_from_int32(ts.tv_nsec div 1000))
  return timestamp_tuple

proc nif_erlang_make_tuple_2*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  VALIDATE_VALUE(argv[0], term_is_integer)
  var count_elem: avm_int = term_to_int(argv[0])
  if UNLIKELY(count_elem < 0):
    RAISE_ERROR(BADARG_ATOM)
  if UNLIKELY(memory_ensure_free(ctx, count_elem + 1) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var new_tuple: term = term_alloc_tuple(count_elem, ctx)
  var element: term = argv[1]
  var i: cint = 0
  while i < count_elem:
    term_put_tuple_element(new_tuple, i, element)
    inc(i)
  return new_tuple

proc nif_erlang_insert_element_3*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  VALIDATE_VALUE(argv[0], term_is_integer)
  VALIDATE_VALUE(argv[1], term_is_tuple)
  ##  indexes are 1 based
  var insert_index: avm_int = term_to_int(argv[0]) - 1
  var old_tuple_size: cint = term_get_tuple_arity(argv[1])
  if UNLIKELY((insert_index > old_tuple_size) or (insert_index < 0)):
    RAISE_ERROR(BADARG_ATOM)
  var new_tuple_size: cint = old_tuple_size + 1
  if UNLIKELY(memory_ensure_free(ctx, new_tuple_size + 1) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var new_tuple: term = term_alloc_tuple(new_tuple_size, ctx)
  var old_tuple: term = argv[1]
  var new_element: term = argv[2]
  var src_elements_shift: cint = 0
  var i: cint = 0
  while i < new_tuple_size:
    if i == insert_index:
      src_elements_shift = 1
      term_put_tuple_element(new_tuple, i, new_element)
    else:
      term_put_tuple_element(new_tuple, i, term_get_tuple_element(old_tuple,
          i - src_elements_shift))
    inc(i)
  return new_tuple

proc nif_erlang_delete_element_2*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  VALIDATE_VALUE(argv[0], term_is_integer)
  VALIDATE_VALUE(argv[1], term_is_tuple)
  ##  indexes are 1 based
  var delete_index: avm_int = term_to_int(argv[0]) - 1
  var old_tuple_size: cint = term_get_tuple_arity(argv[1])
  if UNLIKELY((delete_index > old_tuple_size) or (delete_index < 0)):
    RAISE_ERROR(BADARG_ATOM)
  var new_tuple_size: cint = old_tuple_size - 1
  if UNLIKELY(memory_ensure_free(ctx, new_tuple_size + 1) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var new_tuple: term = term_alloc_tuple(new_tuple_size, ctx)
  var old_tuple: term = argv[1]
  var src_elements_shift: cint = 0
  var i: cint = 0
  while i < new_tuple_size:
    if i == delete_index:
      src_elements_shift = 1
    term_put_tuple_element(new_tuple, i, term_get_tuple_element(old_tuple,
        i + src_elements_shift))
    inc(i)
  return new_tuple

proc nif_erlang_setelement_3*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  VALIDATE_VALUE(argv[0], term_is_integer)
  VALIDATE_VALUE(argv[1], term_is_tuple)
  ##  indexes are 1 based
  var replace_index: avm_int = term_to_int(argv[0]) - 1
  var tuple_size: cint = term_get_tuple_arity(argv[1])
  if UNLIKELY((replace_index >= tuple_size) or (replace_index < 0)):
    RAISE_ERROR(BADARG_ATOM)
  if UNLIKELY(memory_ensure_free(ctx, tuple_size + 1) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var new_tuple: term = term_alloc_tuple(tuple_size, ctx)
  var old_tuple: term = argv[1]
  var i: cint = 0
  while i < tuple_size:
    term_put_tuple_element(new_tuple, i, term_get_tuple_element(old_tuple, i))
    inc(i)
  var value: term = argv[2]
  term_put_tuple_element(new_tuple, replace_index, value)
  return new_tuple

proc nif_erlang_tuple_to_list_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  VALIDATE_VALUE(argv[0], term_is_tuple)
  var tuple_size: cint = term_get_tuple_arity(argv[0])
  if UNLIKELY(memory_ensure_free(ctx, tuple_size * 2) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var `tuple`: term = argv[0]
  var prev: term = term_nil()
  var i: cint = tuple_size - 1
  while i >= 0:
    prev = term_list_prepend(term_get_tuple_element(`tuple`, i), prev, ctx)
    dec(i)
  return prev

proc nif_erlang_binary_to_atom_2*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  return binary_to_atom(ctx, argc, argv, 1)

proc nif_erlang_binary_to_integer_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  var bin_term: term = argv[0]
  VALIDATE_VALUE(bin_term, term_is_binary)
  var bin_data: cstring = term_binary_data(bin_term)
  var bin_data_size: cint = term_binary_size(bin_term)
  if UNLIKELY((bin_data_size == 0) or (bin_data_size >= 24)):
    RAISE_ERROR(BADARG_ATOM)
  var null_terminated_buf: array[24, char]
  memcpy(null_terminated_buf, bin_data, bin_data_size)
  null_terminated_buf[bin_data_size] = '\x00'
  ## TODO: handle 64 bits numbers
  ## TODO: handle errors
  var endptr: cstring
  var value: uint64 = strtoll(null_terminated_buf, addr(endptr), 10)
  if endptr[] != '\x00':
    RAISE_ERROR(BADARG_ATOM)
  return make_maybe_boxed_int64(ctx, value)

when not defined(AVM_NO_FP):
  proc is_valid_float_string*(str: cstring; len: cint): cint =
    var has_point: cint = 0
    var scientific: cint = 0
    var i: cint = 0
    while i < len:
      case str[i]
      of '.':
        if not scientific:
          has_point = 1
        else:
          return 0
      of 'e':
        if not scientific:
          scientific = 1
        else:
          return 0
      else:
        continue
      inc(i)
    return has_point

  proc parse_float*(ctx: ptr Context; buf: cstring; len: cint): term =
    if UNLIKELY((len == 0) or (len >= FLOAT_BUF_SIZE - 1)):
      RAISE_ERROR(BADARG_ATOM)
    var null_terminated_buf: array[FLOAT_BUF_SIZE, char]
    memcpy(null_terminated_buf, buf, len)
    null_terminated_buf[len] = '\x00'
    var fvalue: avm_float
    if UNLIKELY(sscanf(null_terminated_buf, AVM_FLOAT_FMT, addr(fvalue)) != 1):
      RAISE_ERROR(BADARG_ATOM)
    if UNLIKELY(not is_valid_float_string(null_terminated_buf, len)):
      RAISE_ERROR(BADARG_ATOM)
    if UNLIKELY(memory_ensure_free(ctx, FLOAT_SIZE) != MEMORY_GC_OK):
      RAISE_ERROR(OUT_OF_MEMORY_ATOM)
    return term_from_float(fvalue, ctx)

proc nif_erlang_binary_to_float_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  when not defined(AVM_NO_FP):
    var bin_term: term = argv[0]
    VALIDATE_VALUE(bin_term, term_is_binary)
    var bin_data: cstring = term_binary_data(bin_term)
    var bin_data_size: cint = term_binary_size(bin_term)
    return parse_float(ctx, bin_data, bin_data_size)
  else:
    UNUSED(ctx)
    UNUSED(argv)
    RAISE_ERROR(BADARG_ATOM)

proc nif_erlang_list_to_float_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  when not defined(AVM_NO_FP):
    var t: term = argv[0]
    VALIDATE_VALUE(t, term_is_list)
    var proper: cint
    var len: cint = term_list_length(t, addr(proper))
    if UNLIKELY(not proper):
      RAISE_ERROR(BADARG_ATOM)
    var ok: cint
    var string: cstring = interop_list_to_string(argv[0], addr(ok))
    if UNLIKELY(not ok):
      RAISE_ERROR(BADARG_ATOM)
    var res_term: term = parse_float(ctx, string, len)
    free(string)
    return res_term
  else:
    UNUSED(ctx)
    UNUSED(argv)
    RAISE_ERROR(BADARG_ATOM)

proc nif_erlang_binary_to_list_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  var value: term = argv[0]
  VALIDATE_VALUE(value, term_is_binary)
  var bin_size: cint = term_binary_size(value)
  if UNLIKELY(memory_ensure_free(ctx, bin_size * 2) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var bin_data: cstring = term_binary_data(argv[0])
  var prev: term = term_nil()
  var i: cint = bin_size - 1
  while i >= 0:
    prev = term_list_prepend(term_from_int11(bin_data[i]), prev, ctx)
    dec(i)
  return prev

proc nif_erlang_binary_to_existing_atom_2*(ctx: ptr Context; argc: cint;
    argv: ptr term): term =
  return binary_to_atom(ctx, argc, argv, 0)

proc binary_to_atom*(ctx: ptr Context; argc: cint; argv: ptr term; create_new: cint): term {.
    cdecl.} =
  UNUSED(argc)
  var a_binary: term = argv[0]
  VALIDATE_VALUE(a_binary, term_is_binary)
  if UNLIKELY(argv[1] != LATIN1_ATOM):
    RAISE_ERROR(BADARG_ATOM)
  var atom_string: cstring = interop_binary_to_string(a_binary)
  if IS_NULL_PTR(atom_string):
    fprintf(stderr, "Failed to alloc temporary string\n")
    abort()
  var atom_string_len: cint = strlen(atom_string)
  if UNLIKELY(atom_string_len > 255):
    free(atom_string)
    RAISE_ERROR(SYSTEM_LIMIT_ATOM)
  var atom: AtomString = malloc(atom_string_len + 1)
  (cast[ptr uint8](atom))[0] = atom_string_len
  memcpy((cast[cstring](atom)) + 1, atom_string, atom_string_len)
  var global_atom_index: culong = atomshashtable_get_value(ctx.global.atoms_table,
      atom, ULONG_MAX)
  var has_atom: cint = (global_atom_index != ULONG_MAX)
  if create_new or has_atom:
    if not has_atom:
      global_atom_index = globalcontext_insert_atom(ctx.global, atom)
    else:
      free(cast[pointer](atom))
    return term_from_atom_index(global_atom_index)
  else:
    free(cast[pointer](atom))
    RAISE_ERROR(BADARG_ATOM)

proc nif_erlang_list_to_atom_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  return list_to_atom(ctx, argc, argv, 1)

proc nif_erlang_list_to_existing_atom_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  return list_to_atom(ctx, argc, argv, 0)

proc list_to_atom*(ctx: ptr Context; argc: cint; argv: ptr term; create_new: cint): term {.
    cdecl.} =
  UNUSED(argc)
  var a_list: term = argv[0]
  VALIDATE_VALUE(a_list, term_is_list)
  var ok: cint
  var atom_string: cstring = interop_list_to_string(a_list, addr(ok))
  if UNLIKELY(not ok):
    fprintf(stderr, "Failed to alloc temporary string\n")
    abort()
  var atom_string_len: cint = strlen(atom_string)
  if UNLIKELY(atom_string_len > 255):
    free(atom_string)
    RAISE_ERROR(SYSTEM_LIMIT_ATOM)
  var atom: AtomString = malloc(atom_string_len + 1)
  (cast[ptr uint8](atom))[0] = atom_string_len
  memcpy((cast[cstring](atom)) + 1, atom_string, atom_string_len)
  var global_atom_index: culong = atomshashtable_get_value(ctx.global.atoms_table,
      atom, ULONG_MAX)
  var has_atom: cint = (global_atom_index != ULONG_MAX)
  if create_new or has_atom:
    if not has_atom:
      global_atom_index = globalcontext_insert_atom(ctx.global, atom)
    else:
      free(cast[pointer](atom))
    return term_from_atom_index(global_atom_index)
  else:
    free(cast[pointer](atom))
    RAISE_ERROR(BADARG_ATOM)

proc nif_erlang_atom_to_binary_2*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  var atom_term: term = argv[0]
  VALIDATE_VALUE(atom_term, term_is_atom)
  if UNLIKELY(argv[1] != LATIN1_ATOM):
    RAISE_ERROR(BADARG_ATOM)
  var atom_index: cint = term_to_atom_index(atom_term)
  var atom_string: AtomString = cast[AtomString](valueshashtable_get_value(
      ctx.global.atoms_ids_table, atom_index, cast[culong](nil)))
  var atom_len: cint = atom_string_len(atom_string)
  if UNLIKELY(memory_ensure_free(ctx, term_binary_data_size_in_terms(atom_len) +
      BINARY_HEADER_SIZE) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var atom_data: cstring = cast[cstring](atom_string_data(atom_string))
  return term_from_literal_binary(atom_data, atom_len, ctx)

proc nif_erlang_atom_to_list_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  var atom_term: term = argv[0]
  VALIDATE_VALUE(atom_term, term_is_atom)
  var atom_index: cint = term_to_atom_index(atom_term)
  var atom_string: AtomString = cast[AtomString](valueshashtable_get_value(
      ctx.global.atoms_ids_table, atom_index, cast[culong](nil)))
  var atom_len: cint = atom_string_len(atom_string)
  if UNLIKELY(memory_ensure_free(ctx, atom_len * 2) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var prev: term = term_nil()
  var i: cint = atom_len - 1
  while i >= 0:
    var c: char = (cast[cstring](atom_string_data(atom_string)))[i]
    prev = term_list_prepend(term_from_int11(c), prev, ctx)
    dec(i)
  return prev

proc nif_erlang_integer_to_binary_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  var value: term = argv[0]
  VALIDATE_VALUE(value, term_is_any_integer)
  var int_value: avm_int64 = term_maybe_unbox_int64(value)
  var integer_string: array[21, char]
  ## TODO: just copy data to the binary instead of using the stack
  snprintf(integer_string, 21, AVM_INT64_FMT, int_value)
  var len: cint = strlen(integer_string)
  if UNLIKELY(memory_ensure_free(ctx, term_binary_data_size_in_terms(len) +
      BINARY_HEADER_SIZE) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  return term_from_literal_binary(integer_string, len, ctx)

proc nif_erlang_integer_to_list_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  var value: term = argv[0]
  VALIDATE_VALUE(value, term_is_any_integer)
  var int_value: avm_int64 = term_maybe_unbox_int64(value)
  var integer_string: array[21, char]
  snprintf(integer_string, 21, AVM_INT64_FMT, int_value)
  var integer_string_len: cint = strlen(integer_string)
  if UNLIKELY(memory_ensure_free(ctx, integer_string_len * 2) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var prev: term = term_nil()
  var i: cint = integer_string_len - 1
  while i >= 0:
    prev = term_list_prepend(term_from_int11(integer_string[i]), prev, ctx)
    dec(i)
  return prev

when not defined(AVM_NO_FP):
  proc format_float*(value: term; scientific: cint; decimals: cint; compact: cint;
                    out_buf: cstring; outbuf_len: cint): cint =
    ##  %lf and %f are the same since C99 due to double promotion.
    var format: cstring
    if scientific:
      format = "%.*e"
    else:
      format = "%.*f"
    var float_value: avm_float = term_to_float(value)
    snprintf(out_buf, outbuf_len, format, decimals, float_value)
    if compact and not scientific:
      var start: cint = 0
      var len: cint = strlen(out_buf)
      var i: cint = 0
      while i < len:
        if out_buf[i] == '.':
          start = i + 2
          break
        inc(i)
      if start > 1:
        var zero_seq_len: cint = 0
        var i: cint = start
        while i < len:
          if out_buf[i] == '0':
            if zero_seq_len == 0:
              start = i
            inc(zero_seq_len)
          else:
            zero_seq_len = 0
          inc(i)
        if zero_seq_len:
          out_buf[start] = 0
    return strlen(out_buf)

  proc get_float_format_opts*(opts: term; scientific: ptr cint; decimals: ptr cint;
                             compact: ptr cint): cint =
    var t: term = opts
    while term_is_nonempty_list(t):
      var head: term = term_get_list_head(t)
      if term_is_tuple(head) and term_get_tuple_arity(head) == 2:
        var val_term: term = term_get_tuple_element(head, 1)
        if not term_is_integer(val_term):
          return 0
        decimals[] = term_to_int(val_term)
        if (decimals[] < 0) or (decimals[] > FLOAT_BUF_SIZE - 7):
          return 0
        case term_get_tuple_element(head, 0)
        of DECIMALS_ATOM:
          scientific[] = 0
        of SCIENTIFIC_ATOM:
          scientific[] = 1
        else:
          return 0
      elif head == DEFAULTATOMS_COMPACT_ATOM:
        compact[] = 1
      else:
        return 0
      t = term_get_list_tail(t)
      if not term_is_list(t):
        return 0
    return 1

proc nif_erlang_float_to_binary*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  when not defined(AVM_NO_FP):
    var float_term: term = argv[0]
    VALIDATE_VALUE(float_term, term_is_float)
    var scientific: cint = 1
    var decimals: cint = 20
    var compact: cint = 0
    var opts: term = argv[1]
    if argc == 2:
      VALIDATE_VALUE(opts, term_is_list)
      if UNLIKELY(not get_float_format_opts(opts, addr(scientific), addr(decimals),
          addr(compact))):
        RAISE_ERROR(BADARG_ATOM)
    var float_buf: array[FLOAT_BUF_SIZE, char]
    var len: cint = format_float(float_term, scientific, decimals, compact, float_buf,
                             FLOAT_BUF_SIZE)
    if len > FLOAT_BUF_SIZE:
      RAISE_ERROR(BADARG_ATOM)
    if UNLIKELY(memory_ensure_free(ctx, term_binary_data_size_in_terms(len) +
        BINARY_HEADER_SIZE) != MEMORY_GC_OK):
      RAISE_ERROR(OUT_OF_MEMORY_ATOM)
    return term_from_literal_binary(float_buf, len, ctx)
  else:
    UNUSED(ctx)
    UNUSED(argv)
    RAISE_ERROR(BADARG_ATOM)

proc nif_erlang_float_to_list*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  when not defined(AVM_NO_FP):
    var float_term: term = argv[0]
    VALIDATE_VALUE(float_term, term_is_float)
    var scientific: cint = 1
    var decimals: cint = 20
    var compact: cint = 0
    var opts: term = argv[1]
    if argc == 2:
      VALIDATE_VALUE(opts, term_is_list)
      if UNLIKELY(not get_float_format_opts(opts, addr(scientific), addr(decimals),
          addr(compact))):
        RAISE_ERROR(BADARG_ATOM)
    var float_buf: array[FLOAT_BUF_SIZE, char]
    var len: cint = format_float(float_term, scientific, decimals, compact, float_buf,
                             FLOAT_BUF_SIZE)
    if len > FLOAT_BUF_SIZE:
      RAISE_ERROR(BADARG_ATOM)
    if UNLIKELY(memory_ensure_free(ctx, len * 2) != MEMORY_GC_OK):
      RAISE_ERROR(OUT_OF_MEMORY_ATOM)
    var prev: term = term_nil()
    var i: cint = len - 1
    while i >= 0:
      prev = term_list_prepend(term_from_int11(float_buf[i]), prev, ctx)
      dec(i)
    return prev
  else:
    UNUSED(ctx)
    UNUSED(argv)
    RAISE_ERROR(BADARG_ATOM)

proc nif_erlang_list_to_binary_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  var t: term = argv[0]
  VALIDATE_VALUE(t, term_is_list)
  var proper: cint
  var len: cint = term_list_length(t, addr(proper))
  if UNLIKELY(not proper):
    RAISE_ERROR(BADARG_ATOM)
  if UNLIKELY(memory_ensure_free(ctx, term_binary_data_size_in_terms(len) +
      BINARY_HEADER_SIZE) != MEMORY_GC_OK):
    RAISE_ERROR(BADARG_ATOM)
  var ok: cint
  var string: cstring = interop_list_to_string(argv[0], addr(ok))
  if UNLIKELY(not ok):
    RAISE_ERROR(BADARG_ATOM)
  var bin_term: term = term_from_literal_binary(string, len, ctx)
  free(string)
  return bin_term

proc nif_erlang_list_to_integer_1*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  UNUSED(argc)
  var t: term = argv[0]
  var acc: int64 = 0
  var digits: cint = 0
  VALIDATE_VALUE(t, term_is_nonempty_list)
  var negative: cint = 0
  var first_digit: term = term_get_list_head(t)
  if first_digit == term_from_int11('-'):
    negative = 1
    t = term_get_list_tail(t)
  elif first_digit == term_from_int11('+'):
    t = term_get_list_tail(t)
  while term_is_nonempty_list(t):
    var head: term = term_get_list_head(t)
    VALIDATE_VALUE(head, term_is_integer)
    var c: avm_int = term_to_int(head)
    if UNLIKELY((c < '0') or (c > '9')):
      RAISE_ERROR(BADARG_ATOM)
    if acc > INT64_MAX div 10:
      ##  overflow error is not standard, but we need it since we are running on an embedded device
      RAISE_ERROR(OVERFLOW_ATOM)
    acc = (acc * 10) + (c - '0')
    inc(digits)
    t = term_get_list_tail(t)
    if not term_is_list(t):
      RAISE_ERROR(BADARG_ATOM)
  if negative:
    acc = -acc
  if UNLIKELY(digits == 0):
    RAISE_ERROR(BADARG_ATOM)
  return make_maybe_boxed_int64(ctx, acc)

proc nif_erlang_display_1*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(ctx)
  UNUSED(argc)
  term_display(stdout, argv[0], ctx)
  printf("\n")
  return term_nil()

proc nif_erlang_process_flag*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  when defined(ENABLE_ADVANCED_TRACE):
    var pid: term = argv[0]
    var flag: term = argv[1]
    var value: term = argv[2]
    var local_process_id: cint = term_to_local_process_id(pid)
    var target: ptr Context = globalcontext_get_process(ctx.global, local_process_id)
    if flag == context_make_atom(target, trace_calls_atom):
      if value == TRUE_ATOM:
        target.trace_calls = 1
        return OK_ATOM
      elif value == FALSE_ATOM:
        target.trace_calls = 0
        return OK_ATOM
    elif flag == context_make_atom(target, trace_call_args_atom):
      if value == TRUE_ATOM:
        target.trace_call_args = 1
        return OK_ATOM
      elif value == FALSE_ATOM:
        target.trace_call_args = 0
        return OK_ATOM
    elif flag == context_make_atom(target, trace_returns_atom):
      if value == TRUE_ATOM:
        target.trace_returns = 1
        return OK_ATOM
      elif value == FALSE_ATOM:
        target.trace_returns = 0
        return OK_ATOM
    elif flag == context_make_atom(target, trace_send_atom):
      if value == TRUE_ATOM:
        target.trace_send = 1
        return OK_ATOM
      elif value == FALSE_ATOM:
        target.trace_send = 0
        return OK_ATOM
    elif flag == context_make_atom(target, trace_receive_atom): ##  TODO: FIXME
                                                           ##  #else
                                                           ##  unused(ctx);
                                                           ##  unused(argv);
      if value == TRUE_ATOM:
        target.trace_receive = 1
        return OK_ATOM
      elif value == FALSE_ATOM:
        target.trace_receive = 0
        return OK_ATOM
  RAISE_ERROR(BADARG_ATOM)

type
  context_iterator* = proc (ctx: ptr Context; accum: pointer): pointer {.cdecl.}

proc nif_increment_context_count*(ctx: ptr Context; accum: pointer): pointer =
  UNUSED(ctx)
  return cast[pointer]((cast[csize](accum) + 1))

proc nif_increment_port_count*(ctx: ptr Context; accum: pointer): pointer =
  if ctx.native_handler:
    return cast[pointer]((cast[csize](accum) + 1))
  else:
    return accum

type
  ContextAccumulator* = object
    ctx*: ptr Context
    result*: term


proc nif_cons_context*(ctx: ptr Context; p: pointer): pointer =
  var accum: ptr ContextAccumulator = cast[ptr ContextAccumulator](p)
  accum.result = term_list_prepend(term_from_local_process_id(ctx.process_id),
                                 accum.result, accum.ctx)
  return cast[pointer](accum)

proc nif_iterate_processes*(glb: ptr GlobalContext; fun: context_iterator;
                           accum: pointer): pointer =
  var processes: ptr Context = GET_LIST_ENTRY(glb.processes_table, Context,
      processes_table_head)
  var p: ptr Context = processes
  while true:
    accum = fun(p, accum)
    p = GET_LIST_ENTRY(p.processes_table_head.next, Context, processes_table_head)
    if not (processes != p):
      break
  return accum

proc nif_num_processes*(glb: ptr GlobalContext): csize =
  return cast[csize](nif_iterate_processes(glb, nif_increment_context_count, nil))

proc nif_num_ports*(glb: ptr GlobalContext): csize =
  return cast[csize](nif_iterate_processes(glb, nif_increment_port_count, nil))

proc nif_list_processes*(ctx: ptr Context): term =
  var accum: ContextAccumulator
  accum.ctx = ctx
  accum.result = term_nil()
  nif_iterate_processes(ctx.global, nif_cons_context, cast[pointer](addr(accum)))
  return accum.result

proc nif_erlang_processes*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argv)
  UNUSED(argc)
  var num_processes: csize = nif_num_processes(ctx.global)
  if memory_ensure_free(ctx, 2 * num_processes) != MEMORY_GC_OK:
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  return nif_list_processes(ctx)

proc nif_erlang_process_info*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var pid: term = argv[0]
  var item_or_item_info: term = argv[1]
  if not term_is_atom(item_or_item_info):
    RAISE_ERROR(BADARG_ATOM)
  var item: term = item_or_item_info
  var local_process_id: cint = term_to_local_process_id(pid)
  var target: ptr Context = globalcontext_get_process(ctx.global, local_process_id)
  if memory_ensure_free(ctx, 3) != MEMORY_GC_OK:
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var ret: term = term_alloc_tuple(2, ctx)
  ##  heap_size size in words of the heap of the process
  if item == HEAP_SIZE_ATOM:
    term_put_tuple_element(ret, 0, HEAP_SIZE_ATOM)
    term_put_tuple_element(ret, 1, term_from_int32(context_heap_size(target)))
    ##  stack_size stack size, in words, of the process
  elif item == STACK_SIZE_ATOM:
    term_put_tuple_element(ret, 0, STACK_SIZE_ATOM)
    term_put_tuple_element(ret, 1, term_from_int32(context_stack_size(target)))
    ##  message_queue_len number of messages currently in the message queue of the process
  elif item == MESSAGE_QUEUE_LEN_ATOM:
    term_put_tuple_element(ret, 0, MESSAGE_QUEUE_LEN_ATOM)
    term_put_tuple_element(ret, 1,
                           term_from_int32(context_message_queue_len(target)))
    ##  memory size in bytes of the process. This includes call stack, heap, and internal structures.
  elif item == MEMORY_ATOM:
    term_put_tuple_element(ret, 0, MEMORY_ATOM)
    term_put_tuple_element(ret, 1, term_from_int32(context_size(target)))
  else:
    RAISE_ERROR(BADARG_ATOM)
  return ret

proc nif_erlang_system_info*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var key: term = argv[0]
  if not term_is_atom(key):
    RAISE_ERROR(BADARG_ATOM)
  if key == PROCESS_COUNT_ATOM:
    return term_from_int32(nif_num_processes(ctx.global))
  if key == PORT_COUNT_ATOM:
    return term_from_int32(nif_num_ports(ctx.global))
  if key == ATOM_COUNT_ATOM:
    return term_from_int32(ctx.global.atoms_table.count)
  if key == WORDSIZE_ATOM:
    return term_from_int32(TERM_BYTES)
  if key == SYSTEM_ARCHITECTURE_ATOM:
    var buf: array[128, char]
    snprintf(buf, 128, "%s-%s-%s", SYSTEM_NAME, SYSTEM_VERSION, SYSTEM_ARCHITECTURE)
    var len: csize = strnlen(buf, 128)
    if memory_ensure_free(ctx, term_binary_data_size_in_terms(len)) !=
        MEMORY_GC_OK:
      RAISE_ERROR(OUT_OF_MEMORY_ATOM)
    return term_from_literal_binary(cast[ptr uint8](buf), len, ctx)
  return sys_get_info(ctx, key)

proc nif_erlang_binary_to_term*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  if argc < 1 or 2 < argc:
    RAISE_ERROR(BADARG_ATOM)
  if argc == 2 and not term_is_list(argv[1]):
    RAISE_ERROR(BADARG_ATOM)
  var binary: term = argv[0]
  if not term_is_binary(binary):
    RAISE_ERROR(BADARG_ATOM)
  var return_used: uint8 = 0
  var num_extra_terms: csize = 0
  if argc == 2 and term_list_member(argv[1], USED_ATOM, ctx):
    return_used = 1
    num_extra_terms = 3
  var dst: term = term_invalid_term()
  var bytes_read: csize = 0
  var result: ExternalTermResult = externalterm_from_binary(ctx, addr(dst), binary,
      addr(bytes_read), num_extra_terms)
  case result
  of EXTERNAL_TERM_BAD_ARG:
    RAISE_ERROR(BADARG_ATOM)
  of EXTERNAL_TERM_MALLOC, EXTERNAL_TERM_HEAP_ALLOC:
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  of EXTERNAL_TERM_OK:
    nil
  else:
    nil
  if term_is_invalid_term(dst):
    RAISE_ERROR(BADARG_ATOM)
  if return_used:
    var ret: term = term_alloc_tuple(2, ctx)
    term_put_tuple_element(ret, 0, dst)
    term_put_tuple_element(ret, 1, term_from_int(bytes_read))
    return ret
  else:
    return dst

proc nif_erlang_term_to_binary*(ctx: ptr Context; argc: cint; argv: ptr term): term {.
    cdecl.} =
  if argc != 1:
    RAISE_ERROR(BADARG_ATOM)
  var t: term = argv[0]
  var ret: term = externalterm_to_binary(ctx, t)
  if term_is_invalid_term(ret):
    RAISE_ERROR(BADARG_ATOM)
  return ret

proc nif_binary_at_2*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var bin_term: term = argv[0]
  var pos_term: term = argv[1]
  VALIDATE_VALUE(bin_term, term_is_binary)
  VALIDATE_VALUE(pos_term, term_is_integer)
  var size: int32 = term_binary_size(bin_term)
  var pos: avm_int = term_to_int(pos_term)
  if UNLIKELY((pos < 0) or (pos >= size)):
    RAISE_ERROR(BADARG_ATOM)
  return term_from_int11(term_binary_data(bin_term)[pos])

proc nif_binary_first_1*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var bin_term: term = argv[0]
  VALIDATE_VALUE(bin_term, term_is_binary)
  if UNLIKELY(term_binary_size(bin_term) == 0):
    RAISE_ERROR(BADARG_ATOM)
  return term_from_int11(term_binary_data(bin_term)[0])

proc nif_binary_last_1*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var bin_term: term = argv[0]
  VALIDATE_VALUE(bin_term, term_is_binary)
  var size: cint = term_binary_size(bin_term)
  if UNLIKELY(size == 0):
    RAISE_ERROR(BADARG_ATOM)
  return term_from_int11(term_binary_data(bin_term)[size - 1])

proc nif_binary_part_3*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var bin_term: term = argv[0]
  var pos_term: term = argv[1]
  var len_term: term = argv[2]
  VALIDATE_VALUE(bin_term, term_is_binary)
  VALIDATE_VALUE(pos_term, term_is_integer)
  VALIDATE_VALUE(len_term, term_is_integer)
  var bin_size: cint = term_binary_size(bin_term)
  var pos: avm_int = term_to_int(pos_term)
  var len: avm_int = term_to_int(len_term)
  if len < 0:
    inc(pos, len)
    len = -len
  if UNLIKELY((pos < 0) or (pos > bin_size) or (pos + len > bin_size)):
    RAISE_ERROR(BADARG_ATOM)
  if UNLIKELY(memory_ensure_free(ctx, term_binary_data_size_in_terms(len) +
      BINARY_HEADER_SIZE) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var bin_data: cstring = term_binary_data(argv[0])
  return term_from_literal_binary(bin_data + pos, len, ctx)

proc nif_binary_split_2*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var bin_term: term = argv[0]
  var pattern_term: term = argv[1]
  VALIDATE_VALUE(bin_term, term_is_binary)
  VALIDATE_VALUE(pattern_term, term_is_binary)
  var bin_size: cint = term_binary_size(bin_term)
  var pattern_size: cint = term_binary_size(pattern_term)
  if UNLIKELY(pattern_size == 0):
    RAISE_ERROR(BADARG_ATOM)
  var bin_data: cstring = term_binary_data(bin_term)
  var pattern_data: cstring = term_binary_data(pattern_term)
  var found: cstring = cast[cstring](memmem(bin_data, bin_size, pattern_data,
                                        pattern_size))
  var offset: cint = found - bin_data
  if found:
    var tok_size: cint = offset
    ##  + 2, which is the binary header size
    var tok_size_in_terms: cint = term_binary_data_size_in_terms(tok_size) +
        BINARY_HEADER_SIZE
    var rest_size: cint = bin_size - offset - pattern_size
    ##  + 2, which is the binary header size
    var rest_size_in_terms: cint = term_binary_data_size_in_terms(rest_size) +
        BINARY_HEADER_SIZE
    ##  + 2 which is the result cons
    if UNLIKELY(memory_ensure_free(ctx, tok_size_in_terms + rest_size_in_terms + 2) !=
        MEMORY_GC_OK):
      RAISE_ERROR(OUT_OF_MEMORY_ATOM)
    var bin_data: cstring = term_binary_data(argv[0])
    var tok: term = term_from_literal_binary(bin_data, tok_size, ctx)
    var rest: term = term_from_literal_binary(bin_data + offset + pattern_size,
        rest_size, ctx)
    var result_list: term = term_list_prepend(rest, term_nil(), ctx)
    result_list = term_list_prepend(tok, result_list, ctx)
    return result_list
  else:
    if UNLIKELY(memory_ensure_free(ctx, 2) != MEMORY_GC_OK):
      RAISE_ERROR(OUT_OF_MEMORY_ATOM)
    return term_list_prepend(argv[0], term_nil(), ctx)

proc nif_erlang_throw*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var t: term = argv[0]
  ctx.x[0] = THROW_ATOM
  ctx.x[1] = t
  return term_invalid_term()

proc nif_erts_debug_flat_size*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(ctx)
  UNUSED(argc)
  var terms_count: culong
  terms_count = memory_estimate_usage(argv[0])
  return term_from_int32(terms_count)

proc nif_erlang_pid_to_list*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var t: term = argv[0]
  VALIDATE_VALUE(t, term_is_pid)
  ##  2^32 = 4294967296 (10 chars)
  ##  6 chars of static text + '\0'
  var buf: array[17, char]
  snprintf(buf, 17, "<0.%i.0>", term_to_local_process_id(t))
  var str_len: cint = strnlen(buf, 17)
  if UNLIKELY(memory_ensure_free(ctx, str_len * 2) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var prev: term = term_nil()
  var i: cint = str_len - 1
  while i >= 0:
    prev = term_list_prepend(term_from_int11(buf[i]), prev, ctx)
    dec(i)
  return prev

proc nif_erlang_ref_to_list*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var t: term = argv[0]
  VALIDATE_VALUE(t, term_is_reference)
  ##  TODO: FIXME
  when defined(__clang__):
    var format: cstring = "#Ref<0.0.0.%llu>"
  else:
    var format: cstring = "#Ref<0.0.0.%lu>"
  ##  2^64 = 18446744073709551616 (20 chars)
  ##  12 chars of static text + '\0'
  var buf: array[33, char]
  snprintf(buf, 33, format, term_to_ref_ticks(t))
  var str_len: cint = strnlen(buf, 33)
  if UNLIKELY(memory_ensure_free(ctx, str_len * 2) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var prev: term = term_nil()
  var i: cint = str_len - 1
  while i >= 0:
    prev = term_list_prepend(term_from_int11(buf[i]), prev, ctx)
    dec(i)
  return prev

proc nif_erlang_fun_to_list*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var t: term = argv[0]
  VALIDATE_VALUE(t, term_is_function)
  var boxed_value: ptr term = term_to_const_term_ptr(t)
  var fun_module: ptr Module = cast[ptr Module](boxed_value[1])
  var fun_index: uint32 = boxed_value[2]
  ##  char-len(address) + char-len(32-bit-num) + 16 + '\0' = 47
  ##  20                  10
  when defined(__clang__):
    var format: cstring = "#Fun<erl_eval.%lu.%llu>"
  else:
    var format: cstring = "#Fun<erl_eval.%lu.%llu>"
  var buf: array[47, char]
  snprintf(buf, 47, format, fun_index, cast[culong](fun_module))
  var str_len: cint = strnlen(buf, 47)
  if UNLIKELY(memory_ensure_free(ctx, str_len * 2) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var prev: term = term_nil()
  var i: cint = str_len - 1
  while i >= 0:
    prev = term_list_prepend(term_from_int11(buf[i]), prev, ctx)
    dec(i)
  return prev

proc nif_erlang_error*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var r: term = argv[0]
  RAISE_ERROR(r)

proc nif_erlang_make_fun_3*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var module_term: term = argv[0]
  var function_term: term = argv[1]
  var arity_term: term = argv[2]
  VALIDATE_VALUE(module_term, term_is_atom)
  VALIDATE_VALUE(function_term, term_is_atom)
  VALIDATE_VALUE(arity_term, term_is_integer)
  return term_make_function_reference(module_term, function_term, arity_term, ctx)

##  AtomVM extension

proc nif_atomvm_read_priv*(ctx: ptr Context; argc: cint; argv: ptr term): term =
  UNUSED(argc)
  var app_term: term = argv[0]
  var path_term: term = argv[1]
  VALIDATE_VALUE(app_term, term_is_atom)
  var glb: ptr GlobalContext = ctx.global
  if UNLIKELY(not glb.avmpack_data):
    RAISE_ERROR(BADARG_ATOM)
  var atom_index: cint = term_to_atom_index(app_term)
  var atom_string: AtomString = cast[AtomString](valueshashtable_get_value(
      glb.atoms_ids_table, atom_index, cast[culong](nil)))
  var app_len: cint = atom_string_len(atom_string)
  var app: cstring = malloc(app_len + 1)
  memcpy(app, cast[cstring](atom_string_data(atom_string)), app_len)
  app[app_len] = '\x00'
  var ok: cint
  var path: cstring = interop_term_to_string(path_term, addr(ok))
  if UNLIKELY(not ok):
    RAISE_ERROR(BADARG_ATOM)
  if UNLIKELY(not path):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var complete_path_len: cint = app_len + strlen("/priv/") + strlen(path) + 1
  var complete_path: cstring = malloc(complete_path_len)
  snprintf(complete_path, complete_path_len, "%s/priv/%s", app, path)
  free(app)
  free(path)
  var bin_data: pointer
  var size: uint32
  if avmpack_find_section_by_name(glb.avmpack_data, complete_path, addr(bin_data),
                                 addr(size)):
    var file_size: uint32 = READ_32_ALIGNED(cast[ptr uint32](bin_data))
    free(complete_path)
    if UNLIKELY(memory_ensure_free(ctx, TERM_BOXED_REFC_BINARY_SIZE) !=
        MEMORY_GC_OK):
      RAISE_ERROR(OUT_OF_MEMORY_ATOM)
    return term_from_const_binary((cast[ptr uint8](bin_data)) +
        sizeof((uint32)), file_size, ctx)
  else:
    free(complete_path)
    return UNDEFINED_ATOM
