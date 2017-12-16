local E, L, V, P, G, _ = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local TTOS = E:NewModule('TooltipOffset', 'AceEvent-3.0')
local TT = E:GetModule('Tooltip');
local EP = LibStub("LibElvUIPlugin-1.0") 
local addonName, addonTable = ...

--Defaults
P['tooltip']['mouseOffsetX'] = 0
P['tooltip']['mouseOffsetY'] = 0
P['tooltip']['overrideCombat'] = false

--Functions to hook
function TTOS:GameTooltip_SetDefaultAnchor(tt, parent)
	if E.private["tooltip"].enable ~= true then return end
	if self.db.anchor == 'CURSOR' then
		if parent then
			tt:SetOwner(parent, "ANCHOR_CURSOR")
			TTOS:AnchorFrameToMouse(tt);
		end
		if InCombatLockdown() and E.db.tooltip.combathide and not (E.db.tooltip.overrideCombat and IsShiftKeyDown()) then
			tt:Hide()
		end
	elseif self.db.anchor == 'SMART' then
		if parent then
			tt:SetOwner(parent, "ANCHOR_NONE")
		end

		if InCombatLockdown() and E.db.tooltip.combathide and not (E.db.tooltip.overrideCombat and IsShiftKeyDown()) then
			tt:Hide()
		else
			tt:ClearAllPoints()
			if BagsFrame and BagsFrame:IsShown() then
				tt:Point('BOTTOMRIGHT', BagsFrame, 'TOPRIGHT', 0, 18)
			elseif RightChatPanel:GetAlpha() == 1 then
				tt:Point('BOTTOMRIGHT', RightChatPanel, 'TOPRIGHT', 0, 18)
			else
				tt:Point('BOTTOMRIGHT', RightChatPanel, 'BOTTOMRIGHT', 0, 18)
			end
		end
	else
		if parent then
			tt:SetOwner(parent, "ANCHOR_NONE")
		end
		if InCombatLockdown() and E.db.tooltip.combathide and not (E.db.tooltip.overrideCombat and IsShiftKeyDown()) then
			tt:Hide()
		else
			tt:ClearAllPoints()

			local point = E:GetScreenQuadrant(TooltipMover)
			if point == "TOPLEFT" then
				tt:Point("TOPLEFT", TooltipMover, "BOTTOMLEFT", 1, -4)
			elseif point == "TOPRIGHT" then
				tt:Point("TOPRIGHT", TooltipMover, "BOTTOMRIGHT", -1, -4)
			elseif point == "BOTTOMLEFT" or point == "LEFT" then
				tt:Point("BOTTOMLEFT", TooltipMover, "TOPLEFT", 1, 18)
			else
				tt:Point("BOTTOMRIGHT", TooltipMover, "TOPRIGHT", -1, 18)
			end
		end
	end
end

local r1,g1,b1,a1 = unpack(E["media"].backdropfadecolor)
local r2,g2,b2,a2 = unpack(E["media"].bordercolor)
function TTOS.GameTooltip_OnUpdate(tt)
	if (tt.needRefresh and tt:GetAnchorType() == 'ANCHOR_CURSOR' and E.db.tooltip.anchor ~= 'CURSOR') then
		tt:SetBackdropColor(r1,g1,b1,a1)
		tt:SetBackdropBorderColor(r2,g2,b2,a2)
		tt.needRefresh = nil
	elseif tt.forceRefresh then
		tt.forceRefresh = nil
	else
		TTOS:AnchorFrameToMouse(tt)
	end
end

function TTOS:AnchorFrameToMouse(frame)
	if frame:GetAnchorType() ~= "ANCHOR_CURSOR" then return end
	local x, y = GetCursorPosition();
	local effScale = frame:GetEffectiveScale();
	frame:ClearAllPoints();
	frame:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",(x / effScale + E.db.tooltip.mouseOffsetX),(y / effScale + E.db.tooltip.mouseOffsetY));

end

function TTOS:MODIFIER_STATE_CHANGED(event, key)
	if InCombatLockdown() and E.db.tooltip.combathide and not (E.db.tooltip.overrideCombat and IsShiftKeyDown()) then
		GameTooltip:Hide()
	end
end

function TTOS:PLAYER_LOGIN(event)
	print(format("%sElvUI Tooltip Offset|r Version %s%s|r loaded.", E["media"].hexvaluecolor, E["media"].hexvaluecolor, GetAddOnMetadata("ElvUI_TooltipOffset", "Version")))
	hooksecurefunc(TT, "GameTooltip_SetDefaultAnchor", TTOS.GameTooltip_SetDefaultAnchor)
	GameTooltip:HookScript("OnUpdate", TTOS.GameTooltip_OnUpdate)
end

function TTOS:InjectOptions()
	E.Options.args.tooltip.args.general.args.offset = {
		order = 30,
		type = "group",
		name = "Offset",
		args = {
			mouseOffsetX = {
				order = 31,
				type = 'range',
				name = 'Tooltip X-offset',
				desc = 'Offset the tooltip on the X-axis.',
				min = -300, max = 200, step = 1,
				set = function(info, value)
					E.db.tooltip[ info[#info] ] = value
				end,
			},
			mouseOffsetY = {
				order = 32,
				type = 'range',
				name = 'Tooltip Y-offset',
				desc = 'Offset the tooltip on the Y-axis.',
				min = -200, max = 200, step = 1,
				set = function(info, value)
					E.db.tooltip[ info[#info] ] = value
				end,
			},
			overrideCombat = {
				order = 33,
				type = 'toggle',
				name = 'Override Combat Hide',
				desc = 'When enabled, Combat Hide will get overridden when Shift is pressed. Note: You have to mouseover the unit again for the tooltip to show.',
				set = function(info, value)
					E.db.tooltip[ info[#info] ] = value
				end,
			},
		},
	}
end

function TTOS:Initialize()
	EP:RegisterPlugin(addonName, TTOS.InjectOptions)

	TTOS:RegisterEvent("PLAYER_LOGIN")
	TTOS:RegisterEvent("MODIFIER_STATE_CHANGED")
end

E:RegisterModule(TTOS:GetName())