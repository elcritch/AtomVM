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
  globalcontext

const
  FALSE_ATOM_INDEX* = 0
  TRUE_ATOM_INDEX* = 1
  OK_ATOM_INDEX* = 2
  ERROR_ATOM_INDEX* = 3
  UNDEFINED_ATOM_INDEX* = 4
  BADARG_ATOM_INDEX* = 5
  BADARITH_ATOM_INDEX* = 6
  BADARITY_ATOM_INDEX* = 7
  BADFUN_ATOM_INDEX* = 8
  FUNCTION_CLAUSE_ATOM_INDEX* = 9
  TRY_CLAUSE_ATOM_INDEX* = 10
  OUT_OF_MEMORY_ATOM_INDEX* = 11
  OVERFLOW_ATOM_INDEX* = 12
  SYSTEM_LIMIT_ATOM_INDEX* = 13
  FLUSH_ATOM_INDEX* = 14
  HEAP_SIZE_ATOM_INDEX* = 15
  LATIN1_ATOM_INDEX* = 16
  MAX_HEAP_SIZE_ATOM_INDEX* = 17
  MEMORY_ATOM_INDEX* = 18
  MESSAGE_QUEUE_LEN_ATOM_INDEX* = 19
  PUTS_ATOM_INDEX* = 20
  STACK_SIZE_ATOM_INDEX* = 21
  MIN_HEAP_SIZE_ATOM_INDEX* = 22
  PROCESS_COUNT_ATOM_INDEX* = 23
  PORT_COUNT_ATOM_INDEX* = 24
  ATOM_COUNT_ATOM_INDEX* = 25
  SYSTEM_ARCHITECTURE_ATOM_INDEX* = 26
  WORDSIZE_ATOM_INDEX* = 27
  DECIMALS_ATOM_INDEX* = 28
  SCIENTIFIC_ATOM_INDEX* = 29
  COMPACT_ATOM_INDEX* = 30
  BADMATCH_ATOM_INDEX* = 31
  CASE_CLAUSE_ATOM_INDEX* = 32
  IF_CLAUSE_ATOM_INDEX* = 33
  THROW_ATOM_INDEX* = 34
  LOW_ENTROPY_ATOM_INDEX* = 35
  UNSUPPORTED_ATOM_INDEX* = 36
  USED_ATOM_INDEX* = 37
  ALL_ATOM_INDEX* = 38
  START_ATOM_INDEX* = 39
  PLATFORM_ATOMS_BASE_INDEX* = 40
  FALSE_ATOM* = TERM_FROM_ATOM_INDEX(FALSE_ATOM_INDEX)
  TRUE_ATOM* = TERM_FROM_ATOM_INDEX(TRUE_ATOM_INDEX)
  OK_ATOM* = term_from_atom_index(OK_ATOM_INDEX)
  ERROR_ATOM* = term_from_atom_index(ERROR_ATOM_INDEX)
  UNDEFINED_ATOM* = term_from_atom_index(UNDEFINED_ATOM_INDEX)
  BADARG_ATOM* = term_from_atom_index(BADARG_ATOM_INDEX)
  BADARITH_ATOM* = term_from_atom_index(BADARITH_ATOM_INDEX)
  BADARITY_ATOM* = term_from_atom_index(BADARITY_ATOM_INDEX)
  BADFUN_ATOM* = term_from_atom_index(BADFUN_ATOM_INDEX)
  FUNCTION_CLAUSE_ATOM* = term_from_atom_index(FUNCTION_CLAUSE_ATOM_INDEX)
  TRY_CLAUSE_ATOM* = term_from_atom_index(TRY_CLAUSE_ATOM_INDEX)
  OUT_OF_MEMORY_ATOM* = term_from_atom_index(OUT_OF_MEMORY_ATOM_INDEX)
  OVERFLOW_ATOM* = term_from_atom_index(OVERFLOW_ATOM_INDEX)
  SYSTEM_LIMIT_ATOM* = term_from_atom_index(SYSTEM_LIMIT_ATOM_INDEX)
  LATIN1_ATOM* = term_from_atom_index(LATIN1_ATOM_INDEX)
  FLUSH_ATOM* = term_from_atom_index(FLUSH_ATOM_INDEX)
  HEAP_SIZE_ATOM* = term_from_atom_index(HEAP_SIZE_ATOM_INDEX)
  MAX_HEAP_SIZE_ATOM* = term_from_atom_index(MAX_HEAP_SIZE_ATOM_INDEX)
  MEMORY_ATOM* = term_from_atom_index(MEMORY_ATOM_INDEX)
  MESSAGE_QUEUE_LEN_ATOM* = term_from_atom_index(MESSAGE_QUEUE_LEN_ATOM_INDEX)
  PUTS_ATOM* = term_from_atom_index(PUTS_ATOM_INDEX)
  STACK_SIZE_ATOM* = term_from_atom_index(STACK_SIZE_ATOM_INDEX)
  MIN_HEAP_SIZE_ATOM* = term_from_atom_index(MIN_HEAP_SIZE_ATOM_INDEX)
  PROCESS_COUNT_ATOM* = term_from_atom_index(PROCESS_COUNT_ATOM_INDEX)
  PORT_COUNT_ATOM* = term_from_atom_index(PORT_COUNT_ATOM_INDEX)
  ATOM_COUNT_ATOM* = term_from_atom_index(ATOM_COUNT_ATOM_INDEX)
  SYSTEM_ARCHITECTURE_ATOM* = term_from_atom_index(SYSTEM_ARCHITECTURE_ATOM_INDEX)
  WORDSIZE_ATOM* = term_from_atom_index(WORDSIZE_ATOM_INDEX)
  DECIMALS_ATOM* = TERM_FROM_ATOM_INDEX(DECIMALS_ATOM_INDEX)
  SCIENTIFIC_ATOM* = TERM_FROM_ATOM_INDEX(SCIENTIFIC_ATOM_INDEX)
  DEFAULTATOMS_COMPACT_ATOM* = TERM_FROM_ATOM_INDEX(COMPACT_ATOM_INDEX)
  BADMATCH_ATOM* = TERM_FROM_ATOM_INDEX(BADMATCH_ATOM_INDEX)
  CASE_CLAUSE_ATOM* = TERM_FROM_ATOM_INDEX(CASE_CLAUSE_ATOM_INDEX)
  IF_CLAUSE_ATOM* = TERM_FROM_ATOM_INDEX(IF_CLAUSE_ATOM_INDEX)
  THROW_ATOM* = TERM_FROM_ATOM_INDEX(THROW_ATOM_INDEX)
  LOW_ENTROPY_ATOM* = TERM_FROM_ATOM_INDEX(LOW_ENTROPY_ATOM_INDEX)
  UNSUPPORTED_ATOM* = TERM_FROM_ATOM_INDEX(UNSUPPORTED_ATOM_INDEX)
  USED_ATOM* = TERM_FROM_ATOM_INDEX(USED_ATOM_INDEX)
  ALL_ATOM* = TERM_FROM_ATOM_INDEX(ALL_ATOM_INDEX)
  START_ATOM* = TERM_FROM_ATOM_INDEX(START_ATOM_INDEX)

proc defaultatoms_init*(glb: ptr GlobalContext) {.cdecl.}
proc platform_defaultatoms_init*(glb: ptr GlobalContext) {.cdecl.}