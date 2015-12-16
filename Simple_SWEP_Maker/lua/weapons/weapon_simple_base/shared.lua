AddCSLuaFile()

if SERVER then
    include("sv_commands.lua")
    include("sh_commands.lua")
    SWEP.Weight = 5
    SWEP.AutoSwitchTo = false
    SWEP.AutoSwitchFrom = false
end

if CLIENT then
    SWEP.DrawAmmo           = true
    SWEP.DrawCrosshair      = true --Edited because crosshairs are good
    SWEP.ViewModelFOV       = 76 --Edited to fit better with most weapons
    SWEP.ViewModelFlip      = false
    SWEP.CSMuzzleFlashes    = true

    -- This is the font that's used to draw the death icons
    surface.CreateFont("CSKillIcons", {
        size = ScreenScale(30),
        weight = 500,
        antialias = true,
        shadow = true,
        font = "csd"
    })
    surface.CreateFont("CSSelectIcons", {
        size = ScreenScale(60),
        weight = 500,
        antialias = true,
        shadow = true,
        font = "csd"
    })
end

SWEP.Base = "weapon_base"

SWEP.Author = "" --Replace this with your name
SWEP.Contact = "" --How people can contact you
SWEP.Purpose = "" --What your SWEP is used for
SWEP.Instructions = "" --How to use your SWEP

SWEP.Spawnable = false
SWEP.AdminOnly = false
SWEP.UseHands = true

SWEP.HoldType = "normal"

SWEP.Primary.Sound = Sound("Weapon_AK47.Single")
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Damage = 40
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0.02
SWEP.Primary.Delay = 0.15

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.MultiMode = false

SWEP.DarkRPBased = true

/*---------------------------------------------------------
---------------------------------------------------------*/
function SWEP:Initialize()
    if CLIENT and IsValid(self:GetOwner()) then
        local vm = self:GetOwner():GetViewModel()
        self:ResetDarkRPBones(vm)
    end

    self:SetHoldType("normal")
    if SERVER then
        self:SetNPCMinBurst(30)
        self:SetNPCMaxBurst(30)
        self:SetNPCFireRate(0.01)
    end

    self.dt.Ironsights = false
    self.dt.TotalUsedMagCount = 0
    self.dt.FireMode = self.Primary.Automatic and "auto" or "semi"
end

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "Ironsights")
    self:NetworkVar("Bool", 1, "Reloading")
    self:NetworkVar("Float", 0, "LastPrimaryAttack")
    self:NetworkVar("Float", 1, "ReloadEndTime")
    self:NetworkVar("Float", 2, "BurstTime")
    self:NetworkVar("Float", 3, "LastNonBurst")
    self:NetworkVar("Int", 0, "BurstBulletNum")
    self:NetworkVar("Int", 1, "TotalUsedMagCount")
    self:NetworkVar("String", 0, "FireMode")
    self:NetworkVar("Entity", 0, "LastOwner")
    self:NetworkVarNotify("Ironsights", fc{self.IronsightsChanged, fp{fn.Id, self}, fp{select, 4}})
end

/*---------------------------------------------------------
Deploy
---------------------------------------------------------*/
function SWEP:Deploy()
    self:SetHoldType("normal")

    self:IronsightsChanged(self:GetIronsights())

    return true
end

function SWEP:OwnerChanged()
    if IsValid(self:GetOwner()) then self:SetLastOwner(self:GetOwner()) end
end

function SWEP:Holster()
    self.dt.Ironsights = false
    if CLIENT then self.hasShot = false end

    if not IsValid(self:GetOwner()) then return true end
    if CLIENT then
        local vm = self:GetOwner():GetViewModel()
        self:ResetDarkRPBones(vm)
    end

    return true
end

function SWEP:OnRemove()
    self.dt.Ironsights = false

    if CLIENT and IsValid(self:GetOwner()) then
        local vm = self:GetOwner():GetViewModel()
        self:ResetDarkRPBones(vm)
    end
end

/*---------------------------------------------------------
Reload does nothing
---------------------------------------------------------*/
function SWEP:Reload()
    if not self:DefaultReload(ACT_VM_RELOAD) then return end
    self:SetReloading(true)
    self:SetIronsights(false)
    self:SetHoldType(self.HoldType)
    self:GetOwner():SetAnimation(PLAYER_RELOAD)
    self:SetReloadEndTime(CurTime() + 2)
    self:SetTotalUsedMagCount(self:GetTotalUsedMagCount() + 1)
end

