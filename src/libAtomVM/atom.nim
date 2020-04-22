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
  atom, utils

proc atom_string_to_c*(atom_string: AtomString; buf: cstring; bufsize: cint) {.cdecl.} =
  var atom_len: cint = (cast[ptr uint8_t](atom_string))[]
  if bufsize < atom_len:
    atom_len = bufsize - 1
  memcpy(buf, (cast[ptr uint8_t](atom_string)) + 1, atom_len)
  buf[atom_len] = '\x00'

proc atom_are_equals*(a: AtomString; b: AtomString): cint {.cdecl.} =
  var atom_len_a: cint = (cast[ptr uint8_t](a))[]
  var atom_len_b: cint = (cast[ptr uint8_t](b))[]
  if atom_len_a != atom_len_b:
    return 0
  if not memcmp(cast[ptr uint8_t](a) + 1, cast[ptr uint8_t](b) + 1, atom_len_a):
    return 1
  else:
    return 0

proc atom_write_mfa*(buf: cstring; buf_size: csize; module: AtomString;
                    function: AtomString; arity: cint) {.cdecl.} =
  var module_name_len: cuint = atom_string_len(module)
  memcpy(buf, atom_string_data(module), module_name_len)
  buf[module_name_len] = ':'
  var function_name_len: cuint = atom_string_len(function)
  if UNLIKELY((arity > 9) or (module_name_len + function_name_len + 4 > buf_size)):
    fprintf(stderr, "Insufficient room to write mfa.\n")
    abort()
  memcpy(buf + module_name_len + 1, atom_string_data(function), function_name_len)
  ## TODO: handle functions with more than 9 parameters
  buf[module_name_len + function_name_len + 1] = '/'
  buf[module_name_len + function_name_len + 2] = '0' + arity
  buf[module_name_len + function_name_len + 3] = 0
