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
  module, atom, bif, context, externalterm, iff, nifs, utils

when defined(WITH_ZLIB):
const
  LITT_UNCOMPRESSED_SIZE_OFFSET* = 8
  LITT_HEADER_SIZE* = 12

when defined(WITH_ZLIB):
  proc module_uncompress_literals*(litT: ptr uint8_t; size: cint): pointer {.cdecl.}
proc module_build_literals_table*(literalsBuf: pointer): ptr pointer {.cdecl.}
proc module_add_label*(`mod`: ptr Module; index: cint; `ptr`: pointer) {.cdecl.}
proc module_build_imported_functions_table*(this_module: ptr Module;
    table_data: ptr uint8_t): ModuleLoadResult {.cdecl.}
proc module_add_label*(`mod`: ptr Module; index: cint; `ptr`: pointer) {.cdecl.}
const
  IMPL_CODE_LOADER* = 1

import
  opcodesswitch

proc module_populate_atoms_table*(this_module: ptr Module; table_data: ptr uint8_t): ModuleLoadResult {.
    cdecl.} =
  var atoms_count: cint = READ_32_ALIGNED(table_data + 8)
  var current_atom: string = cast[string](table_data) + 12
  this_module.local_atoms_to_global_table = calloc(atoms_count + 1, sizeof((int)))
  if IS_NULL_PTR(this_module.local_atoms_to_global_table):
    fprintf(stderr, "Cannot allocate memory while loading module (line: %i).\n",
            __LINE__)
    return MODULE_ERROR_FAILED_ALLOCATION
  var atom: string = nil
  var i: cint = 1
  while i <= atoms_count:
    var atom_len: cint = current_atom[]
    atom = current_atom
    var global_atom_id: cint = globalcontext_insert_atom(this_module.global,
        cast[AtomString](atom))
    if UNLIKELY(global_atom_id < 0):
      fprintf(stderr,
              "Cannot allocate memory while loading module (line: %i).\n",
              __LINE__)
      return MODULE_ERROR_FAILED_ALLOCATION
    this_module.local_atoms_to_global_table[i] = global_atom_id
    inc(current_atom, atom_len + 1)
    inc(i)
  return MODULE_LOAD_OK

proc module_build_imported_functions_table*(this_module: ptr Module;
    table_data: ptr uint8_t): ModuleLoadResult {.cdecl.} =
  var functions_count: cint = READ_32_ALIGNED(table_data + 8)
  this_module.imported_funcs = calloc(functions_count, sizeof(pointer))
  if IS_NULL_PTR(this_module.imported_funcs):
    fprintf(stderr, "Cannot allocate memory while loading module (line: %i).\n",
            __LINE__)
    return MODULE_ERROR_FAILED_ALLOCATION
  var i: cint = 0
  while i < functions_count:
    var local_module_atom_index: cint = READ_32_ALIGNED(table_data + i * 12 + 12)
    var local_function_atom_index: cint = READ_32_ALIGNED(
        table_data + i * 12 + 4 + 12)
    var module_atom: AtomString = module_get_atom_string_by_id(this_module,
        local_module_atom_index)
    var function_atom: AtomString = module_get_atom_string_by_id(this_module,
        local_function_atom_index)
    var arity: uint32_t = READ_32_ALIGNED(table_data + i * 12 + 8 + 12)
    var bif_handler: BifImpl = bif_registry_get_handler(module_atom, function_atom,
        arity)
    if bif_handler:
      this_module.imported_funcs[i].bif = bif_handler
    else:
      this_module.imported_funcs[i].`func` = addr(nifs_get(module_atom,
          function_atom, arity).base)
    if not this_module.imported_funcs[i].`func`:
      var unresolved: ptr UnresolvedFunctionCall = malloc(
          sizeof(UnresolvedFunctionCall))
      if IS_NULL_PTR(unresolved):
        fprintf(stderr,
                "Cannot allocate memory while loading module (line: %i).\n",
                __LINE__)
        return MODULE_ERROR_FAILED_ALLOCATION
      unresolved.base.`type` = UnresolvedFunctionCall
      unresolved.module_atom_index = this_module.local_atoms_to_global_table[
          local_module_atom_index]
      unresolved.function_atom_index = this_module.local_atoms_to_global_table[
          local_function_atom_index]
      unresolved.arity = arity
      this_module.imported_funcs[i].`func` = addr(unresolved.base)
    inc(i)
  return MODULE_LOAD_OK

