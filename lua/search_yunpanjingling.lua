local curl = require "lcurl.safe"
local json = require "cjson.safe"

script_info = {
	["title"] = "云盘精灵",
	["description"] = "https://www.yunpanjingling.com/",
	["version"] = "0.0.1",
}

function onSearch(key, page)
	return parse(get("https://www.yunpanjingling.com/search/" .. urlEncode(key) .. "?page=" .. page))
end

function onItemClick(item)
	local act = ACT_SHARELINK
	local arg = ""
	local j = json.decode(get(item.url))
	if j and j.pid then
		arg = "https://pan.baidu.com/s/1" .. j.pid
		if j.access_code and j.access_code ~= json.null then
			arg = arg .. " " .. j.access_code
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
	local _, e = c:perform()
	c:close()
	return r
end

function parse(data)
	local result = {}
	local start = 1
	while true do
		local a, b, url, title, time = string.find(data, "<div class=\"item\" data%-id=\"(.-)\".-<div class=\"name\">(.-)</div>.-<use xlink:href=\"#icon%-share\">.-&nbsp;(.-)</span>", start)
		if url == nil then
			break
		end
		title = string.gsub(title, "^%s*(.-)%s*$", "%1", 1)
		time = string.gsub(time, "^%s*(.-)%s*$", "%1", 1)
		local tooltip = string.gsub(title, "<em>(.-)</em>", "%1")
		title = string.gsub(title, "<em>(.-)</em>", "{c #ff0000}%1{/c}")
		table.insert(result, {["url"] = "https://www.yunpanjingling.com/resources/" .. url, ["title"] = title, ["time"] = time, ["showhtml"] = "true", ["tooltip"] = tooltip})
		start = b + 1
	end
	return result
end

function urlEncode(s)
	return (string.gsub(
		s,
		"[^%w%-_%.!~%*'%(%)]",
		function(c)
			return string.format("%%%02X", string.byte(c))
		end
	))
end