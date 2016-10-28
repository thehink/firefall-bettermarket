--Hardcoded until theres a better way to get this information

filters = {
	{title="Price", name="price", type="textinput", min=50, img="crystitepic"},
	{title="Price Per Unit", name="price_per_unit", type="textinput", min=0, img="crystitepic"},
	--{title="Mass", name="stat_mass", type="slider", min=0, max=2000, img="crystitepic"},
	--{title="Power", name="stat_power", type="slider", min=0, max=2000, img="crystitepic"},
	--{title="CPU", name="stat_cpu", type="slider", min=0, max=2000, img="crystitepic"},
	{title="Stage", name="tier", type="slider", min=1, max=4, img="crystitepic"},
	{title="Quality", name="stat_quality", type="slider", min=1, max=1000, img="crystitepic"},
	{title="Item Type ID", name="item_sdb_id", type="single"},
}

--[[
{title="Price", name="price", type="textinput", min=50, img="crystitepic"},
	{title="Price Per Unit", name="price_per_unit", type="textinput", min=0, img="crystitepic"},
	{title="Mass", name="stat_mass", type="slider", min=0, max=2000, img="crystitepic"},
	{title="Power", name="stat_power", type="slider", min=0, max=2000, img="crystitepic"},
	{title="CPU", name="stat_cpu", type="slider", min=0, max=2000, img="crystitepic"},
	{title="Stage", name="tier", type="slider", min=1, max=4, img="crystitepic"},
	{title="Quality", name="stat_quality", type="slider", min=1, max=1000, img="crystitepic"},
	{title="Duration", name="stat_duration", type="slider", min=1, max=1000, img="crystitepic"},
	{title="Repair Pool", name="stat_repair_pool", type="slider", min=1, max=1000, img="crystitepic"},
	{title="Max Ammo", name="stat_max_ammo", type="slider", min=1, max=200},
	{title="Strength", name="stat_strength", type="slider", min=1, max=200},
	{title="Jump Height", name="stat_jump_height", type="slider", min=1, max=1000},
	{title="Run Speed", name="stat_run_speed", type="slider", min=1, max=1000},
	{title="DPS", name="stat_dps", type="slider", min=1, max=1000},
	{title="Damage", name="stat_damage", type="slider", min=1, max=1000},
	{title="Deployable Health", name="stat_deployable_health", type="slider", min=1, max=1000},
	{title="Item SDB id", name="item_sdb_id", type="single"},
]]

