﻿local curl = require "lcurl.safe"
local json = require "cjson.safe"

script_info = {
	["title"] = "AGE动漫",
	["description"] = "https://www.agefans.tv/",
	["version"] = "0.0.7",
}

header = {"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.110 Safari/537.36"}

function onInitAnime()
	local data = get("https://www.agefans.tv/")
	_, _, data = string.find(data, "var new_anime_list = (.-);")
	if data == nil or #data == 0 then
		return
	end
	local j = json.decode(data)
	if j == nil then
		return
	end

	local anime_week = {
		{["title"] = "星期一"},
		{["title"] = "星期二"},
		{["title"] = "星期三"},
		{["title"] = "星期四"},
		{["title"] = "星期五"},
		{["title"] = "星期六"},
		{["title"] = "星期日"}
	}

	for _, item in ipairs(j) do 
		local anime_item = {}
		anime_item["url"] = "https://www.agefans.tv/detail/"..math.tointeger(item["id"])
		anime_item["name"] = item["name"]
		--anime_item["icon_size"] = "63,88"
		--anime_item["image"] = "https://www.agefans.tv/poster/" .. math.tointeger(item["id"]) .. ".jpg"
		local wd = item["wd"]
		if wd == 0 then
			wd = 7
		end
		if wd > 0 and wd <= 7 then
			table.insert(anime_week[wd], anime_item)
		end
	end
	return anime_week
end

function onSearch(key, page)
	local data = get("https://www.agefans.tv/search?page="..page.."&query="..pd.urlEncode(key))
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
		table.insert(result, {["url"] = "https://www.agefans.tv/detail/"..id, ["title"] = pd.htmlUnescape(title), ["image"] = "https:"..img, ["icon_size"] = "48,67", ["time"] = time, ["description"] = pd.htmlUnescape(description)})
		start = b + 1
	end
	return result
end

function onItemClick(item)
	local act = ACT_SHARELINK
	local data = get(item.url)
	local _, _, arg = string.find(data, "<a class=\"res_links_a\" href=\"(.-)\"")
	if arg then
		arg = getEffectiveUrl("https://www.agefans.tv"..arg)
		local _, _, pwd = string.find(data, "<span class=\"res_links_pswd\".-(%w%w%w%w).-</span>")
		if pwd then
			arg = arg.." "..pwd
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
		httpheader = header,
		ssl_verifyhost = 0,
		ssl_verifypeer = 0,
		followlocation = 1,
		timeout = 15,
		proxy = pd.getProxy(),
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
		httpheader = header,
		nobody = 1,
		ssl_verifyhost = 0,
		ssl_verifypeer = 0,
		followlocation = 1,
		timeout = 15,
		proxy = pd.getProxy(),
	}
	c:perform()
	local ret = c:getinfo(curl.INFO_EFFECTIVE_URL)
	c:close()
	if ret == url then
		ret = ""
	end
	return ret
end