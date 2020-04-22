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

const
  _GNU_SOURCE* = true

import
  atom, defaultatoms, platform_defaultatoms, nifs, memory, term

##  TODO: FIXME
## #define ENABLE_TRACE

import
  trace

##  TODO: FIXME

template VALIDATE_VALUE*(value, verify_function: untyped): void =
  nil

template RAISE_ERROR*(error_type_atom: untyped): void =
  nil

##  #define VALIDATE_VALUE(value, verify_function) \
##      if (UNLIKELY(!verify_function((value)))) { \
##          argv[0] = ERROR_ATOM; \
##          argv[1] = BADARG_ATOM; \
##          return term_invalid_term(); \
##      }
##  #define RAISE_ERROR(error_type_atom) \
##      ctx->x[0] = ERROR_ATOM; \
##      ctx->x[1] = (error_type_atom); \
##      return term_invalid_term();

const
  MAX_NVS_KEY_SIZE* = 15
  MD5_DIGEST_LENGTH* = 16

var esp_rst_unknown_atom*: string = "\x0Fesp_rst_unknown"

var esp_rst_poweron*: string = "\x0Fesp_rst_poweron"

var esp_rst_ext*: string = "\vesp_rst_ext"

var esp_rst_sw*: string = "\nesp_rst_sw"

var esp_rst_panic*: string = "\cesp_rst_panic"

var esp_rst_int_wdt*: string = "\x0Fesp_rst_int_wdt"

var esp_rst_task_wdt*: string = "\x10esp_rst_task_wdt"

var esp_rst_wdt*: string = "\vesp_rst_wdt"

var esp_rst_deepsleep*: string = "\x11esp_rst_deepsleep"

var esp_rst_brownout*: string = "\x10esp_rst_brownout"

var esp_rst_sdio*: string = "\fesp_rst_sdio"

##                                                         123456789ABCDEF01

proc write_atom_c_string*(ctx: ptr Context; buf: string; bufsize: csize; t: term): cint {.
    cdecl.}
##
##  NIFs
##

proc nif_esp_random*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.} =
  UNUSED(argc)
  UNUSED(argv)
  var r: uint32_t = esp_random()
  if UNLIKELY(memory_ensure_free(ctx, BOXED_INT_SIZE) != MEMORY_GC_OK):
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  return term_make_boxed_int(r, ctx)

proc nif_esp_random_bytes*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.} =
  UNUSED(argc)
  VALIDATE_VALUE(argv[0], term_is_integer)
  var len: avm_int_t = term_to_int(argv[0])
  if len < 0:
    RAISE_ERROR(BADARG_ATOM)
  if len == 0:
    if UNLIKELY(memory_ensure_free(ctx, term_binary_data_size_in_terms(0) +
        BINARY_HEADER_SIZE) != MEMORY_GC_OK):
      RAISE_ERROR(OUT_OF_MEMORY_ATOM)
    var binary: term = term_from_literal_binary(nil, len, ctx)
    return binary
  else:
    var buf: ptr uint8_t = malloc(len)
    if UNLIKELY(IS_NULL_PTR(buf)):
      RAISE_ERROR(OUT_OF_MEMORY_ATOM)
    esp_fill_random(buf, len)
    if UNLIKELY(memory_ensure_free(ctx, term_binary_data_size_in_terms(len) +
        BINARY_HEADER_SIZE) != MEMORY_GC_OK):
      RAISE_ERROR(OUT_OF_MEMORY_ATOM)
    var binary: term = term_from_literal_binary(buf, len, ctx)
    free(buf)
    return binary

proc nif_esp_restart*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.} =
  UNUSED(ctx)
  UNUSED(argc)
  UNUSED(argv)
  esp_restart()
  return OK_ATOM

proc nif_esp_reset_reason*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.} =
  UNUSED(argc)
  UNUSED(argv)
  var reason: esp_reset_reason_t = esp_reset_reason()
  case reason
  of ESP_RST_UNKNOWN:
    return context_make_atom(ctx, esp_rst_unknown_atom)
  of ESP_RST_POWERON:
    return context_make_atom(ctx, esp_rst_poweron)
  of ESP_RST_EXT:
    return context_make_atom(ctx, esp_rst_ext)
  of ESP_RST_SW:
    return context_make_atom(ctx, esp_rst_sw)
  of ESP_RST_PANIC:
    return context_make_atom(ctx, esp_rst_panic)
  of ESP_RST_INT_WDT:
    return context_make_atom(ctx, esp_rst_int_wdt)
  of ESP_RST_TASK_WDT:
    return context_make_atom(ctx, esp_rst_task_wdt)
  of ESP_RST_WDT:
    return context_make_atom(ctx, esp_rst_wdt)
  of ESP_RST_DEEPSLEEP:
    return context_make_atom(ctx, esp_rst_deepsleep)
  of ESP_RST_BROWNOUT:
    return context_make_atom(ctx, esp_rst_brownout)
  of ESP_RST_SDIO:
    return context_make_atom(ctx, esp_rst_sdio)
  else:
    return UNDEFINED_ATOM

