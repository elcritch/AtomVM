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
##  @file linkedlist.h
##  @brief Linked list manipulation functions
##
##  @details This header implements manipulation functions for doubly linked circular linked lists.
##

##
##  @brief a struct requires a ListHead member to be used with linked list manipulation functions.
##
##  @detail Each struct that is going to be used as part of a linked list should have at least one ListHead,
##  each head can be used for a different linked list.
##

type
  ListHead* = object
    next*: ptr ListHead
    prev*: ptr ListHead


## *
##  @brief gets a pointer to the struct that contains a certain list head
##
##  @details This macro should be used to retrieve a pointer to the struct that is containing the given ListHead.
##

template GET_LIST_ENTRY*(list_item, `type`, list_head_member: untyped): untyped =
  (cast[ptr `type`](((cast[cstring]((list_item))) -
      (cast[culong](addr((cast[ptr `type`](0)).list_head_member))))))

## *
##  @brief Inserts a linked list head between two linked list heads
##
##  @details It inserts a linked list head between prev_head and next_head.
##  @param new_item the linked list head that will be inserted to the linked list
##  @param prev_head the linked list head that comes before the element that is going to be inserted
##  @param next_head the linked list head that comes after the element that is going to be inserted
##

proc linkedlist_insert*(new_item: ptr ListHead; prev_head: ptr ListHead;
                       next_head: ptr ListHead) {.inline, cdecl.} =
  new_item.prev = prev_head
  new_item.next = next_head
  next_head.prev = new_item
  prev_head.next = new_item

## *
##  @brief Removes a linked list item from a linked list
##
##  @details It removes a linked list head from the list pointed by list.
##  @param list a pointer to the linked list pointer that we want to remove the item from, it will be set to NULL if no items are left
##  @param remove_item the item that is going to be removed
##

proc linkedlist_remove*(list: ptr ptr ListHead; remove_item: ptr ListHead) {.inline,
    cdecl.} =
  if remove_item.next == remove_item:
    list[] = nil
    return
  remove_item.prev.next = remove_item.next
  remove_item.next.prev = remove_item.prev
  if list[] == remove_item:
    list[] = remove_item.next

## *
##  @brief Appends a list item to a linked list
##
##  @details It appends a list item head to a linked list and it initializes linked list pointer if empty.
##  @param list a pointer to the linked list pointer that the head is going to be append, it will be set to new_item if it is the first one
##  @param new_item the item that is going to be appended to the end of the list
##

proc linkedlist_append*(list: ptr ptr ListHead; new_item: ptr ListHead) {.inline, cdecl.} =
  if list[] == nil:
    linkedlist_insert(new_item, new_item, new_item)
    list[] = new_item
  else:
    linkedlist_insert(new_item, (list[]).prev, list[])

## *
##  @brief Prepends a list item to a linked list
##
##  @details It prepends a list item head to a linked list and it updates the pointer to the list.
##  @param list a pointer to the linked list
##  @param new_item the list head that is going to be prepended to the list
##

proc linkedlist_prepend*(list: ptr ptr ListHead; new_item: ptr ListHead) {.inline, cdecl.} =
  if list[] == nil:
    linkedlist_insert(new_item, new_item, new_item)
  else:
    linkedlist_insert(new_item, (list[]).prev, list[])
  list[] = new_item

## *
##  @brief Returns the length of a linked list
##
##  @details Returns the length of a linked list
##  @param list a pointer to the linked list
##

proc linkedlist_length*(list: ptr ListHead): csize {.inline, cdecl.} =
  if list == nil:
    return 0
  else:
    var len: csize = 0
    var curr: ptr ListHead = list
    while true:
      inc(len)
      curr = curr.next
      if not (curr != nil and curr != list):
        break
    return len
