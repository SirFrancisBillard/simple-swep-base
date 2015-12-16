--[[---------------------------------------------------------------------------
Here's an example weapon that you can edit (HUGE thanks to FPtje for this)
---------------------------------------------------------------------------]]
AddCSLuaFile()

if CLIENT then
	SWEP.PrintName = "Simple AK47" --The fancy name of your SWEP
	SWEP.Author = "Simple Simpleton" --Who made this SWEP
	SWEP.Slot = 3 --What slot on the hotbar it is in
	SWEP.SlotPos = 0 --What position this weapon has in a stack of weapons on your hotbar
	SWEP.IconLetter = "b" --The letter code of the kill icon. Full list of icons can be found here (for CSS): https://wiki.garrysmod.com/page/CS:S_Kill_Icons

	killicon.AddFont("weapon_custom_ak", "CSKillIcons", SWEP.IconLetter, Color(255, 80, 0, 255)) --Make sure that first one is the name of your SWEP
end

SWEP.Base = "weapon_simple_base" --Basically, this is the foundation of the SWEP

SWEP.Spawnable = true --If it can be spawned
SWEP.AdminSpawnable = true --If it can be spawned but only by Admins
SWEP.Category = "Simple Weapons" --Where this gun will be in the Q menu
SWEP.SpawnMenuIcon = "vgui/entities/weapon_ak472" --The icon displayed in the Q menu

SWEP.UseHands = true --If there is a c_ before SWEP.ViewModel then set this to true. Otherwise set this to false
SWEP.ViewModel = "models/weapons/cstrike/c_rif_ak47.mdl" --The model you see when you hold it
SWEP.WorldModel = "models/weapons/w_rif_ak47.mdl" --The model other players see when you hold it

SWEP.Weight = 5 --Higher the weight, the higher priority this weapon has to be auto switched to
SWEP.AutoSwitchTo = false --Autoswitch to this weapon when you pick it up or run out of ammo in your other gun
SWEP.AutoSwitchFrom = false --Autoswitch away from this weapon if you pick something else up or run out of ammo
SWEP.HoldType = "ar2" --How the weapon is held from third person view

SWEP.Primary.Sound = Sound("Weapon_AK47.Single") --The sound made when the gun shoots
SWEP.Primary.Recoil = 1.5 --How much kick the gun has upon firing
SWEP.Primary.Damage = 40 --Base damage this weapon deals
SWEP.Primary.NumShots = 1 --Number of bullets fired per shot. Only really useful for shotguns
SWEP.Primary.Cone = 0.002 --The amount of degrees bullets might stray from the crosshair (Inaccuracy)
SWEP.Primary.ClipSize = 30 --The amount of bullets in a clip
SWEP.Primary.Delay = 0.08 --The delay in seconds between each shot
SWEP.Primary.DefaultClip = 30 --The amount of spare ammo you get for picking this gun up
SWEP.Primary.Automatic = true --Whether or not this weapon fires automatically
SWEP.Primary.Ammo = "smg1" --What ammo is used. For all ammo types, go here: https://wiki.garrysmod.com/page/Default_Ammo_Types

SWEP.Secondary.ClipSize = -1 --If you want your gun to have a secondary fire mode, like the shotgun or SMG from HL2
SWEP.Secondary.DefaultClip = -1 --If you want your gun to have a secondary fire mode, like the shotgun or SMG from HL2
SWEP.Secondary.Automatic = false --If you want your gun to have a secondary fire mode, like the shotgun or SMG from HL2
SWEP.Secondary.Ammo = "none" --If you want your gun to have a secondary fire mode, like the shotgun or SMG from HL2

SWEP.IronSightsPos = Vector(-6.6, -15, 2.6) --Position of ironsights (complicated)
SWEP.IronSightsAng = Vector(2.6, 0.02, 0) --Angle of ironsights (complicated)

SWEP.MultiMode = true --Whether or not the firing mode can be switched between full auto, burst fire and semi auto
SWEP.DrawCrosshair = true --Whether or not there will be a crosshair in the middle of your screen when using this SWEP
