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

type
  ValuesHashTable* {.bycopy.} = object
    capacity*: cint
    count*: cint
    buckets*: ptr ptr HNode


proc valueshashtable_new*(): ptr ValuesHashTable {.cdecl.}
proc valueshashtable_insert*(hash_table: ptr ValuesHashTable; key: culong;
                            value: culong): cint {.cdecl.}
proc valueshashtable_get_value*(hash_table: ptr ValuesHashTable; key: culong;
                               default_value: culong): culong {.cdecl.}
proc valueshashtable_has_key*(hash_table: ptr ValuesHashTable; key: culong): cint {.
    cdecl.}