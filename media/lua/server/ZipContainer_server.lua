local main = require 'ZipContainer_client'

if not isServer() then return end

---@alias whiteListType table<string, boolean>
---@type whiteListType?
local whiteListArr = nil

---@return table
local function LoadJsonItems()
    local filename = SandboxVars.ZipContainer.WhiteListJsonFileName or 'ZipContainer_WhiteList.json'
    local fileReaderObj = getFileReader(filename, false)
    if fileReaderObj then 
        print("ZipContainer: " .. filename .. " file load successfully")
    else
        print("ZipContainer: " .. filename .. " file is empty or does not exist")
    end

    local json = ""
    local line = fileReaderObj:readLine()
    while line ~= nil do
        json = json .. line
        line = fileReaderObj:readLine()
    end
    fileReaderObj:close()

    local resulTable = {}
    if json and json ~= "" then
        resulTable = Json.Decode(json);
    end
    return resulTable
end

---@return whiteListType
local function getWhiteListArr()
    if whiteListArr then
        return whiteListArr
    end

    ---@type string
    local whiteListStr = SandboxVars.ZipContainer.WhiteList
    whiteListArr = {}
    if whiteListStr then
        local str = string.gsub(whiteListStr, "%s+", "")
        local arr = luautils.split(str, ',')
        for _, type in pairs(arr) do
            whiteListArr[type] = true
        end
    end
    local whiteListJson = LoadJsonItems()
    for _, type in pairs(whiteListJson) do
        whiteListArr[type] = true
    end
    return whiteListArr
end

Events.OnServerStarted.Add(getWhiteListArr)

local commands = {}
commands.getWhiteList = function(player, args)
    --print('whiteListArr', whiteListArr)
    sendServerCommand(main.MOD_NAME, "onGetWhiteList", {whiteListArr = getWhiteListArr()})
end
commands.refreshWhiteList = function(player, args)
    whiteListArr = nil
    commands.getWhiteList(player, args)
end

local function shopItems_OnClientCommand(module, command, player, args)
    if module == main.MOD_NAME and commands[command] then
        commands[command](player, args)
    end
end

Events.OnClientCommand.Add(shopItems_OnClientCommand)