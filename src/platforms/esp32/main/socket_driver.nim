## **************************************************************************
##    Copyright 2018,2019 by Davide Bettio <davide@uninstall.it>            *
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
  socket_driver, port, atom, context, globalcontext, mailbox, interop, utils, scheduler,
  sys, term, esp32_sys, platform_defaultatoms

## #define ENABLE_TRACE 1

import
  trace

proc tcp_server_handler*(ctx: ptr Context) {.cdecl.}
proc tcp_client_handler*(ctx: ptr Context) {.cdecl.}
proc udp_handler*(ctx: ptr Context) {.cdecl.}
proc socket_consume_mailbox*(ctx: ptr Context) {.cdecl.}
var ealready_atom*: cstring = "\bealready"

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

proc tuple_to_ip_addr*(address_tuple: term; out_addr: ptr ip_addr_t) {.cdecl.} =
  out_addr.`type` = IPADDR_TYPE_V4
  out_addr.u_addr.ip4.`addr` = htonl(socket_tuple_to_addr(address_tuple))

proc socket_addr_to_tuple*(ctx: ptr Context; `addr`: ptr ip_addr_t): term {.cdecl.} =
  var addr_tuple: term
  case IP_GET_TYPE(`addr`)
  of IPADDR_TYPE_V4:
    var ad1: uint8_t = ip4_addr1(addr((`addr`.u_addr.ip4)))
    var ad2: uint8_t = ip4_addr2(addr((`addr`.u_addr.ip4)))
    var ad3: uint8_t = ip4_addr3(addr((`addr`.u_addr.ip4)))
    var ad4: uint8_t = ip4_addr4(addr((`addr`.u_addr.ip4)))
    addr_tuple = term_alloc_tuple(4, ctx)
    term_put_tuple_element(addr_tuple, 0, term_from_int11(ad1))
    term_put_tuple_element(addr_tuple, 1, term_from_int11(ad2))
    term_put_tuple_element(addr_tuple, 2, term_from_int11(ad3))
    term_put_tuple_element(addr_tuple, 3, term_from_int11(ad4))
    break
  of IPADDR_TYPE_V6:           ## TODO: implement IPv6
    addr_tuple = term_invalid_term()
  else:
    addr_tuple = term_invalid_term()
  return addr_tuple

type
  socket_type* = enum
    TCPServerSocket, TCPClientSocket, UDPSocket


type
  SocketData* {.bycopy.} = object
    sockets_head*: ListHead
    conn*: ptr netconn
    ctx*: ptr Context
    `type`*: socket_type
    controlling_process_pid*: term
    passive_receiver_process_pid*: term
    passive_ref_ticks*: uint64_t
    avail_bytes*: cint
    port*: uint16_t
    active* {.bitsize: 1.}: bool
    binary* {.bitsize: 1.}: bool

  TCPClientSocketData* {.bycopy.} = object
    socket_data*: SocketData

  TCPServerSocketData* {.bycopy.} = object
    socket_data*: SocketData
    ready_connections*: cint
    accepters_list_head*: ListHead

  TCPServerAccepter* {.bycopy.} = object
    accepter_head*: ListHead
    accepting_process_pid*: term
    ref_ticks*: uint64_t

  UDPSocketData* {.bycopy.} = object
    socket_data*: SocketData

  NetconnEvent* {.bycopy.} = object
    netconn*: ptr netconn
    evt*: netconn_evt
    len*: u16_t


var netconn_events*: xQueueHandle = nil

proc socket_events_handler*(listener: ptr EventListener) {.cdecl.} =
  TRACE("socket_events_handler\n")
  var glb: ptr GlobalContext = listener.data
  var platform: ptr ESP32PlatformData = glb.platform_data
  var event: NetconnEvent
  while xQueueReceive(netconn_events, addr(event), 1) == pdTRUE:
    TRACE("Got netconn event: %p %i %i\n", event.netconn, event.evt, event.len)
    var netconn: ptr netconn = event.netconn
    var evt: netconn_evt = event.evt
    var len: u16_t = event.len
    var socket: ptr SocketData = nil
    var socket_head: ptr ListHead
    ##  TODO: FIXME
    socket_head = (addr(platform.sockets_list_head)).next
    while socket_head != (addr(platform.sockets_list_head)):
      ##  LIST_FOR_EACH(socket_head, &platform->sockets_list_head) {
      var current_socket: ptr SocketData = GET_LIST_ENTRY(socket_head, struct,
          SocketData, sockets_head)
      if current_socket.conn == netconn:
        socket = current_socket
      socket_head = item.next
    if socket:
      if (evt == NETCONN_EVT_RCVMINUS): ## && (len != 0)
        TRACE("Ignoring RCVMINUS event\n")
        continue
      if (evt == NETCONN_EVT_SENDMINUS) or (evt == NETCONN_EVT_SENDPLUS):
        TRACE("Ignoring SENDMINUS/SENDPLUS event\n")
        continue
      if evt == NETCONN_EVT_ERROR:
        TRACE("Ignoring ERROR event\n")
        continue
      inc(socket.avail_bytes, len)
      case socket.`type`
      of TCPServerSocket:
        tcp_server_handler(socket.ctx)
      of TCPClientSocket:
        tcp_client_handler(socket.ctx)
      of UDPSocket:
        udp_handler(socket.ctx)
      else:
        fprintf(stderr, "bug: unknown socket type.\n")
    else:
      TRACE("Got event for unknown conn: %p, evt: %i, len: %i\n", netconn,
            cast[cint](evt), cast[cint](len))

