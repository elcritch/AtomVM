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
  PROTO_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 0)
  UDP_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 1)
  TCP_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 2)
  SOCKET_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 3)
  FCNTL_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 4)
  BIND_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 5)
  GETSOCKNAME_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 6)
  RECVFROM_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 7)
  RECV_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 8)
  SENDTO_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 9)
  SEND_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 10)
  STA_GOT_IP_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 11)
  STA_CONNECTED_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 12)
  ADDRESS_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 13)
  PORT_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 14)
  CONTROLLING_PROCESS_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 15)
  BINARY_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 16)
  ACTIVE_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 17)
  BUFFER_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 18)
  GETADDRINFO_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 19)
  NO_SUCH_HOST_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 20)
  CONNECT_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 21)
  TCP_CLOSED_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 22)
  LISTEN_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 23)
  BACKLOG_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 24)
  ACCEPT_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 25)
  FD_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 26)
  GENERIC_UNIX_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 27)
  PROTO_ATOM* = term_from_atom_index(PROTO_ATOM_INDEX)
  UDP_ATOM* = term_from_atom_index(UDP_ATOM_INDEX)
  TCP_ATOM* = term_from_atom_index(TCP_ATOM_INDEX)
  SOCKET_ATOM* = term_from_atom_index(SOCKET_ATOM_INDEX)
  FCNTL_ATOM* = term_from_atom_index(FCNTL_ATOM_INDEX)
  BIND_ATOM* = term_from_atom_index(BIND_ATOM_INDEX)
  GETSOCKNAME_ATOM* = term_from_atom_index(GETSOCKNAME_ATOM_INDEX)
  RECVFROM_ATOM* = term_from_atom_index(RECVFROM_ATOM_INDEX)
  RECV_ATOM* = term_from_atom_index(RECV_ATOM_INDEX)
  SENDTO_ATOM* = term_from_atom_index(SENDTO_ATOM_INDEX)
  SEND_ATOM* = term_from_atom_index(SEND_ATOM_INDEX)
  STA_GOT_IP_ATOM* = term_from_atom_index(STA_GOT_IP_ATOM_INDEX)
  STA_CONNECTED_ATOM* = term_from_atom_index(STA_CONNECTED_ATOM_INDEX)
  ADDRESS_ATOM* = term_from_atom_index(ADDRESS_ATOM_INDEX)
  PORT_ATOM* = term_from_atom_index(PORT_ATOM_INDEX)
  CONTROLLING_PROCESS_ATOM* = term_from_atom_index(CONTROLLING_PROCESS_ATOM_INDEX)
  BINARY_ATOM* = term_from_atom_index(BINARY_ATOM_INDEX)
  ACTIVE_ATOM* = term_from_atom_index(ACTIVE_ATOM_INDEX)
  BUFFER_ATOM* = term_from_atom_index(BUFFER_ATOM_INDEX)
  GETADDRINFO_ATOM* = term_from_atom_index(GETADDRINFO_ATOM_INDEX)
  NO_SUCH_HOST_ATOM* = term_from_atom_index(NO_SUCH_HOST_ATOM_INDEX)
  CONNECT_ATOM* = term_from_atom_index(CONNECT_ATOM_INDEX)
  TCP_CLOSED_ATOM* = term_from_atom_index(TCP_CLOSED_ATOM_INDEX)
  LISTEN_ATOM* = term_from_atom_index(LISTEN_ATOM_INDEX)
  BACKLOG_ATOM* = term_from_atom_index(BACKLOG_ATOM_INDEX)
  ACCEPT_ATOM* = term_from_atom_index(ACCEPT_ATOM_INDEX)
  FD_ATOM* = term_from_atom_index(FD_ATOM_INDEX)
  GENERIC_UNIX_ATOM* = TERM_FROM_ATOM_INDEX(GENERIC_UNIX_ATOM_INDEX)
