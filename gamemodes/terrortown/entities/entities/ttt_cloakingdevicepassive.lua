-- Only needed without TTT2
if TTT2 then return end

if SERVER then
	resource.AddFile("materials/vgui/ttt/icon_cloakingdevicepassive.vmt")
	resource.AddFile("materials/vgui/ttt/perks/hub_cloakingdevicepassive.png")
	
	AddCSLuaFile()
end

-- feel for to use this function for your own perk, but please credit Zaratusa
-- your perk needs a "hud = true" in the table, to work properly
if CLIENT then
	local defaultY = ScrH() / 2 + 20
	local function getYCoordinate(currentPerkID)
		local amount, i, perk = 0, 1
		while (i < currentPerkID) do

			local role = LocalPlayer():GetRole()

			if role == ROLE_INNOCENT then --he gets it in a special way
				if GetEquipmentItem(ROLE_TRAITOR, i) then
					role = ROLE_TRAITOR -- Temp fix what if a perk is just for Detective
				elseif GetEquipmentItem(ROLE_DETECTIVE, i) then
					role = ROLE_DETECTIVE
				end
			end

			perk = GetEquipmentItem(role, i)

			if (istable(perk) and perk.hud and LocalPlayer():HasEquipmentItem(perk.id)) then
				amount = amount + 1
			end
			i = i * 2
		end
		return defaultY - 80 * amount
	end

	local yCoordinate = defaultY
	-- best performance, but the has about 0.5 seconds delay to the HasEquipmentItem() function
	hook.Add("TTTBoughtItem", "TTTCloakingDevicePassive", function()
		if (LocalPlayer():HasEquipmentItem(EQUIP_CLOAKINGDEVICE)) then
			yCoordinate = getYCoordinate(EQUIP_CLOAKINGDEVICE)
		end
	end)
	local material = Material("vgui/ttt/perks/hub_cloakingdevicepassive.png")
	hook.Add("HUDPaint", "TTTCloakingDevicePassive", function()
		if LocalPlayer():HasEquipmentItem(EQUIP_CLOAKINGDEVICE) then
			surface.SetMaterial(material)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawTexturedRect(20, yCoordinate, 64, 64)
		end
    end)
end
-- end of Zaratusa's code

EQUIP_CLOAKINGDEVICE = (GenerateNewEquipmentID and GenerateNewEquipmentID() ) or 32

local cloakingdevice = {
	avoidTTT2 = true,
	id = EQUIP_CLOAKINGDEVICE,
	loadout = false,
	type = "item_active",
	material = "vgui/ttt/icon_cloakingdevicepassive.vtm",
	name = "Cloaking Device",
	desc = "Become nearly invisible with this.\nDoesn't hide your name, shadow or bloodstains.\nUse 'bind [Key] cloakingdevice' in the console\n  to set a key to activate the Cloaking Device.\n\nMade by Blaubeeree",
	hud = true
}

local detectiveCanUse = CreateConVar("ttt_cloakingdevice_detective", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Detective be able to use the the Cloaking Device."):GetBool()
local traitorCanUse = CreateConVar("ttt_cloakingdevice_traitor", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Traitor be able to use the the Cloaking Device."):GetBool()

if (detectiveCanUse) then
	table.insert(EquipmentItems[ROLE_DETECTIVE], cloakingdevice)
end
if (traitorCanUse) then
	table.insert(EquipmentItems[ROLE_TRAITOR], cloakingdevice)
end