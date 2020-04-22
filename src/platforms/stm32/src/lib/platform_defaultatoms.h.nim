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
  defaultatoms

const
  SET_LEVEL_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 0)
  INPUT_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 1)
  OUTPUT_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 2)
  SET_DIRECTION_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 3)
  SET_INT_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 4)
  GPIO_INTERRUPT_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 5)
  A_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 6)
  B_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 7)
  C_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 8)
  D_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 9)
  E_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 10)
  F_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 11)
  STM32_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 12)
  SET_LEVEL_ATOM* = term_from_atom_index(SET_LEVEL_ATOM_INDEX)
  INPUT_ATOM* = term_from_atom_index(INPUT_ATOM_INDEX)
  OUTPUT_ATOM* = term_from_atom_index(OUTPUT_ATOM_INDEX)
  SET_DIRECTION_ATOM* = term_from_atom_index(SET_DIRECTION_ATOM_INDEX)
  SET_INT_ATOM* = term_from_atom_index(SET_INT_ATOM_INDEX)
  GPIO_INTERRUPT_ATOM* = term_from_atom_index(GPIO_INTERRUPT_ATOM_INDEX)
  A_ATOM* = term_from_atom_index(A_ATOM_INDEX)
  B_ATOM* = term_from_atom_index(B_ATOM_INDEX)
  C_ATOM* = term_from_atom_index(C_ATOM_INDEX)
  D_ATOM* = term_from_atom_index(D_ATOM_INDEX)
  E_ATOM* = term_from_atom_index(E_ATOM_INDEX)
  F_ATOM* = term_from_atom_index(F_ATOM_INDEX)
  STM32_ATOM* = term_from_atom_index(STM32_ATOM_INDEX)
