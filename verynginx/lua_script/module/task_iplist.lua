-- -*- coding: utf-8 -*-

local json = require "json"

local _M = {}

local KEY_STATUS_INIT = "I_"

function _M.init()
         local delay = 5  -- in seconds
         local log = ngx.log
         local ERR = ngx.ERR
         local check

         check = function(premature)
             if not premature then
                 log(ERR, "mm test mm test")
             end
         end

         if  ngx.worker.id() == 0 then
             local ok, err = ngx.timer.every(delay, check)
             if not ok then
                 log(ERR, "failed to create timer: ", err)
                 return
             end
         end
end

return _M
