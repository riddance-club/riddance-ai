local HttpService = game:GetService("HttpService")
local SystemPrompt = game:HttpGet("https://raw.githubusercontent.com/riddance-club/riddance-ai/refs/heads/main/dependencies/SystemPrompt.txt")

if not request then
    error("Your client does not support the request function.")
end

local AIClient = {}
AIClient.__index = AIClient

function AIClient.new(apiKey, model, url)
    local self = setmetatable({}, AIClient)
    self.Key = apiKey
    self.Model = model
    self.Url = url
    self.History = {
        { role = "system", content = SystemPrompt }
    }
    return self
end

function AIClient:Ask(UserPrompt)
    table.insert(self.History, { role = "user", content = UserPrompt })

    local response = request({
        Url = self.Url,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. self.Key
        },
        Body = HttpService:JSONEncode({
            model = self.Model,
            messages = self.History,
            temperature = 0.7
        })
    })

    if response.StatusCode == 200 then
        local data = HttpService:JSONDecode(response.Body)
        local aiMessage = data.choices[1].message
        table.insert(self.History, aiMessage)
        return aiMessage.content
    else
        warn("API Error: " .. response.StatusCode .. " - " .. response.Body)
        return nil
    end
end

function AIClient:Reset()
    local system = self.History[1]
    self.History = { system }
end

return AIClient
