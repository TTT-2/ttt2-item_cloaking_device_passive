if SERVER then
	util.AddNetworkString("cloakingdevice_toggle")
end

local cvDuration = CreateConVar("ttt_cloaking_device_duration", 20, {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "How long should you be invisible?")
local cvCooldown = CreateConVar("ttt_cloaking_device_cooldown", 30, {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "How long should you be the cooldown?")
local cvAllowShoot = CreateConVar("ttt_cloaking_device_allow_shoot", 0, {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Should the player be allowed to shoot when cloaked?")

if SERVER then
	local plymeta = FindMetaTable("Player")

	function plymeta:ToggleCloakingDevice()
		if not self:HasEquipmentItem("item_ttt_cloakingdevicepassive") then return end

		if self.cloaked then
			self:UnCloak()
		else
			self:Cloak()
		end
	end

	-- makes the player invisible if the Cloaking Device is ready
	function plymeta:Cloak()
		if self:GetNWBool("cloakingdeviceready", false) then
			self.cloaked = true
			self:SetNWBool("cloakingdeviceready", false)
			self:SetNWFloat("cloaktime", math.Round(CurTime(), 1))
			self.oldColor = self:GetColor()
			self.oldMat = self:GetMaterial()

			self:SetColor(Color(255, 255, 255, 3))
			self:SetMaterial("sprites/heatwave")
			self:DrawViewModel(false)
			self:DrawWorldModel(false)
			self:EmitSound("AlyxEMP.Charge")

			LANG.Msg(self, "item_cloaking_hud_msg_enabled", nil, MSG_MSTACK_ROLE)
		else
			LANG.Msg(self, "item_cloaking_hud_msg_error", nil, MSG_MSTACK_WARN)
		end
	end

	-- makes the player visible
	function plymeta:UnCloak()
		self.cloaked = false
		self:SetNWFloat("cloaktime", 0)
		self:SetNWFloat("uncloaktime", math.Round(CurTime(), 1))

		self:SetColor(self.oldColor)
		self:SetMaterial(self.oldMat)
		self:DrawWorldModel(true)
		self:DrawViewModel(true)
		self:EmitSound("AlyxEMP.Discharge")

		LANG.Msg(self, "item_cloaking_hud_msg_disabled", nil, MSG_MSTACK_ROLE)
	end

	-- resets the Cloaking Device (called in preparing phase and on player death)
	function plymeta:ResetCloakingDevice()
		if self.oldColor ~= nil then
			self:SetColor(self.oldColor)
		else
			self:SetColor(Color(255, 255, 255, 255))
		end

		if self.oldMat ~= nil then
			self:SetMaterial(self.oldMat)
		else
			self:SetMaterial("models/glass")
		end

		self:DrawViewModel(true)
		self:DrawWorldModel(true)

		self.cloaked = false
		self:SetNWBool("cloakingdeviceready", true)
		self:SetNWFloat("cloaktime", 0)
		self:SetNWFloat("uncloaktime", 0)
	end

	hook.Add("Think", "cloakingdevice_think", function()
		local plys = player.GetAll()

		for i = 1, #plys do
			local ply = plys[i]

			-- player isn't able to shoot while cloaked
			if ply.cloaked and not cvAllowShoot:GetBool() then
				for k,wep in pairs(ply:GetWeapons()) do
					wep:SetNextPrimaryFire(CurTime() + 0.6)
					wep:SetNextSecondaryFire(CurTime() + 0.6)
				end
			end

			-- duration and cooldown
			if ply:GetNWFloat("cloaktime", 0) ~= 0 and math.Round(CurTime(), 1) == ply:GetNWFloat("cloaktime", nil) + cvDuration:GetInt() and ply.cloaked then
				ply:UnCloak()
			elseif ply:GetNWFloat("uncloaktime", 0) ~= 0 and math.Round(CurTime(), 1) == ply:GetNWFloat("uncloaktime", nil) + cvCooldown:GetInt() then
				ply:SetNWFloat("uncloaktime", 0)
				ply:SetNWBool("cloakingdeviceready", true)

				LANG.Msg(ply, "item_cloaking_hud_msg_ready", nil, MSG_MSTACK_PLAIN)
			end
		end
	end)

	hook.Add("TTTPrepareRound", "cloakingdevice_resetAll", function()
		local plys = player.GetAll()

		for i = 1, #plys do
			local ply = plys[i]

			ply:ResetCloakingDevice()
		end
	end)

	hook.Add("PlayerDeath", "cloakingdevice_reset", function(ply)
		ply:ResetCloakingDevice()
	end)

	hook.Add("PlayerSwitchWeapon", "ToggleCloakingDevice_sw", function(ply)
		timer.Simple(0, function()
			if not ply.cloaked then return end

			ply:DrawViewModel(false)
			ply:DrawWorldModel(false)
		end)
	end)

	net.Receive("cloakingdevice_toggle", function(len, ply)
		ply:ToggleCloakingDevice()
	end)
end
