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
  SET_LEVEL_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 0)
  READ_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 1)
  INPUT_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 2)
  OUTPUT_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 3)
  SET_DIRECTION_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 4)
  SET_INT_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 5)
  GPIO_INTERRUPT_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 6)
  NONE_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 7)
  RISING_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 8)
  FALLING_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 9)
  BOTH_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 10)
  LOW_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 11)
  HIGH_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 12)
  ESP32_ATOM_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 13)
  SOCKET_ATOMS_BASE_INDEX* = (PLATFORM_ATOMS_BASE_INDEX + 14)
  PROTO_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 0)
  UDP_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 1)
  TCP_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 2)
  SOCKET_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 3)
  FCNTL_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 4)
  BIND_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 5)
  GETSOCKNAME_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 6)
  RECVFROM_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 7)
  SENDTO_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 8)
  ADDRESS_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 9)
  PORT_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 10)
  CONTROLLING_PROCESS_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 11)
  BINARY_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 12)
  ACTIVE_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 13)
  BUFFER_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 14)
  CONNECT_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 15)
  SEND_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 16)
  TCP_CLOSED_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 17)
  RECV_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 18)
  LISTEN_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 19)
  BACKLOG_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 20)
  ACCEPT_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 21)
  FD_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 22)
  INIT_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 23)
  CLOSE_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 24)
  GET_PORT_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 25)
  SOCKNAME_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 26)
  PEERNAME_ATOM_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 27)
  NETWORK_ATOMS_BASE_INDEX* = (SOCKET_ATOMS_BASE_INDEX + 28)
  STA_ATOM_INDEX* = (NETWORK_ATOMS_BASE_INDEX + 0)
  SSID_ATOM_INDEX* = (NETWORK_ATOMS_BASE_INDEX + 1)
  PSK_ATOM_INDEX* = (NETWORK_ATOMS_BASE_INDEX + 2)
  SNTP_ATOM_INDEX* = (NETWORK_ATOMS_BASE_INDEX + 3)
  STA_GOT_IP_ATOM_INDEX* = (NETWORK_ATOMS_BASE_INDEX + 4)
  STA_CONNECTED_ATOM_INDEX* = (NETWORK_ATOMS_BASE_INDEX + 5)
  STA_DISCONNECTED_ATOM_INDEX* = (NETWORK_ATOMS_BASE_INDEX + 6)
  SPIDRIVER_ATOMS_BASE_INDEX* = (NETWORK_ATOMS_BASE_INDEX + 7)
  BUS_CONFIG_ATOM_INDEX* = (SPIDRIVER_ATOMS_BASE_INDEX + 0)
  MISO_IO_NUM_ATOM_INDEX* = (SPIDRIVER_ATOMS_BASE_INDEX + 1)
  MOSI_IO_NUM_ATOM_INDEX* = (SPIDRIVER_ATOMS_BASE_INDEX + 2)
  SCLK_IO_NUM_ATOM_INDEX* = (SPIDRIVER_ATOMS_BASE_INDEX + 3)
  DEVICE_CONFIG_ATOM_INDEX* = (SPIDRIVER_ATOMS_BASE_INDEX + 4)
  SPI_CLOCK_HZ_ATOM_INDEX* = (SPIDRIVER_ATOMS_BASE_INDEX + 5)
  SPI_MODE_ATOM_INDEX* = (SPIDRIVER_ATOMS_BASE_INDEX + 6)
  SPI_CS_IO_NUM_ATOM_INDEX* = (SPIDRIVER_ATOMS_BASE_INDEX + 7)
  ADDRESS_LEN_BITS_ATOM_INDEX* = (SPIDRIVER_ATOMS_BASE_INDEX + 8)
  READ_AT_ATOM_INDEX* = (SPIDRIVER_ATOMS_BASE_INDEX + 9)
  WRITE_AT_ATOM_INDEX* = (SPIDRIVER_ATOMS_BASE_INDEX + 10)
  I2CDRIVER_ATOMS_BASE_INDEX* = (WRITE_AT_ATOM_INDEX + 1)
  BEGIN_TRANSMISSION_ATOM_INDEX* = (I2CDRIVER_ATOMS_BASE_INDEX + 0)
  END_TRANSMISSION_ATOM_INDEX* = (I2CDRIVER_ATOMS_BASE_INDEX + 1)
  WRITE_BYTE_ATOM_INDEX* = (I2CDRIVER_ATOMS_BASE_INDEX + 2)
  READ_BYTES_ATOM_INDEX* = (I2CDRIVER_ATOMS_BASE_INDEX + 3)
  SCL_IO_NUM_ATOM_INDEX* = (I2CDRIVER_ATOMS_BASE_INDEX + 4)
  SDA_IO_NUM_ATOM_INDEX* = (I2CDRIVER_ATOMS_BASE_INDEX + 5)
  I2C_CLOCK_HZ_ATOM_INDEX* = (I2CDRIVER_ATOMS_BASE_INDEX + 6)
  UART_ATOMS_BASE_INDEX* = (I2C_CLOCK_HZ_ATOM_INDEX + 1)
  NAME_ATOM_INDEX* = (UART_ATOMS_BASE_INDEX + 0)
  SPEED_ATOM_INDEX* = (UART_ATOMS_BASE_INDEX + 1)
  WRITE_ATOM_INDEX* = (UART_ATOMS_BASE_INDEX + 2)
  DATA_BITS_ATOM_INDEX* = (UART_ATOMS_BASE_INDEX + 3)
  STOP_BITS_ATOM_INDEX* = (UART_ATOMS_BASE_INDEX + 4)
  FLOW_CONTROL_ATOM_INDEX* = (UART_ATOMS_BASE_INDEX + 5)
  HARDWARE_ATOM_INDEX* = (UART_ATOMS_BASE_INDEX + 6)
  SOFTWARE_ATOM_INDEX* = (UART_ATOMS_BASE_INDEX + 7)
  PARITY_ATOM_INDEX* = (UART_ATOMS_BASE_INDEX + 8)
  EVEN_ATOM_INDEX* = (UART_ATOMS_BASE_INDEX + 9)
  ODD_ATOM_INDEX* = (UART_ATOMS_BASE_INDEX + 10)
  ADDRESS_ATOM* = term_from_atom_index(ADDRESS_ATOM_INDEX)
  PORT_ATOM* = term_from_atom_index(PORT_ATOM_INDEX)
  CONTROLLING_PROCESS_ATOM* = term_from_atom_index(CONTROLLING_PROCESS_ATOM_INDEX)
  BINARY_ATOM* = term_from_atom_index(BINARY_ATOM_INDEX)
  ACTIVE_ATOM* = term_from_atom_index(ACTIVE_ATOM_INDEX)
  BUFFER_ATOM* = term_from_atom_index(BUFFER_ATOM_INDEX)
  SET_LEVEL_ATOM* = TERM_FROM_ATOM_INDEX(SET_LEVEL_ATOM_INDEX)
  READ_ATOM* = TERM_FROM_ATOM_INDEX(READ_ATOM_INDEX)
  INPUT_ATOM* = TERM_FROM_ATOM_INDEX(INPUT_ATOM_INDEX)
  OUTPUT_ATOM* = TERM_FROM_ATOM_INDEX(OUTPUT_ATOM_INDEX)
  SET_DIRECTION_ATOM* = TERM_FROM_ATOM_INDEX(SET_DIRECTION_ATOM_INDEX)
  SET_INT_ATOM* = TERM_FROM_ATOM_INDEX(SET_INT_ATOM_INDEX)
  GPIO_INTERRUPT_ATOM* = TERM_FROM_ATOM_INDEX(GPIO_INTERRUPT_ATOM_INDEX)
  NONE_ATOM* = TERM_FROM_ATOM_INDEX(NONE_ATOM_INDEX)
  RISING_ATOM* = TERM_FROM_ATOM_INDEX(RISING_ATOM_INDEX)
  FALLING_ATOM* = TERM_FROM_ATOM_INDEX(FALLING_ATOM_INDEX)
  BOTH_ATOM* = TERM_FROM_ATOM_INDEX(BOTH_ATOM_INDEX)
  LOW_ATOM* = TERM_FROM_ATOM_INDEX(LOW_ATOM_INDEX)
  HIGH_ATOM* = TERM_FROM_ATOM_INDEX(HIGH_ATOM_INDEX)
  ESP32_ATOM* = TERM_FROM_ATOM_INDEX(ESP32_ATOM_INDEX)