--dump of all sort varables that doesn't return error from the market web api
sort_variables = jsontotable([[
[
	{
		"format" : "%s", 
		"title" : "Prestige", 
		"name" : "prestige"
	}, 
	{
		"format" : "%s", 
		"title" : "Expires", 
		"name" : "expires_at"
		"blueprint" : "expires_at",
	}, 
	    {
		"format" : "%d", 
		"title" : "Air Sprint", 
		"name" : "air_sprint"
	}, 
	{
		"format" : "%.02f%% lower cost", 
		"title" : "Power Modifier", 
		"name" : "power_mod1"
	}, 
	{
		"format" : "%.2f%%", 
		"title" : "Speed Boost", 
		"name" : "speed_boost"
	}, 
	{
		"format" : "%d%%", 
		"title" : "Damage bonus", 
		"name" : "damagebonus"
	}, 
	{
		"format" : "%.2f", 
		"title" : "Knockback", 
		"name" : "knockback"
	}, 
	{
		"format" : "%.2f m/s", 
		"title" : "Run Speed", 
		"name" : "run_speed"
	}, 
	{
		"format" : "%d", 
		"title" : "CPU", 
		"name" : "cpu"
	}, 
	{
		"format" : "%.2f", 
		"title" : "Charge Speed", 
		"name" : "charge_speed"
	}, 
	{
		"format" : "%.2fm", 
		"title" : "Range", 
		"name" : "range"
	}, 
	{
		"format" : "%.2f", 
		"title" : "Mass", 
		"name" : "mass"
	}, 
	{
		"format" : "%d", 
		"title" : "Energy Drain", 
		"name" : "energy_drain"
	}, 
	{
		"format" : "%.2fm", 
		"title" : "Weapon Splash Radius", 
		"name" : "weapon_splash_radius"
	}, 
	{
		"format" : "%.2fx", 
		"title" : "Sprint Energy Cost", 
		"name" : "sprint_energy_cost"
	}, 
	{
		"format" : "%.2f", 
		"title" : "Healing Wave Knockback", 
		"name" : "healing_wave_knockback"
	}, 
	{
		"format" : "%.1fs", 
		"title" : "Reload Speed", 
		"name" : "reload_speed"
	}, 
	{
		"format" : "%.2f m/s", 
		"title" : "Impulse Strength", 
		"name" : "impulse_strength"
	}, 
	{
		"format" : "%.2f%%", 
		"title" : "Movement Reduction", 
		"name" : "movement_reduction"
	}, 
	{
		"format" : "%.2f", 
		"title" : "Bonus Damage", 
		"name" : "bonus_damage"
	}, 
	{
		"format" : "%d", 
		"title" : "Max Turrets", 
		"name" : "max_turrets"
	}, 
	{
		"format" : "%d health", 
		"title" : "Healing", 
		"name" : "healing"
	}, 
	{
		"format" : "%.2fs", 
		"title" : "Turret Duration", 
		"name" : "turret_duration"
	}, 
	{
		"format" : "%.2f s", 
		"title" : "Rate of Fire Duration", 
		"name" : "rateof_fire_duration"
	}, 
	{
		"format" : "%+.0f%%", 
		"title" : "Repair Pool Modifier", 
		"name" : "repair_pool_mod1"
	}, 
	{
		"format" : "%d base damage", 
		"title" : "Damage", 
		"name" : "damage"
	}, 
	{
		"format" : "%.2fm", 
		"title" : "Mortar Launcher Splash Radius", 
		"name" : "mortar_launcher_splash_radius"
	}, 
	{
		"format" : "%.2f m", 
		"title" : "Healing Leash Distance", 
		"name" : "healing_leash_distance"
	}, 
	{
		"format" : "%.2f seconds", 
		"title" : "Glider Wings Duration", 
		"name" : "glider_wings_duration"
	}, 
	{
		"format" : "%d damage", 
		"title" : "Bulwark Shield", 
		"name" : "bulwark_shield"
	}, 
	{
		"format" : "%.2fx hp", 
		"title" : "Revive Bonus", 
		"name" : "revive_bonus"
	}, 
	{
		"format" : "%d HP.", 
		"title" : "Health", 
		"name" : "health"
	}, 
	{
		"format" : "%.2f N", 
		"title" : "Repulsor Blast Knockback", 
		"name" : "repulsor_blast_knockback"
	}, 
	{
		"format" : "%.2fs", 
		"title" : "Snare Duration", 
		"name" : "snare_duration"
	}, 
	{
		"format" : "%.2fs", 
		"title" : "Deployable Duration", 
		"name" : "deployable_duration"
	}, 
	{
		"format" : "%.2f%% health", 
		"title" : "AI Health", 
		"name" : "ai_health"
	}, 
	{
		"format" : "%.2f m", 
		"title" : "Effect Radius", 
		"name" : "effect_radius"
	}, 
	{
		"format" : "%d", 
		"title" : "Clip Size", 
		"name" : "clip_size"
	}, 
	{
		"format" : "%d damage", 
		"title" : "Turret Damage", 
		"name" : "turret_damage"
	}, 
	{
		"format" : "%d", 
		"title" : "Healing and Damage", 
		"name" : "healingand_damage"
	}, 
	{
		"format" : "%d hp", 
		"title" : "Wall Health", 
		"name" : "wall_health"
	}, 
	{
		"format" : "%d number of mines", 
		"title" : "Max Allowed", 
		"name" : "max_allowed"
	}, 
	{
		"format" : "%d", 
		"title" : "Shots", 
		"name" : "shots"
	}, 
	{
		"format" : "%.2f meters", 
		"title" : "Shoulder Rockets Radius", 
		"name" : "shoulder_rockets_radius"
	}, 
	{
		"format" : "%d", 
		"title" : "Max Targets", 
		"name" : "max_targets"
	}, 
	{
		"format" : "%.2f m/s", 
		"title" : "Evacuate Impulse Strength", 
		"name" : "evacuate_impulse_strength"
	}, 
	{
		"format" : "%.2fs", 
		"title" : "Ability Duration", 
		"name" : "ability_duration"
	}, 
	{
		"format" : "%.2f", 
		"title" : "Energy", 
		"name" : "energy"
	}, 
	{
		"format" : "%d hp", 
		"title" : "Deployable Health", 
		"name" : "deployable_health"
	}, 
	{
		"format" : "%.2f HP/s", 
		"title" : "Health Regen", 
		"name" : "health_regen"
	}, 
	{
		"format" : "%.2f /s", 
		"title" : "Jet Energy Recharge", 
		"name" : "jet_energy_recharge"
	}, 
	{
		"format" : "%.2fs", 
		"title" : "Particle Beam Recharge", 
		"name" : "particle_beam_recharge"
	}, 
	{
		"format" : "%.2f m/s", 
		"title" : "Speed Bonus", 
		"name" : "speed_bonus"
	}, 
	{
		"format" : "%.2f seconds", 
		"title" : "Overload Weapon Chargeup", 
		"name" : "overload_weapon_chargeup"
	}, 
	{
		"format" : "%d energy injection", 
		"title" : "Energy Injection", 
		"name" : "energy_injection"
	}, 
	{
		"format" : "%.2fs", 
		"title" : "EMP Duration", 
		"name" : "emp_duration"
	}, 
	{
		"format" : "%.2f spread", 
		"title" : "Weapon Spread", 
		"name" : "weapon_spread"
	}, 
	{
		"format" : "%.2fs", 
		"title" : "Recharge", 
		"name" : "recharge"
	}, 
	{
		"format" : "%.2fs", 
		"title" : "Fire Patch Duration", 
		"name" : "fire_patch_duration"
	}, 
	{
		"format" : "%.02f%% lower cost", 
		"title" : "Mass Modifier", 
		"name" : "mass_mod1"
	}, 
	{
		"format" : "%.2f seconds", 
		"title" : "Charge Time", 
		"name" : "charge_time"
	}, 
	{
		"format" : "%.2fs", 
		"title" : "Debuff Duration", 
		"name" : "debuff_duration"
	}, 
	{
		"format" : "%.2f%%", 
		"title" : "Health Threshold", 
		"name" : "health_threshold"
	}, 
	{
		"format" : "%d", 
		"title" : "Repair Pool", 
		"name" : "repair_pool"
	}, 
	{
		"format" : "%.2f ms/burst", 
		"title" : "Rate of Fire", 
		"name" : "rateof_fire"
	}, 
	{
		"format" : "%.2fs", 
		"title" : "Damage Duration", 
		"name" : "damage_duration"
	}, 
	{
		"format" : "%.2f multiplier", 
		"title" : "Damage Multiplier", 
		"name" : "damage_multiplier_mod1"
	}, 
	{
		"format" : "%.2f s", 
		"title" : "Duration", 
		"name" : "duration"
	}, 
	{
		"format" : "%d", 
		"title" : "Max Ammo", 
		"name" : "max_ammo"
	}, 
	{
		"format" : "%d", 
		"title" : "Damage Absorption", 
		"name" : "damage_absorption"
	}, 
	{
		"format" : "%.2fs", 
		"title" : "Cloud Duration", 
		"name" : "cloud_duration"
	}, 
	{
		"format" : "%.2fs", 
		"title" : "Buff Duration", 
		"name" : "buff_duration"
	}, 
	{
		"format" : "%.2f", 
		"title" : "Item Heal", 
		"name" : "item_heal"
	}, 
	{
		"format" : "%.2f%%", 
		"title" : "Damage Boost", 
		"name" : "damage_boost"
	}, 
	{
		"format" : "%.2fm", 
		"title" : "Effect Radois", 
		"name" : "effect_radois"
	}, 
	{
		"format" : "%d rounds per burst", 
		"title" : "Rounds Per Burst", 
		"name" : "rounds_per_burst"
	}, 
	{
		"format" : "%d", 
		"title" : "Repair Amount", 
		"name" : "repair_amount"
	}, 
	{
		"format" : "%d damage", 
		"title" : "Rocket Damage", 
		"name" : "rocket_damage"
	}, 
	{
		"format" : "%.2f%%", 
		"title" : "Damage Reduction", 
		"name" : "damage_reduction"
	}, 
	{
		"format" : "%d hp", 
		"title" : "Heal strength", 
		"name" : "healstrength"
	}, 
	{
		"format" : "%.2f%%", 
		"title" : "Damage Bonus", 
		"name" : "damage_bonus"
	}, 
	{
		"format" : "%.2f%%", 
		"title" : "Deployable Health Threshold", 
		"name" : "deployable_health_threshold"
	}, 
	{
		"format" : "%.2f m/s", 
		"title" : "Rocket Jump Impulse Strength", 
		"name" : "rocket_jump_impulse_strength"
	}, 
	{
		"format" : "%.2f%%", 
		"title" : "Lifesteal", 
		"name" : "lifesteal"
	}, 
	{
		"format" : "%d", 
		"title" : "Pulse Damage", 
		"name" : "pulse_damage"
	}, 
	{
		"format" : "%.2f", 
		"title" : "Power", 
		"name" : "power"
	}, 
	{
		"format" : "%d", 
		"title" : "Damage Per Round", 
		"name" : "damage_per_round"
	}, 
	{
		"format" : "%.1f DPS", 
		"title" : "DPS", 
		"name" : "dps"
	}, 
	{
		"format" : "%.2f m/s", 
		"title" : "Strength", 
		"name" : "strength"
	}, 
	{
		"format" : "%d base damage", 
		"title" : "Shoulder Rocket Damage", 
		"name" : "shoulder_rocket_damage"
	}, 
	{
		"format" : "%.2f seconds", 
		"title" : "Charge-up Duration", 
		"name" : "charge_up_duration"
	}, 
	{
		"format" : "%.2f%%", 
		"title" : "Damage Amp", 
		"name" : "damage_amp"
	}, 
	{
		"format" : "%.2f%%", 
		"title" : "Debuff Amount", 
		"name" : "debuff_amount"
	}, 
	{
		"format" : "%.2f m", 
		"title" : "Jump Height", 
		"name" : "jump_height"
	}
]
]]);

