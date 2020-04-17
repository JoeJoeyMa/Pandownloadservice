local curl = require "lcurl.safe"
local json = require "cjson.safe"

script_info = {
	["title"] = "爱搜资源",
	["description"] = "https://www.aisouziyuan.com/",
	["version"] = "0.0.4",
}

function onSearch(key, page)
	local data = ""
	local c = curl.easy{
		url = "https://www.aisouziyuan.com/search",
		httpheader = {
			"Content-Type: application/x-www-form-urlencoded",
			"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.110 Safari/537.36",
		},
		post = 1,
		postfields = "keyWord=" .. urlEncode(key) .. "&pages=" .. page,
		ssl_verifyhost = 0,
		ssl_verifypeer = 0,
		timeout = 15,
		proxy = pd.getProxy(),
		writefunction = function(buffer)
			data = data .. buffer
			return #buffer
		end,
	}
	c:perform()
	c:close()
	return parse(data)
end

function onItemClick(item)
	return ACT_SHARELINK, item.url 
end

function parse(data)
	local result = {}
	local j = json.decode(data)
	if j == nil or j.body == nil or j.body == json.null then
		return result
	end
	for i, item in ipairs(j.body) do 
		local title = item["title"]
		local tooltip = string.gsub(title, "<b>(.-)</b>", "%1")
		title = string.gsub(title, "<b>(.-)</b>", "{c #ff0000}%1{/c}")
		table.insert(result, {["url"] = "https://pan.baidu.com/s/1" .. item["url"] .. " " .. item["password"], ["title"] = title, ["time"] = item["shareData"], ["showhtml"] = "true", ["tooltip"] = tooltip, ["check_url"] = "true"})
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