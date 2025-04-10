/*
Base Builder Zombie Mod
Tirant

Version 6.5 Pub
*/

#include <amxmodx>
#include <amxmisc>
#include <credits>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <csx>
#include <msgstocks>
#include <dhudmessage>
#include <basebuilder>
#include <pointssystem>
#include <ColorChat>
#pragma tabsize 0

//Enable this only if you have bought the credits plugin
//#define BB_CREDITS

#define FLAGS_BUILD 	ADMIN_KICK
#define FLAGS_LOCK 	ADMIN_ALL
#define FLAGS_BUILDBAN 	ADMIN_LEVEL_D
#define FLAGS_SWAP 	ADMIN_LEVEL_D
#define FLAGS_REVIVE 	ADMIN_LEVEL_C
#define FLAGS_GUNS 	ADMIN_LEVEL_C
#define FLAGS_RELEASE 	ADMIN_LEVEL_F
#define FLAGS_OVERRIDE 	ADMIN_BAN
#define FLAGS_LOCKAFTER ADMIN_LEVEL_E

#define VERSION "6.5"
#define MODNAME "^x01 [^x04 Base Builder^x01 ]"

#define LockBlock(%1,%2)  	( entity_set_int( %1, EV_INT_iuser1,     %2 ) )
#define UnlockBlock(%1)   	( entity_set_int( %1, EV_INT_iuser1,     0  ) )
#define BlockLocker(%1)   	( entity_get_int( %1, EV_INT_iuser1         ) )

#define MovingEnt(%1)     	( entity_set_int( %1, EV_INT_iuser2,     1 ) )
#define UnmovingEnt(%1)   	( entity_set_int( %1, EV_INT_iuser2,     0 ) )
#define IsMovingEnt(%1)   	( entity_get_int( %1, EV_INT_iuser2 ) == 1 )

#define SetEntMover(%1,%2)  	( entity_set_int( %1, EV_INT_iuser3, %2 ) )
#define UnsetEntMover(%1)   	( entity_set_int( %1, EV_INT_iuser3, 0  ) )
#define GetEntMover(%1)   	( entity_get_int( %1, EV_INT_iuser3     ) )

#define SetLastMover(%1,%2)  	( entity_set_int( %1, EV_INT_iuser4, %2 ) )
#define UnsetLastMover(%1)   	( entity_set_int( %1, EV_INT_iuser4, 0  ) )
#define GetLastMover(%1)  	( entity_get_int( %1, EV_INT_iuser4     ) )

#define MAXPLAYERS 32
#define MAXENTS 1024
#define AMMO_SLOT 376
#define MODELCHANGE_DELAY 0.5
#define AUTO_TEAM_JOIN_DELAY 0.1
#define TEAM_SELECT_VGUI_MENU_ID 2
#define OBJECT_PUSHPULLRATE 4.0
#define HUD_FRIEND_HEIGHT 0.30

#define BARRIER_COLOR 0.0, 0.0, 0.0
#define BARRIER_RENDERAMT 150.0

#define BLOCK_RENDERAMT 150.0

#define LOCKED_COLOR 125.0, 0.0, 0.0
#define LOCKED_RENDERAMT 225.0

const ZOMBIE_ALLOWED_WEAPONS_BITSUM = (1<<CSW_KNIFE)
#define OFFSET_WPN_WIN 	  41
#define OFFSET_WPN_LINUX  4

#define OFFSET_ACTIVE_ITEM 373
#define OFFSET_LINUX 5
#define TASK_TUTOR 467666646

#if cellbits == 32
	#define OFFSET_BUYZONE 235
#else
	#define OFFSET_BUYZONE 268
#endif


new g_iMaxPlayers
new g_msgSayText, g_msgStatusText
new g_HudSync, g_HudSync1
new map[64]
new g_round = 1;

new keys = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
new ChooseTeamOverrideActive[33];

new g_isConnected[MAXPLAYERS+1]
new g_isAlive[MAXPLAYERS+1]
new g_isZombie[MAXPLAYERS+1]
new g_isBuildBan[MAXPLAYERS+1]
new g_isCustomModel[MAXPLAYERS+1]
const PEV_SPEC_TARGET = pev_iuser2

enum (+= 5000)
{
	TASK_BUILD = 10000,
	TASK_PREPTIME,
	TASK_MODELSET,
	TASK_RESPAWN,
	TASK_HEALTH,
	TASK_IDLESOUND
}

//Custom Sounds
new g_szRoundStart[][] = 
{
	"basebuilder/round_start.wav",
	"basebuilder/round_start2.wav"
}

#define WIN_ZOMBIES 	"basebuilder/win_zombies2.wav"
#define WIN_BUILDERS 	"basebuilder/win_builders2.wav"

#define PHASE_PREP 	"basebuilder/phase_prep3.wav"
#define PHASE_BUILD 	"basebuilder/phase_build3.wav"

#define LOCK_OBJECT 	"buttons/lightswitch2.wav"
#define LOCK_FAIL	"buttons/button10.wav"

#define GRAB_START	"basebuilder/block_grab.wav"
#define GRAB_STOP	"basebuilder/block_drop.wav"

#define INFECTION	"basebuilder/zombie_kill1.wav"

new const g_szZombiePain[][] =
{
	"basebuilder/zombie/pain/pain1.wav",
	"basebuilder/zombie/pain/pain2.wav",
	"basebuilder/zombie/pain/pain3.wav"
}

new const g_szZombieDie[][] =
{
	"basebuilder/zombie/death/death1.wav",
	"basebuilder/zombie/death/death2.wav",
	"basebuilder/zombie/death/death3.wav"
}

new const g_szZombieIdle[][] =
{
	"basebuilder/zombie/idle/idle1.wav",
	"basebuilder/zombie/idle/idle2.wav",
	"basebuilder/zombie/idle/idle3.wav"
}

new const g_szZombieHit[][] =
{
	"basebuilder/zombie/hit/hit1.wav",
	"basebuilder/zombie/hit/hit1.wav",
	"basebuilder/zombie/hit/hit1.wav"
}

new const g_szZombieMiss[][] =
{
	"basebuilder/zombie/miss/miss1.wav",
	"basebuilder/zombie/miss/miss2.wav",
	"basebuilder/zombie/miss/miss3.wav"
}

//Custom Player Models
new Float:g_fModelsTargetTime, Float:g_fRoundStartTime
new g_szPlayerModel[MAXPLAYERS+1][32]

//Game Name
new g_szModName[32]

new g_iCountDown, g_iEntBarrier
new bool:g_boolCanBuild, bool:g_boolPrepTime, bool:g_boolRoundEnded
new g_iFriend[MAXPLAYERS+1]
new CsTeams:g_iTeam[MAXPLAYERS+1], CsTeams:g_iCurTeam[MAXPLAYERS+1]
new bool:g_boolFirstTeam[MAXPLAYERS+1]

//Building Stores
new Float:g_fOffset1[MAXPLAYERS+1], Float:g_fOffset2[MAXPLAYERS+1], Float:g_fOffset3[MAXPLAYERS+1]
new g_iOwnedEnt[MAXPLAYERS+1], g_iOwnedEntities[MAXPLAYERS+1]
new Float:g_fEntDist[MAXPLAYERS+1]

static const g_szWpnEntNames[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }
			
//Weapon Names (For Guns Menu)
static const szWeaponNames[24][23] = { "Schmidt Scout", "XM1014 M4", "Ingram MAC-10", "Steyr AUG A1", "UMP 45", "SG-550 Auto-Sniper",
			"IMI Galil", "Famas", "AWP Magnum Sniper", "MP5 Navy", "M249 Para Machinegun", "M3 Super 90", "M4A1 Carbine",
			"Schmidt TMP", "G3SG1 Auto-Sniper", "SG-552 Commando", "AK-47 Kalashnikov", "ES P90", "P228 Compact",
			"Dual Elite Berettas", "Fiveseven", "USP .45 ACP Tactical", "Glock 18C", "Desert Eagle .50 AE" }
			
#define MAX_COLORS 24
new const Float:g_fColor[MAX_COLORS][3] = 
{
	{200.0, 000.0, 000.0},
	{255.0, 083.0, 073.0},
	{255.0, 117.0, 056.0},
	{255.0, 174.0, 066.0},
	{255.0, 207.0, 171.0},
	{252.0, 232.0, 131.0},
	{254.0, 254.0, 034.0},
	{059.0, 176.0, 143.0},
	{197.0, 227.0, 132.0},
	{000.0, 150.0, 000.0},
	{120.0, 219.0, 226.0},
	{135.0, 206.0, 235.0},
	{128.0, 218.0, 235.0},
	{000.0, 000.0, 255.0},
	{146.0, 110.0, 174.0},
	{255.0, 105.0, 180.0},
	{246.0, 100.0, 175.0},
	{205.0, 074.0, 076.0},
	{250.0, 167.0, 108.0},
	{234.0, 126.0, 093.0},
	{180.0, 103.0, 077.0},
	{149.0, 145.0, 140.0},
	{000.0, 000.0, 000.0},
	{255.0, 255.0, 255.0}
}

new const Float:g_fRenderAmt[MAX_COLORS] = 
{
	100.0, //Red
	135.0, //Red Orange
	140.0, //Orange
	120.0, //Yellow Orange
	140.0, //Peach
	125.0, //Yellow
	100.0, //Lemon Yellow
	125.0, //Jungle Green
	135.0, //Yellow Green
	100.0, //Green
	125.0, //Aquamarine
	150.0, //Baby Blue
	090.0, //Sky Blue
	075.0, //Blue
	175.0, //Violet
	150.0, //Hot Pink
	175.0, //Magenta
	140.0, //Mahogany
	140.0, //Tan
	140.0, //Light Brown
	165.0, //Brown
	175.0, //Gray
	125.0, //Black
	125.0   //White
}

new const g_szColorName[MAX_COLORS][] = 
{
	"Red",
	"Red Orange",
	"Orange",
	"Yellow Orange",
	"Peach",
	"Yellow",
	"Lemon Yellow",
	"Jungle Green",
	"Yellow Green",
	"Green",
	"Aquamarine",
	"Baby Blue",
	"Sky Blue",
	"Blue",
	"Violet",
	"Hot Pink",
	"Magenta",
	"Mahogany",
	"Tan",
	"Light Brown",
	"Brown",
	"Gray",
	"Black",
	"White"
}

enum
{
	COLOR_RED = 0, 		//200, 000, 000
	COLOR_REDORANGE, 	//255, 083, 073
	COLOR_ORANGE, 		//255, 117, 056
	COLOR_YELLOWORANGE, 	//255, 174, 066
	COLOR_PEACH, 		//255, 207, 171
	COLOR_YELLOW, 		//252, 232, 131
	COLOR_LEMONYELLOW, 	//254, 254, 034
	COLOR_JUNGLEGREEN, 	//059, 176, 143
	COLOR_YELLOWGREEN, 	//197, 227, 132
	COLOR_GREEN, 		//000, 200, 000
	COLOR_AQUAMARINE, 	//120, 219, 226
	COLOR_BABYBLUE, 		//135, 206, 235
	COLOR_SKYBLUE, 		//128, 218, 235
	COLOR_BLUE, 		//000, 000, 200
	COLOR_VIOLET, 		//146, 110, 174
	COLOR_PINK, 		//255, 105, 180
	COLOR_MAGENTA, 		//246, 100, 175
	COLOR_MAHOGANY,		//205, 074, 076
	COLOR_TAN, 		//250, 167, 108
	COLOR_LIGHTBROWN, 	//234, 126, 093
	COLOR_BROWN, 		//180, 103, 077
	COLOR_GRAY, 		//149, 145, 140
	COLOR_BLACK, 		//000, 000, 000
	COLOR_WHITE 		//255, 255, 255
}

new g_iColor[MAXPLAYERS+1]
new g_iColorOwner[MAX_COLORS]

//Color Menu
new g_iMenuOffset[MAXPLAYERS+1], g_iMenuOptions[MAXPLAYERS+1][8], g_iWeaponPicked[2][MAXPLAYERS+1],
	g_iPrimaryWeapon[MAXPLAYERS+1]
	
new bool:g_boolFirstTime[MAXPLAYERS+1], bool:g_boolRepick[MAXPLAYERS+1]

new Float:g_fBuildDelay[MAXPLAYERS+1]
#define BUILD_DELAY 0.75

#define KEYS_GENERIC (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)

enum
{
	ATT_HEALTH = 0,
	ATT_SPEED,
	ATT_GRAVITY
}

//Zombie Classes
new g_iZClasses
new g_iZombieClass[MAXPLAYERS+1]
new bool:g_boolFirstSpawn[MAXPLAYERS+1]
new g_szPlayerClass[MAXPLAYERS+1][32]
new g_iNextClass[MAXPLAYERS+1]
new Float:g_fPlayerSpeed[MAXPLAYERS+1]
new bool:g_boolArraysCreated
new Array:g_zclass_name
new Array:g_zclass_info
new Array:g_zclass_modelsstart // start position in models array
new Array:g_zclass_modelsend // end position in models array
new Array:g_zclass_playermodel // player models array
new Array:g_zclass_modelindex // model indices array
new Array:g_zclass_clawmodel
new Array:g_zclass_hp
new Array:g_zclass_spd
new Array:g_zclass_grav
new Array:g_zclass_admin
new Array:g_zclass_credits
//new Float:g_fClassMultiplier[MAXPLAYERS+1][3]

new Array:g_zclass2_realname, Array:g_zclass2_name, Array:g_zclass2_info,
Array:g_zclass2_modelsstart, Array:g_zclass2_modelsend, Array:g_zclass2_playermodel,
Array:g_zclass2_clawmodel, Array:g_zclass2_hp, Array:g_zclass2_spd,
Array:g_zclass2_grav, Array:g_zclass2_admin, Array:g_zclass2_credits, Array:g_zclass_new

//Forwards
new g_fwRoundStart, g_fwPrepStarted, g_fwBuildStarted, g_fwClassPicked, g_fwClassSet,
g_fwPushPull, g_fwGrabEnt_Pre, g_fwGrabEnt_Post, g_fwDropEnt_Pre,
 g_fwDropEnt_Post, g_fwNewColor, g_fwLockEnt_Pre, g_fwLockEnt_Post, g_fwDummyResult

 //Cvars