##  socket

const
  PROTO_ATOM* = TERM_FROM_ATOM_INDEX(PROTO_ATOM_INDEX)
  UDP_ATOM* = TERM_FROM_ATOM_INDEX(UDP_ATOM_INDEX)
  TCP_ATOM* = TERM_FROM_ATOM_INDEX(TCP_ATOM_INDEX)
  SOCKET_ATOM* = TERM_FROM_ATOM_INDEX(SOCKET_ATOM_INDEX)
  FCNTL_ATOM* = TERM_FROM_ATOM_INDEX(FCNTL_ATOM_INDEX)
  BIND_ATOM* = TERM_FROM_ATOM_INDEX(BIND_ATOM_INDEX)
  GETSOCKNAME_ATOM* = TERM_FROM_ATOM_INDEX(GETSOCKNAME_ATOM_INDEX)
  RECVFROM_ATOM* = TERM_FROM_ATOM_INDEX(RECVFROM_ATOM_INDEX)
  SENDTO_ATOM* = TERM_FROM_ATOM_INDEX(SENDTO_ATOM_INDEX)
  ADDRESS_ATOM* = term_from_atom_index(ADDRESS_ATOM_INDEX)
  PORT_ATOM* = term_from_atom_index(PORT_ATOM_INDEX)
  CONTROLLING_PROCESS_ATOM* = term_from_atom_index(CONTROLLING_PROCESS_ATOM_INDEX)
  BINARY_ATOM* = term_from_atom_index(BINARY_ATOM_INDEX)
  ACTIVE_ATOM* = term_from_atom_index(ACTIVE_ATOM_INDEX)
  BUFFER_ATOM* = term_from_atom_index(BUFFER_ATOM_INDEX)
  CONNECT_ATOM* = term_from_atom_index(CONNECT_ATOM_INDEX)
  SEND_ATOM* = TERM_FROM_ATOM_INDEX(SEND_ATOM_INDEX)
  TCP_CLOSED_ATOM* = TERM_FROM_ATOM_INDEX(TCP_CLOSED_ATOM_INDEX)
  RECV_ATOM* = TERM_FROM_ATOM_INDEX(RECV_ATOM_INDEX)
  LISTEN_ATOM* = TERM_FROM_ATOM_INDEX(LISTEN_ATOM_INDEX)
  BACKLOG_ATOM* = TERM_FROM_ATOM_INDEX(BACKLOG_ATOM_INDEX)
  ACCEPT_ATOM* = TERM_FROM_ATOM_INDEX(ACCEPT_ATOM_INDEX)
  FD_ATOM* = TERM_FROM_ATOM_INDEX(FD_ATOM_INDEX)
  INIT_ATOM* = TERM_FROM_ATOM_INDEX(INIT_ATOM_INDEX)
  CLOSE_ATOM* = TERM_FROM_ATOM_INDEX(CLOSE_ATOM_INDEX)
  GET_PORT_ATOM* = TERM_FROM_ATOM_INDEX(GET_PORT_ATOM_INDEX)
  SOCKNAME_ATOM* = TERM_FROM_ATOM_INDEX(SOCKNAME_ATOM_INDEX)
  PEERNAME_ATOM* = TERM_FROM_ATOM_INDEX(PEERNAME_ATOM_INDEX)

