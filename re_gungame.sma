// 1.5.2 - gyxoBka (релиз плагина)
// 1.5.3 - SNauPeR (добавлена настройка HUDа, отредактировано время отображения, также добавлена настройка для поля GAME в поиске серверов)
// 1.6.0 - SNauPeR (добавлены квары новой системы ножа, HUDа оружия, FFA режим для гранаты и понижения лвла при убийства своих, скрытия радара
//                  исправлен баг с зачетом двойного и больше убийств с помощью гранаты, увеличено максимальное количество оружий)
// 1.6.1 - SNauPeR (убран дебаг, дабы не засорять консоль сервера, фикс ошибки Run time Error 2 (forward "CBasePlayer_DropPlayerItem")
// 1.7.0 - SNauPeR (добавлена прямая поддержка (БЕЗ сторонних плагинов) плагинов смены карт от Скальпеля и Мистрика (2.56.1 и 3.0.7))

// // Оптимизация кода под актуальные билды + отказ от некоторых модулей в пользу иных
// 1.7.0f - SNauPeR (g_iMaxPlayers -> MaxClients, в некоторых циклах убраны лишние проходы (начинаем с 1го, а не с 0го игрока))
// 1.7.0s - SNauPeR (ICON_OF -> ICON_OFF)
// 1.7.1f - SNauPeR (set_task -> set_task_ex)
// 1.7.1s - SNauPeR (берем длину для ника, стим, ип из констант amxconst, а не свои)
// 1.7.2 - SNauPeR (cs_get_user_lastactivity -> rg_get_user_lastactivity)
// 1.7.3 - SNauPeR (set_user_godmode -> var_takedamage)
// 1.7.4 - SNauPeR (добавлен clamp для правильных проверок)
// 1.7.5 - SNauPeR (добавлен новый формат чтения конфигов json)
// 1.8.0b - SNauPeR (небольшие правки по коду, перезалив файлов в папку ReGG, добавление объяснений под json, файл readme.txt)
// 1.8.0r - SNauPeR (добавлен квар скрытия денег hide_cash)

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <reapi_stocks>

native gg_give_player_bazooka(id);

#pragma semicolon 1

new const PLUGIN[] = "ReGunGame";
new const VERSION[] = "1.8.1r";
new const AUTHOR[] = "gyxoBka + SNauPeR";

/*---------------EDIT ME------------------*/

#define RED_TEAM_COLOUR   	255.0, 0.0, 0.0   	// Цвет RGB во время защиты для ТТ (рендеринг)
#define BLUE_TEAM_COLOUR   	0.0, 0.0, 255.0		// Цвет RGB во время защиты для CT (рендеринг)
#define GLOW_THICK         	10.0				// "Плотность" цвета защиты. Закомментируйте, чтобы отключить свечение

#define REFRESH_INTERVAL 	5.0					// С какой периодичностью обновляется HUD лидера

#define MAX_SAVES 			32					// Максимальное количество сохраненных игроков (прямопропорционально нагрузкеапппппппс) 

/*----------------------------------------*/

#define rg_get_user_lastactivity(%0) Float:get_member(%0, m_fLastMovement)
#define rg_set_weapon_ammo(%0,%1)    set_member(%0, m_Weapon_iClip, %1)

#define CheckFlag(%1,%2)  			(%1 &   (1 << (%2 & 31)))
#define SetFlag(%1,%2)    			(%1 |=  (1 << (%2 & 31)))
#define ClearFlag(%1,%2)			(%1 &= ~(1 << (%2 & 31)))

#define MAX_LEVELS 			36	// Сколько оружий (максимум)
#define START_LEVEL			1
#define	MAX_SPAWNS			60
#define WEAPON_LEN 			16
#define SOUND_SIZE 			100

#define TASK_PROTECTION_ID	96
#define TASK_GIVEGRENADE_ID 128
#define TASK_LEADER_DISPLAY 500

#define IsPlayer(%1) 		(1 <= %1 <= MaxClients)
#define IsMp3Format(%1)  	equali(%1[strlen(%1) - 4 ], ".mp3")

#define HIDE_HUD_TIMER		(1<<4)
#define HIDE_HUD_CASH		(1<<5)

enum
{
	WORLD = 0,
	BULLET,
	KNIFE,
	GRENADE
}

enum 
{
	SECTION_NONE = 0,
	BASIC,
	DEATHMATCH,
	WARMUP,
	SOUND,
	WEAPON
}

enum
{
	LEVEL_UP = 0,
	LEVEL_DOWN,
	LEVEL_STEAL,
	LEVEL_NADE,
	LEVEL_KNIFE,
	LEVEL_WELCOME,
	LEVEL_WINNER,
	LEVEL_LEAD,
	LEVEL_TIED_LEAD,
	LEVEL_LOST_LEAD
}

enum SaveData
{
	szAuth[MAX_AUTHID_LENGTH + 1],
	iSavedLevel,
	iSavedKills,
	iTimeStamp
}

new g_eSavedData[MAX_SAVES + 1][SaveData];

new Array:g_aLevelUp, 
	Array:g_aLevelDown, 
	Array:g_aLevelSteal, 
	Array:g_aLevelNade, 
	Array:g_aLevelKnife, 
	Array:g_aLevelWelcome, 
	Array:g_aLevelWinner, 
	Array:g_aLevelLead, 
	Array:g_aLevelTiedLead, 
	Array:g_aLevelLostLead;
	
new g_aLevelUp_size, 
	g_aLevelDown_size, 
	g_aLevelSteal_size, 
	g_aLevelNade_size, 
	g_aLevelKnife_size, 
	g_aLevelWelcome_size, 
	g_aLevelWinner_size, 
	g_aLevelLead_size, 
	g_aLevelTiedLead_size,
	g_aLevelLostLead_size;

new g_szWeaponLevelName[MAX_LEVELS + 1][WEAPON_LEN + 1], 
	g_szShortWeaponName[MAX_LEVELS + 1][WEAPON_LEN + 1], 
	g_iNeedFrags[MAX_LEVELS + 1], 
	g_iMaxBpAmmoLevel[MAX_LEVELS + 1],
	g_szWeaponIcon[MAX_LEVELS + 2][12];

enum _:eData_Weapon {
	IS_KNIFE,
	IS_GREADE,
	IS_BAZOOKA
}
new g_iWeaponsData[MAX_LEVELS + 1][eData_Weapon];

new g_iPlayerLevel[MAX_PLAYERS + 1] = {1, 1, ...}, 
	g_iPlayerFrags[MAX_PLAYERS + 1], 
	g_iTiedLeaderId[MAX_PLAYERS + 1];

new g_iSpawnVecs[MAX_SPAWNS][3], 
	g_iSpawnAngles[MAX_SPAWNS][3], 
	g_iSpawnVAngles[MAX_SPAWNS][3], 
	g_iSpawnTeam[MAX_SPAWNS];

new g_szGameName[32], 
	g_szVoteFunction[50], 
	g_szCallPluginName[24], 
	g_szLeaderName[32], 
	g_szTiedLeaderName[32], 
	g_szWarmUpWeapon[WEAPON_LEN + 1];

new g_iMaxLevels = START_LEVEL, 
	g_iLevelVote, 
	g_iLevelBeforeVote, 
	bool:g_bWinnerMotd, 
	g_iAfkProtection, 
	g_iArmorValue, 
	bool:g_bRandomSpawn, 
	g_iWarmUpTime, 
	g_iNewPlayerLevel, 
	g_iAwpAmmo, 
	bool:g_bHideTimer, 
	g_bOldKnifeSystem, 
	g_bHudSystem, 
	g_bGrenadeFF, 
	g_bGrenadeFF_LVL, 
	g_iColorRed, 
	g_iColorGreen, 
	g_iColorBlue, 
	g_iLevelSaveType, 
	bool:g_bDisplayLeader,
	g_iLeaderLevel = START_LEVEL, 
	g_iLeaderId, 
	g_iTiedLeaderNum, 
	g_iWinnerId, 
	g_iLastKilled, 
	g_iWarmUpLevel, 
	bool:g_bProtectionBar, 
	bool:g_bGlowEffect, 
	bool:g_bNoShotProtection,
	bool:g_bHideCash;

new Float:g_fHudPosX = -1.0, 
	Float:g_fHudPosY = 1.0;

new Float:g_fDisplayPosX, 
	Float:g_fDisplayPosY, 
	Float:g_fProtectionTime,  
	Float:g_fNadeRefreshTime;

new bool:g_bGameCommencing, 
	bool:g_bIsWarpUp, 
	bool:g_bVoteStarted; 

