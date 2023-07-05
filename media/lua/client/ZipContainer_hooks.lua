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

local PatchPane = {}
local PatchPage = {}

---@param pane ISInventoryPane
---@param page ISInventoryPage
local function refreshContainer(pane, page)
    ---@type ItemContainer
    local container = pane.inventory
    local isCollapsed = page.isCollapsed
    if container:getType() == ZIP_CONTAINER_TYPE then
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

function PatchPage:clearMaxDrawHeight() -- SHOW
    refreshContainer(self.inventoryPane, self)
    return ISInventoryPage_base.clearMaxDrawHeight(self)
end
function PatchPage:setMaxDrawHeight(height) -- HIDE
    refreshContainer(self.inventoryPane, self)
    return ISInventoryPage_base.setMaxDrawHeight(self, height)
end

function PatchPage:selectContainer(button)
    print('-----selectContainer-----')
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
    ---@type ItemContainer
    local sourceContainer = nil
    if #items > 0 then
        sourceContainer = items[1]:getContainer()
    end

    if sourceContainer and sourceContainer:getType() == ZIP_CONTAINER_TYPE then
        local zipContainer = ZipContainer:new(sourceContainer)
        -- item:setContainer(ItemContainer itemContainer) -- NEED TRY
        zipContainer:pickUpItems(items, targetContainer)
        refreshContainer(self, self.inventoryPage)
        -- TODO: добавить таймед экшин
        return
    end
    if sourceContainer and targetContainer:getType() == ZIP_CONTAINER_TYPE then
        local zipContainer = ZipContainer:new(targetContainer)
        zipContainer:putItems(items, sourceContainer)
        refreshContainer(self, self.inventoryPage)
        -- ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), container)) -- TODO: Переписать
        return
    end
    return ISInventoryPane_base.transferItemsByWeight(self, items, targetContainer)
end

-- local makeHooks
local makeHooks = function ()
    print('makeHooks')
    ISInventoryPane.refreshContainer = PatchPane.refreshContainer
    ISInventoryPane.transferItemsByWeight = PatchPane.transferItemsByWeight

    ISInventoryPage.selectContainer = PatchPage.selectContainer
    ISInventoryPage.setMaxDrawHeight = PatchPage.setMaxDrawHeight
    ISInventoryPage.clearMaxDrawHeight = PatchPage.clearMaxDrawHeight
end
local removeHooks = function ()
    print('removeHooks')
    ISInventoryPane.refreshContainer = ISInventoryPane_base.refreshContainer
    ISInventoryPane.transferItemsByWeight = ISInventoryPane_base.transferItemsByWeight

    ISInventoryPage.selectContainer = ISInventoryPage_base.selectContainer
    ISInventoryPage.setMaxDrawHeight = ISInventoryPage_base.setMaxDrawHeight
    ISInventoryPage.clearMaxDrawHeight = ISInventoryPage_base.clearMaxDrawHeight
end

GmakeHooks = makeHooks -- TODO: дебаг переменная. Удалить
GremoveHooks = removeHooks

-- Events.OnCreateUI.Add(makeHooks)
Events.OnGameStart.Add(makeHooks)

