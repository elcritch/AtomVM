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

var proto_atom*: string = "\x05proto"

var udp_atom*: string = "\x03udp"

var tcp_atom*: string = "\x03tcp"

var socket_atom*: string = "\x06socket"

var fcntl_atom*: string = "\x05fcntl"

var bind_atom*: string = "\x04bind"

var getsockname_atom*: string = "\vgetsockname"

var recvfrom_atom*: string = "\brecvfrom"

var recv_atom*: string = "\x04recv"

var sendto_atom*: string = "\x06sendto"

var send_atom*: string = "\x04send"

var sta_got_ip_atom*: string = "\nsta_got_ip"

var sta_connected_atom*: string = "\csta_connected"

var address_atom*: string = "\aaddress"

var port_atom*: string = "\x04port"

var controlling_process_atom*: string = "\x13controlling_process"

var binary_atom*: string = "\x06binary"

var active_atom*: string = "\x06active"

var buffer_atom*: string = "\x06buffer"

var getaddrinfo_atom*: string = "\vgetaddrinfo"

var no_such_host_atom*: string = "\fno_such_host"

var connect_atom*: string = "\aconnect"

var tcp_closed_atom*: string = "\ntcp_closed"

var listen_atom*: string = "\x06listen"

var backlog_atom*: string = "\abacklog"

var accept_atom*: string = "\x06accept"

var fd_atom*: string = "\x02fd"

var generic_unix_atom*: string = "\fgeneric_unix"

proc platform_defaultatoms_init*(glb: ptr GlobalContext) {.cdecl.} =
  var ok: cint = 1
  ok = ok and globalcontext_insert_atom(glb, proto_atom) == PROTO_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, udp_atom) == UDP_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, tcp_atom) == TCP_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, socket_atom) == SOCKET_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, fcntl_atom) == FCNTL_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, bind_atom) == BIND_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, getsockname_atom) == GETSOCKNAME_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, recvfrom_atom) == RECVFROM_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, recv_atom) == RECV_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, sendto_atom) == SENDTO_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, send_atom) == SEND_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, sta_got_ip_atom) == STA_GOT_IP_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, sta_connected_atom) ==
      STA_CONNECTED_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, address_atom) == ADDRESS_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, port_atom) == PORT_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, controlling_process_atom) ==
      CONTROLLING_PROCESS_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, binary_atom) == BINARY_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, active_atom) == ACTIVE_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, buffer_atom) == BUFFER_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, getaddrinfo_atom) == GETADDRINFO_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, no_such_host_atom) ==
      NO_SUCH_HOST_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, connect_atom) == CONNECT_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, tcp_closed_atom) == TCP_CLOSED_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, listen_atom) == LISTEN_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, backlog_atom) == BACKLOG_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, accept_atom) == ACCEPT_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, fd_atom) == FD_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, generic_unix_atom) ==
      GENERIC_UNIX_ATOM_INDEX
  if not ok:
    abort()