/*---------------------------------------------------------
PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
    self.Primary.Automatic = (self:GetFireMode() == "auto")

    if self:GetBurstBulletNum() == 0 and (self:GetLastNonBurst() or 0) > CurTime() - 0.6 then return end

    if self.MultiMode and self:GetOwner():KeyDown(IN_USE) then
        if self:GetFireMode() == "semi" then
            self:SetFireMode("burst")
            self.Primary.Automatic = false
            self:GetOwner():PrintMessage(HUD_PRINTCENTER, DarkRP.getPhrase("switched_burst"))
        elseif self:GetFireMode() == "burst" then
            self:SetFireMode("auto")
            self.Primary.Automatic = true
            self:GetOwner():PrintMessage(HUD_PRINTCENTER, DarkRP.getPhrase("switched_fully_auto"))
        elseif self:GetFireMode() == "auto" then
            self:SetFireMode("semi")
            self.Primary.Automatic = false
            self:GetOwner():PrintMessage(HUD_PRINTCENTER, DarkRP.getPhrase("switched_semi_auto"))
        end
        self:SetNextPrimaryFire(CurTime() + 0.5)
        self:SetNextSecondaryFire(CurTime() + 0.5)
        return
    end

    if self:GetHoldType() == "normal" and not GAMEMODE.Config.ironshoot then
        self:SetHoldType(self.HoldType)
    end

    if self:GetFireMode() ~= "burst" then
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    end

    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

    if self:Clip1() <= 0 then
        self:EmitSound("weapons/clipempty_rifle.wav")
        self:SetNextPrimaryFire(CurTime() + 2)
        return
    end

    if not self:CanPrimaryAttack() then self:SetIronsights(false) return end
    if not self:GetIronsights() and GAMEMODE.Config.ironshoot then return end
    -- Play shoot sound
    self:EmitSound(self.Primary.Sound)

    -- Shoot the bullet
    self:CSShootBullet(self.Primary.Damage, self.Primary.Recoil + 3, self.Primary.NumShots, self.Primary.Cone + .05)

    if self:GetFireMode() == "burst" then
        self:SetBurstBulletNum(self:GetBurstBulletNum() + 1)
        if self:GetBurstBulletNum() == 1 then
            self:SetLastNonBurst(CurTime())
        end
        if self:GetBurstBulletNum() == 3 then
            self:SetBurstTime(0)
            self:SetBurstBulletNum(0)
        else
            self:SetBurstTime(CurTime() + 0.1)
        end
    end

    -- Remove 1 bullet from our clip
    self:TakePrimaryAmmo(1)

    self:SetLastPrimaryAttack(CurTime())

    if self:GetOwner():IsNPC() then return end

    -- Punch the player's view
    self:GetOwner():ViewPunch(Angle(util.SharedRandom("DarkRP_CSBase" .. self:EntIndex() .. "Mag" .. self:GetTotalUsedMagCount() .. "p" .. self:Clip1(), -1.2, -1.1) * self.Primary.Recoil, util.SharedRandom("DarkRP_CSBase" .. self:EntIndex() .. "Mag" .. self:GetTotalUsedMagCount() .. "y" .. self:Clip1(), -1.1, 1.1) * self.Primary.Recoil, 0))
end

/*---------------------------------------------------------
Name: SWEP:PrimaryAttack()
Desc: +attack1 has been pressed
---------------------------------------------------------*/
function SWEP:CSShootBullet(dmg, recoil, numbul, cone)
    if not IsValid(self:GetOwner()) then return end
    numbul = numbul or 1
    cone = cone or 0.01

    local bullet = {}
    bullet.Num = numbul or 1
    bullet.Src = self:GetOwner():GetShootPos()  -- Source
    bullet.Dir = (self:GetOwner():GetAimVector():Angle() + self:GetOwner():GetViewPunchAngles()):Forward() -- Dir of bullet
    bullet.Spread = Vector(cone, cone, 0)       -- Aim Cone
    bullet.Tracer = 4                           -- Show a tracer on every x bullets
    bullet.Force = 5                            -- Amount of force to give to phys objects
    bullet.Damage = dmg

    self:GetOwner():FireBullets(bullet)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)      -- View model animation
    self:GetOwner():MuzzleFlash()        -- Crappy muzzle light
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)       -- 3rd Person Animation

    if self:GetOwner():IsNPC() then return end

    -- Part of workaround, different viewmodel position if shots have been fired
    if CLIENT then self.hasShot = true end
end

