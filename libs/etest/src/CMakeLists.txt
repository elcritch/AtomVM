##
## Copyright (c) 2018 Fred Dushin <fred@dushin.net>
##

project(estest)

include(BuildErlang)

set(ERLANG_MODULES
    etest
)

pack_archive(etest ${ERLANG_MODULES})

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/etest.avm DESTINATION lib/AtomVM/ebin)