proc socket_driver_init*(glb: ptr GlobalContext) {.cdecl.} =
  TRACE("Initializing socket driver\n")
  netconn_events = xQueueCreate(32, sizeof(NetconnEvent))
  var socket_listener: ptr EventListener = malloc(sizeof((EventListener)))
  var platform: ptr ESP32PlatformData = glb.platform_data
  sys_event_listener_init(socket_listener, addr(netconn_events),
                          socket_events_handler, glb)
  list_append(addr(platform.listeners), addr(socket_listener.listeners_list_head))
  list_init(addr(platform.sockets_list_head))
  TRACE("Socket driver init: done\n")

proc socket_data_init*(data: ptr SocketData; ctx: ptr Context; conn: ptr netconn;
                      `type`: socket_type; platform: ptr ESP32PlatformData) {.cdecl.} =
  data.`type` = `type`
  data.conn = conn
  data.ctx = ctx
  data.controlling_process_pid = term_invalid_term()
  data.port = 0
  data.active = true
  data.binary = false
  list_append(addr(platform.sockets_list_head), addr(data.sockets_head))
  data.passive_receiver_process_pid = term_invalid_term()
  data.passive_ref_ticks = 0
  data.avail_bytes = 0
  ctx.platform_data = data

proc tcp_server_socket_data_new*(ctx: ptr Context; conn: ptr netconn;
                                platform: ptr ESP32PlatformData): ptr TCPServerSocketData {.
    cdecl.} =
  var tcp_data: ptr TCPServerSocketData = malloc(sizeof(TCPServerSocketData))
  if IS_NULL_PTR(tcp_data):
    return nil
  socket_data_init(addr(tcp_data.socket_data), ctx, conn, TCPServerSocket, platform)
  tcp_data.ready_connections = 0
  list_init(addr(tcp_data.accepters_list_head))
  return tcp_data

proc tcp_client_socket_data_new*(ctx: ptr Context; conn: ptr netconn;
                                platform: ptr ESP32PlatformData;
                                controlling_process_pid: term): ptr TCPClientSocketData {.
    cdecl.} =
  var tcp_data: ptr TCPClientSocketData = malloc(sizeof(TCPClientSocketData))
  if IS_NULL_PTR(tcp_data):
    return nil
  socket_data_init(addr(tcp_data.socket_data), ctx, conn, TCPClientSocket, platform)
  tcp_data.socket_data.controlling_process_pid = controlling_process_pid
  return tcp_data

proc udp_socket_data_new*(ctx: ptr Context; conn: ptr netconn;
                         platform: ptr ESP32PlatformData;
                         controlling_process_pid: term): ptr UDPSocketData {.cdecl.} =
  var udp_data: ptr UDPSocketData = malloc(sizeof(UDPSocketData))
  if IS_NULL_PTR(udp_data):
    return nil
  socket_data_init(addr(udp_data.socket_data), ctx, conn, UDPSocket, platform)
  udp_data.socket_data.controlling_process_pid = controlling_process_pid
  return udp_data

proc send_message*(pid: term; message: term; global: ptr GlobalContext) {.cdecl.} =
  var local_process_id: cint = term_to_local_process_id(pid)
  var target: ptr Context = globalcontext_get_process(global, local_process_id)
  mailbox_send(target, message)

##  TODO: FIXME
##  void ESP_IRAM_ATTR socket_callback(struct netconn *netconn, enum netconn_evt evt, u16_t len)

proc socket_callback*(netconn: ptr netconn; evt: netconn_evt; len: u16_t) {.cdecl.} =
  var event: NetconnEvent
  event.netconn = netconn
  event.evt = evt
  event.len = len
  var xHigherPriorityTaskWoken: BaseType_t
  var result: cint = xQueueSendFromISR(netconn_events, addr(event),
                                   addr(xHigherPriorityTaskWoken))
  if result != pdTRUE:
    fprintf(stderr, "socket: failed to enqueue: %i to netconn_events.\n", result)
  var netconn_events_ptr: pointer = addr(netconn_events)
  result = xQueueSendFromISR(event_queue, addr(netconn_events_ptr),
                           addr(xHigherPriorityTaskWoken))
  if result != pdTRUE:
    fprintf(stderr, "socket: failed to enqueue: %i to event_queue.\n", result)

proc accept_conn*(accepter: ptr TCPServerAccepter; ctx: ptr Context) {.cdecl.} =
  TRACE("Going to accept a TCP connection\n")
  var tcp_data: ptr TCPServerSocketData = ctx.platform_data
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr ESP32PlatformData = glb.platform_data
  var accepted_conn: ptr netconn
  var status: err_t = netconn_accept(tcp_data.socket_data.conn, addr(accepted_conn))
  if UNLIKELY(status != ERR_OK):
    ## TODO
    fprintf(stderr, "accept error: %i on %p\n", status,
            cast[pointer](tcp_data.socket_data.conn))
    return
  var pid: term = accepter.accepting_process_pid
  TRACE("accepted conn: %p\n", accepted_conn)
  var new_ctx: ptr Context = context_new(glb)
  new_ctx.native_handler = socket_consume_mailbox
  scheduler_make_waiting(glb, new_ctx)
  var socket_pid: term = term_from_local_process_id(new_ctx.process_id)
  var new_tcp_data: ptr TCPClientSocketData = tcp_client_socket_data_new(new_ctx,
      accepted_conn, platform, pid)
  if IS_NULL_PTR(new_tcp_data):
    abort()
  if UNLIKELY(memory_ensure_free(ctx, 128) != MEMORY_GC_OK):
    abort()
  var `ref`: term = term_from_ref_ticks(accepter.ref_ticks, ctx)
  var return_tuple: term = term_alloc_tuple(2, ctx)
  free(accepter)
  var result_tuple: term = term_alloc_tuple(2, ctx)
  term_put_tuple_element(result_tuple, 0, OK_ATOM)
  term_put_tuple_element(result_tuple, 1, socket_pid)
  term_put_tuple_element(return_tuple, 0, `ref`)
  term_put_tuple_element(return_tuple, 1, result_tuple)
  send_message(pid, return_tuple, glb)

