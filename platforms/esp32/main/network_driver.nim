## **************************************************************************
##    Copyright 2018 by Davide Bettio <davide@uninstall.it>                 *
##    Copyright 2018 by Fred Dushin <fred@dushin.net>                       *
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
  network_driver, port, atom, context, debug, globalcontext, interop, mailbox, utils,
  socket_driver, term, platform_defaultatoms

## #define ENABLE_TRACE 1
##  TODO: FIXME

##  #ifndef TRACE
##      #ifdef ENABLE_TRACE
##          #define TRACE printf
##      #else
##          #define TRACE(...)
##      #endif
##  #endif

const
  CONNECTED_BIT* = BIT0

proc wifi_event_handler*(ctx: pointer; event: ptr system_event): esp_err {.cdecl.}
var wifi_event_group*: EventGroupHandle

type
  ClientData* = object
    ctx*: ptr Context
    pid*: term
    ref_ticks*: uint64


proc network_driver_start*(ctx: ptr Context; pid: term_ref; `ref`: term_ref;
                          config: term) =
  TRACE("network_driver_start")
  var sta_config: term = interop_proplist_get_value(config, STA_ATOM)
  if not term_is_nil(sta_config):
    var ssid_value: term = interop_proplist_get_value(sta_config, SSID_ATOM)
    var pass_value: term = interop_proplist_get_value(sta_config, PSK_ATOM)
    var sntp_value: term = interop_proplist_get_value(config, SNTP_ATOM)
    var ok: cint = 0
    var ssid: cstring = interop_term_to_string(ssid_value, addr(ok))
    if not ok or IS_NULL_PTR(ssid):
      var reply: term = port_create_error_tuple(ctx, BADARG_ATOM)
      port_send_reply(ctx, pid, `ref`, reply)
      return
    var psk: cstring = interop_term_to_string(pass_value, addr(ok))
    if not ok or IS_NULL_PTR(psk):
      free(ssid)
      var reply: term = port_create_error_tuple(ctx, BADARG_ATOM)
      port_send_reply(ctx, pid, `ref`, reply)
      return
    TRACE("ssid: %s psk: xxxxxxxx\n", ssid)
    var data: ptr ClientData = cast[ptr ClientData](malloc(sizeof((ClientData))))
    if UNLIKELY(data == nil):
      fprintf(stderr, "malloc %s:%d", __FILE__, __LINE__)
      abort()
    data.ctx = ctx
    data.pid = pid
    data.ref_ticks = term_to_ref_ticks(`ref`)
    wifi_event_group = xEventGroupCreate()
    ESP_ERROR_CHECK(esp_event_loop_init(wifi_event_handler, data))
    TRACE("Initialized event loop.\n")
    var cfg: wifi_init_config = WIFI_INIT_CONFIG_DEFAULT()
    ESP_ERROR_CHECK(esp_wifi_init(addr(cfg)))
    ESP_ERROR_CHECK(esp_wifi_set_storage(WIFI_STORAGE_RAM))
    var wifi_config: wifi_config
    if UNLIKELY((strlen(ssid) > sizeof((wifi_config.sta.ssid))) or
        (strlen(psk) > sizeof((wifi_config.sta.password)))):
      TRACE("ssid or psk is too long\n")
      free(ssid)
      free(psk)
      var reply: term = port_create_error_tuple(ctx, BADARG_ATOM)
      port_send_reply(ctx, pid, `ref`, reply)
      return
    memset(addr(wifi_config), 0, sizeof((wifi_config)))
    strcpy(cast[cstring](wifi_config.sta.ssid), ssid)
    strcpy(cast[cstring](wifi_config.sta.password), psk)
    free(ssid)
    free(psk)
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA))
    ESP_ERROR_CHECK(esp_wifi_set_config(ESP_IF_WIFI_STA, addr(wifi_config)))
    ESP_LOGI("NETWORK", "starting wifi: SSID: [%s], password: [XXXXXXXX].",
             wifi_config.sta.ssid)
    ESP_ERROR_CHECK(esp_wifi_start())
    if sntp_value != term_nil():
      var ok: cint
      var sntp: cstring = interop_term_to_string(sntp_value, addr(ok))
      if LIKELY(ok):
        ##  do not free(sntp)
        sntp_setoperatingmode(SNTP_OPMODE_POLL)
        sntp_setservername(0, sntp)
        sntp_init()
    port_send_reply(ctx, pid, `ref`, OK_ATOM)
  else:
    var reply: term = port_create_error_tuple(ctx, BADARG_ATOM)
    port_send_reply(ctx, pid, `ref`, reply)