##  network

const
  STA_ATOM* = TERM_FROM_ATOM_INDEX(STA_ATOM_INDEX)
  SSID_ATOM* = TERM_FROM_ATOM_INDEX(SSID_ATOM_INDEX)
  PSK_ATOM* = TERM_FROM_ATOM_INDEX(PSK_ATOM_INDEX)
  SNTP_ATOM* = TERM_FROM_ATOM_INDEX(SNTP_ATOM_INDEX)
  STA_GOT_IP_ATOM* = TERM_FROM_ATOM_INDEX(STA_GOT_IP_ATOM_INDEX)
  STA_CONNECTED_ATOM* = TERM_FROM_ATOM_INDEX(STA_CONNECTED_ATOM_INDEX)
  STA_DISCONNECTED_ATOM* = TERM_FROM_ATOM_INDEX(STA_DISCONNECTED_ATOM_INDEX)

## spidriver

const
  BUS_CONFIG_ATOM* = TERM_FROM_ATOM_INDEX(BUS_CONFIG_ATOM_INDEX)
  MISO_IO_NUM_ATOM* = TERM_FROM_ATOM_INDEX(MISO_IO_NUM_ATOM_INDEX)
  MOSI_IO_NUM_ATOM* = TERM_FROM_ATOM_INDEX(MOSI_IO_NUM_ATOM_INDEX)
  SCLK_IO_NUM_ATOM* = TERM_FROM_ATOM_INDEX(SCLK_IO_NUM_ATOM_INDEX)
  DEVICE_CONFIG_ATOM* = TERM_FROM_ATOM_INDEX(DEVICE_CONFIG_ATOM_INDEX)
  SPI_CLOCK_HZ_ATOM* = TERM_FROM_ATOM_INDEX(SPI_CLOCK_HZ_ATOM_INDEX)
  SPI_MODE_ATOM* = TERM_FROM_ATOM_INDEX(SPI_MODE_ATOM_INDEX)
  SPI_CS_IO_NUM_ATOM* = TERM_FROM_ATOM_INDEX(SPI_CS_IO_NUM_ATOM_INDEX)
  ADDRESS_LEN_BITS_ATOM* = TERM_FROM_ATOM_INDEX(ADDRESS_LEN_BITS_ATOM_INDEX)
  READ_AT_ATOM* = TERM_FROM_ATOM_INDEX(READ_AT_ATOM_INDEX)
  WRITE_AT_ATOM* = TERM_FROM_ATOM_INDEX(WRITE_AT_ATOM_INDEX)

