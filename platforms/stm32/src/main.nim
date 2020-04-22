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

const
  USART_CONSOLE* = USART2
  AVM_ADDRESS* = (0x08080000)
  AVM_FLASH_MAX_SIZE* = (0x00080000)
  CLOCK_FREQUENCY* = (168000000)

proc _write*(file: cint; `ptr`: cstring; len: cint): cint {.cdecl.}
proc clock_setup*() =
  ##  Use external clock, set divider for 168 MHz clock frequency
  rcc_clock_setup_hse_3v3(addr(rcc_hse_8mhz_3v3[RCC_CLOCK_3V3_168MHZ]))
  ##  Enable clock for USART2 GPIO
  rcc_periph_clock_enable(RCC_GPIOA)
  ##  Enable clock for USART2
  rcc_periph_clock_enable(RCC_USART2)

proc usart_setup*() =
  ##  Setup GPIO pins for USART2 transmit
  gpio_mode_setup(GPIOA, GPIO_MODE_AF, GPIO_PUPD_NONE, GPIO2)
  ##  Setup USART2 TX pin as alternate function
  gpio_set_af(GPIOA, GPIO_AF7, GPIO2)
  usart_set_baudrate(USART_CONSOLE, 115200)
  usart_set_databits(USART_CONSOLE, 8)
  usart_set_stopbits(USART_CONSOLE, USART_STOPBITS_1)
  usart_set_mode(USART_CONSOLE, USART_MODE_TX)
  usart_set_parity(USART_CONSOLE, USART_PARITY_NONE)
  usart_set_flow_control(USART_CONSOLE, USART_FLOWCONTROL_NONE)
  ##  Finally enable the USART
  usart_enable(USART_CONSOLE)

##  Set up a timer to create 1ms ticks
##  The handler is in sys.c

proc systick_setup*() =
  ##  clock rate / 1000 to get 1ms interrupt rate
  systick_set_reload(CLOCK_FREQUENCY div 1000)
  systick_set_clocksource(STK_CSR_CLKSOURCE_AHB)
  systick_counter_enable()
  systick_interrupt_enable()

##  Use USART_CONSOLE as a console.
##  This is a syscall for newlib

proc _write*(file: cint; `ptr`: cstring; len: cint): cint =
  var i: cint
  if file == STDOUT_FILENO or file == STDERR_FILENO:
    i = 0
    while i < len:
      if `ptr`[i] == '\n':
        usart_send_blocking(USART_CONSOLE, '\c')
      usart_send_blocking(USART_CONSOLE, `ptr`[i])
      inc(i)
    return i
  errno = EIO
  return -1

proc main*(): cint =
  clock_setup()
  systick_setup()
  usart_setup()
  var flashed_avm: pointer = cast[pointer](AVM_ADDRESS)
  var size: uint32 = AVM_FLASH_MAX_SIZE
  var startup_beam_size: uint32
  var startup_beam: pointer
  var startup_module_name: cstring
  printf("Booting file mapped at: %p, size: %li\n", flashed_avm, size)
  var glb: ptr GlobalContext = globalcontext_new()
  if not avmpack_is_valid(flashed_avm, size) or
      not avmpack_find_section_by_flag(flashed_avm, BEAM_START_FLAG,
                                      addr(startup_beam),
                                      addr(startup_beam_size),
                                      addr(startup_module_name)):
    fprintf(stderr, "error: invalid AVM Pack\n")
    return 1
  glb.avmpack_data = flashed_avm
  glb.avmpack_platform_data = nil
  var `mod`: ptr Module = module_new_from_iff_binary(glb, startup_beam,
      startup_beam_size)
  globalcontext_insert_module_with_filename(glb, `mod`, startup_module_name)
  var ctx: ptr Context = context_new(glb)
  printf("Starting: %s...\n", startup_module_name)
  printf("---\n")
  context_execute_loop(ctx, `mod`, "start", 0)
  printf("Return value: %lx\n", cast[clong](term_to_int32(ctx.x[0])))
  while 1:
    nil
  return 0
