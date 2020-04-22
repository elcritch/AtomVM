## **************************************************************************
##    Copyright 2018 by Riccardo Binetti <rbino@gmx.com>                    *
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
  gpiodriver, platform_defaultatoms

proc consume_gpio_mailbox*(ctx: ptr Context) {.cdecl.}
proc port_atom_to_gpio_port*(ctx: ptr Context; port_atom: term): uint32_t {.cdecl.}
proc gpio_port_to_rcc_port*(gpio_port: uint32_t): uint16_t {.cdecl.}
proc gpio_port_to_name*(gpio_port: uint32_t): char {.cdecl.}
proc gpiodriver_init*(ctx: ptr Context) =
  ctx.native_handler = consume_gpio_mailbox
  ctx.platform_data = nil

proc consume_gpio_mailbox*(ctx: ptr Context) =
  var ret: term
  var message: ptr Message = mailbox_dequeue(ctx)
  var msg: term = message.message
  var pid: term = term_get_tuple_element(msg, 0)
  var cmd: term = term_get_tuple_element(msg, 1)
  var local_process_id: cint = term_to_local_process_id(pid)
  var target: ptr Context = globalcontext_get_process(ctx.global, local_process_id)
  if cmd == SET_LEVEL_ATOM:
    var gpio_tuple: term = term_get_tuple_element(msg, 2)
    var gpio_port_atom: term = term_get_tuple_element(gpio_tuple, 0)
    var gpio_port: uint32_t = port_atom_to_gpio_port(ctx, gpio_port_atom)
    var gpio_pin_num: int32_t = term_to_int32(term_get_tuple_element(gpio_tuple, 1))
    var level: int32_t = term_to_int32(term_get_tuple_element(msg, 3))
    if level != 0:
      gpio_set(gpio_port, 1 shl gpio_pin_num)
    else:
      gpio_clear(gpio_port, 1 shl gpio_pin_num)
    TRACE("gpio: set_level: %c%i %i\n", gpio_port_to_name(gpio_port),
          gpio_pin_num, level != 0)
    ret = OK_ATOM
  elif cmd == SET_DIRECTION_ATOM:
    var gpio_tuple: term = term_get_tuple_element(msg, 2)
    var gpio_port_atom: term = term_get_tuple_element(gpio_tuple, 0)
    var gpio_port: uint32_t = port_atom_to_gpio_port(ctx, gpio_port_atom)
    var gpio_pin_num: int32_t = term_to_int32(term_get_tuple_element(gpio_tuple, 1))
    var direction: term = term_get_tuple_element(msg, 3)
    var rcc_port: uint16_t = gpio_port_to_rcc_port(gpio_port)
    ##  Set direction implicitly enables the port of the GPIO
    rcc_periph_clock_enable(rcc_port)
    if direction == INPUT_ATOM:
      gpio_mode_setup(gpio_port, GPIO_MODE_INPUT, GPIO_PUPD_NONE,
                      1 shl gpio_pin_num)
      TRACE("gpio: set_direction: %c%i INPUT\n", gpio_port_to_name(gpio_port),
            gpio_pin_num)
      ret = OK_ATOM
    elif direction == OUTPUT_ATOM:
      gpio_mode_setup(gpio_port, GPIO_MODE_OUTPUT, GPIO_PUPD_NONE,
                      1 shl gpio_pin_num)
      TRACE("gpio: set_direction: %c%i OUTPUT\n", gpio_port_to_name(gpio_port),
            gpio_pin_num)
      ret = OK_ATOM
    else:
      TRACE("gpio: unrecognized direction\n")
      ret = ERROR_ATOM
  else:
    TRACE("gpio: unrecognized command\n")
    ret = ERROR_ATOM
  free(message)
  mailbox_send(target, ret)

proc port_atom_to_gpio_port*(ctx: ptr Context; port_atom: term): uint32_t =
  if port_atom == A_ATOM:
    return GPIOA
  elif port_atom == B_ATOM:
    return GPIOB
  elif port_atom == C_ATOM:
    return GPIOC
  elif port_atom == D_ATOM:
    return GPIOD
  elif port_atom == E_ATOM:
    return GPIOE
  elif port_atom == F_ATOM:
    return GPIOF
  else:
    return 0

proc gpio_port_to_rcc_port*(gpio_port: uint32_t): uint16_t =
  case gpio_port
  of GPIOA:
    return RCC_GPIOA
  of GPIOB:
    return RCC_GPIOB
  of GPIOC:
    return RCC_GPIOC
  of GPIOD:
    return RCC_GPIOD
  of GPIOE:
    return RCC_GPIOE
  of GPIOF:
    return RCC_GPIOF
  else:
    return 0

proc gpio_port_to_name*(gpio_port: uint32_t): char =
  case gpio_port
  of GPIOA:
    return 'A'
  of GPIOB:
    return 'B'
  of GPIOC:
    return 'C'
  of GPIOD:
    return 'D'
  of GPIOE:
    return 'E'
  of GPIOF:
    return 'F'
  else:
    return 0
