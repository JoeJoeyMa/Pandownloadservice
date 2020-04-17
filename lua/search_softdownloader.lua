local curl = require "lcurl.safe"
local json = require "cjson.safe"

script_info = {
	["title"] = "软件下载器",
	["description"] = "http://soft.tinybad.cn/",
	["version"] = "0.0.1",
}

function request(url,header)
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
	local _, e = c:perform()
	c:close()
	return r
end

function onSearch(key, page)
	local data = ""
	local header = {
		"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36",
	}
	if page == 1 then
		sel = pd.choice({"腾讯软件源", "360软件源"}, 1, "请选择")
	end

	if sel == 2 then
		url = "http://soft.tinybad.cn/api/360Soft/" .. "?_provider=360" .. "&keyword=" .. pd.urlEncode(key) .."&num=30" .. "&page=" .. page

	elseif sel == nil then
		-- body
		return ACT_MESSAGE, '取消操作'
	else
		url = "http://soft.tinybad.cn/api/tencentSoft/" .. "?_provider=tencent" .. "&keyword=" .. pd.urlEncode(key) .."&num=30" .. "&page=" .. page
	end

local data = request(url, header)
	return parse(data)
end

function onItemClick(item)

	if pd.addUri then
		pd.addUri(item.url)
		return ACT_MESSAGE, "已添加到下载列表"
	else
		return ACT_DOWNLOAD, item.url
	end
end

function parse(data)
	local result = {}
	pd.logInfo(data)
	local j = json.decode(data)

	if j == nil  then
		return result
	end
	for i, item in ipairs(j) do 
		local title = item["softName"]
		local logo = item["logo"]
		local fileSize = item["fileSize"]
		local softDesc = item["softDesc"] or item["feature"]
		local updateTime = item["updateTime"]
		local versionName = item["versionName"]
		local tooltip = string.gsub(title, "<b>(.-)</b>", "%1")
		title = string.gsub(title, "<b>(.-)</b>", "{c #ff0000}%1{/c}")
		table.insert(result, {["url"] = item["downloadLink"], ["title"] = title, ["time"] = updateTime, ["showhtml"] = "true", ["tooltip"] = tooltip, ["image"] = logo, ["icon_size"] = "32,32", ["description"] = softDesc.."  文件大小:"..fileSize.."  版本号:"..versionName,})
	end
	return result
end

