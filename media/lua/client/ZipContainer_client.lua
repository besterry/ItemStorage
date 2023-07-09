local MOD_NAME = 'ZipContainer'

---@class ItemTable
---@field id integer
---@field condition number
---@field age number
---@field delta number
---@field hunger number
---@field weight number
---@field isBroken boolean
---@field isCooked boolean
---@field cookedString string
---@field isBurnt boolean
---@field burntString string

---@alias zipTable table<string, ItemTable[]>

---@class ZipContainer
-- -@field itemContainer ItemContainer
-- -@field isoObject IsoObject
-- -@field modData table<string, ItemTable[]>
local ZipContainer = {}

---@param container ItemContainer
---@return ZipContainer
function ZipContainer:new(container)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    -- o.isoPlayer = getPlayer()
    -- o.itemContainer = container
    -- ---@type IsoObject
    -- o.isoObject = container:getParent()
    -- o.modData = o.isoObject:getModData()[MOD_NAME] or {}
    ---@type ItemContainer
    self.itemContainer = container
    ---@type IsoObject
    self.isoObject = container:getParent()
    ---@type zipTable
    self.modData = o.isoObject:getModData()[MOD_NAME] or {}
    -- print('modData', bcUtils.dump(o.modData))
    return self
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
            item:setID(typeTable.id)
            item:setCondition(typeTable.condition)
            item:setAge(typeTable.age)
            item:setBroken(typeTable.isBroken)

            if typeTable.isCooked then
                item:setCooked(typeTable.isCooked)
                item:setCookedString(typeTable.cookedString)
            end
            if typeTable.isBurnt then
                item:setBurnt(typeTable.isBurnt)
                item:setBurntString(typeTable.burntString)
            end
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

local function clone(item)
    local newItem = InventoryItemFactory.CreateItem(item:getFullType())
    if not newItem then return end
    -- newItem:setAge(item:getAge())
    -- newItem:setCondition(item:getCondition(), false)
    newItem:getVisual():copyFrom(item:getVisual()) -- !
    -- newItem:setBroken(item:isBroken())
    newItem:setColor(item:getColor())
    -- if item:isCooked() then
    --     newItem:setCooked(item:isCooked())
    --     newItem:setCookedString(item:getCookedString())
    -- end
    -- if item:isBurnt() then
    --     newItem:setBurnt(item:isBurnt())
    --     newItem:setBurntString(item:getBurntString())
    -- end
    newItem:setDisplayName(item:getDisplayName())

    if item:hasModData() then
        newItem:copyModData(item:getModData())
    end
    if instanceof(item, "Clothing") then
        item:copyPatchesTo(newItem)
        newItem:setBloodLevel(item:getBloodLevel())
        newItem:setDirtyness(item:getDirtyness())
        newItem:setPalette(item:getPalette())
        newItem:setWetness(item:getWetness())
    end
    if instanceof(item, "DrainableComboItem") then
        newItem:setUsedDelta(item:getUsedDelta())
        newItem:updateWeight()
    end
    if instanceof(item, "Food") then
        newItem:setCalories(item:getCalories())
        newItem:setCarbohydrates(item:getCarbohydrates())
        newItem:setProteins(item:getProteins())
        newItem:setLipids(item:getLipids())
        newItem:setWeight(item:getWeight())
        newItem:setHungChange(item:getHungChange())
        newItem:setUnhappyChange(item:getUnhappyChange())
        newItem:setBoredomChange(item:getBoredomChange())
        newItem:setStressChange(item:getStressChange())
        newItem:setEnduranceChange(item:getEnduranceChange())
        newItem:setPainReduction(item:getPainReduction())
        newItem:setThirstChange(item:getThirstChange())
        newItem:setCookedInMicrowave(item:isCookedInMicrowave())
        newItem:setSpices(item:getSpices())
    end
end

---@param items InventoryItem[]
function ZipContainer:addItems(items)
    for key, item in pairs(items) do
        local type = item:getFullType()
        local typeTable = self.modData[type] or {} --[[@as zipTable]]
        local resultTable = {
            id = item:getID(),
            condition = item:getCondition(),
            weight = item:getUnequippedWeight(),
            age = item:getAge(),
            isBroken = item:isBroken(),
        }
        print('item:getVisual(): ', item:getVisual()) -- относится к одежде. Там много параметров. Вероятно проще запретить хранить одежду
        -- print('item:getVisual():toString() ', item:getVisual():toString())
        print('item:getColor() ', item:getColor())
        -- print('item:getColor():toString() ', item:getColor():toString())
        if item:isCooked() then
            resultTable['isCooked'] = item:isCooked()
            resultTable['cookedString'] = item:getCookedString()
        end
        if item:isBurnt() then
            resultTable['isBurnt'] = item:isBurnt()
            resultTable['burntString'] = item:getBurntString()
        end
        if item:IsDrainable() then
            local drainableItem = item --[[@as DrainableComboItem]]
            resultTable['delta'] = drainableItem:getDelta()
        end
        if item:IsFood() then -- TODO: обрабатывать все свойства
            local foodItem = item --[[@as Food]]
            resultTable['hunger'] = foodItem:getHungChange()
        end
        table.insert(typeTable, resultTable)
        self.modData[type] = typeTable
    end
    self:setModData()
end

---@param items InventoryItem[]
function ZipContainer:removeItems(items)
    for _, item in pairs(items) do
        local type = item:getFullType()
        local id = item:getID()
        local typeTables = self.modData[type] or {}
        for idx, typeTable in ipairs(typeTables) do
            -- print('typeTable', bcUtils.dump(typeTable))
            if typeTable and typeTable.id == id then
                table.remove(typeTables, idx)
            end
        end
        self.modData[type] = typeTables
    end
    self:setModData()
end

---@param items InventoryItem[]
---@param sourceContainer ItemContainer
function ZipContainer:putItems(items, sourceContainer)
    self:addItems(items)
    for _, item in pairs(items) do
        sourceContainer:DoRemoveItem(item)
    end
end

---@param items InventoryItem[]
---@param targetContainer ItemContainer
function ZipContainer:pickUpItems(items, targetContainer)
    self:removeItems(items)
    for _, item in pairs(items) do
        targetContainer:addItem(item)
    end
end

---@return integer
function ZipContainer:countItems()
    local count = 0
    for _, typeTables in pairs(self.modData) do
        for _, typeTable in pairs(typeTables) do
            if typeTable then
                count = count + 1
            end
        end
    end
    return count
end

return {
    ZipContainer = ZipContainer
}