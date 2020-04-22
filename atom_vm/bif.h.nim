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
##  @file bif.h
##  @brief BIF private functions.
##

import
  atom, context, exportedfunction, module

const
  MAX_BIF_NAME_LEN* = 260

proc bif_registry_get_handler*(module: AtomString; function: AtomString; arity: cint): BifImpl {.
    cdecl.}
proc bif_erlang_self_0*(ctx: ptr Context): term {.cdecl.}
proc bif_erlang_byte_size_1*(ctx: ptr Context; live: cint; arg1: term): term {.cdecl.}
proc bif_erlang_bit_size_1*(ctx: ptr Context; live: cint; arg1: term): term {.cdecl.}
proc bif_erlang_length_1*(ctx: ptr Context; live: cint; arg1: term): term {.cdecl.}
proc bif_erlang_is_atom_1*(ctx: ptr Context; arg1: term): term {.cdecl.}
proc bif_erlang_is_binary_1*(ctx: ptr Context; arg1: term): term {.cdecl.}
proc bif_erlang_is_integer_1*(ctx: ptr Context; arg1: term): term {.cdecl.}
proc bif_erlang_is_list_1*(ctx: ptr Context; arg1: term): term {.cdecl.}
proc bif_erlang_is_number_1*(ctx: ptr Context; arg1: term): term {.cdecl.}
proc bif_erlang_is_pid_1*(ctx: ptr Context; arg1: term): term {.cdecl.}
proc bif_erlang_is_reference_1*(ctx: ptr Context; arg1: term): term {.cdecl.}
proc bif_erlang_is_tuple_1*(ctx: ptr Context; arg1: term): term {.cdecl.}
proc bif_erlang_hd_1*(ctx: ptr Context; arg1: term): term {.cdecl.}
proc bif_erlang_tl_1*(ctx: ptr Context; arg1: term): term {.cdecl.}
proc bif_erlang_element_2*(ctx: ptr Context; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_tuple_size_1*(ctx: ptr Context; arg1: term): term {.cdecl.}
proc bif_erlang_add_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_sub_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_mul_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_div_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_rem_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_neg_1*(ctx: ptr Context; live: cint; arg1: term): term {.cdecl.}
proc bif_erlang_abs_1*(ctx: ptr Context; live: cint; arg1: term): term {.cdecl.}
proc bif_erlang_ceil_1*(ctx: ptr Context; live: cint; arg1: term): term {.cdecl.}
proc bif_erlang_floor_1*(ctx: ptr Context; live: cint; arg1: term): term {.cdecl.}
proc bif_erlang_round_1*(ctx: ptr Context; live: cint; arg1: term): term {.cdecl.}
proc bif_erlang_trunc_1*(ctx: ptr Context; live: cint; arg1: term): term {.cdecl.}
proc bif_erlang_bor_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_band_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_bxor_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_bsl_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_bsr_2*(ctx: ptr Context; live: cint; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_bnot_1*(ctx: ptr Context; live: cint; arg1: term): term {.cdecl.}
proc bif_erlang_not_1*(ctx: ptr Context; arg1: term): term {.cdecl.}
proc bif_erlang_and_2*(ctx: ptr Context; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_or_2*(ctx: ptr Context; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_xor_2*(ctx: ptr Context; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_equal_to_2*(ctx: ptr Context; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_not_equal_to_2*(ctx: ptr Context; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_exactly_equal_to_2*(ctx: ptr Context; arg1: term; arg2: term): term {.
    cdecl.}
proc bif_erlang_exactly_not_equal_to_2*(ctx: ptr Context; arg1: term; arg2: term): term {.
    cdecl.}
proc bif_erlang_greater_than_2*(ctx: ptr Context; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_less_than_2*(ctx: ptr Context; arg1: term; arg2: term): term {.cdecl.}
proc bif_erlang_less_than_or_equal_2*(ctx: ptr Context; arg1: term; arg2: term): term {.
    cdecl.}
proc bif_erlang_greater_than_or_equal_2*(ctx: ptr Context; arg1: term; arg2: term): term {.
    cdecl.}