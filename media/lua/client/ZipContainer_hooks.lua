local main = require 'ZipContainer_client'
local utils = require 'ZipContainer_utils'
local ZipContainer = main.ZipContainer

local ISInventoryPaneContextMenu_base = {
    -- onPutItems = ISInventoryPaneContextMenu.onPutItems
    isAnyAllowed = ISInventoryPaneContextMenu.isAnyAllowed
}

local ISInventoryPane_base = {
    transferItemsByWeight = ISInventoryPane.transferItemsByWeight,
    refreshContainer = ISInventoryPane.refreshContainer,
}
local ISInventoryPage_base = {
    selectContainer = ISInventoryPage.selectContainer,
    setMaxDrawHeight = ISInventoryPage.setMaxDrawHeight,
    clearMaxDrawHeight = ISInventoryPage.clearMaxDrawHeight,
}
local ISInventoryTransferAction_base = {
    new = ISInventoryTransferAction.new,
    perform = ISInventoryTransferAction.perform,
    transferItem = ISInventoryTransferAction.transferItem,
    isValid = ISInventoryTransferAction.isValid
}

local ISMoveableSpriteProps_base = {
    objectNoContainerOrEmpty = ISMoveableSpriteProps.objectNoContainerOrEmpty
}

local RecipeManager_base = {
    getAvailableItemsAll = RecipeManager.getAvailableItemsAll,
    getAvailableItemsNeeded = RecipeManager.getAvailableItemsNeeded,
    IsRecipeValid = RecipeManager.IsRecipeValid,
    getNumberOfTimesRecipeCanBeDone = RecipeManager.getNumberOfTimesRecipeCanBeDone
}

local PatchPane = {}
local PatchPaneContextMenu = {}
local PatchPage = {}
local PathcTA = {}
local PatchMoveableSpriteProps = {}
local PatchRecipeManager = {}

function PatchPaneContextMenu.isAnyAllowed(container, items)
    local zipContainer = ZipContainer:new(container)
    if zipContainer then
        items = ISInventoryPane.getActualItems(items)
        for _, item in ipairs(items) do
            if container:isItemAllowed(item) and zipContainer.isWhiteListed(item) then
                return true
            end
        end
        return false
    end
    return ISInventoryPaneContextMenu.isAnyAllowed(container, items)
end

--- @param recipe Recipe
--- @param player IsoGameCharacter
--- @param containersArr ArrayList
--- @param item InventoryItem
--- @return int
function PatchRecipeManager.getNumberOfTimesRecipeCanBeDone(recipe, player, containersArr, item)
    local o = RecipeManager_base.getNumberOfTimesRecipeCanBeDone(recipe, player, containersArr, item)
    if not ZipContainer.isValidInArray(containersArr) then
        return o
    end

    local validationTable = {}
    local validationCount = 0
    local resultNumberTable = {}

    local recipeSources = recipe:getSource()
    local sourcesSize = recipeSources:size()
    for i = 0, sourcesSize - 1 do
        local rSource = recipeSources:get(i)
        local itemTypeList = rSource:getItems()
        local itemCount = rSource:getCount()
        local isKeep = rSource:isKeep()
        local hasItemCount = 0
        for j = 0, containersArr:size() - 1 do
            ---@type ItemContainer
            local container = containersArr:get(j)
            local zipContainer = ZipContainer:new(container)
            for k = 0, itemTypeList:size() -1 do
                local itemType = itemTypeList:get(k)
                hasItemCount = hasItemCount + container:getCountType(itemType)
                if zipContainer then
                    hasItemCount = hasItemCount + zipContainer:countItems(itemType)
                end
            end
        end
        if hasItemCount >= itemCount then
            validationCount = validationCount + 1
        end
        if not isKeep then
            table.insert(validationTable, hasItemCount)
        end
    end

    if sourcesSize ~= validationCount then
        return 0
    end

    for key, value in pairs(validationTable) do
        if value == 0 then
            return 0
        end
        local rSource = recipeSources:get(key-1)
        local count = rSource:getCount()
        local resulCount = value / count
        resulCount = resulCount - resulCount % 1
        resultNumberTable[key] = resulCount
    end

    table.sort(resultNumberTable)

    return resultNumberTable[1]
end

