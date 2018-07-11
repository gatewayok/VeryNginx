-- -*- coding: utf-8 -*-
local _M = {}
local redis_host="nginxredis.jxfuntest.com"
local redis_pwd="Jxnginxredis"
local dkjson = require "dkjson"
local json = require "json"
local util = require "util"
local ip_filter_task = require "ip_filter_task"
local iputils = require("resty.iputils")
local redis = require("resty.redis")
iputils.enable_lrucache()
local redkey_ip_blacklist_wap = "ip_blacklist_wap"
local redkey_ip_whitelist_wap = "ip_whitelist_wap"
local redkey_config_ipfilter_wap_enable = "config_ipfilter_wap_enable"
_M["configs_redis"] = {}
--return a json contain current config items
function _M.report()
    _M.configs_redis["config_ipfilter_wap_enable"] = ngx.shared.status:get('config_ipfilter_wap_enable' )
    _M.configs_redis["ip_whitelist"] = ip_filter_task.ip_whitelist
    _M.configs_redis["ip_blacklist"] = ip_filter_task.ip_blacklist
    _M.set_config_metadata( _M["configs_redis"] )
    return dkjson.encode( _M["configs_redis"] )
end
function _M.set()
    local args = util.get_request_args()
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
    if args['btnadd'] == "add"  then
        --[[if args['enable']  then
            ok, err = red:set(redkey_config_ipfilter_wap_enable,args['enable'])
        end]]
        if args['wip']  then
            --ngx.log(ngx.ERR, "btnadd wip:",args['wip'])
            ok, err = red:sadd(redkey_ip_whitelist_wap,args['wip'])
        end
        if args['bip']  then
            ngx.log(ngx.ERR, "btnadd bip:",args['wip'])
            ok, err = red:sadd(redkey_ip_blacklist_wap,args['bip'])
        end
    end
    if args['btndel'] == "del"  then
        --[[if args['enable']  then
            ok, err = red:set(redkey_config_ipfilter_wap_enable,args['enable'])
        end]]
        if args['wip']  then
            --ngx.log(ngx.ERR, "btndel wip:",args['wip'])
            ok, err = red:srem(redkey_ip_whitelist_wap,args['wip'])
        end
        if args['bip']  then
            ngx.log(ngx.ERR, "btndel bip:",args['bip'])
            ok, err = red:srem(redkey_ip_blacklist_wap,args['bip'])
        end
    end
    if not ok then
        ngx.log(ngx.ERR, "failed to set key: ", err)
        ngx.status = 400
        return json.encode({["ret"]="failed",["message"]=err})
    else
        --ngx.log(ngx.ERR, "args:",args['enable']..args['wip'])
        ngx.log(ngx.ERR, "ip_whitelist_len:",table.getn(ip_filter_task.ip_whitelist));
        ngx.log(ngx.ERR, "config_ipfilter_wap_enable:",ngx.shared.status:get('config_ipfilter_wap_enable' ))
        local data = {}
        data['ret'] = 'success'
        return json.encode( data )
    end
end
function _M.set_config_metadata( config_table )

    --make sure empty table trans to right type
    local meta_table = {}
    meta_table['__jsontype'] = 'object'

    if config_table['matcher'] ~= nil then
        setmetatable( config_table['matcher'], meta_table )
        for key, t in pairs( config_table["matcher"] ) do
            setmetatable( t, meta_table )
        end
    end

    if config_table['backend_upstream'] ~= nil then
        setmetatable( config_table['backend_upstream'], meta_table )
        for key, t in pairs( config_table["backend_upstream"] ) do
            setmetatable( t['node'], meta_table )
        end
    end

    if config_table['response'] ~= nil then
        setmetatable( config_table['response'], meta_table )
    end
    if config_table['ip_whitelist'] ~= nil then
        setmetatable( config_table['ip_whitelist'], meta_table )
    end
    --set table meta_data end

end
return _M
