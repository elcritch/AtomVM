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
  avmpack, utils

const
  AVMPACK_SIZE* = 24

proc pad*(size: cint): cint {.inline, cdecl.} =
  return ((size + 4 - 1) shr 2) shl 2

proc avmpack_is_valid*(avmpack_binary: pointer; size: uint32_t): cint {.cdecl.} =
  var pack_header: array[AVMPACK_SIZE, cuchar] = [0x00000023, 0x00000021, 0x0000002F,
      0x00000075, 0x00000073, 0x00000072, 0x0000002F, 0x00000062, 0x00000069,
      0x0000006E, 0x0000002F, 0x00000065, 0x0000006E, 0x00000076, 0x00000020,
      0x00000041, 0x00000074, 0x0000006F, 0x0000006D, 0x00000056, 0x0000004D,
      0x0000000A, 0x00000000, 0x00000000]
  if UNLIKELY(size < 24):
    return 0
  return memcmp(avmpack_binary, pack_header, AVMPACK_SIZE) == 0

proc avmpack_find_section_by_flag*(avmpack_binary: pointer; flags_mask: uint32_t;
                                  `ptr`: ptr pointer; size: ptr uint32_t;
                                  name: stringArray): cint {.cdecl.} =
  var offset: cint = AVMPACK_SIZE
  var flags: ptr uint32_t
  while true:
    var sizes: ptr uint32_t = (cast[ptr uint32_t]((avmpack_binary))) +
        offset div sizeof((uint32_t))
    flags = (cast[ptr uint32_t]((avmpack_binary))) + 1 +
        offset div sizeof((uint32_t))
    if (ENDIAN_SWAP_32(flags[]) and flags_mask) == flags_mask:
      var found_section_name: string = cast[string]((sizes + 3))
      var section_name_len: cint = pad(strlen(found_section_name) + 1)
      `ptr`[] = sizes + 3 + section_name_len div sizeof((uint32_t))
      size[] = ENDIAN_SWAP_32(sizes[])
      name[] = cast[string]((sizes + 3))
      return 1
    inc(offset, ENDIAN_SWAP_32(sizes[]))
    if not flags[]:
      break
  return 0

proc avmpack_find_section_by_name*(avmpack_binary: pointer; name: string;
                                  `ptr`: ptr pointer; size: ptr uint32_t): cint {.cdecl.} =
  var offset: cint = AVMPACK_SIZE
  var flags: ptr uint32_t
  while true:
    var sizes: ptr uint32_t = (cast[ptr uint32_t]((avmpack_binary))) +
        offset div sizeof((uint32_t))
    flags = (cast[ptr uint32_t]((avmpack_binary))) + 1 +
        offset div sizeof((uint32_t))
    var found_section_name: string = cast[string]((sizes + 3))
    if not strcmp(name, found_section_name):
      var section_name_len: cint = pad(strlen(found_section_name) + 1)
      `ptr`[] = sizes + 3 + section_name_len div sizeof((uint32_t))
      size[] = ENDIAN_SWAP_32(sizes[])
      return 1
    inc(offset, ENDIAN_SWAP_32(sizes[]))
    if not flags[]:
      break
  return 0

proc avmpack_fold*(accum: pointer; avmpack_binary: pointer;
                  fold_fun: avmpack_fold_fun): pointer {.cdecl.} =
  var offset: cint = AVMPACK_SIZE
  var size: uint32_t = 0
  while true:
    var size_ptr: ptr uint32_t = (cast[ptr uint32_t]((avmpack_binary))) +
        offset div sizeof((uint32_t))
    size = ENDIAN_SWAP_32(size_ptr[])
    if size > 0:
      var flags_ptr: ptr uint32_t = size_ptr + 1
      var flags: uint32_t = ENDIAN_SWAP_32(flags_ptr[])
      var section_name: string = cast[string]((size_ptr + 3))
      var section_name_len: cint = pad(strlen(section_name) + 1)
      accum = fold_fun(accum, size_ptr, size,
                     size_ptr + 3 + section_name_len div sizeof((uint32_t)), flags,
                     section_name)
      inc(offset, size)
    if not (size > 0):
      break
  return accum