--- @public
--- @static
--- @param recipe Recipe
--- @param player IsoGameCharacter
--- @param item InventoryItem
--- @param containersArr ArrayList
--- @return boolean
function PatchRecipeManager.IsRecipeValid(recipe, player, item, containersArr)
    local o = RecipeManager_base.IsRecipeValid(recipe, player, item, containersArr)
    if not ZipContainer.isValidInArray(containersArr) or o then
        return o
    end

    local isValidCount = 0
    local recipeSources = recipe:getSource()
    local sourcesSize = recipeSources:size()
    for i = 0, sourcesSize - 1 do
        local itemTypeList = recipeSources:get(i):getItems()
        local itemCount = recipeSources:get(i):getCount()
        local hasItemCount = 0
        for j = 0, containersArr:size() - 1 do
            ---@type ItemContainer
            local container = containersArr:get(j)
            local zipContainer = ZipContainer:new(container)
            for k = 0, itemTypeList:size() -1 do
                local itemType = itemTypeList:get(k)
                hasItemCount = hasItemCount + container:getCountType(itemType)
                if zipContainer then
                    hasItemCount = hasItemCount + zipContainer:countItems(itemType)
                end
            end
        end
        if hasItemCount >= itemCount then
            isValidCount = isValidCount + 1
        end
    end
    return sourcesSize == isValidCount
end

--- @param recipe Recipe
--- @param player IsoGameCharacter
--- @param containersArr ArrayList
--- @param selectedItem InventoryItem
--- @param ignoreItems ArrayList
--- @return ArrayList
function PatchRecipeManager.getAvailableItemsAll(recipe, player, containersArr, selectedItem, ignoreItems)
    local o = RecipeManager_base.getAvailableItemsAll(recipe, player, containersArr, selectedItem, ignoreItems)
    for i = 0, containersArr:size() - 1 do
        local zipContainer = ZipContainer:new(containersArr:get(i))
        if zipContainer then
            local items = zipContainer:getItems()
            for _, item in pairs(items) do
                o:add(item)
            end
        end
    end
    return o
end

function PatchMoveableSpriteProps:objectNoContainerOrEmpty(object) -- NOTE: Запрещаем поднимать зип контейнер если он не пустой
    for i=1, object:getContainerCount() do
        local container = object:getContainerByIndex(i-1)
        local zipContainer = ZipContainer:new(container)
        if container and zipContainer and zipContainer:countItems() > 0 then
            return false
        end
    end
    return ISMoveableSpriteProps_base.objectNoContainerOrEmpty(self, object)
end

---@param pane ISInventoryPane
---@param page ISInventoryPage
local function refreshContainer(pane, page)
    ---@type ItemContainer
    local container = pane.inventory
    local isCollapsed = page.isCollapsed
    local zipContainer = ZipContainer:new(container)
    local isVisible = pane.inventory == pane.lastinventory
    if pane.lastinventory and ZipContainer.isValid(pane.lastinventory) and not isVisible then
        -- print('clear last')
        pane.lastinventory:removeAllItems() -- очищаем прошлый контейнер если требуется
    end
    if zipContainer then
        if isCollapsed then
            -- print('clear')
            container:removeAllItems() -- очищаем контейнер если требуется
        else
            local hash1 = zipContainer:getHashOfModdata()
            local hash2 = zipContainer:getHashOfContains()
            -- local count = zipContainer:countItems()
            -- if container:getItems():size() ~= count then
            if hash1 ~= hash2 then --- FIXME: Работает немного медленно. Можно использовать вариант строкой выше, но это менее безопасно. Нормальный хеш посчитать не получилось.
                -- print('real render')
                zipContainer:makeItems() -- отрисовываем айтемы
            end
        end
    end
end

---@param ta ISInventoryTransferAction
local function onTransferComplete(ta)
    local threshold = 50 -- порог тиков для дебаунса (таймаут)
    local item, sourceContainer, targetContainer = ta.item, ta.srcContainer, ta.destContainer
    local sourceZip = ZipContainer:new(sourceContainer)
    local targetZip = ZipContainer:new(targetContainer)
    if sourceZip then
        sourceZip:removeItems({item})
        utils.debounce('onTransferComplete.removeItems', threshold, function (_, acc) -- дебаунс функция, выполнится через 50 тиков после последнего переноса элемента. Чтобы записать моддату для всех элементов сразу. Иначе тормозит
            sourceZip:setModData()
            sourceZip:makeLog(acc, 'GET')
        end, item)
    end
    if targetZip then
        targetZip:addItems({item})
        utils.debounce('onTransferComplete.addItems', threshold, function (_, acc)
            targetZip:setModData()
            targetZip:makeLog(acc, 'PUT')
        end, item)
    end
end

function PatchPage:clearMaxDrawHeight() -- SHOW
    -- print('!!!clearMaxDrawHeight!!!')
    refreshContainer(self.inventoryPane, self)
    return ISInventoryPage_base.clearMaxDrawHeight(self)
end
function PatchPage:setMaxDrawHeight(height) -- HIDE
    -- print('!!!setMaxDrawHeight!!!')
    refreshContainer(self.inventoryPane, self)
    return ISInventoryPage_base.setMaxDrawHeight(self, height)
