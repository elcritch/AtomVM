## **************************************************************************
##    Copyright 2020 by Davide Bettio <davide@uninstall.it>                 *
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
  uart_driver, atom, bif, context, debug, defaultatoms, platform_defaultatoms,
  globalcontext, interop, mailbox, module, utils, term, trace, sys, esp32_sys

var ealready_atom*: cstring = "\bealready"

proc uart_driver_consume_mailbox*(ctx: ptr Context) {.cdecl.}
const
  UART_BUF_SIZE* = 256

type
  UARTData* {.bycopy.} = object
    rxqueue*: xQueueHandle
    listener*: EventListener
    reader_process_pid*: term
    reader_ref_ticks*: uint64_t
    ctx*: ptr Context
    uart_num*: uint8_t


##  TODO: FIXME
##  static void IRAM_ATTR uart_isr_handler(void *arg)

proc uart_isr_handler*(arg: pointer) {.cdecl.} =
  var rxfifo_len: uint16_t
  var interrupt_status: uint16_t
  interrupt_status = UART0.int_st.val
  UNUSED(interrupt_status)
  rxfifo_len = UART0.status.rxfifo_cnt
  var uart_data: ptr UARTData = arg
  while rxfifo_len:
    var c: uint8_t
    c = UART0.fifo.rw_byte
    xQueueSendFromISR(uart_data.rxqueue, addr(c), nil)
    dec(rxfifo_len)
  uart_clear_intr_status(uart_data.uart_num,
                         UART_RXFIFO_FULL_INT_CLR or UART_RXFIFO_TOUT_INT_CLR)
  xQueueSendFromISR(event_queue, addr(arg), nil)

proc send_message*(pid: term; message: term; global: ptr GlobalContext) {.cdecl.} =
  var local_process_id: cint = term_to_local_process_id(pid)
  var target: ptr Context = globalcontext_get_process(global, local_process_id)
  if LIKELY(target):
    mailbox_send(target, message)

proc uart_interrupt_callback*(listener: ptr EventListener) {.cdecl.} =
  var uart_data: ptr UARTData = listener.data
  if uart_data.reader_process_pid != term_invalid_term():
    var count: cuint = uxQueueMessagesWaiting(uart_data.rxqueue)
    if count == 0:
      return
    var ref_size: cint = (sizeof((uint64_t) div sizeof((term)))) + 1
    var bin_size: cint = term_binary_data_size_in_terms(count) + BINARY_HEADER_SIZE +
        ref_size
    if UNLIKELY(memory_ensure_free(uart_data.ctx, bin_size + ref_size + 3 + 3) !=
        MEMORY_GC_OK):
      abort()
    var bin: term = term_create_uninitialized_binary(count, uart_data.ctx)
    var bin_buf: ptr uint8_t = cast[ptr uint8_t](term_binary_data(bin))
    var i: cuint = 0
    while i < count:
      var c: uint8_t
      if xQueueReceive(uart_data.rxqueue, addr(c), 1) == pdTRUE:
        bin_buf[i] = c
      else:
        ##  it shouldn't happen
        ##  TODO: log bug?
        return
      inc(i)
    var ctx: ptr Context = uart_data.ctx
    var ok_tuple: term = term_alloc_tuple(2, ctx)
    term_put_tuple_element(ok_tuple, 0, OK_ATOM)
    term_put_tuple_element(ok_tuple, 1, bin)
    var `ref`: term = term_from_ref_ticks(uart_data.reader_ref_ticks, ctx)
    var result_tuple: term = term_alloc_tuple(2, ctx)
    term_put_tuple_element(result_tuple, 0, `ref`)
    term_put_tuple_element(result_tuple, 1, ok_tuple)
    send_message(uart_data.reader_process_pid, result_tuple, ctx.global)
    uart_data.reader_process_pid = term_invalid_term()
    uart_data.reader_ref_ticks = 0