new g_MsgHideWeapon,
	g_MsgRoundTime, 
	g_hookMsgRoundTime; 

new g_iHudLeaderSync, 
	g_iHudFragSync,
	g_iTotalSpawns;

new IsPlayerAlive, 
	IsPlayerConnected, 
	IsPlayerBot;

new Float:g_fLastKill[MAX_PLAYERS + 1];

native mapm_start_vote(iType);
new bool:g_bIsMapMModular = true;

public plugin_natives() {
	set_native_filter("native_filter");
}

public native_filter(szNativeName[], iIndex, bool:bTrap) {	
	if(!bTrap) {	
		if(equal(szNativeName, "mapm_start_vote")) {
			g_bIsMapMModular = false;
			return PLUGIN_HANDLED;
		}	
	}
	return PLUGIN_CONTINUE;
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_cvar("regungame", VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED);
	
	register_logevent("EventGameCommencing", 2, "0=World triggered", "1=Game_Commencing");
	register_event("CurWeapon", "EventCurWeapon","be","1=1");
	register_event("AmmoX", "EventAmmoX","be");
	register_event("ResetHUD", "onResetHUD", "b");
	
	RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn", true);
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "CBasePlayer_TraceAttack", false);
	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed", true);
	RegisterHookChain(RG_CBasePlayer_DropPlayerItem, "CBasePlayer_DropPlayerItem", false);
	RegisterHookChain(RG_CSGameRules_DeadPlayerWeapons, "CSGameRules_DeadPlayerWeapons", false);
	RegisterHookChain(RG_CSGameRules_GiveC4, "CSGameRules_GiveC4", false);
	RegisterHookChain(RH_SV_DropClient, "SV_DropClient", true);
	
	register_forward(FM_ClientKill, "Fwd_ClientKill");

	g_iHudLeaderSync = CreateHudSyncObj();
	g_iHudFragSync = CreateHudSyncObj();
	
	g_MsgRoundTime = get_user_msgid("RoundTime");
	g_MsgHideWeapon = get_user_msgid("HideWeapon");
	
	register_message(g_MsgHideWeapon, "msgHideWeapon");
	
	remove_entity_name("armoury_entity");
	remove_entity_name("info_bomb_target");
	remove_entity_name("func_bomb_target");
}

public onResetHUD(id)
{
	if(!id || is_user_bot(id) || CheckFlag(IsPlayerBot, id))
		return;

	new iHideFlags = GetHudHideFlags();

	if(iHideFlags) {
		message_begin(MSG_ONE, g_MsgHideWeapon, _, id);
		write_byte(iHideFlags);
		message_end();
	}
}

public msgHideWeapon()
{
	new iHideFlags = GetHudHideFlags();

	if(iHideFlags) {
		set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | iHideFlags);
	}
}

public SV_DropClient(id, bCrash, szFmt[])
{
	ClearFlag(IsPlayerAlive, id);
	ClearFlag(IsPlayerConnected, id);
	remove_task(id + TASK_PROTECTION_ID);
	ClearFlag(IsPlayerBot, id);
	remove_task(id + TASK_GIVEGRENADE_ID);
	
	if(g_iLevelSaveType >= 0)
	{
		SaveDisconnectPlayer(id);
	}
	
	g_iPlayerLevel[id] = START_LEVEL;
	g_iPlayerFrags[id] = 0;
	
	CalculateNewLeader();
}

public CBasePlayer_DropPlayerItem() {
	SetHookChainReturn(ATYPE_INTEGER, 0);
	return HC_SUPERCEDE;
}

public Fwd_ClientKill(const id) 
	return FMRES_SUPERCEDE;


public plugin_precache()
{	
	ReadCfg();
	if(g_bRandomSpawn)
	{
		readSpawns();
	}

	if(g_aLevelUp_size)
	{
		PrecacheSounds(g_aLevelUp, g_aLevelUp_size);
	}

	if(g_aLevelDown_size)
	{
		PrecacheSounds(g_aLevelDown, g_aLevelDown_size);
	}
	
	if(g_aLevelSteal_size)
	{
		PrecacheSounds(g_aLevelSteal, g_aLevelSteal_size);
	}
	
	if(g_aLevelNade_size)
	{
		PrecacheSounds(g_aLevelNade, g_aLevelNade_size);
	}
	
	if(g_aLevelWelcome_size)
	{
		PrecacheSounds(g_aLevelWelcome, g_aLevelWelcome_size);
	}
	
	if(g_aLevelWinner_size)
	{
		PrecacheSounds(g_aLevelWinner, g_aLevelWinner_size);
	}
	
	if(g_aLevelLead_size)
	{
		PrecacheSounds(g_aLevelLead, g_aLevelLead_size);
	}

	if(g_aLevelTiedLead_size)
	{
		PrecacheSounds(g_aLevelTiedLead, g_aLevelTiedLead_size);
	}
	
	if(g_aLevelLostLead_size)
	{
		PrecacheSounds(g_aLevelLostLead, g_aLevelLostLead_size);
	}
	
	if(g_aLevelKnife_size)
	{
		PrecacheSounds(g_aLevelKnife, g_aLevelKnife_size);
	}
}

public plugin_cfg()
{
	set_cvar_num("mp_freezetime", 0);
	set_cvar_num("mp_timelimit", 0);
	set_cvar_num("mp_round_infinite", 0);
	set_cvar_num("mp_refill_bpammo_weapons", 2);
	
	set_member_game(m_bCTCantBuy, true);
	set_member_game(m_bTCantBuy, true);
	set_member_game(m_GameDesc, g_szGameName);
	
	g_iLevelVote = g_iMaxLevels - clamp(g_iLevelBeforeVote, 1, g_iMaxLevels);
	
	if(g_bDisplayLeader) set_task_ex(REFRESH_INTERVAL, "ShowLeader", TASK_LEADER_DISPLAY, _, _, SetTask_Repeat);
}

NewPlayerMiddleLevel()
{
	new iLevel, iMaxLevel = START_LEVEL, iMinLevel = 100;		/** Level 100 just big value to get min ;) **/
	
	for(new id = 1; id <= MaxClients; id++)
	{
		if(!CheckFlag(IsPlayerConnected, id)) continue;
		
		iLevel = g_iPlayerLevel[id];
		if(iMinLevel > iLevel) 
		{
			iMinLevel = iLevel;
			continue;
		}
		
		if(iMaxLevel < iLevel) iMaxLevel = iLevel;
	}
	
	if(iMinLevel > g_iMaxLevels) return START_LEVEL;
	
	return (iMaxLevel + iMinLevel) / 2;
}

public client_connect(id)
{
	ClearFlag(IsPlayerConnected, id);
	ClearFlag(IsPlayerAlive, id);
}

public client_putinserver(id)
{	
	if(GetPlayerData(id))
	{
		CalculateNewLeader();
	}
	else
	{
		switch(g_iNewPlayerLevel)
		{
			case 0:
			{
				g_iPlayerLevel[id] = NewPlayerMiddleLevel();
			}
			default:
			{
				new iLevel; iLevel = g_iPlayerLevel[g_iLeaderId] - g_iNewPlayerLevel;
				g_iPlayerLevel[id] = iLevel > START_LEVEL ? iLevel : START_LEVEL;
			}
		}
	}
	
	if(is_user_connected(id))
	{
		SetFlag(IsPlayerConnected, id);
	}
	
	if(is_user_bot(id) || is_user_hltv(id))
	{
		SetFlag(IsPlayerBot, id);
		return;
	}
	
	set_task_ex(0.5, "PlayWelcomeSound", id);
}

public CSGameRules_DeadPlayerWeapons(const wEnt)
{
	SetHookChainReturn(ATYPE_INTEGER, GR_PLR_DROP_GUN_NO);
	return HC_SUPERCEDE;
}

public CSGameRules_GiveC4() return HC_SUPERCEDE; 

public CBasePlayer_TraceAttack(id, pevAttacker, Float:damage, Float:vecDir[3], tr, bitsDamageType) {

	if(get_member(pevAttacker, m_iTeam) == get_member(id, m_iTeam)) {
		if(bitsDamageType == DMG_GRENADE && g_bGrenadeFF)
			return HC_CONTINUE;
			
		SetHookChainReturn(ATYPE_INTEGER, false);
		return HC_SUPERCEDE;
	}
	return HC_CONTINUE;
}

