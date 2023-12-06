-- ONLY FOR TTT2

if SERVER then
	resource.AddFile("materials/vgui/ttt/icon_cloakingdevicepassive.vmt")
	resource.AddFile("materials/vgui/ttt/perks/hub_cloakingdevicepassive_ttt2.png")

	AddCSLuaFile()
end

ITEM.hud = Material("vgui/ttt/perks/hub_cloakingdevicepassive_ttt2.png")
ITEM.EquipMenuData = {
	type = "item_active",
	name = "Cloaking Device",
	desc = "Become nearly invisible with this.\nDoesn't hide your name, shadow or bloodstains.\n\nMade by Blaubeeree",
}

ITEM.material = "vgui/ttt/icon_cloakingdevicepassive.vmt"
ITEM.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}

function ITEM:DrawInfo()
	local duration_end = GetConVar("ttt_cloakingdevice_duration"):GetInt() + LocalPlayer():GetNWFloat("cloaktime", nil)
	local cooldown_end = GetConVar("ttt_cloakingdevice_cooldown"):GetInt() + LocalPlayer():GetNWFloat("uncloaktime", nil)

	if LocalPlayer():GetNWBool("cloakingdeviceready", false) then
		timeleft = "ready"
	elseif duration_end > math.Round(CurTime(), 1) then
		timeleft = math.Round(duration_end - CurTime())
	elseif cooldown_end > math.Round(CurTime(), 1) then
		timeleft = math.Round(-1 * cooldown_end + CurTime())
	else
		timeleft = "ERROR"
	end

	return timeleft
end

if CLIENT then
	bind.Register("cloakingdevice", function()
		LocalPlayer():ConCommand("cloakingdevice")
	end, function() end, "Other Bindings", "Cloaking Device")

	timer.Simple( 0, function()
		AddTTT2AddonDev("76561198329270449")
	end)
end