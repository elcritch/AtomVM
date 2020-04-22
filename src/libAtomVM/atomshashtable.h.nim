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
  atom

type
  AtomsHashTable* {.bycopy.} = object
    capacity*: cint
    count*: cint
    buckets*: ptr ptr HNode


proc atomshashtable_new*(): ptr AtomsHashTable {.cdecl.}
proc atomshashtable_insert*(hash_table: ptr AtomsHashTable; string: AtomString;
                           value: culong): cint {.cdecl.}
proc atomshashtable_get_value*(hash_table: ptr AtomsHashTable; string: AtomString;
                              default_value: culong): culong {.cdecl.}
proc atomshashtable_has_key*(hash_table: ptr AtomsHashTable; string: AtomString): cint {.
    cdecl.}
template TO_ATOMSHASHTABLE_VALUE*(value: untyped): untyped =
  (cast[culong]((value)))
