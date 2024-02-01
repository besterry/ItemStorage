local main = require 'ZipContainer_client'
local utils = require 'ZipContainer_utils'
local ZipContainer = main.ZipContainer

local hasZipNear = false

local ISInventoryPaneContextMenu_base = {
    -- onPutItems = ISInventoryPaneContextMenu.onPutItems
    isAnyAllowed = ISInventoryPaneContextMenu.isAnyAllowed,
    addDynamicalContextMenu = ISInventoryPaneContextMenu.addDynamicalContextMenu
}

local ISInventoryPane_base = {
    transferItemsByWeight = ISInventoryPane.transferItemsByWeight,
    refreshContainer = ISInventoryPane.refreshContainer,
    renderdetails = ISInventoryPane.renderdetails
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
    getNumberOfTimesRecipeCanBeDone = RecipeManager.getNumberOfTimesRecipeCanBeDone,
    PerformMakeItem = RecipeManager.PerformMakeItem,
    UseAmount = RecipeManager.UseAmount
}

local ISDestroyStuffAction_base = {
    isValid = ISDestroyStuffAction.isValid
}

local ISInventoryPane_patch = {}
local ISInventoryPaneContextMenu_patch = {}
local ISInventoryPage_patch = {}
local ISInventoryTransferAction_patch = {}
local ISMoveableSpriteProps_patch = {}
local RecipeManager_patch = {}
local ISDestroyStuffAction_patch = {}

---@param object IsoThumpable
local function isZipTile(object)
    local objectName = object:getSprite():getName()
    return luautils.stringStarts(objectName, main.TILE_NAME_START)
end

---@param object IsoThumpable
local function isEmpty(object)
    for i=1, object:getContainerCount() do
        local container = object:getContainerByIndex(i-1)
        local zipContainer = ZipContainer:new(container)
        if container and zipContainer and zipContainer:countItems() == 0 then
            return true
        end
    end
end


function ISDestroyStuffAction_patch:isValid()
    local o = ISDestroyStuffAction_base.isValid(self)
    local object = self.item

    if isZipTile(object) and not isEmpty(object) and not isAdmin() then
        self.character:Say(getText('IGUI_Container_not_empty'))
        return false
    end
    return o
end

function ISInventoryPaneContextMenu_patch.isAnyAllowed(container, items)
    -- local zipContainer = ZipContainer:new(container)
    if ZipContainer.isValid(container) then
        local result = nil
        items = ISInventoryPane.getActualItems(items)
        for _, item in ipairs(items) do
            if container:isItemAllowed(item) and ZipContainer.isWhiteListed(item) then
                if result == nil then
                    result = true
                end
            else
                result = false
            end
        end
        return result
    end
    return ISInventoryPaneContextMenu_base.isAnyAllowed(container, items)
end


-- --- @param recipe Recipe
-- --- @param player IsoGameCharacter
-- --- @param containersArr ArrayList
-- --- @param item InventoryItem
-- --- @return int
-- function RecipeManager_patch.getNumberOfTimesRecipeCanBeDone(recipe, player, containersArr, item)
--     local o = RecipeManager_base.getNumberOfTimesRecipeCanBeDone(recipe, player, containersArr, item)
--     if not ZipContainer.isValidInArray(containersArr) then
--         return o
--     end

--     local validationTable = {}
--     local validationCount = 0
--     local resultNumberTable = {}

--     local recipeSources = recipe:getSource()
--     local sourcesSize = recipeSources:size()
--     for i = 0, sourcesSize - 1 do
--         local rSource = recipeSources:get(i)
--         local itemTypeList = rSource:getItems()
--         local itemCount = rSource:getCount()
--         local isKeep = rSource:isKeep()
--         local hasItemCount = 0
--         for j = 0, containersArr:size() - 1 do
--             ---@type ItemContainer
--             local container = containersArr:get(j)
--             local zipContainer = ZipContainer:new(container)
--             for k = 0, itemTypeList:size() -1 do
--                 local itemType = itemTypeList:get(k)
--                 hasItemCount = hasItemCount + container:getCountType(itemType)
--                 if zipContainer then
--                     hasItemCount = hasItemCount + zipContainer:countItems(itemType)
--                 end
--             end
--         end
--         if hasItemCount >= itemCount then
--             validationCount = validationCount + 1
--         end
--         if not isKeep then
--             table.insert(validationTable, hasItemCount)
--         end
--     end

--     if sourcesSize ~= validationCount then
--         return 0
--     end

