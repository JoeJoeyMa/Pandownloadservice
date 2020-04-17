local curl = require "lcurl.safe"
local json = require "cjson.safe"


script_info = {
	["title"] = "58网盘",
	["version"] = "0.0.2",
	["description"] = "输入:config可以设置默认排序方式",
}

function request(args)

	local cookie = args.cookie or ""
	local referer = args.referer or ""
	--pd.logInfo("the cccc..:"..cookie)
	local header = args.header or {"User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36","Cookie: "..cookie,"Referer: "..referer}
	--pd.logInfo("header cookie:"..header[2])
	local method = args.method or "GET"
	local para = args.para
	local url = args.url
	local data = ""

	local c = curl.easy{
		url = url,
		ssl_verifyhost = 0,
		ssl_verifypeer = 0,
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
	if key == ":config" and page == 1 then
		return setSort()
	end

	local url = "https://www.58wangpan.com/search/"..getSort().."kw"..pd.urlEncode(key).."pg"..page

	local result = {}
	local start = 1
	local p_start,p_end,title,href,fileType,time
	local data = request({url=url})
	while true do
		p_start,p_end,fileType,href,title,time=string.find(data,'<i class="file%-icon i(.-)"></i>.-<div class="title"><a href="(.-)" title=".-" target="_blank" >(.-)</a></div>.-<div class="feed_time"><span>(.-)</span></div>',start)

		if not href then
			pd.logInfo("no href:..")
			break
		end

		--pd.logInfo("href:"..href)
		--pd.logInfo("title:"..title)
		--pd.logInfo("singer:"..singer)
		--pd.logInfo("songstype:"..songstype)
		--pd.logInfo("fileSize:"..fileSize)
		--pd.logInfo("time:"..time)


		href = "https://www.58wangpan.com"..href
		--local img = "https://www.58wangpan.com/images/"..fileType..".png"
		local tooltip = string.gsub(title, '<font color="red" >(.-)</font>', "%1")
		title = string.gsub(title,'<font color="red" >(.-)</font>', "{c #ff0000}%1{/c}")
		--pd.logInfo("title:.."..title)
		table.insert(result,{["href"]=href, ["title"]=title, ["time"]=time, ["showhtml"] = "true", ["tooltip"] = tooltip, ["image"] = "icon/FileType/Middle/"..getFiletype(fileType), ["icon_size"] = "16,16"})

		start = p_end + 1

	end

	return result
end

function onItemClick(item)

	if item.isConfig then
		if item.isSel == "1" then
			return ACT_NULL
		else
			pd.setConfig("58网盘", item.key, item.val)
			return ACT_MESSAGE, "设置成功! (请手动刷新页面)"
		end
	end



	local url = getUrl(item.href)
	if url then
		return ACT_SHARELINK,url
	else
		return ACT_ERROR,"获取链接失败"
	end

end

function getUrl(href)
	local data = request({url=href})
	local baiduPan_url,url
	--pd.logInfo("data:"..data)
	local p_start,p_end,fileID = string.find(data,"dialog_fileId = '(.-)'")
	if fileID then
		url = "https://www.58wangpan.com/redirect/file?id="..fileID
		data = request({url=url,referer=href})
		p_start,p_end,baiduPan_url = string.find(data,"var url = '(.-)'")
	end
	--pd.logInfo("baiduPan_url:"..baiduPan_url)
	return baiduPan_url
end

function getFiletype(fileType)

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
		["pdf"] = "PdfType.png",
		["ppt"] = "PptType.png",
		["zip"] = "RarType.png",
		["torrent"] = "TorrentType.png",
		["txt"] = "TxtType.png",
		["video"] = "VideoType.png",
		["vsd"] = "VsdType.png",
		["xls"] = "XlsType.png",








	}
	 return map[fileType] or "OtherType.png"

end

function setSort()
	local config = {}
	local sortType = pd.getConfig("58网盘","sortType")
	table.insert(config, {["title"] = "排序方式", ["enabled"] = "false"})
	table.insert(config, createConfigItem("默认排序", "sortType", "default", #sortType == 0 or sortType == "default"))
	table.insert(config, createConfigItem("最新分享文件", "sortType", "newest", sortType == "newest"))
	table.insert(config, createConfigItem("高清大文件", "sortType", "high definition", sortType == "high definition"))
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

function getSort()
	local sort
	local sortType = pd.getConfig("58网盘","sortType")
	if sortType == "newest" then
		sort = "o1m1"
	elseif sortType == "high definition" then
		sort = "o2m1"
	else
		sort = "m1"
	end
	return sort
end