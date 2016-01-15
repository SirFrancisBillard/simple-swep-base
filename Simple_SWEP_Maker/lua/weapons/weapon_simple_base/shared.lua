AddCSLuaFile()

-- Spawning info

SWEP.Spawnable = true
SWEP.AdminOnly = true

-- SWEP info

SWEP.ClassName = "simple_base"
SWEP.PrintName = "Simple SWEP Base"
SWEP.Base = "weapon_base"

-- Personal info

SWEP.Author = "<Your name here>"
SWEP.Contact = "www.google.com"
SWEP.Purpose = "Shoot"
SWEP.Instructions = "Point and click"

-- Model info

SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 62
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.UseHands = false
SWEP.HoldType = "pistol"

-- Switching info

SWEP.AutoSwitchFrom = true
SWEP.AutoSwitchTo = true
SWEP.Weight = 5

-- Viewmodel animations

SWEP.BobScale = 1
SWEP.SwayScale = 1

-- Info box info

SWEP.BounceWeaponIcon = true
SWEP.DrawWeaponInfoBox = true

-- Drawing info

SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

-- Slot info

SWEP.Slot = 0
SWEP.SlotPos = 10

-- Primary attack info

SWEP.Primary.Ammo = "pistol"
SWEP.Primary.ClipSize = 18
SWEP.Primary.DefaultClip = 36
SWEP.Primary.Automatic = false
SWEP.Primary.Damage = 10
SWEP.Primary.PushForce = 500
SWEP.Primary.MaxDistance = 50000
SWEP.Primary.NumBullets = 1
SWEP.Primary.Trace = 1
SWEP.Primary.Cone = 0.05
SWEP.Primary.Recoil = 1

-- Secondary attack info

SWEP.Secondary.Ammo = "buckshot"
SWEP.Secondary.ClipSize = 4
SWEP.Secondary.DefaultClip = 8
SWEP.Secondary.Automatic = false
SWEP.Secondary.Damage = 10
SWEP.Secondary.PushForce = 500
SWEP.Secondary.MaxDistance = 50000
SWEP.Secondary.NumBullets = 6
SWEP.Secondary.Trace = 1
SWEP.Secondary.Cone = 0.05
SWEP.Secondary.Recoil = 1

-- Sound info

SWEP.Primary.Sound = "Weapon_AR2.Single"
SWEP.Secondary.Sound = "Weapon_Shotgun.Single"
SWEP.HolsterSound = ""
SWEP.DeploySound = ""
SWEP.ExtraReloadSound = "" -- Sound played over the default reload sound

-- Misc info

SWEP.AccurateCrosshair = true -- 3D crosshair
SWEP.m_WeaponDeploySpeed = 1 -- Multiplier of weapon deploy animation speed
SWEP.ShouldDropOnDeath = false

-- Base code

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:Reload()
	self.Weapon:DefaultReload( ACT_VM_RELOAD )
	if not SWEP.ExtraReloadSound == "" then
		self.Weapon:EmitSound( self.ExtraReloadSound )
	end
end

function SWEP:Holster( wep )
	return true
	if not SWEP.HolsterSound == "" then
		self.Weapon:EmitSound( self.HolsterSound )
	end
end

function SWEP:Deploy()
	return true
	if not SWEP.DeploySound == "" then
		self.Weapon:EmitSound( self.DeploySound )
	end
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack then return end
	self:TakePrimaryAmmo( 1 )
	self.Weapon:EmitSound( self.Primary.Sound )
	local bullet = {}
	bullet.Num 	= self.Primary.NumBullets
	bullet.Src 	= self.Owner:GetShootPos()
	bullet.Dir 	= self.Owner:GetAimVector()
	bullet.Spread 	= Vector( self.Primary.Cone, self.Primary.Cone, 0 )
	bullet.Tracer	= self.Primary.Trace -- Show a tracer on every X bullets
	bullet.Force	= self.Primary.PushForce
	bullet.Damage	= self.Primary.Damage
	bullet.AmmoType = "Pistol"
	self.Owner:FireBullets( bullet )
	self:ShootEffects()
	self.Owner:ViewPunch( Angle( self.Primary.Recoil * -1, 0, 0 ) )
end

function SWEP:SecondaryAttack()
	if not self:CanSecondaryAttack then return end
	self:TakeSecondaryAmmo( 1 )
	self.Weapon:EmitSound( self.Secondary.Sound )
	local bullet = {}
	bullet.Num 	= self.Secondary.NumBullets
	bullet.Src 	= self.Owner:GetShootPos()
	bullet.Dir 	= self.Owner:GetAimVector()
	bullet.Spread 	= Vector( self.Secondary.Cone, self.Secondary.Cone, 0 )
	bullet.Tracer	= self.Secondary.Trace -- Show a tracer on every X bullets
	bullet.Force	= self.Secondary.PushForce
	bullet.Damage	= self.Secondary.Damage
	bullet.AmmoType = "Pistol"
	self.Owner:FireBullets( bullet )
	self:ShootEffects()
	self.Owner:ViewPunch( Angle( self.Secondary.Recoil * -1, 0, 0 ) )
end

function SWEP:ShouldDropOnDie()
	return self.ShouldDropOnDeath
end
