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
  spidriver, atom, bif, context, debug, defaultatoms, platform_defaultatoms,
  globalcontext, interop, mailbox, module, utils, term, trace, sys, esp32_sys

proc spidriver_consume_mailbox*(ctx: ptr Context) {.cdecl.}
proc spidriver_transfer_at*(ctx: ptr Context; address: uint64_t; data_len: cint;
                           data: uint32_t; ok: ptr bool): uint32_t {.cdecl.}
type
  SPIData* = object
    handle*: spi_device_handle_t
    transaction*: spi_transaction_t


proc spidriver_init*(ctx: ptr Context; opts: term) {.cdecl.} =
  var spi_data: ptr SPIData = calloc(1, sizeof(SPIData))
  ctx.native_handler = spidriver_consume_mailbox
  ctx.platform_data = spi_data
  var bus_config: term = interop_proplist_get_value(opts, BUS_CONFIG_ATOM)
  var miso_io_num_term: term = interop_proplist_get_value(bus_config,
      MISO_IO_NUM_ATOM)
  var mosi_io_num_term: term = interop_proplist_get_value(bus_config,
      MOSI_IO_NUM_ATOM)
  var sclk_io_num_term: term = interop_proplist_get_value(bus_config,
      SCLK_IO_NUM_ATOM)
  var buscfg: spi_bus_config_t
  memset(addr(buscfg), 0, sizeof((spi_bus_config_t)))
  buscfg.miso_io_num = term_to_int32(miso_io_num_term)
  buscfg.mosi_io_num = term_to_int32(mosi_io_num_term)
  buscfg.sclk_io_num = term_to_int32(sclk_io_num_term)
  buscfg.quadwp_io_num = -1
  buscfg.quadhd_io_num = -1
  var device_config: term = interop_proplist_get_value(opts, DEVICE_CONFIG_ATOM)
  var clock_speed_hz_term: term = interop_proplist_get_value(device_config,
      SPI_CLOCK_HZ_ATOM)
  var mode_term: term = interop_proplist_get_value(device_config, SPI_MODE_ATOM)
  var spics_io_num_term: term = interop_proplist_get_value(device_config,
      SPI_CS_IO_NUM_ATOM)
  var address_bits_term: term = interop_proplist_get_value(device_config,
      ADDRESS_LEN_BITS_ATOM)
  var devcfg: spi_device_interface_config_t
  memset(addr(devcfg), 0, sizeof((spi_device_interface_config_t)))
  devcfg.clock_speed_hz = term_to_int32(clock_speed_hz_term)
  devcfg.mode = term_to_int32(mode_term)
  devcfg.spics_io_num = term_to_int32(spics_io_num_term)
  devcfg.queue_size = 4
  devcfg.address_bits = term_to_int32(address_bits_term)
  var ret: cint = spi_bus_initialize(HSPI_HOST, addr(buscfg), 1)
  if ret == ESP_OK:
    TRACE("initialized SPI\n")
  else:
    TRACE("spi_bus_initialize return code: %i\n", ret)
  ret = spi_bus_add_device(HSPI_HOST, addr(devcfg), addr(spi_data.handle))
  if ret == ESP_OK:
    TRACE("initialized SPI device\n")
  else:
    TRACE("spi_bus_add_device return code: %i\n", ret)

