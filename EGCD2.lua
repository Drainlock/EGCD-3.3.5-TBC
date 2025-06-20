EGCD2DB = EGCD2DB or { iconsize = 30, arenaOnly = false, lock = false, }
local abilities = {}
local band = bit.band

local spellids = {[72] = 1.5, [469] = 1.5, [676] = 1.5, [1680] = 1.5,
[2048] = 1.5, [5246] = 1.5, [6552] = 1.5, [25208] = 1.5, [30330] = 1.5, [25212] = 1.5,
[25264] = 1.5, [25266] = 1.5, [11585] = 1.5, [25203] = 1.5, [25236] = 1.5,
[12323] = 1.5, [25225] = 1.5, [12292] = 1.5, [18499] = 1.5, [20594] = 1.5,
[20589] = 1.5, [7744] = 1.5, [20600] = 1.5, [25046] = 1.5, [38768] = 1, [26862] = 1,
[26863] = 1, [26864] = 1, [14278] = 1, [34097] = 1, [5940] = 1, [34413] = 1,
[38764] = 1, [31224] = 1, [2094] = 1, [1725] = 1, [26679] = 2, [32684] = 1,
[26866] = 1, [26865] = 1, [8643] = 1, [6774] = 1, [13877] = 1, [13750] = 1,
[14185] = 1, [27277] = 1.5, [27280] = 1.5, [19647] = 1.5, }

-- Initialize abilities
for spellid, time in pairs(spellids) do
    local name, _, spellicon = GetSpellInfo(spellid)
    if name then
        abilities[name] = { icon = spellicon, duration = time }
    end
end

-- Initialize order with spell IDs
local order = {}
for spellid in pairs(spellids) do
    table.insert(order, spellid)
end

-- Convert spell IDs to spell names for order
for k, v in ipairs(order) do
    local name = GetSpellInfo(v)
    if name then
        order[k] = name
    else
        order[k] = nil -- Remove invalid spell IDs
    end
end
-- Filter out nil entries
order = { unpack(order) }

-- Create order index for sorting
local orderIndex = {}
for i, ability in ipairs(order) do
    orderIndex[ability] = i
end

local frame, bar

local GetTime = GetTime
local ipairs = ipairs
local pairs = pairs
local bit_band = bit.band
local GetSpellInfo = GetSpellInfo

local GROUP_UNITS = bit.bor(0x00000010, 0x00000400)

local activetimers = {}

local size = 0
local function getsize()
    size = 0
    for k in pairs(activetimers) do size = size + 1
    end
end

local function EGCD2DB_AddIcons()
    for _, ability in ipairs(order) do
        local btn = CreateFrame("Frame", nil, bar)
        btn:SetSize(EGCD2DB.iconsize, EGCD2DB.iconsize)
        btn:SetFrameStrata("LOW")
        
		local cd = CreateFrame("Cooldown", nil, btn)
        cd.noomnicc = true
        cd:SetAllPoints(true)
        cd:SetFrameStrata("MEDIUM")
		cd:SetDrawBling(false)
        cd:Hide()
        
        local texture = btn:CreateTexture(nil, "BACKGROUND")
        texture:SetAllPoints(true)
        texture:SetTexture(abilities[ability].icon)
        texture:SetTexCoord(0.07, 0.9, 0.07, 0.9)
        
        btn.texture = texture
        btn.duration = abilities[ability].duration
        btn.cd = cd
        
        bar[ability] = btn
    end
end

function EGCD2DB_RearrangeButtons()
    if EGCD2DB.arenaOnly and not arena then
        -- Hide all buttons and shrink bar if not in arena
        for ability in pairs(abilities) do
            local btn = bar[ability]
            if btn then
                btn:Hide()
            end
        end
        bar:SetWidth(1)
    else
        -- Collect active abilities from activetimers
        local activeAbilities = {}
        for ability in pairs(activetimers) do
            table.insert(activeAbilities, ability)
        end
        table.sort(activeAbilities, function(a, b)
            return orderIndex[a] < orderIndex[b]
        end)
        -- Position active buttons
        local x = 0
        for _, ability in ipairs(activeAbilities) do
            local btn = bar[ability]
            if btn then
                btn:ClearAllPoints()
				btn:SetPoint("CENTER", bar, "CENTER", x, 0)
                btn:Show()
                x = x + EGCD2DB.iconsize + 2 -- Move right by icon size + gap
            end
        end
        -- Hide buttons for abilities not on cooldown
        for ability in pairs(abilities) do
            if not activetimers[ability] then
                local btn = bar[ability]
                if btn then
                    btn:Hide()
                end
            end
        end
        -- Adjust bar width based on number of active buttons
        bar:SetWidth(math.max(x, EGCD2DB.iconsize))
    end
end

