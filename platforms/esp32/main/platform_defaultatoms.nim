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

var set_level_atom*: cstring = "\tset_level"

var read_atom*: cstring = "\x04read"

var input_atom*: cstring = "\x05input"

var output_atom*: cstring = "\x06output"

var set_direction_atom*: cstring = "\cset_direction"

var set_int_atom*: cstring = "\aset_int"

var gpio_interrupt_atom*: cstring = "\x0Egpio_interrupt"

var none_atom*: cstring = "\x04none"

var rising_atom*: cstring = "\x06rising"

var falling_atom*: cstring = "\afalling"

var both_atom*: cstring = "\x04both"

var low_atom*: cstring = "\x03low"

var high_atom*: cstring = "\x04high"

var esp32_atom*: cstring = "\x05esp32"

var proto_atom*: cstring = "\x05proto"

var udp_atom*: cstring = "\x03udp"

var tcp_atom*: cstring = "\x03tcp"

var socket_atom*: cstring = "\x06socket"

var fcntl_atom*: cstring = "\x05fcntl"

var bind_atom*: cstring = "\x04bind"

var getsockname_atom*: cstring = "\vgetsockname"

var recvfrom_atom*: cstring = "\brecvfrom"

var sendto_atom*: cstring = "\x06sendto"

var address_atom*: cstring = "\aaddress"

var port_atom*: cstring = "\x04port"

var controlling_process_atom*: cstring = "\x13controlling_process"

var binary_atom*: cstring = "\x06binary"

var active_atom*: cstring = "\x06active"

var buffer_atom*: cstring = "\x06buffer"

var connect_atom*: cstring = "\aconnect"

var send_atom*: cstring = "\x04send"

var tcp_closed_atom*: cstring = "\ntcp_closed"

var recv_atom*: cstring = "\x04recv"

var listen_atom*: cstring = "\x06listen"

var backlog_atom*: cstring = "\abacklog"

var accept_atom*: cstring = "\x06accept"

var fd_atom*: cstring = "\x02fd"

var init_atom*: cstring = "\x04init"

var close_atom*: cstring = "\x05close"

var get_port_atom*: cstring = "\bget_port"

var sockname_atom*: cstring = "\bsockname"

var peername_atom*: cstring = "\bpeername"

var sta_atom*: cstring = "\x03sta"

var ssid_atom*: cstring = "\x04ssid"

var psk_atom*: cstring = "\x03psk"

var sntp_atom*: cstring = "\x04sntp"

var sta_got_ip_atom*: cstring = "\nsta_got_ip"

var sta_connected_atom*: cstring = "\csta_connected"

var sta_disconnected_atom*: cstring = "\x10sta_disconnected"

## spidriver

var bus_config_atom*: cstring = "\nbus_config"

var miso_io_num_atom*: cstring = "\vmiso_io_num"

var mosi_io_num_atom*: cstring = "\vmosi_io_num"

var sclk_io_num_atom*: cstring = "\vsclk_io_num"

var device_config_atom*: cstring = "\cdevice_config"

var spi_clock_hz_atom*: cstring = "\fspi_clock_hz"

var spi_mode_atom*: cstring = "\bspi_mode"

var spi_cs_io_num_atom*: cstring = "\cspi_cs_io_num"

var address_len_bits_atom*: cstring = "\x10address_len_bits"

var read_at_atom*: cstring = "\aread_at"

var write_at_atom*: cstring = "\bwrite_at"

## i2cdriver

var begin_transmission_atom*: cstring = "\x12begin_transmission"

var end_transmission_atom*: cstring = "\x10end_transmission"

var write_byte_atom*: cstring = "\nwrite_byte"

var read_bytes_atom*: cstring = "\nread_bytes"

var scl_io_num_atom*: cstring = "\nscl_io_num"

var sda_io_num_atom*: cstring = "\nsda_io_num"

var i2c_clock_hz_atom*: cstring = "\fi2c_clock_hz"

## uart

var name_atom*: cstring = "\x04name"

var speed_atom*: cstring = "\x05speed"

var write_atom*: cstring = "\x05write"

var data_bits_atom*: cstring = "\tdata_bits"

var stop_bits_atom*: cstring = "\tstop_bits"

