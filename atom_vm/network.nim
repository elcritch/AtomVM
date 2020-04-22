## **************************************************************************
##    Copyright 2018 by Davide Bettio <davide@uninstall.it>                 *
##    Copyright 2018 by Fred Dushin <fred@dushin.net>                       *
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
  context, port, network, network_driver, context, globalcontext, mailbox, utils, term

var start_a*: cstring = "\x05start"

var ifconfig_a*: cstring = "\bifconfig"

proc network_consume_mailbox*(ctx: ptr Context) =
  var message: ptr Message = mailbox_dequeue(ctx)
  var msg: term = message.message
  if port_is_standard_port_command(msg):
    port_ensure_available(ctx, 32)
    var pid: term = term_get_tuple_element(msg, 0)
    var `ref`: term = term_get_tuple_element(msg, 1)
    var cmd: term = term_get_tuple_element(msg, 2)
    if term_is_atom(cmd) and cmd == context_make_atom(ctx, ifconfig_a):
      var reply: term = network_driver_ifconfig(ctx)
      port_send_reply(ctx, pid, `ref`, reply)
    elif term_is_tuple(cmd) and term_get_tuple_arity(cmd) == 2:
      var cmd_name: term = term_get_tuple_element(cmd, 0)
      var config: term = term_get_tuple_element(cmd, 1)
      if cmd_name == context_make_atom(ctx, start_a):
        network_driver_start(ctx, pid, `ref`, config)
      else:
        port_send_reply(ctx, pid, `ref`, port_create_error_tuple(ctx, BADARG_ATOM))
    else:
      port_send_reply(ctx, pid, `ref`, port_create_error_tuple(ctx, BADARG_ATOM))
  else:
    fprintf(stderr, "WARNING: Invalid port command.  Unable to send reply")
  free(message)

proc network_init*(ctx: ptr Context; opts: term) =
  UNUSED(opts)
  ctx.native_handler = network_consume_mailbox
  ctx.platform_data = nil
