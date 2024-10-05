-- CCAM - CCAM (Can't Carry Any More!) provides slash commands to show an alert if the selected bags are full.
-- Tuill of Pagle
-- Revisions:
-- 0.10 - Initial version, copy of template (by Tuill) source
-- 0.11 - Bump to prompt package build at Curse after approval
-- 0.12 - Removed most of the commented debugging code.
-- 0.13-- Bump interface for 1.13.5 Classic, refresh libs, clean up debug-only code
-- 0.14 - Reconcile dev and Curse package versions
-- 0.15 - Tag to prompt packaging after contact w/ Overwolf support
-- 0.16 - Bump & tag after move to Github
-- 0.17 - Rename of pkgmeta from .dotfile for visiblity
-- 0.18 - Trivial update testing customized changelog, update client version
-- 0.19 - Bump interface for 1.13.7 TBC Classic pre-pre-patch, refresh libs
-- 0.20 - Bump interface for 2.5.2, refresh libs
-- 0.21 - Bump interface for 2.5.3, refresh libs
-- 0.22 - Bump interface for 2.5.4, refresh libs
-- 0.23 - Bump interface for 3.4.0, refresh libs, break out TBC and Wrath TOCs
-- 0.24 - Bump interface for 3.4.1, refresh libs
-- 0.25 - Adjust GetContainerNumFreeSlots() to new, more "Retail" 3.4.1 form.
-- 0.26 - Bump interface for 1.14.4 classic, 3.4.3 wrath classic, refresh libs
-- 0.27 - Bump interface for 1.15.0 classic, 3.4.3 wrath classic, refresh libs, re-add .pkgmeta to troubleshoot Curse changelog
-- 0.28 - Initial for Cata Classic, refresh libs. UPDATE - Bump version and interface for Classic-Classic. UPDATE - Bump again 1.15.4.


-- All comments by Tuill
-- I recommend a Lua-aware editor like SciTE that provides syntactic highlighting.

-- No global for now

-- local scope identifier for performance and template-ability
local ourAddon = LibStub("AceAddon-3.0"):NewAddon("CCAM", "AceConsole-3.0")

-- local scope identifiers for util functions
local strlower = strlower
local strfind = strfind
local strsplit = strsplit
local tonumber = tonumber
local tostring = tostring
local table_insert = table.insert
local table_sort = table.sort
local RaidNotice_AddMessage = RaidNotice_AddMessage
local PlaySoundFile = PlaySoundFile

-- Fetch version & notes from TOC file
local ourVersion = GetAddOnMetadata("CCAM", "Version")
local ourNotes = GetAddOnMetadata("CCAM", "Notes")

-- Multi-line string for the help text, color codes inline
local helpUsing = [[
Slash commands |cffeeee33/ccam|r or |cffeeee33/cca|r :

|cffeeee33/ccam #
/ccam #,#
/ccam #-#
/ccam #-#,#|r

...Shows an on-screen alert if there are no free bag slots in the specified bags. # indicates a bag ID to check, #,# being multiple bags, and #-# an inclusive range of bags, with the backpack being bag 0 and player bags being 1 (closest to the backpack) thru 4 (furthest to the left).

The default message is simply "BAGS FULL", but anything you put after the bag selection string will be displayed as the alert:

|cffeeee33/ccam 0-3 No space left in regular bags!|r

|r
]]

ourAddon.ccamExampleText = [[
/ccam 0-2,4
]]

StaticPopupDialogs["CCAM_EXAMPLE"] = {
  text = "Example Macro:",
  button1 = "OK",
  OnShow = function (self, data)
    self.editBox:SetMultiLine(true)
  self.editBox:SetHeight(50)
  --self.editBox:GetParent():SetBackdrop(nil) -- Works for entire Dialog
  self.editBox:DisableDrawLayer("BACKGROUND")
    self.editBox:SetText(ourAddon.ccamExampleText)
  self.editBox:HighlightText()
  self:Show()
  end,
  hasEditBox = true,
  hasWideEditBox = true,
  editBoxWidth = 220,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,  -- avoid some UI taint, see http:/www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

-- Ace3 options table
-- RegisterOptionsTable can take a function ref for the options arg
-- Taking advantage of this in case we decide to dynamically adjust
-- at use-time
local function ourOptions()
  local options = {
   name = "CCAM",
   type = 'group',
   args = {
  general = {
    type = 'group',
    name = "Settings",
    args = {
      header1 =
      {
        order = 1,
        type = "header",
        name = "",
      },
      version =
      {
        order = 2,
        type = "description",
        name = "Version " .. ourVersion .. "\n",
      },
      usage =
      {
        type = "group",
        name = "Usage",
        desc = "Usage",
        guiInline = true,
        order = 3,
        args =
        {
          example =
          {
            order = 4,
            type = "execute",
            name = "Show Example Macro",
            desc = "",
            descStyle = "inline",
            func = function() StaticPopup_Show("CCAM_EXAMPLE") end,
          },
          about =
          {
            order = 5,
            type = "description",
            name = ourNotes.."\n",
            fontSize = "medium",
          },
          about2 =
          {
            order = 6,
            type = "description",
            name = helpUsing,
            fontSize = "medium",
          },
        },
      },
    },
  }, -- end using
   }, -- top args
  } -- end table
 return options
end

function ourAddon:OnInitialize()

  local ourConfig = LibStub("AceConfig-3.0")
  local ourConfigDialog = LibStub("AceConfigDialog-3.0") -- For snapping into the ESC menu addons list

  ourConfig:RegisterOptionsTable("CCAM", ourOptions)

  self.optionsFrames = {}
  self.optionsFrames.general = ourConfigDialog:AddToBlizOptions("CCAM", "CCAM", nil, "general")

  -- Create slash commands
  self:RegisterChatCommand("cca", "CcamPrehandler")
  self:RegisterChatCommand("ccam", "LongCcamPrehandler")
end

function ourAddon:CcamPrehandler(input)
  self:CcamHandler(input, "cca")
end

function ourAddon:LongCcamPrehandler(input)
  self:CcamHandler(input, "ccam")
end

function ourAddon:CcamHandler(input, slashCommand)
  -- Show addon config dialog as help if no args, we verify we're not in combat
  -- so it shouldn't be too annoying (better than just a blurt in the chat pane...)
  if input == "" then
    if InCombatLockdown() then
      self:Print("In combat, declining to show CCAM info.")
    else
      self:Print("Usage:\n|cffeeee33/"..slashCommand.." #|r\n|cffeeee33/"..slashCommand.." #,#|r\n|cffeeee33/"..slashCommand.." #,#-#|r \n|cffeeee33/"..slashCommand.." #,#-# Custom Message|r \n...where # is a bag ID to include.\nESC > Interface > Addons > CCAM for more.")
    end
  else
    self:CcamInputHandler(input, slashCommand)
  end
end

-- Functions defined in a do block so we could have pseudo-static variables
do

  function ourAddon:CcamInputHandler(input, slashCommand)
    local ourArgs, ourTarget, maxBag, freeSlots, chosenBags, splitArgs, commaTest, affectedBags, custMsg
    freeSlots = 0
    splitArgs = {}
    affectedBags = {[0] = false, [1] = false, [2] = false, [3] = false, [4] = false, invalidInput = true}
    ourArgs, ourTarget = SecureCmdOptionParse(input)
    if ((ourArgs == nil) or (ourArgs == "")) then
      -- No bag ID(s), so stop here
      -- If we're calling with macro options, ourArgs will
      -- be nil/empty in cases where there's no tests-true option,
      -- so correct behavior here is to silently return (do nothing).
      return
    end
	if ourArgs:find('%s+') then
      _, _, ourArgs, custMsg = ourArgs:find('^(%S+)%s+(.+)')
	else
	  _, _, ourArgs = ourArgs:find('^(%S+)')
	end
    commaTest = strfind(ourArgs, ",")
    if ( commaTest ~= nil ) then
      splitArgs = { strsplit(",", ourArgs) }
    else
      table_insert(splitArgs, ourArgs)
    end
    for ourI, ourValue in ipairs(splitArgs) do
      if ourValue ~= "" then
        affectedBags = ourAddon:ProcessArgs(ourValue, affectedBags)
      end
    end
    if affectedBags.invalidInput == true then
      self:Print("Usage:\n|cffeeee33/"..slashCommand.." #|r\n|cffeeee33/"..slashCommand.." #,#|r\n|cffeeee33/"..slashCommand.." #,#-#|r \n|cffeeee33/"..slashCommand.." #,#-# Custom Message|r \n...where # is a bag ID to include.\nESC > Interface > Addons > CCAM for more.")
      return
    end
    for bagKey, bagValue in pairs(affectedBags) do
      if bagKey then
        if bagValue == true then
		  freeSlots = freeSlots + C_Container.GetContainerNumFreeSlots(bagKey);
        else
		  -- Didn't choose to test this bag
        end
      end
    end
	if custMsg == "" or custMsg == nil then
	  custMsg = "BAGS FULL"
	end
    if freeSlots == 0 then
      RaidNotice_AddMessage(RaidWarningFrame, custMsg, ChatTypeInfo["RAID_WARNING"])
      PlaySoundFile("Sound\\Interface\\RaidWarning.ogg", "Master")
    end
  end

  function ourAddon:ProcessArgs(arglet, whichBags)
    local minMax, ourRange
    minMax = {}
    if strfind(arglet, "-") then
      ourRange = { strsplit("-", arglet) }
      for argI, argValue in ipairs(ourRange) do
        if argValue ~= "" then
          table_insert(minMax, argValue)
        end
      end
      if #minMax > 0 then
        table_sort(minMax)
      else
        self:Print("Error: No recognizable bag ID provided.")
        return whichBags
      end
      for step=tonumber(minMax[1]), tonumber(minMax[#minMax]), 1 do
        if whichBags[step] ~= nil then
          whichBags[step] = true
          whichBags.invalidInput = false
        end
      end
    else
      local ourIndex = tonumber(arglet)
      if whichBags[ourIndex] ~= nil then
        whichBags[ourIndex] = true
        whichBags.invalidInput = false
      end
    end
    return whichBags
  end

end -- end of do
