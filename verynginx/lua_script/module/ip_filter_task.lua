-- -*- coding: utf-8 -*-
local _M = {}
local jxconfig = require "jxconfig"
--local redis_host="nginxredis.test.com"
--local redis_pwd="test"
local json = require "json"
local util = require "util"
--local iputils = require("resty.iputils")
local redis = require("resty.redis")
--iputils.enable_lrucache()
local redis_host = jxconfig.configs['redis_host']
local redis_pwd = jxconfig.configs['redis_pwd']
local redkey_config_ipfilter_enable = jxconfig.configs['redkey_config_ipfilter_enable']
local redkey_ip_blacklist = jxconfig.configs['redkey_ip_blacklist']
local redkey_ip_whitelist = jxconfig.configs['redkey_ip_whitelist']
--local redkey_ip_blacklist = "ip_blacklist_wap"
--local redkey_ip_whitelist = "ip_whitelist_wap"
--local redkey_config_ipfilter_enable = "config_ipfilter_wap_enable"
--config_ipfilter_wap_enable= false

_M.ip_whitelist = {
  }
_M.ip_blacklist = {
}

function _M.init()
    ngx.shared.status:set('config_ipfilter_wap_enable', "off" )
end
function _M.task_getips()
    local delay = 60  -- in seconds
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

    --if ngx.worker.id() == 0 then
        local ok, err = new_timer(delay, check)
        if not ok then
            ngx.log(ngx.ERR, "failed to create timer: ", err)
            return
        end
    --end
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

            local new_ip_blacklist, err = red:smembers(redkey_ip_blacklist)
            local new_ip_whitelist, err = red:smembers(redkey_ip_whitelist)
            local new_config_ipfilter_wap_enable, err = red:get(redkey_config_ipfilter_enable)
            if err then
                ngx.log(ngx.ERR, "Redis read key error: ", err)
            else
                _M.ip_blacklist = new_ip_blacklist
                _M.ip_whitelist = new_ip_whitelist
                --config_ipfilter_wap_enable = new_config_ipfilter_wap_enable
                ngx.shared.status:set('config_ipfilter_wap_enable', new_config_ipfilter_wap_enable )
            end
            --ngx.log(ngx.ERR, "ip_whitelist_len:",table.getn(_M.ip_whitelist));
            --ngx.log(ngx.ERR, "ip_blacklist_len:",table.getn(_M.ip_blacklist));
            --ngx.log(ngx.ERR, "config_ipfilter_wap_enable:",ngx.shared.status:get('config_ipfilter_wap_enable' ))

            -- 连接池大小200个，并且设置最大的空闲时间是 30 秒
            local ok, err = red:set_keepalive(30000, 200)
            if not ok then
                ngx.log(ngx.ERR, "failed to set keepalive: ", err)
                return
            end
end
--function _M.set()
--    local args = util.get_request_args()
--    local red = redis:new()
--    red:set_timeout(2000) -- 1 sec
--    local ok, err = red:connect(redis_host, 6379)
--    if not ok then
--        ngx.log(ngx.ERR, "failed to connect redis: ", err)
--        return
--    end
--    local count
--    count, err = red:get_reused_times()
--    if 0 == count then
--        ok, err = red:auth(redis_pwd)
--        if not ok then
--            ngx.log(ngx.ERR, "failed to auth: ", err)
--            return
--        end
--    elseif err then
--        ngx.log(ngx.ERR, "failed to get reused times: ", err)
--        return
--    end
--    if args['enable']  then
--        ok, err = red:set(redkey_config_ipfilter_enable,args['enable'])
--    end
--    if args['wip']  then
--        ok, err = red:sadd(redkey_ip_whitelist,args['wip'])
--    end
--    if args['bip']  then
--        ok, err = red:sadd(redkey_ip_blacklist,args['bip'])
--    end
--    if not ok then
--        ngx.log(ngx.ERR, "failed to set key: ", err)
--        ngx.status = 400
--        return json.encode({["ret"]="failed",["message"]=err})
--    else
--        ngx.log(ngx.ERR, "args:",args['enable']..args['wip'])
--        ngx.log(ngx.ERR, "ip_whitelist_len:",table.getn(_M.ip_whitelist));
--        ngx.log(ngx.ERR, "config_ipfilter_wap_enable:",ngx.shared.status:get('config_ipfilter_wap_enable' ))
--        local data = {}
--        data['ret'] = 'success'
--        return json.encode( data )
--    end
--end

return _M
