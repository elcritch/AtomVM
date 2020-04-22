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
  debug

##  TODO: FIXME
##  static COLD_FUNC void debug_display_type(term t, const Context *ctx)

proc debug_display_type*(t: term; ctx: ptr Context) {.cdecl.} =
  if term_is_atom(t) or term_is_integer(t) or term_is_nil(t) or term_is_pid(t):
    term_display(stderr, t, ctx)
  elif (t and 0x0000003F) == 0:
    fprintf(stderr, "tuple(%i)", term_get_size_from_boxed_header(t))
  elif term_is_boxed(t):
    fprintf(stderr, "boxed(0x%lx)", cast[culong](term_to_term_ptr(t)))
  elif (t and 0x00000003) == 0x00000001:
    fprintf(stderr, "list(0x%lx)", cast[culong](term_to_term_ptr(t)))
  elif term_is_catch_label(t):
    var module_index: cint
    var catch_label: cint = term_to_catch_label_and_module(t, addr(module_index))
    fprintf(stderr, "catch label(%i:%i)", module_index, catch_label)
  elif term_is_cp(t):
    fprintf(stderr, "continuation pointer")
  else:
    fprintf(stderr, "unknown")

##  TODO: FIXME
##  static COLD_FUNC void debug_dump_binary_mem(char *buf, term val, unsigned n)

proc debug_dump_binary_mem*(buf: cstring; val: term; n: cuint) {.cdecl.} =
  var i: cuint = 0
  while i < n:
    var bit_i: cint = val shr i and 0x00000001
    buf[(n - 1) - i] = if bit_i: '1' else: '0'
    inc(i)
  buf[n] = '\x00'

##  TODO: FIXME
##  static COLD_FUNC void debug_dump_term(Context *ctx, term *pos, const char *region, unsigned i)

proc debug_dump_term*(ctx: ptr Context; pos: ptr term; region: cstring; i: cuint) {.cdecl.} =
  var t: term = pos[]
  ##  TODO use TERM_BITS instead
  var buf: array[32 + 1, char]
  debug_dump_binary_mem(buf, pos[], 32)
  fprintf(stderr, "DEBUG: %s 0x%lx %3i: (%s)b 0x%09lx: ", region,
          cast[culong](pos), i, buf, t)
  debug_display_type(t, ctx)
  fprintf(stderr, "\n")

##  TODO: FIXME
##  COLD_FUNC void debug_dump_memory(Context *ctx, term *start, term *end, const char *region)

proc debug_dump_memory*(ctx: ptr Context; start: ptr term; `end`: ptr term;
                       region: cstring) {.cdecl.} =
  var size: culong = `end` - start
  fprintf(stderr, "DEBUG:\n")
  fprintf(stderr, "DEBUG: %s start: 0x%lx\n", region, cast[culong](start))
  fprintf(stderr, "DEBUG: %s end:   0x%lx\n", region, cast[culong](`end`))
  fprintf(stderr, "DEBUG: %s size:  %li words\n", region, size)
  var pos: ptr term = start
  var i: cuint = 0
  while i < size:
    debug_dump_term(ctx, pos, region, i)
    inc(pos)
    inc(i)
  fprintf(stderr, "DEBUG:\n")

##  TODO: FIXME
##  COLD_FUNC void debug_dump_context(Context *ctx)

proc debug_dump_context*(ctx: ptr Context) {.cdecl.} =
  debug_dump_heap(ctx)
  debug_dump_stack(ctx)
  debug_dump_registers(ctx)

##  TODO: FIXME
##  COLD_FUNC void debug_dump_heap(Context *ctx)

proc debug_dump_heap*(ctx: ptr Context) {.cdecl.} =
  debug_dump_memory(ctx, ctx.heap_start, ctx.heap_ptr, "heap")

##  TODO: FIXME
##  COLD_FUNC void debug_dump_stack(Context *ctx)

proc debug_dump_stack*(ctx: ptr Context) {.cdecl.} =
  debug_dump_memory(ctx, ctx.e, ctx.stack_base, "stack")

##  TODO: FIXME
##  COLD_FUNC void debug_dump_registers(Context *ctx)

proc debug_dump_registers*(ctx: ptr Context) {.cdecl.} =
  debug_dump_memory(ctx, ctx.x, ctx.x + 16, "register")

##  TODO: FIXME
##  COLD_FUNC void debug_print_processes_list(struct ListHead *processes)

proc debug_print_processes_list*(processes: ptr ListHead) {.cdecl.} =
  var contexts: ptr Context = GET_LIST_ENTRY(processes, Context, processes_list_head)
  if not contexts:
    printf("No processes\n")
    return
  var context: ptr Context = contexts
  printf("Processes list:\n")
  while true:
    printf("%i: %p\n", context.process_id, cast[pointer](context))
    context = GET_LIST_ENTRY(context.processes_list_head.next, Context,
                           processes_list_head)
    if not (context != contexts):
      break
  printf("\n")

##  TODO: FIXME
##  COLD_FUNC char reg_type_c(int reg_type)

proc reg_type_c*(reg_type: cint): char {.cdecl.} =
  case reg_type
  of 2:
    return 'a'
  of 3:
    return 'x'
  of 4:
    return 'y'
  of 12:
    return 'y'
  else:
    return '?'
