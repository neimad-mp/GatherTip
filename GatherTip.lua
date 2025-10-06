-- GatherTip 1.3 (Turtle/Vanilla 1.12)
-- Herbalism + Mining: one extra tooltip line with CLASSIC color bands.
-- Fix: never add more than one line; update same line instead.

---------------------------------------------------------------
-- Herb requirements (Classic)
---------------------------------------------------------------
local HERB_REQ = {
  ["Peacebloom"]           = 1,
  ["Silverleaf"]           = 1,
  ["Earthroot"]            = 15,
  ["Mageroyal"]            = 50,
  ["Briarthorn"]           = 70,
  ["Stranglekelp"]         = 85,
  ["Bruiseweed"]           = 100,
  ["Wild Steelbloom"]      = 115,
  ["Grave Moss"]           = 120,
  ["Kingsblood"]           = 125,
  ["Liferoot"]             = 150,
  ["Fadeleaf"]             = 160,
  ["Goldthorn"]            = 170,
  ["Khadgar's Whisker"]    = 185,
  ["Wintersbite"]          = 195,
  ["Firebloom"]            = 205,
  ["Purple Lotus"]         = 210,
  ["Arthas' Tears"]        = 220,
  ["Sungrass"]             = 230,
  ["Blindweed"]            = 235,
  ["Ghost Mushroom"]       = 245,
  ["Gromsblood"]           = 250,
  ["Golden Sansam"]        = 260,
  ["Dreamfoil"]            = 270,
  ["Mountain Silversage"]  = 280,
  ["Plaguebloom"]          = 285,
  ["Icecap"]               = 290,
  ["Black Lotus"]          = 300,
}

---------------------------------------------------------------
-- Mining requirements (Classic)
---------------------------------------------------------------
local MINING_REQ = {
  ["Copper Vein"]                    = 1,
  ["Tin Vein"]                       = 65,
  ["Silver Vein"]                    = 75,
  ["Iron Deposit"]                   = 125,
  ["Gold Vein"]                      = 155,
  ["Mithril Deposit"]                = 175,
  ["Truesilver Deposit"]             = 230,
  ["Dark Iron Deposit"]              = 230,
  ["Small Thorium Vein"]             = 245,
  ["Rich Thorium Vein"]              = 275,
  ["Small Obsidian Chunk"]           = 305,
  ["Large Obsidian Chunk"]           = 305,
  
  ["Ooze Covered Silver Vein"]       = 75,
  ["Ooze Covered Gold Vein"]         = 155,
  ["Ooze Covered Mithril Deposit"]   = 175,
  ["Ooze Covered Truesilver Deposit"]= 230,
  ["Ooze Covered Thorium Vein"]      = 245,
  ["Ooze Covered Rich Thorium Vein"] = 275,

  ["Incendicite Mineral Vein"]       = 65,
  ["Lesser Bloodstone Deposit"]      = 75,
  ["Hakkari Thorium Vein"]           = 275,
}

---------------------------------------------------------------
-- Classic gathering color bands
---------------------------------------------------------------
local function DiffColor(req, cur)
  if cur < req        then return 1.0, 0.1, 0.1 end   -- red
  if cur < req + 25   then return 1.0, 0.5, 0.0 end   -- orange
  if cur < req + 50   then return 1.0, 1.0, 0.2 end   -- yellow
  if cur < req + 100  then return 0.3, 1.0, 0.3 end   -- green
  return 0.6, 0.6, 0.6                                -- grey
end

---------------------------------------------------------------
-- Skill reads (Vanilla)
---------------------------------------------------------------
local function GetSkillRankByName(skillName)
  local n = GetNumSkillLines()
  for i = 1, n do
    local name, isHeader, _, rank = GetSkillLineInfo(i)
    if not isHeader and name == skillName then
      return rank or 0
    end
  end
  return 0
end

local function GetHerbalismRank() return GetSkillRankByName("Herbalism") end
local function GetMiningRank()    return GetSkillRankByName("Mining")    end

---------------------------------------------------------------
-- One-line augmentation with a tooltip "bookmark"
---------------------------------------------------------------
-- We store the line index we add on GameTooltip.HerbTipLine
-- and simply update that line on subsequent passes.

local function ClearBookmark()
  GameTooltip.HerbTipLine = nil
  GameTooltip.HerbTipName = nil
end

local function AugmentTooltip()
  local first = GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
  if not first or first == "" then return end

  -- Decide which table applies
  local req = HERB_REQ[first]
  local cur
  if req then
    cur = GetHerbalismRank()
  else
    req = MINING_REQ[first]
    if req then
      cur = GetMiningRank()
    else
      -- Not a herb or mining node; clear our bookmark if we had one
      return
    end
  end

  local text = string.format("%d / %d", req, cur)
  local r, g, b = DiffColor(req, cur)

  local idx = GameTooltip.HerbTipLine
  if idx and GameTooltip.HerbTipName == first then
    -- Update existing line
    local line = _G["GameTooltipTextLeft"..idx]
    if line then
      line:SetText(text)
      line:SetTextColor(r, g, b)
    else
      -- Our stored index is stale; fall through and re-add
      idx = nil
    end
  end

  if not idx then
    GameTooltip:AddLine(text, r, g, b)
    GameTooltip:Show()
    GameTooltip.HerbTipLine = GameTooltip:NumLines()
    GameTooltip.HerbTipName = first
  end
end

---------------------------------------------------------------
-- Hooks (Vanilla-safe)
---------------------------------------------------------------
-- Clear our bookmark on hide/owner change
local orig_OnHide = GameTooltip:GetScript("OnHide")
GameTooltip:SetScript("OnHide", function()
  if orig_OnHide then orig_OnHide() end
  ClearBookmark()
end)

local orig_SetOwner = GameTooltip.SetOwner
GameTooltip.SetOwner = function(self, owner, ...)
  ClearBookmark()
  return orig_SetOwner(self, owner, unpack(arg))
end

-- Update on show and while updating
local orig_OnShow = GameTooltip:GetScript("OnShow")
GameTooltip:SetScript("OnShow", function()
  if orig_OnShow then orig_OnShow() end
  AugmentTooltip()
end)

local orig_OnUpdate = GameTooltip:GetScript("OnUpdate")
GameTooltip:SetScript("OnUpdate", function()
  if orig_OnUpdate then orig_OnUpdate() end
  AugmentTooltip()
end)
