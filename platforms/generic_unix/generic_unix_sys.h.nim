## **************************************************************************
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

type
  event_handler* = proc (listener: ptr EventListener) {.cdecl.}
  EventListener* = object
    listeners_list_head*: ListHead
    handler*: event_handler
    data*: pointer
    fd*: cint

  GenericUnixPlatformData* = object
    listeners*: ptr ListHead


proc socket_init*(ctx: ptr Context; opts: term) {.cdecl.}