## i2cdriver

const
  BEGIN_TRANSMISSION_ATOM* = TERM_FROM_ATOM_INDEX(BEGIN_TRANSMISSION_ATOM_INDEX)
  END_TRANSMISSION_ATOM* = TERM_FROM_ATOM_INDEX(END_TRANSMISSION_ATOM_INDEX)
  WRITE_BYTE_ATOM* = TERM_FROM_ATOM_INDEX(WRITE_BYTE_ATOM_INDEX)
  READ_BYTES_ATOM* = TERM_FROM_ATOM_INDEX(READ_BYTES_ATOM_INDEX)
  SCL_IO_NUM_ATOM* = TERM_FROM_ATOM_INDEX(SCL_IO_NUM_ATOM_INDEX)
  SDA_IO_NUM_ATOM* = TERM_FROM_ATOM_INDEX(SDA_IO_NUM_ATOM_INDEX)
  I2C_CLOCK_HZ_ATOM* = TERM_FROM_ATOM_INDEX(I2C_CLOCK_HZ_ATOM_INDEX)

## uart_driver

const
  NAME_ATOM* = TERM_FROM_ATOM_INDEX(NAME_ATOM_INDEX)
  SPEED_ATOM* = TERM_FROM_ATOM_INDEX(SPEED_ATOM_INDEX)
  WRITE_ATOM* = TERM_FROM_ATOM_INDEX(WRITE_ATOM_INDEX)
  DATA_BITS_ATOM* = TERM_FROM_ATOM_INDEX(DATA_BITS_ATOM_INDEX)
  STOP_BITS_ATOM* = TERM_FROM_ATOM_INDEX(STOP_BITS_ATOM_INDEX)
  FLOW_CONTROL_ATOM* = TERM_FROM_ATOM_INDEX(FLOW_CONTROL_ATOM_INDEX)
  HARDWARE_ATOM* = TERM_FROM_ATOM_INDEX(HARDWARE_ATOM_INDEX)
  SOFTWARE_ATOM* = TERM_FROM_ATOM_INDEX(SOFTWARE_ATOM_INDEX)
  PARITY_ATOM* = TERM_FROM_ATOM_INDEX(PARITY_ATOM_INDEX)
  EVEN_ATOM* = TERM_FROM_ATOM_INDEX(EVEN_ATOM_INDEX)
  ODD_ATOM* = TERM_FROM_ATOM_INDEX(ODD_ATOM_INDEX)
