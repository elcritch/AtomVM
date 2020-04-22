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
  globalcontext, atomshashtable, defaultatoms,
  valueshashtable, sys, context,
  src/libAtomVM/atom

type
  Context* {.bycopy.} = object

  GlobalContext* {.bycopy.} = object

  Module* {.bycopy.} = object

  GlobalContext* {.bycopy.} = object
    ready_processes*: seq[Context]
    waiting_processes*: seq[Context]
    processes_table*: ref seq[Context]
    registered_processes*: ref seq[Context]
    last_process_id*: int32
    atoms_table*: ref Table[AtomString, uint32]
    atoms_ids_table*: ref Table[uint32, AtomString]
    modules_table*: ref Table[AtromString, uint32]
    modules_by_index*: ref ref Module
    loaded_modules_count*: int
    avmpack_data*: ref seq[byte]
    avmpack_platform_data*: ref seq[byte]
    timer_wheel*: ref TimerWheel
    last_seen_millis*: uint32
    ref_ticks*: uint64
    platform_data*: ref seq

  RegisteredProcess* {.bycopy.} = object
    registered_processes_list_head*: ListHead
    atom_index*: cint
    local_process_id*: cint


proc globalcontext_new*(): GlobalContext =
  var glb = GlobalContext()

  list_init(addr(glb.ready_processes))
  list_init(addr(glb.waiting_processes))

  glb.processes_table = nil
  glb.registered_processes = nil
  glb.last_process_id = 0
  glb.atoms_table = atomshashtable_new()

  if IS_NULL_PTR(glb.atoms_table):
    free(glb)
    return nil
  glb.atoms_ids_table = valueshashtable_new()
  if IS_NULL_PTR(glb.atoms_ids_table):
    free(glb.atoms_table)
    free(glb)
    return nil
  defaultatoms_init(glb)
  glb.modules_by_index = nil
  glb.loaded_modules_count = 0
  glb.modules_table = atomshashtable_new()
  if IS_NULL_PTR(glb.modules_table):
    free(glb.atoms_ids_table)
    free(glb.atoms_table)
    free(glb)
    return nil
  glb.timer_wheel = timer_wheel_new(16)
  if IS_NULL_PTR(glb.timer_wheel):
    free(glb.modules_table)
    free(glb.atoms_ids_table)
    free(glb.atoms_table)
    free(glb)
    return nil
  glb.last_seen_millis = 0
  glb.ref_ticks = 0
  sys_init_platform(glb)
  return glb

##  TODO: FIXME
##  COLD_FUNC void globalcontext_destroy(GlobalContext *glb)

proc globalcontext_destroy*(glb: ptr GlobalContext) {.cdecl.} =
  free(glb)

proc globalcontext_get_process*(glb: ptr GlobalContext; process_id: int32_t): ptr Context {.
    cdecl.} =
  var processes: ptr Context = GET_LIST_ENTRY(glb.processes_table, Context,
      processes_table_head)
  var p: ptr Context = processes
  while true:
    if p.process_id == process_id:
      return p
    p = GET_LIST_ENTRY(p.processes_table_head.next, Context, processes_table_head)
    if not (processes != p):
      break
  return nil

proc globalcontext_get_new_process_id*(glb: ptr GlobalContext): int32_t {.cdecl.} =
  inc(glb.last_process_id)
  return glb.last_process_id

proc globalcontext_register_process*(glb: ptr GlobalContext; atom_index: cint;
                                    local_process_id: cint) {.cdecl.} =
  var registered_process: ptr RegisteredProcess = malloc(sizeof(RegisteredProcess))
  if IS_NULL_PTR(registered_process):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    abort()
  registered_process.atom_index = atom_index
  registered_process.local_process_id = local_process_id
  linkedlist_append(addr(glb.registered_processes),
                    addr(registered_process.registered_processes_list_head))

proc globalcontext_get_registered_process*(glb: ptr GlobalContext; atom_index: cint): cint {.
    cdecl.} =
  if not glb.registered_processes:
    return 0
  var registered_processes: ptr RegisteredProcess = GET_LIST_ENTRY(
      glb.registered_processes, struct, RegisteredProcess,
      registered_processes_list_head)
  var p: ptr RegisteredProcess = registered_processes
  while true:
    if p.atom_index == atom_index:
      return p.local_process_id
    p = GET_LIST_ENTRY(p.registered_processes_list_head.next, struct,
                     RegisteredProcess, registered_processes_list_head)
    if not (p != registered_processes):
      break
  return 0

