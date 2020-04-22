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
  context, term

proc socket_driver_create_data*(): pointer {.cdecl.}
proc socket_driver_delete_data*(data: pointer) {.cdecl.}
proc socket_driver_do_init*(ctx: ptr Context; params: term): term {.cdecl.}
proc socket_driver_do_send*(ctx: ptr Context; buffer: term): term {.cdecl.}
proc socket_driver_do_sendto*(ctx: ptr Context; dest_address: term; dest_port: term;
                             buffer: term): term {.cdecl.}
proc socket_driver_do_recv*(ctx: ptr Context; pid: term; `ref`: term; length: term;
                           timeout: term) {.cdecl.}
proc socket_driver_do_recvfrom*(ctx: ptr Context; pid: term; `ref`: term; length: term;
                               timeout: term) {.cdecl.}
proc socket_driver_do_close*(ctx: ptr Context) {.cdecl.}
proc socket_driver_get_port*(ctx: ptr Context): term {.cdecl.}
proc socket_driver_do_accept*(ctx: ptr Context; pid: term; `ref`: term; timeout: term) {.
    cdecl.}
proc socket_driver_sockname*(ctx: ptr Context): term {.cdecl.}
proc socket_driver_peername*(ctx: ptr Context): term {.cdecl.}