var flow_control_atom*: cstring = "\fflow_control"

var hardware_atom*: cstring = "\bhardware"

var software_atom*: cstring = "\bsoftware"

var parity_atom*: cstring = "\x06parity"

var even_atom*: cstring = "\x04even"

var odd_atom*: cstring = "\x03odd"

proc platform_defaultatoms_init*(glb: ptr GlobalContext) {.cdecl.} =
  var ok: cint = 1
  ok = ok and
      globalcontext_insert_atom(glb, set_level_atom) == SET_LEVEL_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, read_atom) == READ_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, input_atom) == INPUT_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, output_atom) == OUTPUT_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, set_direction_atom) ==
      SET_DIRECTION_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, set_int_atom) == SET_INT_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, gpio_interrupt_atom) ==
      GPIO_INTERRUPT_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, none_atom) == NONE_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, rising_atom) == RISING_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, falling_atom) == FALLING_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, both_atom) == BOTH_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, low_atom) == LOW_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, high_atom) == HIGH_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, esp32_atom) == ESP32_ATOM_INDEX
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
  ok = ok and globalcontext_insert_atom(glb, sendto_atom) == SENDTO_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, address_atom) == ADDRESS_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, port_atom) == PORT_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, controlling_process_atom) ==
      CONTROLLING_PROCESS_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, binary_atom) == BINARY_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, active_atom) == ACTIVE_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, buffer_atom) == BUFFER_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, connect_atom) == CONNECT_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, send_atom) == SEND_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, tcp_closed_atom) == TCP_CLOSED_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, recv_atom) == RECV_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, listen_atom) == LISTEN_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, backlog_atom) == BACKLOG_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, accept_atom) == ACCEPT_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, fd_atom) == FD_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, init_atom) == INIT_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, close_atom) == CLOSE_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, get_port_atom) == GET_PORT_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, sockname_atom) == SOCKNAME_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, peername_atom) == PEERNAME_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, sta_atom) == STA_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, ssid_atom) == SSID_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, psk_atom) == PSK_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, sntp_atom) == SNTP_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, sta_got_ip_atom) == STA_GOT_IP_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, sta_connected_atom) ==
      STA_CONNECTED_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, sta_disconnected_atom) ==
      STA_DISCONNECTED_ATOM_INDEX
  ## spidriver
  ok = ok and
      globalcontext_insert_atom(glb, bus_config_atom) == BUS_CONFIG_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, miso_io_num_atom) == MISO_IO_NUM_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, mosi_io_num_atom) == MOSI_IO_NUM_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, sclk_io_num_atom) == SCLK_IO_NUM_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, device_config_atom) ==
      DEVICE_CONFIG_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, spi_clock_hz_atom) ==
      SPI_CLOCK_HZ_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, spi_mode_atom) == SPI_MODE_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, spi_cs_io_num_atom) ==
      SPI_CS_IO_NUM_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, address_len_bits_atom) ==
      ADDRESS_LEN_BITS_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, read_at_atom) == READ_AT_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, write_at_atom) == WRITE_AT_ATOM_INDEX
  ## i2cdriver
  ok = ok and
      globalcontext_insert_atom(glb, begin_transmission_atom) ==
      BEGIN_TRANSMISSION_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, end_transmission_atom) ==
      END_TRANSMISSION_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, write_byte_atom) == WRITE_BYTE_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, read_bytes_atom) == READ_BYTES_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, scl_io_num_atom) == SCL_IO_NUM_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, sda_io_num_atom) == SDA_IO_NUM_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, i2c_clock_hz_atom) ==
      I2C_CLOCK_HZ_ATOM_INDEX
  ## uart
  ok = ok and globalcontext_insert_atom(glb, name_atom) == NAME_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, speed_atom) == SPEED_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, write_atom) == WRITE_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, data_bits_atom) == DATA_BITS_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, stop_bits_atom) == STOP_BITS_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, flow_control_atom) ==
      FLOW_CONTROL_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, hardware_atom) == HARDWARE_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, software_atom) == SOFTWARE_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, parity_atom) == PARITY_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, even_atom) == EVEN_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, odd_atom) == ODD_ATOM_INDEX
  if not ok:
    abort()
