##
## Copyright (c) 2018 Fred Dushin <fred@dushin.net>
##

project(eavmlib)

include(BuildErlang)

set(ERLANG_MODULES
    atomvm
    console
    esp
    gpio
    i2c
    http_server
    json_encoder
    logger
    network_fsm
    spi
    timer_manager
    timestamp_util
    uart
)

pack_archive(eavmlib ${ERLANG_MODULES})

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/eavmlib.avm DESTINATION lib/AtomVM/ebin)