new g_pcvar_buildtime, g_iBuildTime,
	g_pcvar_preptime, g_iPrepTime,
	g_pcvar_givenades, g_iGrenadeHE, g_iGrenadeFLASH, g_iGrenadeSMOKE,
	g_pcvar_entmindist, Float: g_fEntMinDist,
	g_pcvar_entsetdist, Float: g_fEntSetDist,
	g_pcvar_entmaxdist, Float: g_fEntMaxDist,
	g_pcvar_resetent, g_iResetEnt,
	g_pcvar_showmovers, g_iShowMovers,
	g_pcvar_lockblocks, g_iLockBlocks,
	g_pcvar_lockmax, g_iLockMax,
	g_pcvar_colormode, g_iColorMode,
	g_pcvar_zombietime, g_iZombieTime,
	g_pcvar_infecttime, g_iInfectTime,
	g_pcvar_supercut, g_iSupercut,
	g_pcvar_gunsmenu, g_iGunsMenu,
	g_pcvar_enabled,
	g_pcvar_allowedweps
	
	

 
 
 
public plugin_precache()
{
	server_cmd("bb_credits_active 0")
	
	register_plugin("Base Builder", VERSION, "Tirant")
	register_cvar("base_builder", VERSION, FCVAR_SPONLY|FCVAR_SERVER)
	set_cvar_string("base_builder", VERSION)
	
	g_pcvar_enabled = register_cvar("bb_enabled", "1")
	
	if (!get_pcvar_num(g_pcvar_enabled))
		return;

	new szCache[64], i;
		
	g_pcvar_buildtime = register_cvar("bb_buildtime", "190") //Build Time
	g_iBuildTime = clamp(get_pcvar_num(g_pcvar_buildtime), 30, 300)
	g_pcvar_preptime = register_cvar("bb_preptime", "30") //Prep Time
	g_iPrepTime = clamp(get_pcvar_num(g_pcvar_preptime), 0, 60)
	g_pcvar_zombietime = register_cvar("bb_zombie_respawn_delay", "2") //Zombie Respawn Delay
	g_iZombieTime = clamp(get_pcvar_num(g_pcvar_zombietime), 1, 30)
	g_pcvar_infecttime = register_cvar("bb_infection_respawn", "5") //Survivor Respawn Infection Delay
	g_iInfectTime = clamp(get_pcvar_num(g_pcvar_infecttime), 0, 30)
	g_pcvar_showmovers = register_cvar("bb_showmovers", "1") //Show Movers
	g_iShowMovers = clamp(get_pcvar_num(g_pcvar_showmovers), 0, 1)
	g_pcvar_lockblocks = register_cvar("bb_lockblocks", "1") //Lock blocks
	g_iLockBlocks = clamp(get_pcvar_num(g_pcvar_lockblocks), 0, 1)
	g_pcvar_lockmax = register_cvar("bb_lockmax", "15") //Lock max
	g_iLockMax = clamp(get_pcvar_num(g_pcvar_lockmax), 0, 50)
	g_pcvar_colormode = register_cvar("bb_colormode", "1") //Color mode <0/1/2> Menu, one color per player, random
	g_iColorMode = clamp(get_pcvar_num(g_pcvar_colormode), 0, 2)
	g_pcvar_entmaxdist = register_cvar("bb_max_move_dist", "768") //Push ceiling
	g_fEntMaxDist = get_pcvar_float(g_pcvar_entmaxdist)
	g_pcvar_entmindist = register_cvar("bb_min_move_dist", "32") //Pull floor
	g_fEntMinDist = get_pcvar_float(g_pcvar_entmindist)
	g_pcvar_entsetdist = register_cvar("bb_min_dist_set", "64") //Grab set
	g_fEntSetDist = get_pcvar_float(g_pcvar_entsetdist)
	g_pcvar_resetent = register_cvar("bb_resetblocks", "1") //Reset blocks on new round
	g_iResetEnt = clamp(get_pcvar_num(g_pcvar_resetent), 0, 1)
	g_pcvar_supercut = register_cvar("bb_zombie_supercut", "0") //One hit kill for zombies
	g_iSupercut = clamp(get_pcvar_num(g_pcvar_supercut), 0, 1)
	g_pcvar_gunsmenu = register_cvar("bb_gunsmenu", "1") //Use the internal guns menu
	g_iGunsMenu = clamp(get_pcvar_num(g_pcvar_gunsmenu), 0, 1)
	
	g_pcvar_givenades = register_cvar("bb_roundnades","h") //Grenades
	g_pcvar_allowedweps = register_cvar("bb_weapons","bmqtx")
	
	get_pcvar_string(g_pcvar_givenades, szCache, sizeof szCache - 1)
	for (i=0; i<strlen(szCache);i++)
	{
		switch(szCache[i])
		{
			case 'h': g_iGrenadeHE++
			case 'f': g_iGrenadeFLASH++
			case 's': g_iGrenadeSMOKE++
		}
	}
	
	for (i=0; i<sizeof g_szRoundStart; i++) 	precache_sound(g_szRoundStart[i])
	for (i=0; i<sizeof g_szZombiePain;i++) 	precache_sound(g_szZombiePain[i])
	for (i=0; i<sizeof g_szZombieDie;i++) 	precache_sound(g_szZombieDie[i])
	for (i=0; i<sizeof g_szZombieIdle;i++) 	precache_sound(g_szZombieIdle[i])
	for (i=0; i<sizeof g_szZombieHit;i++) 	precache_sound(g_szZombieHit[i])
	for (i=0; i<sizeof g_szZombieMiss;i++) 	precache_sound(g_szZombieMiss[i])
	
	precache_sound(WIN_ZOMBIES)
	precache_sound(WIN_BUILDERS)
	precache_sound(PHASE_BUILD)
	precache_sound(PHASE_PREP)
	precache_sound(LOCK_OBJECT)
	precache_sound(LOCK_FAIL)
	precache_sound(GRAB_START)
	precache_sound(GRAB_STOP)
	if (g_iInfectTime)
		precache_sound(INFECTION)
	
	i = create_entity("info_bomb_target");
	entity_set_origin(i, Float:{8192.0,8192.0,8192.0})
	
	i = create_entity("info_map_parameters");
	DispatchKeyValue(i, "buying", "3");
	DispatchKeyValue(i, "bombradius", "1");
	DispatchSpawn(i);
	
	g_zclass_name = ArrayCreate(32, 1)
	g_zclass_info = ArrayCreate(32, 1)
	g_zclass_modelsstart = ArrayCreate(1, 1)
	g_zclass_modelsend = ArrayCreate(1, 1)
	g_zclass_playermodel = ArrayCreate(32, 1)
	g_zclass_modelindex = ArrayCreate(1, 1)
	g_zclass_clawmodel = ArrayCreate(32, 1)
	g_zclass_hp = ArrayCreate(1, 1)
	g_zclass_spd = ArrayCreate(1, 1)
	g_zclass_grav = ArrayCreate(1, 1)
	g_zclass_admin = ArrayCreate(1, 1)
	g_zclass_credits = ArrayCreate(1, 1)
	
	g_zclass2_realname = ArrayCreate(32, 1)
	g_zclass2_name = ArrayCreate(32, 1)
	g_zclass2_info = ArrayCreate(32, 1)
	g_zclass2_modelsstart = ArrayCreate(1, 1)
	g_zclass2_modelsend = ArrayCreate(1, 1)
	g_zclass2_playermodel = ArrayCreate(32, 1)
	g_zclass2_clawmodel = ArrayCreate(32, 1)
	g_zclass2_hp = ArrayCreate(1, 1)
	g_zclass2_spd = ArrayCreate(1, 1)
	g_zclass2_grav = ArrayCreate(1, 1)
	g_zclass2_admin = ArrayCreate(1, 1)
	g_zclass2_credits = ArrayCreate(1, 1)
	g_zclass_new = ArrayCreate(1, 1)
	
	g_boolArraysCreated = true
	
	return;
}

