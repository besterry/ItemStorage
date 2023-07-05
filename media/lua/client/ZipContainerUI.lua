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
    setMaxDrawHeight = ISInventoryPage.setMaxDrawHeight
}

local PatchPane = {}
local PatchPage = {}

-- ISInventoryPane:renderdetails(doDragged)

function PatchPage:setMaxDrawHeight(height)
    print('setMaxDrawHeight', height, self.isCollapsed)
    return ISInventoryPage_base.setMaxDrawHeight(self, height)
end

function PatchPage:selectContainer(button)
    print('-----selectContainer-----')
    return ISInventoryPage_base.selectContainer(self, button)
end

function PatchPane:refreshContainer()
    -- local playerLoot = getPlayerLoot(self.player).inventory
    -- local superContainer = SuperContainer:new(playerLoot)
    -- print('playerLoot', playerLoot:getType())

    print('self.inventory', self.inventory:getType())
    -- print('container:getType()', container:getType())
    ---@type ItemContainer
    local container = self.inventory
    if container:getType() == ZIP_CONTAINER_TYPE then
    -- if container:getType() == 'counter' then
        local zipContainer = ZipContainer:new(container)
        self.inventory = zipContainer:makeItems()
    end
    return ISInventoryPane_base.refreshContainer(self)
end

---@param items InventoryItem[]
---@param container ItemContainer
function PatchPane:transferItemsByWeight(items, container)
    print('transferItemsByWeight')
    if container:getType() == ZIP_CONTAINER_TYPE then
        local zipContainer = ZipContainer:new(container)
        zipContainer:addItems(items)
        self:refreshContainer()
        -- ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), container)) -- TODO: Переписать
        return
    end
    -- self.superContainer = nil
    return ISInventoryPane_base.transferItemsByWeight(self, items, container)
end

-- local makeHooks
local makeHooks = function ()
    print('onCreateUI_handler')
    ISInventoryPane.refreshContainer = PatchPane.refreshContainer
    ISInventoryPane.transferItemsByWeight = PatchPane.transferItemsByWeight

    ISInventoryPage.selectContainer = PatchPage.selectContainer
    ISInventoryPage.setMaxDrawHeight = PatchPage.setMaxDrawHeight
    -- Events.OnCreateUI.Remove(makeHooks)
end
-- makeHooks()

GmakeHooks = makeHooks -- TODO: дебаг переменная. Удалить

-- Events.OnCreateUI.Add(makeHooks)
Events.OnGameStart.Add(makeHooks)

