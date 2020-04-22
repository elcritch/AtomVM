## **************************************************************************
##    Copyright 2018 by Fred Dushin <fred@dushin.net>                       *
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
  globalcontext, context, term, defaultatoms

proc port_create_tuple2*(ctx: ptr Context; a: term; b: term): term {.cdecl.}
proc port_create_tuple3*(ctx: ptr Context; a: term; b: term; c: term): term {.cdecl.}
proc port_create_tuple_n*(ctx: ptr Context; num_terms: csize; terms: ptr term): term {.
    cdecl.}
proc port_create_error_tuple*(ctx: ptr Context; reason: term): term {.cdecl.}
proc port_create_sys_error_tuple*(ctx: ptr Context; syscall: term; errno: cint): term {.
    cdecl.}
proc port_create_ok_tuple*(ctx: ptr Context; t: term): term {.cdecl.}
proc port_send_reply*(ctx: ptr Context; pid: term; `ref`: term; reply: term) {.cdecl.}
proc port_send_message*(ctx: ptr Context; pid: term; msg: term) {.cdecl.}
proc port_ensure_available*(ctx: ptr Context; size: csize) {.cdecl.}
proc port_is_standard_port_command*(msg: term): cint {.cdecl.}