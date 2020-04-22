## **************************************************************************
##    Copyright 2018 by Davide Bettio <davide@uninstall.it>                 *
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
  term

proc interop_term_to_string*(t: term; ok: ptr cint): cstring {.cdecl.}
proc interop_binary_to_string*(binary: term): cstring {.cdecl.}
proc interop_list_to_string*(list: term; ok: ptr cint): cstring {.cdecl.}
proc interop_proplist_get_value*(list: term; key: term): term {.cdecl.}
proc interop_proplist_get_value_default*(list: term; key: term; default_value: term): term {.
    cdecl.}
proc interop_iolist_size*(t: term; ok: ptr cint): cint {.cdecl.}
proc interop_write_iolist*(t: term; p: cstring): cint {.cdecl.}