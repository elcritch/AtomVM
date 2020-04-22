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
  iff, utils

type
  IFFRecord* = object
    name*: array[4, char]
    size*: uint32_t


proc iff_align*(size: uint32_t): uint32_t {.cdecl.} =
  return ((size + 4 - 1) shr 2) shl 2

proc iff_is_valid_beam*(beam_data: pointer): cint {.cdecl.} =
  return memcmp(beam_data, "FOR1", 4) == 0

proc scan_iff*(iff_binary: pointer; buf_size: cint; offsets: ptr culong;
              sizes: ptr culong) {.cdecl.} =
  var data: ptr uint8_t = iff_binary
  memset(offsets, 0, sizeof(cast[culong](MAX_OFFS[])))
  memset(sizes, 0, sizeof(cast[culong](MAX_SIZES[])))
  var current_pos: cint = 12
  var iff_size: uint32_t = READ_32_ALIGNED(data + 4)
  var file_size: cint = iff_size
  if UNLIKELY(buf_size < file_size):
    fprintf(stderr, "warning: buffer holding IFF is smaller than IFF size: %i",
            buf_size)
  while true:
    var current_record: ptr IFFRecord = cast[ptr IFFRecord]((data + current_pos))
    if not memcmp(current_record.name, "AtU8", 4):
      offsets[AT8U] = current_pos
      sizes[AT8U] = ENDIAN_SWAP_32(current_record.size)
    elif not memcmp(current_record.name, "Code", 4):
      offsets[CODE] = current_pos
      sizes[CODE] = ENDIAN_SWAP_32(current_record.size)
    elif not memcmp(current_record.name, "ExpT", 4):
      offsets[EXPT] = current_pos
      sizes[EXPT] = ENDIAN_SWAP_32(current_record.size)
    elif not memcmp(current_record.name, "LocT", 4):
      offsets[LOCT] = current_pos
      sizes[LOCT] = ENDIAN_SWAP_32(current_record.size)
    elif not memcmp(current_record.name, "LitT", 4):
      offsets[LITT] = current_pos
      sizes[LITT] = ENDIAN_SWAP_32(current_record.size)
    elif not memcmp(current_record.name, "LitU", 4):
      offsets[LITU] = current_pos
      sizes[LITU] = ENDIAN_SWAP_32(current_record.size)
    elif not memcmp(current_record.name, "ImpT", 4):
      offsets[IMPT] = current_pos
      sizes[IMPT] = ENDIAN_SWAP_32(current_record.size)
    elif not memcmp(current_record.name, "FunT", 4):
      offsets[FUNT] = current_pos
      sizes[FUNT] = ENDIAN_SWAP_32(current_record.size)
    elif not memcmp(current_record.name, "StrT", 4):
      offsets[STRT] = current_pos
      sizes[STRT] = ENDIAN_SWAP_32(current_record.size)
    inc(current_pos, iff_align(ENDIAN_SWAP_32(current_record.size) + 8))
    if not (current_pos < file_size):
      break
