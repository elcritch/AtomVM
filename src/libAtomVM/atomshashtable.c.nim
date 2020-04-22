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
  atomshashtable, utils

const
  DEFAULT_SIZE* = 8

type
  HNode* {.bycopy.} = object
    next*: ptr HNode
    key*: AtomString
    value*: culong


proc sdbm_hash*(str: ptr cuchar; len: cint): culong {.cdecl.} =
  var hash: culong = 0
  var c: cint
  var i: cint = 0
  while i < len:
    c = inc(str)[]
    hash = c + (hash shl 6) + (hash shl 16) - hash
    inc(i)
  return hash

proc atomshashtable_new*(): ptr AtomsHashTable {.cdecl.} =
  var htable: ptr AtomsHashTable = malloc(sizeof(AtomsHashTable))
  if IS_NULL_PTR(htable):
    return nil
  htable.buckets = calloc(DEFAULT_SIZE, sizeof(ptr HNode))
  if IS_NULL_PTR(htable.buckets):
    free(htable)
    return nil
  htable.count = 0
  htable.capacity = DEFAULT_SIZE
  return htable

proc atomshashtable_insert*(hash_table: ptr AtomsHashTable; string: AtomString;
                           value: culong): cint {.cdecl.} =
  var alen: cint = atom_string_len(string)
  var hash: culong = sdbm_hash(string, alen)
  var index: clong = hash mod hash_table.capacity
  var node: ptr HNode = hash_table.buckets[index]
  if node:
    while 1:
      if atom_are_equals(string, node.key):
        node.value = value
        return 1
      if node.next:
        node = node.next
      else:
        break
  var new_node: ptr HNode = malloc(sizeof(HNode))
  if IS_NULL_PTR(new_node):
    return 0
  new_node.next = nil
  new_node.key = string
  new_node.value = value
  if node:
    node.next = new_node
  else:
    hash_table.buckets[index] = new_node
  inc(hash_table.count)
  return 1

proc atomshashtable_get_value*(hash_table: ptr AtomsHashTable; string: AtomString;
                              default_value: culong): culong {.cdecl.} =
  var hash: culong = sdbm_hash(string, atom_string_len(string))
  var index: clong = hash mod hash_table.capacity
  var node: ptr HNode = hash_table.buckets[index]
  while node:
    if atom_are_equals(string, node.key):
      return node.value
    node = node.next
  return default_value

proc atomshashtable_has_key*(hash_table: ptr AtomsHashTable; string: AtomString): cint {.
    cdecl.} =
  var hash: culong = sdbm_hash(string, atom_string_len(string))
  var index: clong = hash mod hash_table.capacity
  var node: ptr HNode = hash_table.buckets[index]
  while node:
    if atom_are_equals(string, node.key):
      return 1
    node = node.next
  return 0
