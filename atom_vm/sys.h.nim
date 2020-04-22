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
##  @file sys.h
##  @brief Platform specific functions.
##
##  @details This header defines platform dependent functions, that mostly deals with events.
##

import
  globalcontext, linkedlist, module

## *
##  @brief process any pending event without blocking
##
##  @details check all open file descriptors/queues, dispatch messages for new events and wake up contexts accordingly.
##  @param glb the global context.
##

proc sys_consume_pending_events*(glb: ptr GlobalContext) {.cdecl.}
## *
##  @brief gets wall clock time
##
##  @details gets system wall clock time.
##  @param t the timespec that will be updated.
##

proc sys_time*(t: ptr timespec) {.cdecl.}
## *
##  @brief Loads a BEAM module using platform dependent methods.
##
##  @details Loads a BEAM module into memory using platform dependent methods and returns a pointer to a Module struct.
##  @param global the global context.
##  @param module_name the name of the BEAM file (e.g. "mymodule.beam").
##

proc sys_load_module*(global: ptr GlobalContext; module_name: cstring): ptr Module {.
    cdecl.}
## *
##  @brief Create a port driver
##  @details This function creates a port driver, enscapsulated in a Context object.  This function should
##  create a Context object throught the supplied global context, which will assume ownership of the new instance.
##  @param glb the global context
##  @param opts the term options passed into the port open command
##  @return a new Context instance, or NULL, if a driver cannot be created from the inputs.
##

proc sys_create_port*(glb: ptr GlobalContext; driver_name: cstring; opts: term): ptr Context {.
    cdecl.}
## *
##  @brief Get platform-dependent information for the specified key.
##  @details This function returns platform-depndent information specified by the supplied key.
##  If not information is available for the specified key, this function should return the
##  atom 'undefined'
##  @param ctx the current context
##  @param key an atom used to indicate the type of information requested.
##  @return a term containing the requested information, or the atom undefined, if
##  there is no system information for the specified key.
##

proc sys_get_info*(ctx: ptr Context; key: term): term {.cdecl.}
proc sys_init_platform*(global: ptr GlobalContext) {.cdecl.}
proc sys_start_millis_timer*() {.cdecl.}
proc sys_stop_millis_timer*() {.cdecl.}
proc sys_millis*(): uint32 {.cdecl.}
proc sys_sleep*(glb: ptr GlobalContext) {.cdecl.}