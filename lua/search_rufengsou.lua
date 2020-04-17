local curl = require "lcurl.safe"

script_info = {
	["title"] = "如风搜",
	["description"] = "http://www.rufengso.net/; 搜索框输入:config设置是否过滤失效链接",
	["version"] = "0.0.4",
}


function request(url)
	local r = ""
	local c = curl.easy{
		url = url,
		httpheader = {
			"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36",
		},
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


	local data =  request("http://www.rufengso.net/s/name/" .. pd.urlEncode(key) .. "/" .. page)
	local result = {}
	local start = 1
	if page == 1 then
		local count
		_,__,count = string.find(data,'<h1 class="inline">.-</h1>.-<span.->(.-)</span>')
		table.insert(result, { ["time"] = "找到约 "..count.." 条数据",  ["enabled"] = "false",["showhtml"] = "true"})
	end

	while true do
		local fileType
		local start_position, end_position, title, href = string.find(data,"<div class=\"row\".-title=\"(.-)\" href=\"(.-)\">",start)

		if href == nil then
			break
		end
		href = "http://www.rufengso.net" .. href


		local filtration = pd.getConfig("mp4吧","filtration")
		if filtration == "yes" then
			url = getUrl(href)
		else
			url = nil
		end


		table.insert(result,{["title"]=title,["href"]=href,["url"]=url, ["image"] = "icon/FileType/Middle/"..getFiletype(title), ["icon_size"] = "32,32",["check_url"] = "true"})
		start = end_position + 1
	end

	return result

end

function onItemClick(item)
	if item.isConfig then
		if item.isSel == "1" then
			return ACT_NULL
		else
			pd.setConfig("如风搜", item.key, item.val)
			return ACT_MESSAGE, "设置成功! (请手动刷新页面)"
		end
	end

	local url = item.url or getUrl(item.href)
	if url == nil then
		return ACT_MESSAGE, '获取URL失败'
	end

	return ACT_SHARELINK, url

end

function getUrl(url)
	local ret = request(url)
	local _, __, href = string.find(ret,'class="dbutton2" href="(.-)"',1)

	ret = request(href)
	_,__,url = string.find(ret, "URL='(.-)'")
	return url
end

function getFiletype(fileName)
	local fileType
	local map = {
		["apk"] = "ApkType.png",
		["Apps"] = "ApksType.png",
		["cad"] = "CadType.png",
		["doc"] = "DocType.png",
		["exe"] = "ExeType.png",
		["folder"] = "FolderType.png",
		["jpg"] = "ImgType.png",
		["ipad"] = "IpadType.png",
		["music"] = "MusicType.png",
		["mp3"] = "MusicType.png",
		["flac"] = "MusicType.png",
		["ape"] = "MusicType.png",
		["pdf"] = "PdfType.png",
		["ppt"] = "PptType.png",
		["zip"] = "RarType.png",
		["rar"] = "RarType.png",
		["7z"] = "RarType.png",
		["torrent"] = "TorrentType.png",
		["txt"] = "TxtType.png",
		["video"] = "VideoType.png",
		["mp4"] = "VideoType.png",
		["mkv"] = "VideoType.png",
		["avi"] = "VideoType.png",
		["rmvb"] = "VideoType.png",
		["vsd"] = "VsdType.png",
		["xls"] = "XlsType.png",
	}

	for i, v in pairs(map) do
		pd.logInfo(i)
		if string.find(fileName,"%."..i) then
			fileType = v
			break
		elseif not string.find(fileName,"%.(%a-)[34]$") then
			fileType = "FolderType.png"
			break
		else
			fileType = "OtherType.png"
		end
	end

	 return fileType

end

function setConfig()
	local config = {}
	local filtration = pd.getConfig("如风搜","filtration")
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