-- -*- coding: utf-8 -*-

local _M = {}
local iputils = require("resty.iputils")
local redis = require("resty.redis")
iputils.enable_lrucache()
local whitelist_ips = {
      "127.0.0.1",
      "10.10.10.0/24",
      "192.168.0.0/16",
      --"128.199.113.98",
  }
local banlist_ips = {
      "127.0.0.1",
      "10.10.10.0/24",
      "192.168.0.0/16",
      --"128.199.113.98",
}


function _M.task_getips()
    local delay = 3  -- in seconds
    local new_timer = ngx.timer.at
    local check

    check = function(premature)
        if not premature then
            ngx.log(ngx.ERR, "start refresh ip: ", err)
            _M.refreship()
            local ok, err = new_timer(delay, check)
            if not ok then
                ngx.log(ngx.ERR, "failed to create timer: ", err)
                return
            end
        end
    end

    if ngx.worker.id() == 0 then
        local ok, err = new_timer(delay, check)
        if not ok then
            ngx.log(ngx.ERR, "failed to create timer: ", err)
            return
        end
    end
end

function _M.refreship()
            local redis = require "resty.redis"
            local red = redis:new()

            red:set_timeout(1000) -- 1 sec

            local ok, err = red:connect("172.31.26.218", 6379)
            if not ok then
                ngx.log(ngx.ERR, "failed to connect: ", err)
                return
            end
            local count
            count, err = red:get_reused_times()
            if 0 == count then
                ok, err = red:auth("Jxnginxredis")
                if not ok then
                    ngx.log(ngx.ERR, "failed to auth: ", err)
                    return
                end
            elseif err then
                ngx.log(ngx.ERR, "failed to get reused times: ", err)
                return
            end

            ok, err = red:set("dog", "an animal")
            if not ok then
                ngx.log(ngx.ERR, "failed to set dog: ", err)
                return
            end

            ngx.log(ngx.ERR, "set result ok: ", err)

            -- 连接池大小是100个，并且设置最大的空闲时间是 10 秒
            local ok, err = red:set_keepalive(10000, 100)
            if not ok then
                ngx.log(ngx.ERR, "failed to set keepalive: ", err)
                return
            end
  whitelist_ips = {
      "127.0.0.1",
      "10.10.10.0/24",
      "192.168.0.0/16",
      "128.199.113.98",
  }
  banlist_ips = {
      "127.0.0.1",
      "10.10.10.0/24",
      "192.168.0.0/16",
      --"128.199.113.98",
  }
end


function _M.filter()

  whitelist = iputils.parse_cidrs(whitelist_ips)
  banlist = iputils.parse_cidrs(banlist_ips)

    if iputils.ip_in_cidrs(ngx.var.clientRealIp, whitelist) then
        return _M
    end
    if iputils.ip_in_cidrs(ngx.var.clientRealIp, banlist) or ngx.var.geoip_country_code~="CN" then
        return ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end

return _M
