local MOD_NAME = 'ZipContainer'

---@class ItemTable
---@field condition number
---@field delta number
---@field hunger number
---@field weight number

---@class ZipContainer
---@field itemContainer ItemContainer
---@field isoObject IsoObject
---@field modData table<string, ItemTable[]>
local ZipContainer = {}

---@param container ItemContainer
function ZipContainer:new(container)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    -- o.isoPlayer = getPlayer()
    o.itemContainer = container
    o.isoObject = container:getParent()
    o.modData = o.isoObject:getModData()[MOD_NAME] or {}
    -- print('modData', bcUtils.dump(o.modData))
    return o
end

function ZipContainer:setModData()
    self.isoObject:getModData()[MOD_NAME] = self.modData
    self.isoObject:transmitModData()
end

---@return ItemContainer
function ZipContainer:makeItems()
    self.itemContainer:removeAllItems()
    for type, typeTables in pairs(self.modData) do
        for _, typeTable in pairs(typeTables) do
            local item = InventoryItemFactory.CreateItem(type);
            item:setCondition(typeTable.condition)
            if typeTable.delta then
                item = item  --[[@as DrainableComboItem]]
                item:setDelta(typeTable.delta)
            end
            if typeTable.hunger then
                item = item  --[[@as Food]]
                item:setHungChange(typeTable.hunger)
            end
            self.itemContainer:addItem(item)
        end
    end
    return self.itemContainer
end

---@param items InventoryItem[]
function ZipContainer:addItems(items)
    for key, item in pairs(items) do
        local type = item:getFullType()
        local typeTable = self.modData[type] or {}
        local delta = nil
        local hunger = nil
        if item:IsDrainable() then
            local drainableItem = item --[[@as DrainableComboItem]]
            delta = drainableItem:getDelta()
        end
        if item:IsFood() then -- TODO: обрабатывать все свойства
            local foodItem = item --[[@as Food]]
            hunger = foodItem:getHungChange()
        end
        table.insert(typeTable, {
            condition = item:getCondition(),
            weight = item:getUnequippedWeight(),
            delta = delta,
            hunger = hunger
        })
        self.modData[type] = typeTable
    end
    self:setModData()
end

---@return integer
function ZipContainer:countItems()
    local count = 0
    for _, typeTables in pairs(self.modData) do
        for _, _ in pairs(typeTables) do
            count = count + 1
        end
    end
    return count
end

return {
    ZipContainer = ZipContainer
}