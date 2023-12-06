if TTT2 then return end -- only for normal TTT

if SERVER then
	util.AddNetworkString("cloakingdevice_acivate")
	util.AddNetworkString("cloakingdevice_message")
	util.AddNetworkString("cloakingdevice_acivate")
end

local duration = CreateConVar("ttt_cloakingdevice_duration", 20, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "How long should you be invisible?"):GetInt()
local cooldown = CreateConVar("ttt_cloakingdevice_cooldown", 30, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "How long should you be the cooldown?"):GetInt()
local allowShoot = CreateConVar("ttt_cloakingdevice_allowShoot", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Should the player be allowed to shoot when cloaked? (1=yes, 0=no)"):GetBool()


local plymeta = FindMetaTable("Player")
if CLIENT then
    local preventmultiplemsg
	net.Receive("cloakingdevice_message", function()
        if not preventmultiplemsg then
            preventmultiplemsg = true
            local msg = net.ReadString()
            timer.Simple(0.2, function()
                chat.AddText("Cloaking Device: ", Color(255, 255, 255), msg)
                chat.PlaySound()
                preventmultiplemsg = false
            end)
        end
	end)

	concommand.Add("cloakingdevice", function( ply )
		net.Start("cloakingdevice_acivate")
		net.SendToServer()
	end)
end

if SERVER then
	function plymeta:CloakingDevice()						                    -- function called when player activates the Cloaking Device
		if TTT2 then
			if self:HasEquipmentItem("item_ttt_cloakingdevicepassive") then
				if self.cloaked then
					self:UnCloak()
				else
					self:Cloak()
				end
			end
		else
			if self:HasEquipmentItem(EQUIP_CLOAKINGDEVICE)then
				if self.cloaked then
					self:UnCloak()
				else
					self:Cloak()
				end
			end

		end
	end

	function plymeta:Cloak()								                	-- makes the player invisible if the Cloaking Device is ready
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

	function plymeta:UnCloak()									                -- makes the player visible
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

	function plymeta:ResetCloakingdevice()  					                -- resets the Cloaking Device (called in preparing phase and on player death)
		if self.oldColor ~= nil then self:SetColor(self.oldColor)
		else self:SetColor(Color(255, 255, 255, 255)) end
		if self.oldMat ~= nil then self:SetMaterial(self.oldMat)
		else self:SetMaterial("models/glass") end
		self:DrawViewModel( true )
		self:DrawWorldModel( true )
		
		self.cloaked = false
        self:SetNWBool("cloakingdeviceready", true)
        self:SetNWFloat("cloaktime", 0)
        self:SetNWFloat("uncloaktime", 0)
	end
    
    hook.Add( "Think", "cloakingdevice_Think", function()
		for i, ply in pairs(player.GetAll()) do
            if ply.cloaked and not allowShoot then		                        -- player isn't able to shoot while cloaked
                for k,wep in pairs(ply:GetWeapons()) do
                    wep:SetNextPrimaryFire(CurTime() + 0.6)
                    wep:SetNextSecondaryFire(CurTime() + 0.6)
                end
            end
                                                                                -- duration and cooldown
            if ply:GetNWFloat("cloaktime", 0) ~= 0 and math.Round(CurTime(), 1) == ply:GetNWFloat("cloaktime", nil) + duration and ply.cloaked then ply:UnCloak()
            elseif ply:GetNWFloat("uncloaktime", 0) ~= 0 and math.Round(CurTime(), 1) == ply:GetNWFloat("uncloaktime", nil) + cooldown then
                ply:SetNWFloat("uncloaktime", 0)
                ply:SetNWBool("cloakingdeviceready", true)
                
                net.Start("cloakingdevice_message")
				net.WriteString("Your Cloaking Device is ready again!")
				net.Send(ply)
            end
            
            if not TTT2 and ply.cloaked then							        -- if you are using TTT2 the time will be displayed on the hud so you dont need the messanges
                if math.Round(CurTime(), 1) == ply:GetNWFloat("cloaktime", nil) + duration - 10 then net.Start("cloakingdevice_message") net.WriteString("You will visible again in 10 secounds!") net.Send(ply)
                elseif math.Round(CurTime(), 1) == ply:GetNWFloat("cloaktime", nil) + duration - 3 then net.Start("cloakingdevice_message") net.WriteString("You will visible again in 3 secounds!") net.Send(ply)
                elseif math.Round(CurTime(), 1) == ply:GetNWFloat("cloaktime", nil) + duration - 2 then net.Start("cloakingdevice_message") net.WriteString("You will visible again in 2 secounds!") net.Send(ply)
                elseif math.Round(CurTime(), 1) == ply:GetNWFloat("cloaktime", nil) + duration - 1 then net.Start("cloakingdevice_message") net.WriteString("You will visible again in 1 secounds!") net.Send(ply)    end
            end
		end
	end)
	
	hook.Add("TTTPrepareRound", "cloakingdevice_ResetAll", function()		
		for _, ply in pairs(player.GetAll()) do
			ply:ResetCloakingdevice()
		end
	end)
	
	hook.Add("PlayerDeath", "cloakingdevice_Reset", function( ply )
		ply:ResetCloakingdevice()
	end)

	hook.Add("TTTBeginRound", "cloakingdevice_convars", function()              -- updates convars every round
		duration = GetConVar("ttt_cloakingdevice_duration"):GetInt()
		cooldown = GetConVar("ttt_cloakingdevice_cooldown"):GetInt()
		allowShoot = GetConVar("ttt_cloakingdevice_allowShoot"):GetBool()
	end)
	
	hook.Add("PlayerSwitchWeapon", "cloakingdevice_sw", function( ply )         -- hides weapon
		timer.Simple(0, function()
			if ply.cloaked then
				ply:DrawViewModel( false )
				ply:DrawWorldModel( false )
			end
		end)
	end)
	
	net.Receive("cloakingdevice_acivate", function( len, ply )
		ply:CloakingDevice()
	end)
end