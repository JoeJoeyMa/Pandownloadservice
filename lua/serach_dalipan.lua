local curl = require "lcurl.safe"

script_info = {
	["title"] = "大力盘",
	["description"] = "https://www.dalipan.com/; 搜索框输入:config设置是否过滤失效链接",
	["version"] = "0.0.3",
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
	if key == ":config" and page == 1 then
		return setConfig()
	end
	local header = {
			"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36",
		}
		
	local data = request("https://www.dalipan.com/search?keyword=" .. pd.urlEncode(key) .. "&page=" .. page, header)
	local result = {}
	local start = 1
	if page == 1 then
		local p_start,p_end,count = string.find(data,'<p class="tip".-><span .-class="em" .->(.-)</span>')
		table.insert(result, { ["time"] = "找到约 "..count.." 条数据",  ["enabled"] = "false",["showhtml"] = "true"})
	end
	while true do
	
		local a, b, img, id, title, time = string.find(data, '<div class="resource%-item"><img src="(.-)".-<a href="/detail/(.-)" target="_blank" class="valid">(.-)</a>.-<p class="time">(.-)</p>', start)
			
		if id == nil then
			break
		end
			
		--title = string.gsub(title, "^%s*", "", 1)
		local tooltip = string.gsub(title, "<mark>(.-)</mark>", "%1")
		title = string.gsub(title, "<mark>(.-)</mark>", "{c #ff0000}%1{/c}")
		local url
		local filtration = pd.getConfig("大力盘","filtration")
		if filtration == "yes" then
			url = parseDetail(id)
		else
			url = nil
		end


		table.insert(result, {["id"] = id , ["title"] = title,  ["showhtml"] = "true", ["tooltip"] = tooltip, ["time"] = time, ["image"] = "https://dalipan.com" .. img, ["icon_size"] = "32,32", ["check_url"] = "true", ["url"]=url})
		-- table.insert(result, {["url"] = url .. " " .. pwd, ["title"] = title,  ["showhtml"] = "true", ["tooltip"] = tooltip, ["check_url"] = "true", ["time"] = time})
		start = b + 1
		
	end
	return result
end


function parseDetail(id)

		local deatil_url = "https://www.dalipan.com/detail/".. id
		header = {
			"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36",
			"referer: " .. deatil_url,
		}
		local image_url = "https://www.dalipan.com/images/recommand.png"
		request(image_url, header)
		local api_url = 'https://www.dalipan.com/api/private?id=' .. id
		local ret = request(api_url, header)
		local a, c, pwd, url = string.find(ret, '"pwd": "(.-)",.-"url": "(.-)"')
		
		return url .. " " .. pwd

end

function onItemClick(item)

	if item.isConfig then
		if item.isSel == "1" then
			return ACT_NULL
		else
			pd.setConfig("大力盘", item.key, item.val)
			return ACT_MESSAGE, "设置成功! (请手动刷新页面)"
		end
	end


	local url = item.url or parseDetail(item.id)
	return ACT_SHARELINK, url 
end

function setConfig()
	local config = {}
	local filtration = pd.getConfig("大力盘","filtration")
	table.insert(config, {["title"] = "过滤失效链接", ["enabled"] = "false"})
	table.insert(config, createConfigItem("不过滤失效链接", "filtration", "no", #filtration == 0 or filtration == "no"))
	table.insert(config, createConfigItem("过滤失效链接", "filtration", "yes",  filtration == "yes"))

	return config
end

function createConfigItem(title, key, val, isSel)
	local item = {}
	item.title = title
	item.key = key
	item.val = val
	item.icon_size = "14,14"
	item.isConfig = "1"
	if isSel then
		item.image = "option/selected.png"
		item.isSel = "1"
	else
		item.image = "option/normal.png"
		item.isSel = "0"
	end
	return item
end