when defined(ENABLE_ADVANCED_TRACE):
  proc module_get_imported_function_module_and_name*(this_module: ptr Module;
      index: cint; module_atom: ptr AtomString; function_atom: ptr AtomString) {.cdecl.} =
    var table_data: ptr uint8_t = cast[ptr uint8_t](this_module.import_table)
    var functions_count: cint = READ_32_ALIGNED(table_data + 8)
    if UNLIKELY(index > functions_count):
      abort()
    var local_module_atom_index: cint = READ_32_ALIGNED(table_data + index * 12 + 12)
    var local_function_atom_index: cint = READ_32_ALIGNED(
        table_data + index * 12 + 4 + 12)
    module_atom[] = module_get_atom_string_by_id(this_module,
        local_module_atom_index)
    function_atom[] = module_get_atom_string_by_id(this_module,
        local_function_atom_index)

proc module_search_exported_function*(this_module: ptr Module;
                                     func_name: AtomString; func_arity: cint): uint32_t {.
    cdecl.} =
  var table_data: ptr uint8_t = cast[ptr uint8_t](this_module.export_table)
  var functions_count: cint = READ_32_ALIGNED(table_data + 8)
  var i: cint = 0
  while i < functions_count:
    var function_atom: AtomString = module_get_atom_string_by_id(this_module,
        READ_32_ALIGNED(table_data + i * 12 + 12))
    var arity: int32_t = READ_32_ALIGNED(table_data + i * 12 + 4 + 12)
    if (func_arity == arity) and atom_are_equals(func_name, function_atom):
      var label: uint32_t = READ_32_ALIGNED(table_data + i * 12 + 8 + 12)
      return label
    inc(i)
  return 0

proc module_add_label*(`mod`: ptr Module; index: cint; `ptr`: pointer) {.cdecl.} =
  `mod`.labels[index] = `ptr`

proc module_new_from_iff_binary*(global: ptr GlobalContext; iff_binary: pointer;
                                size: culong): ptr Module {.cdecl.} =
  var beam_file: ptr uint8_t = cast[pointer](iff_binary)
  var offsets: array[MAX_OFFS, culong]
  var sizes: array[MAX_SIZES, culong]
  scan_iff(beam_file, size, offsets, sizes)
  var `mod`: ptr Module = malloc(sizeof((Module)))
  if IS_NULL_PTR(`mod`):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    return nil
  memset(`mod`, 0, sizeof((Module)))
  `mod`.module_index = -1
  `mod`.global = global
  if UNLIKELY(module_populate_atoms_table(`mod`, beam_file + offsets[AT8U]) !=
      MODULE_LOAD_OK):
    module_destroy(`mod`)
    return nil
  if UNLIKELY(module_build_imported_functions_table(`mod`,
      beam_file + offsets[IMPT]) != MODULE_LOAD_OK):
    module_destroy(`mod`)
    return nil
  when defined(ENABLE_ADVANCED_TRACE):
    `mod`.import_table = beam_file + offsets[IMPT]
  `mod`.code = cast[ptr CodeChunk]((beam_file + offsets[CODE]))
  `mod`.export_table = beam_file + offsets[EXPT]
  `mod`.atom_table = beam_file + offsets[AT8U]
  `mod`.fun_table = beam_file + offsets[FUNT]
  `mod`.str_table = beam_file + offsets[STRT]
  `mod`.str_table_len = sizes[STRT]
  `mod`.labels = calloc(ENDIAN_SWAP_32(`mod`.code.labels), sizeof(pointer))
  if IS_NULL_PTR(`mod`.labels):
    module_destroy(`mod`)
    return nil
  if offsets[LITT]:
    when defined(WITH_ZLIB):
      `mod`.literals_data = module_uncompress_literals(beam_file + offsets[LITT],
          sizes[LITT])
      if IS_NULL_PTR(`mod`.literals_data):
        module_destroy(`mod`)
        return nil
    `mod`.literals_table = module_build_literals_table(`mod`.literals_data)
    `mod`.free_literals_data = 1
  elif offsets[LITU]:
    `mod`.literals_data = beam_file + offsets[LITU] + IFF_SECTION_HEADER_SIZE
    `mod`.literals_table = module_build_literals_table(`mod`.literals_data)
    `mod`.free_literals_data = 0
  else:
    `mod`.literals_data = nil
    `mod`.literals_table = nil
    `mod`.free_literals_data = 0
  `mod`.end_instruction_ii = read_core_chunk(`mod`)
  return `mod`

