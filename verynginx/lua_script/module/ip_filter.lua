-- -*- coding: utf-8 -*-

local _M = {}

function _M.filter()
    
  local iputils = require("resty.iputils")
  iputils.enable_lrucache()
  local whitelist_ips = {
      "127.0.0.1",
      "10.10.10.0/24",
      "192.168.0.0/16",
      "128.199.113.98",
  }
  local banlist_ips = {
      "127.0.0.1",
      "10.10.10.0/24",
      "192.168.0.0/16",
      --"128.199.113.98",
  }
  whitelist = iputils.parse_cidrs(whitelist_ips)
  banlist = iputils.parse_cidrs(banlist_ips)

    if iputils.ip_in_cidrs(ngx.var.remote_addr, whitelist) then
        return _M
    end
    if iputils.ip_in_cidrs(ngx.var.remote_addr, banlist) or ngx.var.geoip_country_code~="CN" then
        return ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end

return _M
