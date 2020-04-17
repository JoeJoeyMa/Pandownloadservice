local curl = require "lcurl.safe"
local json = require "cjson.safe"


script_info = {
	["title"] = "蓝奏云",
	["version"] = "0.0.1",
	["description"] = "解析蓝奏云分享链接获取下载直链并下载",
}

function easyRequest(url,header)
	local r = ""
	local c = curl.easy{
		url = url,
		httpheader = header or {"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36"},
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

function expertRequest(method, url, para, header)
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
	else
		c:setopt(curl.OPT_HTTPHEADER, {"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36"})
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

function onSearch(url, page)
	result = {}
	local data = getLIst(url,page)
	pd.logInfo("data")
	if data then
		for i, v in ipairs(data) do
			--pd.logInfo(v["url"])
			url = v["url"]
			--pd.logInfo(url)
			getSingle(url)

		end
	else
		getSingle(url)
	end

	return result

end

function onItemClick(item)
	url = item.url
	pd.logInfo(url)
	if pd.addUri then
		pd.addUri(url, {["out"] = item.title})
		return ACT_MESSAGE, "已添加到下载列表"
	else
		return ACT_DOWNLOAD, url
	end
end

function getDownloadUrlWithoutPwd(link,ret)
	local header,p_strat,p_end,fileId,url,para,zt,dom,inf,sign
	p_strat,p_end,fileName,fileSize,updataTime = string.find(ret,'<div class="b">(.-)</div>.-文件大小：</span>(.-)<br>.-<span class="p7">上传时间：</span>(.-)<br>')
	--pd.logInfo("p_strat"..p_strat)
	--pd.logInfo("p_end"..p_end)
	--pd.logInfo("fileName"..fileName)
	--pd.logInfo("fileSize"..fileSize)
	--pd.logInfo("updataTime"..updataTime)


	header = {
		"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36","referer: ".. link
	}
	pd.logInfo("ret:"..ret)
	pd.logInfo("link:"..link)
	p_strat,p_end,fileId = string.find(ret,'class="ifr2".-<iframe class="ifr2".-src="(.-)"')
	pd.logInfo("fileId:"..fileId)
	url = "https://www.lanzous.com" .. fileId
	ret = easyRequest(url,header)
	p_strat,p_end,sign = string.find(ret,"'sign':'(.-)'")
	para = "action=downprocess&sign="..sign
	header = {
		"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36","referer: ".. url
	}
	url = "https://www.lanzous.com/ajaxm.php"
	ret = expertRequest("POST",url,para,header)

	ret = json.decode(ret)

	zt = ret["zt"]
	dom = ret["dom"]
	url = ret["url"]
	inf = ret["inf"]

	--p_strat,p_end,zt,dom,url,inf = string.find(ret,'"zt":(.-),"dom":"(.-)","url":"(.-)","inf":(.-)}')
	--pd.logInfo("zt"..zt)
	--pd.logInfo("dom"..dom)
	--pd.logInfo("url"..url)
	--pd.logInfo("inf"..inf)
	if zt ~= "0" then
		url = string.gsub(dom,"\\","") .. "/file/" .. url
		url = string.gsub(url,"\\","")
		--pd.logInfo("URL："..url)
		header = {
			"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36","Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,,application/signed-exchange;v=b3" ,"Accept-Encoding: gzip, deflate, br" ,"Accept-Language: zh-CN,zh;q=0.9,en;q=0.8,et;q=0.7,de;q=0.6"
		}
		ret = expertRequest("HEAD",url,nil,header)

		p_strat,p_end,url = string.find(ret,'Location: (.-)\n')
		table.insert(result,{["title"]=fileName,["time"]=updataTime,["fileSize"]=fileSize,["url"]=url})
		--pd.logInfo(url)
	end

	return result
end

function getDownloadUrlWithPwd(link,ret,pwd)
	local header,p_strat,p_end,url,para,zt,dom,inf

	p_strat,p_end,updataTime = string.find(ret,"<span class=\"n_file_infos\">(.-)</span>")
	p_strat,p_end,fileSize = string.find(ret,"<div class=\"n_filesize\">大小：(.-)</div>")
	p_strat,p_end,para = string.find(ret,"data : '(.-)'")
	--pd.logInfo("updataTime:"..updataTime)
	--pd.logInfo("fileSize:"..fileSize)
	--pd.logInfo("para:"..para)
	header = {"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36","referer: ".. link}
	url = "https://www.lanzous.com/ajaxm.php"
	ret = expertRequest("POST",url,para..pwd,header)
	ret = json.decode(ret)

	zt = ret["zt"]
	dom = ret["dom"]
	url = ret["url"]
	inf = ret["inf"]
	--p_strat,p_end,zt,dom,url,inf = string.find(ret,'"zt":(.-),"dom":"(.-)","url":"(.-)","inf":(.-)}')
	--pd.logInfo("zt"..zt)
	--pd.logInfo("dom"..dom)
	--pd.logInfo("url"..url)
	--pd.logInfo("inf"..inf)
	pd.logInfo(zt)
	if inf == "密码不正确" then
		pd.logInfo("密码错误")
		return inf
		--return inf
	else
		fileName = inf
		url = string.gsub(dom,"\\","") .. "/file/" .. url
		url = string.gsub(url,"\\","")
		--pd.logInfo("url:"..url)
		header = {
			"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36","Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,,application/signed-exchange;v=b3" ,"Accept-Encoding: gzip, deflate, br" ,"Accept-Language: zh-CN,zh;q=0.9,en;q=0.8,et;q=0.7,de;q=0.6"
		}
		ret = expertRequest("HEAD",url,nil,header)
		--pd.logInfo(ret)
		p_strat,p_end,url = string.find(ret,'Location: (.-)\n')
		--pd.logInfo("p_strat"..p_strat)
		--pd.logInfo("p_end"..p_end)
		--pd.logInfo("url"..url)
		--fileName = utf8.char(fileName)
		table.insert(result,{["title"]=fileName,["time"]=updataTime,["fileSize"]=fileSize,["url"]=url})
		return result
	end
end

function getLIst(link,page)

	if not page then
		page = 1
	end

	if string.find(link,"(.-)%W-密码%W+(.-)") then

		local p_strat,p_end
		p_strat,p_end,link,pwd = string.find(link,"(.-)%W-密码%W+(.*)")
		pd.logInfo(link.." "..pwd)
	end


	local p_strat,p_end,t,k,pg,lx,fid,uid,rep,up,ls,header,ret,t_name,k_name
	ret = easyRequest(link)
	-- 不是列表集合
	if not string.find(ret,"filemoreajax") then
		return nil
	end
	--pd.logInfo(ret)

	url = "https://www.lanzous.com/filemoreajax.php"
	header = {
		"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36","referer: ".. link
	}
	p_strat,p_end,t_name,k_name = string.find(ret,"'t':(.-),.-'k':(.-),")
	if string.find(ret,"输入密码") then
		if not pwd then
			pwd = pd.input("链接"..link.."密码：")
		end

		p_strat,p_end,t,k,lx,fid,uid,rep,up,ls = string.find(ret,"var "..t_name.." = '(.-)';.-var "..k_name.." = '(.-)';.-data :.-'lx':(.-),.-'fid':(.-),.-'uid':'(.-)',.-'rep':'(.-)',.-'up':(.-),.-'ls':(.-),",1)
		para = "lx="..lx.."&fid="..fid.."&uid="..uid.."&pg="..page.."&rep="..rep.."&t="..t.."&k="..k.."&up="..up.."&ls="..ls.."&pwd="..pwd

	else
		p_strat,p_end,t,k,lx,fid,uid,rep,up = string.find(ret,"var "..t_name.." = '(.-)';.-var "..k_name.." = '(.-)';.-data :.-'lx':(.-),.-'fid':(.-),.-'uid':'(.-)',.-'rep':'(.-)',.-'up':(.-),",1)
		para = "lx="..lx.."&fid="..fid.."&uid="..uid.."&pg="..page.."&rep="..rep.."&t="..t.."&k="..k.."&up="..up

	end



	ret = expertRequest("POST",url,para,header)
	--pd.logInfo(para)
	--pd.logInfo(ret)
	ret = json.decode(ret)
	local result = {}
	local title,size,time,url
	if ret["info"] == "sucess" then
		for i, v in ipairs(ret["text"]) do
			--pd.logInfo(i)
			title = v["name_all"]
			size = v["size"]
			time = v["time"]
			url = "https://www.lanzous.com/" .. v["id"]
			table.insert(result,{["url"] = url, ["title"] = title,["size"] = size,["time"] = time})

		end
	end
	return result
end

function getSingle(url)

	local ret,header,p_strat,p_end,pwd

	if string.find(url,"(.-)%W-密码%W+(.-)") then
		p_strat,p_end,url,pwd = string.find(url,"(.-)%W-密码%W+(.*)")
	end

	ret = easyRequest(url)

	if string.find(ret,"输入密码") then
		--pd.logInfo("需要输入密码")
		if pwd == nil then
			pwd = pd.input("链接"..url.."密码:")
		end

		getDownloadUrlWithPwd(url,ret,pwd)
		if result == "密码不正确" then
			return ERROR, "密码错误"
		end
	else
		--pd.logInfo("不需要输入密码")
		getDownloadUrlWithoutPwd(url,ret)
	end
	return result
end