public CBasePlayer_Killed(id, pevAttacker, iGib)
{
	static bool:bGrenadeSound, bool:bKnifeSound; 
	static bool:bGiveNewWeapon; bGiveNewWeapon = false;
	static bool:bLevelDown; bLevelDown = false;
	static bool:bWinner;
	
	if(bWinner) return HC_CONTINUE;
	
	ClearFlag(IsPlayerAlive, id);
	
	if(!IsPlayer(pevAttacker) || id == pevAttacker || !CheckFlag(IsPlayerConnected, pevAttacker))
		return HC_CONTINUE;
	
	if(g_bIsWarpUp) 
	{
		if(g_iWeaponsData[g_iWarmUpLevel][IS_GREADE] || g_iWeaponsData[g_iWarmUpLevel][IS_GREADE])
			return HC_CONTINUE;
		
		rg_instant_reload_weapons(pevAttacker);		
		return HC_CONTINUE;
	}
	
	if(g_iAfkProtection)
	{
		if(get_gametime() - rg_get_user_lastactivity(id) > g_iAfkProtection)
			return HC_CONTINUE;
	}

	static iAttackerLevel, iAttackerFrags, iNeedFrags, iInflictor;
	iAttackerLevel = g_iPlayerLevel[pevAttacker];
	iAttackerFrags = g_iPlayerFrags[pevAttacker];
	iNeedFrags = g_iNeedFrags[iAttackerLevel];

	get_death_reason(id, pevAttacker, iInflictor);
	
	// Double kill detected
	// Не нужно засчитывать, если с одной грены убили нескольких
	if((get_gametime() - g_fLastKill[pevAttacker]) < 0.25 && iInflictor == GRENADE)
		return HC_CONTINUE;

	g_fLastKill[pevAttacker] = get_gametime();
	
	switch(iInflictor)
	{
		case BULLET:
		{
			iAttackerFrags++;
			if(iNeedFrags <= iAttackerFrags)
			{
				iAttackerFrags = 0;
				iAttackerLevel++;
				
				bGiveNewWeapon = true;
				
				if(g_aLevelUp_size)
				{
					PlaySound(pevAttacker, g_aLevelUp, g_aLevelUp_size);
				}
			}
			else rg_instant_reload_weapons(pevAttacker);
		}
		case GRENADE: {
			if(get_member(pevAttacker, m_iTeam) == get_member(id, m_iTeam)) // Friendly Fire
			{
				if(g_bGrenadeFF_LVL) {
					if(iAttackerLevel > START_LEVEL)
					{
						DeleteStatusIcon(pevAttacker, iAttackerLevel+1);
						iAttackerFrags = 0;
						iAttackerLevel--;
						
						if(g_aLevelDown_size)
						{
							PlaySound(pevAttacker, g_aLevelDown, g_aLevelDown_size);
						}
						
						bGiveNewWeapon = true;
						bLevelDown = true;
					}
				}
			} else {
				iAttackerFrags++;
				if(iNeedFrags <= iAttackerFrags)
				{
					iAttackerFrags = 0;
					iAttackerLevel++;
					
					bGiveNewWeapon = true;
					
					if(g_aLevelUp_size)
					{
						PlaySound(pevAttacker, g_aLevelUp, g_aLevelUp_size);
					}
				}
				else rg_instant_reload_weapons(pevAttacker);
			}
		}
		case KNIFE:
		{
			if(g_bOldKnifeSystem) {
				if(g_iPlayerLevel[id] > START_LEVEL)
				{
					g_iPlayerLevel[id]--;
					
					if(g_iLeaderId == id)
					{
						switch(g_iTiedLeaderNum)
						{
							case 0:
							{
								CalculateNewLeader();
							}
							case 1: 
							{
								g_iLeaderId = g_iTiedLeaderId[g_iTiedLeaderNum];
								g_iTiedLeaderId[g_iTiedLeaderNum] = 0;
								g_iTiedLeaderNum--;
								
								get_user_name(g_iLeaderId, g_szLeaderName, charsmax(g_szLeaderName));
							}
							default:
							{
								g_iLeaderId = g_iTiedLeaderId[g_iTiedLeaderNum];
								g_iTiedLeaderId[g_iTiedLeaderNum] = 0;
								g_iTiedLeaderNum--;

								get_user_name(g_iLeaderId, g_szLeaderName, charsmax(g_szLeaderName));
								get_user_name(g_iTiedLeaderId[g_iTiedLeaderNum], g_szTiedLeaderName, charsmax(g_szTiedLeaderName));
							}	
						}
					}
					
					if(g_aLevelDown_size)
					{
						PlaySound(id, g_aLevelDown, g_aLevelDown_size);
					}
				}
				
				if(!g_iWeaponsData[iAttackerLevel][IS_GREADE]) 
				{
					iAttackerLevel++;
					
					if(g_aLevelSteal_size)
					{
						PlaySound(pevAttacker, g_aLevelSteal, g_aLevelSteal_size);
					}
					
					bGiveNewWeapon = true;
				}
				else rg_give_item(id, "weapon_hegrenade", GT_APPEND);
			} else {
				iAttackerFrags++;
				if(iNeedFrags <= iAttackerFrags)
				{
					iAttackerFrags = 0;
					iAttackerLevel++;
					
					bGiveNewWeapon = true;
					
					if(g_aLevelUp_size)
					{
						PlaySound(pevAttacker, g_aLevelUp, g_aLevelUp_size);
					}
				}
				else rg_instant_reload_weapons(pevAttacker);
			}
		}
	}
	
	
	if(g_iWeaponsData[iAttackerLevel][IS_GREADE] && !bGrenadeSound && g_aLevelNade_size)
	{
		PlaySound(pevAttacker, g_aLevelNade, g_aLevelNade_size);
		bGrenadeSound = true;
	}
	
	if(g_iWeaponsData[iAttackerLevel][IS_KNIFE] && !bKnifeSound && g_aLevelKnife_size)
	{
		PlaySound(pevAttacker, g_aLevelKnife, g_aLevelKnife_size);
		bKnifeSound = true;
	}
	
	if(g_iLeaderLevel == iAttackerLevel && g_iLeaderId != pevAttacker)
	{
		new bool:bIsPlayerTied = false;
		for(new i = 1; i <= g_iTiedLeaderNum; i++)
		{
			if(g_iTiedLeaderId[i] == pevAttacker) 
			{
				bIsPlayerTied = true;
				break;
			}
		}
		
		if(!bIsPlayerTied)
		{
			// PLAY SOUND TIED LEADER TO EACH PLAYER
			if(g_aLevelTiedLead_size && g_iLeaderId)
			{
				PlaySound(pevAttacker, g_aLevelTiedLead, g_aLevelTiedLead_size);
				PlaySound(g_iLeaderId, g_aLevelTiedLead, g_aLevelTiedLead_size);
			}
			g_iTiedLeaderNum++;
			g_iTiedLeaderId[g_iTiedLeaderNum] = pevAttacker;
			
			get_user_name(pevAttacker, g_szTiedLeaderName, charsmax(g_szTiedLeaderName));
		}
	}
	
	if(iAttackerLevel > g_iLeaderLevel)
	{
		if(g_iLeaderId != pevAttacker)
		{
			// PLAY SOUND LOST LEAD
			if(g_aLevelLostLead_size && g_iLeaderId)
			{
				PlaySound(g_iLeaderId, g_aLevelLostLead, g_aLevelLostLead_size);
			}
			
			// PLAY SOUND LEAD
			if(g_aLevelLead_size)
			{
				PlaySound(pevAttacker, g_aLevelLead, g_aLevelLead_size);
			}
			g_iLeaderId = pevAttacker; 
			get_user_name(g_iLeaderId, g_szLeaderName, charsmax(g_szLeaderName));
		}
		ResetTiedLeader();
		g_iLeaderLevel = iAttackerLevel;
	}
	
	// Time to vote for map?
	if(iAttackerLevel == g_iLevelVote && !g_bVoteStarted)
	{
		g_bVoteStarted = true;		// just to vote once
		StartMapVote();
	}
	
	// Attacker can be winner
	if(iAttackerLevel >= g_iMaxLevels)
	{
		bWinner = true;
		
		remove_task(TASK_LEADER_DISPLAY);
		
		g_iWinnerId = pevAttacker;			// GAME OVER. Winner detected ;)
		g_iLastKilled = id;					// We have looser, too : D
		
		//PLAY WINNER SOUND
		if(g_aLevelWinner_size)
		{
			PlaySound(0, g_aLevelWinner, g_aLevelWinner_size);
		}
		
		// If default MOTD used let's show it
		if(g_bWinnerMotd)
		{
			set_task_ex(1.0, "ShowWinnerMotd");
		}
		set_task_ex(6.0, "DelayedMapChange");
		
		return HC_CONTINUE; 
	}
	
	if(bGiveNewWeapon) GiveBetterWeapon(pevAttacker, iAttackerLevel);

	iNeedFrags = g_iNeedFrags[iAttackerLevel];
	RefreshFragInformer(pevAttacker, iNeedFrags, iAttackerFrags, iAttackerLevel);
	
	g_iPlayerLevel[pevAttacker] = iAttackerLevel;
	g_iPlayerFrags[pevAttacker] = iAttackerFrags;
	
	if(bLevelDown) {
		if(g_iLeaderId == pevAttacker)
		{
			switch(g_iTiedLeaderNum)
			{
				case 0:
				{
					CalculateNewLeader();
				}
				case 1: 
				{
					g_iLeaderId = g_iTiedLeaderId[g_iTiedLeaderNum];
					g_iTiedLeaderId[g_iTiedLeaderNum] = 0;
					g_iTiedLeaderNum--;
					
					get_user_name(g_iLeaderId, g_szLeaderName, charsmax(g_szLeaderName));
				}
				default:
				{
					g_iLeaderId = g_iTiedLeaderId[g_iTiedLeaderNum];
					g_iTiedLeaderId[g_iTiedLeaderNum] = 0;
					g_iTiedLeaderNum--;

					get_user_name(g_iLeaderId, g_szLeaderName, charsmax(g_szLeaderName));
					get_user_name(g_iTiedLeaderId[g_iTiedLeaderNum], g_szTiedLeaderName, charsmax(g_szTiedLeaderName));
				}	
			}
		}
	}
	
	return HC_CONTINUE;
}

