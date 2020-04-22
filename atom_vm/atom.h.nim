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
##  @file atom.h
##  @brief Atoms manipulation functions
##
##  @details This header provides atom manipulation functions, such as atom_string_len, atom_string_data, etc...
##

type
  AtomString* = pointer

## *
##  @brief Gets a C string from an AtomString
##
##  @details Copies the atom string data to a bufffer and makes it null terminated.
##  @param atom_string that will be converted to a C string.
##  @param buf the buffer where the C string will be written.
##  @param bufsize available buf size.
##

proc atom_string_to_c*(atom_string: AtomString; buf: cstring; bufsize: cint) {.cdecl.}
## *
##  @brief Check for equality two AtomStrings
##
##  @details Returns 1 if two atom strings are equal, 0 otherwise. This function doesn't behave like strcmp.
##  @param a first atom string to be compared.
##  @param b second atom string to be compared.
##  @returns 1 if they are equals, 0 otherwise.
##

proc atom_are_equals*(a: AtomString; b: AtomString): cint {.cdecl.}
## *
##  @brief Returns the length of an atom string in bytes.
##
##  @details Returns the length stored in the AtomString (which means that length is not computed).
##  @param atom_str the atom string.
##  @returns the specified atom string length.
##

proc atom_string_len*(atom_str: AtomString): cint {.inline, cdecl.} =
  return (cast[ptr uint8_t](atom_str))[]

## *
##  @brief Gets actual atom string data.
##
##  @details Returns actual atom string data, which is not a \0 terminated C string.
##  @param atom_str an AtomString pointer.
##  @returns const pointer to string data (chars array).
##

proc atom_string_data*(atom_str: AtomString): pointer {.inline, cdecl.} =
  return (cast[ptr uint8_t](atom_str)) + 1

## *
##  @brief Write module:function/arity to the supplied buffer.
##
##  @details Write module:function/arity to the supplied buffer.  This function will abort
##           if the written module, function, and arity are longer than the supplied
##           buffer size.
##  @param   buf the buffer to write into
##  @param   buf_size the amount of room in the buffer
##  @param   module the module name
##  @param   function the function name
##  @param   arity the function arity
##

proc atom_write_mfa*(buf: cstring; buf_size: csize; module: AtomString;
                    function: AtomString; arity: cint) {.cdecl.}