local function EGCD2DB_SavePosition()
    local point, _, relativePoint, xOfs, yOfs = bar:GetPoint()
    if not EGCD2DB.Position then 
        EGCD2DB.Position = {}
    end
    EGCD2DB.Position.point = point
    EGCD2DB.Position.relativePoint = relativePoint
    EGCD2DB.Position.xOfs = xOfs
    EGCD2DB.Position.yOfs = yOfs
end

local function EGCD2DB_LoadPosition()
    if EGCD2DB.Position then
        bar:SetPoint(EGCD2DB.Position.point, UIParent, EGCD2DB.Position.relativePoint, EGCD2DB.Position.xOfs, EGCD2DB.Position.yOfs)
    else
        bar:SetPoint("CENTER", UIParent, "CENTER")
    end
end

local function EGCD2DB_UpdateBar()
    for ability in pairs(abilities) do
        local btn = bar[ability]
        btn:SetSize(EGCD2DB.iconsize, EGCD2DB.iconsize)
    end
    if EGCD2DB.lock then
        bar:EnableMouse(false)
    else
        bar:EnableMouse(true)
    end
    EGCD2DB_RearrangeButtons()
end

local function EGCD2DB_CreateBar()
    bar = CreateFrame("Frame", nil, UIParent)
    bar:SetMovable(true)
    bar:SetSize(EGCD2DB.iconsize, EGCD2DB.iconsize)
    bar:SetClampedToScreen(true) 
    bar:SetScript("OnMouseDown", function(self, button) if button == "LeftButton" then self:StartMoving() end end)
    bar:SetScript("OnMouseUp", function(self, button) if button == "LeftButton" then self:StopMovingOrSizing() EGCD2DB_SavePosition() end end)
    bar:Show()
    
    EGCD2DB_AddIcons()
    EGCD2DB_UpdateBar()
    EGCD2DB_LoadPosition()
end

local function EGCD2DB_StopAbility(ref, ability)
    activetimers[ability] = nil
    ref.cd:Hide()
    EGCD2DB_RearrangeButtons()
end

local time = 0
local function EGCD2DB_OnUpdate(self, elapsed)
    time = time + elapsed
    if time > 0.25 then
        getsize()
        for ability, ref in pairs(activetimers) do
            ref.cooldown = ref.start + ref.duration - GetTime()
            if ref.cooldown <= 0 then
                EGCD2DB_StopAbility(ref, ability)
            end
        end
	   
									 
        if size == 0 then frame:SetScript("OnUpdate", nil) end
        time = time - 0.25
    end
end

local function EGCD2DB_StartTimer(ref, ability)
    if not activetimers[ability] then
        activetimers[ability] = ref
        ref.cd:Show()
        ref.cd:SetCooldown(GetTime(), ref.duration)												  
        ref.start = GetTime()
        EGCD2DB_RearrangeButtons()
    end
    frame:SetScript("OnUpdate", EGCD2DB_OnUpdate)
end

local function EGCD2DB_COMBAT_LOG_EVENT_UNFILTERED(...)
    if EGCD2DB.arenaOnly and not arena then
        return
    end
    local spellID, ability, useSecondDuration
    return function(_, eventtype, _, srcName, srcFlags, _, dstName, dstFlags, id)
        if (band(srcFlags, 0x00000040) == 0x00000040 and (eventtype == "SPELL_CAST_SUCCESS" or eventtype == "SPELL_AURA_APPLIED" or eventtype == "SPELL_DAMAGE")) then
            spellID = id
        else
            return
        end
        if (band(srcFlags, 0x00000040) ~= 0x00000040 or band(srcFlags, 0x00000400) == 0) then -- check to skip non-player sources
            return
        end
        useSecondDuration = false
        ability = GetSpellInfo(spellID)
        if abilities[ability] then
            EGCD2DB_StartTimer(bar[ability], ability)
        end
    end
end

EGCD2DB_COMBAT_LOG_EVENT_UNFILTERED = EGCD2DB_COMBAT_LOG_EVENT_UNFILTERED()

local function EGCD2DB_ResetAllTimers()
    for ability in pairs(activetimers) do
        local ref = bar[ability]
        if ref then
            ref.cd:Hide()
            ref:Hide()
        end
    end
    activetimers = {}
    EGCD2DB_RearrangeButtons()
end

local function isInArena()
    local _, instanceType = IsInInstance()
    return instanceType == "arena"
end

local function EGCD2DB_PLAYER_ENTERING_WORLD(self)
    arena = isInArena()
    if EGCD2DB.arenaOnly and not arena then
        EGCD2DB_ResetAllTimers()
    end
    EGCD2DB_RearrangeButtons()
end

local function EGCD2DB_Reset()
    EGCD2DB = { iconsize = 30, arenaOnly = false, lock = false }
    EGCD2DB_UpdateBar()
    EGCD2DB_LoadPosition()