public DelayedMapChange()
{
	new szNextMap[32];
	get_cvar_string("amx_nextmap", szNextMap, charsmax(szNextMap));
	
	server_cmd("changelevel %s", szNextMap);
}

public CBasePlayer_Spawn(id)
{
	if(!is_user_alive(id))
	{
		ClearFlag(IsPlayerAlive, id);
		return HC_CONTINUE;
	}
	
	SetFlag(IsPlayerAlive, id);
	
	if(g_bRandomSpawn)
	{
		spawn_Preset(id);
	}
	
	new iLevel;
	
	if(g_bIsWarpUp) iLevel = g_iWarmUpLevel;
	else 
	{
		iLevel = g_iPlayerLevel[id];
		SendStatusIcon(id, iLevel);
		RefreshFragInformer(id, g_iNeedFrags[iLevel], g_iPlayerFrags[id], iLevel);
	}
	
	if(g_fProtectionTime) PlayerProtection(id);
	
	rg_remove_all_items(id, false);
	
	if(g_iArmorValue) rg_set_user_armor(id, g_iArmorValue, ARMOR_VESTHELM);
	
	rg_give_item(id, "weapon_knife", GT_APPEND);
	
	if(!iLevel || g_iWeaponsData[iLevel][IS_KNIFE]) return HC_CONTINUE;
	else if(g_iWeaponsData[iLevel][IS_GREADE]) rg_give_item(id, "weapon_hegrenade", GT_APPEND);
	else if(g_iWeaponsData[iLevel][IS_BAZOOKA]) gg_give_player_bazooka(id);
	else
	{
		rg_give_item(id, g_szWeaponLevelName[iLevel], GT_APPEND);
		rg_set_user_bpammo(id, rg_get_weapon_info(g_szWeaponLevelName[iLevel], WI_ID), g_iMaxBpAmmoLevel[iLevel]);
		ExecuteHamB(Ham_Weapon_RetireWeapon, get_member(id, m_rgpPlayerItems, 3));
	}	
		
	return HC_CONTINUE;
}

public EventGameCommencing()
{
	if(g_bGrenadeFF)
		set_cvar_num("mp_friendlyfire", 1);
	
	if(g_bGameCommencing) 
		return;
	
	g_bGameCommencing = true;
	
	set_cvar_num("mp_round_infinite", 1);
	
	if(g_iWarmUpTime)
	{
		g_bIsWarpUp = true;
		g_hookMsgRoundTime = register_message(g_MsgRoundTime, "Message_RoundTime");
		set_task_ex(1.0, "TaskCountdownRestart", _, _, _, SetTask_RepeatTimes, g_iWarmUpTime);
		set_task_ex(5.0, "WarmpupStart");
	}
}

public WarmpupStart()
{
	set_hudmessage(g_iColorRed, g_iColorGreen, g_iColorBlue, -1.0, 0.3, 0, 0.0, 5.0, 0.0, 0.0);
	ShowSyncHudMsg(0, CreateHudSyncObj(), "ПЕРЕД ИГРОЙ НАДО РАЗМЯТЬСЯ^nРАЗМИНКА!");
}

public EventAmmoX(id)
{
	new iLevel;

	if(g_bIsWarpUp) iLevel = g_iWarmUpLevel;
	else iLevel = g_iPlayerLevel[id];

	if(g_iWeaponsData[iLevel][IS_GREADE])
	{
		new iAmount = read_data(2);
		
		if(iAmount > 0)
		{
			remove_task(id + TASK_GIVEGRENADE_ID);
			return;
		}
		
		set_task_ex(g_fNadeRefreshTime, "GiveGrenade", id + TASK_GIVEGRENADE_ID);
		
		if(!CheckFlag(IsPlayerBot, id)) SendBarTime(id, floatround(g_fNadeRefreshTime, floatround_round));
	}
}

public EventCurWeapon(id)
{
	if(!CheckFlag(IsPlayerAlive, id)) return;

	// Пополняем патроны
	if(WeaponIdType:read_data(2) == WEAPON_AWP && read_data(3) > g_iAwpAmmo)
	{
		new wEnt = get_member(id, m_pActiveItem);
		rg_set_weapon_ammo(wEnt, g_iAwpAmmo);

		SendCurWeapon(id, g_iAwpAmmo, WEAPON_AWP, g_iAwpAmmo);
	}
}

public DisableProtection(id)
{
	id -= TASK_PROTECTION_ID;
	if(!is_user_alive(id)) return;
	set_entvar(id, var_takedamage, DAMAGE_YES);
	if(g_bNoShotProtection) set_member(id, m_bIsDefusing, false);
	if(g_bGlowEffect) UTIL_SetRendering(id, kRenderFxNone, 0.0, Float:{0.0, 0.0, 0.0}, kRenderNormal);
}

public TaskCountdownRestart()
{
	switch(	--g_iWarmUpTime)
	{
		case 0:
		{
			g_bIsWarpUp = false;
			unregister_message(g_MsgRoundTime, g_hookMsgRoundTime);
			set_cvar_num("sv_restart", 1);
			set_task_ex(2.0, "EndHud");
		}
	}
}

public EndHud()
{
	set_hudmessage(g_iColorRed, g_iColorGreen, g_iColorBlue, -1.0, 0.3, 0, 0.0, 5.0, 0.0, 0.0);
	ShowSyncHudMsg(0, CreateHudSyncObj(), "СПАСИБО ЗА РАЗМИНКУ!^nПРИЯТНОЙ ИГРЫ!");
}

public Message_RoundTime(msgid, dest, receiver) 
{
	const ARG_TIME_REMAINING = 1;
	if(g_bIsWarpUp) set_msg_arg_int(ARG_TIME_REMAINING, ARG_SHORT, g_iWarmUpTime);
	else set_msg_arg_int(ARG_TIME_REMAINING, ARG_SHORT, g_iPlayerFrags[receiver]);
}

public ShowLeader()
{
	if(!g_iLeaderId) return;
	
	set_hudmessage(g_iColorRed, g_iColorGreen, g_iColorBlue, g_fDisplayPosX, g_fDisplayPosY, 0, 0.0, REFRESH_INTERVAL, 0.0, 0.0);
	
	switch(g_iTiedLeaderNum)
	{
		case 0: ShowSyncHudMsg(0, g_iHudLeaderSync, "Лидер: %s (%d - %s)", g_szLeaderName, g_iLeaderLevel, g_szShortWeaponName[g_iLeaderLevel]);
		case 1: ShowSyncHudMsg(0, g_iHudLeaderSync, "Лидеры: %s + %s (%d - %s)", g_szLeaderName, g_szTiedLeaderName, g_iLeaderLevel, g_szShortWeaponName[g_iLeaderLevel]);
		default: ShowSyncHudMsg(0, g_iHudLeaderSync, "Лидеры: %s + %d (%d - %s)", g_szLeaderName, g_iTiedLeaderNum, g_iLeaderLevel, g_szShortWeaponName[g_iLeaderLevel]);
	}
}

