-- -*- coding: utf-8 -*-

local json = require "json"
local iputils = require("resty.iputils")
local _M = {}

function _M.init()
         local delay = 5  -- in seconds
         local new_timer = ngx.timer.at
         local log = ngx.log
         local ERR = ngx.ERR
         local check

         check = function(premature)
             if not premature then
                 log(ERR, "start refresh ip")
                 _M.refreship()
                 local ok, err = new_timer(delay, check)
                 if not ok then
                     log(ERR, "failed to create timer: ", err)
                     return
                 end
             end
         end

         if ngx.worker.id() == 0 then
             local ok, err = new_timer(delay, check)
             if not ok then
                 log(ERR, "failed to create timer: ", err)
                 return
             end
         end
end
function _M.refreship()
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
end
return _M
