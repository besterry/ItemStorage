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
            print('clean1', pane.inventory:getItems():size())
            container:removeAllItems()
            -- pane.inventory = container
            print('clean2', pane.inventory:getItems():size())
        else
            print('add1', pane.inventory:getItems():size())
            local zipContainer = ZipContainer:new(container)
            -- pane.inventory = zipContainer:makeItems()
            zipContainer:makeItems()
            print('add2', pane.inventory:getItems():size())
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
    refreshContainer(self.inventoryPane, self)
    return ISInventoryPage_base.selectContainer(self, button)
end

function PatchPane:refreshContainer()
    -- local playerLoot = getPlayerLoot(self.player).inventory
    -- local superContainer = SuperContainer:new(playerLoot)
    -- print('playerLoot', playerLoot:getType())
    -- print('refreshContainer')
    -- print('self.inventory', self.inventory:getType())
    -- print('self.inventoryPage.isCollapsed', self.inventoryPage.isCollapsed)
    -- print('self.inventoryPage.toggleStove:getIsVisible()', self.inventoryPage.toggleStove:getIsVisible())
    -- print('container:getType()', container:getType())
    -- ---@type ItemContainer
    -- local container = self.inventory
    -- if container:getType() == ZIP_CONTAINER_TYPE then
    -- -- if container:getType() == 'counter' then
    --     local zipContainer = ZipContainer:new(container)
    --     self.inventory = zipContainer:makeItems()
    -- end
    refreshContainer(self, self.inventoryPage)
    return ISInventoryPane_base.refreshContainer(self)
end

---@param items InventoryItem[]
---@param container ItemContainer
function PatchPane:transferItemsByWeight(items, container)
    print('transferItemsByWeight')
    if container:getType() == ZIP_CONTAINER_TYPE then
        local zipContainer = ZipContainer:new(container)
        zipContainer:addItems(items)
        -- self:refreshContainer()
        refreshContainer(self, self.inventoryPage)
        -- ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), container)) -- TODO: Переписать
        return
    end
    -- self.superContainer = nil
    return ISInventoryPane_base.transferItemsByWeight(self, items, container)
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

Events.OnResetLua.Add(removeHooks)