public PlayWelcomeSound(id)
{
	if(g_aLevelWelcome_size && CheckFlag(IsPlayerConnected, id))
	{
		PlaySound(id, g_aLevelWelcome, g_aLevelWelcome_size);
	}
}

public GiveGrenade(id)
{
	remove_task(id);
	id -= TASK_GIVEGRENADE_ID;
	
	if(CheckFlag(IsPlayerAlive, id) && g_iWeaponsData[g_iPlayerLevel[id]][IS_GREADE])
		rg_give_item(id, "weapon_hegrenade", GT_APPEND);
}

public ShowWinnerMotd()
{
	new szNextMap[32];
	new szNewMotd[2048], iLen = 0, iMax = charsmax(szNewMotd);
	new szWinnerName[32], szLastKilledName[32], szWinnerColor[8], szLoserColor[8];
	get_user_name(g_iWinnerId, szWinnerName, charsmax(szWinnerName));
	get_user_name(g_iLastKilled, szLastKilledName, charsmax(szLastKilledName));
	
	get_team_color(g_iWinnerId, szWinnerColor, charsmax(szWinnerColor));
	get_team_color(g_iLastKilled, szLoserColor, charsmax(szLoserColor));
	
	get_cvar_string("amx_nextmap", szNextMap, charsmax(szNextMap));
	

	iLen = copy(szNewMotd, charsmax(szNewMotd), "<!DOCTYPE html><html><head><meta charset='utf-8' /><style type='text/css'>body \
	{font-family:consolas;color:#00FF00;background-color:#000000;font-size: 20pt;}");
	iLen += formatex(szNewMotd[iLen], iMax - iLen, "hr {border:body;background-color:#%s;color:#%s;height:2px;}	h3 {text-align:center;} #ul {text-align:center;} \
	wn {color:#%s;} ln {color:#%s;} wc {color:#FFFFFF;} nm {font-size: 17pt;}</style></head>",szWinnerColor, szWinnerColor, szWinnerColor, szLoserColor);
	iLen += formatex(szNewMotd[iLen], iMax - iLen, "<body><h3>[GUNGAME]</h3><div id='ul'><ul><hr><wn>%s</wn> <wc>победил!</wc><hr></ul></div>", szWinnerName);
	iLen += formatex(szNewMotd[iLen], iMax - iLen, "<h3>Последним был убит: <ln>%s</ln></h3><h3><wc><nm>Следующая карта:</nm></wc>%s</h3></body></html>", szLastKilledName, szNextMap);

	for(new id = 1; id <= MaxClients; id++)
	{
		if(!CheckFlag(IsPlayerConnected, id)) continue;
		
		show_motd(id, szNewMotd);
	}	
}

StartMapVote()
{
	if(contain(g_szCallPluginName, "fungun") != -1) {
		server_cmd("map_govote");
	} else if(contain(g_szCallPluginName, "mistrick") != -1) {
		if(g_bIsMapMModular) 
			mapm_start_vote(1); 
		else if(callfunc_begin("StartVote", "mapmanager.amxx") == 1) { 
			callfunc_push_int(0); 
			callfunc_end(); 
		}
	} else if(callfunc_begin(g_szVoteFunction, g_szCallPluginName) == 1) { 
		callfunc_end(); 
	}
}

PlayerProtection(id)
{
	if(!is_user_alive(id)) return;
	
	set_entvar(id, var_takedamage, DAMAGE_NO);
	
	if(g_bGlowEffect)
	{
		switch(TeamName:get_member(id, m_iTeam)) 
		{
			case TEAM_TERRORIST: UTIL_SetRendering(id, kRenderFxGlowShell, GLOW_THICK, Float:{RED_TEAM_COLOUR}, kRenderNormal);
			case TEAM_CT: UTIL_SetRendering(id, kRenderFxGlowShell, GLOW_THICK, Float:{BLUE_TEAM_COLOUR}, kRenderNormal);
		}
	}
	
	if(g_bProtectionBar) SendBarTime(id, floatround(g_fProtectionTime, floatround_round));
	
	if(g_bNoShotProtection) set_member(id, m_bIsDefusing, true);
	
	new TaskID = TASK_PROTECTION_ID + id;
	
	remove_task(TaskID);
	set_task_ex(g_fProtectionTime, "DisableProtection", TaskID);
}