proc do_accept*(ctx: ptr Context; msg: term) {.cdecl.} =
  var tcp_data: ptr TCPServerSocketData = ctx.platform_data
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  var accepter: ptr TCPServerAccepter = malloc(sizeof(TCPServerAccepter))
  accepter.accepting_process_pid = pid
  accepter.ref_ticks = term_to_ref_ticks(`ref`)
  list_append(addr(tcp_data.accepters_list_head), addr(accepter.accepter_head))
  if tcp_data.ready_connections:
    TRACE("accepting existing connections.\n")
    var accepter_head: ptr ListHead
    var tmp: ptr ListHead
    var accepter: ptr TCPServerAccepter = nil
    ##  MUTABLE_LIST_FOR_EACH(accepter_head, tmp, &tcp_data->accepters_list_head) {
    accepter_head = (addr(tcp_data.accepters_list_head)).next
    tmp = accepter_head.next
    while accepter_head != (addr(tcp_data.accepters_list_head)):
      ## TODO: check if is alive here
      if 1:
        accepter = GET_LIST_ENTRY(accepter_head, struct, TCPServerAccepter,
                                accepter_head)
        list_remove(accepter_head)
      accepter_head = tmp
      tmp = accepter_head.next
    if accepter:
      accept_conn(accepter, ctx)
      dec(tcp_data.ready_connections)

proc tcp_client_handler*(ctx: ptr Context) {.cdecl.} =
  TRACE("tcp_client_handler\n")
  var tcp_data: ptr TCPClientSocketData = ctx.platform_data
  var glb: ptr GlobalContext = ctx.global
  if not tcp_data.socket_data.active:
    return
  if not tcp_data.socket_data.avail_bytes:
    TRACE("No bytes to receive.\n")
    return
  var buf: ptr netbuf = nil
  var status: err_t = netconn_recv(tcp_data.socket_data.conn, addr(buf))
  if UNLIKELY(status != ERR_OK):
    ## TODO
    fprintf(stderr, "tcp_client_handler error: %i\n", status)
    return
  var data: pointer
  var data_len: u16_t
  status = netbuf_data(buf, addr(data), addr(data_len))
  if UNLIKELY(status != ERR_OK):
    ## TODO
    fprintf(stderr, "netbuf_data error: %i\n", status)
    return
  dec(tcp_data.socket_data.avail_bytes, data_len)
  ## HANDLE fragments here?
  TRACE("%*s\n", cast[cint](data_len), cast[cstring](data))
  var recv_terms_size: cint
  if tcp_data.socket_data.binary:
    recv_terms_size = term_binary_data_size_in_terms(data_len) +
        BINARY_HEADER_SIZE
  else:
    recv_terms_size = data_len * 2
  var tuples_size: cint
  if tcp_data.socket_data.active:
    ##  tuples_size = 5 (result_tuple size)
    tuples_size = 4
  else:
    ##  tuples_size = 3 (ok_tuple size) + 3 (result_tuple size)
    tuples_size = 3 + 3
  if UNLIKELY(memory_ensure_free(ctx, tuples_size + recv_terms_size) !=
      MEMORY_GC_OK):
    abort()
  var recv_data: term
  if tcp_data.socket_data.binary:
    recv_data = term_create_uninitialized_binary(data_len, ctx)
    memcpy(cast[pointer](term_binary_data(recv_data)), data, data_len)
  else:
    recv_data = term_from_string(cast[ptr uint8_t](data), data_len, ctx)
  netbuf_delete(buf)
  var pid: term = tcp_data.socket_data.controlling_process_pid
  var result_tuple: term
  if tcp_data.socket_data.active:
    result_tuple = term_alloc_tuple(3, ctx)
    term_put_tuple_element(result_tuple, 0, TCP_ATOM)
    term_put_tuple_element(result_tuple, 1,
                           term_from_local_process_id(ctx.process_id))
    term_put_tuple_element(result_tuple, 2, recv_data)
  else:
    var ok_tuple: term = term_alloc_tuple(2, ctx)
    term_put_tuple_element(ok_tuple, 0, OK_ATOM)
    term_put_tuple_element(ok_tuple, 1, recv_data)
    result_tuple = term_alloc_tuple(2, ctx)
    term_put_tuple_element(result_tuple, 0, term_from_ref_ticks(
        tcp_data.socket_data.passive_ref_ticks, ctx))
    term_put_tuple_element(result_tuple, 1, ok_tuple)
    pid = tcp_data.socket_data.passive_receiver_process_pid
    tcp_data.socket_data.passive_receiver_process_pid = term_invalid_term()
    tcp_data.socket_data.passive_ref_ticks = 0
  TRACE("sending received: ")
  when defined(ENABLE_TRACE):
    term_display(stdout, result_tuple, ctx)
  TRACE(" to ")
  when defined(ENABLE_TRACE):
    term_display(stdout, pid, ctx)
  TRACE("\n")
  send_message(pid, result_tuple, glb)

