local AIClient = loadstring(game:HttpGet("https://raw.githubusercontent.com/riddance-club/riddance-ai/refs/heads/main/dependencies/AIClient.lua"))()
local processCommand = loadstring("https://raw.githubusercontent.com/riddance-club/riddance-ai/refs/heads/main/dependencies/Commands.lua")()

local ai_settings = getgenv() and getgenv().riddance_ai
if not ai_settings then
	error("You have not set up your Riddance AI settings.")
end

local bot = AIClient.new(ai_settings.ApiKey, ai_settings.Model, settings.Url)
local reply = ai_settings.Prompt
local end_result

while task.wait(ai_settings.Delay) do
	local response = bot:Ask(reply)
	if response then
		print("User:", reply)
		local process = processCommand(response)
		if not process then
			end_result = response
			break
		else
			reply = process
		end
	else
		error("Failed to get a response.")
	end
end

ai_settings.Callback(end_result)