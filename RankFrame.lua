-- RCRankFrame.lua - Manages the rankframe

local rank;

function SolutionLC_RankFrame.show()
	RCRankFrame:Show()
end

function SolutionLC_RankFrame.DropDown_OnLoad()
	for ci = 1, GuildControlGetNumRanks() do 
		info = {};
		info.text = " "..ci.." - "..GuildControlGetRankName(ci);
		info.value = ci;
		info.func = function() SolutionLC_RankFrame.setMinRank(ci) end;
		UIDropDownMenu_AddButton(info);
	end
end

function SolutionLC_RankFrame.setMinRank(rankNum)
	rank = rankNum;
	UIDropDownMenu_SetText(RankDropDown,  " "..rankNum.." - "..GuildControlGetRankName(rankNum)) 
end

function SolutionLC_RankFrame.acceptOnClick()
	if rank > 0 then
		SolutionLC_Mainframe.setRank(rank)
		RCRankFrame:Hide()
	else
		print("RCLootCouncil: Couldn't find the rank")
	end
end

function SolutionLC_RankFrame.cancelOnClick()
	RCRankFrame:Hide()
end
