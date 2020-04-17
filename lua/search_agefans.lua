﻿local curl = require "lcurl.safe"

script_info = {
	["title"] = "AGE动漫",
	["description"] = "https://donghua.agefans.com/",
	["version"] = "0.0.3",
}

function onSearch(key, page)
	return parse(get("https://donghua.agefans.com/search?page=" .. page .. "&query=" .. pd.urlEncode(key)))
end

function onItemClick(item)
	local act = ACT_SHARELINK
	local data = get(item.url)
	local _, _, arg = string.find(data, "<a class=\"res_links_a\" href=\"(.-)\"")
	if arg then
		arg = getEffectiveUrl("https://donghua.agefans.com" .. arg)
		local _, _, pwd = string.find(data, "<span class=\"res_links_pswd\".-(%w%w%w%w).-</span>")
		if pwd then
			arg = arg .. " " .. pwd
		end
	end
	if arg == nil or #arg == 0 then
		act = ACT_ERROR
		arg = "获取链接失败"
	end
	return act, arg 
end

function get(url)
	local r = ""
	local c = curl.easy{
		url = url,
		followlocation = 1,
		timeout = 15,
		proxy = pd.getProxy(),
		ssl_verifyhost = 0,
		ssl_verifypeer = 0,
		writefunction = function(buffer)
			r = r .. buffer
			return #buffer
		end,
	}
	c:perform()
	c:close()
	return r
end

function getEffectiveUrl(url)
	local c = curl.easy{
		url = url,
		nobody = 1,
		followlocation = 1,
		timeout = 15,
		proxy = pd.getProxy(),
		ssl_verifyhost = 0,
		ssl_verifypeer = 0,
	}
	c:perform()
	local ret = c:getinfo(curl.INFO_EFFECTIVE_URL)
	c:close()
	if ret == url then
		ret = ""
	end
	return ret
end

function parse(data)
	local result = {}
	local start = 1
	while true do
		local a, b, img, id, title, time, description = string.find(data, "<img width=\"150px\".-src=\"(.-)\".-<a href=\"/detail/(%d+)\" class=\"cell_imform_name\">(.-)</a>.-首播时间.-<spa.->(.-)</span>.-cell_imform_desc\">(.-)</div>", start)
		if id == nil then
			break
		end
		title = string.gsub(title, "^%s*(.-)%s*$", "%1", 1)
		time = string.gsub(time, "^%s*(.-)%s*$", "%1", 1)
		description = string.gsub(description, "^%s*(.-)%s*$", "%1", 1)
		table.insert(result, {["url"] = "https://donghua.agefans.com/detail/" .. id, ["title"] = pd.htmlUnescape(title), ["image"] = "https:"..img, ["icon_size"] = "48,67", ["time"] = time, ["description"] = pd.htmlUnescape(description)})
		start = b + 1
	end
	return result
end