public plugin_cfg()
{
	g_boolArraysCreated = false
}
public event_newround() {
    g_round++
}
public plugin_init()
{
	if (!get_pcvar_num(g_pcvar_enabled))
		return;
		
	formatex(g_szModName, charsmax(g_szModName), "Base Builder %s", VERSION)
	
	register_clcmd("say /menu", "GameMenu");
	register_clcmd("say", 	   	"cmdSay");
	register_clcmd("say_team",	"cmdSay");
	
	register_menu( "Menu 1", keys, "GameMenu_Handler" );
	register_menu( "Menu 2", keys, "PlayerMenu_Handler" );
	
	//Added for old users
	register_clcmd("+grab",		"cmdGrabEnt");
	register_clcmd("-grab",		"cmdStopEnt");
	
	register_clcmd("bb_lock",	"cmdLockBlock",0, " - Aim at a block to lock it");
	register_clcmd("bb_claim",	"cmdLockBlock",0, " - Aim at a block to lock it");
	
	register_clcmd("bb_buildban",	"cmdBuildBan",0, " <player>");
	register_clcmd("bb_unbuildban",	"cmdBuildBan",0, " <player>");
	register_clcmd("bb_bban",	"cmdBuildBan",0, " <player>");
	register_clcmd("chooseteam", "ChooseTeam"); 
	
	register_clcmd("bb_swap",	"cmdSwap",0, " <player>");
	register_clcmd("bb_revive",	"cmdRevive",0, " <player>");
	if (g_iGunsMenu) register_clcmd("bb_guns",	"cmdGuns",0, " <player>");
	register_clcmd("bb_startround",	"cmdStartRound",0, " - Starts the round");
	
	register_logevent("logevent_round_start",2, 	"1=Round_Start")
	register_logevent("logevent_round_end", 2, 	"1=Round_End")
	
	register_message(get_user_msgid("TextMsg"), 	"msgRoundEnd")
	register_message(get_user_msgid("TextMsg"),	"msgSendAudio")
	register_message(get_user_msgid("StatusIcon"), 	"msgStatusIcon");
	register_message(get_user_msgid("Health"), 	"msgHealth");
	register_message(get_user_msgid("StatusValue"), 	"msgStatusValue")
	register_message(get_user_msgid("TeamInfo"), 	"msgTeamInfo");
	
	register_menucmd(register_menuid("ColorsSelect"),KEYS_GENERIC,"colors_pushed")
	register_menucmd(register_menuid("ZClassSelect"),KEYS_GENERIC,"zclass_pushed")
	if (g_iGunsMenu)
	{
		register_menucmd(register_menuid("WeaponMethodMenu"),(1<<0)|(1<<1)|(1<<2),"weapon_method_pushed")
		register_menucmd(register_menuid("PrimaryWeaponSelect"),KEYS_GENERIC,"prim_weapons_pushed")
		register_menucmd(register_menuid("SecWeaponSelect"),KEYS_GENERIC,"sec_weapons_pushed")
	}
	
	register_event("HLTV", 		"ev_RoundStart", "a", "1=0", "2=0")
	register_event("AmmoX", 		"ev_AmmoX", 	 "be", "1=1", "1=2", "1=3", "1=4", "1=5", "1=6", "1=7", "1=8", "1=9", "1=10")
	//register_event("Health",   	"ev_Health", 	 "be", "1>0");
	register_event("StatusValue", 	"ev_SetTeam", 	 "be", "1=1");
	register_event("StatusValue", 	"ev_ShowStatus", "be", "1=2", "2!0");
	register_event("StatusValue", 	"ev_HideStatus", "be", "1=1", "2=0");
	register_event("HLTV", "event_newround", "a", "1=0", "2=0");

	RegisterHam(Ham_Touch, 		"weapon_shield","ham_WeaponCleaner_Post", 1)
	RegisterHam(Ham_Touch, 		"weaponbox",  	"ham_WeaponCleaner_Post", 1)
	RegisterHam(Ham_Spawn, 		"player", 	"ham_PlayerSpawn_Post", 1)
	RegisterHam(Ham_TakeDamage, 	"player", 	"ham_TakeDamage")
	for (new i = 1; i < sizeof g_szWpnEntNames; i++)
		if (g_szWpnEntNames[i][0]) RegisterHam(Ham_Item_Deploy, g_szWpnEntNames[i], "ham_ItemDeploy_Post", 1)
	
	register_forward(FM_GetGameDescription, 		"fw_GetGameDescription")
	register_forward(FM_SetClientKeyValue, 		"fw_SetClientKeyValue")
	register_forward(FM_ClientUserInfoChanged, 	"fw_ClientUserInfoChanged")
	register_forward(FM_CmdStart, 			"fw_CmdStart");
	register_forward(FM_PlayerPreThink, 		"fw_PlayerPreThink")
	register_forward(FM_EmitSound,			"fw_EmitSound")
	register_forward(FM_ClientKill,			"fw_Suicide")
	if (g_iShowMovers)
		register_forward(FM_TraceLine, 		"fw_Traceline")
	
	register_clcmd("drop", "clcmd_drop")
	register_clcmd("buy", "clcmd_buy")
	
	//Team Handlers
	register_message(get_user_msgid("ShowMenu"), "message_show_menu")
	register_message(get_user_msgid("VGUIMenu"), "message_vgui_menu")
	
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET)
	
	g_iMaxPlayers = get_maxplayers()
	g_HudSync = CreateHudSyncObj();
	g_HudSync1 = CreateHudSyncObj();
	g_msgSayText = get_user_msgid("SayText")
	g_msgStatusText = get_user_msgid("StatusText");
	
	g_iEntBarrier = find_ent_by_tname( -1, "barrier" );
	
	//Custom Forwards
	g_fwRoundStart = CreateMultiForward("bb_round_started", ET_IGNORE)
	g_fwPrepStarted = CreateMultiForward("bb_prepphase_started", ET_IGNORE)
	g_fwBuildStarted = CreateMultiForward("bb_buildphase_started", ET_IGNORE)
	g_fwClassPicked = CreateMultiForward("bb_zombie_class_picked", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwClassSet = CreateMultiForward("bb_zombie_class_set", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwPushPull = CreateMultiForward("bb_block_pushpull", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_fwGrabEnt_Pre = CreateMultiForward("bb_grab_pre", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwGrabEnt_Post = CreateMultiForward("bb_grab_post", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwDropEnt_Pre = CreateMultiForward("bb_drop_pre", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwDropEnt_Post = CreateMultiForward("bb_drop_post", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwNewColor = CreateMultiForward("bb_new_color", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwLockEnt_Pre = CreateMultiForward("bb_lock_pre", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwLockEnt_Post = CreateMultiForward("bb_lock_post", ET_IGNORE, FP_CELL, FP_CELL)
	
	register_dictionary("basebuilder.txt");
}

public plugin_natives()
{
	register_native("bb_register_zombie_class","native_register_zombie_class", 1)
	
	register_native("bb_get_class_cost","native_get_class_cost", 1)
	register_native("bb_get_user_zombie_class","native_get_user_zombie_class", 1)
	register_native("bb_get_user_next_class","native_get_user_next_class", 1)
	register_native("bb_set_user_zombie_class","native_set_user_zombie_class", 1)
	
	
	register_native("bb_is_user_zombie","native_is_user_zombie", 1)
	register_native("bb_is_user_banned","native_is_user_banned", 1)
	
	register_native("bb_is_build_phase","native_bool_buildphase", 1)
	register_native("bb_is_prep_phase","native_bool_prepphase", 1)
	
	register_native("bb_get_build_time","native_get_build_time", 1)
	register_native("bb_set_build_time","native_set_build_time", 1)
	
	register_native("bb_get_user_color","native_get_user_color", 1)
	register_native("bb_set_user_color","native_set_user_color", 1)
	
	register_native("bb_drop_user_block","native_drop_user_block", 1)
	register_native("bb_get_user_block","native_get_user_block", 1)
	register_native("bb_set_user_block","native_set_user_block", 1)
	
	register_native("bb_is_locked_block","native_is_locked_block", 1)
	register_native("bb_lock_block","native_lock_block", 1)
	register_native("bb_unlock_block","native_unlock_block", 1)
	register_native("bb_get_flags_lockafter","native_get_flags_lockafter", 1) 
	
	register_native("bb_release_zombies","native_release_zombies", 1)
	
	register_native("bb_set_user_primary","native_set_user_primary", 1)
	register_native("bb_get_user_primary","native_get_user_primary", 1)
	
	register_native("bb_get_flags_build","native_get_flags_build", 1)
	register_native("bb_get_flags_lock","native_get_flags_lock", 1)
	register_native("bb_get_flags_buildban","native_get_flags_buildban", 1)
	register_native("bb_get_flags_swap","native_get_flags_swap", 1)
	register_native("bb_get_flags_revive","native_get_flags_revive", 1)
	register_native("bb_get_flags_guns","native_get_flags_guns", 1)
	register_native("bb_get_flags_release","native_get_flags_release", 1)
	register_native("bb_get_flags_override","native_get_flags_override", 1)
	
	//register_native("bb_set_user_mult","native_set_user_mult", 1)
	
	//ZP Natives Converted
	register_native("zp_register_zombie_class","native_register_zombie_class", 1)
	register_native("zp_get_user_zombie_class","native_get_user_zombie_class", 1)
	register_native("zp_get_user_next_class","native_get_user_next_class", 1)
	register_native("zp_set_user_zombie_class","native_set_user_zombie_class", 1)
	register_native("zp_get_user_zombie","native_is_user_zombie", 1)
}

public fw_GetGameDescription()
{
	forward_return(FMV_STRING, g_szModName)
	return FMRES_SUPERCEDE;
}
public ChooseTeam(id) {
	if (ChooseTeamOverrideActive[id])
	{
		GameMenu(id)
		return PLUGIN_HANDLED;
	}
	ChooseTeamOverrideActive[id] = true
	return PLUGIN_CONTINUE;
}
public client_putinserver(id)
{
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	g_isConnected[id] = true
	g_isAlive[id] = false
	g_isZombie[id] = false
	g_isBuildBan[id] = false
	g_isCustomModel[id] = false
	g_boolFirstSpawn[id] = true
	g_boolFirstTeam[id] = false
	g_boolFirstTime[id] = true
	g_boolRepick[id] = true
	ChooseTeamOverrideActive[id] = true
	
	g_iZombieClass[id] = 0
	g_iNextClass[id] = g_iZombieClass[id]
	//for (new i = 0; i < 3; i++) g_fClassMultiplier[id][i] = 1.0
	
	set_task(7.0,"Respawn_Player",id+TASK_RESPAWN);
	set_task(0.1, "ShowHud", id+42526, _, _, "b");
	
	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	if (g_iOwnedEnt[id])
		cmdStopEnt(id)

	g_isConnected[id] = false
	g_isAlive[id] = false
	g_isZombie[id] = false
	g_isBuildBan[id] = false
	g_isCustomModel[id] = false
	g_boolFirstSpawn[id] = false
	g_boolFirstTeam[id] = false
	g_boolFirstTime[id] = false
	g_boolRepick[id] = false
	
	g_iZombieClass[id] = 0
	g_iNextClass[id] = 0
	//for (new i = 0; i < 3; i++) g_fClassMultiplier[id][i] = 1.0
	
	g_iOwnedEntities[id] = 0
	
	remove_task(id+TASK_RESPAWN)
	remove_task(id+TASK_HEALTH)
	remove_task(id+TASK_IDLESOUND)
	
	for (new iEnt = g_iMaxPlayers+1; iEnt < MAXENTS; iEnt++)
	{
		if (is_valid_ent(iEnt) && g_iLockBlocks && BlockLocker(iEnt) == id)
		{
			UnlockBlock(iEnt)
			set_pev(iEnt,pev_rendermode,kRenderNormal)
				
			UnsetLastMover(iEnt);
			UnsetEntMover(iEnt);
		}
	}
}  

public ev_RoundStart()
{
	remove_task(TASK_BUILD)
	remove_task(TASK_PREPTIME)
	
	arrayset(g_iOwnedEntities, 0, MAXPLAYERS+1)
	arrayset(g_iColor, 0, MAXPLAYERS+1)
	arrayset(g_iColorOwner, 0, MAX_COLORS)
	arrayset(g_boolRepick, true, MAXPLAYERS+1)
	
	g_boolRoundEnded = false
	g_boolCanBuild = true
	g_fRoundStartTime = get_gametime()
	
	if (g_iResetEnt)
	{
		new szClass[10], szTarget[7];
		for (new iEnt = g_iMaxPlayers+1; iEnt < MAXENTS; iEnt++)
		{
			if (is_valid_ent(iEnt))
			{
				entity_get_string(iEnt, EV_SZ_classname, szClass, 9);
				entity_get_string(iEnt, EV_SZ_targetname, szTarget, 6);
				if (!BlockLocker(iEnt) && iEnt != g_iEntBarrier && equal(szClass, "func_wall") && !equal(szTarget, "ignore"))
				{
					set_pev(iEnt,pev_rendermode,kRenderNormal)
					engfunc( EngFunc_SetOrigin, iEnt, Float:{ 0.0, 0.0, 0.0 } );
					
					UnsetLastMover(iEnt);
					UnsetEntMover(iEnt);
				}
				else if (g_iLockBlocks && BlockLocker(iEnt))
				{
					UnlockBlock(iEnt)
					set_pev(iEnt,pev_rendermode,kRenderNormal)
					engfunc( EngFunc_SetOrigin, iEnt, Float:{ 0.0, 0.0, 0.0 } );
					
					UnsetLastMover(iEnt);
					UnsetEntMover(iEnt);
				}
			}
		}
	}
}

public ev_AmmoX(id)
	set_pdata_int(id, AMMO_SLOT + read_data(1), 200, 5)

public ShowHud(taskid)
{
	taskid -= 42526;
		
	if (is_user_alive(taskid))
	{
		new szGoal[32], Float:userSpd[33], usergrav
		userSpd[taskid] = Float:ArrayGetCell(g_zclass_spd, g_iZombieClass[taskid]);
		usergrav = floatround(Float:ArrayGetCell(g_zclass_grav, g_iZombieClass[taskid]) * 1000.0);
		get_mapname(map,63)
		//if (is_credits_active())
		#if defined BB_CREDITS
			format(szGoal, 31, "^n%L: %d", LANG_SERVER, "HUD_GOAL", credits_get_user_goal(taskid))
		#endif
		
		if (g_isZombie[taskid])
		{
			set_hudmessage(255, 255, 0, 0.01, 0.20, 0, 6.0, 0.1);
			static szCache1[32]
			ArrayGetString(g_zclass_name, g_iZombieClass[taskid], szCache1,  charsmax(szCache1))
		
			ShowSyncHudMsg(taskid, g_HudSync1, "[%L: %d]^n[%L: %s%s]^n[Points: %i]^n^n[Gravity: %d | Speed: %d]",
			LANG_SERVER, "HUD_HEALTH", pev(taskid, pev_health),
			LANG_SERVER, "HUD_CLASS", szCache1, szGoal, get_user_golds(taskid), usergrav, userSpd[taskid]);
		}
		else 
		{
			set_hudmessage(0, 255, 255, 0.01, 0.20, 0, 6.0, 0.1)
			ShowSyncHudMsg(taskid, g_HudSync1, "[%L: %d]^n[Class: Builder]^n[Points: %i]^n^n[Your Color: %s%s]^n[Claimed Objects: %d/%d]",
			LANG_SERVER, "HUD_HEALTH", pev(taskid, pev_health), get_user_golds(taskid),
			szGoal, g_szColorName[g_iColor[taskid]], g_iOwnedEntities[taskid], g_iLockMax);
			
		}
	}
}
public GameMenu(id)
{
    new menu[650], iLen = 0, szCache1[32]
    
    ArrayGetString(g_zclass_name, g_iZombieClass[id], szCache1, charsmax(szCache1))
     
    iLen = formatex(menu[iLen], charsmax(menu) - iLen, "\w|\r%L\w| \d[\yCTX\d] \wMain-Menu \w|\r%L\w|^n^n", LANG_SERVER, "KRUG", LANG_SERVER, "KRUG");
    
    iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\w1\r]. \wBuy Weapons^n");
    
    iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\w2\r]. \wExtra Items \y(Points)^n");
    
    iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\w3\r]. \rChoose Zombie Class \d[\y%s\d]^n^n", szCache1);
    
    iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\w4\r]. \wRespawn^n")
    
    iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\w5\r]. \wPlayer Menu^n^n");
    
 if(!(get_user_flags(id) & ADMIN_CVAR))
    iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\w6\r]. \dAdmin Menu^n^n");
 else
    iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\w6\r]. \rAdmin Menu^n^n");
    
    
    
    iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r[\w0\r]. \wExit")
    
    show_menu(id, keys, menu, -1, "Menu 1");
}
public GameMenu_Handler(id, key)
{  
    switch(key)
    {       
        case 0: client_cmd(id,"say /guns");
        case 1: client_cmd(id,"say /shop");
        case 2: client_cmd(id,"say /class");
        case 3: client_cmd(id,"say /respawn");
        case 4: PlayerMenu(id)
        case 5: client_cmd(id,"say /amenu");
    }
    return PLUGIN_HANDLED
}

public PlayerMenu(id)
{
    static menu[650], iLen
    iLen = 0
     
    iLen = formatex(menu[iLen], charsmax(menu) - iLen, "\rCTX \wPlayer Menu \d| \wPlayer Section \y[ALL]^n^n");
    
    if (g_boolCanBuild)
    iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r1. \wColors Menu^n");
    else
    iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r1. \dColors Menu^n");
    
    iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r2. \wCamera Menu^n^n");

    iLen += formatex(menu[iLen], charsmax(menu) - iLen, "\r0. \wExit")

    
    show_menu(id, keys, menu, -1, "Menu 2");
}
public PlayerMenu_Handler(id, key) 
{      
    switch(key)
    {       
        case 0: client_cmd(id,"say /colors")
        case 1: client_cmd(id,"say /cam")

    }
    return PLUGIN_HANDLED
}

public youtube(id)
{
	ChatColor(id, "!y[!gMexico BB!y] !ySub This Channel -->https://www.youtube.com/@aldinnn1872/featured")
}

stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)

	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!y", "^1")
	replace_all(msg, 190, "!t", "^3")

	if (id) players[0] = id; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}
