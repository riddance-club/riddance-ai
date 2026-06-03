local HttpService = game:GetService("HttpService")
local ReflectionService = game:GetService("ReflectionService")

local function resolvePath(path) -- string like "game.Workspace.Terrain"
    local code = "return " .. path
    local success, func = pcall(loadstring, code)
    if success and type(func) == "function" then
        local execSuccess, result = pcall(func)
        if execSuccess and typeof(result) == "Instance" then
            return result
        end
    end
    return nil
end

local function getPathWithService(instance) -- ai is so fucking stupid so i have to keep reminding it in some way to not use it directly just because the output gives it like that
    if typeof(instance) ~= "Instance" then return "" end
    if instance == game then return "game" end
    local path = {}
    local current = instance
    while current and current ~= game do
        if current.Parent == game then
            table.insert(path, 1, 'game:GetService("' .. current.ClassName .. '")')
        else
            if string.match(current.Name, "^[%a_][%w_]*$") then
                table.insert(path, 1, "." .. current.Name)
            else
                local safeName = string.gsub(current.Name, '"', '\\"')
                table.insert(path, 1, '["' .. safeName .. '"]')
            end
        end
        current = current.Parent
    end
    return table.concat(path, "")
end

local commands = {
    ["getchildren"] = function(path)
        local tbl = {}
        local resolvedPath = resolvePath(path)
        if resolvedPath then
            for _, v in resolvedPath:GetChildren() do
                table.insert(tbl, {getPathWithService(v), v.ClassName})
            end
        end
        local encoded = HttpService:JSONEncode(tbl)
        return encoded
    end,

    ["getallinstances"] = function(path, target, search)
        local tbl = {}
        local resolvedPath = resolvePath(path)
        if resolvedPath then
            for _, v in resolvedPath:GetDescendants() do
                if v:IsA(target) and (not search or v.Name:find(search)) then
                    table.insert(tbl, getPathWithService(v))
                end
            end
        end
        local encoded = HttpService:JSONEncode(tbl)
        return encoded
    end,

    ["getproperties"] = function(path) -- works but holy shit how bloated this code is just to avoid AI having excess properties
        local resolvedPath = resolvePath(path)
        if resolvedPath then
            local propertiesInfo = ReflectionService:GetPropertiesOfClass(resolvedPath.ClassName)
            local propertyTable = {}
            if propertiesInfo then
                for _, propData in ipairs(propertiesInfo) do
                    local propName = propData.Name
                    local firstChar = string.sub(propName, 1, 1)
                    local isLegacyAlias = (firstChar == string.lower(firstChar) and firstChar ~= string.upper(firstChar))
                    local isHidden = false
                    if propData.Tags then
                        for _, tag in ipairs(propData.Tags) do
                            if tag == "Hidden" or tag == "Deprecated" then
                                isHidden = true
                                break
                            end
                        end
                    end
                    if not isHidden and not isLegacyAlias then
                        local success, value = pcall(function()
                            return resolvedPath[propName]
                        end)
                        if success and value ~= nil then
                            local valType = typeof(value)
                            local processedValue
                            if valType == "string" or valType == "number" or valType == "boolean" then
                                processedValue = value
                            elseif valType == "EnumItem" then
                                processedValue = value.Name
                            elseif valType == "Instance" then
                                processedValue = getPathWithService(value)
                            else 
                                processedValue = tostring(value)
                            end
                            if processedValue ~= "" then
                                propertyTable[propName] = processedValue
                            end
                        end
                    end
                end
            end
            local success, json = pcall(function()
                return HttpService:JSONEncode(propertyTable)
            end)
            return success and json or "Failed to get property list."
        end
        return "Failed to get instance at path."
    end,

    ["decompile"] = function(path)
        local resolvedPath = resolvePath(path)
        if resolvedPath then
            if resolvedPath:IsA("LocalScript") or resolvedPath:IsA("ModuleScript") then
                return decompile(resolvedPath)
            end
            return "Instance is not a LocalScript or ModuleScript. Unable to decompile."
        end
        return "Failed to get instance at path."
    end
}

return function(input)
    print("AI:", input)
    if not input:find("^!") then return end
    local words = {}
    for word in input:sub(2):gmatch("%S+") do
        table.insert(words, word)
    end
    local commandName = table.remove(words, 1):lower()
    local commandFunc = commands[commandName]
    if commandFunc then
        return commandFunc(unpack(words))
    else
        warn("AI might have tried to trigger a non existent command:", commandName)
    end
    return "Failed to process command."
end
