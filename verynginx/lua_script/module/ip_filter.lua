-- -*- coding: utf-8 -*-

local _M = {}
local VeryNginxConfig = require "VeryNginxConfig"
local iputils = require("resty.iputils")
local redis = require("resty.redis")
iputils.enable_lrucache()
local redis_host="nginxredis.jxfuntest.com"
local redis_pwd="Jxnginxredis"
local redkey_ip_blacklist_wap = "ip_blacklist_wap"
local redkey_ip_whitelist_wap = "ip_whitelist_wap"
local ip_whitelist = {
      --"128.199.113.98",
      --"211.24.114.252",
      --"139.59.106.99",
  }
local ip_blacklist = {
}

function _M.task_getips()
    local delay = 5  -- in seconds
    local new_timer = ngx.timer.at
    local check

    check = function(premature)
        if not premature then
            --ngx.log(ngx.ERR, "start refresh ip: ", err)
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
            local red = redis:new()
            red:set_timeout(2000) -- 1 sec
            local ok, err = red:connect(redis_host, 6379)
            if not ok then
                ngx.log(ngx.ERR, "failed to connect redis: ", err)
                return
            end
            local count
            count, err = red:get_reused_times()
            if 0 == count then
                ok, err = red:auth(redis_pwd)
                if not ok then
                    ngx.log(ngx.ERR, "failed to auth: ", err)
                    return
                end
            elseif err then
                ngx.log(ngx.ERR, "failed to get reused times: ", err)
                return
            end

            local new_ip_blacklist, err = red:smembers(redkey_ip_blacklist_wap);
            local new_ip_whitelist, err = red:smembers(redkey_ip_whitelist_wap);
            if err then
                ngx.log(ngx.ERR, "Redis read key error: ", err);
            else
                ip_blacklist = new_ip_blacklist
                ip_whitelist = new_ip_whitelist
            end
            ngx.log(ngx.ERR, "keys:",table.getn(ip_whitelist));

            -- 连接池大小200个，并且设置最大的空闲时间是 30 秒
            local ok, err = red:set_keepalive(30000, 200)
            if not ok then
                ngx.log(ngx.ERR, "failed to set keepalive: ", err)
                return
            end
end


function _M.filter()
  local ip = ngx.var.clientRealIp
    local response_list = VeryNginxConfig.configs['response']
    local response = nil
  whitelist = iputils.parse_cidrs(ip_whitelist)
  blacklist = iputils.parse_cidrs(ip_blacklist)
    ngx.log(ngx.ERR, "keys:",table.getn(ip_whitelist));
    if iputils.ip_in_cidrs(ip, whitelist) then
        return _M
    end
    if iputils.ip_in_cidrs(ip, blacklist) or ngx.var.geoip_country_code~="CN" then
        response = response_list['403_response_html']
        if response ~= nil then
            ngx.header.content_type = response['content_type']
            ngx.say( response['body'] )
            ngx.exit( ngx.HTTP_OK )
        else
            ngx.header.content_type = 'text/html'
            ngx.say('<html lang="en"> <head> <meta charset="UTF-8"> <meta name="viewport" content="width=device-width, initial-scale=1.0"> <meta http-equiv="X-UA-Compatible" content="ie=edge"> <title>当前网页无法打开</title> </head> <body style="text-align:center"> <div style="margin:10rem auto 0 auto;"> <h1 class="headline">当前网页无法打开!</h1> <p class="light m-b">尊敬的客户 : 您所在的地区或国家限制访问本网站。</p> <p class="light m-b">Dear Customers: Your country or region is restricted to visit this station.</p> </div> </body> </html>')
            ngx.exit( ngx.HTTP_OK )
        end
    end
end

return _M