/*---------------------------------------------------------
Checks the objects before any action is taken
This is to make sure that the entities haven't been removed
---------------------------------------------------------*/
function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
    if self.IconLetter and string.find(self.IconLetter, "^[0-9a-wA-Z]$") then
        draw.DrawNonParsedSimpleText(self.IconLetter, "CSSelectIcons", x + wide / 2, y + tall * 0.2, Color(255, 210, 0, 255), TEXT_ALIGN_CENTER)

        -- try to fool them into thinking they're playing a Tony Hawks game
        draw.DrawNonParsedSimpleText(self.IconLetter, "CSSelectIcons", x + wide / 2 + math.Rand(-4, 4), y + tall * 0.2 + math.Rand(-14, 14), Color(255, 210, 0, math.Rand(10, 120)), TEXT_ALIGN_CENTER)
        draw.DrawNonParsedSimpleText(self.IconLetter, "CSSelectIcons", x + wide / 2 + math.Rand(-4, 4), y + tall * 0.2 + math.Rand(-9, 9), Color(255, 210, 0, math.Rand(10, 120)), TEXT_ALIGN_CENTER)
    else
        -- Set us up the texture
        surface.SetDrawColor(255, 255, 255, alpha)
        surface.SetTexture(self.WepSelectIcon)

        -- Lets get a sin wave to make it bounce
        local fsin = 0

        if self.BounceWeaponIcon then
            fsin = math.sin(CurTime() * 10) * 5
        end

        -- Borders
        y = y + 10
        x = x + 10
        wide = wide - 20

        -- Draw that motherfucker
        surface.DrawTexturedRect(x + (fsin), y - (fsin), wide - fsin * 2, (wide / 2) + (fsin))

        -- Draw weapon info box
        self:PrintWeaponInfo(x + wide + 20, y + tall * 0.95, alpha)
    end
end

local IRONSIGHT_TIME = 0.25

function SWEP:CalcView() end

/*---------------------------------------------------------
Name: GetViewModelPosition
Desc: Allows you to re-position the view model
---------------------------------------------------------*/
function SWEP:GetViewModelPosition(pos, ang)
    if not self.IronSightsPos then return pos, ang end

    local bIron = self:GetIronsights()

    if bIron ~= self.bLastIron then
        self.bLastIron = bIron
        self.fIronTime = CurTime()

        if bIron then
            self.SwayScale  = 0.3
            self.BobScale   = 0.1
        else
            self.SwayScale  = 1.0
            self.BobScale   = 1.0
        end
    end

    local fIronTime = self.fIronTime or 0

    pos = pos + ang:Forward() * -5
    if GAMEMODE.Config.ironshoot then
        ang:RotateAroundAxis(ang:Right(), -15)
    end

    if not bIron and fIronTime < CurTime() - IRONSIGHT_TIME then
        return pos, ang
    end

    local Mul = 1.0

    if fIronTime > CurTime() - IRONSIGHT_TIME then
        Mul = math.Clamp((CurTime() - fIronTime) / IRONSIGHT_TIME, 0, 1)

        if not bIron then Mul = 1 - Mul end
    end

    local Offset    = self.IronSightsPos

    if self.IronSightsAng then
        ang = ang * 1
        ang:RotateAroundAxis(ang:Right(),   self.IronSightsAng.x * Mul)
        ang:RotateAroundAxis(ang:Up(),      self.IronSightsAng.y * Mul)
        ang:RotateAroundAxis(ang:Forward(), self.IronSightsAng.z * Mul)
    end

    if GAMEMODE.Config.ironshoot then
        ang:RotateAroundAxis(ang:Right(), Mul * 15)
    else
        ang:RotateAroundAxis(ang:Right(), Mul)
    end

    local Right     = ang:Right()
    local Up        = ang:Up()
    local Forward   = ang:Forward()

    pos = pos + Offset.x * Right * Mul
    pos = pos + Offset.y * Forward * Mul
    pos = pos + Offset.z * Up * Mul

    if not self.hasShot then
        if self.IronSightsAngAfterShootingAdjustment then
            ang:RotateAroundAxis(ang:Right(),   self.IronSightsAngAfterShootingAdjustment.x * Mul)
            ang:RotateAroundAxis(ang:Up(),      self.IronSightsAngAfterShootingAdjustment.y * Mul)
            ang:RotateAroundAxis(ang:Forward(), self.IronSightsAngAfterShootingAdjustment.z * Mul)
        end

        if self.IronSightsPosAfterShootingAdjustment then
            Offset = self.IronSightsPosAfterShootingAdjustment
            Right = ang:Right()
            Up = ang:Up()
            Forward = ang:Forward()

            pos = pos + Offset.x * Right * Mul
            pos = pos + Offset.y * Forward * Mul
            pos = pos + Offset.z * Up * Mul
        end
    end

    return pos, ang
