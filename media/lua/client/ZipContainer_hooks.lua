local main = require 'ZipContainer_client'
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

local PatchPane = {}
local PatchPage = {}
local PathcTA = {}


---@param pane ISInventoryPane
---@param page ISInventoryPage
local function refreshContainer(pane, page)
    ---@type ItemContainer
    local container = pane.inventory
    if pane.lastinventory and ZipContainer.isValid(pane.lastinventory) then
        container = pane.lastinventory
    end
    local isCollapsed = page.isCollapsed
    local zipContainer = ZipContainer:new(container)
    local isVisible = pane.inventory == pane.lastinventory
    if zipContainer then
        print('zipContainer state: ', isCollapsed, isVisible)
        if isCollapsed or not isVisible then
            print('colapsed')
            container:removeAllItems()
        else
            local count = zipContainer:countItems()
            print('prerender items', count)
            if container:getItems():size() ~= count then --- FIXME: Нужно проверять чексумму
                print('real render')
                zipContainer:makeItems()
            end
        end
    end
end


---@param ta ISInventoryTransferAction
local function onTransferComplete(ta)
-- local function onTransferComplete(character, item, sourceContainer, targetContainer, ta)
    local item, sourceContainer, targetContainer = ta.item, ta.srcContainer, ta.destContainer
    local sourceZip = ZipContainer:new(sourceContainer)
    local targetZip = ZipContainer:new(targetContainer)
    if sourceZip then
        sourceZip:removeItems({item})
    end
    if targetZip then
        targetZip:addItems({item})
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
    -- print('-----selectContainer-----')
    refreshContainer(self.inventoryPane, self) -- TODO: нужно очищать прошлый контейнер. Понять как выбрать прошлый контейнер
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

-- local lastMillis = 0
-- local onTick = function()
--     local currentMillis = math.floor(getTimeInMillis()/10)
--     if lastMillis ~= currentMillis then
--         lastMillis = currentMillis
--         debounceTimerRender = debounceTimerRender + 1
--         debounceTimerModData = debounceTimerModData + 1
--         -- print('tick', debounceTimer)
--     end
-- end

-- local makeHooks
local makeHooks = function ()
    print('makeHooks')
    ISInventoryPane.refreshContainer = PatchPane.refreshContainer

    ISInventoryPage.selectContainer = PatchPage.selectContainer
    ISInventoryPage.setMaxDrawHeight = PatchPage.setMaxDrawHeight
    ISInventoryPage.clearMaxDrawHeight = PatchPage.clearMaxDrawHeight

    ISInventoryTransferAction.transferItem = PathcTA.transferItem

    -- Events.OnTick.Add(onTick);
end
local removeHooks = function ()
    print('removeHooks')
    ISInventoryPane.refreshContainer = ISInventoryPane_base.refreshContainer

    ISInventoryPage.selectContainer = ISInventoryPage_base.selectContainer
    ISInventoryPage.setMaxDrawHeight = ISInventoryPage_base.setMaxDrawHeight
    ISInventoryPage.clearMaxDrawHeight = ISInventoryPage_base.clearMaxDrawHeight

    ISInventoryTransferAction.transferItem = ISInventoryTransferAction_base.transferItem

    -- Events.OnTick.Remove(onTick);
end

GmakeHooks = makeHooks -- TODO: дебаг переменная. Удалить
GremoveHooks = removeHooks

-- Events.OnCreateUI.Add(makeHooks)
Events.OnGameStart.Add(makeHooks)

-- TODO: 
--0. Разобраться с рассинхроном. Кешировать очередь или придумать ещё что-то
--1. добавить логирование. Пока непонятно как это сделать
--2. брать предметы из ящика при крафте
--3. очищать ящик если отошли от него с открытой панелью
--3. запретить поднимать ящик если в нём есть предметы
--4. запретить складывать сложные предметы. Разобраться какие предметы сложные