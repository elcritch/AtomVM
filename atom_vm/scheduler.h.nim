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
##  @file scheduler.h
##  @brief Scheduling functions.
##
##  @details Scheduling functions are used to schedule processes.
##

import
  context, globalcontext, linkedlist

const
  DEFAULT_REDUCTIONS_AMOUNT* = 1024

## *
##  @brief move a process to waiting queue and wait a ready one
##
##  @details move current process to the waiting queue, and schedule the next one or sleep until an event is received.
##  @param global the global context.
##  @param c the process context.
##

proc scheduler_wait*(global: ptr GlobalContext; c: ptr Context): ptr Context {.cdecl.}
## *
##  @brief make sure a process is on the ready queue
##
##  @details make a process ready again by moving it to the ready queue.
##  @param global the global context.
##  @param c the process context.
##

proc scheduler_make_ready*(global: ptr GlobalContext; c: ptr Context) {.cdecl.}
## *
##  @brief just move a process to the wait queue
##
##  @details make a process waiting.
##  @param global the global context.
##  @param c the process context.
##

proc scheduler_make_waiting*(global: ptr GlobalContext; c: ptr Context) {.cdecl.}
## *
##  @brief removes a process and terminates it from the scheduling queue
##
##  @detail removes a process from the scheduling ready queue and destroys it if its not a leader process.
##  @param global the global context.
##  @param c the process that is going to be terminated.
##

proc scheduler_terminate*(c: ptr Context) {.cdecl.}
## *
##  @brief the number of processes
##
##  @detail counts the number of processes that are registered on the processes table.
##  @param global the global context.
##  @returns the total number of processes in the processes table.
##

proc schudule_processes_count*(global: ptr GlobalContext): cint {.cdecl.}
## *
##  @brief gets next runnable process from the ready queue.
##
##  @detail gets next runnable process from the ready queue, it may return current process if there isn't any other runnable process.
##  @param global the global context.
##  @param c the current process.
##  @returns runnable process.
##

proc scheduler_next*(global: ptr GlobalContext; c: ptr Context): ptr Context {.cdecl.}
## *
##  @brief sets context timeout
##
##  @details set context timeout timestamp, move context to wait queue and update global next timeout timestamp.
##  @param ctx the context that will be put on sleep
##  @param timeout ammount of time to be waited in milliseconds.
##

proc scheduler_set_timeout*(ctx: ptr Context; timeout: uint32_t) {.cdecl.}
proc scheduler_cancel_timeout*(ctx: ptr Context) {.cdecl.}