--     for key, value in pairs(validationTable) do
--         if value == 0 then
--             return 0
--         end
--         local rSource = recipeSources:get(key-1)
--         local count = rSource:getCount()
--         local resulCount = value / count
--         resulCount = resulCount - resulCount % 1
--         resultNumberTable[key] = resulCount
--     end

--     table.sort(resultNumberTable)

--     return resultNumberTable[1]
-- end

--- @param containersArr ArrayList
--- @return ArrayList
local function removeZipZontainerFromList(containersArr)
    local copyContainersArr = containersArr:clone()
    copyContainersArr:trimToSize()
    for i = copyContainersArr:size() - 1, 0, -1 do
        local container = copyContainersArr:get(i)
        if container then
            local zipContainer = ZipContainer:new(container)
            if zipContainer then
                copyContainersArr:remove(container)
                copyContainersArr:trimToSize()
            end
        end
    end
    return copyContainersArr
end

-- --- @param selectedItem InventoryItem 
-- --- @param context any
-- --- @param recipeList ArrayList, 
-- --- @param player IsoGameCharacter
-- --- @param containerList ArrayList
-- function ISInventoryPaneContextMenu_patch:addDynamicalContextMenu(selectedItem, context, recipeList, player, containerList)
--     -- if 
--     print('selectedItem', selectedItem, type(selectedItem))
--     if selectedItem then
--         -- local isZipContainer = ZipContainer.isValid(selectedItem:getContainer())
--         -- if isZipContainer then
--         --     recipeList:clear()
--         -- end
--     end
--     return ISInventoryPaneContextMenu_base:addDynamicalContextMenu(selectedItem, context, recipeList, player, containerList)
-- end


--- @param recipe Recipe
--- @param player IsoGameCharacter
--- @param containersArr ArrayList
--- @param selectedItem InventoryItem
--- @param ignoreItems ArrayList
--- @return ArrayList
function RecipeManager_patch.getAvailableItemsNeeded(recipe, player, containersArr, selectedItem, ignoreItems)
    if not ZipContainer.isValidInArray(containersArr) then
        return RecipeManager_base.getAvailableItemsNeeded(recipe, player, containersArr, selectedItem, ignoreItems)
    end
    local copyContainersArr = containersArr:clone()
    if recipe:isCanBeDoneFromFloor() then
        copyContainersArr = removeZipZontainerFromList(containersArr)
    end
    -- if selectedItem then
    --     local isZipContainer = ZipContainer.isValid(selectedItem:getContainer())
    --     if isZipContainer then
    --         return RecipeManager_base.getAvailableItemsNeeded(recipe, player, copyContainersArr, nil, ignoreItems)
    --     end
    -- end
    return RecipeManager_base.getAvailableItemsNeeded(recipe, player, copyContainersArr, selectedItem, ignoreItems)
end

--- @param recipe Recipe
--- @param player IsoGameCharacter
--- @param containersArr ArrayList
--- @param item InventoryItem
--- @return int
function RecipeManager_patch.getNumberOfTimesRecipeCanBeDone(recipe, player, containersArr, item)
    if not ZipContainer.isValidInArray(containersArr) then
        return RecipeManager_base.getNumberOfTimesRecipeCanBeDone(recipe, player, containersArr, item)
    end
    local copyContainersArr = containersArr:clone()
    if recipe:isCanBeDoneFromFloor() then
        copyContainersArr = removeZipZontainerFromList(containersArr)
    end
    -- print('item', item)
    -- if item then
    --     local isZipContainer = ZipContainer.isValid(item:getContainer())
    --     if isZipContainer then
    --         print('isZip')
    --         return 0
    --     end
    -- end
    return RecipeManager_base.getNumberOfTimesRecipeCanBeDone(recipe, player, copyContainersArr, item)
end

--- @param recipe Recipe
--- @param player IsoGameCharacter
--- @param item InventoryItem
--- @param containersArr ArrayList
--- @return boolean
function RecipeManager_patch.IsRecipeValid(recipe, player, item, containersArr)
    if (containersArr == nil) then
        return RecipeManager_base.IsRecipeValid(recipe, player, item, containersArr)
    end
    local copyContainersArr = containersArr:clone()
    if recipe:isCanBeDoneFromFloor() then
        copyContainersArr = removeZipZontainerFromList(containersArr)
        if item then
            local isZipContainer = ZipContainer.isValid(item:getContainer())
            if isZipContainer then
                -- print('isZip')
                return false
            end
        end
    end
    
    return RecipeManager_base.IsRecipeValid(recipe, player, item, copyContainersArr)
