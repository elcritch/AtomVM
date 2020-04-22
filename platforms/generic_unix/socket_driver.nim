## **************************************************************************
##    Copyright 2018 by Davide Bettio <davide@uninstall.it>                 *
##    Copyright 2019 by Fred Dushin <fred@dushin.net>                       *
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
  socket_driver, port, atom, context, generic_unix_sys, globalcontext, interop,
  mailbox, utils, term, sys, platform_defaultatoms

##  TODO: FIXME
##  #define ENABLE_TRACE

import
  trace

const
  BUFSIZE* = 128

type
  SocketDriverData* = object
    sockfd*: cint
    proto*: term
    port*: term
    controlling_process*: term
    binary*: term
    active*: term
    buffer*: term
    active_listener*: ptr EventListener


proc active_recv_callback*(listener: ptr EventListener) {.cdecl.}
proc passive_recv_callback*(listener: ptr EventListener) {.cdecl.}
proc active_recvfrom_callback*(listener: ptr EventListener) {.cdecl.}
proc passive_recvfrom_callback*(listener: ptr EventListener) {.cdecl.}
proc socket_tuple_to_addr*(addr_tuple: term): uint32_t {.cdecl.} =
  return ((term_to_int32(term_get_tuple_element(addr_tuple, 0)) and 0x000000FF) shl
      24) or
      ((term_to_int32(term_get_tuple_element(addr_tuple, 1)) and 0x000000FF) shl
      16) or
      ((term_to_int32(term_get_tuple_element(addr_tuple, 2)) and 0x000000FF) shl
      8) or
      (term_to_int32(term_get_tuple_element(addr_tuple, 3)) and 0x000000FF)

proc socket_tuple_from_addr*(ctx: ptr Context; `addr`: uint32_t): term {.cdecl.} =
  var terms: array[4, term]
  terms[0] = term_from_int32((`addr` shr 24) and 0x000000FF)
  terms[1] = term_from_int32((`addr` shr 16) and 0x000000FF)
  terms[2] = term_from_int32((`addr` shr 8) and 0x000000FF)
  terms[3] = term_from_int32(`addr` and 0x000000FF)
  return port_create_tuple_n(ctx, 4, terms)

proc socket_create_packet_term*(ctx: ptr Context; buf: cstring; len: ssize_t;
                               is_binary: cint): term {.cdecl.} =
  if is_binary:
    return term_from_literal_binary(cast[pointer](buf), len, ctx)
  else:
    return term_from_string(cast[ptr uint8_t](buf), len, ctx)

proc socket_driver_create_data*(): pointer {.cdecl.} =
  var data: ptr SocketDriverData = calloc(1, sizeof(SocketDriverData))
  data.sockfd = -1
  data.proto = term_invalid_term()
  data.port = term_invalid_term()
  data.controlling_process = term_invalid_term()
  data.binary = term_invalid_term()
  data.active = term_invalid_term()
  data.buffer = term_invalid_term()
  data.active_listener = nil
  return cast[pointer](data)

proc socket_driver_delete_data*(data: pointer) {.cdecl.} =
  free(data)

proc do_bind*(ctx: ptr Context; address: term; port: term): term {.cdecl.} =
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  var serveraddr: sockaddr_in
  UNUSED(address)
  memset(addr(serveraddr), 0, sizeof((serveraddr)))
  serveraddr.sin_family = AF_INET
  if address == UNDEFINED_ATOM:
    serveraddr.sin_addr.s_addr = htonl(INADDR_ANY)
  elif term_is_tuple(address):
    serveraddr.sin_addr.s_addr = htonl(socket_tuple_to_addr(address))
  else:
    term_display(stderr, address, ctx)
    return port_create_error_tuple(ctx, BADARG_ATOM)
  var p: avm_int_t = term_to_int(port)
  serveraddr.sin_port = htons(p)
  var address_len: socklen_t = sizeof((serveraddr))
  if `bind`(socket_data.sockfd, cast[ptr sockaddr](addr(serveraddr)), address_len) ==
      -1:
    return port_create_sys_error_tuple(ctx, BIND_ATOM, errno)
  else:
    TRACE("socket_driver: bound to %ld\n", p)
    if getsockname(socket_data.sockfd, cast[ptr sockaddr](addr(serveraddr)),
                  addr(address_len)) == -1:
      return port_create_sys_error_tuple(ctx, GETSOCKNAME_ATOM, errno)
    else:
      socket_data.port = ntohs(serveraddr.sin_port)
      return OK_ATOM