proc nif_esp_nvs_get_binary*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.} =
  UNUSED(argc)
  VALIDATE_VALUE(argv[0], term_is_atom)
  VALIDATE_VALUE(argv[1], term_is_atom)
  var namespace: array[MAX_NVS_KEY_SIZE + 1, char]
  if write_atom_c_string(ctx, namespace, MAX_NVS_KEY_SIZE + 1, argv[0]) != 0:
    RAISE_ERROR(BADARG_ATOM)
  var key: array[MAX_NVS_KEY_SIZE + 1, char]
  if write_atom_c_string(ctx, key, MAX_NVS_KEY_SIZE + 1, argv[1]) != 0:
    RAISE_ERROR(BADARG_ATOM)
  var nvs: nvs_handle
  var err: esp_err_t = nvs_open(namespace, NVS_READONLY, addr(nvs))
  case err
  of ESP_OK:
    nil
  of ESP_ERR_NVS_NOT_FOUND:
    TRACE("No such namespace.  namespace=\'%s\'\n", namespace)
    return UNDEFINED_ATOM
  else:
    fprintf(stderr, "Unable to open NVS. namespace \'%s\' err=%i\n", namespace, err)
    RAISE_ERROR(term_from_int(err))
  var size: csize = 0
  err = nvs_get_blob(nvs, key, nil, addr(size))
  case err
  of ESP_OK:
    nil
  of ESP_ERR_NVS_NOT_FOUND:
    TRACE("No such entry.  namespace=\'%s\' key=\'%s\'\n", namespace, key)
    return UNDEFINED_ATOM
  else:
    fprintf(stderr, "Unable to get NVS blob size. namespace \'%s\'  key=\'%s\' err=%i\n",
            namespace, key, err)
    RAISE_ERROR(term_from_int(err))
  if UNLIKELY(memory_ensure_free(ctx, size + BINARY_HEADER_SIZE) != MEMORY_GC_OK):
    TRACE("Unabled to ensure free space for binary.  namespace=\'%s\' key=\'%s\' size=%i\n",
          namespace, key, size)
    RAISE_ERROR(OUT_OF_MEMORY_ATOM)
  var binary: term = term_create_uninitialized_binary(size, ctx)
  err = nvs_get_blob(nvs, key, cast[pointer](term_binary_data(binary)), addr(size))
  nvs_close(nvs)
  case err
  of ESP_OK:
    TRACE("Found data for key.  namespace=\'%s\' key=\'%s\' size=\'%i\'\n",
          namespace, key, size)
    return binary
  else:
    fprintf(stderr,
            "Unable to get NVS blob. namespace=\'%s\' key=\'%s\' err=%i\n",
            namespace, key, err)
    RAISE_ERROR(term_from_int(err))

proc nif_esp_nvs_set_binary*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.} =
  UNUSED(argc)
  VALIDATE_VALUE(argv[0], term_is_atom)
  VALIDATE_VALUE(argv[1], term_is_atom)
  VALIDATE_VALUE(argv[2], term_is_binary)
  var namespace: array[MAX_NVS_KEY_SIZE + 1, char]
  if write_atom_c_string(ctx, namespace, MAX_NVS_KEY_SIZE + 1, argv[0]) != 0:
    RAISE_ERROR(BADARG_ATOM)
  var key: array[MAX_NVS_KEY_SIZE + 1, char]
  if write_atom_c_string(ctx, key, MAX_NVS_KEY_SIZE + 1, argv[1]) != 0:
    RAISE_ERROR(BADARG_ATOM)
  var binary: term = argv[2]
  var size: csize = term_binary_size(binary)
  var nvs: nvs_handle
  var err: esp_err_t = nvs_open(namespace, NVS_READWRITE, addr(nvs))
  case err
  of ESP_OK:
    nil
  else:
    fprintf(stderr, "Unable to open NVS. namespace \'%s\' err=%i\n", namespace, err)
    RAISE_ERROR(term_from_int(err))
  err = nvs_set_blob(nvs, key, term_binary_data(binary), size)
  nvs_close(nvs)
  case err
  of ESP_OK:
    TRACE("Wrote blob to NVS. namespace \'%s\' key \'%s\' size: %i\n", namespace,
          key, size)
    return OK_ATOM
  else:
    fprintf(stderr, "Unable to set NVS blob. namespace=\'%s\' key=\'%s\' size=%i err=%i\n",
            namespace, key, size, err)
    RAISE_ERROR(term_from_int(err))

