import
  defaultatoms

var false_atom*: string = "\x05false"

var true_atom*: string = "\x04true"

var ok_atom*: string = "\x02ok"

var error_atom*: string = "\x05error"

var undefined_atom*: string = "\tundefined"

var badarg_atom*: string = "\x06badarg"

var badarith_atom*: string = "\bbadarith"

var badarity_atom*: string = "\bbadarity"

var badfun_atom*: string = "\x06badfun"

var system_limit_atom*: string = "\fsystem_limit"

var function_clause_atom*: string = "\x0Ffunction_clause"

var try_clause_atom*: string = "\ntry_clause"

var out_of_memory_atom*: string = "\cout_of_memory"

var overflow_atom*: string = "\boverflow"

var flush_atom*: string = "\x05flush"

var heap_size_atom*: string = "\theap_size"

var latin1_atom*: string = "\x06latin1"

var max_heap_size_atom*: string = "\cmax_heap_size"

var memory_atom*: string = "\x06memory"

var message_queue_len_atom*: string = "\x11message_queue_len"

var puts_atom*: string = "\x04puts"

var stack_size_atom*: string = "\nstack_size"

var min_heap_size_atom*: string = "\cmin_heap_size"

var process_count_atom*: string = "\cprocess_count"

var port_count_atom*: string = "\nport_count"

var atom_count_atom*: string = "\natom_count"

var system_architecture_atom*: string = "\x13system_architecture"

var wordsize_atom*: string = "\bwordsize"

var decimals_atom*: string = "\bdecimals"

var scientific_atom*: string = "\nscientific"

var compact_atom*: string = "\acompact"

var badmatch_atom*: string = "\bbadmatch"

var case_clause_atom*: string = "\vcase_clause"

var if_clause_atom*: string = "\tif_clause"

var throw_atom*: string = "\x05throw"

var low_entropy_atom*: string = "\vlow_entropy"

var unsupported_atom*: string = "\vunsupported"

var used_atom*: string = "\x04used"

var all_atom*: string = "\x03all"

var start_atom*: string = "\x05start"

proc defaultatoms_init*(glb: ptr GlobalContext) {.cdecl.} =
  var ok: cint = 1
  ok = ok and globalcontext_insert_atom(glb, false_atom) == FALSE_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, true_atom) == TRUE_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, ok_atom) == OK_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, error_atom) == ERROR_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, undefined_atom) == UNDEFINED_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, badarg_atom) == BADARG_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, badarith_atom) == BADARITH_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, badarity_atom) == BADARITY_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, badfun_atom) == BADFUN_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, function_clause_atom) ==
      FUNCTION_CLAUSE_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, try_clause_atom) == TRY_CLAUSE_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, out_of_memory_atom) ==
      OUT_OF_MEMORY_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, overflow_atom) == OVERFLOW_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, system_limit_atom) ==
      SYSTEM_LIMIT_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, flush_atom) == FLUSH_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, heap_size_atom) == HEAP_SIZE_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, latin1_atom) == LATIN1_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, max_heap_size_atom) ==
      MAX_HEAP_SIZE_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, memory_atom) == MEMORY_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, message_queue_len_atom) ==
      MESSAGE_QUEUE_LEN_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, puts_atom) == PUTS_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, stack_size_atom) == STACK_SIZE_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, min_heap_size_atom) ==
      MIN_HEAP_SIZE_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, process_count_atom) ==
      PROCESS_COUNT_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, port_count_atom) == PORT_COUNT_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, atom_count_atom) == ATOM_COUNT_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, system_architecture_atom) ==
      SYSTEM_ARCHITECTURE_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, wordsize_atom) == WORDSIZE_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, decimals_atom) == DECIMALS_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, scientific_atom) == SCIENTIFIC_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, compact_atom) == COMPACT_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, badmatch_atom) == BADMATCH_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, case_clause_atom) == CASE_CLAUSE_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, if_clause_atom) == IF_CLAUSE_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, throw_atom) == THROW_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, low_entropy_atom) == LOW_ENTROPY_ATOM_INDEX
  ok = ok and
      globalcontext_insert_atom(glb, unsupported_atom) == UNSUPPORTED_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, used_atom) == USED_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, all_atom) == ALL_ATOM_INDEX
  ok = ok and globalcontext_insert_atom(glb, start_atom) == START_ATOM_INDEX
  if not ok:
    abort()
  platform_defaultatoms_init(glb)
