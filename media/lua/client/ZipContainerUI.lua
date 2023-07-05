local main = require 'ZipContainerClient'
local ZipContainer = main.ZipContainer
-- getPlayerLoot(self.player).inventoryPane.selected = {};
-- getPlayerInventory(self.player).inventoryPane.selected = {};
-- InventoryItemFactory.CreateItem("Base.Plank");

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

-- ISInventoryPane:renderdetails(doDragged)

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
    print('clearMaxDrawHeight', self.isCollapsed)
    refreshContainer(self.inventoryPane, self)
    return ISInventoryPage_base.clearMaxDrawHeight(self)
end
function PatchPage:setMaxDrawHeight(height) -- HIDE
    print('setMaxDrawHeight', self.isCollapsed)
    refreshContainer(self.inventoryPane, self)
    return ISInventoryPage_base.setMaxDrawHeight(self, height)
end

function PatchPage:selectContainer(button)
    print('-----selectContainer-----')
    refreshContainer(self.inventoryPane, self) -- TODO: удалять из прошлого контейнера
    return ISInventoryPage_base.selectContainer(self, button)
end

function PatchPane:refreshContainer()
    refreshContainer(self, self.inventoryPage)
    return ISInventoryPane_base.refreshContainer(self)
end

---@param items InventoryItem[]
---@param targetContainer ItemContainer
function PatchPane:transferItemsByWeight(items, targetContainer)
    print('transferItemsByWeight')
    if #items > 0 then
        ---@type ItemContainer
        local sourceContainer = items[1]:getContainer()
        if sourceContainer:getType() == ZIP_CONTAINER_TYPE then
            print('FROM CONTAINER')
            -- TODO: добавить таймед экшин
        end
    end
    if targetContainer:getType() == ZIP_CONTAINER_TYPE then
        local zipContainer = ZipContainer:new(targetContainer)
        zipContainer:addItems(items)
        refreshContainer(self, self.inventoryPage)
        -- ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), container)) -- TODO: Переписать
        return
    end
    -- self.superContainer = nil
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

local reloadHookes = function ()
    removeHooks()
    makeHooks()
end
-- makeHooks()

GmakeHooks = makeHooks -- TODO: дебаг переменная. Удалить
GremoveHooks = removeHooks
GreloadHookes = reloadHookes

-- Events.OnCreateUI.Add(makeHooks)
Events.OnGameStart.Add(makeHooks)

-- Events.OnResetLua.Add(removeHooks)