end

function PatchPage:selectContainer(button)
    -- print('!!!selectContainer!!!')
    refreshContainer(self.inventoryPane, self)
    return ISInventoryPage_base.selectContainer(self, button)
end

function PatchPane:refreshContainer()
    -- print('!!!refreshContainer!!!')
    refreshContainer(self, self.inventoryPage)
    return ISInventoryPane_base.refreshContainer(self)
end

---@param items InventoryItem[]
---@param container ItemContainer
function PatchPane:transferItemsByWeight(items, container)
    local zipContainer = ZipContainer:new(container)
    if zipContainer then
        zipContainer:removeForbiddenTypeFromItemList(items)
    end
    return ISInventoryPane_base.transferItemsByWeight(self, items, container)
end


---@param item InventoryItem
function PathcTA:transferItem(item)
    local o = ISInventoryTransferAction_base.transferItem(self, item)
    onTransferComplete(self)
    return o
end

function PathcTA:isValid()
    local zipContainer = ZipContainer:new(self.destContainer)
    if zipContainer then
        local o_getServerOptions = getServerOptions
        getServerOptions = function()
            return {
                ['getInteger'] = function (this, key)
                    if key == 'ItemNumbersLimitPerContainer' then
                        return 0
                    end
                    return o_getServerOptions().getInteger(this, key)
                end
            }
        end
        local p_result = ISInventoryTransferAction_base.isValid(self)
        getServerOptions = o_getServerOptions
        return p_result
    end
    return ISInventoryTransferAction_base.isValid(self)
end

local makeHooks = function ()
    print('Zip Container: make hooks')
    ISInventoryPane.refreshContainer = PatchPane.refreshContainer
    ISInventoryPane.transferItemsByWeight = PatchPane.transferItemsByWeight

    ISInventoryPaneContextMenu.isAnyAllowed = PatchPaneContextMenu.isAnyAllowed

    ISInventoryPage.selectContainer = PatchPage.selectContainer
    ISInventoryPage.setMaxDrawHeight = PatchPage.setMaxDrawHeight
    ISInventoryPage.clearMaxDrawHeight = PatchPage.clearMaxDrawHeight

    ISInventoryTransferAction.transferItem = PathcTA.transferItem
    ISInventoryTransferAction.isValid = PathcTA.isValid

    ISMoveableSpriteProps.objectNoContainerOrEmpty = PatchMoveableSpriteProps.objectNoContainerOrEmpty

    RecipeManager.getAvailableItemsAll = PatchRecipeManager.getAvailableItemsAll
    RecipeManager.IsRecipeValid = PatchRecipeManager.IsRecipeValid
    RecipeManager.getNumberOfTimesRecipeCanBeDone = PatchRecipeManager.getNumberOfTimesRecipeCanBeDone
end
local removeHooks = function ()
    print('Zip Container: remove hooks')
    ISInventoryPane.refreshContainer = ISInventoryPane_base.refreshContainer
    ISInventoryPane.transferItemsByWeight = ISInventoryPane_base.transferItemsByWeight

    ISInventoryPaneContextMenu.isAnyAllowed = ISInventoryPaneContextMenu_base.isAnyAllowed

    ISInventoryPage.selectContainer = ISInventoryPage_base.selectContainer
    ISInventoryPage.setMaxDrawHeight = ISInventoryPage_base.setMaxDrawHeight
    ISInventoryPage.clearMaxDrawHeight = ISInventoryPage_base.clearMaxDrawHeight

    ISInventoryTransferAction.transferItem = ISInventoryTransferAction_base.transferItem
    ISInventoryTransferAction.isValid = ISInventoryTransferAction_base.isValid

    ISMoveableSpriteProps.objectNoContainerOrEmpty = ISMoveableSpriteProps_base.objectNoContainerOrEmpty

    RecipeManager.getAvailableItemsAll = RecipeManager_base.getAvailableItemsAll
    RecipeManager.IsRecipeValid = RecipeManager_base.IsRecipeValid
    RecipeManager.getNumberOfTimesRecipeCanBeDone = RecipeManager_base.getNumberOfTimesRecipeCanBeDone
end

-- GmakeHooks = makeHooks -- TODO: дебаг переменная. Удалить
-- GremoveHooks = removeHooks

if AUD then
    AUD.setButton(1, "Add hooks", makeHooks)
    AUD.setButton(2, "Remove hooks", removeHooks)
end

-- Events.OnCreateUI.Add(makeHooks)
Events.OnGameStart.Add(makeHooks)

-- TODO: 
--1. добавить логирование
--2. брать предметы из ящика при крафте WIP