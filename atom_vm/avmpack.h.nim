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
## *
##  @file avmpack.h
##  @brief AVM Pack file format parsing function.
##

const
  END_OF_FILE* = 0
  BEAM_START_FLAG* = 1
  BEAM_CODE_FLAG* = 2

## *
##  @brief callback function for AVMPack section fold.
##  @details Instances of this function are supplied to the avmpack_fold function, in order to
##  provide a callback mechanism for folding over the contents of the AVM binary.
##  @param accum The accumulator supplied by the application.
##  @param section_ptr a pointer to the start of the AVM section (including the module header)
##  @param section_size the size of the entire section (including the module header)
##  @param beam_ptr the start of the beam module portion of the section.  This pointers starts immeadiately after
##  the (aligned) header.
##  @param flags the section flags, as defined in the module header
##  @param section_name the section name, as defined in the module header
##  @return an acculator, which will be supplied to the next call to this funtion, and eventually returned from the avmpack_fold function.
##

type
  avmpack_fold_fun* = proc (accum: pointer; section_ptr: pointer;
                         section_size: uint32_t; beam_ptr: pointer; flags: uint32_t;
                         section_name: cstring): pointer {.cdecl.}

## *
##  @brief Finds an AVM Pack section that has certain flags set.
##
##  @details Finds an AVM Pack section that has certain flags set and returns a pointer to it, its size and its name.
##  @param avmpack_binary a pointer to valid AVM Pack file data.
##  @param flags_mask that will be matched against file sections.
##  @param ptr will point to the found file section.
##  @param size will be set to the file section size that has been found, if the section has not been found it will not be updated.
##  @returns 1 if the file section has been found, 0 otherwise.
##

proc avmpack_find_section_by_flag*(avmpack_binary: pointer; flags_mask: uint32_t;
                                  `ptr`: ptr pointer; size: ptr uint32_t;
                                  name: cstringArray): cint {.cdecl.}
## *
##  @brief Finds an AVM Pack section that has certain name.
##
##  @details Finds an AVM Pack section with a certain name and returns a pointer to it and its size.
##  @param avmpack_binary a pointer to valid AVM Pack file data.
##  @param name the file section name that will be searched.
##  @param ptr will point to the found file section, if the section has not been found it will not be updated.
##  @param size will be set to the file section size that has been found, if the section has not been found it will not be updated.
##  @returns 1 if the file section has been found, 0 otherwise.
##

proc avmpack_find_section_by_name*(avmpack_binary: pointer; name: cstring;
                                  `ptr`: ptr pointer; size: ptr uint32_t): cint {.cdecl.}
## *
##  @brief Returns 1 if the pointed binary is a valid AVM Pack.
##
##  @details Returns if the pointed binary is a valid AVM Pack binary or not.
##  @param avmpack_binary a pointer to an AVM Pack binary.
##  @param size the size of AVM Pack binary.
##  @returns 1 if it is a valid AVM Pack binary, 0 otherwise.
##

proc avmpack_is_valid*(avmpack_binary: pointer; size: uint32_t): cint {.cdecl.}
## *
##  @brief Fold over all the sections in an AVM Pack.
##
##  @details This function will call the callback on each section of the AVM Pack, passing in
##  the current section of each module in the AVM binary to the supplied fold function.
##  @param avmpack_binary a pointer to an AVM Pack binary.
##  @param fold_fun funtion that will be called for each AVM section.
##

proc avmpack_fold*(accum: pointer; avmpack_binary: pointer;
                  fold_fun: avmpack_fold_fun): pointer {.cdecl.}