if SERVER then
	util.AddNetworkString("cloakingdevice_acivate")
	util.AddNetworkString("cloakingdevice_message")
	util.AddNetworkString("cloakingdevice_acivate")
end

local cvDuration = CreateConVar("ttt_cloakingdevice_duration", 20, {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "How long should you be invisible?")
local cvCooldown = CreateConVar("ttt_cloakingdevice_cooldown", 30, {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "How long should you be the cooldown?")
local cvAllowShoot = CreateConVar("ttt_cloakingdevice_allowShoot", 0, {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Should the player be allowed to shoot when cloaked?")

if CLIENT then
	local preventmultiplemsg

	net.Receive("cloakingdevice_message", function()
		if preventmultiplemsg then return end

		preventmultiplemsg = true

		local msg = net.ReadString()

		timer.Simple(0.2, function()
			chat.AddText("Cloaking Device: ", Color(255, 255, 255), msg)
			chat.PlaySound()
			preventmultiplemsg = false
		end)
	end)

	concommand.Add("cloakingdevice", function( ply )
		net.Start("cloakingdevice_acivate")
		net.SendToServer()
	end)
end

if SERVER then
	local plymeta = FindMetaTable("Player")

	function plymeta:CloakingDevice()
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
			self:DrawViewModel( false )
			self:DrawWorldModel( false )
			self:EmitSound("AlyxEMP.Charge")

			net.Start("cloakingdevice_message")
			net.WriteString("You are now invisible!")
			net.Send(self)
		else
			net.Start("cloakingdevice_message")
			net.WriteString("Your Cloaking Device isn't ready yet!")
			net.Send(self)
		end
	end

	-- makes the player visible
	function plymeta:UnCloak()
		self.cloaked = false
		self:SetNWFloat("cloaktime", 0)
		self:SetNWFloat("uncloaktime", math.Round(CurTime(), 1))

		self:SetColor(self.oldColor)
		self:SetMaterial(self.oldMat)
		self:DrawWorldModel( true )
		self:DrawViewModel( true )
		self:EmitSound("AlyxEMP.Discharge")

		net.Start("cloakingdevice_message")
		net.WriteString("You are visible again!")
		net.Send(self)
	end

	-- resets the Cloaking Device (called in preparing phase and on player death)
	function plymeta:ResetCloakingdevice()
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

		self:DrawViewModel( true )
		self:DrawWorldModel( true )

		self.cloaked = false
		self:SetNWBool("cloakingdeviceready", true)
		self:SetNWFloat("cloaktime", 0)
		self:SetNWFloat("uncloaktime", 0)
	end

	hook.Add("Think", "cloakingdevice_Think", function()
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

				net.Start("cloakingdevice_message")
				net.WriteString("Your Cloaking Device is ready again!")
				net.Send(ply)
			end
		end
	end)

	hook.Add("TTTPrepareRound", "cloakingdevice_ResetAll", function()
		local plys = player.GetAll()

		for i = 1, #plys do
			local ply = plys[i]

			ply:ResetCloakingdevice()
		end
	end)

	hook.Add("PlayerDeath", "cloakingdevice_Reset", function(ply)
		ply:ResetCloakingdevice()
	end)

	hook.Add("PlayerSwitchWeapon", "cloakingdevice_sw", function(ply)
		timer.Simple(0, function()
			if not ply.cloaked then return end

			ply:DrawViewModel(false)
			ply:DrawWorldModel(false)
		end)
	end)

	net.Receive("cloakingdevice_acivate", function(len, ply)
		ply:CloakingDevice()
	end)
end