proc nif_esp_nvs_erase_key*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.} =
  UNUSED(argc)
  VALIDATE_VALUE(argv[0], term_is_atom)
  VALIDATE_VALUE(argv[1], term_is_atom)
  var namespace: array[MAX_NVS_KEY_SIZE + 1, char]
  if write_atom_c_string(ctx, namespace, MAX_NVS_KEY_SIZE + 1, argv[0]) != 0:
    RAISE_ERROR(BADARG_ATOM)
  var key: array[MAX_NVS_KEY_SIZE + 1, char]
  if write_atom_c_string(ctx, key, MAX_NVS_KEY_SIZE + 1, argv[1]) != 0:
    RAISE_ERROR(BADARG_ATOM)
  var nvs: nvs_handle
  var err: esp_err_t = nvs_open(namespace, NVS_READWRITE, addr(nvs))
  case err
  of ESP_OK:
    nil
  else:
    fprintf(stderr, "Unable to open NVS. namespace \'%s\' err=%i\n", namespace, err)
    RAISE_ERROR(term_from_int(err))
  err = nvs_erase_key(nvs, key)
  nvs_close(nvs)
  case err
  of ESP_OK:
    TRACE("Erased key. namespace \'%s\' key \'%s\'\n", namespace, key)
    return OK_ATOM
  of ESP_ERR_NVS_NOT_FOUND:
    TRACE("No such entry -- ok.  namespace=\'%s\' key=\'%s\'\n", namespace, key)
    return OK_ATOM
  else:
    fprintf(stderr, "Unable to erase key. namespace=\'%s\' key=\'%s\' err=%i\n",
            namespace, key, err)
    RAISE_ERROR(term_from_int(err))

proc nif_esp_nvs_erase_all*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.} =
  UNUSED(argc)
  VALIDATE_VALUE(argv[0], term_is_atom)
  var namespace: array[MAX_NVS_KEY_SIZE + 1, char]
  if write_atom_c_string(ctx, namespace, MAX_NVS_KEY_SIZE + 1, argv[0]) != 0:
    RAISE_ERROR(BADARG_ATOM)
  var nvs: nvs_handle
  var err: esp_err_t = nvs_open(namespace, NVS_READWRITE, addr(nvs))
  case err
  of ESP_OK:
    nil
  else:
    fprintf(stderr, "Unable to open NVS. namespace \'%s\' err=%i\n", namespace, err)
    RAISE_ERROR(term_from_int(err))
  err = nvs_erase_all(nvs)
  nvs_close(nvs)
  case err
  of ESP_OK:
    TRACE("Erased all. namespace \'%s\'\n", namespace)
    return OK_ATOM
  else:
    fprintf(stderr, "Unable to erase all. namespace=\'%s\' err=%i\n", namespace,
            err)
    RAISE_ERROR(term_from_int(err))

proc nif_esp_nvs_reformat*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.} =
  UNUSED(argc)
  UNUSED(argv)
  var err: esp_err_t = nvs_flash_erase()
  case err
  of ESP_OK:
    nil
  else:
    fprintf(stderr, "Unable to reformat NVS partition. err=%i\n", err)
    RAISE_ERROR(term_from_int(err))
  err = nvs_flash_init()
  case err
  of ESP_OK:
    fprintf(stderr, "Warning: Reformatted NVS partition!\n")
    return OK_ATOM
  else:
    fprintf(stderr, "Unable to initialize NVS partition. err=%i\n", err)
    RAISE_ERROR(term_from_int(err))

proc nif_rom_md5*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.} =
  UNUSED(argc)
  var data: term = argv[0]
  VALIDATE_VALUE(data, term_is_binary)
  var digest: array[MD5_DIGEST_LENGTH, cuchar]
  var md5: MD5Context
  MD5Init(addr(md5))
  MD5Update(addr(md5), cast[ptr cuchar](term_binary_data(data)),
            term_binary_size(data))
  MD5Final(digest, addr(md5))
  return term_from_literal_binary(digest, MD5_DIGEST_LENGTH, ctx)

proc nif_atomvm_platform*(ctx: ptr Context; argc: cint; argv: ptr term): term {.cdecl.} =
  UNUSED(ctx)
  UNUSED(argc)
  UNUSED(argv)
  return ESP32_ATOM

