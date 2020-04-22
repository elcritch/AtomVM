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
  hashes, tables

type
  AtomId* = distinct uint32
  AtomString* = ref object
    str*: string

proc hash(x: AtomString): Hash =
  ## Piggyback on the already available string hash proc.
  ##
  ## Without this proc nothing works!
  result = x.str.hash 
  result = !$result

proc `==`*(a, b: AtomString): bool =
  if not a.isNil and not b.isNil:
    return a.str == b.str
  else:
    return system.`==`(a, b)

proc atom_write_mfa*(module: AtomString; function: AtomString; arity: uint): string {.cdecl.} =
  ## @brief Write module:function/arity to the supplied buffer.
  ##
  ## @details Write module:function/arity to the supplied buffer.  This function will abort
  ##          if the written module, function, and arity are longer than the supplied
  ##          buffer size.
  ## @param   buf the buffer to write into
  ## @param   buf_size the amount of room in the buffer
  ## @param   module the module name
  ## @param   function the function name
  ## @param   arity the function arity
  result = $(module.str) & ":" & $(function.str) & "/" & $(arity)