end


/*---------------------------------------------------------
IronsightsChanged
---------------------------------------------------------*/

function SWEP:IronsightsChanged(b)
    self:SetHoldType(b and self.HoldType or "normal")
end

/*---------------------------------------------------------
SecondaryAttack
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
    if not self.IronSightsPos then return end

    if self:GetReloading() then return end

    self:SetIronsights(not self:GetIronsights())

    self:SetNextSecondaryFire(CurTime() + 0.3)
end

/*---------------------------------------------------------
onRestore
    Loaded a saved game
---------------------------------------------------------*/
function SWEP:OnRestore()
    self:SetNextSecondaryFire(0)
    self.dt.Ironsights = false
end

function SWEP:OnDrop()
    self.PrimaryClipLeft = self:Clip1()
    self.SecondaryClipLeft = self:Clip2()

    if not IsValid(self:GetLastOwner()) then return end
    self.PrimaryAmmoLeft = self:GetLastOwner():GetAmmoCount(self:GetPrimaryAmmoType())
    self.SecondaryAmmoLeft = self:GetLastOwner():GetAmmoCount(self:GetSecondaryAmmoType())
    self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
end

function SWEP:Equip(NewOwner)
    if self.PrimaryClipLeft and self.SecondaryClipLeft and self.PrimaryAmmoLeft and self.SecondaryAmmoLeft then
        NewOwner:SetAmmo(self.PrimaryAmmoLeft, self:GetPrimaryAmmoType())
        NewOwner:SetAmmo(self.SecondaryAmmoLeft, self:GetSecondaryAmmoType())

        self:SetClip1(self.PrimaryClipLeft)
        self:SetClip2(self.SecondaryClipLeft)
    end
end

function SWEP:Think()
    if self.Primary.ClipSize ~= -1 and not self:GetReloading() and not self:GetIronsights() and self:GetLastPrimaryAttack() + 1 < CurTime() and self:GetHoldType() == self.HoldType then
        self:SetHoldType("normal")
    end
    if self:GetReloadEndTime() ~= 0 and CurTime() >= self:GetReloadEndTime() then
        self:SetReloadEndTime(0)
        self:SetReloading(false)
        self:SetHoldType("normal")
        if CLIENT then self.hasShot = false end
    end
    if self:GetBurstTime() ~= 0 and CurTime() >= self:GetBurstTime() then
        self:PrimaryAttack()
    end
end

if CLIENT then
    function SWEP:ViewModelDrawn(vm)
        if self.DarkRPViewModelBoneManipulations and not self:GetReloading() then
            self:UpdateDarkRPBones(vm, self.DarkRPViewModelBoneManipulations)
        else
            self:ResetDarkRPBones(vm)
        end
    end

    function SWEP:UpdateDarkRPBones(vm, manipulations)
        if not IsValid(vm) or not vm:GetBoneCount() then return end

        -- Fill in missing bone names. Things fuck up when we workaround the scale bug and bones are missing.
        local bones = {}
        for i = 0, vm:GetBoneCount() - 1 do
            local bonename = vm:GetBoneName(i)
            if manipulations[bonename] then
                bones[bonename] = manipulations[bonename]
            else
                bones[bonename] = {
                    scale = Vector(1,1,1),
                    pos = Vector(0,0,0),
                    angle = Angle(0,0,0)
                }
            end
        end

        for k, v in pairs(bones) do
            local bone = vm:LookupBone(k)
            if not bone then continue end

            -- Bone scaling seems to be buggy. Workaround.
            local scale = Vector(v.scale.x, v.scale.y, v.scale.z)
            local ms = Vector(1,1,1)
            local cur = vm:GetBoneParent(bone)
            while cur >= 0 do
                local pscale = bones[vm:GetBoneName(cur)].scale
                ms = ms * pscale
                cur = vm:GetBoneParent(cur)
            end
            scale = scale * ms

            if vm:GetManipulateBoneScale(bone) ~= scale then
                vm:ManipulateBoneScale(bone, scale)
            end
            if vm:GetManipulateBonePosition(bone) ~= v.pos then
                vm:ManipulateBonePosition(bone, v.pos)
            end
            if vm:GetManipulateBoneAngles(bone) ~= v.angle then
                vm:ManipulateBoneAngles(bone, v.angle)
            end
        end
    end

    function SWEP:ResetDarkRPBones(vm)
        if not IsValid(vm) or not vm:GetBoneCount() then return end
        for i = 0, vm:GetBoneCount() - 1 do
            vm:ManipulateBoneScale(i, Vector(1, 1, 1))
            vm:ManipulateBoneAngles(i, Angle(0, 0, 0))
            vm:ManipulateBonePosition(i, Vector(0, 0, 0))
        end
    end