end

--- @param recipe Recipe
--- @param player IsoGameCharacter
--- @param containersArr ArrayList
--- @param selectedItem InventoryItem
--- @param ignoreItems ArrayList
--- @return ArrayList
function RecipeManager_patch.getAvailableItemsAll(recipe, player, containersArr, selectedItem, ignoreItems)
    -- print('getAvailableItemsAll')
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

---@param object IsoThumpable
function ISMoveableSpriteProps_patch:objectNoContainerOrEmpty(object) -- NOTE: Запрещаем поднимать зип контейнер если он не пустой
    if isZipTile(object) and not isEmpty(object) then
        return false
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
        hasZipNear = false
    end
    if zipContainer then
        if isCollapsed then
            -- print('clear')
            container:removeAllItems() -- очищаем контейнер если требуется
            hasZipNear = false
        else
            local hash1 = zipContainer:getHashOfModdata()
            local hash2 = zipContainer:getHashOfContains()
            -- local count = zipContainer:countItems()
            -- if container:getItems():size() ~= count then
            if hash1 ~= hash2 then --- FIXME: Работает немного медленно. Можно использовать вариант строкой выше, но это менее безопасно. Нормальный хеш посчитать не получилось.
                -- print('real render')
                zipContainer:makeItems() -- отрисовываем айтемы
                hasZipNear = true
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

function ISInventoryPage_patch:clearMaxDrawHeight() -- SHOW
    -- print('!!!clearMaxDrawHeight!!!')
    refreshContainer(self.inventoryPane, self)
    return ISInventoryPage_base.clearMaxDrawHeight(self)
end
function ISInventoryPage_patch:setMaxDrawHeight(height) -- HIDE
    -- print('!!!setMaxDrawHeight!!!')
    refreshContainer(self.inventoryPane, self)
    return ISInventoryPage_base.setMaxDrawHeight(self, height)
end

function ISInventoryPage_patch:selectContainer(button)
    -- print('!!!selectContainer!!!')
    refreshContainer(self.inventoryPane, self)
    return ISInventoryPage_base.selectContainer(self, button)
end

function ISInventoryPane_patch:renderdetails(doDragged)
    local o = ISInventoryPane_base.renderdetails(self, doDragged)
    local y = 0;
    local textDY = (self.itemHgt - self.fontHgt) / 2
    for _, group in ipairs(self.itemslist) do
        local count = 1;
        for _, item in ipairs(group.items) do
            local xoff = 0;
            local yoff = 0;
            local itemName = item:getName();
            -- hasZipNear
            if count == 1 and not ZipContainer.isValid(self.inventory) and ZipContainer.isWhiteListed(item) then
                -- self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, self:getWidth()-1, self.itemHgt, 0.1, 1.0, 1.0, 0.0); -- Желтый фон
                self:drawText(itemName, self.column2+8+xoff, (y*self.itemHgt)+self.headerHgt+textDY+yoff, 0.7, 0.7, 0.1, 0.5, self.font);
            end
            y = y + 1
            if count == ISInventoryPane.MAX_ITEMS_IN_STACK_TO_RENDER + 1 then
                break
            end
            if count == 1 and self.collapsed ~= nil and group.name ~= nil and self.collapsed[group.name] then
                break
            end
            count = count + 1
        end
    end
    return o
end

function ISInventoryPane_patch:refreshContainer()
    -- print('!!!refreshContainer!!!')
    refreshContainer(self, self.inventoryPage)
    return ISInventoryPane_base.refreshContainer(self)
end

---@param items InventoryItem[]
---@param container ItemContainer
function ISInventoryPane_patch:transferItemsByWeight(items, container)
    local zipContainer = ZipContainer:new(container)
    if zipContainer then
        zipContainer:removeForbiddenTypeFromItemList(items)
    end
    return ISInventoryPane_base.transferItemsByWeight(self, items, container)
end


---@param item InventoryItem
function ISInventoryTransferAction_patch:transferItem(item)
    local o = ISInventoryTransferAction_base.transferItem(self, item)
    onTransferComplete(self)
    return o
end

function ISInventoryTransferAction_patch:isValid()
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

    local o_result = ISInventoryTransferAction_base.isValid(self)
    local isOwner = false
    if self.srcContainer then
        local parent = self.srcContainer:getParent()
        if parent and parent:getModData().owner then
            isOwner = self.character:getUsername() == parent:getModData().owner
            if isAdmin() then isOwner = true end
            return (o_result and isOwner)
        end
    end
    return o_result