proc network_driver_ifconfig*(ctx: ptr Context): term =
  return port_create_error_tuple(ctx, UNDEFINED_ATOM)

proc get_ipv4_addr*(`addr`: ptr ip4_addr): u32 =
  return `addr`.`addr`

proc send_got_ip*(data: ptr ClientData; info: ptr tcpip_adapter_ip_info) =
  TRACE("Sending got_ip back to AtomVM\n")
  var ctx: ptr Context = data.ctx
  port_ensure_available(ctx, ((4 + 1) * 3 + (2 + 1) + (2 + 1)) * 2)
  var pid: term = data.pid
  var `ref`: term = term_from_ref_ticks(data.ref_ticks, ctx)
  var ip: term = socket_tuple_from_addr(ctx, ntohl(get_ipv4_addr(addr(info.ip))))
  var netmask: term = socket_tuple_from_addr(ctx,
      ntohl(get_ipv4_addr(addr(info.netmask))))
  var gw: term = socket_tuple_from_addr(ctx, ntohl(get_ipv4_addr(addr(info.gw))))
  var ip_info: term = port_create_tuple3(ctx, ip, netmask, gw)
  var reply: term = port_create_tuple2(ctx, STA_GOT_IP_ATOM, ip_info)
  port_send_reply(ctx, pid, `ref`, reply)

proc send_atom*(data: ptr ClientData; atom: term) =
  var ctx: ptr Context = data.ctx
  port_ensure_available(ctx, 6)
  var pid: term = data.pid
  var `ref`: term = term_from_ref_ticks(data.ref_ticks, ctx)
  ##  Pid ! {Ref, Atom}
  port_send_reply(ctx, pid, `ref`, atom)

proc send_sta_connected*(data: ptr ClientData) =
  TRACE("Sending sta_connected back to AtomVM\n")
  send_atom(data, STA_CONNECTED_ATOM)

proc send_sta_disconnected*(data: ptr ClientData) =
  TRACE("Sending sta_disconnected back to AtomVM\n")
  send_atom(data, STA_DISCONNECTED_ATOM)

proc wifi_event_handler*(ctx: pointer; event: ptr system_event): esp_err =
  var data: ptr ClientData = cast[ptr ClientData](ctx)
  case event.event_id
  of SYSTEM_EVENT_STA_START:
    ESP_LOGI("NETWORK", "SYSTEM_EVENT_STA_START received.")
    esp_wifi_connect()
  of SYSTEM_EVENT_STA_GOT_IP:
    ESP_LOGI("NETWORK", "SYSTEM_EVENT_STA_GOT_IP: %s",
             inet_ntoa(event.event_info.got_ip.ip_info.ip))
    xEventGroupSetBits(wifi_event_group, CONNECTED_BIT)
    send_got_ip(data, addr(event.event_info.got_ip.ip_info))
  of SYSTEM_EVENT_STA_CONNECTED:
    ESP_LOGI("NETWORK", "SYSTEM_EVENT_STA_CONNECTED received.")
    send_sta_connected(data)
  of SYSTEM_EVENT_STA_DISCONNECTED:
    ESP_LOGI("NETWORK", "SYSTEM_EVENT_STA_DISCONNECTED received.")
    esp_wifi_connect()
    xEventGroupClearBits(wifi_event_group, CONNECTED_BIT)
    send_sta_disconnected(data)
  else:
    ESP_LOGI("NETWORK", "Unhandled wifi event: %i.", event.event_id)
  return ESP_OK