proc globalcontext_insert_atom*(glb: ptr GlobalContext; atom_string: AtomString): cint {.
    cdecl.} =
  return globalcontext_insert_atom_maybe_copy(glb, atom_string, 0)

proc globalcontext_insert_atom_maybe_copy*(glb: ptr GlobalContext;
    atom_string: AtomString; copy: cint): cint {.cdecl.} =
  var htable: ptr AtomsHashTable = glb.atoms_table
  var atom_index: culong = atomshashtable_get_value(htable, atom_string, ULONG_MAX)
  if atom_index == ULONG_MAX:
    if copy:
      var len: uint8_t = (cast[ptr uint8_t](atom_string))[]
      var buf: ptr uint8_t = malloc(1 + len)
      if UNLIKELY(IS_NULL_PTR(buf)):
        fprintf(stderr, "Unable to allocate memory for atom string\n")
        abort()
      memcpy(buf, atom_string, 1 + len)
      atom_string = buf
    atom_index = htable.count
    if not atomshashtable_insert(htable, atom_string, atom_index):
      return -1
    if not valueshashtable_insert(glb.atoms_ids_table, atom_index,
                                cast[culong](atom_string)):
      return -1
  return cast[cint](atom_index)

proc globalcontext_atomstring_from_term*(glb: ptr GlobalContext; t: term): AtomString {.
    cdecl.} =
  if not term_is_atom(t):
    abort()
  var atom_index: culong = term_to_atom_index(t)
  var ret: culong = valueshashtable_get_value(glb.atoms_ids_table, atom_index,
      ULONG_MAX)
  if ret == ULONG_MAX:
    return nil
  return cast[AtomString](ret)

proc globalcontext_insert_module*(global: ptr GlobalContext; module: ptr Module;
                                 module_name_atom: AtomString): cint {.cdecl.} =
  if not atomshashtable_insert(global.modules_table, module_name_atom,
                             TO_ATOMSHASHTABLE_VALUE(module)):
    return -1
  var module_index: cint = global.loaded_modules_count
  var new_modules_by_index: ptr ptr Module = calloc(module_index + 1, sizeof(ptr Module))
  if IS_NULL_PTR(new_modules_by_index):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    abort()
  if global.modules_by_index:
    var i: cint = 0
    while i < module_index:
      new_modules_by_index[i] = global.modules_by_index[i]
      inc(i)
    free(global.modules_by_index)
  module.module_index = module_index
  global.modules_by_index = new_modules_by_index
  global.modules_by_index[module_index] = module
  inc(global.loaded_modules_count)
  return module_index

proc globalcontext_insert_module_with_filename*(glb: ptr GlobalContext;
    module: ptr Module; filename: cstring) {.cdecl.} =
  var len: cint = strnlen(filename, 260)
  var len_without_ext: cint = len - strlen(".beam")
  if strcmp(filename + len_without_ext, ".beam") != 0:
    printf("File isn\'t a .beam file\n")
    abort()
  var atom_string: cstring = malloc(len_without_ext + 1)
  if IS_NULL_PTR(atom_string):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    abort()
  memcpy(atom_string + 1, filename, len_without_ext)
  atom_string[0] = len_without_ext
  if UNLIKELY(globalcontext_insert_module(glb, module, atom_string) < 0):
    abort()

proc globalcontext_get_module*(global: ptr GlobalContext;
                              module_name_atom: AtomString): ptr Module {.cdecl.} =
  var found_module: ptr Module = cast[ptr Module](atomshashtable_get_value(
      global.modules_table, module_name_atom, cast[culong](nil)))
  if not found_module:
    var module_name: cstring = malloc(256 + 5)
    if IS_NULL_PTR(module_name):
      return nil
    atom_string_to_c(module_name_atom, module_name, 256)
    strcat(module_name, ".beam")
    var loaded_module: ptr Module = sys_load_module(global, module_name)
    free(module_name)
    if UNLIKELY(not loaded_module or
        (globalcontext_insert_module(global, loaded_module, module_name_atom) < 0)):
      return nil
    return loaded_module
  return found_module
