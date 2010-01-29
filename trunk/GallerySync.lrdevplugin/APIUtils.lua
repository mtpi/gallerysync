local LrHttp = import 'LrHttp'
local logger = import 'LrLogger'('GallerySync.APIUtils')
--logger:enable('print')

require 'TableUtils'

local json = require('json')

local timeout = 10

local function urlEncode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str	
end

local function argsToUrl(args)
    local strArgs = '?'
    for k,v in pairs(args) do
        strArgs = strArgs .. urlEncode(k) .. '=' .. urlEncode(v) .. '&'
    end
    strArgs = string.gsub(strArgs, '&$', '')
    strArgs = string.gsub(strArgs, '\?$', '')
    return strArgs
end

function request(url, args, method, custom_headers, ...)
    assert(method,'method param is nil to call')
    local JSONRequestArray = {
        id="httpRequest",
        ["method"]=method,
        params = arg
    }
    logger:debug('JSONRequestArray=' .. table.tostring(JSONRequestArray))
    local jsonRequest = json.encode(JSONRequestArray)
    logger:debug('jsonRequest=' .. jsonRequest)
    local headers = {
        {field='User-Agent', value=_G.userAgent},
        {field='Content-Type', value='application/json'},
        {field='Content-Length', value=string.len(jsonRequest)}
    }
    for i,header in ipairs(custom_headers) do
        table.insert(headers, header)
    end
    logger:debug('HTTP request headers: ' .. table.tostring(headers))
    local respBody, respHeaders = LrHttp.post(url .. argsToUrl(args), jsonRequest, headers, 'POST', timeout)
    if not respBody then
        return nil, {'HTTP request failed'}
    end
    logger:debug('HTTP request respBody: ' .. respBody)
    logger:debug('HTTP request respHeaders: ' .. table.tostring(respHeaders))
    -- Check the http response code
    if (respHeaders.status~=200) then
        logger:debug('HTTP ERROR: ' .. respHeaders.status)
        return nil, {"HTTP ERROR: " .. respHeaders.status}
    end
    -- And decode the httpResponse and check the JSON RPC result code
    result = json.decode( respBody )
    if result.result then
        return result.result, nil
    else
        return nil, result.error
    end
end

function postMultipart(url, args, mimeChunks, custom_headers)
    local headers = {
        {field='User-Agent', value=_G.userAgent},
    }
    for i,header in ipairs(custom_headers) do
        table.insert(headers, header)
    end
    logger:debug('HTTP postMultipart url: ' .. url .. argsToUrl(args))
    logger:debug('HTTP postMultipart headers: ' .. table.tostring(headers))
    logger:debug('HTTP postMultipart mimeChunks: ' .. table.tostring(mimeChunks))
    
    local respBody, respHeaders = LrHttp.postMultipart(url .. argsToUrl(args), mimeChunks, headers, timeout)
    if not respBody or respBody == '' then
        logger:error('HTTP postMultipart ERROR headers:' .. table.tostring(respHeaders))
        return nil
    end
    logger:debug('HTTP postMultipart respBody: ' .. respBody)
    logger:debug('HTTP postMultipart respHeaders: ' .. table.tostring(respHeaders))
    return respBody
end
