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
##  @file iff.h
##  @brief IFF/BEAM file parsing and constants.
##
##  @details BEAM module parser function and related defines.
##

## * UTF-8 Atoms table section

const
  AT8U* = 0

## * Code chunk section

const
  CODE* = 1

## * Exported functions table section

const
  EXPT* = 2

## * Local functions table section

const
  LOCT* = 3

## * Imported functions table section

const
  IMPT* = 4

## * Literals table section with all the compressed zlib literals data

const
  LITT* = 5

## * Uncompressed literals table section

const
  LITU* = 6

## * Funs table section

const
  FUNT* = 7

## * Str table section

const
  STRT* = 8

## * Required size for offsets array

const
  MAX_OFFS* = 9

## * Required size for sizes array

const
  MAX_SIZES* = 9

## * sizeof IFF section header in bytes

const
  IFF_SECTION_HEADER_SIZE* = 8

## *
##  @brief parse a BEAM/IFF file and build a sections offsets table
##
##  @details Read a buffer contaning a BEAM module file and set all found IFF sections into offsets array.
##  @param data is BEAM module data.
##  @param file_size is the BEAM module size in bytes.
##  @param offsets all the relative offsets, each entry will be set to the offset of a different IFF section.
##  @param sizes the computed sections sizes.
##

proc scan_iff*(iff_binary: pointer; file_size: cint; offsets: ptr culong;
              sizes: ptr culong) {.cdecl.}
## *
##  @brief Returns 1 if pointed binary is valid BEAM IFF.
##
##  @details Checks if the pointed binary has a valid BEAM IFF header.
##  @param beam_data a pointer to the beam_data binary
##  @returns 1 if beam_data points to a valid binary, otherwise 0 is returned.
##

proc iff_is_valid_beam*(beam_data: pointer): cint {.cdecl.}