table.sort(sort_variables, function(a,b) return a.title < b.title; end);

for _,v in ipairs(sort_variables) do
	table.insert(filters, {title=v.title, name="stat_"..v.name, type="slider"});
end
--[[{
	{title = "Mass", name="mass", blueprint = "number"},
	{title = "CPU", name="cpu", blueprint = "number"},
	{title = "Power", name="power", blueprint = "number"},
	{title = "Dps", name="dps", blueprint = "number"},
	{title = "DMG Per Round", name="damage_per_round", blueprint = "number"},
	
	{title = "Stage", name="tier"},
	{title = "Repair Pool", name="repair_pool"},
	
	{title = "Duration", name="duration", blueprint = "number"},
	{title = "Recharge", name="recharge"},
	{title = "Healing", name="healing"},
	{title = "Effect Radius", name="effect_radius"},
	{title = "Charge Speed", name="charge_speed"},
	{title = "Damage", name="damage"},
	{title = "Movement Reduction", name="movement_reduction"},
	
	{title = "Range", name="range"},
	{title = "Clip Size", name="clip_size"},
	{title = "Splash Radius", name="weapon_splash_radius"},
	{title = "Rate Of Fire", name="rateof_fire"},
	{title = "Reload Speed", name="reload_speed"},
	{title = "Max Ammo", name="max_ammo"},
	
	{title = "Run Speed", name="run_speed"},
	{title = "Jump Height", name="jump_height"},
	{title = "Expiration Date", name="expires_at"},
}]]