##
##  NIF structures and distpatch
##
##  TODO: FIXME
##  static const struct Nif esp_random_nif =
##  {
##      .base.type = NIFFunctionType,
##      .nif_ptr = nif_esp_random
##  };
##  static const struct Nif esp_random_bytes_nif =
##  {
##      .base.type = NIFFunctionType,
##      .nif_ptr = nif_esp_random_bytes
##  };
##  static const struct Nif esp_restart_nif =
##  {
##      .base.type = NIFFunctionType,
##      .nif_ptr = nif_esp_restart
##  };
##  static const struct Nif esp_reset_reason_nif =
##  {
##      .base.type = NIFFunctionType,
##      .nif_ptr = nif_esp_reset_reason
##  };
##  static const struct Nif esp_nvs_get_binary_nif =
##  {
##      .base.type = NIFFunctionType,
##      .nif_ptr = nif_esp_nvs_get_binary
##  };
##  static const struct Nif esp_nvs_set_binary_nif =
##  {
##      .base.type = NIFFunctionType,
##      .nif_ptr = nif_esp_nvs_set_binary
##  };
##  static const struct Nif esp_nvs_erase_key_nif =
##  {
##      .base.type = NIFFunctionType,
##      .nif_ptr = nif_esp_nvs_erase_key
##  };
##  static const struct Nif esp_nvs_erase_all_nif =
##  {
##      .base.type = NIFFunctionType,
##      .nif_ptr = nif_esp_nvs_erase_all
##  };
##  static const struct Nif esp_nvs_reformat_nif =
##  {
##      .base.type = NIFFunctionType,
##      .nif_ptr = nif_esp_nvs_reformat
##  };
##  static const struct Nif rom_md5_nif =
##  {
##      .base.type = NIFFunctionType,
##      .nif_ptr = nif_rom_md5
##  };
##  static const struct Nif atomvm_platform_nif =
##  {
##      .base.type = NIFFunctionType,
##      .nif_ptr = nif_atomvm_platform
##  };

proc platform_nifs_get_nif*(nifname: string): ptr Nif {.cdecl.} =
  if strcmp("atomvm:random/0", nifname) == 0:
    TRACE("Resolved platform nif %s ...\n", nifname)
    return addr(esp_random_nif)
  if strcmp("atomvm:rand_bytes/1", nifname) == 0:
    TRACE("Resolved platform nif %s ...\n", nifname)
    return addr(esp_random_bytes_nif)
  if strcmp("esp:restart/0", nifname) == 0:
    TRACE("Resolved platform nif %s ...\n", nifname)
    return addr(esp_restart_nif)
  if strcmp("esp:reset_reason/0", nifname) == 0:
    TRACE("Resolved platform nif %s ...\n", nifname)
    return addr(esp_reset_reason_nif)
  if strcmp("esp:nvs_get_binary/2", nifname) == 0:
    TRACE("Resolved platform nif %s ...\n", nifname)
    return addr(esp_nvs_get_binary_nif)
  if strcmp("esp:nvs_set_binary/3", nifname) == 0:
    TRACE("Resolved platform nif %s ...\n", nifname)
    return addr(esp_nvs_set_binary_nif)
  if strcmp("esp:nvs_erase_key/2", nifname) == 0:
    TRACE("Resolved platform nif %s ...\n", nifname)
    return addr(esp_nvs_erase_key_nif)
  if strcmp("esp:nvs_erase_all/1", nifname) == 0:
    TRACE("Resolved platform nif %s ...\n", nifname)
    return addr(esp_nvs_erase_all_nif)
  if strcmp("esp:nvs_reformat/0", nifname) == 0:
    TRACE("Resolved platform nif %s ...\n", nifname)
    return addr(esp_nvs_reformat_nif)
  if strcmp("erlang:md5/1", nifname) == 0:
    TRACE("Resolved platform nif %s ...\n", nifname)
    return addr(rom_md5_nif)
  if strcmp("atomvm:platform/0", nifname) == 0:
    TRACE("Resolved platform nif %s ...\n", nifname)
    return addr(atomvm_platform_nif)
  return nil

##
##  internal functions
##

proc write_atom_c_string*(ctx: ptr Context; buf: string; bufsize: csize; t: term): cint {.
    cdecl.} =
  var atom_string: AtomString = globalcontext_atomstring_from_term(ctx.global, t)
  if atom_string == nil:
    return -1
  atom_string_to_c(atom_string, buf, bufsize)
  return 0