proc spidriver_transfer_at*(ctx: ptr Context; address: uint64_t; data_len: cint;
                           data: uint32_t; ok: ptr bool): uint32_t {.cdecl.} =
  TRACE("--- SPI transfer ---\n")
  TRACE("spi: address: %x, tx: %x\n", cast[cint](address), cast[cint](data))
  var spi_data: ptr SPIData = ctx.platform_data
  memset(addr(spi_data.transaction), 0, sizeof((spi_transaction_t)))
  var tx_data: uint32_t = SPI_SWAP_DATA_TX(data, data_len)
  spi_data.transaction.flags = SPI_TRANS_USE_TXDATA or SPI_TRANS_USE_RXDATA
  spi_data.transaction.length = data_len
  spi_data.transaction.`addr` = address
  spi_data.transaction.tx_data[0] = tx_data
  spi_data.transaction.tx_data[1] = (tx_data shr 8) and 0x000000FF
  spi_data.transaction.tx_data[2] = (tx_data shr 16) and 0x000000FF
  spi_data.transaction.tx_data[3] = (tx_data shr 24) and 0x000000FF
  ## TODO: int ret = spi_device_queue_trans(spi_data->handle, &spi_data->transaction, portMAX_DELAY);
  var ret: cint = spi_device_polling_transmit(spi_data.handle,
      addr(spi_data.transaction))
  if UNLIKELY(ret != ESP_OK):
    ok[] = false
    return 0
  var rx_data: uint32_t = (cast[uint32_t](spi_data.transaction.rx_data[0])) or
      (cast[uint32_t](spi_data.transaction.rx_data[1]) shl 8) or
      (cast[uint32_t](spi_data.transaction.rx_data[2]) shl 16) or
      (cast[uint32_t](spi_data.transaction.rx_data[3]) shl 24)
  TRACE("spi: ret: %x\n", cast[cint](ret))
  TRACE("spi: rx: %x\n", cast[cint](rx_data))
  TRACE("--- end of transfer ---\n")
  ok[] = true
  return SPI_SWAP_DATA_RX(rx_data, data_len)

proc make_read_result_tuple*(read_value: uint32_t; ctx: ptr Context): term {.inline,
    cdecl.} =
  var boxed: bool
  var required: cint
  if read_value > MAX_NOT_BOXED_INT:
    boxed = true
    required = 3 + BOXED_INT_SIZE
  else:
    boxed = false
    required = 3
  if UNLIKELY(memory_ensure_free(ctx, required) != MEMORY_GC_OK):
    return ERROR_ATOM
  var read_value_term: term = if boxed: term_make_boxed_int(read_value, ctx) else: term_from_int(
      read_value)
  var result_tuple: term = term_alloc_tuple(2, ctx)
  term_put_tuple_element(result_tuple, 0, OK_ATOM)
  term_put_tuple_element(result_tuple, 1, read_value_term)
  return result_tuple

proc spidriver_read_at*(ctx: ptr Context; req: term): term {.cdecl.} =
  ## cmd is at index 0
  var address_term: term = term_get_tuple_element(req, 1)
  var len_term: term = term_get_tuple_element(req, 2)
  var address: avm_int64_t = term_maybe_unbox_int64(address_term)
  var data_len: avm_int_t = term_to_int(len_term)
  var ok: bool
  var read_value: uint32_t = spidriver_transfer_at(ctx, address, data_len, 0, addr(ok))
  if UNLIKELY(not ok):
    return ERROR_ATOM
  return make_read_result_tuple(read_value, ctx)

proc spidriver_write_at*(ctx: ptr Context; req: term): term {.cdecl.} =
  ## cmd is at index 0
  var address_term: term = term_get_tuple_element(req, 1)
  var len_term: term = term_get_tuple_element(req, 2)
  var data_term: term = term_get_tuple_element(req, 3)
  var address: uint64_t = term_maybe_unbox_int64(address_term)
  var data_len: avm_int_t = term_to_int(len_term)
  var data: avm_int_t = term_maybe_unbox_int(data_term)
  var ok: bool
  var read_value: uint32_t = spidriver_transfer_at(ctx, address, data_len, data,
      addr(ok))
  if UNLIKELY(not ok):
    return ERROR_ATOM
  return make_read_result_tuple(read_value, ctx)

proc spidriver_consume_mailbox*(ctx: ptr Context) {.cdecl.} =
  var message: ptr Message = mailbox_dequeue(ctx)
  var msg: term = message.message
  var pid: term = term_get_tuple_element(msg, 0)
  var `ref`: term = term_get_tuple_element(msg, 1)
  var req: term = term_get_tuple_element(msg, 2)
  var cmd: term = term_get_tuple_element(req, 0)
  var local_process_id: cint = term_to_local_process_id(pid)
  var target: ptr Context = globalcontext_get_process(ctx.global, local_process_id)
  var ret: term
  case cmd
  of READ_AT_ATOM:
    TRACE("spi: read at.\n")
    ret = spidriver_read_at(ctx, req)
  of WRITE_AT_ATOM:
    TRACE("spi: write at.\n")
    ret = spidriver_write_at(ctx, req)
  else:
    TRACE("spi: error: unrecognized command.\n")
    ret = ERROR_ATOM
  free(message)
  UNUSED(`ref`)
  mailbox_send(target, ret)
