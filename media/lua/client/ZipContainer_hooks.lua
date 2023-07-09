local main = require 'ZipContainer_client'
local ZipContainer = main.ZipContainer

local ZIP_CONTAINER_TYPE = 'ZipContainer'

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
    new = ISInventoryTransferAction.new
}

local PatchPane = {}
local PatchPage = {}
local PathcTA = {}

---@type InventoryItem[]
local qItemsList = {}

---@param pane ISInventoryPane
---@param page ISInventoryPage
local function refreshContainer(pane, page)
    ---@type ItemContainer
    local container = pane.inventory
    local isCollapsed = page.isCollapsed
    if container:getType() == ZIP_CONTAINER_TYPE then
        -- print('refreshContainer', container:getItems():size(), isCollapsed)
        if isCollapsed then
            container:removeAllItems()
        else
            local zipContainer = ZipContainer:new(container)
            local count = zipContainer:countItems()
            if container:getItems():size() ~= count then --- FIXME: Спорная оптимизация, проверка только по количеству можт вызвать неожиданные эффекты. Нужно сделать какой-то кеш но я пока не придумал как
                zipContainer:makeItems()
            end
        end
    end
end

---@param character IsoPlayer
---@param item InventoryItem
---@param sourceContainer ItemContainer
---@param targetContainer ItemContainer
---@param ta ISInventoryTransferAction
local function onTransferComplete(character, item, sourceContainer, targetContainer, ta)
    local isSourceZip = sourceContainer:getType() == ZIP_CONTAINER_TYPE
    local isTargetZip = targetContainer:getType() == ZIP_CONTAINER_TYPE
    if isSourceZip then
        local zipContainer = ZipContainer:new(sourceContainer)
        -- item:setContainer(ItemContainer itemContainer) -- NEED TRY
        zipContainer:removeItems({item})
        -- zipContainer:pickUpItems({item}, targetContainer)
        -- refreshContainer(self, self.inventoryPage)
        -- return
    end
    if isTargetZip then
        local zipContainer = ZipContainer:new(targetContainer)
        zipContainer:addItems({item})
        -- zipContainer:putItems({item}, sourceContainer)
        -- print('zipContainer', bcUtils.dump(zipContainer.modData))
        -- refreshContainer(self, self.inventoryPage)
        -- return
    end
    -- local actionQueue = ISTimedActionQueue.getTimedActionQueue(character)
    -- local indexSelf = actionQueue:indexOf(ta)
    -- print('indexSelf', indexSelf)
    -- print('actionQueue', #actionQueue.queue)
    -- local isFinal = false
    -- if isSourceZip or isTargetZip then
    --     for idx, qItem in pairs(qItemsList) do
    --         if qItem:getID() == item:getID() then
    --             if idx == #qItemsList then
    --                 isFinal = true
    --             end
    --         end
    --     end
    -- end
    -- if isFinal then
    --     qItemsList = {}
    -- end
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

---@param items InventoryItem[]
---@param targetContainer ItemContainer
function PatchPane:transferItemsByWeight(items, targetContainer)
    -- ---@type ItemContainer
    -- local sourceContainer = nil
    -- if #items > 0 then
    --     sourceContainer = items[1]:getContainer()
    -- end

    -- if sourceContainer and sourceContainer:getType() == ZIP_CONTAINER_TYPE then
    --     -- print('aaaaa')
    --     qItemsList = items
    --     -- local zipContainer = ZipContainer:new(sourceContainer)
    --     -- item:setContainer(ItemContainer itemContainer) -- NEED TRY
    --     -- zipContainer:pickUpItems(items, targetContainer)
    --     -- refreshContainer(self, self.inventoryPage)
    --     -- TODO: добавить таймед экшин
    --     -- return
    -- end
    -- if targetContainer:getType() == ZIP_CONTAINER_TYPE then
    --     -- print('bbbbbb')
    --     qItemsList = items
    --     -- local zipContainer = ZipContainer:new(targetContainer)
    --     -- zipContainer:putItems(items, sourceContainer)
    --     -- refreshContainer(self, self.inventoryPage)
    --     -- ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), container)) -- TODO: Переписать
    --     -- return
    -- end
    return ISInventoryPane_base.transferItemsByWeight(self, items, targetContainer)
end

function PathcTA:new(character, item, srcContainer, destContainer, time)
    local o = ISInventoryTransferAction_base.new(self, character, item, srcContainer, destContainer, time)
    o.onCompleteFunc = onTransferComplete
    o.onCompleteArgs = {character, item, srcContainer, destContainer, o}
    return o
end

-- local makeHooks
local makeHooks = function ()
    print('makeHooks')
    ISInventoryPane.refreshContainer = PatchPane.refreshContainer
    ISInventoryPane.transferItemsByWeight = PatchPane.transferItemsByWeight

    ISInventoryPage.selectContainer = PatchPage.selectContainer
    ISInventoryPage.setMaxDrawHeight = PatchPage.setMaxDrawHeight
    ISInventoryPage.clearMaxDrawHeight = PatchPage.clearMaxDrawHeight

    ISInventoryTransferAction.new = PathcTA.new
end
local removeHooks = function ()
    print('removeHooks')
    ISInventoryPane.refreshContainer = ISInventoryPane_base.refreshContainer
    ISInventoryPane.transferItemsByWeight = ISInventoryPane_base.transferItemsByWeight

    ISInventoryPage.selectContainer = ISInventoryPage_base.selectContainer
    ISInventoryPage.setMaxDrawHeight = ISInventoryPage_base.setMaxDrawHeight
    ISInventoryPage.clearMaxDrawHeight = ISInventoryPage_base.clearMaxDrawHeight

    ISInventoryTransferAction.new = ISInventoryTransferAction_base.new
end

GmakeHooks = makeHooks -- TODO: дебаг переменная. Удалить
GremoveHooks = removeHooks

-- Events.OnCreateUI.Add(makeHooks)
Events.OnGameStart.Add(makeHooks)

-- TODO: добавить логирование когда ТА завершилось. Для этого нужно сделать иньекцию в:
-- ISInventoryTransferAction:stop() когда ТА завершилась преждевременно
-- ISInventoryTransferAction:perform() когда ТА завершилась нормально
-- Нужно посчитать сколько айтемов завершилось нормально и залогировать таблицу моддаты
-- Очередь хранится в ISTimedActionQueue.getTimedActionQueue(character).queue
-- Сложная задача. Оставим на потом