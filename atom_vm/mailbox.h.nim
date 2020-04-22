## **************************************************************************
##    Copyright 2017 by Davide Bettio <davide@uninstall.it>                 *
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
## *
##  @file mailbox.h
##  @brief Mailbox management functions such as send and receive functions.
##
##  @details Mailbox management functions should be used to send messages to a certain process or port and to receive them.
##

import
  list, term, context

type
  Message* = object
    mailbox_list_head*: ListHead
    msg_memory_size*: cint
    message*: term


## *
##  @brief Sends a message to a certain mailbox.
##
##  @details Sends a term to a certain process or port mailbox.
##  @param c the process context.
##  @param t the term that will be sent.
##

proc mailbox_send*(c: ptr Context; t: term) {.cdecl.}
## *
##  @brief Gets next message from a mailbox.
##
##  @details Dequeue a term that has been previously queued on a certain process or driver mailbox.
##  @param c the process or driver context.
##  @returns next queued term.
##

proc mailbox_receive*(c: ptr Context): term {.cdecl.}
## *
##  @brief Dequeue next message struct from mailbox.
##
##  @details Dequeue a message that has been previously queued on a certain process or driver mailbox.
##  @param c the process or driver context.
##  @returns dequeued message, the caller must free() the message.
##

proc mailbox_dequeue*(c: ptr Context): ptr Message {.cdecl.}
## *
##  @brief Gets next message from a mailbox (without removing it).
##
##  @details Peek the mailbox and retrieve a term that has been previously queued on a certain process or driver mailbox.
##  @param c the process or driver context.
##  @returns peek queued term.
##

proc mailbox_peek*(c: ptr Context): term {.cdecl.}
## *
##  @brief Remove next message from mailbox.
##
##  @details Discard a term that has been previously queued on a certain process or driver mailbox.
##  @param c the process or driver context.
##

proc mailbox_remove*(c: ptr Context) {.cdecl.}