public msgStatusIcon(const iMsgId, const iMsgDest, const iPlayer)
{
	if(g_isAlive[iPlayer] && g_isConnected[iPlayer]) 
	{
		static szMsg[8]
		get_msg_arg_string(2, szMsg, 7)
    
		if(equal(szMsg, "buyzone"))
		{
			set_pdata_int(iPlayer, OFFSET_BUYZONE, get_pdata_int(iPlayer, OFFSET_BUYZONE) & ~(1<<0))
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
} 

public msgHealth(msgid, dest, id)
{
	if(!g_isAlive[id])
		return PLUGIN_CONTINUE;
	
	static hp;
	hp = get_msg_arg_int(1);
	
	if(hp > 255 && (hp % 256) == 0)
		set_msg_arg_int(1, ARG_BYTE, ++hp);
	
	return PLUGIN_CONTINUE;
}

public msgRoundEnd(const MsgId, const MsgDest, const MsgEntity)
{
	static Message[192]
	get_msg_arg_string(2, Message, 191)
	
	if (equal(Message, "#Terrorists_Win"))
	{
		g_boolRoundEnded = true
		set_hudmessage(255, 255, 255, -1.0, 0.40, 0, 6.0, 6.0, 0.1, 0.2, 1)
		show_hudmessage(0, "%L", LANG_SERVER, "WIN_ZOMBIE")
		set_msg_arg_string(2, "")
		client_cmd(0, "spk %s", WIN_ZOMBIES)
		
		return PLUGIN_HANDLED
	}
	else if (equal(Message, "#Target_Saved") || equal(Message, "#CTs_Win"))
	{
		g_boolRoundEnded = true
		set_hudmessage(255, 255, 255, -1.0, 0.40, 0, 6.0, 6.0, 0.1, 0.2, 1)
		show_hudmessage(0, "%L", LANG_SERVER, "WIN_BUILDER")
		set_msg_arg_string(2, "")
		client_cmd(0, "spk %s", WIN_BUILDERS)
		
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public msgSendAudio(const MsgId, const MsgDest, const MsgEntity)
{
	static szSound[17]
	get_msg_arg_string(2,szSound,16)
	if(equal(szSound[7], "terwin") || equal(szSound[7], "ctwin") || equal(szSound[7], "rounddraw")) return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public ham_WeaponCleaner_Post(iEnt)
{
	call_think(iEnt)
}

public ham_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (!is_valid_ent(victim) || !g_isAlive[victim] || !is_user_connected(attacker))
		return HAM_IGNORED
		
	if(g_boolCanBuild || g_boolRoundEnded || g_boolPrepTime)
		return HAM_SUPERCEDE;
		
	if (victim == attacker)
		return HAM_SUPERCEDE;
		
	if (g_iSupercut)
	{
		damage*=99.0
	}
		
	SetHamParamFloat(4, damage)
	return HAM_HANDLED
}


public ham_ItemDeploy_Post(weapon_ent)
{
	static owner
	owner = get_pdata_cbase(weapon_ent, OFFSET_WPN_WIN, OFFSET_WPN_LINUX);

	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	
	if (g_isZombie[owner] && weaponid == CSW_KNIFE)
	{
		static szClawModel[100]
		ArrayGetString(g_zclass_clawmodel, g_iZombieClass[owner], szClawModel, charsmax(szClawModel))
		format(szClawModel, charsmax(szClawModel), "models/%s.mdl", szClawModel)
		entity_set_string( owner , EV_SZ_viewmodel , szClawModel )  
		entity_set_string( owner , EV_SZ_weaponmodel , "" ) 
	}
	
	if (g_isZombie[owner] && !((1<<weaponid) & ZOMBIE_ALLOWED_WEAPONS_BITSUM))
	{
		engclient_cmd(owner, "weapon_knife")
	}
	else if (g_boolCanBuild)
	{
		engclient_cmd(owner, "weapon_knife")
		client_print(owner, print_center, "%L", LANG_SERVER, "FAIL_KNIFE");
	}
}

public logevent_round_start()
{
	set_pev(g_iEntBarrier,pev_solid,SOLID_BSP)
	set_pev(g_iEntBarrier,pev_rendermode,kRenderTransColor)
	set_pev(g_iEntBarrier,pev_rendercolor, Float:{ BARRIER_COLOR })
	set_pev(g_iEntBarrier,pev_renderamt, Float:{ BARRIER_RENDERAMT })
	
	print_color(0, "^x04 ---[ Base Builder 7.0  ]---", VERSION);
	print_color(0, "^x03 %L", LANG_SERVER, "ROUND_MESSAGE");

	client_cmd(0, "spk %s", PHASE_BUILD)
	
	remove_task(TASK_BUILD)
	set_task(1.0, "task_CountDown", TASK_BUILD,_, _, "a", g_iBuildTime);
	g_iCountDown = (g_iBuildTime-1);
	
	ExecuteForward(g_fwBuildStarted, g_fwDummyResult);
}

public task_CountDown()
{
	g_iCountDown--
	new mins = g_iCountDown/60, secs = g_iCountDown%60
	if (g_iCountDown>=0){
		set_dhudmessage(0, 255, 255, -0.5, 0.15, 0, 6.0, 0.1);
		show_dhudmessage(0, "%L %L: [%d:%s%d] (%d/8)", LANG_SERVER, "THUNDERBOLT", LANG_SERVER, "BUILD_TIMER", mins, (secs < 10 ? "0" : ""), secs, g_round);
	} else {
		if (g_iPrepTime)
		{
			g_boolCanBuild = false
			g_boolPrepTime = true
			g_iCountDown = g_iPrepTime+1
			set_task(1.0, "task_PrepTime", TASK_PREPTIME,_, _, "a", g_iCountDown);
			
			set_dhudmessage(255, 255, 255, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2, 1)
			show_dhudmessage(0, "%L", LANG_SERVER, "PREP_ANNOUNCE");
			
			new players[32], num
			get_players(players, num)
			for (new i = 0; i < num; i++)
			{
				if (g_isAlive[players[i]] && !g_isZombie[players[i]])
				{
					ExecuteHamB(Ham_CS_RoundRespawn, players[i])
					
					if (g_iOwnedEnt[players[i]])
						cmdStopEnt(players[i])
				}
			}
			print_color(0, "%s^x04 %L", MODNAME, LANG_SERVER, "PREP_ANNOUNCE")
			
			client_cmd(0, "spk %s", PHASE_PREP)
			
			ExecuteForward(g_fwPrepStarted, g_fwDummyResult);
		}
		else
			Release_Zombies()

		remove_task(TASK_BUILD);
		return PLUGIN_HANDLED;
	}
	
	new szTimer[32]
	if (g_iCountDown>10)
	{
		if (mins && !secs) num_to_word(mins, szTimer, 31)
		else if (!mins && secs == 30) num_to_word(secs, szTimer, 31)
		else return PLUGIN_HANDLED;
		
		client_cmd(0, "spk ^"fvox/%s %s remaining^"", szTimer, (mins ? "minutes" : "seconds"))
	}
	else
	{
		num_to_word(g_iCountDown, szTimer, 31)
		client_cmd(0, "spk ^"fvox/%s^"", szTimer)
	}
	return PLUGIN_CONTINUE;
}

public task_PrepTime()
{
	g_iCountDown--
	
	if (g_iCountDown>=0){
		set_dhudmessage(0, 255, 255, -0.5, 0.15, 0, 6.0, 0.1);
		show_dhudmessage(0, "%L %L: [0:%s%d] (%d/8)", LANG_SERVER, "THUNDERBOLT", LANG_SERVER, "PREP_TIMER", (g_iCountDown < 10 ? "0" : ""), g_iCountDown, g_round);
	}
	if (0<g_iCountDown<11)
	{
		new szTimer[32]
		num_to_word(g_iCountDown, szTimer, 31)
		client_cmd(0, "spk ^"fvox/%s^"", szTimer)
	}
	else if (g_iCountDown == 0)
	{
		Release_Zombies()
		remove_task(TASK_PREPTIME);
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE;
}

public logevent_round_end()
{
	if (g_boolRoundEnded)
	{
		new players[32], num, player
		get_players(players, num)
		for (new i = 0; i < num; i++)
		{
			player = players[i]
			
			if (g_iCurTeam[player] == g_iTeam[player] )
				cs_set_user_team(player, (g_iTeam[player] = (g_iTeam[player] == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T)))
			else
				g_iTeam[player] = g_iTeam[player] == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T
		}
		print_color(0, "%s^x04 %L", MODNAME, LANG_SERVER, "SWAP_ANNOUNCE")
	}
	remove_task(TASK_BUILD)	
	return PLUGIN_HANDLED
}

public client_death(g_attacker, g_victim, wpnindex, hitplace, TK)
{
	if (is_user_alive(g_victim))
		return PLUGIN_HANDLED;
	
	remove_task(g_victim+TASK_IDLESOUND)
	
	g_isAlive[g_victim] = false;
	
	if (TK == 0 && g_attacker != g_victim && g_isZombie[g_attacker])
	{
		client_cmd(0, "spk %s", INFECTION)
		new szPlayerName[32]
		get_user_name(g_victim, szPlayerName, 31)
		set_hudmessage(255, 255, 255, -1.0, 0.45, 0, 1.0, 5.0, 0.1, 0.2, 1)
		show_hudmessage(0, "%L", LANG_SERVER, "INFECT_ANNOUNCE", szPlayerName);
	}
	
	set_hudmessage(255, 255, 255, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2, 1)
	if (g_isZombie[g_victim])
	{
		show_hudmessage(g_victim, "%L", LANG_SERVER, "DEATH_ZOMBIE", g_iZombieTime);
		set_task(float(g_iZombieTime), "Respawn_Player", g_victim+TASK_RESPAWN)
	}
	else if (g_iInfectTime)
	{
		show_hudmessage(g_victim, "%L", LANG_SERVER, "DEATH_HUMAN", g_iInfectTime);
		cs_set_user_team(g_victim, CS_TEAM_T)
		g_isZombie[g_victim] = true
		set_task(float(g_iInfectTime), "Respawn_Player", g_victim+TASK_RESPAWN)
	}
	
	return PLUGIN_CONTINUE;
}

public Respawn_Player(id)
{
	id-=TASK_RESPAWN
	
	if (!is_user_connected(id))
		return PLUGIN_HANDLED
	
	if (((g_boolCanBuild || g_boolPrepTime) && cs_get_user_team(id) == CS_TEAM_CT) || cs_get_user_team(id) == CS_TEAM_T)
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id)
		
		//Loop the task until they have successfully spawned
		if (!g_isAlive[id])
			set_task(3.0,"Respawn_Human",id+TASK_RESPAWN)
	}
	return PLUGIN_HANDLED
}

public ham_PlayerSpawn_Post(id)
{
	if (is_user_alive(id))
	{
		g_isAlive[id] = true;
		
		g_isZombie[id] = (cs_get_user_team(id) == CS_TEAM_T ? true : false)
		
		remove_task(id + TASK_RESPAWN)
		remove_task(id + TASK_MODELSET)
		remove_task(id + TASK_IDLESOUND)
		if (g_isZombie[id])
		{
			if (g_boolFirstSpawn[id])
			{
				print_color(id, "This server is running Base Builder v%s by Tirant", VERSION);
				show_zclass_menu(id, 0)
				g_boolFirstSpawn[id] = false
			}
			
			if (g_iNextClass[id] != g_iZombieClass[id])
				g_iZombieClass[id] = g_iNextClass[id]

			set_pev(id, pev_health, float(ArrayGetCell(g_zclass_hp, g_iZombieClass[id]))/**g_fClassMultiplier[id][ATT_HEALTH]*/)
			set_pev(id, pev_gravity, Float:ArrayGetCell(g_zclass_grav, g_iZombieClass[id])/**g_fClassMultiplier[id][ATT_GRAVITY]*/)
			g_fPlayerSpeed[id] = float(ArrayGetCell(g_zclass_spd, g_iZombieClass[id]))/**g_fClassMultiplier[id][ATT_SPEED]*/
				
			//Handles the knife and claw model
			strip_user_weapons(id)
			give_item(id, "weapon_knife")
							
			static szClawModel[100]
			ArrayGetString(g_zclass_clawmodel, g_iZombieClass[id], szClawModel, charsmax(szClawModel))
			format(szClawModel, charsmax(szClawModel), "models/%s.mdl", szClawModel)
			entity_set_string( id , EV_SZ_viewmodel , szClawModel )  
			entity_set_string( id , EV_SZ_weaponmodel , "" ) 
						
			ArrayGetString(g_zclass_name, g_iZombieClass[id], g_szPlayerClass[id], charsmax(g_szPlayerClass[]))
			
			set_task(random_float(60.0, 360.0), "task_ZombieIdle", id+TASK_IDLESOUND, _, _, "b")

			ArrayGetString(g_zclass_playermodel, g_iZombieClass[id], g_szPlayerModel[id], charsmax(g_szPlayerModel[]))
			new szCurrentModel[32]
			fm_get_user_model(id, szCurrentModel, charsmax(szCurrentModel))
			if (!equal(szCurrentModel, g_szPlayerModel[id]))
			{
				if (get_gametime() - g_fRoundStartTime < 5.0)
					set_task(5.0 * MODELCHANGE_DELAY, "fm_user_model_update", id + TASK_MODELSET)
				else
					fm_user_model_update(id + TASK_MODELSET)
			}
			
			ExecuteForward(g_fwClassSet, g_fwDummyResult, id, g_iZombieClass[id]);
		}
		else if (g_isCustomModel[id])
		{
			fm_reset_user_model(id)
		}
		
		if (!g_isZombie[id])
		{
			entity_set_string( id , EV_SZ_viewmodel , "models/v_knife.mdl" )  
			
			if (((/*g_boolPrepTime && */g_iPrepTime && !g_boolCanBuild) || (g_boolCanBuild && !g_iPrepTime)) && g_iGunsMenu)
			{
				//if (is_credits_active())
				#if defined BB_CREDITS
					credits_show_gunsmenu(id)
				#else
					show_method_menu(id)
				#endif
			}
				
			if (!g_iColor[id])
			{
				new i = random(MAX_COLORS)
				if (g_iColorMode)
				{
					while (g_iColorOwner[i])
					{
						i = random(MAX_COLORS)
					}
				}
				print_color(id, "%s^x04 %L:^x01 %s", MODNAME, LANG_SERVER, "COLOR_PICKED", g_szColorName[i]);
				g_iColor[id] = i
				g_iColorOwner[i] = id

				if (g_iOwnedEnt[id])
				{
					set_pev(g_iOwnedEnt[id],pev_rendercolor, g_fColor[g_iColor[id]] )
					set_pev(g_iOwnedEnt[id],pev_renderamt, g_fRenderAmt[g_iColor[id]] )
				}
			}
		}
	}
}

public task_ZombieIdle(taskid)
{
	taskid-=TASK_IDLESOUND
	if (g_isAlive[taskid] && g_isConnected[taskid] && !g_isZombie[taskid])
		emit_sound(taskid, CHAN_VOICE, g_szZombieIdle[random(sizeof g_szZombieIdle - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public fw_SetClientKeyValue(id, const infobuffer[], const key[])
{   
	if (g_isCustomModel[id] && equal(key, "model"))
		return FMRES_SUPERCEDE
	return FMRES_IGNORED
}

public fw_ClientUserInfoChanged(id)
{
	if (!g_isCustomModel[id])
		return FMRES_IGNORED
	static szCurrentModel[32]
	fm_get_user_model(id, szCurrentModel, charsmax(szCurrentModel))
	if (!equal(szCurrentModel, g_szPlayerModel[id]) && !task_exists(id + TASK_MODELSET))
		fm_set_user_model(id + TASK_MODELSET)
	return FMRES_IGNORED
}

public fm_user_model_update(taskid)
{
	static Float:fCurTime
	fCurTime = get_gametime()
	
	if (fCurTime - g_fModelsTargetTime >= MODELCHANGE_DELAY)
	{
		fm_set_user_model(taskid)
		g_fModelsTargetTime = fCurTime
	}
	else
	{
		set_task((g_fModelsTargetTime + MODELCHANGE_DELAY) - fCurTime, "fm_set_user_model", taskid)
		g_fModelsTargetTime += MODELCHANGE_DELAY
	}
}

public fm_set_user_model(player)
{
	player -= TASK_MODELSET
	engfunc(EngFunc_SetClientKeyValue, player, engfunc(EngFunc_GetInfoKeyBuffer, player), "model", g_szPlayerModel[player])
	g_isCustomModel[player] = true
}

stock fm_get_user_model(player, model[], len)
{
	engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, player), "model", model, len)
}

stock fm_reset_user_model(player)
{
	g_isCustomModel[player] = false
	dllfunc(DLLFunc_ClientUserInfoChanged, player, engfunc(EngFunc_GetInfoKeyBuffer, player))
}

public message_show_menu(msgid, dest, id) 
{
	if (!(!get_user_team(id) && !is_user_bot(id) && !access(id, ADMIN_IMMUNITY)))
		return PLUGIN_CONTINUE

	static team_select[] = "#Team_Select"
	static menu_text_code[sizeof team_select]
	get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1)
	if (!equal(menu_text_code, team_select))
		return PLUGIN_CONTINUE

	static param_menu_msgid[2]
	param_menu_msgid[0] = msgid
	set_task(AUTO_TEAM_JOIN_DELAY, "task_force_team_join", id, param_menu_msgid, sizeof param_menu_msgid)

	return PLUGIN_HANDLED
}

public message_vgui_menu(msgid, dest, id) 
{
	if (get_msg_arg_int(1) != TEAM_SELECT_VGUI_MENU_ID || !(!get_user_team(id) && !is_user_bot(id) && !access(id, ADMIN_IMMUNITY)))// 
		return PLUGIN_CONTINUE
		
	static param_menu_msgid[2]
	param_menu_msgid[0] = msgid
	set_task(AUTO_TEAM_JOIN_DELAY, "task_force_team_join", id, param_menu_msgid, sizeof param_menu_msgid)

	return PLUGIN_HANDLED
}

public task_force_team_join(menu_msgid[], id) 
{
	if (get_user_team(id))
		return

	static msg_block
	msg_block = get_msg_block(menu_msgid[0])
	set_msg_block(menu_msgid[0], BLOCK_SET)
	engclient_cmd(id, "jointeam", "5")
	engclient_cmd(id, "joinclass", "5")
	set_msg_block(menu_msgid[0], msg_block)
}

public msgTeamInfo(msgid, dest)
{
	if (dest != MSG_ALL && dest != MSG_BROADCAST)
		return;
	
	static id, team[2]
	id = get_msg_arg_int(1)

	get_msg_arg_string(2, team, charsmax(team))
	switch (team[0])
	{
		case 'T' : // TERRORIST
		{
			g_iCurTeam[id] = CS_TEAM_T;
		}
		case 'C' : // CT
		{
			g_iCurTeam[id] = CS_TEAM_CT;
		}
		case 'S' : // SPECTATOR
		{
			g_iCurTeam[id] = CS_TEAM_SPECTATOR;
		}
		default : g_iCurTeam[id] = CS_TEAM_UNASSIGNED;
	}
	if (!g_boolFirstTeam[id])
	{
		g_boolFirstTeam[id] = true
		g_iTeam[id] = g_iCurTeam[id]
	}
}

public clcmd_drop(id)
{
	client_print (id, print_center, "%L", LANG_SERVER, "FAIL_DROP")
	return PLUGIN_HANDLED
}

public clcmd_buy(id)
{
	client_print (id, print_center, "%L", LANG_SERVER, "FAIL_BUY")
	return PLUGIN_HANDLED
}

public msgStatusValue()
	set_msg_block(g_msgStatusText, BLOCK_SET);

public ev_SetTeam(id)
	g_iFriend[id] = read_data(2)

public ev_ShowStatus(id) //called when id looks at someone
{
	new szName[32], pid = read_data(2);
	get_user_name(pid, szName, 31);

	if (g_iFriend[id] == 1)	// friend
	{
		new clip, ammo, wpnid = get_user_weapon(pid, clip, ammo), szWpnName[32];

		if (wpnid)
			xmod_get_wpnname(wpnid, szWpnName, 31);

		set_hudmessage(0, 225, 0, -1.0, HUD_FRIEND_HEIGHT, 1, 0.01, 3.0, 0.01, 0.01);
		new nLen, szStatus[512]
		if (!g_isZombie[pid])
			nLen += format( szStatus[nLen], 511-nLen, "[Name: %s]^n[Health: %d]^n[Color: %s]^n[Points: %i]", szName, pev(pid, pev_health), g_szColorName[g_iColor[pid]], get_user_golds(pid));
		else
		{
			nLen += format( szStatus[nLen], 511-nLen, "[Name: %s]^n[Class: %s]^n[Health: %d]", szName, g_szPlayerClass[pid], pev(pid, pev_health));
			
			/*if (is_credits_active())
			{
				nLen += format( szStatus[nLen], 511-nLen, "^n^nClass Multipliers:", szName, g_szPlayerClass[pid], pev(pid, pev_health));
				nLen += format( szStatus[nLen], 511-nLen, "^nHealth: %f", g_fClassMultiplier[pid][ATT_HEALTH]);
				nLen += format( szStatus[nLen], 511-nLen, "^nSpeed: %f", g_fClassMultiplier[pid][ATT_SPEED]);
				nLen += format( szStatus[nLen], 511-nLen, "^nGravity: %f", g_fClassMultiplier[pid][ATT_GRAVITY]);
			}*/
		}
		ShowSyncHudMsg(id, g_HudSync, szStatus);
	} 
	if (g_iFriend[id] != 1) //enemy
	{
		set_hudmessage(225, 0, 0, -1.0, HUD_FRIEND_HEIGHT, 1, 0.01, 3.0, 0.01, 0.01);
		if (g_isZombie[pid])
			ShowSyncHudMsg(id, g_HudSync, "[Name: %s]^n[Class: %s]", szName, g_szPlayerClass[pid]);
		else
			ShowSyncHudMsg(id, g_HudSync, "[Name: %s]^n[Color: %s]", szName, g_szColorName[g_iColor[pid]]);
	}
}

public ev_HideStatus(id)
	ClearSyncHud(id, g_HudSync);

public cmdSay(id)
{
	if (!g_isConnected[id])
		return PLUGIN_HANDLED;

	new szMessage[32]
	read_args(szMessage, charsmax(szMessage));
	remove_quotes(szMessage);
		
	if(szMessage[0] == '/')
	{
		if (equali(szMessage, "/commands") == 1 || equali(szMessage, "/cmd")  == 1 )
		{
			print_color(id, "%s /class, /respawn, /random, /mycolor, /guns%s%s%s", MODNAME, (g_iColorMode ? ", /whois <color>": ""), (g_iColorMode != 2 ? ", /colors":""), (access(id, FLAGS_LOCK) ? ", /lock":"")  );
		}
		else if (equali(szMessage, "/class") == 1)
		{
			show_zclass_menu(id, 0)
		}
		else if (equali(szMessage, "/respawn") == 1 || equali(szMessage, "/revive")  == 1 || equali(szMessage, "/fixspawn")  == 1)
		{
			if (g_boolCanBuild && !g_isZombie[id])
				ExecuteHamB(Ham_CS_RoundRespawn, id)
			else if (g_isZombie[id])
			{
				if (pev(id, pev_health) == float(ArrayGetCell(g_zclass_hp, g_iZombieClass[id])) || !is_user_alive(id))
					ExecuteHamB(Ham_CS_RoundRespawn, id)
				else
					client_print(id, print_center, "%L", LANG_SERVER, "FAIL_SPAWN");
			}
		}
		else if (equali(szMessage, "/lock") == 1 || equali(szMessage, "/claim") == 1 && g_isAlive[id])
		{
			if (access(id, FLAGS_LOCK))
				cmdLockBlock(id)
			else
				client_print(id, print_center, "%L", LANG_SERVER, "FAIL_ACCESS");
			return PLUGIN_HANDLED;
		}
		else if (equal(szMessage, "/whois",6) && g_iColorMode)
		{
			for ( new i=0; i<MAX_COLORS; i++)
			{
				if (equali(szMessage[7], g_szColorName[i]) == 1)
				{
					if (g_iColorOwner[i])
					{
						new szPlayerName[32]
						get_user_name(g_iColorOwner[i], szPlayerName, 31)
						print_color(id, "%s^x04 %s^x01's color is^x04 %s", MODNAME, szPlayerName, g_szColorName[i]);
					}
					else
						print_color(id, "%s %L^x04 %s", MODNAME, LANG_SERVER, "COLOR_NONE", g_szColorName[i]);
						
					break;
				}
			}
		}
		else if (equali(szMessage, "/colors") == 1 && !g_isZombie[id] && g_boolCanBuild && g_iColorMode != 2)
		{
			show_colors_menu(id, 0)
		}
		else if (equali(szMessage, "/mycolor") == 1 && !g_isZombie[id])
		{
			print_color(id, "%s^x04 %L:^x01 %s", MODNAME, LANG_SERVER, "COLOR_YOURS", g_szColorName[g_iColor[id]]);
			return PLUGIN_HANDLED
		}
		else if (equali(szMessage, "/random") == 1 && !g_isZombie[id] && g_boolCanBuild)
		{
			new i = random(MAX_COLORS)
			if (g_iColorMode)
			{
				while (g_iColorOwner[i])
				{
					i = random(MAX_COLORS)
				}
			}
			print_color(id, "%s^x04 %L:^x01 %s", MODNAME, LANG_SERVER, "COLOR_RANDOM", g_szColorName[i]);
			g_iColorOwner[g_iColor[id]] = 0
			g_iColor[id] = i
			g_iColorOwner[i] = id
			
			for (new iEnt = g_iMaxPlayers+1; iEnt < MAXENTS; iEnt++)
			{
				if (is_valid_ent(iEnt) && g_iLockBlocks && BlockLocker(iEnt) == id)
					set_pev(iEnt,pev_rendercolor,g_fColor[g_iColor[id]])
			}
			
			ExecuteForward(g_fwNewColor, g_fwDummyResult, id, g_iColor[id]);
		}
		else if (equali(szMessage, "/guns", 5) && g_iGunsMenu)
		{
			if(!g_isAlive[id])
				return PLUGIN_HANDLED
				
			if (access(id, FLAGS_GUNS))
			{
				new player = cmd_target(id, szMessage[6], 0)
			
				if (!player)
				{
					//if (is_credits_active())
					#if defined BB_CREDITS
						credits_show_gunsmenu(id)
					#else
						show_method_menu(id)
					#endif
					return PLUGIN_CONTINUE
				}
				
				cmdGuns(id, player)
				return PLUGIN_HANDLED;
			}
			else
			{
				if(!g_boolCanBuild || !g_boolRepick[id])
					return PLUGIN_HANDLED	
		
				//if (is_credits_active())
				#if defined BB_CREDITS
					credits_show_gunsmenu(id)
				#else
					show_method_menu(id)
				#endif
				return PLUGIN_HANDLED
			}
		}
		else if (equal(szMessage, "/swap",5) && access(id, FLAGS_SWAP))
		{
			new player = cmd_target(id, szMessage[6], 0)
		
			if (!player)
			{
				print_color(id, "%s Player^x04 %s^x01 could not be found or targetted", MODNAME, szMessage[6])
				return PLUGIN_CONTINUE
			}
			
			cmdSwap(id, player)
		}
		else if (equal(szMessage, "/revive",7) && access(id, FLAGS_REVIVE))
		{
			new player = cmd_target(id, szMessage[8], 0)
		
			if (!player)
			{
				print_color(id, "%s Player^x04 %s^x01 could not be found or targetted", MODNAME, szMessage[6])
				return PLUGIN_CONTINUE
			}
			
			cmdRevive(id, player)
		}
		else if (equal(szMessage, "/ban",4) && access(id, FLAGS_BUILDBAN))
		{
			new player = cmd_target(id, szMessage[5], 0)
		
			if (!player)
			{
				print_color(id, "%s Player^x04 %s^x01 could not be found or targetted", MODNAME, szMessage[6])
				return PLUGIN_CONTINUE
			}
			
			cmdBuildBan(id, player)
		}
		else if (equal(szMessage, "/releasezombies",5) && access(id, FLAGS_RELEASE))
		{
			cmdStartRound(id)
		}
	}
	return PLUGIN_CONTINUE
}

public cmdSwap(id, target)
{
	if (access(id, FLAGS_SWAP))
	{
		new player
		
		if (target) player = target
		else
		{
			new arg[32]
			read_argv(1, arg, 31)
			player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF)
		}

		if (!player || !is_user_connected(player))
			return client_print(id, print_console, "[Base Builder] %L", LANG_SERVER, "FAIL_NAME");
			
		cs_set_user_team(player,( g_iTeam[player] = g_iTeam[player] == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T))
			
		if (is_user_alive(player))
			ExecuteHamB(Ham_CS_RoundRespawn, player)
		
		new szAdminAuthid[32],szAdminName[32],szPlayerName[32],szPlayerID[32]
		get_user_name(id,szAdminName,31)
		get_user_authid (id,szAdminAuthid,31)
		get_user_name(player, szPlayerName, 31)
		get_user_authid (player,szPlayerID,31)
		
		client_print(id, print_console, "[Base Builder] Player %s was swapped from the %s team to the %s team by %s", szPlayerName, g_iTeam[player] == CS_TEAM_CT ? "zombie":"builder", g_iTeam[player] == CS_TEAM_CT ? "builder":"zombie", szAdminName)
		Log("[SWAP] Admin: %s || SteamID: %s swapped Player: %s || SteamID: %s", szAdminName, szAdminAuthid, szPlayerName, szPlayerID)
		
		set_hudmessage(255,0, 0, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2, 1)
		show_hudmessage(player, "%L", LANG_SERVER, "ADMIN_SWAP");
		
		print_color(0, "%s Player^x04 %s^x01 has been^x04 swapped^x01 to the^x04 %s^x01 team by ^x04%s", MODNAME, szPlayerName, g_iTeam[player] == CS_TEAM_CT ? "builder":"zombie", szAdminName)
	}
	return PLUGIN_HANDLED	
}

public cmdRevive(id, target)
{
	if (access(id, FLAGS_REVIVE))
	{
		new player
		if (target) player = target
		else
		{
			new arg[32]
			read_argv(1, arg, 31)
			player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF)
		}

		if (!player || !is_user_connected(player))
			return client_print(id, print_console, "[Base Builder] %L", LANG_SERVER, "FAIL_NAME");
			
		ExecuteHamB(Ham_CS_RoundRespawn, player)
		
		new szAdminAuthid[32],szAdminName[32],szPlayerName[32],szPlayerID[32]
		get_user_name(id,szAdminName,31)
		get_user_authid (id,szAdminAuthid,31)
		get_user_name(player, szPlayerName, 31)
		get_user_authid (player,szPlayerID,31)
		
		client_print(id, print_console, "[Base Builder] Player %s has been^x04 revived by %s", szPlayerName, szAdminName)
		Log("[REVIVE] Admin: %s || SteamID: %s revived Player: %s || SteamID: %s", szAdminName, szAdminAuthid, szPlayerName, szPlayerID)
		
		set_hudmessage(255,0, 0, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2, 1)
		show_hudmessage(player, "%L", LANG_SERVER, "ADMIN_REVIVE");
		
		print_color(0, "%s Player^x04 %s^x01 has been^x04 revived^x01 by an admin by ^x04%s", MODNAME, szPlayerName, szAdminName)
	}
	return PLUGIN_HANDLED	
}
public cmdGuns(id, target)
{
	if (access(id, FLAGS_GUNS))
	{
		new player
		if (target) player = target
		else
		{
			new arg[32]
			read_argv(1, arg, 31)
			player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF)
		}
		
		if (!player || !is_user_connected(player))
		{
			client_print(id, print_console, "[Base Builder] %L", LANG_SERVER, "FAIL_NAME");
			return PLUGIN_HANDLED;
		}
		
		if (g_isZombie[player])
		{
			return PLUGIN_HANDLED;
		}
		
		if (!g_isAlive[player])
		{
			client_print(id, print_console, "[Base Builder] %L", LANG_SERVER, "FAIL_DEAD");
			return PLUGIN_HANDLED;
		}

		//if (is_credits_active())
		#if defined BB_CREDITS
			credits_show_gunsmenu(player)
		#else
			show_method_menu(player)
		#endif
		
		new szAdminAuthid[32],szAdminName[32],szPlayerName[32],szPlayerID[32]
		get_user_name(id,szAdminName,31)
		get_user_authid (id,szAdminAuthid,31)
		get_user_name(player, szPlayerName, 31)
		get_user_authid (player,szPlayerID,31)
		
		client_print(id, print_console, "[Base Builder] Player %s has had his weapons menu re-opened", szPlayerName);
		Log("[GUNS] Admin: %s || SteamID: %s opened the guns menu for Player: %s || SteamID: %s", szAdminName, szAdminAuthid, szPlayerName, szPlayerID);
		
		set_hudmessage(255,0, 0, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2, 1)
		show_hudmessage(player, "%L", LANG_SERVER, "ADMIN_GUNS");
		
		print_color(0, "%s Player^x04 %s^x01 has had their^x04 guns^x01 menu^x04 re-opened", MODNAME, szPlayerName)
	}
	return PLUGIN_HANDLED	
}

public cmdStartRound(id)
{
	if (access(id, FLAGS_RELEASE))
	{
		native_release_zombies()
	}
}

public Release_Zombies()
{
	g_boolCanBuild = false
	remove_task(TASK_BUILD);
	
	g_boolPrepTime = false
	remove_task(TASK_PREPTIME);
	
	new players[32], num, player, szWeapon[32]
	get_players(players, num, "a")
	for(new i = 0; i < num; i++)
	{
		player = players[i]

		if (!g_isZombie[player])
		{
			if (g_iOwnedEnt[player])
				cmdStopEnt(player)

			if(g_iGrenadeHE		) give_item(player,"weapon_hegrenade"	), cs_set_user_bpammo(player,CSW_HEGRENADE,	g_iGrenadeHE)
			if(g_iGrenadeFLASH	) give_item(player,"weapon_flashbang"	), cs_set_user_bpammo(player,CSW_FLASHBANG,	g_iGrenadeFLASH)
			if(g_iGrenadeSMOKE	) give_item(player,"weapon_smokegrenade"	), cs_set_user_bpammo(player,CSW_SMOKEGRENADE,	g_iGrenadeSMOKE)

			if (g_iPrimaryWeapon[player])
			{
				get_weaponname(g_iPrimaryWeapon[player],szWeapon,sizeof szWeapon - 1)
				engclient_cmd(player, szWeapon);
			}
		}
	}
			
	set_pev(g_iEntBarrier,pev_solid,SOLID_NOT)
	set_pev(g_iEntBarrier,pev_renderamt,Float:{ 0.0 })
	
	set_hudmessage(255, 255, 255, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2, 1)
	show_hudmessage(0, "%L", LANG_SERVER, "RELEASE_ANNOUNCE");
	client_cmd(0, "spk %s", g_szRoundStart[ random( sizeof g_szRoundStart ) ] )
	
	ExecuteForward(g_fwRoundStart, g_fwDummyResult);
}

public fw_CmdStart( id, uc_handle, randseed )
{
	if (!g_isConnected[id] || !g_isAlive[id])
		return FMRES_IGNORED

	//new button = pev(id, pev_button)
	new button = get_uc( uc_handle , UC_Buttons );
	new oldbutton = pev(id, pev_oldbuttons)

	if( button & IN_USE && !(oldbutton & IN_USE) && !g_iOwnedEnt[id])
		cmdGrabEnt(id)
	else if( oldbutton & IN_USE && !(button & IN_USE) && g_iOwnedEnt[id])
		cmdStopEnt(id)

	return FMRES_IGNORED;
}

public cmdGrabEnt(id)
{
	if (g_fBuildDelay[id] + BUILD_DELAY > get_gametime())
	{
		g_fBuildDelay[id] = get_gametime()
		client_print (id, print_center, "%L", LANG_SERVER, "BUILD_SPAM")
		return PLUGIN_HANDLED
	}
	else
		g_fBuildDelay[id] = get_gametime()

	if (g_isBuildBan[id])
	{
		client_print (id, print_center, "%L", LANG_SERVER, "BUILD_BANNED")
		client_cmd(id, "spk %s", LOCK_FAIL);
		return PLUGIN_HANDLED;
	}
	
	if (g_isZombie[id] && !access(id, FLAGS_OVERRIDE))
		return PLUGIN_HANDLED
		
	if (!g_boolCanBuild && !access(id, FLAGS_BUILD) && !access(id, FLAGS_OVERRIDE))
	{
		ColorChat(0, GREEN, "%L", LANG_SERVER, "BUILD_NOTIME")
		return PLUGIN_HANDLED
	}
	
	if (g_iOwnedEnt[id] && is_valid_ent(g_iOwnedEnt[id])) 
		cmdStopEnt(id)
	
	new ent, bodypart
	get_user_aiming (id,ent,bodypart)
	
	if (!is_valid_ent(ent) || ent == g_iEntBarrier || is_user_alive(ent) || IsMovingEnt(ent))
		return PLUGIN_HANDLED;
	
	if ((BlockLocker(ent) && BlockLocker(ent) != id) || (BlockLocker(ent) && !access(id, FLAGS_OVERRIDE)))
		return PLUGIN_HANDLED;
	
	new szClass[10], szTarget[7];
	entity_get_string(ent, EV_SZ_classname, szClass, 9);
	entity_get_string(ent, EV_SZ_targetname, szTarget, 6);
	if (!equal(szClass, "func_wall") || equal(szTarget, "ignore"))
		return PLUGIN_HANDLED;
		
	ExecuteForward(g_fwGrabEnt_Pre, g_fwDummyResult, id, ent);

	new Float:fOrigin[3], iAiming[3], Float:fAiming[3]
	
	get_user_origin(id, iAiming, 3);
	IVecFVec(iAiming, fAiming);
	entity_get_vector(ent, EV_VEC_origin, fOrigin);

	g_fOffset1[id] = fOrigin[0] - fAiming[0];
	g_fOffset2[id] = fOrigin[1] - fAiming[1];
	g_fOffset3[id] = fOrigin[2] - fAiming[2];
	
	g_fEntDist[id] = get_user_aiming(id, ent, bodypart);
		
	if (g_fEntMinDist)
	{
		if (g_fEntDist[id] < g_fEntMinDist)
			g_fEntDist[id] = g_fEntSetDist;
	}
	else if (g_fEntMaxDist)
	{
		if (g_fEntDist[id] > g_fEntMaxDist)
			return PLUGIN_HANDLED
	}

	set_pev(ent,pev_rendermode,kRenderTransColor)
	set_pev(ent,pev_rendercolor, g_fColor[g_iColor[id]] )
	set_pev(ent,pev_renderamt, g_fRenderAmt[g_iColor[id]] )
		
	MovingEnt(ent);
	SetEntMover(ent, id);
	g_iOwnedEnt[id] = ent

	//Checked after object is successfully grabbed
	if (!g_boolCanBuild && (access(id, FLAGS_BUILD) || access(id, FLAGS_OVERRIDE)))
	{
		new adminauthid[32],adminname[32]
		get_user_authid (id,adminauthid,31)
		get_user_name(id,adminname,31)
		Log("[MOVE] Admin: %s || SteamID: %s moved an entity", adminname, adminauthid)
	}
	
	client_cmd(id, "spk %s", GRAB_START);
	
	ExecuteForward(g_fwGrabEnt_Post, g_fwDummyResult, id, ent);
	
	return PLUGIN_HANDLED
}

public cmdStopEnt(id)
{
	if (!g_iOwnedEnt[id])
		return PLUGIN_HANDLED;
		
	new ent = g_iOwnedEnt[id]
	
	ExecuteForward(g_fwDropEnt_Pre, g_fwDummyResult, id, ent);
	
	if (BlockLocker(ent))
	{
		switch(g_iLockBlocks)
		{
			case 0:
			{
				set_pev(ent,pev_rendermode,kRenderTransColor)
				set_pev(ent,pev_rendercolor, Float:{ LOCKED_COLOR })
				set_pev(ent,pev_renderamt,Float:{ LOCKED_RENDERAMT })
			}
			case 1:
			{
				set_pev(ent,pev_rendermode,kRenderTransColor)
				set_pev(ent,pev_rendercolor, g_fColor[g_iColor[id]])
				set_pev(ent,pev_renderamt,Float:{ LOCKED_RENDERAMT })
			}
		}
	}
	else
		set_pev(ent,pev_rendermode,kRenderNormal)	
	
	UnsetEntMover(ent);
	SetLastMover(ent,id);
	g_iOwnedEnt[id] = 0;
	UnmovingEnt(ent);
	
	client_cmd(id, "spk %s", GRAB_STOP);
	
	ExecuteForward(g_fwDropEnt_Post, g_fwDummyResult, id, ent);
	
	return PLUGIN_HANDLED;
}

public cmdLockBlock(id)
{
	if (!g_boolCanBuild && g_iLockBlocks && !access(id, FLAGS_LOCKAFTER))
    {
        client_print(id, print_center, "%L", LANG_SERVER, "FAIL_LOCK");
        return PLUGIN_HANDLED;
    } 
	
	if (!access(id, FLAGS_LOCK) || (g_isZombie[id] && !access(id, FLAGS_OVERRIDE)))
		return PLUGIN_HANDLED;
		
	new ent, bodypart
	get_user_aiming (id,ent,bodypart)
	
	new szTarget[7], szClass[10];
	entity_get_string(ent, EV_SZ_targetname, szTarget, 6);
	entity_get_string(ent, EV_SZ_classname, szClass, 9);
	if (!ent || !is_valid_ent(ent) || is_user_alive(ent) || ent == g_iEntBarrier || !equal(szClass, "func_wall") || equal(szTarget, "ignore"))
		return PLUGIN_HANDLED;
	
	ExecuteForward(g_fwLockEnt_Pre, g_fwDummyResult, id, ent);
	
	switch (g_iLockBlocks)
	{
		case 0:
		{
			if (!BlockLocker(ent) && !IsMovingEnt(ent))
			{
				LockBlock(ent, id);
				set_pev(ent,pev_rendermode,kRenderTransColor)
				set_pev(ent,pev_rendercolor,Float:{LOCKED_COLOR})
				set_pev(ent,pev_renderamt,Float:{LOCKED_RENDERAMT})
				client_cmd(id, "spk %s", LOCK_OBJECT);
			}
			else if (BlockLocker(ent))
			{
				UnlockBlock(ent)
				set_pev(ent,pev_rendermode,kRenderNormal)
				client_cmd(id, "spk %s", LOCK_OBJECT);
			}
		}
		case 1:
		{
			if (!BlockLocker(ent) && !IsMovingEnt(ent))
			{
				if (g_iOwnedEntities[id]<g_iLockMax || !g_iLockMax)
				{
					LockBlock(ent, id)
					g_iOwnedEntities[id]++
					set_pev(ent,pev_rendermode,kRenderTransColor)
					set_pev(ent,pev_rendercolor,g_fColor[g_iColor[id]])
					set_pev(ent,pev_renderamt,Float:{LOCKED_RENDERAMT})
					
					client_cmd(id, "spk %s", LOCK_OBJECT);
				}
				else if (g_iOwnedEntities[id]>=g_iLockMax)
				{
					client_cmd(id, "spk %s", LOCK_FAIL);
				}
			}
			else if (BlockLocker(ent))
			{
				if (BlockLocker(ent) == id || access(id, FLAGS_OVERRIDE))
				{
					g_iOwnedEntities[BlockLocker(ent)]--
					set_pev(ent,pev_rendermode,kRenderNormal)
					
					
					UnlockBlock(ent)
					client_cmd(id, "spk %s", LOCK_OBJECT);
				}
				else
				{
					client_cmd(id, "spk %s", LOCK_FAIL);
				}
			}	
		}
	}
	
	ExecuteForward(g_fwLockEnt_Post, g_fwDummyResult, id, ent);
	
	return PLUGIN_HANDLED
}

public cmdBuildBan(id, target)
{
	if (access(id, FLAGS_BUILDBAN))
	{
		new player
		if (target) player = target
		else
		{
			new arg[32]
			read_argv(1, arg, 31)
			player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY)
		}
		
		if (!player)
			return client_print(id, print_console, "[Base Builder] %L", LANG_SERVER, "FAIL_NAME");
		
		new szAdminAuthid[32],szAdminName[32],szPlayerName[32],szPlayerID[32]
		get_user_name(id,szAdminName,31)
		get_user_authid (id,szAdminAuthid,31)
		get_user_name(player, szPlayerName, 31)
		get_user_authid (player,szPlayerID,31)
		
		g_isBuildBan[player] = g_isBuildBan[player] ? false : true
		
		if (g_isBuildBan[player] && g_iOwnedEnt[player])
			cmdStopEnt(player)
		
		client_print(id, print_console, "[Base Builder] Player %s was %s from building", szPlayerName, g_isBuildBan[player] ? "banned":"unbanned")
		Log("[MOVE] Admin: %s || SteamID: %s banned Player: %s || SteamID: %s from building", szAdminName, szAdminAuthid, szPlayerName, szPlayerID)
		
		set_hudmessage(255,0, 0, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2, 1)
		show_hudmessage(player, "%L", LANG_SERVER, "ADMIN_BUILDBAN", g_isBuildBan[player] ? "disabled":"re-enabled");
		
		print_color(0, "%s Player^x04 %s^x01 has been^x04 %s^x01 from building", MODNAME, szPlayerName, g_isBuildBan[player] ? "banned":"unbanned")
	}
	
	return PLUGIN_HANDLED;
}