end

hook.Add("SetupMove", "DarkRP_WeaponSpeed", function(ply, mv) --Is broken if not used in DarkRP
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not wep.DarkRPBased or not wep.GetIronsights or not wep:GetIronsights() then return end

    mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() / 3)
end)

/********************************************************
	SWEP Construction Kit base code
		Created by Clavus
	Available for public use, thread at:
	   facepunch.com/threads/1032378
	   
	   
	DESCRIPTION:
		This script is meant for experienced scripters 
		that KNOW WHAT THEY ARE DOING. Don't come to me 
		with basic Lua questions.
		
		Just copy into your SWEP or SWEP base of choice
		and merge with your own code.
		
		The SWEP.VElements, SWEP.WElements and
		SWEP.ViewModelBoneMods tables are all optional
		and only have to be visible to the client.
********************************************************/

function SWEP:Initialize()

	// other initialize code goes here

	if CLIENT then
	
		// Create a new table for every weapon instance
		self.VElements = table.FullCopy( self.VElements )
		self.WElements = table.FullCopy( self.WElements )
		self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

		self:CreateModels(self.VElements) // create viewmodels
		self:CreateModels(self.WElements) // create worldmodels
		
		// init view model bone build function
		if IsValid(self.Owner) then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
				
				// Init viewmodel visibility
				if (self.ShowViewModel == nil or self.ShowViewModel) then
					vm:SetColor(Color(255,255,255,255))
				else
					// we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
					vm:SetColor(Color(255,255,255,1))
					// ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
					// however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
					vm:SetMaterial("Debug/hsv")			
				end
			end
		end
		
	end

end

function SWEP:Holster()
	
	if CLIENT and IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
	end
	
	return true
end

function SWEP:OnRemove()
	self:Holster()
end