ReadCfg()
{
	new szFilePath[64];
	
	get_localinfo("amxx_configsdir", szFilePath, charsmax(szFilePath));
	formatex(szFilePath, charsmax(szFilePath), "%s/re_gungame.ini",szFilePath);
	
	new FileHandle = fopen(szFilePath, "rt");
	
	if(!FileHandle)
	{
		new szErrorMsg[64];
		formatex(szErrorMsg, charsmax(szErrorMsg), "File doesnt exists: %s",szFilePath);
		
		return set_fail_state(szErrorMsg);
	}
	
	new szTemp[250], szKey[32], szValue[512];
	new iSection;
	
	while(!feof(FileHandle))
	{
		fgets(FileHandle, szTemp, charsmax(szTemp));
		trim(szTemp);
		
		if (szTemp[0] == '[')
		{
			iSection++;
			continue;
		}
		
		if(!szTemp[0] || szTemp[0] == ';' || szTemp[0] == '/') continue;
		
		strtok(szTemp, szKey, charsmax(szKey), szValue, charsmax(szValue), '=');
		trim(szKey);
		trim(szValue);

		switch(iSection)
		{
			case BASIC:
			{
				if(equal(szKey, "game_name"))
				{
					// ### EDIT
					// если 0, то отключено
					if(!equali(szValue, "0"))
						copy(g_szGameName, charsmax(g_szGameName), szValue);
				}
				if(equal(szKey, "vote_before"))
				{
					g_iLevelBeforeVote = str_to_num(szValue);
				}
				else if(equal(szKey, "vote_function"))
				{
					copy(g_szVoteFunction, charsmax(g_szVoteFunction), szValue);
				}
				else if(equal(szKey, "vote_plugin"))
				{
					copy(g_szCallPluginName, charsmax(g_szCallPluginName), szValue);
				}
				else if(equal(szKey, "save_type"))
				{
					g_iLevelSaveType = str_to_num(szValue);
				}
				else if(equal(szKey, "newplayer_level"))
				{
					g_iNewPlayerLevel = str_to_num(szValue);
				}
				else if(equal(szKey, "display_leader"))
				{
					g_bDisplayLeader = str_to_num(szValue) ? true : false;
				}
				else if(equal(szKey, "display_pos_x"))
				{
					g_fDisplayPosX = str_to_float(szValue);
				}
				else if(equal(szKey, "display_pos_y"))
				{
					g_fDisplayPosY = str_to_float(szValue);
				}
				else if(equal(szKey, "hud_color_red"))
				{
					g_iColorRed = str_to_num(szValue);
				}
				else if(equal(szKey, "hud_color_green"))
				{
					g_iColorGreen = str_to_num(szValue);
				}
				else if(equal(szKey, "hud_color_blue"))
				{
					g_iColorBlue = str_to_num(szValue);
				}
				else if(equal(szKey, "hud_pos_x"))
				{
					g_fHudPosX = str_to_float(szValue);
				}
				else if(equal(szKey, "hud_pos_y"))
				{
					g_fHudPosY = str_to_float(szValue);
				}
				else if(equal(szKey, "winner_motd"))
				{
					g_bWinnerMotd = str_to_num(szValue) ? true : false;
				}
				else if(equal(szKey, "afk_protection"))
				{
					g_iAfkProtection = str_to_num(szValue);
				}
				else if(equal(szKey, "nade_refresh"))
				{
					g_fNadeRefreshTime = str_to_float(szValue);
				}
				else if(equal(szKey, "give_armor"))
				{
					g_iArmorValue = str_to_num(szValue);
				}
				else if(equal(szKey, "awp_ammo"))
				{
					g_iAwpAmmo = str_to_num(szValue);
				}
				else if(equal(szKey, "hide_timer"))
				{
					g_bHideTimer = str_to_num(szValue) ? true : false;
				}
				else if(equal(szKey, "hide_cash"))
				{
					g_bHideCash = str_to_num(szValue) ? true : false;
				}
				else if(equal(szKey, "old_knife_system"))
				{
					g_bOldKnifeSystem = str_to_num(szValue) ? true : false;
				}
				else if(equal(szKey, "grenade_ff"))
				{
					g_bGrenadeFF = str_to_num(szValue) ? true : false;
				}
				else if(equal(szKey, "grenade_ff_lvl"))
				{
					g_bGrenadeFF_LVL = str_to_num(szValue) ? true : false;
				}
				else if(equal(szKey, "hud_system"))
				{
					g_bHudSystem = str_to_num(szValue) ? true : false;
				}
			}
			case DEATHMATCH:
			{
				if(equal(szKey, "protection_time"))
				{
					g_fProtectionTime = str_to_float(szValue);
				}
				else if(equal(szKey, "protection_bar"))
				{
					g_bProtectionBar = str_to_num(szValue) ? true : false;
				}
				else if(equal(szKey, "noshot_protection"))
				{
					g_bNoShotProtection = str_to_num(szValue) ? true : false;
				}
				else if(equal(szKey, "glow_effect"))
				{
					g_bGlowEffect = str_to_num(szValue) ? true : false;
				}
				else if(equal(szKey, "random_spawn"))
				{
					g_bRandomSpawn = str_to_num(szValue) ? true : false;
				}
			}
			case WARMUP:
			{
				if(equal(szKey, "warmup_time"))
				{
					g_iWarmUpTime = str_to_num(szValue);
				}
				else if(equal(szKey, "warmup_weapon"))
				{
					formatex(g_szWarmUpWeapon, charsmax(g_szWarmUpWeapon), "weapon_%s", szValue);
				}
			}
			case SOUND:
			{ 
				if(equal(szKey, "levelup"))
				{
					g_aLevelUp = ArrayCreate(SOUND_SIZE+1);
					CopyToArray(szValue, LEVEL_UP);
				}
				else if(equal(szKey, "leveldown"))
				{
					g_aLevelDown = ArrayCreate(SOUND_SIZE+1);
					CopyToArray(szValue, LEVEL_DOWN);
				}
				else if(equal(szKey, "levelsteal"))
				{
					g_aLevelSteal = ArrayCreate(SOUND_SIZE+1);
					CopyToArray(szValue, LEVEL_STEAL);
				}
				else if(equal(szKey, "nade"))
				{
					g_aLevelNade = ArrayCreate(SOUND_SIZE+1);
					CopyToArray(szValue, LEVEL_NADE);
				}
				else if(equal(szKey, "knife"))
				{
					g_aLevelKnife = ArrayCreate(SOUND_SIZE+1);
					CopyToArray(szValue, LEVEL_KNIFE);
				}
				else if(equal(szKey, "welcome"))
				{
					g_aLevelWelcome = ArrayCreate(SOUND_SIZE+1);
					CopyToArray(szValue, LEVEL_WELCOME);
				}
				else if(equal(szKey, "winner"))
				{
					g_aLevelWinner = ArrayCreate(SOUND_SIZE+1);
					CopyToArray(szValue, LEVEL_WINNER);
				}
				else if(equal(szKey, "lead"))
				{
					g_aLevelLead = ArrayCreate(SOUND_SIZE+1);
					CopyToArray(szValue, LEVEL_LEAD);
				}
				else if(equal(szKey, "tiedlead"))
				{
					g_aLevelTiedLead = ArrayCreate(SOUND_SIZE+1);
					CopyToArray(szValue, LEVEL_TIED_LEAD);
				}
				else if(equal(szKey, "lostlead"))
				{
					g_aLevelLostLead = ArrayCreate(SOUND_SIZE+1);
					CopyToArray(szValue, LEVEL_LOST_LEAD);
				}
			}
			case WEAPON:
			{
				if(equal(szKey, "glock18"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_glock18";
					SaveWeaponData(str_to_num(szValue), 120, "weapon_glock18", szKey);
				}
				else if(equal(szKey, "usp"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_usp";
					SaveWeaponData(str_to_num(szValue), 100, "weapon_usp", szKey);
				}
				else if(equal(szKey, "p228"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_p228";
					SaveWeaponData(str_to_num(szValue), 52, "weapon_p228", szKey);
				}
				else if(equal(szKey, "deagle"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_deagle";
					SaveWeaponData(str_to_num(szValue), 35, "weapon_deagle", szKey);
				}
				else if(equal(szKey, "fiveseven"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_fiveseven";
					SaveWeaponData(str_to_num(szValue), 100, "weapon_fiveseven", szKey);
				}
				else if(equal(szKey, "elite"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_elite";
					SaveWeaponData(str_to_num(szValue), 120, "weapon_elite", szKey);
				}
				else if(equal(szKey, "m3"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_m3";
					SaveWeaponData(str_to_num(szValue), 32, "weapon_m3", szKey);
				}
				else if(equal(szKey, "xm1014"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_xm1014";
					SaveWeaponData(str_to_num(szValue), 32, "weapon_xm1014", szKey);
				}
				if(equal(szKey, "tmp"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_tmp";
					SaveWeaponData(str_to_num(szValue), 120, "weapon_tmp", szKey);
				}
				else if(equal(szKey, "mac10"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_mac10";
					SaveWeaponData(str_to_num(szValue), 100, "weapon_mac10", szKey);
				}
				else if(equal(szKey, "mp5navy"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_mp5navy";
					SaveWeaponData(str_to_num(szValue), 120, "weapon_mp5navy", szKey);
				}
				else if(equal(szKey, "ump45"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_ump45";
					SaveWeaponData(str_to_num(szValue), 100, "weapon_ump45", szKey);
				}
				else if(equal(szKey, "p90"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_p90";
					SaveWeaponData(str_to_num(szValue), 100, "weapon_p90", szKey);
				}
				else if(equal(szKey, "galil"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_galil";
					SaveWeaponData(str_to_num(szValue), 90, "weapon_galil", szKey);
				}
				else if(equal(szKey, "famas"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_famas";
					SaveWeaponData(str_to_num(szValue), 90, "weapon_famas", szKey);
				}
				else if(equal(szKey, "ak47"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_ak47";
					SaveWeaponData(str_to_num(szValue), 90, "weapon_ak47", szKey);
				}
				if(equal(szKey, "scout"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_scout";
					SaveWeaponData(str_to_num(szValue), 90, "weapon_scout", szKey);
				}
				else if(equal(szKey, "m4a1"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_m4a1";
					SaveWeaponData(str_to_num(szValue), 90, "weapon_m4a1", szKey);
				}
				else if(equal(szKey, "sg552"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_sg552";
					SaveWeaponData(str_to_num(szValue), 90, "weapon_sg552", szKey);
				}
				else if(equal(szKey, "sg550"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_sg550";
					SaveWeaponData(str_to_num(szValue), 90, "weapon_sg550", szKey);
				}
				else if(equal(szKey, "g3sg1"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_g3sg1";
					SaveWeaponData(str_to_num(szValue), 90, "weapon_g3sg1", szKey);
				}
				else if(equal(szKey, "aug"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_aug";
					SaveWeaponData(str_to_num(szValue), 90, "weapon_aug", szKey);
				}
				else if(equal(szKey, "m249"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_m249";
					SaveWeaponData(str_to_num(szValue), 200, "weapon_m249", szKey);
				}
				else if(equal(szKey, "awp"))
				{
					g_szWeaponIcon[g_iMaxLevels] = "d_awp";
					SaveWeaponData(str_to_num(szValue), 30, "weapon_awp", szKey);
				}
				else if(equal(szKey, "hegrenade"))
				{
					g_iWeaponsData[g_iMaxLevels][IS_GREADE] = 1;
					g_szWeaponIcon[g_iMaxLevels] = "d_grenade";
					SaveWeaponData(str_to_num(szValue), 1, "weapon_hegrenade", szKey);
				}
				else if(equal(szKey, "knife"))
				{
					g_iWeaponsData[g_iMaxLevels][IS_KNIFE] = 1;
					g_szWeaponIcon[g_iMaxLevels] = "d_knife";
					SaveWeaponData(str_to_num(szValue), 1, "weapon_knife", szKey);
				}
				else if(equal(szKey, "bazooka"))
				{
					g_iWeaponsData[g_iMaxLevels][IS_BAZOOKA] = 1;
					g_szWeaponIcon[g_iMaxLevels] = "d_headshot";
					SaveWeaponData(str_to_num(szValue), 1, "weapon_bazooka", szKey);
				}
			}
		}
	}
	fclose(FileHandle);

	if(g_iMaxLevels > MAX_LEVELS)
		g_iMaxLevels = MAX_LEVELS;
	
	return PLUGIN_CONTINUE;
}

SaveWeaponData(iNeedFrags, iMaxAmmo, szWeaponName[], szShortName[])
{
	if(equali(szWeaponName,g_szWarmUpWeapon))
	{
		g_iWarmUpLevel = g_iMaxLevels;
	}
	g_iMaxBpAmmoLevel[g_iMaxLevels] = iMaxAmmo;
	formatex(g_szShortWeaponName[g_iMaxLevels], WEAPON_LEN, "%s", szShortName);
	formatex(g_szWeaponLevelName[g_iMaxLevels], WEAPON_LEN, "%s", szWeaponName);
	g_iNeedFrags[g_iMaxLevels] = iNeedFrags;
	g_iMaxLevels++;
}

CopyToArray(szValue[], iArray)
{
	new szTemp2[512], szSound[SOUND_SIZE + 1];
	copy(szTemp2, SOUND_SIZE, szValue);
	
	
	while(szTemp2[0])
	{
		strtok(szTemp2, szSound, SOUND_SIZE, szTemp2, charsmax(szTemp2), ';');
		trim(szSound);
		
		if(!file_exists(szSound)) 
		{
			log_to_file("GunGame_Error.txt", "File '%s' doesn't exist", szSound);
			continue;
		}
		
		switch(iArray)
		{
			case LEVEL_UP:
			{
				ArrayPushString(g_aLevelUp, szSound);
				g_aLevelUp_size++;
			}
			case LEVEL_DOWN:
			{
				ArrayPushString(g_aLevelDown, szSound);
				g_aLevelDown_size++;
			}
			case LEVEL_STEAL:
			{
				ArrayPushString(g_aLevelSteal, szSound);
				g_aLevelSteal_size++;
			}
			case LEVEL_NADE:
			{
				ArrayPushString(g_aLevelNade, szSound);
				g_aLevelNade_size++;
			}
			case LEVEL_KNIFE:
			{
				ArrayPushString(g_aLevelKnife, szSound);
				g_aLevelKnife_size++;
			}
			case LEVEL_WELCOME:
			{
				ArrayPushString(g_aLevelWelcome, szSound);
				g_aLevelWelcome_size++;
			}
			case LEVEL_WINNER:
			{
				ArrayPushString(g_aLevelWinner, szSound);
				g_aLevelWinner_size++;
			}
			case LEVEL_LEAD:
			{
				ArrayPushString(g_aLevelLead, szSound);
				g_aLevelLead_size++;
			}
			case LEVEL_TIED_LEAD:
			{
				ArrayPushString(g_aLevelTiedLead, szSound);
				g_aLevelTiedLead_size++;
			}
			case LEVEL_LOST_LEAD:
			{
				ArrayPushString(g_aLevelLostLead, szSound);
				g_aLevelLostLead_size++;
			}
		}
	}
}

SavePlayerData(id, CellNum)
{
	g_eSavedData[CellNum][iSavedLevel] = g_iPlayerLevel[id];
	g_eSavedData[CellNum][iSavedKills] = g_iPlayerFrags[id];
	g_eSavedData[CellNum][iTimeStamp] = _:get_gametime();
	
	switch(g_iLevelSaveType)
	{
		case 0: get_user_name(id, g_eSavedData[CellNum][szAuth], MAX_NAME_LENGTH);
		case 1: get_user_ip(id, g_eSavedData[CellNum][szAuth], MAX_IP_LENGTH);
		case 2: get_user_authid(id, g_eSavedData[CellNum][szAuth], MAX_AUTHID_LENGTH);
	}	
}

bool:GetPlayerData(id)
{
	new szAuthData[MAX_AUTHID_LENGTH+1];
	switch(g_iLevelSaveType)
	{
		case 0: get_user_name(id, szAuthData, MAX_NAME_LENGTH);
		case 1: get_user_ip(id, szAuthData, MAX_IP_LENGTH);
		case 2: get_user_authid(id, szAuthData, MAX_AUTHID_LENGTH);
	}
	
	for(new i; i < MAX_SAVES + 1; i++)
	{
		if(!g_eSavedData[i][iSavedLevel]) continue;

		if(!equal(szAuthData, g_eSavedData[i][szAuth])) continue; 
		
		g_iPlayerLevel[id] = g_eSavedData[i][iSavedLevel];
		g_iPlayerFrags[id] = g_eSavedData[i][iSavedKills];
		
		g_eSavedData[i][iSavedLevel] = 0;
		g_eSavedData[i][iSavedKills] = 0;
		g_eSavedData[i][iTimeStamp] = 0;
		arrayset(g_eSavedData[i][szAuth], 0, MAX_AUTHID_LENGTH + 1);
		
		return true;
	}
	return false;
}

SaveDisconnectPlayer(id)
{
	new iOldestStamp, iOldestPlayer;
	new bool:bSaved = false;
	
	for(new i; i < MAX_SAVES + 1; i++)
	{
		if(g_eSavedData[i][iTimeStamp] > iOldestStamp)
		{
			iOldestStamp = g_eSavedData[i][iTimeStamp];
			iOldestPlayer = i;
		}
		
		if(g_eSavedData[i][iSavedLevel]) continue;
		
		SavePlayerData(id, i);
		
		bSaved = true;
		
		break;
	}
	if(!bSaved)
	{
		SavePlayerData(id, iOldestPlayer);
	}
}

ResetTiedLeader()
{
	for(new i = 1; i <= g_iTiedLeaderNum; i++)
	{
		g_iTiedLeaderId[i] = 0;
	}
	g_iTiedLeaderNum = 0;
}

CalculateNewLeader()
{
	g_iLeaderId = 0;
	g_iLeaderLevel = 0;
	ResetTiedLeader();
	
	new iTempPlayerLevel;
	
	for(new id = 1; id <= MaxClients; id++)
	{
		if(!CheckFlag(IsPlayerConnected, id)) continue;
		
		iTempPlayerLevel = g_iPlayerLevel[id];
		if(iTempPlayerLevel == START_LEVEL) continue;
		
		if(iTempPlayerLevel > g_iLeaderLevel)
		{
			g_iLeaderLevel = iTempPlayerLevel;
			g_iLeaderId = id;
			ResetTiedLeader();
		}
		else if(iTempPlayerLevel == g_iLeaderLevel)
		{
			g_iTiedLeaderNum++;
			g_iTiedLeaderId[g_iTiedLeaderNum] = id;
		}	
	}
	
	if(g_iLeaderId) 
	{
		get_user_name(g_iLeaderId, g_szLeaderName, charsmax(g_szLeaderName));
		// PLAY SOUND LEAD
		if(g_aLevelLead_size)
		{
			PlaySound(g_iLeaderId, g_aLevelLead, g_aLevelLead_size);
		}
	}
	if(g_iTiedLeaderNum) 
	{
		get_user_name(g_iTiedLeaderId[g_iTiedLeaderNum], g_szTiedLeaderName, charsmax(g_szTiedLeaderName));
		
		for(new i = 1; i <= g_iTiedLeaderNum; i++)
		{
			if(g_aLevelTiedLead_size)
			{
				PlaySound(g_iTiedLeaderId[i], g_aLevelTiedLead, g_aLevelTiedLead_size);
			}
		}
	}
}

get_death_reason(const id, const pevAttacker, &iType)
{
	new iInflictor = get_entvar(id, var_dmg_inflictor);
	
	if(iInflictor == pevAttacker)
	{
		new iWpnId = get_member(get_member(pevAttacker, m_pActiveItem), m_iId);

		if(WeaponIdType:iWpnId == WEAPON_KNIFE) iType = KNIFE;
		else iType = BULLET;
	}
	else
	{
		if(get_member(id, m_bKilledByGrenade)) iType = GRENADE;
		else  iType = WORLD;
	}
}

GiveBetterWeapon(const id, const iLevel)
{
	if(iLevel <= g_iMaxLevels && CheckFlag(IsPlayerAlive, id))
	{
		DeleteStatusIcon(id, iLevel);
		SendStatusIcon(id, iLevel);
		if(!g_iWeaponsData[iLevel-1][IS_BAZOOKA])
			rg_remove_item(id, g_szWeaponLevelName[iLevel-1]);
		else
			rg_remove_items_by_slot(id, PRIMARY_WEAPON_SLOT);

		if(!g_iWeaponsData[iLevel][IS_BAZOOKA])
			rg_give_item(id, g_szWeaponLevelName[iLevel], GT_APPEND);
		else
			gg_give_player_bazooka(id);

		if(!g_iWeaponsData[iLevel][IS_GREADE] && !g_iWeaponsData[iLevel][IS_KNIFE] && !g_iWeaponsData[iLevel][IS_BAZOOKA])
		{
			rg_set_user_bpammo(id, rg_get_weapon_info(g_szWeaponLevelName[iLevel], WI_ID), g_iMaxBpAmmoLevel[iLevel]);
			ExecuteHamB(Ham_Weapon_RetireWeapon, get_member(id, m_rgpPlayerItems, 3));
		}
	}
}

PlaySound(const id, Array:aArray, aSize)
{
	if(CheckFlag(IsPlayerBot, id) || !CheckFlag(IsPlayerConnected, id)) return;
	
	new szSound[SOUND_SIZE];
	ArrayGetString(aArray, random_num(0, aSize-1), szSound, charsmax(szSound));
	
	if(IsMp3Format(szSound)) client_cmd(id, "mp3 play %s", szSound);
	else rh_emit_sound2(id, id, CHAN_STATIC, szSound[6], VOL_NORM, ATTN_NORM);
}

PrecacheSounds(Array:aArray, aSize)
{
	new szSound[SOUND_SIZE];
	new iLen = charsmax(szSound);
	
	for(new i; i < aSize; i++)
	{
		ArrayGetString(aArray, i, szSound, iLen);
		
		if(IsMp3Format(szSound)) precache_generic(szSound);
		else precache_sound(szSound[6]);
	}
}

RefreshFragInformer(const id, const iNeedFrags, const iAttackerFrags, const iLevel)
{
	if(CheckFlag(IsPlayerBot, id)) return;
	
	static iLeftFrags; iLeftFrags = iNeedFrags - iAttackerFrags;
	
	set_hudmessage(g_iColorRed, g_iColorGreen, g_iColorBlue, g_fHudPosX, g_fHudPosY, 0, 0.0, 60.0, 0.0, 0.0, -1);
	ShowSyncHudMsg(id, g_iHudFragSync, "Мой уровень: %d - %s^nУбийств до нового уровня: %d", iLevel, g_szShortWeaponName[iLevel], iLeftFrags);
}

readSpawns()
{
	new szMap[32], szConfig[32],  MapFile[256];

	get_mapname(szMap, 31);
	get_localinfo("amxx_configsdir", szConfig, charsmax(szConfig));
	format(MapFile, 255, "%s\gungame\%s.spawns.cfg", szConfig, szMap);
	g_iTotalSpawns = 0;

	if (file_exists(MapFile)) 
	{
		new szData[124], iLen;
		new iLine = 0;
		new pos[12][8];

		while(g_iTotalSpawns < MAX_SPAWNS && (iLine = read_file(MapFile , iLine , szData , 123 , iLen)) != 0) 
		{
			if (strlen(szData)<2 || szData[0] == '[')
				continue;

			parse(szData, pos[1], 7, pos[2], 7, pos[3], 7, pos[4], 7, pos[5], 7, pos[6], 7, pos[7], 7, pos[8], 7, pos[9], 7, pos[10], 7);

			// Origin
			g_iSpawnVecs[g_iTotalSpawns][0] = str_to_num(pos[1]);
			g_iSpawnVecs[g_iTotalSpawns][1] = str_to_num(pos[2]);
			g_iSpawnVecs[g_iTotalSpawns][2] = str_to_num(pos[3]);

			//Angles
			g_iSpawnAngles[g_iTotalSpawns][0] = str_to_num(pos[4]);
			g_iSpawnAngles[g_iTotalSpawns][1] = str_to_num(pos[5]);
			g_iSpawnAngles[g_iTotalSpawns][2] = str_to_num(pos[6]);

			// Teams
			g_iSpawnTeam[g_iTotalSpawns] = str_to_num(pos[7]);

			//v-Angles
			g_iSpawnVAngles[g_iTotalSpawns][0] = str_to_num(pos[8]);
			g_iSpawnVAngles[g_iTotalSpawns][1] = str_to_num(pos[9]);
			g_iSpawnVAngles[g_iTotalSpawns][2] = str_to_num(pos[10]);

			g_iTotalSpawns++;
		}
	}
	return PLUGIN_CONTINUE;
}

public spawn_Preset(id)
{
	if (g_iTotalSpawns < 2) return PLUGIN_CONTINUE;

	new Float:fSpawnVecs[3], Float:fSpawnAngles[3], Float:fSpawnVAngles[3];
	new Float:loc[32][3], locnum;
	new n, x, iNum, iFinal = -1;
	new team = get_member(id, m_iTeam);
	
	for(new pId = 1; pId <= MaxClients; pId++)
	{
		if(CheckFlag(IsPlayerAlive, pId) && pId != id && get_member(pId, m_iTeam) != team)
		{
			get_entvar(pId, var_origin, loc[locnum]);
			locnum++;
		}
	}
	
	iNum = 0;
	
	n = random_num(0, g_iTotalSpawns-1);
	
	while (iNum <= g_iTotalSpawns)
	{
		if(iNum == g_iTotalSpawns) break;
	
		if(n < g_iTotalSpawns - 1) n++;
		else n = 0;
	
		iNum++;

		if((team == 1 && g_iSpawnTeam[n] == 2) || (team == 2 && g_iSpawnTeam[n] == 1)) continue;

		iFinal = n;
		IVecFVec(g_iSpawnVecs[n], fSpawnVecs);
		
		for (x = 0; x < locnum; x++)
		{
			new Float:distance = get_distance_f(fSpawnVecs, loc[x]);
			if (distance < 500.0)
			{
				//invalidate
				iFinal = -1;
				break;
			}
		}

		if (iFinal == -1) continue;

		new trace = trace_hull(fSpawnVecs,1);
	
		if(trace) continue;

		if(locnum < 1) break;

		if(iFinal != -1) break;
	}

	if (iFinal != -1)
	{
		new Float:mins[3], Float:maxs[3], Float:size[3];
	
		IVecFVec(g_iSpawnVecs[iFinal], fSpawnVecs);
		IVecFVec(g_iSpawnAngles[iFinal], fSpawnAngles);
		IVecFVec(g_iSpawnVAngles[iFinal], fSpawnVAngles);
	
		get_entvar(id, var_mins, mins);
		get_entvar(id, var_maxs, maxs);
		
		size[0] = maxs[0] - mins[0];
		size[1] = maxs[1] - mins[1];
		size[2] = maxs[2] - mins[2];
		
		set_entvar(id, var_size, size);
		set_entvar(id, var_origin, fSpawnVecs);
		set_entvar(id, var_fixangle, 1);

		set_entvar(id, var_angles, fSpawnAngles);
		set_entvar(id, var_v_angle, fSpawnVAngles);
		set_entvar(id, var_fixangle, 1);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

stock get_team_color(const id, szColor[], const iLen)
{
	switch(TeamName:get_member(id, m_iTeam)) 
	{
		case TEAM_TERRORIST: formatex(szColor, iLen,"FF0000");
		case TEAM_CT: formatex(szColor, iLen,"1E90FF");
		default: formatex(szColor, iLen,"FFFFFF");
	}
}

stock GetHudHideFlags()
{
	new iFlags;

	if(g_bHideTimer)
		iFlags |= HIDE_HUD_TIMER;
	if(g_bHideCash)
		iFlags |= HIDE_HUD_CASH;

	return iFlags;
}

/* Messages */
/* thx fl0wer */
stock SendCurWeapon(id, isActive, any:weaponId, clipAmmo)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("CurWeapon");

	message_begin(MSG_ONE, msg, _, id);
	write_byte(isActive);
	write_byte(weaponId);
	write_byte(clipAmmo);
	message_end();
}

const ICON_ON  	= 1;
const ICON_OFF	= 0;

stock SendStatusIcon(id, iLevel)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("StatusIcon");
		
	message_begin(MSG_ONE, msg, {0,0,0}, id);
	write_byte(ICON_ON);
	write_string(g_szWeaponIcon[g_bHudSystem ? iLevel : (iLevel + 1)]);
	write_byte(g_iColorRed);
	write_byte(g_iColorGreen);
	write_byte(g_iColorBlue);
	message_end();
}

stock DeleteStatusIcon(id, iLevel)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("StatusIcon");
		
	message_begin(MSG_ONE, msg, {0,0,0}, id);
	write_byte(ICON_OFF);
	write_string(g_szWeaponIcon[g_bHudSystem ? (iLevel - 1) : iLevel]);
	message_end();
}

stock SendBarTime(id, duration = 0)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("BarTime");

	message_begin(MSG_ONE, msg, _, id);
	write_short(duration);
	message_end();
}

/* Util */
stock UTIL_SetRendering(id, mode = kRenderNormal, Float:amount = 0.0, Float:color[3] = NULL_VECTOR, fx = kRenderFxNone)
{
	set_entvar(id, var_rendermode, mode);
	set_entvar(id, var_renderamt, amount);
	set_entvar(id, var_rendercolor, color);
	set_entvar(id, var_renderfx, fx);
}