end

-- local removeItemTransaction_base = removeItemTransaction
-- local InvMngRemoveItem_base = InvMngRemoveItem
-- local createItemTransaction_base = createItemTransaction
-- local isItemTransactionConsistent_base = isItemTransactionConsistent
local makeHooks = function ()
    print('Zip Container: make hooks')
    ISInventoryPane.refreshContainer = ISInventoryPane_patch.refreshContainer
    ISInventoryPane.transferItemsByWeight = ISInventoryPane_patch.transferItemsByWeight
    ISInventoryPane.renderdetails = ISInventoryPane_patch.renderdetails

    ISInventoryPaneContextMenu.isAnyAllowed = ISInventoryPaneContextMenu_patch.isAnyAllowed
    -- ISInventoryPaneContextMenu.addDynamicalContextMenu = ISInventoryPaneContextMenu_patch.addDynamicalContextMenu

    ISInventoryPage.selectContainer = ISInventoryPage_patch.selectContainer
    ISInventoryPage.setMaxDrawHeight = ISInventoryPage_patch.setMaxDrawHeight
    ISInventoryPage.clearMaxDrawHeight = ISInventoryPage_patch.clearMaxDrawHeight

    ISInventoryTransferAction.transferItem = ISInventoryTransferAction_patch.transferItem
    ISInventoryTransferAction.isValid = ISInventoryTransferAction_patch.isValid

    ISMoveableSpriteProps.objectNoContainerOrEmpty = ISMoveableSpriteProps_patch.objectNoContainerOrEmpty

    ISDestroyStuffAction.isValid = ISDestroyStuffAction_patch.isValid

    RecipeManager.IsRecipeValid = RecipeManager_patch.IsRecipeValid
    RecipeManager.getAvailableItemsAll = RecipeManager_patch.getAvailableItemsAll
    RecipeManager.getNumberOfTimesRecipeCanBeDone = RecipeManager_patch.getNumberOfTimesRecipeCanBeDone
    RecipeManager.getAvailableItemsNeeded = RecipeManager_patch.getAvailableItemsNeeded

    sendClientCommand(getPlayer(), main.MOD_NAME, 'getWhiteList', {})
end
local removeHooks = function ()
    print('Zip Container: remove hooks')
    ISInventoryPane.refreshContainer = ISInventoryPane_base.refreshContainer
    ISInventoryPane.transferItemsByWeight = ISInventoryPane_base.transferItemsByWeight
    ISInventoryPane.renderdetails = ISInventoryPane_base.renderdetails

    ISInventoryPaneContextMenu.isAnyAllowed = ISInventoryPaneContextMenu_base.isAnyAllowed
    -- ISInventoryPaneContextMenu.addDynamicalContextMenu = ISInventoryPaneContextMenu_base.addDynamicalContextMenu

    ISInventoryPage.selectContainer = ISInventoryPage_base.selectContainer
    ISInventoryPage.setMaxDrawHeight = ISInventoryPage_base.setMaxDrawHeight
    ISInventoryPage.clearMaxDrawHeight = ISInventoryPage_base.clearMaxDrawHeight

    ISInventoryTransferAction.transferItem = ISInventoryTransferAction_base.transferItem
    ISInventoryTransferAction.isValid = ISInventoryTransferAction_base.isValid

    ISMoveableSpriteProps.objectNoContainerOrEmpty = ISMoveableSpriteProps_base.objectNoContainerOrEmpty

    ISDestroyStuffAction.isValid = ISDestroyStuffAction_base.isValid

    RecipeManager.getAvailableItemsAll = RecipeManager_base.getAvailableItemsAll
    RecipeManager.IsRecipeValid = RecipeManager_base.IsRecipeValid
    RecipeManager.getNumberOfTimesRecipeCanBeDone = RecipeManager_base.getNumberOfTimesRecipeCanBeDone
    RecipeManager.getAvailableItemsNeeded = RecipeManager_base.getAvailableItemsNeeded

    sendClientCommand(getPlayer(), main.MOD_NAME, 'refreshWhiteList', {})

end

if AUD then
    AUD.setButton(1, "Add hooks", makeHooks)
    AUD.setButton(2, "Remove hooks", removeHooks)
end

Events.OnLoad.Add(makeHooks)