end

local testFrame = CreateFrame("Frame")
local testTimer = 0
local testIndex = 1
local oldArenaOnly = false
local function EGCD2DB_TestUpdate(self, elapsed)
    testTimer = testTimer + elapsed
    if testTimer >= 1 then
        if testIndex <= #order then
            local ability = order[testIndex]
            if bar[ability] then
                EGCD2DB_StartTimer(bar[ability], ability)
            end
            testIndex = testIndex + 1
            testTimer = 0
        else
            testFrame:SetScript("OnUpdate", nil)
            EGCD2DB.arenaOnly = oldArenaOnly	  
            testIndex = 1
            testTimer = 0
        end
    end
end

local function EGCD2DB_Test()
    print("Starting EGCD2 test")
    oldArenaOnly = EGCD2DB.arenaOnly
    EGCD2DB.arenaOnly = false
    testIndex = 1; testTimer = 0
    testFrame:SetScript("OnUpdate", EGCD2DB_TestUpdate)
end

local cmdfuncs = {
    ["size"] = function(v)
        if v and v >= 10 and v <= 100 then
            EGCD2DB.iconsize = v
            EGCD2DB_UpdateBar()
            ChatFrame1:AddMessage("EGCD2 icon size set to " .. v, 0, 1, 0)
        else
            ChatFrame1:AddMessage("Invalid icon size. Use a number between 10 and 100.", 1, 0, 0)
        end
    end,
    arenaonly = function()
        EGCD2DB.arenaOnly = not EGCD2DB.arenaOnly
        ChatFrame1:AddMessage("EGCD2 bar now " .. (EGCD2DB.arenaOnly and "only shows in arenas" or "shows everywhere"), 0, 1, 0)
        if EGCD2DB.arenaOnly and not arena then
            EGCD2DB_ResetAllTimers()
        end
        EGCD2DB_UpdateBar()
    end,
    lock = function()
        EGCD2DB.lock = not EGCD2DB.lock
        ChatFrame1:AddMessage("EGCD2 bar now " .. (EGCD2DB.lock and "locked" or "unlocked"), 0, 1, 0)
        EGCD2DB_UpdateBar()
    end,
    reset = function() EGCD2DB_Reset() end,
    test = function() EGCD2DB_Test() end,
}

local cmdtbl = {}
function EGCD2DB_Command(cmd)
    for k in pairs(cmdtbl) do
        cmdtbl[k] = nil
    end
    for v in string.gmatch(cmd, "[^ ]+") do
        table.insert(cmdtbl, v)
    end
    local cb = cmdfuncs[cmdtbl[1]] 
    if cb then
        local s = tonumber(cmdtbl[2])
        if s then
            cb(s)
        else
            cb()
        end
    else
        ChatFrame1:AddMessage("EGCD2DB Options | /egcd <option>", 0, 1, 0)        
        ChatFrame1:AddMessage("-- size <number> | value: " .. EGCD2DB.iconsize, 0, 1, 0)
        ChatFrame1:AddMessage("-- arenaonly (toggle) | value: " .. tostring(EGCD2DB.arenaOnly), 0, 1, 0)
        ChatFrame1:AddMessage("-- lock (toggle) | value: " .. tostring(EGCD2DB.lock), 0, 1, 0)
        ChatFrame1:AddMessage("-- test (execute)", 0, 1, 0)
        ChatFrame1:AddMessage("-- reset (execute)", 0, 1, 0)
    end
end

local function EGCD2DB_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    if not EGCD2DB.iconsize then EGCD2DB.iconsize = 30 end
    if not EGCD2DB.arenaOnly then EGCD2DB.arenaOnly = false end
    if not EGCD2DB.lock then EGCD2DB.lock = false end
    EGCD2DB_CreateBar()
    
    SlashCmdList["EGCD2DB"] = EGCD2DB_Command
    SLASH_EGCD2DB1 = "/egcd"
    
    ChatFrame1:AddMessage("|cff77FF24Enemy global cooldown|r by |cff835EF0Drainlock|r. Type |cff77FF24/egcd|r for options.")
end

local eventhandler = {
    ["VARIABLES_LOADED"] = function(self) EGCD2DB_OnLoad(self) end,
    ["PLAYER_ENTERING_WORLD"] = function(self) EGCD2DB_PLAYER_ENTERING_WORLD(self) end,
    ["COMBAT_LOG_EVENT_UNFILTERED"] = function(self, ...) EGCD2DB_COMBAT_LOG_EVENT_UNFILTERED(...) end,
}

local function EGCD2DB_OnEvent(self, event, ...)
    eventhandler[event](self, ...)
end

frame = CreateFrame("Frame", nil, UIParent)
frame:SetScript("OnEvent", EGCD2DB_OnEvent)
frame:RegisterEvent("VARIABLES_LOADED")