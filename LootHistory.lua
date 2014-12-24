-- LootHistory.lua: Manages the Loot History Frame

local addon = LibStub("AceAddon-3.0"):GetAddon("SolutionLC")
LootHistory = addon:NewModule("LootHistory", "AceTimer-3.0")

local self = LootHistory
local selection = {}; -- the current selection
local lootDB;
local offset = 0
local filterPasses = true;
local contentTable = {}

--[[ lootDB format:
	lootDB = {			
		"playerName" = {
					[#] = {"lootWon", "date (d/m/y)", "time (h:m:s)", "instance", "boss", "votes", "itemReplaced1", "itemReplaced2", "response", "responseID"}
		},
	}
]]

function LootHistory:OnLoad()
	-- create the entries
	local entry = CreateFrame("Button", "$parentEntry1", RCLootHistoryFrameScrollFrame, "RCLootHistoryEntry")
	entry:SetID(1)
	entry:SetPoint("TOPLEFT", 4, -4)
	for i = 2, 13 do
		entry = CreateFrame("Button", "$parentEntry"..i, RCLootHistoryFrameScrollFrame, "RCLootHistoryEntry")
		entry:SetID(i)
		entry:SetPoint("TOP", "$parentEntry"..(i-1), "BOTTOM")
	end	
	-- create dropdown frame
	dropDownFrame = CreateFrame("FRAME", nil, RCLootHistoryFrame, "UIDropDownMenuTemplate")
end

function LootHistory:OnEnable()
	wipe(contentTable)
	lootDB = SolutionLC.db.factionrealm.lootDB -- get the db
	-- get all player names
	local i = 1;
	for k,v in pairs(lootDB) do
		for a,b in pairs(v) do
			if filterPasses and b["responseID"] == SolutionLC.db.profile.dbToSend.passButton then
				-- do nothing
			else
				contentTable[i] = b
				contentTable[i].playerName = k;
				i = i + 1
			end
		end
	end
	LootHistoryFrame:Show()
	LootHistory:Update()
	LootHistory:UpdateSelection()
end

function LootHistory:OnDisable()
	

end

function LootHistory:Update()
	FauxScrollFrame_Update(RCLootHistoryFrameScrollFrame, #contentTable, 13, 20, nil, nil, nil, nil, nil, nil, true);
	offset = FauxScrollFrame_GetOffset(RCLootHistoryFrameScrollFrame)
	local mlDB = SolutionLC:GetVariable("mlDB")
	local frame = "RCLootHistoryFrameScrollFrame"
	for i = 1, 13 do
		local line = offset + i
		if contentTable[line] then
			getglobal(frame.."Entry"..i.."String1"):SetText(contentTable[line]["playerName"])
			getglobal(frame.."Entry"..i.."String2"):SetText(contentTable[line]["date"])
			getglobal(frame.."Entry"..i.."String3"):SetText(contentTable[line]["lootWon"])
			getglobal(frame.."Entry"..i.."String4"):SetText(contentTable[line]["response"])

			if contentTable[line]["responseID"] == 0 then -- not a button response
				getglobal(frame.."Entry"..i.."String4"):SetTextColor(1,0,0,1)
			else
				local color = mlDB.buttons[contentTable[line]["responseID"]]["color"]
				getglobal(frame.."Entry"..i.."String4"):SetTextColor(color[1],color[2],color[3],color[4])
			end
			
			getglobal(frame.."Entry"..i):Show()
		else
			getglobal(frame.."Entry"..i):Hide()
		end
	end
end

function LootHistory:IsSelected(id)
	id = id + offset -- handle the offset
	return selection == id;
end

function LootHistory:Select(id)
	id = id + offset
	selection = contentTable[id]
	LootHistory:UpdateSelection()
end	

function LootHistory:UpdateSelection()
	local frame = "RCLootHistoryFrameString"
	if selection.playerName then
		local numLoots, numTime, numMSloot = 0, 0, 0
		for k,v in pairs(lootDB[selection.playerName]) do
			if v.lootWon and v.lootWon ~= "" then numLoots = numLoots + 1 end
			if v.responseID and v.responseID == 1 then numMSloot = numMSloot + 1 end
		end
		numTime = SolutionLC:GetNumberOfDaysFromNow(lootDB[selection.playerName][1].date)
			
		getglobal(frame.."1"):SetText(selection.playerName)
		getglobal(frame.."1"):Show()
		getglobal(frame.."2"):SetText("Mainspec rolls won: "..numMSloot)
		getglobal(frame.."2"):Show()
		getglobal(frame.."3"):SetText("Recieved "..numLoots.." items during the last "..numTime)
		getglobal(frame.."3"):Show()
	else -- remove it
		getglobal(frame.."1"):Hide()
		getglobal(frame.."2"):Hide()
		getglobal(frame.."3"):Hide()
	end
end

function LootHistory:MouseOver(id)
	id = id + offset
	local dateString = SolutionLC:GetNumberOfDaysFromNow(contentTable[id].date)
	local _, _, _,ilvl = GetItemInfo(string.match(contentTable[id].lootWon, "|%x+|Hitem:.-|h.-|h|r"));
	GameTooltip:SetOwner(RCLootHistoryFrame, "ANCHOR_RIGHT", 0, -150)
	GameTooltip:AddDoubleLine("Time since loot recieved:",		dateString, 1,1,1, 1,1,1)
	GameTooltip:AddDoubleLine("Item given:",					contentTable[id].lootWon, 1,1,1, 1,1,1)
	GameTooltip:AddDoubleLine("ilvl:",							ilvl, 1,1,1, 1,1,1)
	GameTooltip:AddDoubleLine("Dropped by:",					contentTable[id].boss, 1,1,1, 0.862745, 0.0784314, 0.235294)
	GameTooltip:AddDoubleLine("From:",							contentTable[id].instance, 1,1,1, 0.823529, 0.411765, 0.117647)
	GameTooltip:AddDoubleLine("Item(s) replaced:",				contentTable[id].itemReplaced1, 1,1,1, 1,1,1)
	if contentTable[id].itemReplaced2 ~= "" then
		GameTooltip:AddDoubleLine(" ",							contentTable[id].itemReplaced2, 1,1,1, 1,1,1)
	end
	GameTooltip:AddDoubleLine("Dropped at:",					contentTable[id].time.." - "..contentTable[id].date, 1,1,1, 1,1,1)
	GameTooltip:AddDoubleLine(contentTable[id].playerName.."'s response:",contentTable[id].response, 1,1,1, 1,1,1)
	GameTooltip:AddDoubleLine("Votes for player:",				contentTable[id].votes, 1,1,1, 1,1,1)
	GameTooltip:Show()
end

function LootHistory:GetFilterPasses()
	return filterPasses;
end

function LootHistory:SetFilterPasses()
	filterPasses = not filterPasses
	LootHistory:OnEnable() -- rebuild the contentTable
	return filterPasses;
end

function LootHistory:Close()
	RCLootHistoryFrame:Hide()
	SolutionLC:DisableModule("LootHistory")
end
