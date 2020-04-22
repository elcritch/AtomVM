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
##  @file exportedfunction.h
##  @brief Module exported functions structs and macros.
##
##  @details Structs required to handle both exported/imported NIFs and functions.
##

import
  term

type
  BifImpl* = proc (): term {.cdecl.}
  BifImpl0* = proc (ctx: ptr Context): term {.cdecl.}
  BifImpl1* = proc (ctx: ptr Context; arg1: term): term {.cdecl.}
  BifImpl2* = proc (ctx: ptr Context; arg1: term; arg2: term): term {.cdecl.}
  GCBifImpl1* = proc (ctx: ptr Context; live: cint; arg1: term): term {.cdecl.}
  GCBifImpl2* = proc (ctx: ptr Context; live: cint; arg1: term; arg2: term): term {.cdecl.}
  GCBifImpl3* = proc (ctx: ptr Context; live: cint; arg1: term; arg2: term; arg3: term): term {.
      cdecl.}
  NifImpl* = proc (ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.}
  FunctionType* = enum
    InvalidFunctionType = 0, NIFFunctionType = 2, UnresolvedFunctionCall = 3,
    ModuleFunction = 4


type
  ExportedFunction* = object
    `type`*: FunctionType

  Nif* = object
    base*: ExportedFunction
    nif_ptr*: NifImpl

  UnresolvedFunctionCall* = object
    base*: ExportedFunction
    module_atom_index*: cint
    function_atom_index*: cint
    arity*: cint

  ModuleFunction* = object
    base*: ExportedFunction
    target*: ptr Module
    label*: cint


template EXPORTED_FUNCTION_TO_NIF*(`func`: untyped): untyped =
  (cast[ptr Nif](((cast[cstring]((`func`))) -
      (cast[culong](addr((cast[ptr Nif](0)).base))))))

template EXPORTED_FUNCTION_TO_UNRESOLVED_FUNCTION_CALL*(`func`: untyped): untyped =
  (cast[ptr UnresolvedFunctionCall](((cast[cstring]((`func`))) -
      (cast[culong](addr((cast[ptr UnresolvedFunctionCall](0)).base))))))

template EXPORTED_FUNCTION_TO_MODULE_FUNCTION*(`func`: untyped): untyped =
  (cast[ptr ModuleFunction](((cast[cstring]((`func`))) -
      (cast[culong](addr((cast[ptr ModuleFunction](0)).base))))))

type
  imported_func* = object {.union.}
    `func`*: ptr ExportedFunction
    bif*: BifImpl

