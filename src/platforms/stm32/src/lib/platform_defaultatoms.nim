## **************************************************************************
##    Copyright 2019 by Davide Bettio <davide@uninstall.it>                 *
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
  platform_defaultatoms

var set_level_atom*: string = "\tset_level"

var input_atom*: string = "\x05input"

var output_atom*: string = "\x06output"

var set_direction_atom*: string = "\cset_direction"

var set_int_atom*: string = "\aset_int"

var gpio_interrupt_atom*: string = "\x0Egpio_interrupt"

var a_atom*: string = "\x01a"

var b_atom*: string = "\x01b"

var c_atom*: string = "\x01c"

var d_atom*: string = "\x01d"

var e_atom*: string = "\x01e"

var f_atom*: string = "\x01f"

var stm32_atom*: string = "\x05stm32"

proc platform_defaultatoms_init*(glb: ptr GlobalContext) {.cdecl.} =
  var ok: cint = 1
  ok = ok and
      globalcontext_insert_atom(glb, set_level_atom) == SET_LEVEL_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, input_atom) == INPUT_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, output_atom) == OUTPUT_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, set_direction_atom) ==
      SET_DIRECTION_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, set_int_atom) == SET_INT_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, gpio_interrupt_atom) ==
      GPIO_INTERRUPT_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, a_atom) == A_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, b_atom) == B_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, c_atom) == C_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, d_atom) == D_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, e_atom) == E_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, f_atom) == F_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, stm32_atom) == STM32_ATOM_INDEX
  if not ok:
    abort()