proc tcp_server_handler*(ctx: ptr Context) {.cdecl.} =
  TRACE("tcp_server_handler\n")
  var tcp_data: ptr TCPServerSocketData = ctx.platform_data
  var accepter_head: ptr ListHead
  var tmp: ptr ListHead
  var accepter: ptr TCPServerAccepter = nil
  ##  MUTABLE_LIST_FOR_EACH(accepter_head, tmp, &tcp_data->accepters_list_head) {
  accepter_head = (addr(tcp_data.accepters_list_head)).next
  tmp = accepter_head.next
  while accepter_head != (addr(tcp_data.accepters_list_head)):
    ## TODO: is alive here
    if 1:
      accepter = GET_LIST_ENTRY(accepter_head, struct, TCPServerAccepter,
                              accepter_head)
      list_remove(accepter_head)
    accepter_head = tmp
    tmp = accepter_head.next
  if accepter:
    accept_conn(accepter, ctx)
  else:
    inc(tcp_data.ready_connections)

proc udp_handler*(ctx: ptr Context) {.cdecl.} =
  TRACE("udp_client_handler\n")
  var udp_data: ptr UDPSocketData = ctx.platform_data
  var glb: ptr GlobalContext = ctx.global
  var socket_data: ptr SocketData = addr(udp_data.socket_data)
  if not socket_data.active and
      (socket_data.passive_receiver_process_pid == term_invalid_term()):
    return
  if not udp_data.socket_data.avail_bytes:
    TRACE("No bytes to receive.\n")
    return
  var buf: ptr netbuf = nil
  var status: err_t = netconn_recv(udp_data.socket_data.conn, addr(buf))
  if UNLIKELY(status != ERR_OK):
    ## TODO
    fprintf(stderr, "tcp_client_handler error: %i\n", status)
    return
  var data: pointer
  var data_len: u16_t
  status = netbuf_data(buf, addr(data), addr(data_len))
  if UNLIKELY(status != ERR_OK):
    ## TODO
    fprintf(stderr, "netbuf_data error: %i\n", status)
    return
  dec(udp_data.socket_data.avail_bytes, data_len)
  ## HANDLE fragments here?
  TRACE("%*s\n", cast[cint](data_len), cast[cstring](data))
  var recv_terms_size: cint
  if udp_data.socket_data.binary:
    recv_terms_size = term_binary_data_size_in_terms(data_len) +
        BINARY_HEADER_SIZE
  else:
    recv_terms_size = data_len * 2
  var tuples_size: cint
  if socket_data.active:
    ##  tuples_size = 5 (addr size) + 6 (result_tuple size)
    tuples_size = 5 + 6
  else:
    ##  tuples_size = 4 (recv_ret size) + 5 (addr size) + 3 (ok_tuple size) + 3 (result_tuple size)
    tuples_size = 4 + 5 + 3 + 3
  if UNLIKELY(memory_ensure_free(ctx, tuples_size + recv_terms_size) !=
      MEMORY_GC_OK):
    abort()
  var recv_data: term
  if udp_data.socket_data.binary:
    recv_data = term_create_uninitialized_binary(data_len, ctx)
    memcpy(cast[pointer](term_binary_data(recv_data)), data, data_len)
  else:
    recv_data = term_from_string(cast[ptr uint8_t](data), data_len, ctx)
  var `addr`: term = socket_addr_to_tuple(ctx, netbuf_fromaddr(buf))
  var port: term = term_from_int32(netbuf_fromport(buf))
  netbuf_delete(buf)
  var pid: term = udp_data.socket_data.controlling_process_pid
  var result_tuple: term
  if socket_data.active:
    result_tuple = term_alloc_tuple(5, ctx)
    term_put_tuple_element(result_tuple, 0, UDP_ATOM)
    term_put_tuple_element(result_tuple, 1,
                           term_from_local_process_id(ctx.process_id))
    term_put_tuple_element(result_tuple, 2, `addr`)
    term_put_tuple_element(result_tuple, 3, port)
    term_put_tuple_element(result_tuple, 4, recv_data)
  else:
    var recv_ret: term = term_alloc_tuple(3, ctx)
    term_put_tuple_element(recv_ret, 0, `addr`)
    term_put_tuple_element(recv_ret, 1, port)
    term_put_tuple_element(recv_ret, 2, recv_data)
    var ok_tuple: term = term_alloc_tuple(2, ctx)
    term_put_tuple_element(ok_tuple, 0, OK_ATOM)
    term_put_tuple_element(ok_tuple, 1, recv_ret)
    result_tuple = term_alloc_tuple(2, ctx)
    term_put_tuple_element(result_tuple, 0, term_from_ref_ticks(
        socket_data.passive_ref_ticks, ctx))
    term_put_tuple_element(result_tuple, 1, ok_tuple)
    pid = socket_data.passive_receiver_process_pid
    socket_data.passive_receiver_process_pid = term_invalid_term()
    socket_data.passive_ref_ticks = 0
  TRACE("sending received: ")
  when defined(ENABLE_TRACE):
    term_display(stdout, result_tuple, ctx)
  TRACE(" to ")
  when defined(ENABLE_TRACE):
    term_display(stdout, pid, ctx)
  TRACE("\n")
  send_message(pid, result_tuple, glb)