categories = {
	{name="All Items", ids = {0}},
	{name="Jumpjets", ids = {16}},
	{name="Plating", ids = {17}},
	{name="Servos", ids = {18}},
	{name="Weapon", ids = {58}, subcategories = {
		{name="Primaries", ids = {59},subcategories = {
			{name="Bio Rifle", ids = {496}},
			{name="Bio Crossbow", ids = {1263}},
			{name="Thermal Cannon", ids = {495}},
			{name="Sniper Rifle", ids = {33}},
			{name="Heavy Laser MG", ids = {752}},
			{name="Fusion Cannon", ids = {751}},
			{name="Charge Rifle", ids = {1262}},
			{name="Tesla Rifle", ids = {69}},
			{name="Shock Rail", ids = {1007}},
			{name="Bio Needler", ids = {32}},
			{name="Plasma Cannon", ids = {20}},
			{name="Plasma MG", ids = {1008}},
			{name="R36 Assault Rifle", ids = {1279}},
			{name="Heavy MG(not working)", ids = {58}},
			{name="Sticky Grenade Launcher", ids = {31}},
			{name="LMG(not working)", ids = {58}},
		}},
		{name="Secondaries", ids = {60},subcategories = {
			{name="Assault Rifle", ids = {21}},
			{name="Shotgun", ids = {23}},
			{name="Grenade Launcher", ids = {24}},
			{name="SMG", ids = {22}},
			{name="Burst Rifle", ids = {25}},
		}},
	}},
	{name="Ability Module", ids = {61}},
	{name="Thumper Beacon", ids = {80}},
	{name="Crafting Components", ids = {3321},subcategories = {
		{name="Optional", ids = {1920}},
		{name="Drops", ids = {3446}},
	}},

	{name="Battleframe Progression", ids = {1603}},
	{name="Resources", ids = {15}, subcategories = {
		{name="Mineral", ids = {3298}, subcategories = {
			{name="Copper", ids = {133}},
			{name="Iron", ids = {134}},
			{name="Aluminum", ids = {135}},
			{name="Carbon", ids = {136}},
			{name="Ceramic", ids = {138}},
			{name="Silicate", ids = {137}},
		}},
		{name="Gas", ids = {3299}, subcategories = {
			{name="Nitrine", ids = {141}},
			{name="Radine", ids = {3304}},
			{name="Octine", ids = {140}},
			{name="Methine", ids = {139}},
		}},
		{name="Organic", ids = {3300}, subcategories = {
			{name="Petrochemical", ids = {142}},
			{name="Biopolymer", ids = {143}},
			{name="Xenografts", ids = {144}},
			{name="Regenics", ids = {146}},
			{name="Anabolics", ids = {147}},
			{name="Toxins", ids = {145}},
		}}
	}},
	
	{name="Deployable", ids = {81}},
	
	{name="Consumables", ids = {84, 89, 82}, subcategories = {
		{name="Vehicles", ids = {84}},
		{name="Pet", ids = {89}},
	}},
	
	{name="Vehicles", ids = {84}},

	{name="Currency", ids = {207}},
	{name="Encapsulated Super-Melded Cell", ids = {3378}},
	
};