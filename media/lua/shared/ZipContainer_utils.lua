-- copy from BravensUtils.DelayFunction
local delayFn = function(func, delay)

    delay = delay or 1;
    local ticks = 0;
    local canceled = false;

    local function onTick()

        if not canceled and ticks < delay then
            ticks = ticks + 1;
            return;
        end

        Events.OnTick.Remove(onTick);
        if not canceled then func(); end
    end

    Events.OnTick.Add(onTick);

    return function()
        canceled = true;
    end
end

---@class debounceEntry
---@field func function
---@field ticks integer
---@field acc any[]
---@field onTick function | nil
---@field startTime number

---@type table<string, debounceEntry>
local debounceDict = {}
---@param name string
---@param delay integer
---@param func function
---@param args any | nil
local debounceFn = function (name, delay, func, args)
    if debounceDict[name] then
        debounceDict[name].func = func
        debounceDict[name].ticks = 0
        table.insert(debounceDict[name].acc, args)
        Events.OnTick.Remove(debounceDict[name].onTick);
    else 
        debounceDict[name] = {
            func = func,
            ticks = 0,
            acc = {args},
            startTime = os.time(),
        }
    end

    debounceDict[name].onTick = function ()
        if not debounceDict[name] then
            return
        end
        local ticks = debounceDict[name].ticks

        if ticks < delay then
            ticks = ticks + 1;
            debounceDict[name].ticks = ticks
        else
            --print('Zip Container debounce time: ', os.time() - debounceDict[name].startTime)
            debounceDict[name].func(args, debounceDict[name].acc)
            Events.OnTick.Remove(debounceDict[name].onTick);
            debounceDict[name] = nil
        end
    end

    Events.OnTick.Add(debounceDict[name].onTick);
end

return {
    delay = delayFn,
    debounce = debounceFn,
    -- getWhiteListArr = getWhiteListArr,
}