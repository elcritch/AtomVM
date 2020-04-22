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
  TempStack* = object
    stack_end*: ptr term
    stack_pos*: ptr term
    size*: cint


proc temp_stack_init*(temp_stack: ptr TempStack) {.inline, cdecl.} =
  temp_stack.size = 8
  temp_stack.stack_end = (cast[ptr term](malloc(temp_stack.size * sizeof((term))))) +
      temp_stack.size
  temp_stack.stack_pos = temp_stack.stack_end

proc temp_stack_destory*(temp_stack: ptr TempStack) {.inline, cdecl.} =
  free(temp_stack.stack_end - temp_stack.size)

proc temp_stack_grow*(temp_stack: ptr TempStack) {.cdecl.} =
  var old_used_size: cint = temp_stack.stack_end - temp_stack.stack_pos
  var new_size: cint = temp_stack.size * 2
  var new_stack_end: ptr term = (cast[ptr term](malloc(new_size * sizeof((term))))) +
      new_size
  var new_stack_pos: ptr term = new_stack_end - old_used_size
  memcpy(new_stack_pos, temp_stack.stack_pos, old_used_size * sizeof((term)))
  free(temp_stack.stack_end - temp_stack.size)
  temp_stack.stack_end = new_stack_end
  temp_stack.stack_pos = new_stack_pos
  temp_stack.size = new_size

proc temp_stack_is_empty*(temp_stack: ptr TempStack): cint {.inline, cdecl.} =
  return temp_stack.stack_end == temp_stack.stack_pos

proc temp_stack_push*(temp_stack: ptr TempStack; value: term) {.inline, cdecl.} =
  if temp_stack.stack_end - temp_stack.stack_pos == temp_stack.size - 1:
    temp_stack_grow(temp_stack)
  dec(temp_stack.stack_pos)
  temp_stack.stack_pos[] = value

proc temp_stack_pop*(temp_stack: ptr TempStack): term {.inline, cdecl.} =
  var value: term = temp_stack.stack_pos[]
  inc(temp_stack.stack_pos)
  return value
