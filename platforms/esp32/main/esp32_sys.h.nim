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
  freertos/FreeRTOS

const
  EVENT_DESCRIPTORS_COUNT* = 16

type
  event_handler_t* = proc (listener: ptr EventListener) {.cdecl.}
  EventListener* = object
    listeners_list_head*: ListHead
    handler*: event_handler_t
    data*: pointer
    sender*: pointer

  ESP32PlatformData* = object
    listeners*: ListHead
    sockets_list_head*: ListHead


var event_queue*: xQueueHandle

proc esp32_sys_queue_init*() {.cdecl.}
proc sys_event_listener_init*(listener: ptr EventListener; sender: pointer;
                             handler: event_handler_t; data: pointer) {.cdecl.}
proc socket_init*(ctx: ptr Context; opts: term) {.cdecl.}