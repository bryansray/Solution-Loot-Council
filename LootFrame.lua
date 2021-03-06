local MAX_VISIBLE_FRAMES = 5;
local db, buttonsDB;
local itemsLooting = {}
local lootFrames = {}
local buttonsWidth = 0
local _;

function SolutionLC_LootFrame:CreateFrame(id)
	SolutionLC:debugS("LootFrame:CreateFrame("..tostring(id)..")")
	local frame = CreateFrame("Frame", "$parentEntry"..id, SolutionLootFrame, "SolutionLootFrameEntry")
	frame:SetPoint("TOPLEFT", SolutionLootFrame)
	frame:SetID(id)

	-- Note button
	StaticPopupDialogs["LOOTFRAME_NOTE"] = {
		text = "Enter your note:",
		button1 = "Done",
		button2 = "Cancel",
		OnAccept = function(self)
			self.frame.note = self.editBox:GetText()
		end,
		enterClicksFirstButton = true,
		hasEditBox = true,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3, 	
	}

	local noteButton = CreateFrame("Button", nil, frame)
	noteButton:SetWidth(25)
    noteButton:SetHeight(25)
    noteButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    noteButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)

    local noteButtonIcon = noteButton:CreateTexture(nil, "BACKGROUND")
    noteButtonIcon:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    noteButtonIcon:SetPoint("CENTER", noteButton, "CENTER", 0, 1)
    noteButtonIcon:SetHeight(14)
    noteButtonIcon:SetWidth(12)

    local noteButtonOverlay = noteButton:CreateTexture(nil, "OVERLAY")
    noteButtonOverlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    noteButtonOverlay:SetWidth(42)
    noteButtonOverlay:SetHeight(42)
    noteButtonOverlay:SetPoint("TOPLEFT")

    noteButton:RegisterForClicks("AnyUp")

    noteButton:SetScript("OnClick", function()
        local dialog = StaticPopup_Show("LOOTFRAME_NOTE");
		if dialog then
			dialog.frame = frame
		end
    end)

    noteButton:SetScript("OnMouseDown", function(self)
        noteButtonIcon:SetTexCoord(.1,.9,.1,.9)
    end)
    noteButton:SetScript("OnMouseUp", function(self)
        noteButtonIcon:SetTexCoord(0,1,0,1)
    end)

    noteButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "BOTTOMRIGHT")
        GameTooltip:AddLine("Add note")
        GameTooltip:AddLine("Click this to add a note to send to the master looter.",.8,.8,.8,1, true)
        GameTooltip:Show()
    end)
    noteButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    noteButton:EnableMouse(true)

	frame.noteButton = noteButton;
	frame.note = nil
	frame.buttons = {}

	return frame;
end