if CLIENT then

	SWEP.vRenderOrder = nil
	function SWEP:ViewModelDrawn()
		
		local vm = self.Owner:GetViewModel()
		if !IsValid(vm) then return end
		
		if (!self.VElements) then return end
		
		self:UpdateBonePositions(vm)

		if (!self.vRenderOrder) then
			
			// we build a render order because sprites need to be drawn after models
			self.vRenderOrder = {}

			for k, v in pairs( self.VElements ) do
				if (v.type == "Model") then
					table.insert(self.vRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.vRenderOrder, k)
				end
			end
			
		end

		for k, name in ipairs( self.vRenderOrder ) do
		
			local v = self.VElements[name]
			if (!v) then self.vRenderOrder = nil break end
			if (v.hide) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (!v.bone) then continue end
			
			local pos, ang = self:GetBoneOrientation( self.VElements, v, vm )
			
			if (!pos) then continue end
			
			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				//model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
			elseif (v.type == "Sprite" and sprite) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
				
			elseif (v.type == "Quad" and v.draw_func) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()

			end
			
		end
		
	end

	SWEP.wRenderOrder = nil
	function SWEP:DrawWorldModel()
		
		if (self.ShowWorldModel == nil or self.ShowWorldModel) then
			self:DrawModel()
		end
		
		if (!self.WElements) then return end
		
		if (!self.wRenderOrder) then

			self.wRenderOrder = {}

			for k, v in pairs( self.WElements ) do
				if (v.type == "Model") then
					table.insert(self.wRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.wRenderOrder, k)
				end
			end

		end
		
		if (IsValid(self.Owner)) then
			bone_ent = self.Owner
		else
			// when the weapon is dropped
			bone_ent = self
		end
		
		for k, name in pairs( self.wRenderOrder ) do
		
			local v = self.WElements[name]
			if (!v) then self.wRenderOrder = nil break end
			if (v.hide) then continue end
			
			local pos, ang
			
			if (v.bone) then
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent )
			else
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
			end
			
			if (!pos) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				//model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
			elseif (v.type == "Sprite" and sprite) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
				
			elseif (v.type == "Quad" and v.draw_func) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()

			end
			
		end
		
	end

	function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
		
		local bone, pos, ang
		if (tab.rel and tab.rel != "") then
			
			local v = basetab[tab.rel]
			
			if (!v) then return end
			
			// Technically, if there exists an element with the same name as a bone
			// you can get in an infinite loop. Let's just hope nobody's that stupid.
			pos, ang = self:GetBoneOrientation( basetab, v, ent )
			
			if (!pos) then return end
			
			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
		else
		
			bone = ent:LookupBone(bone_override or tab.bone)

			if (!bone) then return end
			
			pos, ang = Vector(0,0,0), Angle(0,0,0)
			local m = ent:GetBoneMatrix(bone)
			if (m) then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end
			
			if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
				ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
				ang.r = -ang.r // Fixes mirrored models
			end
		
		end
		
		return pos, ang
	end

	function SWEP:CreateModels( tab )

		if (!tab) then return end

		// Create the clientside models here because Garry says we can't do it in the render hook
		for k, v in pairs( tab ) do
			if (v.type == "Model" and v.model and v.model != "" and (!IsValid(v.modelEnt) or v.createdModel != v.model) and 
					string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") ) then
				
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if (IsValid(v.modelEnt)) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else
					v.modelEnt = nil
				end
				
			elseif (v.type == "Sprite" and v.sprite and v.sprite != "" and (!v.spriteMaterial or v.createdSprite != v.sprite) 
				and file.Exists ("materials/"..v.sprite..".vmt", "GAME")) then
				
				local name = v.sprite.."-"
				local params = { ["$basetexture"] = v.sprite }
				// make sure we create a unique name based on the selected options
				local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
				for i, j in pairs( tocheck ) do
					if (v[j]) then
						params["$"..j] = 1
						name = name.."1"
					else
						name = name.."0"
					end
				end

				v.createdSprite = v.sprite
				v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
				
			end
		end
		
	end
	
	local allbones
	local hasGarryFixedBoneScalingYet = false

	function SWEP:UpdateBonePositions(vm)
		
		if self.ViewModelBoneMods then
			
			if (!vm:GetBoneCount()) then return end
			
			// !! WORKAROUND !! //
			// We need to check all model names :/
			local loopthrough = self.ViewModelBoneMods
			if (!hasGarryFixedBoneScalingYet) then
				allbones = {}
				for i=0, vm:GetBoneCount() do
					local bonename = vm:GetBoneName(i)
					if (self.ViewModelBoneMods[bonename]) then 
						allbones[bonename] = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename] = { 
							scale = Vector(1,1,1),
							pos = Vector(0,0,0),
							angle = Angle(0,0,0)
						}
					end
				end
				
				loopthrough = allbones
			end
			// !! ----------- !! //
			
			for k, v in pairs( loopthrough ) do
				local bone = vm:LookupBone(k)
				if (!bone) then continue end
				
				// !! WORKAROUND !! //
				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms = Vector(1,1,1)
				if (!hasGarryFixedBoneScalingYet) then
					local cur = vm:GetBoneParent(bone)
					while(cur >= 0) do
						local pscale = loopthrough[vm:GetBoneName(cur)].scale
						ms = ms * pscale
						cur = vm:GetBoneParent(cur)
					end
				end
				
				s = s * ms
				// !! ----------- !! //
				
				if vm:GetManipulateBoneScale(bone) != s then
					vm:ManipulateBoneScale( bone, s )
				end
				if vm:GetManipulateBoneAngles(bone) != v.angle then
					vm:ManipulateBoneAngles( bone, v.angle )
				end
				if vm:GetManipulateBonePosition(bone) != p then
					vm:ManipulateBonePosition( bone, p )
				end
			end
		else
			self:ResetBonePositions(vm)
		end
		   
	end
	 
	function SWEP:ResetBonePositions(vm)
		
		if (!vm:GetBoneCount()) then return end
		for i=0, vm:GetBoneCount() do
			vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
			vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
			vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
		end
		
	end

	/**************************
		Global utility code
	**************************/

	// Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
	// Does not copy entities of course, only copies their reference.
	// WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
	function table.FullCopy( tab )

		if (!tab) then return nil end
		
		local res = {}
		for k, v in pairs( tab ) do
			if (type(v) == "table") then
				res[k] = table.FullCopy(v) // recursion ho!
			elseif (type(v) == "Vector") then
				res[k] = Vector(v.x, v.y, v.z)
			elseif (type(v) == "Angle") then
				res[k] = Angle(v.p, v.y, v.r)
			else
				res[k] = v
			end
		end
		
		return res
		
	end
	
end


