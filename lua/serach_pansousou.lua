local curl = require "lcurl.safe"
local json = require "cjson.safe"


script_info = {
	["title"] = "盘搜搜",
	["version"] = "0.0.1",
	["description"] = "http://m.pansoso.com",
}

function request(args)

	local cookie = args.cookie or ""
	local referer = args.referer or ""
	local acceptEncoding = args.acceptEncoding or ""
	--pd.logInfo("the cccc..:"..cookie)
	local header = args.header or {"User-Agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Mobile Safari/537.36","Cookie: "..cookie,"Referer: "..referer,"Accept-Encoding"..acceptEncoding}
	--pd.logInfo("header cookie:"..header[2])
	local method = args.method or "GET"
	local para = args.para
	local url = args.url
	local data = ""

	local c = curl.easy{
		url = url,
		ssl_verifyhost = 0,
		ssl_verifypeer = 0,
		accept_encoding = "gzip",
		timeout = 15,
		proxy = pd.getProxy(),
	}


	if para ~= nil then
		c:setopt(curl.OPT_POST, 1)
		c:setopt(curl.OPT_POSTFIELDS, para)
	end

	if header ~= nil then
		c:setopt(curl.OPT_HTTPHEADER, header)
	end

	if method == "HEAD" then
		c:setopt(curl.OPT_NOBODY, 1)
		--c:setopt(curl.OPT_FOLLOWLOCATION, 1)
		c:setopt(curl.OPT_HEADERFUNCTION, function(h)
			data = data .. h
		end)
	else
		c:setopt(curl.OPT_WRITEFUNCTION, function(buffer)
			data = data .. buffer
			return #buffer
		end)
	end

	local _, err = c:perform()
	if err == nil and method == "HEAD" then
		--data = c:getinfo(curl.INFO_EFFECTIVE_URL)
	end
	c:close()

	if err then
		return nil, tostring(err)
	else
		return data, nil
	end



end

function onSearch(key,page)
	local url = "http://m.pansoso.com/zh/"..pd.urlEncode(key).."_"..page
	local result = {}
	local start = 1
	local p_start,p_end,title,href,sharer,time,description
	local data = request({url=url})
	p_start,start = string.find(data,'<div id="con">')
	while true do
		p_start,p_end,href,title,fileSize,sharer,time=string.find(data,'<a href="(.-)" .-<div class="des">文件名:(.-) , 文件大小:(.-) , 分享者:(.-) , 分享时间:(.-) ,',start)

		if not href then
			pd.logInfo("no href:..")
			break
		end


		href = "http://m.pansoso.com"..href
		local tooltip = string.gsub(title, key, "%1")
		title = string.gsub(title,key, "{c #ff0000}%1{/c}")
		description = "文件大小："..fileSize.."  ".."分享者："..sharer

		--pd.logInfo("title:.."..title)
		table.insert(result,{["href"]=href, ["title"]=title, ["time"]=time, ["showhtml"] = "true", ["tooltip"] = tooltip, ["description"] = description})

		start = p_end + 1

	end

	return result
end

function onItemClick(item)
	local url = getUrl(item.href)
	if url then
		return ACT_SHARELINK,url
	else
		return ACT_ERROR,"获取链接失败"
	end

end

function getUrl(href)
	--pd.logInfo(href)
	local data = request({url=href})
	local baiduPan_url,url,p_start,p_end
	--pd.logInfo("data:"..data)
	p_start,p_end,url = string.find(data,'id="down_button_link".-href="(.-)"')
	--pd.logInfo("url:"..url)
	if url then
		data = request({url=url,referer=href})
		p_start,p_end,url = string.find(data,'href="http://to.pansoso.com/(.-)"')
		url = "http://to.pansoso.com/"..url
		-- <a rel="noreferrer external nofollow" href="http://to.pansoso.com/?url=/sH%2B3Bhh4Zf31%2BDdACzW9lEj0rO71My2yKLmhVVv7I7%2B3P6GGHbhiPfJ4MgAcNb2UWLSo7vXzMjI9uaFVUDsuv7C/ukYWuGh9/Pg3wB71pRRHNKiu%2BLM3Mio5pJVVw==&a=f4ZsK
		--：<a rel="noreferrer external nofollow" class="btn-download" target="_self" id="ceef3a87" href="http://to.pansoso.com/?url=/sH%2B3Bhh4Zf31%2BDdACzW9lEj0rO71My2yKLmhVVv7I7%2B3P6GGHbhiPfJ4MgAcNb2UWLSo7vXzMjI9uaFVUDsuv7C/ukYWuGh9/Pg3wB71pRRHNKiu%2BLM3Mio5pJVVw==&a=Mo8dA">
		--pd.logInfo("url:"..url)
		if url then
			p_start,p_end,baiduPan_url = string.find(request({url=url,method="HEAD"}),"Location:(.-)\n")
			--pd.logInfo("baiduPan_url:"..baiduPan_url)
		end

	end
	--pd.logInfo("baiduPan_url:"..baiduPan_url)
	return baiduPan_url
end