##  TODO: FIXME
##  COLD_FUNC void module_destroy(Module *module)

proc module_destroy*(module: ptr Module) {.cdecl.} =
  free(module.labels)
  free(module.imported_funcs)
  free(module.literals_table)
  if module.free_literals_data:
    free(module.literals_data)
  free(module)

when defined(WITH_ZLIB):
  proc module_uncompress_literals*(litT: ptr uint8_t; size: cint): pointer {.cdecl.} =
    var required_buf_size: cuint = READ_32_ALIGNED(
        litT + LITT_UNCOMPRESSED_SIZE_OFFSET)
    var outBuf: ptr uint8_t = malloc(required_buf_size)
    if IS_NULL_PTR(outBuf):
      fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
      return nil
    var infstream: z_stream
    infstream.zalloc = Z_NULL
    infstream.zfree = Z_NULL
    infstream.opaque = Z_NULL
    infstream.avail_in = (uInt)(size - IFF_SECTION_HEADER_SIZE)
    infstream.next_in = cast[ptr Bytef]((litT + LITT_HEADER_SIZE))
    infstream.avail_out = cast[uInt](required_buf_size)
    infstream.next_out = cast[ptr Bytef](outBuf)
    var ret: cint = inflateInit(addr(infstream))
    if ret != Z_OK:
      fprintf(stderr, "Failed inflateInit\n")
      return nil
    ret = inflate(addr(infstream), Z_NO_FLUSH)
    if ret != Z_OK:
      fprintf(stderr, "Failed inflate\n")
      return nil
    inflateEnd(addr(infstream))
    return outBuf

proc module_build_literals_table*(literalsBuf: pointer): ptr pointer {.cdecl.} =
  var terms_count: uint32_t = READ_32_ALIGNED(literalsBuf)
  var pos: ptr uint8_t = cast[ptr uint8_t](literalsBuf) + sizeof((uint32_t))
  var literals_table: ptr pointer = calloc(terms_count, sizeof((void * `const`)))
  if IS_NULL_PTR(literals_table):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    return nil
  var i: uint32_t = 0
  while i < terms_count:
    var term_size: uint32_t = READ_32_UNALIGNED(pos)
    literals_table[i] = pos + sizeof((uint32_t))
    inc(pos, term_size + sizeof((uint32_t)))
    inc(i)
  return literals_table

proc module_load_literal*(`mod`: ptr Module; index: cint; ctx: ptr Context): term {.cdecl.} =
  return externalterm_to_term(`mod`.literals_table[index], ctx, 1)

proc module_resolve_function*(`mod`: ptr Module; import_table_index: cint): ptr ExportedFunction {.
    cdecl.} =
  var `func`: ptr ExportedFunction = cast[ptr ExportedFunction](`mod`.imported_funcs[
      import_table_index].`func`)
  var unresolved: ptr UnresolvedFunctionCall = EXPORTED_FUNCTION_TO_UNRESOLVED_FUNCTION_CALL(
      `func`)
  var module_name_atom: AtomString = cast[AtomString](valueshashtable_get_value(
      `mod`.global.atoms_ids_table, unresolved.module_atom_index,
      cast[culong](nil)))
  var function_name_atom: AtomString = cast[AtomString](valueshashtable_get_value(
      `mod`.global.atoms_ids_table, unresolved.function_atom_index,
      cast[culong](nil)))
  var arity: cint = unresolved.arity
  var found_module: ptr Module = globalcontext_get_module(`mod`.global,
      module_name_atom)
  if LIKELY(found_module != nil):
    var exported_label: cint = module_search_exported_function(found_module,
        function_name_atom, arity)
    if exported_label == 0:
      var buf: array[256, char]
      atom_write_mfa(buf, 256, module_name_atom, function_name_atom, arity)
      fprintf(stderr, "Warning: function %s cannot be resolved.\n", buf)
      return nil
    var mfunc: ptr ModuleFunction = malloc(sizeof(ModuleFunction))
    if IS_NULL_PTR(mfunc):
      fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
      return nil
    mfunc.base.`type` = ModuleFunction
    mfunc.target = found_module
    mfunc.label = exported_label
    free(unresolved)
    `mod`.imported_funcs[import_table_index].`func` = addr(mfunc.base)
    return addr(mfunc.base)
  else:
    var buf: array[256, char]
    atom_string_to_c(module_name_atom, buf, 256)
    fprintf(stderr, "Warning: module %s cannot be resolved.\n", buf)
    return nil