proc init_udp_socket*(ctx: ptr Context; socket_data: ptr SocketDriverData;
                     params: term; active: term): term {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr GenericUnixPlatformData = glb.platform_data
  var sockfd: cint = socket(AF_INET, SOCK_DGRAM, 0)
  if sockfd == -1:
    return port_create_sys_error_tuple(ctx, SOCKET_ATOM, errno)
  socket_data.sockfd = sockfd
  if fcntl(socket_data.sockfd, F_SETFL, O_NONBLOCK) == -1:
    close(sockfd)
    return port_create_sys_error_tuple(ctx, FCNTL_ATOM, errno)
  var address: term = interop_proplist_get_value_default(params, ADDRESS_ATOM,
      UNDEFINED_ATOM)
  var port: term = interop_proplist_get_value(params, PORT_ATOM)
  var ret: term = do_bind(ctx, address, port)
  if ret != OK_ATOM:
    close(sockfd)
  else:
    if fcntl(socket_data.sockfd, F_SETFL, O_NONBLOCK) == -1:
      return port_create_sys_error_tuple(ctx, FCNTL_ATOM, errno)
    if active == TRUE_ATOM:
      var listener: ptr EventListener = malloc(sizeof((EventListener)))
      if IS_NULL_PTR(listener):
        fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
        abort()
      listener.fd = socket_data.sockfd
      listener.data = ctx
      listener.handler = active_recvfrom_callback
      linkedlist_append(addr(platform.listeners),
                        addr(listener.listeners_list_head))
      socket_data.active_listener = listener
  return ret

proc do_connect*(socket_data: ptr SocketDriverData; ctx: ptr Context; address: term;
                port: term): term {.cdecl.} =
  ##  TODO handle IP addresses
  if not term_is_list(address):
    return port_create_error_tuple(ctx, BADARG_ATOM)
  var hints: addrinfo
  memset(addr(hints), 0, sizeof((hints)))
  hints.ai_family = AF_INET
  hints.ai_socktype = SOCK_STREAM
  hints.ai_protocol = IPPROTO_TCP
  var ok: cint
  var addr_str: cstring = interop_term_to_string(address, addr(ok))
  if not ok:
    return port_create_error_tuple(ctx, BADARG_ATOM)
  var port_str: array[32, char]
  snprintf(port_str, 32, "%u", cast[cushort](term_to_int(port)))
  TRACE("socket_driver: resolving to %s:%s over socket fd %i\n", addr_str,
        port_str, term_to_int32(socket_data.sockfd))
  var server_info: ptr addrinfo
  var status: cint = getaddrinfo(addr_str, port_str, addr(hints), addr(server_info))
  free(addr_str)
  if status != 0:
    return port_create_sys_error_tuple(ctx, GETADDRINFO_ATOM, status)
  var `addr`: ptr sockaddr = nil
  var addr_len: csize = 0
  var p: ptr addrinfo = server_info
  while p != nil:
    `addr` = p.ai_addr
    addr_len = p.ai_addrlen
    break
    p = p.ai_next
  if IS_NULL_PTR(`addr`):
    return port_create_error_tuple(ctx, NO_SUCH_HOST_ATOM)
  status = connect(socket_data.sockfd, `addr`, addr_len)
  freeaddrinfo(server_info)
  if status == -1:
    return port_create_sys_error_tuple(ctx, CONNECT_ATOM, errno)
  else:
    TRACE("socket_driver: connected.\n")
    return OK_ATOM

proc init_client_tcp_socket*(ctx: ptr Context; socket_data: ptr SocketDriverData;
                            params: term; active: term): term {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr GenericUnixPlatformData = glb.platform_data
  var sockfd: cint = socket(AF_INET, SOCK_STREAM, 0)
  if sockfd == -1:
    return port_create_sys_error_tuple(ctx, SOCKET_ATOM, errno)
  socket_data.sockfd = sockfd
  var address: term = interop_proplist_get_value(params, ADDRESS_ATOM)
  var port: term = interop_proplist_get_value(params, PORT_ATOM)
  var ret: term = do_connect(socket_data, ctx, address, port)
  if ret != OK_ATOM:
    close(sockfd)
  else:
    if active == TRUE_ATOM:
      var listener: ptr EventListener = malloc(sizeof((EventListener)))
      if IS_NULL_PTR(listener):
        fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
        abort()
      listener.fd = socket_data.sockfd
      listener.data = ctx
      listener.handler = active_recv_callback
      linkedlist_append(addr(platform.listeners),
                        addr(listener.listeners_list_head))
      socket_data.active_listener = listener
  return ret

proc do_listen*(socket_data: ptr SocketDriverData; ctx: ptr Context; params: term): term {.
    cdecl.} =
  var backlog: term = interop_proplist_get_value(params, BACKLOG_ATOM)
  if not term_is_integer(backlog):
    return port_create_error_tuple(ctx, BADARG_ATOM)
  var status: cint = listen(socket_data.sockfd, term_from_int(backlog))
  if status == -1:
    return port_create_sys_error_tuple(ctx, LISTEN_ATOM, errno)
  else:
    return OK_ATOM

proc init_server_tcp_socket*(ctx: ptr Context; socket_data: ptr SocketDriverData;
                            params: term): term {.cdecl.} =
  var sockfd: cint = socket(AF_INET, SOCK_STREAM, 0)
  if sockfd == -1:
    return port_create_sys_error_tuple(ctx, SOCKET_ATOM, errno)
  socket_data.sockfd = sockfd
  if fcntl(socket_data.sockfd, F_SETFL, O_NONBLOCK) == -1:
    close(sockfd)
    return port_create_sys_error_tuple(ctx, FCNTL_ATOM, errno)
  var address: term = interop_proplist_get_value_default(params, ADDRESS_ATOM,
      UNDEFINED_ATOM)
  var port: term = interop_proplist_get_value(params, PORT_ATOM)
  var ret: term = do_bind(ctx, address, port)
  if ret != OK_ATOM:
    close(sockfd)
  else:
    ret = do_listen(socket_data, ctx, params)
    if ret != OK_ATOM:
      close(sockfd)
    else:
      TRACE("socket_driver: listening on port %u\n",
            cast[cuint](term_to_int(port)))
  return ret

proc init_accepting_socket*(ctx: ptr Context; socket_data: ptr SocketDriverData;
                           fd: term; active: term): term {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr GenericUnixPlatformData = glb.platform_data
  socket_data.sockfd = term_to_int(fd)
  if active == TRUE_ATOM:
    var listener: ptr EventListener = malloc(sizeof((EventListener)))
    if IS_NULL_PTR(listener):
      fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
      abort()
    listener.fd = socket_data.sockfd
    listener.data = ctx
    listener.handler = active_recv_callback
    linkedlist_append(addr(platform.listeners),
                      addr(listener.listeners_list_head))
    socket_data.active_listener = listener
  return OK_ATOM

proc socket_driver_do_init*(ctx: ptr Context; params: term): term {.cdecl.} =
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  if not term_is_list(params):
    return port_create_error_tuple(ctx, BADARG_ATOM)
  var proto: term = interop_proplist_get_value(params, PROTO_ATOM)
  if term_is_nil(proto):
    return port_create_error_tuple(ctx, BADARG_ATOM)
  socket_data.proto = proto
  ##
  ##  get the controlling process
  ##
  var controlling_process: term = interop_proplist_get_value_default(params,
      CONTROLLING_PROCESS_ATOM, term_invalid_term())
  if not (term_is_invalid_term(controlling_process) or
      term_is_pid(controlling_process)):
    return port_create_error_tuple(ctx, BADARG_ATOM)
  socket_data.controlling_process = controlling_process
  ##
  ##  get the binary flag
  ##
  var binary: term = interop_proplist_get_value_default(params, BINARY_ATOM,
      FALSE_ATOM)
  if not (binary == TRUE_ATOM or binary == FALSE_ATOM):
    return port_create_error_tuple(ctx, BADARG_ATOM)
  socket_data.binary = binary
  ##
  ##  get the buffer size
  ##
  var buffer: term = interop_proplist_get_value_default(params, BUFFER_ATOM,
      term_from_int(BUFSIZE))
  if not term_is_integer(buffer):
    return port_create_error_tuple(ctx, BADARG_ATOM)
  socket_data.buffer = buffer
  ##
  ##  get the active flag
  ##
  var active: term = interop_proplist_get_value_default(params, ACTIVE_ATOM,
      FALSE_ATOM)
  socket_data.active = active
  ##
  ##  initialize based on specified protocol and action
  ##
  if proto == UDP_ATOM:
    var ret: term = init_udp_socket(ctx, socket_data, params, active)
    return ret
  elif proto == TCP_ATOM:
    var connect: term = interop_proplist_get_value_default(params, CONNECT_ATOM,
        FALSE_ATOM)
    if connect == TRUE_ATOM:
      return init_client_tcp_socket(ctx, socket_data, params, active)
    else:
      var listen: term = interop_proplist_get_value_default(params, LISTEN_ATOM,
          FALSE_ATOM)
      if listen == TRUE_ATOM:
        return init_server_tcp_socket(ctx, socket_data, params)
      else:
        var accept: term = interop_proplist_get_value_default(params, ACCEPT_ATOM,
            FALSE_ATOM)
        if accept == TRUE_ATOM:
          var fd: term = interop_proplist_get_value(params, FD_ATOM)
          if not term_is_integer(fd):
            return port_create_error_tuple(ctx, BADARG_ATOM)
          else:
            return init_accepting_socket(ctx, socket_data, fd, active)
        else:
          return port_create_error_tuple(ctx, BADARG_ATOM)
  else:
    return port_create_error_tuple(ctx, BADARG_ATOM)

proc socket_driver_do_close*(ctx: ptr Context) {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr GenericUnixPlatformData = glb.platform_data
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  if socket_data.active == TRUE_ATOM:
    linkedlist_remove(addr(platform.listeners),
                      addr(socket_data.active_listener.listeners_list_head))
  if close(socket_data.sockfd) == -1:
    TRACE("socket: close failed")
  else:
    TRACE("socket_driver: closed socket\n")

##
##  INET API
##

proc socket_driver_get_port*(ctx: ptr Context): term {.cdecl.} =
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  port_ensure_available(ctx, 7)
  return port_create_ok_tuple(ctx, term_from_int(socket_data.port))

proc socket_driver_sockname*(ctx: ptr Context): term {.cdecl.} =
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  var `addr`: sockaddr_in
  var addrlen: socklen_t = sizeof((`addr`))
  var result: cint = getsockname(socket_data.sockfd,
                             cast[ptr sockaddr](addr(`addr`)), addr(addrlen))
  if result != 0:
    port_ensure_available(ctx, 3)
    return port_create_error_tuple(ctx, term_from_int(errno))
  else:
    port_ensure_available(ctx, 8)
    var addr_term: term = socket_tuple_from_addr(ctx, ntohl(`addr`.sin_addr.s_addr))
    var port_term: term = term_from_int(ntohs(`addr`.sin_port))
    return port_create_tuple2(ctx, addr_term, port_term)

proc socket_driver_peername*(ctx: ptr Context): term {.cdecl.} =
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  var `addr`: sockaddr_in
  var addrlen: socklen_t = sizeof((`addr`))
  var result: cint = getpeername(socket_data.sockfd,
                             cast[ptr sockaddr](addr(`addr`)), addr(addrlen))
  if result != 0:
    port_ensure_available(ctx, 3)
    return port_create_error_tuple(ctx, term_from_int(errno))
  else:
    port_ensure_available(ctx, 8)
    var addr_term: term = socket_tuple_from_addr(ctx, ntohl(`addr`.sin_addr.s_addr))
    var port_term: term = term_from_int(ntohs(`addr`.sin_port))
    return port_create_tuple2(ctx, addr_term, port_term)

##
##  send operations
##

proc socket_driver_do_send*(ctx: ptr Context; buffer: term): term {.cdecl.} =
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  var buf: cstring
  var len: csize
  if term_is_binary(buffer):
    buf = cast[cstring](term_binary_data(buffer))
    len = term_binary_size(buffer)
  elif term_is_list(buffer):
    var ok: cint
    len = interop_iolist_size(buffer, addr(ok))
    if UNLIKELY(not ok):
      return port_create_error_tuple(ctx, BADARG_ATOM)
    buf = malloc(len)
    if UNLIKELY(not interop_write_iolist(buffer, buf)):
      free(buf)
      return port_create_error_tuple(ctx, BADARG_ATOM)
  else:
    return port_create_error_tuple(ctx, BADARG_ATOM)
  var sent_data: cint = send(socket_data.sockfd, buf, len, 0)
  if term_is_list(buffer):
    free(buf)
  if sent_data == -1:
    return port_create_sys_error_tuple(ctx, SEND_ATOM, errno)
  else:
    TRACE("socket_driver: sent data with len: %li\n", len)
    var sent_atom: term = term_from_int(sent_data)
    return port_create_ok_tuple(ctx, sent_atom)

proc socket_driver_do_sendto*(ctx: ptr Context; dest_address: term; dest_port: term;
                             buffer: term): term {.cdecl.} =
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  var `addr`: sockaddr_in
  memset(addr(`addr`), 0, sizeof(sockaddr_in))
  `addr`.sin_family = AF_INET
  `addr`.sin_addr.s_addr = htonl(socket_tuple_to_addr(dest_address))
  `addr`.sin_port = htons(term_to_int32(dest_port))
  var buf: cstring
  var len: csize
  if term_is_binary(buffer):
    buf = cast[cstring](term_binary_data(buffer))
    len = term_binary_size(buffer)
  elif term_is_list(buffer):
    var ok: cint
    len = interop_iolist_size(buffer, addr(ok))
    if UNLIKELY(not ok):
      return port_create_error_tuple(ctx, BADARG_ATOM)
    buf = malloc(len)
    if UNLIKELY(not interop_write_iolist(buffer, buf)):
      free(buf)
      return port_create_error_tuple(ctx, BADARG_ATOM)
  else:
    return port_create_error_tuple(ctx, BADARG_ATOM)
  var sent_data: cint = sendto(socket_data.sockfd, buf, len, 0,
                           cast[ptr sockaddr](addr(`addr`)), sizeof((`addr`)))
  if term_is_list(buffer):
    free(buf)
  if sent_data == -1:
    return port_create_sys_error_tuple(ctx, SENDTO_ATOM, errno)
  else:
    TRACE("socket_driver: sent data with len: %li, to: %i, port: %i\n", len,
          ntohl(`addr`.sin_addr.s_addr), ntohs(`addr`.sin_port))
    var sent_atom: term = term_from_int32(sent_data)
    return port_create_ok_tuple(ctx, sent_atom)

##
##  receive operations
##

type
  RecvFromData* = object
    ctx*: ptr Context
    pid*: term
    length*: term
    ref_ticks*: uint64_t


proc active_recv_callback*(listener: ptr EventListener) {.cdecl.} =
  var ctx: ptr Context = cast[ptr Context](listener.data)
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  ##
  ##  allocate the receive buffer
  ##
  var buf_size: avm_int_t = term_to_int(socket_data.buffer)
  var buf: cstring = malloc(buf_size)
  if IS_NULL_PTR(buf):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    abort()
  var len: ssize_t = recvfrom(socket_data.sockfd, buf, buf_size, 0, nil, nil)
  if len <= 0:
    ##  {tcp, Socket, {error, {SysCall, Errno}}}
    port_ensure_available(ctx, 12)
    var pid: term = socket_data.controlling_process
    var msgs: array[2, term] = [TCP_CLOSED_ATOM,
                           term_from_local_process_id(ctx.process_id)]
    var msg: term = port_create_tuple_n(ctx, 2, msgs)
    port_send_message(ctx, pid, msg)
    socket_driver_do_close(ctx)
  else:
    TRACE("socket_driver: received data of len: %li\n", len)
    var ensure_packet_avail: cint
    var binary: cint
    if socket_data.binary == TRUE_ATOM:
      binary = 1
      ensure_packet_avail = term_binary_data_size_in_terms(len) +
          BINARY_HEADER_SIZE
    else:
      binary = 0
      ensure_packet_avail = len * 2
    ##  {tcp, pid, binary}
    port_ensure_available(ctx, 20 + ensure_packet_avail)
    var pid: term = socket_data.controlling_process
    var packet: term = socket_create_packet_term(ctx, buf, len, binary)
    var msgs: array[3, term] = [TCP_ATOM, term_from_local_process_id(ctx.process_id),
                           packet]
    var msg: term = port_create_tuple_n(ctx, 3, msgs)
    port_send_message(ctx, pid, msg)
  free(buf)

proc passive_recv_callback*(listener: ptr EventListener) {.cdecl.} =
  var recvfrom_data: ptr RecvFromData = cast[ptr RecvFromData](listener.data)
  var ctx: ptr Context = recvfrom_data.ctx
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr GenericUnixPlatformData = glb.platform_data
  ##
  ##  allocate the receive buffer
  ##
  var buf_size: avm_int_t = term_to_int(recvfrom_data.length)
  var buf: cstring = malloc(buf_size)
  if IS_NULL_PTR(buf):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    abort()
  var len: ssize_t = recvfrom(socket_data.sockfd, buf, buf_size, 0, nil, nil)
  if len <= 0:
    ##  {Ref, {error, {SysCall, Errno}}}
    port_ensure_available(ctx, 12)
    var pid: term = recvfrom_data.pid
    var `ref`: term = term_from_ref_ticks(recvfrom_data.ref_ticks, ctx)
    port_send_reply(ctx, pid, `ref`,
                    port_create_sys_error_tuple(ctx, RECV_ATOM, errno))
  else:
    TRACE("socket_driver: passive received data of len: %li\n", len)
    var ensure_packet_avail: cint
    if socket_data.binary == TRUE_ATOM:
      ensure_packet_avail = term_binary_data_size_in_terms(len) +
          BINARY_HEADER_SIZE
    else:
      ensure_packet_avail = len * 2
    port_ensure_available(ctx, 20 + ensure_packet_avail)
    ##  {Ref, {ok, Packet::binary()}}
    var pid: term = recvfrom_data.pid
    var `ref`: term = term_from_ref_ticks(recvfrom_data.ref_ticks, ctx)
    var packet: term = socket_create_packet_term(ctx, buf, len, ensure_packet_avail)
    var reply: term = port_create_ok_tuple(ctx, packet)
    port_send_reply(ctx, pid, `ref`, reply)
  ##
  ##  remove the EventListener from the global list and clean up
  ##
  linkedlist_remove(addr(platform.listeners), addr(listener.listeners_list_head))
  free(listener)
  free(recvfrom_data)
  free(buf)

proc active_recvfrom_callback*(listener: ptr EventListener) {.cdecl.} =
  var ctx: ptr Context = cast[ptr Context](listener.data)
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  ##
  ##  allocate the receive buffer
  ##
  var buf_size: avm_int_t = term_to_int(socket_data.buffer)
  var buf: cstring = malloc(buf_size)
  if IS_NULL_PTR(buf):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    abort()
  var clientaddr: sockaddr_in
  var clientlen: socklen_t = sizeof((clientaddr))
  var len: ssize_t = recvfrom(socket_data.sockfd, buf, buf_size, 0,
                          cast[ptr sockaddr](addr(clientaddr)), addr(clientlen))
  if len == -1:
    ##  {udp, Socket, {error, {SysCall, Errno}}}
    port_ensure_available(ctx, 12)
    var pid: term = socket_data.controlling_process
    var msgs: array[3, term] = [UDP_ATOM, term_from_local_process_id(ctx.process_id), port_create_sys_error_tuple(
        ctx, RECVFROM_ATOM, errno)]
    var msg: term = port_create_tuple_n(ctx, 3, msgs)
    port_send_message(ctx, pid, msg)
  else:
    var ensure_packet_avail: cint
    if socket_data.binary == TRUE_ATOM:
      ensure_packet_avail = term_binary_data_size_in_terms(len) +
          BINARY_HEADER_SIZE
    else:
      ensure_packet_avail = len * 2
    ##  {udp, pid, {int,int,int,int}, int, binary}
    port_ensure_available(ctx, 20 + ensure_packet_avail)
    var pid: term = socket_data.controlling_process
    var `addr`: term = socket_tuple_from_addr(ctx, htonl(clientaddr.sin_addr.s_addr))
    var port: term = term_from_int32(htons(clientaddr.sin_port))
    var packet: term = socket_create_packet_term(ctx, buf, len,
        socket_data.binary == TRUE_ATOM)
    var msgs: array[5, term] = [UDP_ATOM, term_from_local_process_id(ctx.process_id),
                           `addr`, port, packet]
    var msg: term = port_create_tuple_n(ctx, 5, msgs)
    port_send_message(ctx, pid, msg)
  free(buf)

proc passive_recvfrom_callback*(listener: ptr EventListener) {.cdecl.} =
  var recvfrom_data: ptr RecvFromData = cast[ptr RecvFromData](listener.data)
  var ctx: ptr Context = recvfrom_data.ctx
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr GenericUnixPlatformData = glb.platform_data
  ##
  ##  allocate the receive buffer
  ##
  var buf_size: avm_int_t = term_to_int(recvfrom_data.length)
  var buf: cstring = malloc(buf_size)
  if IS_NULL_PTR(buf):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    abort()
  var clientaddr: sockaddr_in
  var clientlen: socklen_t = sizeof((clientaddr))
  var len: ssize_t = recvfrom(socket_data.sockfd, buf, buf_size, 0,
                          cast[ptr sockaddr](addr(clientaddr)), addr(clientlen))
  if len == -1:
    ##  {Ref, {error, {SysCall, Errno}}}
    port_ensure_available(ctx, 12)
    var pid: term = recvfrom_data.pid
    var `ref`: term = term_from_ref_ticks(recvfrom_data.ref_ticks, ctx)
    port_send_reply(ctx, pid, `ref`,
                    port_create_sys_error_tuple(ctx, RECVFROM_ATOM, errno))
  else:
    var ensure_packet_avail: cint
    if socket_data.binary == TRUE_ATOM:
      ensure_packet_avail = term_binary_data_size_in_terms(len) +
          BINARY_HEADER_SIZE
    else:
      ensure_packet_avail = len * 2
    ##  {Ref, {ok, {{int,int,int,int}, int, binary}}}
    port_ensure_available(ctx, 20 + ensure_packet_avail)
    var pid: term = recvfrom_data.pid
    var `ref`: term = term_from_ref_ticks(recvfrom_data.ref_ticks, ctx)
    var `addr`: term = socket_tuple_from_addr(ctx, htonl(clientaddr.sin_addr.s_addr))
    var port: term = term_from_int32(htons(clientaddr.sin_port))
    var packet: term = socket_create_packet_term(ctx, buf, len,
        socket_data.binary == TRUE_ATOM)
    var addr_port_packet: term = port_create_tuple3(ctx, `addr`, port, packet)
    var reply: term = port_create_ok_tuple(ctx, addr_port_packet)
    port_send_reply(ctx, pid, `ref`, reply)
  ##
  ##  remove the EventListener from the global list and clean up
  ##
  linkedlist_remove(addr(platform.listeners), addr(listener.listeners_list_head))
  free(listener)
  free(recvfrom_data)
  free(buf)

proc do_recv*(ctx: ptr Context; pid: term; `ref`: term; length: term; timeout: term;
             handler: event_handler_t) {.cdecl.} =
  UNUSED(timeout)
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr GenericUnixPlatformData = glb.platform_data
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  ##
  ##  The socket must be in active mode
  ##
  if socket_data.active == TRUE_ATOM:
    port_ensure_available(ctx, 12)
    port_send_reply(ctx, pid, `ref`, port_create_error_tuple(ctx, BADARG_ATOM))
    return
  var data: ptr RecvFromData = cast[ptr RecvFromData](malloc(sizeof((RecvFromData))))
  if IS_NULL_PTR(data):
    fprintf(stderr, "Unable to allocate space for RecvFromData: %s:%i\n",
            __FILE__, __LINE__)
    abort()
  data.ctx = ctx
  data.pid = pid
  data.length = length
  data.ref_ticks = term_to_ref_ticks(`ref`)
  ##
  ##  Create an event listener with this request-specific data, and append to the global list
  ##
  var listener: ptr EventListener = malloc(sizeof((EventListener)))
  if IS_NULL_PTR(listener):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    abort()
  listener.fd = socket_data.sockfd
  listener.handler = handler
  listener.data = data
  linkedlist_append(addr(platform.listeners), addr(listener.listeners_list_head))

proc socket_driver_do_recvfrom*(ctx: ptr Context; pid: term; `ref`: term; length: term;
                               timeout: term) {.cdecl.} =
  do_recv(ctx, pid, `ref`, length, timeout, passive_recvfrom_callback)

proc socket_driver_do_recv*(ctx: ptr Context; pid: term; `ref`: term; length: term;
                           timeout: term) {.cdecl.} =
  do_recv(ctx, pid, `ref`, length, timeout, passive_recv_callback)

##
##  accept
##

proc accept_callback*(listener: ptr EventListener) {.cdecl.} =
  var recvfrom_data: ptr RecvFromData = cast[ptr RecvFromData](listener.data)
  var ctx: ptr Context = recvfrom_data.ctx
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr GenericUnixPlatformData = glb.platform_data
  ##
  ##  accept the connection
  ##
  var clientaddr: sockaddr_in
  var clientlen: socklen_t = sizeof((clientaddr))
  var fd: cint = accept(socket_data.sockfd, cast[ptr sockaddr](addr(clientaddr)),
                    addr(clientlen))
  if fd == -1:
    ##  {Ref, {error, {SysCall, Errno}}}
    port_ensure_available(ctx, 12)
    var pid: term = recvfrom_data.pid
    var `ref`: term = term_from_ref_ticks(recvfrom_data.ref_ticks, ctx)
    port_send_reply(ctx, pid, `ref`,
                    port_create_sys_error_tuple(ctx, ACCEPT_ATOM, errno))
  else:
    ##  {Ref, {ok, Fd::int()}}
    port_ensure_available(ctx, 10)
    var pid: term = recvfrom_data.pid
    var `ref`: term = term_from_ref_ticks(recvfrom_data.ref_ticks, ctx)
    var reply: term = port_create_ok_tuple(ctx, term_from_int(fd))
    port_send_reply(ctx, pid, `ref`, reply)
  ##
  ##  remove the EventListener from the global list and clean up
  ##
  linkedlist_remove(addr(platform.listeners), addr(listener.listeners_list_head))
  free(listener)
  free(recvfrom_data)

proc socket_driver_do_accept*(ctx: ptr Context; pid: term; `ref`: term; timeout: term) {.
    cdecl.} =
  UNUSED(timeout)
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr GenericUnixPlatformData = glb.platform_data
  var socket_data: ptr SocketDriverData = cast[ptr SocketDriverData](ctx.platform_data)
  ##
  ##  Create and initialize the request-specific data
  ##
  var data: ptr RecvFromData = cast[ptr RecvFromData](malloc(sizeof((RecvFromData))))
  if IS_NULL_PTR(data):
    fprintf(stderr, "Unable to allocate space for RecvFromData: %s:%i\n",
            __FILE__, __LINE__)
    abort()
  data.ctx = ctx
  data.pid = pid
  data.length = 0
  data.ref_ticks = term_to_ref_ticks(`ref`)
  ##
  ##  Create an event listener with this request-specific data, and append to the global list
  ##
  var listener: ptr EventListener = malloc(sizeof((EventListener)))
  if IS_NULL_PTR(listener):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    abort()
  listener.fd = socket_data.sockfd
  listener.handler = accept_callback
  listener.data = data
  linkedlist_append(addr(platform.listeners), addr(listener.listeners_list_head))

##  TODO define in defaultatoms

var send_a*: cstring = "\x04send"

var sendto_a*: cstring = "\x06sendto"

var init_a*: cstring = "\x04init"

var bind_a*: cstring = "\x04bind"

var recvfrom_a*: cstring = "\brecvfrom"

var recv_a*: cstring = "\x04recv"

var close_a*: cstring = "\x05close"

var get_port_a*: cstring = "\bget_port"

var accept_a*: cstring = "\x06accept"

var sockname_a*: cstring = "\bsockname"

var peername_a*: cstring = "\bpeername"

proc socket_consume_mailbox*(ctx: ptr Context) {.cdecl.} =
  TRACE("START socket_consume_mailbox\n")
  if UNLIKELY(ctx.native_handler != socket_consume_mailbox):
    abort()
  port_ensure_available(ctx, 16)
  var message: ptr Message = mailbox_dequeue(ctx)
  var msg: term = message.message
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  var cmd: term = term_get_tuple_element(msg, 2)
  var cmd_name: term = term_get_tuple_element(cmd, 0)
  if cmd_name == context_make_atom(ctx, init_a):
    var params: term = term_get_tuple_element(cmd, 1)
    var reply: term = socket_driver_do_init(ctx, params)
    port_send_reply(ctx, pid, `ref`, reply)
    if reply != OK_ATOM:
      ##  TODO handle shutdown
      ##  socket_driver_delete_data(ctx->platform_data);
      ##  context_destroy(ctx);
  elif cmd_name == context_make_atom(ctx, sendto_a):
    var dest_address: term = term_get_tuple_element(cmd, 1)
    var dest_port: term = term_get_tuple_element(cmd, 2)
    var buffer: term = term_get_tuple_element(cmd, 3)
    var reply: term = socket_driver_do_sendto(ctx, dest_address, dest_port, buffer)
    port_send_reply(ctx, pid, `ref`, reply)
  elif cmd_name == context_make_atom(ctx, send_a):
    var buffer: term = term_get_tuple_element(cmd, 1)
    var reply: term = socket_driver_do_send(ctx, buffer)
    port_send_reply(ctx, pid, `ref`, reply)
  elif cmd_name == context_make_atom(ctx, recvfrom_a):
    var length: term = term_get_tuple_element(cmd, 1)
    var timeout: term = term_get_tuple_element(cmd, 2)
    socket_driver_do_recvfrom(ctx, pid, `ref`, length, timeout)
  elif cmd_name == context_make_atom(ctx, recv_a):
    var length: term = term_get_tuple_element(cmd, 1)
    var timeout: term = term_get_tuple_element(cmd, 2)
    socket_driver_do_recv(ctx, pid, `ref`, length, timeout)
  elif cmd_name == context_make_atom(ctx, accept_a):
    var timeout: term = term_get_tuple_element(cmd, 1)
    socket_driver_do_accept(ctx, pid, `ref`, timeout)
  elif cmd_name == context_make_atom(ctx, close_a):
    socket_driver_do_close(ctx)
    port_send_reply(ctx, pid, `ref`, OK_ATOM)
    ##  TODO handle shutdown
    ##  socket_driver_delete_data(ctx->platform_data);
    ##  context_destroy(ctx);
  elif cmd_name == context_make_atom(ctx, sockname_a):
    var reply: term = socket_driver_sockname(ctx)
    port_send_reply(ctx, pid, `ref`, reply)
  elif cmd_name == context_make_atom(ctx, peername_a):
    var reply: term = socket_driver_peername(ctx)
    port_send_reply(ctx, pid, `ref`, reply)
  elif cmd_name == context_make_atom(ctx, get_port_a):
    var reply: term = socket_driver_get_port(ctx)
    port_send_reply(ctx, pid, `ref`, reply)
  else:
    port_send_reply(ctx, pid, `ref`, port_create_error_tuple(ctx, BADARG_ATOM))
  free(message)
  TRACE("END socket_consume_mailbox\n")

proc socket_init*(ctx: ptr Context; opts: term) {.cdecl.} =
  UNUSED(opts)
  var data: pointer = socket_driver_create_data()
  ctx.native_handler = socket_consume_mailbox
  ctx.platform_data = data