proc bool_term_to_bool*(b: term; ok: ptr bool): bool {.cdecl.} =
  case b
  of TRUE_ATOM:
    ok[] = true
    return true
  of FALSE_ATOM:
    ok[] = true
    return false
  else:
    ok[] = false
    return false

proc do_connect*(ctx: ptr Context; msg: term) {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr ESP32PlatformData = glb.platform_data
  var cmd: term = term_get_tuple_element(msg, 2)
  var params: term = term_get_tuple_element(cmd, 1)
  var address_term: term = interop_proplist_get_value(params, ADDRESS_ATOM)
  var port_term: term = interop_proplist_get_value(params, PORT_ATOM)
  var binary_term: term = interop_proplist_get_value(params, BINARY_ATOM)
  var active_term: term = interop_proplist_get_value(params, ACTIVE_ATOM)
  var controlling_process_term: term = interop_proplist_get_value(params,
      CONTROLLING_PROCESS_ATOM)
  var ok_int: cint
  var address_string: cstring = interop_term_to_string(address_term, addr(ok_int))
  if UNLIKELY(not ok_int):
    abort()
  var port: avm_int_t = term_to_int(port_term)
  var ok: bool
  var active: bool = bool_term_to_bool(active_term, addr(ok))
  if UNLIKELY(not ok):
    abort()
  var binary: bool = bool_term_to_bool(binary_term, addr(ok))
  if UNLIKELY(not ok):
    abort()
  TRACE("tcp: connecting to: %s\n", address_string)
  var remote_ip: ip_addr
  ## TODO: use dns_gethostbyname instead
  var status: err_t = netconn_gethostbyname(address_string, addr(remote_ip))
  if UNLIKELY(status != ERR_OK):
    free(address_string)
    TRACE("tcp: host resolution failed.\n")
    return
  TRACE("tcp: host resolved.\n")
  free(address_string)
  var conn: ptr netconn = netconn_new_with_proto_and_callback(NETCONN_TCP, 0,
      socket_callback)
  if IS_NULL_PTR(conn):
    abort()
  status = netconn_connect(conn, addr(remote_ip), port)
  if UNLIKELY(status != ERR_OK):
    TRACE("tcp: failed connect: %i\n", status)
    return
  TRACE("tcp: connected.\n")
  var tcp_data: ptr TCPClientSocketData = tcp_client_socket_data_new(ctx, conn,
      platform, controlling_process_term)
  if IS_NULL_PTR(tcp_data):
    abort()
  tcp_data.socket_data.active = active
  tcp_data.socket_data.binary = binary
  if UNLIKELY(memory_ensure_free(ctx, 3) != MEMORY_GC_OK):
    abort()
  var return_tuple: term = term_alloc_tuple(2, ctx)
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  term_put_tuple_element(return_tuple, 0, `ref`)
  term_put_tuple_element(return_tuple, 1, OK_ATOM)
  send_message(pid, return_tuple, glb)

proc do_listen*(ctx: ptr Context; msg: term) {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr ESP32PlatformData = glb.platform_data
  var cmd: term = term_get_tuple_element(msg, 2)
  var params: term = term_get_tuple_element(cmd, 1)
  var port_term: term = interop_proplist_get_value(params, PORT_ATOM)
  var backlog_term: term = interop_proplist_get_value(params, BACKLOG_ATOM)
  var binary_term: term = interop_proplist_get_value(params, BINARY_ATOM)
  var active_term: term = interop_proplist_get_value(params, ACTIVE_ATOM)
  var port: avm_int_t = term_to_int(port_term)
  var backlog: avm_int_t = term_to_int(backlog_term)
  var ok: bool
  var active: bool = bool_term_to_bool(active_term, addr(ok))
  if UNLIKELY(not ok):
    abort()
  var binary: bool = bool_term_to_bool(binary_term, addr(ok))
  if UNLIKELY(not ok):
    abort()
  var conn: ptr netconn = netconn_new_with_proto_and_callback(NETCONN_TCP, 0,
      socket_callback)
  var status: err_t = netconn_bind(conn, IP_ADDR_ANY, port)
  if UNLIKELY(status != ERR_OK):
    ## TODO
    fprintf(stderr, "bind error: %i\n", status)
    return
  var naddr: ip_addr_t
  var nport: u16_t
  status = netconn_getaddr(conn, addr(naddr), addr(nport), 1)
  if UNLIKELY(status != ERR_OK):
    ## TODO
    fprintf(stderr, "getaddr error: %i\n", status)
    return
  status = netconn_listen_with_backlog(conn, backlog)
  if UNLIKELY(status != ERR_OK):
    ## TODO
    fprintf(stderr, "listen error: %i\n", status)
    return
  var tcp_data: ptr TCPServerSocketData = tcp_server_socket_data_new(ctx, conn,
      platform)
  if IS_NULL_PTR(tcp_data):
    abort()
  tcp_data.socket_data.port = nport
  tcp_data.socket_data.active = active
  tcp_data.socket_data.binary = binary
  if UNLIKELY(memory_ensure_free(ctx, 3) != MEMORY_GC_OK):
    abort()
  var return_tuple: term = term_alloc_tuple(2, ctx)
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  term_put_tuple_element(return_tuple, 0, `ref`)
  term_put_tuple_element(return_tuple, 1, OK_ATOM)
  send_message(pid, return_tuple, glb)

proc do_udp_open*(ctx: ptr Context; msg: term) {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr ESP32PlatformData = glb.platform_data
  var cmd: term = term_get_tuple_element(msg, 2)
  var params: term = term_get_tuple_element(cmd, 1)
  var port_term: term = interop_proplist_get_value(params, PORT_ATOM)
  var binary_term: term = interop_proplist_get_value(params, BINARY_ATOM)
  var active_term: term = interop_proplist_get_value(params, ACTIVE_ATOM)
  var controlling_process: term = interop_proplist_get_value(params,
      CONTROLLING_PROCESS_ATOM)
  var port: avm_int_t = term_to_int(port_term)
  var ok: bool
  var active: bool = bool_term_to_bool(active_term, addr(ok))
  if UNLIKELY(not ok):
    abort()
  var binary: bool = bool_term_to_bool(binary_term, addr(ok))
  if UNLIKELY(not ok):
    abort()
  var conn: ptr netconn = netconn_new_with_proto_and_callback(NETCONN_UDP, 0,
      socket_callback)
  if IS_NULL_PTR(conn):
    fprintf(stderr, "failed to open conn\n")
    abort()
  var udp_data: ptr UDPSocketData = udp_socket_data_new(ctx, conn, platform,
      controlling_process)
  if IS_NULL_PTR(udp_data):
    abort()
  udp_data.socket_data.active = active
  udp_data.socket_data.binary = binary
  if port != 0:
    var status: err_t = netconn_bind(conn, IP_ADDR_ANY, port)
    if UNLIKELY(status != ERR_OK):
      fprintf(stderr, "bind error: %i\n", status)
      return
  var naddr: ip_addr_t
  var nport: u16_t
  var status: err_t = netconn_getaddr(conn, addr(naddr), addr(nport), 1)
  if UNLIKELY(status != ERR_OK):
    ## TODO
    fprintf(stderr, "getaddr error: %i\n", status)
    return
  udp_data.socket_data.port = nport
  if UNLIKELY(memory_ensure_free(ctx, 3) != MEMORY_GC_OK):
    abort()
  var return_tuple: term = term_alloc_tuple(2, ctx)
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  term_put_tuple_element(return_tuple, 0, `ref`)
  term_put_tuple_element(return_tuple, 1, OK_ATOM)
  send_message(pid, return_tuple, glb)

##  Required for compatibility with existing erlang libraries
##  TODO: remove this when not required anymore

proc do_init*(ctx: ptr Context; msg: term) {.cdecl.} =
  var cmd: term = term_get_tuple_element(msg, 2)
  var params: term = term_get_tuple_element(cmd, 1)
  if interop_proplist_get_value_default(params, LISTEN_ATOM, FALSE_ATOM) ==
      TRUE_ATOM:
    TRACE("listen\n")
    do_listen(ctx, msg)
  elif interop_proplist_get_value_default(params, CONNECT_ATOM, FALSE_ATOM) ==
      TRUE_ATOM:
    TRACE("connect\n")
    do_connect(ctx, msg)
  elif interop_proplist_get_value_default(params, PROTO_ATOM, FALSE_ATOM) ==
      UDP_ATOM:
    TRACE("udp_open\n")
    do_udp_open(ctx, msg)

proc do_send*(ctx: ptr Context; msg: term) {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var tcp_data: ptr TCPServerSocketData = ctx.platform_data
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  var cmd: term = term_get_tuple_element(msg, 2)
  var data: term = term_get_tuple_element(cmd, 1)
  var ok: cint
  var buffer_size: cint = interop_iolist_size(data, addr(ok))
  if UNLIKELY(not ok):
    fprintf(stderr, "error: invalid iolist.\n")
    return
  var buffer: pointer = malloc(buffer_size)
  interop_write_iolist(data, buffer)
  var status: err_t = netconn_write(tcp_data.socket_data.conn, buffer, buffer_size,
                                NETCONN_NOCOPY)
  if UNLIKELY(status != ERR_OK):
    fprintf(stderr, "write error: %i\n", status)
    return
  free(buffer)
  if UNLIKELY(memory_ensure_free(ctx, 3) != MEMORY_GC_OK):
    abort()
  var return_tuple: term = term_alloc_tuple(2, ctx)
  term_put_tuple_element(return_tuple, 0, `ref`)
  term_put_tuple_element(return_tuple, 1, OK_ATOM)
  send_message(pid, return_tuple, glb)

proc do_sendto*(ctx: ptr Context; msg: term) {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var udp_data: ptr UDPSocketData = ctx.platform_data
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  var cmd: term = term_get_tuple_element(msg, 2)
  var dest_addr_term: term = term_get_tuple_element(cmd, 1)
  var dest_port_term: term = term_get_tuple_element(cmd, 2)
  var data: term = term_get_tuple_element(cmd, 3)
  var ok: cint
  var buffer_size: cint = interop_iolist_size(data, addr(ok))
  var buffer: pointer = malloc(buffer_size)
  interop_write_iolist(data, buffer)
  var ip4addr: ip_addr_t
  tuple_to_ip_addr(dest_addr_term, addr(ip4addr))
  var destport: uint16_t = term_to_int32(dest_port_term)
  var sendbuf: ptr netbuf = netbuf_new()
  var status: err_t = netbuf_ref(sendbuf, buffer, buffer_size)
  if UNLIKELY(status != ERR_OK):
    fprintf(stderr, "netbuf_ref error: %i\n", status)
    netbuf_delete(sendbuf)
    return
  status = netconn_sendto(udp_data.socket_data.conn, sendbuf, addr(ip4addr), destport)
  if UNLIKELY(status != ERR_OK):
    fprintf(stderr, "netbuf_ref error: %i\n", status)
    netbuf_delete(sendbuf)
    return
  netbuf_delete(sendbuf)
  free(buffer)
  if UNLIKELY(memory_ensure_free(ctx, 3) != MEMORY_GC_OK):
    abort()
  var return_tuple: term = term_alloc_tuple(2, ctx)
  term_put_tuple_element(return_tuple, 0, `ref`)
  term_put_tuple_element(return_tuple, 1, OK_ATOM)
  send_message(pid, return_tuple, glb)

proc do_close*(ctx: ptr Context; msg: term) {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var tcp_data: ptr TCPServerSocketData = ctx.platform_data
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  var res: err_t = netconn_delete(tcp_data.socket_data.conn)
  if res != ERR_OK:
    TRACE("socket: close failed")
    return
  tcp_data.socket_data.conn = nil
  list_remove(addr(tcp_data.socket_data.sockets_head))
  if UNLIKELY(memory_ensure_free(ctx, 3) != MEMORY_GC_OK):
    abort()
  var return_tuple: term = term_alloc_tuple(2, ctx)
  term_put_tuple_element(return_tuple, 0, `ref`)
  term_put_tuple_element(return_tuple, 1, OK_ATOM)
  send_message(pid, return_tuple, glb)
  free(tcp_data)
  scheduler_terminate(ctx)

proc do_recvfrom*(ctx: ptr Context; msg: term) {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var socket_data: ptr SocketData = ctx.platform_data
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  if socket_data.passive_receiver_process_pid != term_invalid_term():
    ##  3 (error_tuple) + 3 (result_tuple)
    if UNLIKELY(memory_ensure_free(ctx, 3 + 3) != MEMORY_GC_OK):
      abort()
    var ealready: term = context_make_atom(ctx, ealready_atom)
    var error_tuple: term = term_alloc_tuple(2, ctx)
    term_put_tuple_element(error_tuple, 0, ERROR_ATOM)
    term_put_tuple_element(error_tuple, 1, ealready)
    var result_tuple: term = term_alloc_tuple(2, ctx)
    term_put_tuple_element(result_tuple, 0, `ref`)
    term_put_tuple_element(result_tuple, 1, error_tuple)
    send_message(pid, result_tuple, glb)
  if socket_data.avail_bytes:
    TRACE(stderr, "do_recvfrom: have already ready bytes.\n")
    var buf: ptr netbuf = nil
    var status: err_t = netconn_recv(socket_data.conn, addr(buf))
    if UNLIKELY(status != ERR_OK):
      ## TODO
      fprintf(stderr, "tcp_client_handler error: %i\n", status)
      return
    var data: pointer
    var data_len: u16_t
    status = netbuf_data(buf, addr(data), addr(data_len))
    if UNLIKELY(status != ERR_OK):
      ## TODO
      fprintf(stderr, "netbuf_data error: %i\n", status)
      return
    dec(socket_data.avail_bytes, data_len)
    ## HANDLE fragments here?
    TRACE("%*s\n", cast[cint](data_len), cast[cstring](data))
    var recv_terms_size: cint
    if socket_data.binary:
      recv_terms_size = term_binary_data_size_in_terms(data_len) +
          BINARY_HEADER_SIZE
    else:
      recv_terms_size = data_len * 2
    ##  4 (recv_ret size) + 3 (ok_tuple size) + 3 (result_tuple size) + recv_terms_size
    if UNLIKELY(memory_ensure_free(ctx, 4 + 3 + 3 + recv_terms_size) != MEMORY_GC_OK):
      abort()
    var recv_data: term
    if socket_data.binary:
      recv_data = term_create_uninitialized_binary(data_len, ctx)
      memcpy(cast[pointer](term_binary_data(recv_data)), data, data_len)
    else:
      recv_data = term_from_string(cast[ptr uint8_t](data), data_len, ctx)
    var `addr`: term = socket_addr_to_tuple(ctx, netbuf_fromaddr(buf))
    var port: term = term_from_int32(netbuf_fromport(buf))
    netbuf_delete(buf)
    var recv_ret: term = term_alloc_tuple(3, ctx)
    term_put_tuple_element(recv_ret, 0, `addr`)
    term_put_tuple_element(recv_ret, 1, port)
    term_put_tuple_element(recv_ret, 2, recv_data)
    var ok_tuple: term = term_alloc_tuple(2, ctx)
    term_put_tuple_element(ok_tuple, 0, OK_ATOM)
    term_put_tuple_element(ok_tuple, 1, recv_ret)
    var result_tuple: term = term_alloc_tuple(2, ctx)
    term_put_tuple_element(result_tuple, 0, `ref`)
    term_put_tuple_element(result_tuple, 1, ok_tuple)
    send_message(pid, result_tuple, glb)
  else:
    socket_data.passive_receiver_process_pid = pid
    socket_data.passive_ref_ticks = term_to_ref_ticks(`ref`)

proc do_get_port*(ctx: ptr Context; msg: term) {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var socket_data: ptr SocketData = ctx.platform_data
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  ##  3 (error_ok_tuple) + 3 (result_tuple)
  if UNLIKELY(memory_ensure_free(ctx, 3 + 3) != MEMORY_GC_OK):
    abort()
  var error_ok_tuple: term = term_alloc_tuple(2, ctx)
  if socket_data.port != 0:
    term_put_tuple_element(error_ok_tuple, 0, OK_ATOM)
    term_put_tuple_element(error_ok_tuple, 1, term_from_int(socket_data.port))
  else:
    term_put_tuple_element(error_ok_tuple, 0, ERROR_ATOM)
    term_put_tuple_element(error_ok_tuple, 1, BADARG_ATOM)
  var result_tuple: term = term_alloc_tuple(2, ctx)
  term_put_tuple_element(result_tuple, 0, `ref`)
  term_put_tuple_element(result_tuple, 1, error_ok_tuple)
  send_message(pid, result_tuple, glb)

proc do_sockname*(ctx: ptr Context; msg: term) {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var socket_data: ptr SocketData = ctx.platform_data
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  var `addr`: ip_addr_t
  var port: u16_t
  var result: err_t = netconn_addr(socket_data.conn, addr(`addr`), addr(port))
  var return_msg: term
  if result != ERR_OK:
    if UNLIKELY(memory_ensure_free(ctx, 3 + 3) != MEMORY_GC_OK):
      abort()
    return_msg = term_alloc_tuple(2, ctx)
    term_put_tuple_element(return_msg, 0, ERROR_ATOM)
    term_put_tuple_element(return_msg, 1, term_from_int(result))
  else:
    if UNLIKELY(memory_ensure_free(ctx, 3 + 8) != MEMORY_GC_OK):
      abort()
    return_msg = term_alloc_tuple(2, ctx)
    var addr_term: term = socket_addr_to_tuple(ctx, addr(`addr`))
    var port_term: term = term_from_int(port)
    term_put_tuple_element(return_msg, 0, addr_term)
    term_put_tuple_element(return_msg, 1, port_term)
  var result_tuple: term = term_alloc_tuple(2, ctx)
  term_put_tuple_element(result_tuple, 0, `ref`)
  term_put_tuple_element(result_tuple, 1, return_msg)
  send_message(pid, result_tuple, glb)

proc do_peername*(ctx: ptr Context; msg: term) {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var socket_data: ptr SocketData = ctx.platform_data
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  var `addr`: ip_addr_t
  var port: u16_t
  var result: err_t = netconn_peer(socket_data.conn, addr(`addr`), addr(port))
  var return_msg: term
  if result != ERR_OK:
    if UNLIKELY(memory_ensure_free(ctx, 3 + 3) != MEMORY_GC_OK):
      abort()
    return_msg = term_alloc_tuple(2, ctx)
    term_put_tuple_element(return_msg, 0, ERROR_ATOM)
    term_put_tuple_element(return_msg, 1, term_from_int(result))
  else:
    if UNLIKELY(memory_ensure_free(ctx, 3 + 8) != MEMORY_GC_OK):
      abort()
    return_msg = term_alloc_tuple(2, ctx)
    var addr_term: term = socket_addr_to_tuple(ctx, addr(`addr`))
    var port_term: term = term_from_int(port)
    term_put_tuple_element(return_msg, 0, addr_term)
    term_put_tuple_element(return_msg, 1, port_term)
  var result_tuple: term = term_alloc_tuple(2, ctx)
  term_put_tuple_element(result_tuple, 0, `ref`)
  term_put_tuple_element(result_tuple, 1, return_msg)
  send_message(pid, result_tuple, glb)

proc socket_consume_mailbox*(ctx: ptr Context) {.cdecl.} =
  while not list_is_empty(addr(ctx.mailbox)):
    var message: ptr Message = mailbox_dequeue(ctx)
    var msg: term = message.message
    TRACE("message: ")
    when defined(ENABLE_TRACE):
      term_display(stdout, msg, ctx)
    TRACE("\n")
    var cmd: term = term_get_tuple_element(msg, 2)
    var cmd_name: term = term_get_tuple_element(cmd, 0)
    case cmd_name              ## TODO: remove this
    of INIT_ATOM:
      TRACE("init\n")
      do_init(ctx, msg)
    of SENDTO_ATOM:
      TRACE("sendto\n")
      do_sendto(ctx, msg)
    of SEND_ATOM:
      TRACE("send\n")
      do_send(ctx, msg)
    of RECVFROM_ATOM:
      TRACE("recvfrom\n")
      do_recvfrom(ctx, msg)
    of RECV_ATOM:
      TRACE("recv\n")
      do_recvfrom(ctx, msg)
    of ACCEPT_ATOM:
      TRACE("accept\n")
      do_accept(ctx, msg)
    of CLOSE_ATOM:
      TRACE("close\n")
      do_close(ctx, msg)
    of GET_PORT_ATOM:
      fprintf(stderr, "get_port\n")
      do_get_port(ctx, msg)
    of SOCKNAME_ATOM:
      fprintf(stderr, "sockname\n")
      do_sockname(ctx, msg)
    of PEERNAME_ATOM:
      fprintf(stderr, "peername\n")
      do_peername(ctx, msg)
    else:
      TRACE("badarg\n")
    free(message)

proc socket_init*(ctx: ptr Context; opts: term) {.cdecl.} =
  UNUSED(opts)
  ctx.native_handler = socket_consume_mailbox
  ctx.platform_data = nil