public fw_PlayerPreThink(id)
{
	if (!is_user_connected(id))
	{
		cmdStopEnt(id)
		return PLUGIN_HANDLED
	}
	
	if (g_isZombie[id])
		set_pev(id, pev_maxspeed, g_fPlayerSpeed[id])
	
	if (!g_iOwnedEnt[id] || !is_valid_ent(g_iOwnedEnt[id]))
		return FMRES_HANDLED
		
	new buttons = pev(id, pev_button)
	if (buttons & IN_ATTACK)
	{
		g_fEntDist[id] += OBJECT_PUSHPULLRATE;
		
		if (g_fEntDist[id] > g_fEntMaxDist)
		{
			g_fEntDist[id] = g_fEntMaxDist
			client_print(id, print_center, "%L", LANG_SERVER, "OBJECT_MAX")
		}
		else
			client_print(id, print_center, "%L", LANG_SERVER, "OBJECT_PUSH")
			
		ExecuteForward(g_fwPushPull, g_fwDummyResult, id, g_iOwnedEnt[id], 1);
	}
	else if (buttons & IN_ATTACK2)
	{
		g_fEntDist[id] -= OBJECT_PUSHPULLRATE;
			
		if (g_fEntDist[id] < g_fEntSetDist)
		{
			g_fEntDist[id] = g_fEntSetDist
			client_print(id, print_center, "%L", LANG_SERVER, "OBJECT_MIN")
		}
		else
			client_print(id, print_center, "%L", LANG_SERVER, "OBJECT_PULL")
			
		ExecuteForward(g_fwPushPull, g_fwDummyResult, id, g_iOwnedEnt[id], 2);
	}
	
	new iOrigin[3], iLook[3], Float:fOrigin[3], Float:fLook[3], Float:vMoveTo[3], Float:fLength
	    
	get_user_origin(id, iOrigin, 1);
	IVecFVec(iOrigin, fOrigin);
	get_user_origin(id, iLook, 3);
	IVecFVec(iLook, fLook);
	    
	fLength = get_distance_f(fLook, fOrigin);
	if (fLength == 0.0) fLength = 1.0;

	vMoveTo[0] = (fOrigin[0] + (fLook[0] - fOrigin[0]) * g_fEntDist[id] / fLength) + g_fOffset1[id];
	vMoveTo[1] = (fOrigin[1] + (fLook[1] - fOrigin[1]) * g_fEntDist[id] / fLength) + g_fOffset2[id];
	vMoveTo[2] = (fOrigin[2] + (fLook[2] - fOrigin[2]) * g_fEntDist[id] / fLength) + g_fOffset3[id];
	vMoveTo[2] = float(floatround(vMoveTo[2], floatround_floor));

	entity_set_origin(g_iOwnedEnt[id], vMoveTo);
	
	return FMRES_HANDLED
}

