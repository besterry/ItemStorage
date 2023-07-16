local main = require 'ZipContainer_client'
local utils = require 'ZipContainer_utils'
local ZipContainer = main.ZipContainer

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
    transferItem = ISInventoryTransferAction.transferItem
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
local PatchPage = {}
local PathcTA = {}
local PatchMoveableSpriteProps = {}
local PatchRecipeManager = {}

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
        print('clear last')
        pane.lastinventory:removeAllItems() -- очищаем прошлый контейнер если требуется
    end
    if zipContainer then
        if isCollapsed then
            print('clear')
            container:removeAllItems() -- очищаем контейнер если требуется
        else
            local hash1 = zipContainer:getHashOfModdata()
            local hash2 = zipContainer:getHashOfContains()
            -- local count = zipContainer:countItems()
            -- if container:getItems():size() ~= count then
            if hash1 ~= hash2 then --- FIXME: Работает немного медленно. Можно использовать вариант строкой выше, но это менее безопасно. Нормальный хеш посчитать не получилось.
                print('real render')
                zipContainer:makeItems() -- отрисовываем айтемы
            end
        end
    end
end

---@param ta ISInventoryTransferAction
local function onTransferComplete(ta)
    local item, sourceContainer, targetContainer = ta.item, ta.srcContainer, ta.destContainer
    local sourceZip = ZipContainer:new(sourceContainer)
    local targetZip = ZipContainer:new(targetContainer)
    if sourceZip then
        sourceZip:removeItems({item})
        utils.debounce('onTransferComplete.removeItems', 50, function () -- дебаунс функция, выполнится через 50 тиков после последнего переноса элемента. Чтобы записать моддату для всех элементов сразу. Иначе тормозит
            print('debounce.removeItems')
            sourceZip:setModData()
        end)
    end
    if targetZip then
        targetZip:addItems({item})
        utils.debounce('onTransferComplete.addItems', 50, function ()
            print('debounce.addItems')
            targetZip:setModData()
        end)
    end
end

function PatchPage:clearMaxDrawHeight() -- SHOW
    refreshContainer(self.inventoryPane, self)
    return ISInventoryPage_base.clearMaxDrawHeight(self)
end
function PatchPage:setMaxDrawHeight(height) -- HIDE
    refreshContainer(self.inventoryPane, self)
    return ISInventoryPage_base.setMaxDrawHeight(self, height)
end

function PatchPage:selectContainer(button)
    refreshContainer(self.inventoryPane, self)
    return ISInventoryPage_base.selectContainer(self, button)
end

function PatchPane:refreshContainer()
    refreshContainer(self, self.inventoryPage)
    return ISInventoryPane_base.refreshContainer(self)
end

---@param item InventoryItem
function PathcTA:transferItem(item)
    local o = ISInventoryTransferAction_base.transferItem(self, item)
    onTransferComplete(self)
    return o
end

local makeHooks = function ()
    print('makeHooks')
    ISInventoryPane.refreshContainer = PatchPane.refreshContainer

    ISInventoryPage.selectContainer = PatchPage.selectContainer
    ISInventoryPage.setMaxDrawHeight = PatchPage.setMaxDrawHeight
    ISInventoryPage.clearMaxDrawHeight = PatchPage.clearMaxDrawHeight

    ISInventoryTransferAction.transferItem = PathcTA.transferItem

    ISMoveableSpriteProps.objectNoContainerOrEmpty = PatchMoveableSpriteProps.objectNoContainerOrEmpty

    RecipeManager.getAvailableItemsAll = PatchRecipeManager.getAvailableItemsAll
    RecipeManager.IsRecipeValid = PatchRecipeManager.IsRecipeValid
    RecipeManager.getNumberOfTimesRecipeCanBeDone = PatchRecipeManager.getNumberOfTimesRecipeCanBeDone
end
local removeHooks = function ()
    print('removeHooks')
    ISInventoryPane.refreshContainer = ISInventoryPane_base.refreshContainer

    ISInventoryPage.selectContainer = ISInventoryPage_base.selectContainer
    ISInventoryPage.setMaxDrawHeight = ISInventoryPage_base.setMaxDrawHeight
    ISInventoryPage.clearMaxDrawHeight = ISInventoryPage_base.clearMaxDrawHeight

    ISInventoryTransferAction.transferItem = ISInventoryTransferAction_base.transferItem

    ISMoveableSpriteProps.objectNoContainerOrEmpty = ISMoveableSpriteProps_base.objectNoContainerOrEmpty

    RecipeManager.getAvailableItemsAll = RecipeManager_base.getAvailableItemsAll
    RecipeManager.IsRecipeValid = RecipeManager_base.IsRecipeValid
    RecipeManager.getNumberOfTimesRecipeCanBeDone = RecipeManager_base.getNumberOfTimesRecipeCanBeDone
end

GmakeHooks = makeHooks -- TODO: дебаг переменная. Удалить
GremoveHooks = removeHooks

if AUD then
    AUD.setButton(1, "Add hooks", makeHooks)
    AUD.setButton(2, "Remove hooks", removeHooks)
end

-- Events.OnCreateUI.Add(makeHooks)
Events.OnGameStart.Add(makeHooks)

-- TODO: 
--1. добавить логирование. Пока непонятно как это сделать
--2. брать предметы из ящика при крафте
--4. запретить складывать сложные предметы. Разобраться какие предметы сложные