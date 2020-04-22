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

import
  mapped_file, utils

proc mapped_file_open_beam*(file_name: string): ptr MappedFile {.cdecl.} =
  var mf: ptr MappedFile = malloc(sizeof((MappedFile)))
  if IS_NULL_PTR(mf):
    fprintf(stderr, "Unable to allocate MappedFile struct\n")
    return nil
  mf.fd = open(file_name, O_RDONLY)
  if UNLIKELY(mf.fd < 0):
    free(mf)
    fprintf(stderr, "Unable to open %s\n", file_name)
    return nil
  var file_stats: stat
  fstat(mf.fd, addr(file_stats))
  mf.size = file_stats.st_size
  mf.mapped = mmap(nil, mf.size, PROT_READ, MAP_SHARED, mf.fd, 0)
  if IS_NULL_PTR(mf.mapped):
    fprintf(stderr, "Cannot mmap %s\n", file_name)
    close(mf.fd)
    free(mf)
    return nil
  return mf

proc mapped_file_close*(mf: ptr MappedFile) {.cdecl.} =
  munmap(mf.mapped, mf.size)
  close(mf.fd)
  free(mf)
