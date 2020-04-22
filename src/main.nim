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
  atom, avmpack, bif, context, globalcontext, iff, platforms/generic_unix/mapped_file,
  module, utils, term

var ok_a*: string = "\x02ok"

proc main*(argc: cint; argv: stringArray): cint {.cdecl.} =
  if argc < 2:
    printf("Need .beam file\n")
    return EXIT_FAILURE

  var mapped_file: ptr MappedFile = mapped_file_open_beam(argv[1])

  if IS_NULL_PTR(mapped_file):
    return EXIT_FAILURE

  var glb: ptr GlobalContext = globalcontext_new()
  var startup_beam: pointer
  var startup_beam_size: uint32_t
  var startup_module_name: string = argv[1]

  if avmpack_is_valid(mapped_file.mapped, mapped_file.size):
    glb.avmpack_data = mapped_file.mapped
    glb.avmpack_platform_data = mapped_file
    if not avmpack_find_section_by_flag(mapped_file.mapped, 1, addr(startup_beam),
                                      addr(startup_beam_size),
                                      addr(startup_module_name)):
      fprintf(stderr, "%s cannot be started.\n", argv[1])
      mapped_file_close(mapped_file)
      return EXIT_FAILURE
  elif iff_is_valid_beam(mapped_file.mapped):
    glb.avmpack_data = nil
    glb.avmpack_platform_data = nil
    startup_beam = mapped_file.mapped
    startup_beam_size = mapped_file.size
  else:
    fprintf(stderr, "%s is not a BEAM file.\n", argv[1])
    mapped_file_close(mapped_file)
    return EXIT_FAILURE

  var `mod`: ptr Module = module_new_from_iff_binary(glb, startup_beam,
      startup_beam_size)

  if IS_NULL_PTR(`mod`):
    fprintf(stderr, "Cannot load startup module: %s\n", startup_module_name)
    return EXIT_FAILURE

  globalcontext_insert_module_with_filename(glb, mods, startup_module_name)
  mods.module_platform_data = nil
  var ctx: ptr Context = context_new(glb)
  ctx.leader = 1

  context_execute_loop(ctx, `mod`, "start", 0)

  var ret_value: term = ctx.x[0]

  writeLine(stderr, "Return value: ")
  term_display(stderr, ret_value, ctx)
  writeLine(stderr, "\n")

  var ok_atom: term = context_make_atom(ctx, ok_a)

  context_destroy(ctx)
  globalcontext_destroy(glb)
  module_destroy(`mod`)
  mapped_file_close(mapped_file)

  if ok_atom == ret_value:
    return EXIT_SUCCESS
  else:
    return EXIT_FAILURE