function SolutionLC_LootFrame:AddItem(lootTable, item)
	local i = table.getn(lootTable)
	local index = 1;

	tinsert(itemsLooting, { item = item, position = i });
	
	local name, link, _, ilvl, _, _, _, _, _, texture = GetItemInfo(item)
	local frame = lootFrames[i];
	
	if not frame then
		frame = SolutionLC_LootFrame:CreateFrame(i);
		lootFrames[i] = frame;
	end
	
	frame.item = item
	frame.id = i;
	frame.index = index;
	
	for j = 1, db.numButtons do
		local button = frame.buttons[j]
		if not button then -- create it
			button = CreateFrame("button", "$parentButton"..j, frame, "SolutionLootFrame_Button")
			button:SetID(j)				
			if j == 1 then -- first needs specific anchor
				button:SetPoint("BOTTOMLEFT", 65, 10)				
			else
				button:SetPoint("TOPLEFT", "$parentButton"..(j-1), "TOPRIGHT", 5, 0)				
			end	
			button:Show()
			frame.buttons[j] = button				
		end
		-- Always update the text in case of changes
		local length = #(buttonsDB[j]["text"]) * 10 - 20; -- calculate length
		if length < 66 then length = 66 end -- minimun is 66px
		button:SetText(buttonsDB[j]["text"])
		button:SetWidth(length)

		-- Frame and mouseover width
		local count = 18
		if strlen(name) > count then
			count = strlen(name)
		end
		local lootFrameWidth = 155
		local hoverWidth = count * 10 - 40

		-- Get the width of each button
		for k, but in pairs(frame.buttons) do
			if k > db.numButtons then break; end -- don't get it too wide
			lootFrameWidth = lootFrameWidth + but:GetWidth()
		end

		-- make sure the width doesn't get less than the length of the item
		if lootFrameWidth - 50 < hoverWidth then lootFrameWidth = hoverWidth + 50; end 
		SolutionLootFrame:SetWidth(lootFrameWidth)

		frame:SetWidth(lootFrameWidth)
		getglobal("SolutionLootFrameEntry"..i.."Hover2"):SetWidth(hoverWidth)
		getglobal("SolutionLootFrameEntry"..i.."ItemLabel"):SetText(link);
		getglobal("SolutionLootFrameEntry"..i.."ItemLabel"):SetFont("Fonts\\FRIZQT__.TTF", 16);
		getglobal("SolutionLootFrameEntry"..i.."Texture"):SetTexture(texture);
		getglobal("SolutionLootFrameEntry"..i.."Ilvl"):SetText("ilvl: "..ilvl);
		getglobal("SolutionLootFrameEntry"..i.."Ilvl"):SetPoint("TOPRIGHT", "$parent", "TOPRIGHT", -2, -5)
		SolutionLootFrame:SetHeight(i * 75)
		SolutionLootFrame:SetWidth(lootFrameWidth)
		frame:Show();
		lootFrames[i] = frame
	end
	for j = db.numButtons+1, #frame.buttons do -- throw away not used buttons
		if frame.buttons[j] then
			frame.buttons[j]:Hide()
			frame.buttons[j]:SetParent(nil)
		end
	end
	-- Anchor the frames correctly
	if i > 1 then
		lootFrames[i]:SetPoint("TOPLEFT", lootFrames[i-1], "BOTTOMLEFT")
	end
	
	SolutionLootFrame:Show()
end

