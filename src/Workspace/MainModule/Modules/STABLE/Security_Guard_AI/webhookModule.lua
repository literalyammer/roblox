local module = {}

local https = game:GetService("HttpService")

module.sendMsg = function(username, message, pfp, embed, webhookUrl)
	local data
	if not embed then
		data = {
			['username'] = username,
			['content'] = message,
			['avatar_url'] = pfp,
		}
	elseif embed then
		data = {
			['username'] = username,
			['avatar_url'] = pfp,
			['embeds'] = embed
		}
	end
	https:PostAsync(webhookUrl, https:JSONEncode(data))
end

return module