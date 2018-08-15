-- -*- coding: utf-8 -*-
local _M = {}
local VeryNginxConfig = require "VeryNginxConfig"
local ip_filter_task = require "ip_filter_task"
local iputils = require("resty.iputils")

function _M.filter()
    if ngx.shared.status:get('config_ipfilter_wap_enable' ) ~= "on" then
        return _M
    end
  local ip = ngx.var.clientRealIp
  local response_list = VeryNginxConfig.configs['response']
  local response = nil
  whitelist = iputils.parse_cidrs(ip_filter_task.ip_whitelist)
  blacklist = iputils.parse_cidrs(ip_filter_task.ip_blacklist)
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
            --ngx.say('<html lang="en"> <head> <meta charset="UTF-8"> <meta name="viewport" content="width=device-width, initial-scale=1.0"> <meta http-equiv="X-UA-Compatible" content="ie=edge"> <title>当前网页无法打开</title> </head> <body style="text-align:center"> <div style="margin:10rem auto 0 auto;"> <h1 class="headline">当前网页无法打开!</h1> <p class="light m-b">尊敬的客户 : 由于您的国家和地区限制，我们无法为您提供服务。给您造成不便，敬请谅解。</p> <p class="light m-b">Dear Customers: Your country or region is restricted to visit this station.</p> </div> </body> </html>')
                        page = [[
            <html lang="en"> <head>
            <meta charset="UTF-8"> <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta http-equiv="X-UA-Compatible" content="ie=edge"> <title>当前网页无法打开</title>
            <style>
                html {
                  font: 16px/1.5 'Hiragino Sans GB', 'microsoft yahei', arial, sans-serif;
                  height: 100%;
                  width: 100%;
                  overflow-y: scroll;
                }

                body {
                  text-align: center;
                  font: inherit;
                  color: rgba(55, 52, 82, 1);
                  background-image: url('https://asset.cnduboshi.com/403/images/bg-min.png');
                  background-size: cover;
                  background-repeat: no-repeat;
                  background-position: center top;
                  min-height: 100%;
                  overflow: auto;
                }

                html,
                body {
                  margin: 0;
                  padding: 0;
                }

                *,
                *::after,
                *::before {
                  box-sizing: border-box;
                  margin: 0;
                  padding: 0;
                }

                .container {
                  position: relative;
                  display: block;
                  width: 100%;
                  max-width: 90%;
                  margin: 10rem auto 0 auto;
                  top: 50%;
                }

                .light {
                  color: rgba(55, 52, 82, 0.7)
                }
                .lighter {
                  color: rgba(55, 52, 82, 0.5)
                }
                .headline {
                  font-weight: normal;
                  font-size: 4.25rem;
                  line-height: 1.2;
                  margin-bottom: 1.5rem;
                }

                .m-b {
                  margin-bottom: 1.5rem;
                }

                .contact-btn {
                  background: #00ABFD;
                  box-shadow: 0 2px 4px 0 rgba(4, 116, 170, 0.36);
                  color: rgba(255, 255, 255, 0.9);
                  border-radius: 100px;
                  height: 3rem;
                  border-radius: 1.5rem;
                  font-size: 1.2rem;
                  font-weight: normal;
                  padding: 0 2rem;
                }
                @media screen and (max-width: 700px){
                  body {
                    background-image: url('https://asset.cnduboshi.com/403/images/app_bg-min.png');
                  }
                }
              </style>

            </head>
            <body style="text-align:center"> <div style="margin:10rem auto 0 auto;">
            <h1 class="headline">当前网页无法打开!</h1> <p class="light m-b">尊敬的客户 : 您所在的地区或国家限制访问本网站。</p>
            <p class="light m-b">Dear Customers: Your country or region is restricted to visit this station.</p>
            </div> </body> </html>
           ]]
            ngx.say(page)
            ngx.exit( ngx.HTTP_OK )
        end
    end
end

return _M




