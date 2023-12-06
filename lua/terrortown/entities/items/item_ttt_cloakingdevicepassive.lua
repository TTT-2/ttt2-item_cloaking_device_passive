-- ONLY FOR TTT2

if SERVER then
	resource.AddFile("materials/vgui/ttt/icon_cloakingdevicepassive.vmt")
	resource.AddFile("materials/vgui/ttt/perks/hub_cloakingdevicepassive_ttt2.png")
	resource.AddFile("materials/vgui/ttt/hudhelp/icon_cloakingdevicepassive.vmt")

	AddCSLuaFile()
end

ITEM.hud = Material("vgui/ttt/perks/hub_cloakingdevicepassive_ttt2.png")
ITEM.EquipMenuData = {
	type = "item_active",
	name = "item_cloaking_device",
	desc = "item_cloaking_device_desc",
}

ITEM.material = "vgui/ttt/icon_cloakingdevicepassive.vmt"
ITEM.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}

function ITEM:DrawInfo()
	local duration_end = GetConVar("ttt_cloakingdevice_duration"):GetInt() + LocalPlayer():GetNWFloat("cloaktime", nil)
	local cooldown_end = GetConVar("ttt_cloakingdevice_cooldown"):GetInt() + LocalPlayer():GetNWFloat("uncloaktime", nil)

	if LocalPlayer():GetNWBool("cloakingdeviceready", false) then
		return "item_cloaking_hud_ready"
	elseif duration_end > math.Round(CurTime(), 1) then
		return math.Round(duration_end - CurTime())
	elseif cooldown_end > math.Round(CurTime(), 1) then
		return math.Round(-1 * cooldown_end + CurTime())
	else
		return "item_cloaking_hud_error"
	end
end

if CLIENT then
	local materialKeyBind = Material("vgui/ttt/hudhelp/icon_cloakingdevicepassive")

	function ITEM:AddToSettingsMenu(parent)
		local form = vgui.CreateTTT2Form(parent, "header_equipment_additional")

		form:MakeSlider({
			label = "label_cloaking_device_duration",
			serverConvar = "ttt_cloaking_device_duration",
			min = 0,
			max = 50,
			decimal = 0
		})

		form:MakeSlider({
			label = "label_cloaking_device_cooldown",
			serverConvar = "ttt_cloaking_device_cooldown",
			min = 0,
			max = 50,
			decimal = 0
		})

		form:MakeCheckBox({
			label = "label_cloaking_device_allow_shoot",
			serverConvar = "ttt_cloaking_device_allow_shoot"
		})
	end

	hook.Add("TTT2FinishedLoading", "TTTItemCloakingdevicePassiveInitStatus", function()
		bind.Register("cloakingdevice", function()
			net.Start("cloakingdevice_toggle")
			net.SendToServer()
		end, function() end, "header_bindings_other", "item_cloaking_bindings_name", KEY_N)

		timer.Simple(0, function()
			AddTTT2AddonDev("76561198329270449")
		end)

		keyhelp.RegisterKeyHelper("cloakingdevice", materialKeyBind, KEYHELP_EQUIPMENT, "label_keyhelper_cloakingdevicepassive", function(client)
			if client:IsSpec() or not client:HasEquipmentItem("item_ttt_cloakingdevicepassive") then return end

			return true
		end)
	end)
end