public fw_Traceline(Float:start[3], Float:end[3], conditions, id, trace)
{
	if (!is_user_alive(id))
		return PLUGIN_HANDLED
	
	new ent = get_tr2(trace, TR_pHit)
	
	if (is_valid_ent(ent))
	{
		new ent,body
		get_user_aiming(id,ent,body)
		
		new szClass[10], szTarget[7];
		entity_get_string(ent, EV_SZ_classname, szClass, 9);
		entity_get_string(ent, EV_SZ_targetname, szTarget, 6);
		if (equal(szClass, "func_wall") && !equal(szTarget, "ignore") && ent != g_iEntBarrier && g_iShowMovers == 1)
		{
			if (g_boolCanBuild || access(id, ADMIN_SLAY))
			{
				set_hudmessage(0, 50, 255, -1.0, 0.55, 1, 0.01, 3.0, 0.01, 0.01);
				if (!BlockLocker(ent))
				{
					new szCurMover[32], szLastMover[32]
					if (GetEntMover(ent))
					{
						get_user_name(GetEntMover(ent),szCurMover,31)
						if (!GetLastMover(ent))
							ShowSyncHudMsg(id, g_HudSync, "Current Mover: %s^nLast Mover: NONE", szCurMover);
					}
					if (GetLastMover(ent))
					{
						get_user_name(GetLastMover(ent),szLastMover,31)
						if (!GetEntMover(ent))
							ShowSyncHudMsg(id, g_HudSync, "Current Mover: NONE^nLast Mover: %s", szLastMover);
					}
					if (GetEntMover(ent) && GetLastMover(ent))
						ShowSyncHudMsg(id, g_HudSync, "Current Mover: %s^nLast Mover: %s", szCurMover, szLastMover);
					else if (!GetEntMover(ent) && !GetLastMover(ent))
						ShowSyncHudMsg(id, g_HudSync, "This object hasn't been moved");
				}
				else
				{
					new szEntOwner[32]
					get_user_name(BlockLocker(ent),szEntOwner,31)
					ShowSyncHudMsg(id, g_HudSync, "Claimed by: %s", szEntOwner);
				}
			}
		}
	}
	else ClearSyncHud(id, g_HudSync);
	
	return PLUGIN_HANDLED
}

