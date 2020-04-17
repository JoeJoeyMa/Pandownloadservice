local curl = require "lcurl.safe"

script_info = {
	["title"] = "MP4吧",
	["description"] = "http://www.mp4ba.com/",
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

	local header = {
		"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36",
	}

	local data = request("http://m.mp4ba.com/mobile/index/search/q/" .. pd.urlEncode(key) .. "/page/" .. page .. ".html" , header)
	local result = {}
	local start = 1

	while true do

		local start_position, end_position, href, title, pub_time = string.find(data,'<li><a href="(.-)">(.-)</a><span>(.-)</span></li>',start)

		if href == nil then
			break
		end

		local tooltip = string.gsub(title, "<i style='color:#f60;'>(.-)</i>", "%1")

		title = string.gsub(title, "<i style='color:#f60;'>(.-)</i>", "{c #ff0000}%1{/c}")

		table.insert(result, {["href"] = href  , ["title"] = title,["showhtml"] = "true", ["tooltip"] = tooltip, ["time"] = pub_time,  })

		start = end_position + 1

	end

	return result


end

function onItemClick(item)

	local header = {
		"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36",
	}

	local ret = request(item.href,header)

	local _, __, url, pwd = string.find(ret,'<div class="weui%-cell__ft">.-<a href="(.-)" target="_blank" class="weui%-btn weui%-btn_mini bg%-orange">.-<a href="javascript:;" class="weui%-btn weui%-btn_mini code">(.-)</a>.-</div>',1)

	if url ~= nil then
		if pwd ~= nil then
			pwd = string.gsub(pwd, "提取码：", "")
			url = url .. " " .. pwd
		end
		return ACT_SHARELINK, url
	else
		return ACT_MESSAGE, "获取百度云链接失败"
	end

end
