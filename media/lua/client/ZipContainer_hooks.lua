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

local PatchPane = {}
local PatchPage = {}
local PathcTA = {}
local PatchMoveableSpriteProps = {}

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
            -- local count = zipContainer:countItems()
            local hash1 = zipContainer:getHashOfModdata()
            local hash2 = zipContainer:getHashOfContains()
            -- if container:getItems():size() ~= count then
            if hash1 ~= hash2 then --- FIXME: Работает довольно медленно. Можно использовать вариант строкой выше, но это менее безопасно
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
end
local removeHooks = function ()
    print('removeHooks')
    ISInventoryPane.refreshContainer = ISInventoryPane_base.refreshContainer

    ISInventoryPage.selectContainer = ISInventoryPage_base.selectContainer
    ISInventoryPage.setMaxDrawHeight = ISInventoryPage_base.setMaxDrawHeight
    ISInventoryPage.clearMaxDrawHeight = ISInventoryPage_base.clearMaxDrawHeight

    ISInventoryTransferAction.transferItem = ISInventoryTransferAction_base.transferItem

    ISMoveableSpriteProps.objectNoContainerOrEmpty = ISMoveableSpriteProps_base.objectNoContainerOrEmpty
end

GmakeHooks = makeHooks -- TODO: дебаг переменная. Удалить
GremoveHooks = removeHooks

if AUD then
    AUD.setButton(1, "Add hooks", makeHooks)
    AUD.setButton(2, "Remove hooks", removeHooks)
end

Events.OnGameStart.Add(makeHooks)

-- TODO: 
--1. добавить логирование. Пока непонятно как это сделать
--2. брать предметы из ящика при крафте
--4. запретить складывать сложные предметы. Разобраться какие предметы сложные