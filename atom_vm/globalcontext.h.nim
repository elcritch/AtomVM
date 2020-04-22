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
## *
##  @file globalcontext.h
##  @brief GlobalContext struct and releated management functions
##
##  @details GlobalContext keeps the state of an AtomVM instance, multiple instances can run simultanously.
##

import
  atom, term, linkedlist

type
  Context* = object

  GlobalContext* = object

  Module* = object

  GlobalContext* = object
    ready_processes*: ListHead
    waiting_processes*: ListHead
    processes_table*: ptr ListHead
    registered_processes*: ptr ListHead
    last_process_id*: int32_t
    atoms_table*: ptr AtomsHashTable
    atoms_ids_table*: ptr ValuesHashTable
    modules_table*: ptr AtomsHashTable
    modules_by_index*: ptr ptr Module
    loaded_modules_count*: cint
    avmpack_data*: pointer
    avmpack_platform_data*: pointer
    timer_wheel*: ptr TimerWheel
    last_seen_millis*: uint32_t
    ref_ticks*: uint64_t
    platform_data*: pointer


## *
##  @brief Creates a new GlobalContext
##
##  @details Allocates a new GlobalContext struct and initialize it, the newly created global context is a new AtomVM instance.
##  @returns A newly created GlobalContext.
##

proc globalcontext_new*(): ptr GlobalContext {.cdecl.}
## *
##  @brief Destoys an existing GlobalContext
##
##  @details Frees global context resources and memory and removes it from the processes table.
##  @param c the global context that will be destroyed.
##

proc globalcontext_destroy*(glb: ptr GlobalContext) {.cdecl.}
## *
##  @brief Gets a Context from the process table
##
##  @details Retrieves from the process table the context with the given local process id.
##  @param glb the global context (that owns the process table).
##  @param process_id the local process id.
##  @returns a Context * with the requested local process id.
##

proc globalcontext_get_process*(glb: ptr GlobalContext; process_id: int32_t): ptr Context {.
    cdecl.}
## *
##  @brief Gets a new process id
##
##  @details Returns a new (unused) process id, this functions should be used to allocate a new local process id.
##  @param glb the global context.
##  @returns A new local process id integer.
##

proc globalcontext_get_new_process_id*(glb: ptr GlobalContext): int32_t {.cdecl.}
## *
##  @brief Register a process
##
##  @details Register a process with a certain name (atom) so it can be easily retrieved later.
##  @param glb the global context, each registered process will be globally available for that context.
##  @param atom_index the atom table index.
##  @param local_process_id the process local id.
##

proc globalcontext_register_process*(glb: ptr GlobalContext; atom_index: cint;
                                    local_process_id: cint) {.cdecl.}
## *
##  @brief Get a registered process
##
##  @details Returns the local process id of a previously registered process.
##  @param glb the global context.
##  @param atom_index the atom table index.
##  @returns a previously registered process local id.
##

proc globalcontext_get_registered_process*(glb: ptr GlobalContext; atom_index: cint): cint {.
    cdecl.}
## *
##  @brief equivalent to globalcontext_insert_atom_maybe_copy(glb, atom_string, 0);
##

proc globalcontext_insert_atom*(glb: ptr GlobalContext; atom_string: AtomString): cint {.
    cdecl.}
## *
##  @brief Inserts an atom into the global atoms table, making a copy of the supplied atom
##  string, if copy is non-zero.
##
##  @details Inserts an atom into the global atoms table and returns its id.
##  @param glb the global context.
##  @param atom_string the atom string that will be added to the global atoms table, it will not be copied so it must stay allocated and valid.
##  @param copy if non-zero, make a copy of the input atom_string if the atom is not already in the table.  The table
##  assumes "ownership" of the allocated memory.
##  @returns newly added atom id or -1 in case of failure.
##

proc globalcontext_insert_atom_maybe_copy*(glb: ptr GlobalContext;
    atom_string: AtomString; copy: cint): cint {.cdecl.}
## *
##  @brief   Returns the AtomString value of a term.
##
##  @details This function fetches the AtomString value of the atom associated
##           with the supplied term.  The input term must be an atom type.
##           If no such atom is registered in the global table, this function
##           returns NULL.  The caller should NOT free the data associated with
##           the returned value.
##  @param   glb the global context
##  @param   t the atom term
##  @returns the AtomString associated with the supplied atom term.
##

proc globalcontext_atomstring_from_term*(glb: ptr GlobalContext; t: term): AtomString {.
    cdecl.}
##
##  @brief Insert an already loaded module with a certain filename to the modules table.
##
##  @details Insert an already loaded module to the modules table using the filename without ".beam" as the module name.
##  @param glb the global context.
##  @param module the module that will be added to the modules table.
##  @param filename module filename (without the path).
##

proc globalcontext_insert_module_with_filename*(glb: ptr GlobalContext;
    module: ptr Module; filename: cstring) {.cdecl.}
## *
##  @brief Inserts a module to the modules table.
##
##  @details Inserts an already loaded module to the modules table and assigns and index to it so it can be retrieved later by name or index.
##  @param global the global context.
##  @param module the module that will be added to the modules table.
##  @param module_name_atom the module name (as AtomString).
##  @returns the module index if successful, otherwise -1.
##

proc globalcontext_insert_module*(global: ptr GlobalContext; module: ptr Module;
                                 module_name_atom: AtomString): cint {.cdecl.}
## *
##  @brief Returns the module with the given name
##
##  @details Tries to get the module with the given name from the modules table and eventually loads it.
##  @param global the global context.
##  @param module_name_atom the module name.
##  @returns a pointer to a Module struct.
##

proc globalcontext_get_module*(global: ptr GlobalContext;
                              module_name_atom: AtomString): ptr Module {.cdecl.}
proc globalcontext_get_ref_ticks*(global: ptr GlobalContext): uint64_t {.inline, cdecl.} =
  return inc(global.ref_ticks)