public fw_EmitSound(id,channel,const sample[],Float:volume,Float:attn,flags,pitch)
{
	if (!is_user_connected(id) || !g_isZombie[id] || g_boolCanBuild || g_boolPrepTime || g_boolRoundEnded)
		return FMRES_IGNORED;
		
	if(equal(sample[7], "die", 3) || equal(sample[7], "dea", 3))
	{
		emit_sound(id,channel,g_szZombieDie[random(sizeof g_szZombieDie - 1)],volume,attn,flags,pitch)
		return FMRES_SUPERCEDE
	}
	
	if(equal(sample[7], "bhit", 4))
	{
		emit_sound(id,channel,g_szZombiePain[random(sizeof g_szZombiePain - 1)],volume,attn,flags,pitch)
		return FMRES_SUPERCEDE
	}
	
	// Zombie attacks with knife
	if (equal(sample[8], "kni", 3))
	{
		if (equal(sample[14], "sla", 3)) // slash
		{
			emit_sound(id,channel,g_szZombieMiss[random(sizeof g_szZombieMiss - 1)],volume,attn,flags,pitch)
			return FMRES_SUPERCEDE;
		}
		if (equal(sample[14], "hit", 3)) // hit
		{
			if (sample[17] == 'w') // wall
			{
				emit_sound(id,channel,g_szZombieHit[random(sizeof g_szZombieHit - 1)],volume,attn,flags,pitch)
				return FMRES_SUPERCEDE;
			}
			else
			{
				emit_sound(id,channel,g_szZombieHit[random(sizeof g_szZombieHit - 1)],volume,attn,flags,pitch)
				return FMRES_SUPERCEDE;
			}
		}
		if (equal(sample[14], "sta", 3)) // stab
		{
			emit_sound(id,channel,g_szZombieMiss[random(sizeof g_szZombieMiss - 1)],volume,attn,flags,pitch)
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED
}

public fw_Suicide(id) return FMRES_SUPERCEDE

public show_colors_menu(id,offset)
{
	if(offset<0) offset = 0

	new keys, curnum, menu[2048]
	for(new i=offset;i<MAX_COLORS;i++)
	{
		if (g_iColorMode == 0 || (g_iColorMode == 1 && !g_iColorOwner[i]))
		{
			g_iMenuOptions[id][curnum] = i
			keys += (1<<curnum)
	
			curnum++
			format(menu, charsmax(menu), "%s^n\r[\w%d\r]. \w%s", menu, curnum, g_szColorName[i])
	
			if(curnum==8)
				break;
		}
	}

	format(menu, charsmax(menu), "\ySelect Your Color:^n     \wCurrent: \r%s\w^n%s^n", g_szColorName[g_iColor[id]], menu)
	if(curnum==8 && offset<12)
	{
		keys += (1<<8)
		format(menu, charsmax(menu), "%s^n\r[\w9\r]. \wNext",menu)
	}
	if(offset)
	{
		keys += (1<<9)
		format(menu, charsmax(menu), "%s^n\r[\w0\r]. \wBack",menu)
	}

	show_menu(id,keys,menu,-1,"ColorsSelect")
}

public colors_pushed(id,key)
{
	if(key<8)
	{
		g_iColorOwner[g_iMenuOptions[id][key]] = id
		g_iColorOwner[g_iColor[id]] = 0
		g_iColor[id] = g_iMenuOptions[id][key]
		print_color(id, "%s You have picked^x04 %s^x01 as your color", MODNAME, g_szColorName[g_iColor[id]])
		g_iMenuOffset[id] = 0
		
		ExecuteForward(g_fwNewColor, g_fwDummyResult, id, g_iColor[id]);
	}
	else
	{
		if(key==8)
			g_iMenuOffset[id] += 8
		if(key==9)
			g_iMenuOffset[id] -= 8
		show_colors_menu(id,g_iMenuOffset[id])
	}

	return ;
}

public show_zclass_menu(id,offset)
{
	if(offset<0) offset = 0

	new keys, curnum, menu[512], szCache1[32], szCache2[32], iCache3
	for(new i=offset;i<g_iZClasses;i++)
	{
		ArrayGetString(g_zclass_name, i, szCache1, charsmax(szCache1))
		ArrayGetString(g_zclass_info, i, szCache2, charsmax(szCache2))
		iCache3 = ArrayGetCell(g_zclass_admin, i)
		
		// Add to menu
		if (i == g_iZombieClass[id])
			format(menu, charsmax(menu), "%s^n\d\r[\w%d\r]. \d%s \r[\y%s\r]\r \d%s\r", menu, curnum+1, szCache1, szCache2, iCache3 == ADMIN_ALL ? "(Selected)" : "(Selected)")
		else
			format(menu,511,"%s^n\r\r[\w%d\r]. \w%s \r[\y%s\r]", menu, curnum+1, szCache1, szCache2, iCache3 == ADMIN_ALL ? "" : "" )
		
		g_iMenuOptions[id][curnum] = i
		keys += (1<<curnum)
	
		curnum++
		
		if(curnum==8)
			break;
	}

    format(menu,511,"\rCTX \wZombie Classes \d| \wClass Section \y[Zombies]^n\r%s^n", menu)
    if(curnum==8 && offset<12)
    {
        keys += (1<<8)
        format(menu,511,"%s^n\d\r9.\d \r \wNext\r ",menu)
    }
    if(offset)
    {
        keys += (1<<9)
        format(menu,511,"%s^n\d\r0.\d \r \wBack\r ",menu)
    
    }

    show_menu(id,keys,menu,-1,"ZClassSelect")
} 

public zclass_pushed(id,key)
{
	if(key<8)
	{
		if (g_iMenuOptions[id][key] == g_iZombieClass[id])
		{
			client_cmd(id, "spk %s", LOCK_FAIL);
			
			print_color(id, "%s %L", MODNAME, LANG_SERVER, "CLASS_CURRENT")
			show_zclass_menu(id,g_iMenuOffset[id])
			return ;
		}
		
		new iCache3 = ArrayGetCell(g_zclass_admin, g_iMenuOptions[id][key])
		
		if ((iCache3 != ADMIN_ALL || !iCache3) && !access(id, iCache3))
		{
			print_color(id, "%s %L", MODNAME, LANG_SERVER, "CLASS_NO_ACCESS")
			show_zclass_menu(id,g_iMenuOffset[id])
			return ;
		}
		
		g_iNextClass[id] = g_iMenuOptions[id][key]
	
		new szCache1[32]
		ArrayGetString(g_zclass_name, g_iMenuOptions[id][key], szCache1, charsmax(szCache1))
		
		if (!g_isZombie[id] || (g_isZombie[id] && (g_boolCanBuild || g_boolPrepTime)))
			print_color(id, "%s You have selected^x04 %s^x01 as your next class", MODNAME, szCache1)
		if (!g_isAlive[id])
			print_color(id, "%s %L", MODNAME, LANG_SERVER, "CLASS_RESPAWN")
		g_iMenuOffset[id] = 0
		
		if (g_isZombie[id] && (g_boolCanBuild || g_boolPrepTime))
			ExecuteHamB(Ham_CS_RoundRespawn, id)
			
		ExecuteForward(g_fwClassPicked, g_fwDummyResult, id, g_iZombieClass[id]);
	}
	else
	{
		if(key==8)
			g_iMenuOffset[id] += 8
		if(key==9)
			g_iMenuOffset[id] -= 8
		show_zclass_menu(id,g_iMenuOffset[id])
	}

	return ;
}



/*------------------------------------------------------------------------------------------------*/
public show_method_menu(id)
{
	if(g_boolFirstTime[id])
	{
		g_boolFirstTime[id] = false
		show_primary_menu(id,0)
	}
	else
	{
		g_iMenuOffset[id] = 0
		show_menu(id,(1<<0)|(1<<1),"\yChoose Your Weapons:^n^n\r\r[\w1\r]. \wNew Guns^n\r\r[\w2\r]. \wLast Guns",-1,"WeaponMethodMenu")
	}
}

public weapon_method_pushed(id,key)
{
	switch(key)
	{
		case 0: show_primary_menu(id,0)
		case 1: give_weapons(id)
	}
	return ;
}

public show_primary_menu(id,offset)
{
	if(offset<0) offset = 0

	new cvar_value[32]
	get_pcvar_string(g_pcvar_allowedweps,cvar_value,31)
	new flags = read_flags(cvar_value)

	new keys, curnum, menu[2048]
	for(new i=offset;i<19;i++)
	{
		if(flags & power(2,i))
		{
			g_iMenuOptions[id][curnum] = i
			keys += (1<<curnum)
	
			curnum++
			format(menu,2047,"%s^n\r[\w%d\r]. \w%s\r",menu,curnum,szWeaponNames[i])
	
			if(curnum==8)
				break;
		}
	}

	format(menu,2047,"\yPrimary Weapons:\w^n%s^n",menu)
	if(curnum==8 && offset<12)
	{
		keys += (1<<8)
		format(menu,2047,"\r%s^n\r[\w9\r]. Next",menu)
	}
	if(offset)
	{
		keys += (1<<9)
		format(menu,2047,"\r%s^n\r[\w0\r]. Back",menu)
	}

	show_menu(id,keys,menu,-1,"PrimaryWeaponSelect")
}

public prim_weapons_pushed(id,key)
{
	if(key<8)
	{
		g_iWeaponPicked[0][id] = g_iMenuOptions[id][key]
		g_iMenuOffset[id] = 0
		show_secondary_menu(id,0)
	}
	else
	{
		if(key==8)
			g_iMenuOffset[id] += 8
		if(key==9)
			g_iMenuOffset[id] -= 8
		show_primary_menu(id,g_iMenuOffset[id])
	}
	return ;
}

public show_secondary_menu(id,offset)
{
	if(offset<0) offset = 0

	new cvar_value[32]
	get_pcvar_string(g_pcvar_allowedweps,cvar_value,31)
	new flags = read_flags(cvar_value)

	new keys, curnum, menu[2048]
	for(new i=18;i<24;i++)
	{
		if(flags & power(2,i))
		{
			g_iMenuOptions[id][curnum] = i
			keys += (1<<curnum)
	
			curnum++
			format(menu,2047,"%s^n\r[\w%d\r]. \w%s\r",menu,curnum,szWeaponNames[i])
		}
	}

	format(menu,2047,"\ySecondary Weapons:\w^n%s",menu)

	show_menu(id,keys,menu,-1,"SecWeaponSelect")
}

public sec_weapons_pushed(id,key)
{
	if(key<8)
	{
		g_iWeaponPicked[1][id] = g_iMenuOptions[id][key]
	}
	give_weapons(id)
	return ;
}

public give_weapons(id)
{
	strip_user_weapons(id)
	give_item(id,"weapon_knife")
   
	new szWeapon[32], csw
	csw = csw_contant(g_iWeaponPicked[0][id])
	get_weaponname(csw,szWeapon,31)
	give_item(id,szWeapon)
	cs_set_user_bpammo(id,csw,999)
	g_iPrimaryWeapon[id] = csw

	csw = csw_contant(g_iWeaponPicked[1][id])
	get_weaponname(csw,szWeapon,31)
	give_item(id,szWeapon)
	cs_set_user_bpammo(id,csw,999)
	
	g_boolRepick[id] = false
}

stock csw_contant(weapon)
{
	new num = 29
	switch(weapon)
	{
		case 0: num = 3
		case 1: num = 5
		case 2: num = 7
		case 3: num = 8
		case 4: num = 12
		case 5: num = 13
		case 6: num = 14
		case 7: num = 15
		case 8: num = 18

		case 10: num = 20
		case 11: num = 21
		case 12: num = 22
		case 13: num = 23
		case 14: num = 24
		case 15: num = 27
		case 16: num = 28
		case 17: num = 30
		case 18: num = 1
		case 19: num = 10
		case 20: num = 11
		case 21: num = 16
		case 22: num = 17
		case 23: num = 26
		case 24:
		{
			new s_weapon[32]
		
			get_pcvar_string(g_pcvar_allowedweps,s_weapon,31)
		   
			new flags = read_flags(s_weapon)
			do
			{
				num = random_num(0,18)
				if(!(num & flags))
				{
					num = -1
				}
			}
			while(num==-1)
			num = csw_contant(num)
		}
		case 25:
		{
			new s_weapon[32]

			get_pcvar_string(g_pcvar_allowedweps,s_weapon,31)
		
			new flags = read_flags(s_weapon)
			do
			{
				num = random_num(18,23)
				if(!(num & flags))
				{
					num = -1
				}
			}
			while(num==-1)
			num = csw_contant(num)
		}
	}
	return num;
}
/*------------------------------------------------------------------------------------------------*/

Log(const message_fmt[], any:...)
{
	static message[256];
	vformat(message, sizeof(message) - 1, message_fmt, 2);
	
	static filename[96];
	static dir[64];
	if( !dir[0] )
	{
		get_basedir(dir, sizeof(dir) - 1);
		add(dir, sizeof(dir) - 1, "/logs");
	}
	
	format_time(filename, sizeof(filename) - 1, "%m-%d-%Y");
	format(filename, sizeof(filename) - 1, "%s/BaseBuilder_%s.log", dir, filename);
	
	log_to_file(filename, "%s", message);
}

print_color(target, const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()
	
	// Send to everyone
	if (!target)
	{
		static player
		for (player = 1; player <= g_iMaxPlayers; player++)
		{
			// Not connected
			if (!g_isConnected[player])
				continue;
			
			// Remember changed arguments
			static changed[5], changedcount // [5] = max LANG_PLAYER occurencies
			changedcount = 0
			
			// Replace LANG_PLAYER with player id
			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}
			
			// Format message for player
			vformat(buffer, charsmax(buffer), message, 3)
			
			// Send it
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			// Replace back player id's with LANG_PLAYER
			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	// Send to specific target
	else
	{
		// Format message for player
		vformat(buffer, charsmax(buffer), message, 3)
		
		// Send it
		message_begin(MSG_ONE, g_msgSayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}

stock fm_cs_get_current_weapon_ent(id)
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);

public native_register_zombie_class(const name[], const info[], const model[], const clawmodel[], hp, speed, Float:gravity, Float:knockback, adminflags, credits)
{
	if (!g_boolArraysCreated)
		return 0;
		
	// Strings passed byref
	param_convert(1)
	param_convert(2)
	param_convert(3)
	param_convert(4)
	
	// Add the class
	ArrayPushString(g_zclass_name, name)
	ArrayPushString(g_zclass_info, info)
	
	ArrayPushCell(g_zclass_modelsstart, ArraySize(g_zclass_playermodel))
	ArrayPushString(g_zclass_playermodel, model)
	ArrayPushCell(g_zclass_modelsend, ArraySize(g_zclass_playermodel))
	ArrayPushCell(g_zclass_modelindex, -1)
	
	ArrayPushString(g_zclass_clawmodel, clawmodel)
	ArrayPushCell(g_zclass_hp, hp)
	ArrayPushCell(g_zclass_spd, speed)
	ArrayPushCell(g_zclass_grav, gravity)
	ArrayPushCell(g_zclass_admin, adminflags)
	ArrayPushCell(g_zclass_credits, credits)
	
	// Set temporary new class flag
	ArrayPushCell(g_zclass_new, 1)
	
	// Override zombie classes data with our customizations
	new i, k, buffer[32], Float:buffer2, nummodels_custom, nummodels_default, prec_mdl[100], size = ArraySize(g_zclass2_realname)
	for (i = 0; i < size; i++)
	{
		ArrayGetString(g_zclass2_realname, i, buffer, charsmax(buffer))
		
		// Check if this is the intended class to override
		if (!equal(name, buffer))
			continue;
		
		// Remove new class flag
		ArraySetCell(g_zclass_new, g_iZClasses, 0)
		
		// Replace caption
		ArrayGetString(g_zclass2_name, i, buffer, charsmax(buffer))
		ArraySetString(g_zclass_name, g_iZClasses, buffer)
		
		// Replace info
		ArrayGetString(g_zclass2_info, i, buffer, charsmax(buffer))
		ArraySetString(g_zclass_info, g_iZClasses, buffer)
		
		nummodels_custom = ArrayGetCell(g_zclass2_modelsend, i) - ArrayGetCell(g_zclass2_modelsstart, i)
		nummodels_default = ArrayGetCell(g_zclass_modelsend, g_iZClasses) - ArrayGetCell(g_zclass_modelsstart, g_iZClasses)
			
		// Replace each player model and model index
		for (k = 0; k < min(nummodels_custom, nummodels_default); k++)
		{
			ArrayGetString(g_zclass2_playermodel, ArrayGetCell(g_zclass2_modelsstart, i) + k, buffer, charsmax(buffer))
			ArraySetString(g_zclass_playermodel, ArrayGetCell(g_zclass_modelsstart, g_iZClasses) + k, buffer)
				
			// Precache player model and replace its modelindex with the real one
			formatex(prec_mdl, charsmax(prec_mdl), "models/player/%s/%s.mdl", buffer, buffer)
			ArraySetCell(g_zclass_modelindex, ArrayGetCell(g_zclass_modelsstart, g_iZClasses) + k, engfunc(EngFunc_PrecacheModel, prec_mdl))
		}
			
		// We have more custom models than what we can accommodate,
		// Let's make some space...
		if (nummodels_custom > nummodels_default)
		{
			for (k = nummodels_default; k < nummodels_custom; k++)
			{
				ArrayGetString(g_zclass2_playermodel, ArrayGetCell(g_zclass2_modelsstart, i) + k, buffer, charsmax(buffer))
				ArrayInsertStringAfter(g_zclass_playermodel, ArrayGetCell(g_zclass_modelsstart, g_iZClasses) + k - 1, buffer)
				
				// Precache player model and retrieve its modelindex
				formatex(prec_mdl, charsmax(prec_mdl), "models/player/%s/%s.mdl", buffer, buffer)
				ArrayInsertCellAfter(g_zclass_modelindex, ArrayGetCell(g_zclass_modelsstart, g_iZClasses) + k - 1, engfunc(EngFunc_PrecacheModel, prec_mdl))
			}
				
			// Fix models end index for this class
			ArraySetCell(g_zclass_modelsend, g_iZClasses, ArrayGetCell(g_zclass_modelsend, g_iZClasses) + (nummodels_custom - nummodels_default))
		}
		
		// Replace clawmodel
		ArrayGetString(g_zclass2_clawmodel, i, buffer, charsmax(buffer))
		ArraySetString(g_zclass_clawmodel, g_iZClasses, buffer)
		
		// Precache clawmodel
		formatex(prec_mdl, charsmax(prec_mdl), "models/%s.mdl", buffer)
		engfunc(EngFunc_PrecacheModel, prec_mdl)
		
		// Replace health
		buffer[0] = ArrayGetCell(g_zclass2_hp, i)
		ArraySetCell(g_zclass_hp, g_iZClasses, buffer[0])
		
		// Replace speed
		buffer[0] = ArrayGetCell(g_zclass2_spd, i)
		ArraySetCell(g_zclass_spd, g_iZClasses, buffer[0])
		
		// Replace gravity
		buffer2 = Float:ArrayGetCell(g_zclass2_grav, i)
		ArraySetCell(g_zclass_grav, g_iZClasses, buffer2)
		
		// Replace admin flags
		buffer2 = ArrayGetCell(g_zclass2_admin, i)
		ArraySetCell(g_zclass_admin, g_iZClasses, buffer2)
	
		// Replace credits
		buffer2 = ArrayGetCell(g_zclass2_credits, i)
		ArraySetCell(g_zclass_credits, g_iZClasses, buffer2)
	}
	
	// If class was not overriden with customization data
	if (ArrayGetCell(g_zclass_new, g_iZClasses))
	{
		// Precache default class model and replace modelindex with the real one
		formatex(prec_mdl, charsmax(prec_mdl), "models/player/%s/%s.mdl", model, model)
		ArraySetCell(g_zclass_modelindex, ArrayGetCell(g_zclass_modelsstart, g_iZClasses), engfunc(EngFunc_PrecacheModel, prec_mdl))
		
		// Precache default clawmodel
		formatex(prec_mdl, charsmax(prec_mdl), "models/%s.mdl", clawmodel)
		engfunc(EngFunc_PrecacheModel, prec_mdl)
	}

	g_iZClasses++
	
	return g_iZClasses-1
}

public native_get_class_cost(classid)
{
	if (classid < 0 || classid >= g_iZClasses)
		return -1;
	
	return ArrayGetCell(g_zclass_credits, classid)
}

public native_get_class_name(classid, szName[], len) {
if(classid < 0 || classid >= g_iZClasses)
return;

new szClassName[32];
ArrayGetString( g_zclass_name, classid, szClassName, charsmax(szClassName));

param_convert( 2 );
formatex( szName, len, szClassName );
}
public native_get_user_zombie_class(id) return g_iZombieClass[id];
public native_get_user_next_class(id) return g_iNextClass[id];
public native_set_user_zombie_class(id, classid)
{
	if (classid < 0 || classid >= g_iZClasses)
		return 0;
	
	g_iNextClass[id] = classid
	return 1;
}

public native_is_user_zombie(id) return g_isZombie[id]
public native_is_user_banned(id) return g_isBuildBan[id]

public native_bool_buildphase() return g_boolCanBuild
public native_bool_prepphase() return g_boolPrepTime

public native_get_build_time()
{
	if (g_boolCanBuild)
		return g_iCountDown
		
	return 0;
}

public native_set_build_time(time)
{
	if (g_boolCanBuild)
	{
		g_iCountDown = time
		return 1
	}
		
	return 0;
}
public native_get_user_color(id) return g_iColor[id]
public native_set_user_color(id, color)
{
	g_iColor[id] = color
}

public native_drop_user_block(id)
{
	cmdStopEnt(id)
}
public native_get_user_block(id)
{
	if (g_iOwnedEnt[id])
		return g_iOwnedEnt[id]
		
	return 0;
}
public native_set_user_block(id, entity)
{
	if (is_valid_ent(entity) && !is_user_alive(entity) && !MovingEnt(entity))
		g_iOwnedEnt[id] = entity
}

public native_is_locked_block(entity)
{
	if (is_valid_ent(entity) && !is_user_alive(entity))
		return BlockLocker(entity) ? true : false
		
	return -1;
}
public native_lock_block(entity)
{
	if (is_valid_ent(entity) && !is_user_alive(entity) && !BlockLocker(entity))
	{
		LockBlock(entity, 33);
		set_pev(entity,pev_rendermode,kRenderTransColor)
		set_pev(entity,pev_rendercolor,Float:{LOCKED_COLOR})
		set_pev(entity,pev_renderamt,Float:{LOCKED_RENDERAMT})
	}
}
public native_unlock_block(entity)
{
	if (is_valid_ent(entity) && !is_user_alive(entity) && BlockLocker(entity))
	{
		UnlockBlock(entity)
		set_pev(entity,pev_rendermode,kRenderNormal)
	}
}

public native_release_zombies()
{
	if (g_boolCanBuild || g_boolPrepTime)
	{
		Release_Zombies()
		return 1;
	}
	return 0;
}

public native_set_user_primary(id, csw_primary)
{
	if (CSW_P228<=csw_primary<=CSW_P90)
	{
		g_iPrimaryWeapon[id] = csw_primary
		return g_iPrimaryWeapon[id];
	}
		
	return -1;
}

public native_get_user_primary(id) return g_iPrimaryWeapon[id]

public native_get_flags_build() 		return FLAGS_BUILD
public native_get_flags_lock() 		return FLAGS_LOCK
public native_get_flags_buildban() 	return FLAGS_BUILDBAN
public native_get_flags_swap() 		return FLAGS_SWAP
public native_get_flags_revive() 	return FLAGS_REVIVE
public native_get_flags_guns() 		return FLAGS_GUNS
public native_get_flags_release() 	return FLAGS_RELEASE
public native_get_flags_override() 	return FLAGS_OVERRIDE
public native_get_flags_lockafter()     return FLAGS_LOCKAFTER 
/*public native_set_user_mult(id, attribute, Float: amount)
{
	if (attribute < ATT_HEALTH || attribute > ATT_GRAVITY)
		return 0;
		
	if (amount < 1.0)
		amount = 1.0
		
	g_fClassMultiplier[id][attribute] = amount
	
	return 1;
}*/
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1050\\ f0\\ fs16 \n\\ par }
*/