proc uart_driver_init*(ctx: ptr Context; opts: term) {.cdecl.} =
  var uart_name_term: term = interop_proplist_get_value(opts, NAME_ATOM)
  var uart_speed_term: term = interop_proplist_get_value_default(opts, SPEED_ATOM,
      term_from_int(115200))
  var data_bits_term: term = interop_proplist_get_value_default(opts, DATA_BITS_ATOM,
      term_from_int(8))
  var stop_bits_term: term = interop_proplist_get_value_default(opts, STOP_BITS_ATOM,
      term_from_int(1))
  var flow_control_term: term = interop_proplist_get_value_default(opts,
      FLOW_CONTROL_ATOM, NONE_ATOM)
  var parity_term: term = interop_proplist_get_value_default(opts, PARITY_ATOM,
      NONE_ATOM)
  var ok: cint
  var uart_name: cstring = interop_term_to_string(uart_name_term, addr(ok))
  if not uart_name or not ok:
    abort()
  var uart_num: uint8_t
  if not strcmp(uart_name, "UART0"):
    uart_num = UART_NUM_0
  elif not strcmp(uart_name, "UART1"):
    uart_num = UART_NUM_1
  elif not strcmp(uart_name, "UART2"):
    uart_num = UART_NUM_2
  else:
    abort()
  free(uart_name)
  var uart_speed: avm_int_t = term_to_int(uart_speed_term)
  var data_bits: cint
  case term_to_int(data_bits_term)
  of 8:
    data_bits = UART_DATA_8_BITS
  of 7:
    data_bits = UART_DATA_7_BITS
  of 6:
    data_bits = UART_DATA_6_BITS
  of 5:
    data_bits = UART_DATA_5_BITS
  else:
    abort()
  var stop_bits: cint
  case term_to_int(stop_bits_term)
  of 1:
    stop_bits = UART_STOP_BITS_1
  of 2:
    stop_bits = UART_STOP_BITS_2
  else:
    abort()
  var flow_control: cint
  case flow_control_term
  of NONE_ATOM:
    flow_control = UART_HW_FLOWCTRL_DISABLE
  of HARDWARE_ATOM:
    flow_control = UART_HW_FLOWCTRL_CTS_RTS
  of SOFTWARE_ATOM:
    nil
  else:
    abort()
  var parity: cint
  case parity_term
  of NONE_ATOM:
    parity = UART_PARITY_DISABLE
  of EVEN_ATOM:
    parity = UART_PARITY_EVEN
  of ODD_ATOM:
    parity = UART_PARITY_ODD
  else:
    abort()
  var uart_config: uart_config_t
  uart_config.baud_rate = uart_speed
  uart_config.data_bits = data_bits
  uart_config.parity = parity
  uart_config.stop_bits = stop_bits
  uart_config.flow_ctrl = flow_control
  uart_param_config(uart_num, addr(uart_config))
  uart_driver_install(uart_num, UART_BUF_SIZE, 0, 0, nil, 0)
  var glb: ptr GlobalContext = ctx.global
  var platform: ptr ESP32PlatformData = glb.platform_data
  var uart_data: ptr UARTData = malloc(sizeof(UARTData))
  if IS_NULL_PTR(uart_data):
    fprintf(stderr, "Failed to allocate memory: %s:%i.\n", __FILE__, __LINE__)
    abort()
  uart_data.listener.sender = uart_data
  uart_data.listener.data = uart_data
  uart_data.listener.handler = uart_interrupt_callback
  list_append(addr(platform.listeners),
              addr(uart_data.listener.listeners_list_head))
  uart_data.rxqueue = xQueueCreate(UART_BUF_SIZE, sizeof((uint8_t)))
  uart_data.reader_process_pid = term_invalid_term()
  uart_data.reader_ref_ticks = 0
  uart_data.ctx = ctx
  uart_data.uart_num = uart_num
  ctx.native_handler = uart_driver_consume_mailbox
  ctx.platform_data = uart_data
  uart_isr_free(uart_num)
  var isr_handle: uart_isr_handle_t
  uart_isr_register(uart_num, uart_isr_handler, uart_data, ESP_INTR_FLAG_IRAM,
                    addr(isr_handle))
  uart_enable_rx_intr(uart_num)

proc uart_driver_do_read*(ctx: ptr Context; msg: term) {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var uart_data: ptr UARTData = ctx.platform_data
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  if uart_data.reader_process_pid != term_invalid_term():
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
    return
  var count: cuint = uxQueueMessagesWaiting(uart_data.rxqueue)
  if count > 0:
    var bin_size: cint = term_binary_data_size_in_terms(count) + BINARY_HEADER_SIZE
    if UNLIKELY(memory_ensure_free(uart_data.ctx, bin_size + 3 + 3) != MEMORY_GC_OK):
      abort()
    var bin: term = term_create_uninitialized_binary(count, uart_data.ctx)
    var bin_buf: ptr uint8_t = cast[ptr uint8_t](term_binary_data(bin))
    var i: cuint = 0
    while i < count:
      var c: uint8_t
      if LIKELY(xQueueReceive(uart_data.rxqueue, addr(c), 1) == pdTRUE):
        bin_buf[i] = c
      else:
        ##  it shouldn't happen
        ##  TODO: log bug?
        return
      inc(i)
    var ok_tuple: term = term_alloc_tuple(2, ctx)
    term_put_tuple_element(ok_tuple, 0, OK_ATOM)
    term_put_tuple_element(ok_tuple, 1, bin)
    var result_tuple: term = term_alloc_tuple(2, ctx)
    term_put_tuple_element(result_tuple, 0, `ref`)
    term_put_tuple_element(result_tuple, 1, ok_tuple)
    send_message(pid, result_tuple, uart_data.ctx.global)
  else:
    uart_data.reader_process_pid = pid
    uart_data.reader_ref_ticks = term_to_ref_ticks(`ref`)

proc uart_driver_do_write*(ctx: ptr Context; msg: term) {.cdecl.} =
  var glb: ptr GlobalContext = ctx.global
  var uart_data: ptr UARTData = ctx.platform_data
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  var cmd: term = term_get_tuple_element(msg, 2)
  var data: term = term_get_tuple_element(cmd, 1)
  var ok: cint
  var buffer_size: cint = interop_iolist_size(data, addr(ok))
  var buffer: pointer = malloc(buffer_size)
  interop_write_iolist(data, buffer)
  uart_write_bytes(uart_data.uart_num, buffer, buffer_size)
  free(buffer)
  if UNLIKELY(memory_ensure_free(ctx, 3) != MEMORY_GC_OK):
    abort()
  var result_tuple: term = term_alloc_tuple(2, ctx)
  term_put_tuple_element(result_tuple, 0, `ref`)
  term_put_tuple_element(result_tuple, 1, OK_ATOM)
  send_message(pid, result_tuple, glb)

proc uart_driver_consume_mailbox*(ctx: ptr Context) {.cdecl.} =
  while not list_is_empty(addr(ctx.mailbox)):
    var message: ptr Message = mailbox_dequeue(ctx)
    var msg: term = message.message
    var req: term = term_get_tuple_element(msg, 2)
    var cmd: term = if term_is_atom(req): req else: term_get_tuple_element(req, 0)
    case cmd
    of READ_ATOM:
      TRACE("read\n")
      uart_driver_do_read(ctx, msg)
    of WRITE_ATOM:
      TRACE("write\n")
      uart_driver_do_write(ctx, msg)
    else:
      TRACE("uart: error: unrecognized command.\n")
    free(message)
