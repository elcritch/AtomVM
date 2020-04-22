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
  i2cdriver, atom, bif, context, debug, defaultatoms, platform_defaultatoms,
  globalcontext, interop, mailbox, module, utils, term, trace, sys, esp32_sys

proc i2cdriver_begin_transmission*(ctx: ptr Context; pid: term; req: term): term {.cdecl.}
proc i2cdriver_end_transmission*(ctx: ptr Context; pid: term): term {.cdecl.}
proc i2cdriver_write_byte*(ctx: ptr Context; pid: term; req: term): term {.cdecl.}
proc i2cdriver_consume_mailbox*(ctx: ptr Context) {.cdecl.}
type
  I2CData* = object
    cmd*: i2c_cmd_handle_t
    transmitting_pid*: term


proc i2cdriver_init*(ctx: ptr Context; opts: term) {.cdecl.} =
  var i2c_data: ptr I2CData = calloc(1, sizeof(I2CData))
  i2c_data.transmitting_pid = term_invalid_term()
  ctx.native_handler = i2cdriver_consume_mailbox
  ctx.platform_data = i2c_data
  var scl_io_num_term: term = interop_proplist_get_value(opts, SCL_IO_NUM_ATOM)
  var sda_io_num_term: term = interop_proplist_get_value(opts, SDA_IO_NUM_ATOM)
  var clock_hz_term: term = interop_proplist_get_value(opts, I2C_CLOCK_HZ_ATOM)
  var conf: i2c_config_t
  memset(addr(conf), 0, sizeof((i2c_config_t)))
  conf.mode = I2C_MODE_MASTER
  conf.scl_io_num = term_to_int32(scl_io_num_term)
  conf.sda_io_num = term_to_int32(sda_io_num_term)
  conf.sda_pullup_en = GPIO_PULLUP_ENABLE
  conf.scl_pullup_en = GPIO_PULLUP_ENABLE
  conf.master.clk_speed = term_to_int32(clock_hz_term)
  var ret: esp_err_t = i2c_param_config(I2C_NUM_0, addr(conf))
  if UNLIKELY(ret != ESP_OK):
    TRACE("i2cdriver: failed config, return value: %i\n", ret)
    ## TODO: return error
    return
  ret = i2c_driver_install(I2C_NUM_0, I2C_MODE_MASTER, 0, 0, 0)
  if UNLIKELY(ret != ESP_OK):
    TRACE("i2cdriver: failed install, return vale: %i\n", ret)
    ## TODO: return error

proc i2cdriver_begin_transmission*(ctx: ptr Context; pid: term; req: term): term {.cdecl.} =
  var i2c_data: ptr I2CData = ctx.platform_data
  if UNLIKELY(i2c_data.transmitting_pid != term_invalid_term()):
    ##  another process is already transmitting
    return ERROR_ATOM
  var address_term: term = term_get_tuple_element(req, 1)
  var address: uint8_t = term_to_int32(address_term)
  i2c_data.cmd = i2c_cmd_link_create()
  i2c_master_start(i2c_data.cmd)
  i2c_master_write_byte(i2c_data.cmd, (address shl 1) or I2C_MASTER_WRITE, true)
  i2c_data.transmitting_pid = pid
  return OK_ATOM

proc i2cdriver_end_transmission*(ctx: ptr Context; pid: term): term {.cdecl.} =
  var i2c_data: ptr I2CData = ctx.platform_data
  if UNLIKELY(i2c_data.transmitting_pid != pid):
    ##  transaction owned from a different pid
    return ERROR_ATOM
  i2c_master_stop(i2c_data.cmd)
  var result: esp_err_t = i2c_master_cmd_begin(I2C_NUM_0, i2c_data.cmd, portMAX_DELAY)
  i2c_cmd_link_delete(i2c_data.cmd)
  i2c_data.transmitting_pid = term_invalid_term()
  if UNLIKELY(result != ESP_OK):
    TRACE("i2cdriver end_transmission error: result was: %i.\n", result)
    return ERROR_ATOM
  return OK_ATOM

proc i2cdriver_write_byte*(ctx: ptr Context; pid: term; req: term): term {.cdecl.} =
  var i2c_data: ptr I2CData = ctx.platform_data
  if UNLIKELY(i2c_data.transmitting_pid != pid):
    ##  transaction owned from a different pid
    return ERROR_ATOM
  var data_term: term = term_get_tuple_element(req, 1)
  var data: uint8_t = term_to_int32(data_term)
  var result: esp_err_t = i2c_master_write_byte(i2c_data.cmd, cast[uint8_t](data),
      true)
  if UNLIKELY(result != ESP_OK):
    TRACE("i2cdriver write_byte error: result was: %i.\n", result)
    return ERROR_ATOM
  return OK_ATOM

proc i2cdriver_read_bytes*(ctx: ptr Context; pid: term; req: term): term {.cdecl.} =
  var i2c_data: ptr I2CData = ctx.platform_data
  if UNLIKELY(i2c_data.transmitting_pid != term_invalid_term()):
    ##  another process is already transmitting
    return ERROR_ATOM
  var address_term: term = term_get_tuple_element(req, 1)
  var address: uint8_t = term_to_int32(address_term)
  var read_bytes_term: term = term_get_tuple_element(req, 2)
  var read_count: avm_int_t = term_to_int32(read_bytes_term)
  if UNLIKELY(memory_ensure_free(ctx, BOXED_INT_SIZE) != MEMORY_GC_OK):
    return ERROR_ATOM
  var data_term: term = term_create_uninitialized_binary(read_count, ctx)
  var data: ptr uint8_t = cast[ptr uint8_t](term_binary_data(data_term))
  i2c_data.cmd = i2c_cmd_link_create()
  i2c_master_start(i2c_data.cmd)
  var result: esp_err_t = i2c_master_write_byte(i2c_data.cmd,
      (address shl 1) or I2C_MASTER_READ, true)
  if UNLIKELY(result != ESP_OK):
    TRACE("i2cdriver read_bytes error: result was: %i.\n", result)
    return ERROR_ATOM
  result = i2c_master_read(i2c_data.cmd, data, read_count, I2C_MASTER_LAST_NACK)
  if UNLIKELY(result != ESP_OK):
    TRACE("i2cdriver read_bytes error: result was: %i.\n", result)
    return ERROR_ATOM
  i2c_master_stop(i2c_data.cmd)
  result = i2c_master_cmd_begin(I2C_NUM_0, i2c_data.cmd, portMAX_DELAY)
  i2c_cmd_link_delete(i2c_data.cmd)
  i2c_data.transmitting_pid = term_invalid_term()
  if UNLIKELY(result != ESP_OK):
    TRACE("i2cdriver write_byte error: result was: %i.\n", result)
    return ERROR_ATOM
  return data_term

proc i2cdriver_consume_mailbox*(ctx: ptr Context) {.cdecl.} =
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
  of BEGIN_TRANSMISSION_ATOM:
    ret = i2cdriver_begin_transmission(ctx, pid, req)
  of END_TRANSMISSION_ATOM:
    ret = i2cdriver_end_transmission(ctx, pid)
  of WRITE_BYTE_ATOM:
    ret = i2cdriver_write_byte(ctx, pid, req)
  of READ_BYTES_ATOM:
    ret = i2cdriver_read_bytes(ctx, pid, req)
  else:
    TRACE("i2c: error: unrecognized command: %lx\n", cmd)
    ret = ERROR_ATOM
  free(message)
  UNUSED(`ref`)
  mailbox_send(target, ret)