function SolutionLC_LootFrame:Update(lootTable, newRollRequest)
	-- only edit the lootTable when we recieve it from the ML
	-- and actually create a new table, not just reference
	if lootTable then
		wipe(itemsLooting)
		for k, v in ipairs(lootTable) do
			itemsLooting[k] = { item = v, position = k}
		end
	end 
	if newRollRequest then
		local test = true
		for _,v in pairs(itemsLooting) do
			if v.item == newRollRequest.item then test = false; end
		end
		if test then tinsert(itemsLooting, newRollRequest); end
	end
	local numFrames = 0
	db = SolutionLC:GetVariable("mlDB")
	buttonsDB = db.buttons
	
	for i,_ in ipairs(itemsLooting) do
		if not itemsLooting[i] then break; end 		
		numFrames = numFrames + 1

		if numFrames > MAX_VISIBLE_FRAMES then break end -- only show the max number of frames

		local name, link, _, ilvl, _, _, _, _, _, texture = GetItemInfo(itemsLooting[i].item)

		local frame = lootFrames[i]
		if not frame then
			frame = SolutionLC_LootFrame:CreateFrame(i)
			lootFrames[i] = frame
		end
		frame.item = itemsLooting[i].item
		frame.id = itemsLooting[i].position
		if not db.allowNotes then
			frame.noteButton:Hide()
		else
			frame.noteButton:Show()
		end

		-- Create/show the buttons
		for j = 1, db.numButtons do
			local button = frame.buttons[j]
			if not button then -- create it
				button = CreateFrame("button", "$parentButton"..j, frame, "SolutionLootFrame_Button")
				button:SetID(j)				
				if j == 1 then -- first needs specific anchor
					button:SetPoint("BOTTOMLEFT", 65, 10)				
				else
					button:SetPoint("TOPLEFT", "$parentButton"..(j-1), "TOPRIGHT", 5, 0)				
				end	
				button:Show()
				frame.buttons[j] = button				
			end
			-- Always update the text in case of changes
			local length = #(buttonsDB[j]["text"]) * 10 - 20; -- calculate length
			if length < 66 then length = 66 end -- minimun is 66px
			button:SetText(buttonsDB[j]["text"])
			button:SetWidth(length)

			-- Frame and mouseover width
			local count = 18
			if strlen(name) > count then
				count = strlen(name)
			end
			local lootFrameWidth = 155
			local hoverWidth = count * 10 - 40

			-- Get the width of each button
			for k, but in pairs(frame.buttons) do
				if k > db.numButtons then break; end -- don't get it too wide
				lootFrameWidth = lootFrameWidth + but:GetWidth()
			end

			-- make sure the width doesn't get less than the length of the item
			if lootFrameWidth - 50 < hoverWidth then lootFrameWidth = hoverWidth + 50; end 
			SolutionLootFrame:SetWidth(lootFrameWidth)

			frame:SetWidth(lootFrameWidth)
			getglobal("SolutionLootFrameEntry"..i.."Hover2"):SetWidth(hoverWidth)
			getglobal("SolutionLootFrameEntry"..i.."ItemLabel"):SetText(link);
			getglobal("SolutionLootFrameEntry"..i.."ItemLabel"):SetFont("Fonts\\FRIZQT__.TTF", 16);
			getglobal("SolutionLootFrameEntry"..i.."Texture"):SetTexture(texture);
			getglobal("SolutionLootFrameEntry"..i.."Ilvl"):SetText("ilvl: "..ilvl);
			getglobal("SolutionLootFrameEntry"..i.."Ilvl"):SetPoint("TOPRIGHT", "$parent", "TOPRIGHT", -2, -5)
			SolutionLootFrame:SetHeight(i * 75)
			SolutionLootFrame:SetWidth(lootFrameWidth)
			frame:Show();
			lootFrames[i] = frame
		end
		for j = db.numButtons+1, #frame.buttons do -- throw away not used buttons
			if frame.buttons[j] then
				frame.buttons[j]:Hide()
				frame.buttons[j]:SetParent(nil)
			end
		end
		-- Anchor the frames correctly
		if i > 1 then
			lootFrames[i]:SetPoint("TOPLEFT", lootFrames[i-1], "BOTTOMLEFT")
		end
	end  
	
	-- Hide unused frames
	for i = MAX_VISIBLE_FRAMES, numFrames+1, -1 do
		if lootFrames[i] then
			lootFrames[i]:Hide()
			-- and clear the note since we need a blank next time
			lootFrames[i].note = nil;
		end
	end		
	if #itemsLooting == 0 then -- they're all hidden, so hide the frame
		SolutionLC:debugS("LootFrame hidden")
		SolutionLC_LootFrame.hide()
		return;
	end
	SolutionLootFrame:Show()
end

---------- ShowTooltip -------------
-- Shows the loot item's tooltip
------------------------------------
function SolutionLC_LootFrame.ShowTooltip(frame)
	GameTooltip:SetOwner(SolutionLootFrame, "ANCHOR_CURSOR")
	GameTooltip:SetHyperlink(frame.item)
	GameTooltip:Show()
end

------------- toolMouseLeave ------------------------
-- Removes the tooltip when mouse leaves the area
-----------------------------------------------------
function SolutionLC_LootFrame.toolMouseLeave()
	GameTooltip:Hide()
end

---------- onClick ------------------
-- Sends user response to MasterLooter
-------------------------------------
function SolutionLC_LootFrame:onClick(response, frame, button)
	SolutionLC:debugS("LootFrame:onClick("..tostring(response)..", frame, button)")
	SolutionLC.handleResponse(response, frame);	
	local position = frame.index or frame:GetID();
	tremove(itemsLooting, position);
	SolutionLC_LootFrame:Update()
end

----------- hide -------------------
-- Hides the loot frame 
------------------------------------
function SolutionLC_LootFrame.hide()
	if SolutionLootFrame:IsShown() then
		wipe(itemsLooting)
		SolutionLootFrame:Hide()
	end
end
