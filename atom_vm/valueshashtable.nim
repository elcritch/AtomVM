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
  valueshashtable, utils

const
  DEFAULT_SIZE* = 8

type
  HNode* = object
    next*: ptr HNode
    key*: culong
    value*: culong


proc valueshashtable_new*(): ptr ValuesHashTable =
  var htable: ptr ValuesHashTable = malloc(sizeof(ValuesHashTable))
  if IS_NULL_PTR(htable):
    return nil
  htable.buckets = calloc(DEFAULT_SIZE, sizeof(ptr HNode))
  if IS_NULL_PTR(htable.buckets):
    free(htable)
    return nil
  htable.count = 0
  htable.capacity = DEFAULT_SIZE
  return htable

proc valueshashtable_insert*(hash_table: ptr ValuesHashTable; key: culong;
                            value: culong): cint =
  var index: clong = key mod hash_table.capacity
  var node: ptr HNode = hash_table.buckets[index]
  if node:
    while 1:
      if node.key == key:
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
  new_node.key = key
  new_node.value = value
  if node:
    node.next = new_node
  else:
    hash_table.buckets[index] = new_node
  inc(hash_table.count)
  return 1

proc valueshashtable_get_value*(hash_table: ptr ValuesHashTable; key: culong;
                               default_value: culong): culong =
  var index: clong = key mod hash_table.capacity
  var node: ptr HNode = hash_table.buckets[index]
  while node:
    if node.key == key:
      return node.value
    node = node.next
  return default_value

proc valueshashtable_has_key*(hash_table: ptr ValuesHashTable; key: culong): cint {.
    cdecl.} =
  var index: clong = key mod hash_table.capacity
  var node: ptr HNode = hash_table.buckets[index]
  while node:
    if node.key == key:
      return 1
    node = node.next
  return 0
