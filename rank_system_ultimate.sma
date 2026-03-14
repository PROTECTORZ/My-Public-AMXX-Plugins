#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <curl>
#include <reapi>
#include <ranksultimate_const>

#define PLUGIN_NAME 	    "Rank System Ultimate"
#define PLUGIN_VERSION 	    "2.8a"
#define PLUGIN_AUTHOR	    "Tornado_SW"
#define CVAR_NAME 		    "RankSystemUltimate"
#define DIRECTORY_NAME	    "rank_system_ultimate.txt"

new g_szOrder[MAX_ORDERS][MAX_NAME_LENGTH] = { "RSU_XP", "RSU_KILLS_C", "RSU_MVP", "RSU_ROUNDS_WON", "RSU_BOMBS_PLANTED", "RSU_BOMBS_EXPLODED", "RSU_BOMBS_DEFUSED", "RSU_PLAYED_TIME", "RSU_SKILL" }

new Handle:g_iSqlTuple, Handle:g_iSqlConnection
new Array:g_aRanks, Array:g_aSkills
new Trie:g_tRewards, Trie:g_tTeamRewards
new bool:g_blSqlFailed, bool:g_blMVP, bool:g_blGoodKill[MAX_PLAYERS + 1], bool:g_blLoggedTop15[MAX_PLAYERS + 1], g_blLoaded[MAX_PLAYERS + 1][2], bool:g_blLogged[MAX_PLAYERS + 1]
new HookChain:g_pCBasePlayer_Killed_Post, HookChain:g_pSV_WriteFullClientUpdate
new g_szDeathString[MAX_NAME_LENGTH], g_szSaveInfo[MAX_PLAYERS + 1][MAX_INFO_LENGTH], g_szName[MAX_PLAYERS + 1][MAX_NAME_LENGTH], g_szPlayerFile[MAX_PLAYERS + 1][MAX_USER_INFO_LENGTH]
new g_szSteamData[MAX_DATA_LENGTH], g_szAuthID64[MAX_PLAYERS + 1][MAX_NAME_LENGTH], g_szSteam[MAX_PLAYERS + 1][SteamData][MAX_USER_INFO_LENGTH]
new g_pPlayerData[MAX_PLAYERS + 1][PlayerData], g_pMapData[MAX_PLAYERS + 1][MapData], g_pAssistData[MAX_PLAYERS + 1][AssistData]
new g_iWeaponKills[MAX_PLAYERS + 1][MAX_WEAPONS_EX], g_iRoundKills[MAX_PLAYERS + 1], g_iRoundHs[MAX_PLAYERS + 1], g_iOrder[MAX_PLAYERS + 1], g_iOldRank[MAX_PLAYERS + 1]
new g_iHudInfo[MAX_PLAYERS + 1], g_iRankInfo[MAX_PLAYERS + 1]
new g_iTotalXp[MAX_PLAYERS + 1], g_iTotalTeamXp[MAX_PLAYERS + 1]
new g_iObject[3], g_iScreenFade, g_iRows, g_iPlantID, g_iRanks, g_iSkills, g_iAssistKiller, g_iMaxPlayers
new g_fwdLevelUpdated, g_fwdXPUpdated
new g_eSetting[Settings]

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(CVAR_NAME, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_dictionary(DIRECTORY_NAME)

	RegisterHookChain(RG_CBasePlayer_Spawn, 				"CBase_Player_Spawn",				true)
	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "SetClientUserInfoName", 			false)
	RegisterHookChain(RG_RoundEnd, 							"RG__RoundEnd", 					false)
	RegisterHookChain(RG_CBaseEntity_FireBullets3, 			"CBaseEntity_FireBullets", 			true)
	RegisterHookChain(RG_CBaseEntity_FireBuckshots, 		"CBaseEntity_FireBullets", 			true)
	RegisterHookChain(RG_CBasePlayer_TakeDamage, 			"CBasePlayer_TakeDamage", 			true)
	RegisterHookChain(RG_PlayerBlind, 						"RG__PlayerBlind", 					false)
	RegisterHookChain(RG_CBasePlayer_Killed, 				"CBasePlayer_Killed_Pre", 			false)
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, 		"CSGameRules_OnRoundFreezeEnd", 	false)
	RegisterHookChain(RG_PlantBomb, 						"RG_PlantBomb_Hook", 				true)
	RegisterHookChain(RG_CGrenade_DefuseBombEnd, 			"RG_CGrenade_DefuseBombEnd_Hook", 	true)
	RegisterHookChain(RG_CGrenade_ExplodeBomb, 				"RG_CGrenade_ExplodeBomb_Hook", 	true)
	RegisterHookChain(RG_CSGameRules_GoToIntermission, 		"CSGameRules_GoToIntermission", 	true)

	DisableHookChain((g_pCBasePlayer_Killed_Post = 	RegisterHookChain(RG_CBasePlayer_Killed, 		"CBasePlayer_Killed_Post", 	true)))
	DisableHookChain((g_pSV_WriteFullClientUpdate = RegisterHookChain(RH_SV_WriteFullClientUpdate, 	"SV_WriteFullClientUpdate", false)))

	register_concmd("rsu_give_xp", 		"cmdGiveXP", 		ADMIN_RCON, 	"<nick|#userid> <amount>")
	register_concmd("rsu_reset_stats", 	"cmdResetStats", 	ADMIN_RCON, 	"<nick>")
	register_concmd("rsu_reset_tables", "cmdResetTable", 	ADMIN_RCON)
	
	register_clcmd("say", "cmdTop")
	register_clcmd("say_team", "cmdTop")

	g_fwdLevelUpdated = CreateMultiForward("rsu_user_level_updated", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_fwdXPUpdated    = CreateMultiForward("rsu_user_xp_updated",    ET_STOP,   FP_CELL, FP_CELL, FP_CELL)

	g_iMaxPlayers = get_maxplayers() + 1
	g_iScreenFade = get_user_msgid("ScreenFade")
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")

	SqlInit()
}

public plugin_natives()
{
	register_library("ranksultimate")
	register_native("rsu_get_user_xp", 				"native_rsu_get_user_xp")
	register_native("rsu_get_user_next_xp", 		"native_rsu_get_user_next_xp")
	register_native("rsu_get_user_level", 			"native_rsu_get_user_level")
	register_native("rsu_get_user_kills", 			"native_rsu_get_user_kills")
	register_native("rsu_get_user_deaths", 			"native_rsu_get_user_deaths")
	register_native("rsu_get_user_headshots", 		"native_rsu_get_user_headshots")
	register_native("rsu_get_user_assists", 		"native_rsu_get_user_assists")
	register_native("rsu_get_user_shots", 			"native_rsu_get_user_shots")
	register_native("rsu_get_user_hits", 			"native_rsu_get_user_hits")
	register_native("rsu_get_user_damage", 			"native_rsu_get_user_damage")
	register_native("rsu_get_user_mvp", 			"native_rsu_get_user_mvp")
	register_native("rsu_get_user_rounds_won", 		"native_rsu_get_user_rounds_won")
	register_native("rsu_get_user_bombs_planted", 	"native_rsu_get_user_bombs_planted")
	register_native("rsu_get_user_bombs_defused", 	"native_rsu_get_user_bombs_defused")
	register_native("rsu_get_user_bombs_exploded", 	"native_rsu_get_user_bombs_exploded")
	register_native("rsu_get_user_played_time", 	"native_rsu_get_user_played_time")
	register_native("rsu_get_rank_by_level", 		"native_rsu_get_rank_by_level")
	register_native("rsu_get_user_rank", 			"native_rsu_get_user_rank")
	register_native("rsu_get_user_skill", 			"native_rsu_get_user_skill")
	register_native("rsu_get_user_skill_range", 	"native_rsu_get_user_skill_range")
	register_native("rsu_get_max_levels", 			"native_rsu_get_max_levels")
	register_native("rsu_get_user_server_rank", 	"native_rsu_get_user_server_rank")
	register_native("rsu_get_max_server_ranks", 	"native_rsu_get_max_server_ranks")
	register_native("rsu_give_user_xp",				"native_rsu_give_user_xp")
	register_native("rsu_give_team_xp",				"native_rsu_give_team_xp")
	register_native("rsu_is_level_loaded", 			"native_rsu_is_level_loaded")
	register_native("rsu_reset_stats", 				"native_rsu_reset_stats")
}

public native_rsu_get_user_xp(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][Xp]
}

public native_rsu_get_user_next_xp(iPlugin, iParams)
{
	new iLevel, eMaxRanks[RankInfo]
	for(new i = 1; i < g_iRanks - 1; i++)
	{
		ArrayGetArray(g_aRanks, i, eMaxRanks)

		if(g_pPlayerData[get_param(1)][Xp] >= eMaxRanks[RankXp])
		{
			iLevel++
		}
	}

	static eNextRank[RankInfo]
	ArrayGetArray(g_aRanks, iLevel + 1, eNextRank)

	return eNextRank[RankXp]
}

public native_rsu_get_user_level(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][Level] + 1
}

public native_rsu_get_user_kills(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][Kills]
}

public native_rsu_get_user_deaths(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][Deaths]
}

public native_rsu_get_user_headshots(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][Headshots]
}

public native_rsu_get_user_assists(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][Assists]
}

public native_rsu_get_user_shots(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][Shots]
}

public native_rsu_get_user_hits(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][Hits]
}

public native_rsu_get_user_damage(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][Damage]
}

public native_rsu_get_user_mvp(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][MVP]
}

public native_rsu_get_user_rounds_won(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][RoundsWon]
}

public native_rsu_get_user_bombs_planted(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][Planted]
}

public native_rsu_get_user_bombs_defused(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][Defused]
}

public native_rsu_get_user_bombs_exploded(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][Exploded]
}

public native_rsu_get_user_played_time(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][PlayedTime]
}

public native_rsu_get_rank_by_level(iPlugin, iParams)
{
	static eRank[RankInfo]
	ArrayGetArray(g_aRanks, get_param(1) - 1, eRank)

	set_string(2, eRank[RankName], get_param(3))
}

public native_rsu_get_user_rank(iPlugin, iParams)
{
	new iLevel, eMaxRanks[RankInfo]
	for(new i = 1; i < g_iRanks - 1; i++)
	{
		ArrayGetArray(g_aRanks, i, eMaxRanks)

		if(g_pPlayerData[get_param(1)][Xp] >= eMaxRanks[RankXp])
		{
			iLevel++
		}
	}

	static eRank[RankInfo]
	ArrayGetArray(g_aRanks, iLevel, eRank)

	set_string(2, eRank[RankName], get_param(3))
}

public native_rsu_get_user_skill(iPlugin, iParams)
{
	new iSkill, eMaxSkills[SkillInfo]
	for(new i = 1; i < g_iSkills; i++)
	{
		ArrayGetArray(g_aSkills, i, eMaxSkills)

		if(GetSkillRange(get_param(1)) >= eMaxSkills[SkillRange])
		{
			iSkill++
		}
	}

	static eSkill[SkillInfo]
	ArrayGetArray(g_aSkills, iSkill, eSkill)
	
	set_string(2, eSkill[SkillName], get_param(3))
}

public native_rsu_get_user_skill_range(iPlugin, iParams)
{
	return _:GetSkillRange(get_param(1))
}

public native_rsu_get_max_levels(iPlugin, iParams)
{
	return g_iRanks
}

public native_rsu_get_user_server_rank(iPlugin, iParams)
{
	return g_pPlayerData[get_param(1)][RankID]
}

public native_rsu_get_max_server_ranks(iPlugin, iParams)
{
	return g_iRows
}

public native_rsu_give_user_xp(iPlugin, iParams)
{
	new iXp = get_param(2)
	UpdateXpAndRank(get_param(1), iXp, false)
	return iXp
}

public native_rsu_give_team_xp(iPlugin, iParams)
{
	new iPlayers[MAX_PLAYERS], iPnum
	new iXp = get_param(2)

	switch(get_param(1))
	{
		case TEAM_T:
		{
			get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, "TERRORIST")

			for(new i; i < iPnum; i++)
			{
				UpdateXpAndRank(iPlayers[i], iXp, true)
				return iXp
			}
		}
		case TEAM_CT:
		{
			get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, "CT")

			for(new i; i < iPnum; i++)
			{
				UpdateXpAndRank(iPlayers[i], iXp, true)
				return iXp
			}
		}
		case TEAM_SPEC:
		{
			get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, "SPECTATOR")

			for(new i; i < iPnum; i++)
			{
				UpdateXpAndRank(iPlayers[i], iXp, true)
				return iXp
			}
		}
	}

	return iXp
}

public native_rsu_is_level_loaded(iPlugin, iParams)
{
	return g_blLoaded[get_param(1)][LOAD_STATS]
}

public native_rsu_reset_stats(iPlugin, iParams)
{
	ResetMySQLTables()
}

public plugin_precache()
{
	g_aRanks = ArrayCreate(RankInfo)
	g_aSkills = ArrayCreate(SkillInfo)

	g_tRewards = TrieCreate()
	g_tTeamRewards = TrieCreate()

	ReadFile()
}

public plugin_end()
{
	SQL_FreeHandle(g_iSqlConnection)
	SQL_FreeHandle(g_iSqlTuple)

	ArrayDestroy(g_aRanks)
	ArrayDestroy(g_aSkills)

	TrieDestroy(g_tRewards)
	TrieDestroy(g_tTeamRewards)
}

public SqlInit()
{
	g_iSqlTuple = SQL_MakeDbTuple(g_eSetting[MYSQL_HOST], g_eSetting[MYSQL_USER], g_eSetting[MYSQL_PASSWORD], g_eSetting[MYSQL_DATABASE])
	SQL_SetCharset(g_iSqlTuple, "utf8mb4")

	static szError[MAX_ITEM_LENGTH], iErrorCode
	g_iSqlConnection = SQL_Connect(g_iSqlTuple, iErrorCode, szError, charsmax(szError))

	if(g_iSqlConnection == Empty_Handle)
	{
		set_fail_state(szError)
	}

	static szQuery[5][MAX_QUERY_LENGTH + MAX_DATA_LENGTH]
	formatex(szQuery[0], charsmax(szQuery[]), "CREATE TABLE IF NOT EXISTS `%s` (Player VARCHAR(%i) NOT NULL, Nick VARCHAR(%i) NOT NULL, `Steam ID` VARCHAR(%i) NOT NULL, IP VARCHAR(%i) NOT NULL,\
	XP INT(%i) NOT NULL, `Rank XP` INT(%i) NOT NULL, `Next Rank XP` INT(%i) NOT NULL, Level INT(%i) NOT NULL, `Rank Name` VARCHAR(%i) NOT NULL, Kills INT(%i) NOT NULL, Deaths INT(%i) NOT NULL,\
	Headshots INT(%i) NOT NULL, Assists INT(%i) NOT NULL, Shots INT(%i) NOT NULL, Hits INT(%i) NOT NULL, Damage INT(%i) NOT NULL, Planted INT(%i) NOT NULL, Exploded INT(%i) NOT NULL,\
	Defused INT(%i) NOT NULL, MVP INT(%i) NOT NULL, `Rounds Won` INT(%i) NOT NULL, `Played Time` INT(%i) NOT NULL, `First Login` VARCHAR(%i) NOT NULL, `Last Login` VARCHAR(%i) NOT NULL,\
	Skill VARCHAR(%i) NOT NULL, `Skill Range` FLOAT(%i, 2) NOT NULL, Flags VARCHAR(%i) NOT NULL, Online INT(%i) NOT NULL, New INT(%i) NOT NULL, Steam INT(%i) NOT NULL, Avatar VARCHAR(%i) NOT NULL,\
	Profile VARCHAR(%i) NOT NULL, PRIMARY KEY (Player));", g_eSetting[MYSQL_TABLE], MAX_INFO_LENGTH, MAX_NAME_LENGTH, MAX_NAME_LENGTH, MAX_IP_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH,
	MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_NAME_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH,
	MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INFO_LENGTH, MAX_INFO_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INFO_LENGTH, MAX_INT_LENGTH,
	MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_USER_INFO_LENGTH, MAX_USER_INFO_LENGTH)
	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[0])

	formatex(szQuery[1], charsmax(szQuery[]), "CREATE TABLE IF NOT EXISTS `%s` (Player VARCHAR(%i) NOT NULL, `Weapon ID` INT(%i) NOT NULL, `Weapon Kills` INT(%i) NOT NULL);",
	g_eSetting[MYSQL_TABLE2], MAX_INFO_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH)
	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[1])

	formatex(szQuery[2], charsmax(szQuery[]), "CREATE TABLE IF NOT EXISTS `%s` (Player VARCHAR(%i) NOT NULL, Nick VARCHAR(%i) NOT NULL, `Steam ID` VARCHAR(%i) NOT NULL, IP VARCHAR(%i) NOT NULL,\
	`Map Name` VARCHAR(%i) DEFAULT 'n/a', `Map Kills` INT(%i) NOT NULL, `Map Deaths` INT(%i) NOT NULL, `Map MVP` INT(%i) NOT NULL, `Map XP` INT(%i) NOT NULL, Level INT(%i) NOT NULL,\
	`Team Win` INT(%i) DEFAULT '2', Flags VARCHAR(%i) NOT NULL, Online INT(%i) NOT NULL, New INT(%i) NOT NULL, Steam INT(%i) NOT NULL, Avatar VARCHAR(%i) NOT NULL, Profile VARCHAR(%i) NOT NULL);",
	g_eSetting[MYSQL_TABLE3], MAX_INFO_LENGTH, MAX_NAME_LENGTH, MAX_NAME_LENGTH, MAX_IP_LENGTH, MAX_MAPNAME_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH,
	MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INFO_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_USER_INFO_LENGTH, MAX_USER_INFO_LENGTH)
	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[2])

	formatex(szQuery[3], charsmax(szQuery[]), "UPDATE `%s` SET Online = '0'; TRUNCATE TABLE `%s`;", g_eSetting[MYSQL_TABLE], g_eSetting[MYSQL_TABLE3])
	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[3])

	formatex(szQuery[4], charsmax(szQuery[]), "ALTER TABLE `%s` CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci; ALTER TABLE `%s` CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;\
	ALTER TABLE `%s` CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;", g_eSetting[MYSQL_TABLE], g_eSetting[MYSQL_TABLE2], g_eSetting[MYSQL_TABLE3])
	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[4])
}

public QueryHandler(iFailState, Handle:iQuery, szError[], iErrorCode)
{
	SQL_IsFail(iFailState, iErrorCode, szError)
}

ReadFile()
{
	get_datadir(g_szSteamData, charsmax(g_szSteamData))
	format(g_szSteamData, charsmax(g_szSteamData), "%s/%s", g_szSteamData, "steamdata")

	if(!dir_exists(g_szSteamData))
	{
	    mkdir(g_szSteamData)
	}

	static szFile[MAX_USER_INFO_LENGTH]
	get_configsdir(szFile, charsmax(szFile))
	add(szFile, charsmax(szFile), "/rank_system_ultimate.ini")
	
	new iFile = fopen(szFile, "rt")
	
	if(iFile)
	{
		static szData[MAX_DATA_LENGTH + MAX_RESOURCE_PATH_LENGTH], szKey[MAX_RESOURCE_PATH_LENGTH], szValue[MAX_DATA_LENGTH], eRanks[RankInfo], eSkills[SkillInfo], iSection = SECTION_NONE

		while(!feof(iFile))
		{
			fgets(iFile, szData, charsmax(szData))
			trim(szData)
		
			switch(szData[0])
			{
				case ';', EOS, '#': continue
				case '[':
				{
					if(szData[strlen(szData) - 1] == ']')
					{
						switch(szData[1])
						{
							case 'M': iSection = SECTION_MYSQL
							case 'R': iSection = SECTION_RANKS
							case 'S': iSection = SECTION_SETTINGS
							case 'C': iSection = SECTION_COMMANDS
							case 'X': iSection = SECTION_REWARDS
						}

						if(szData[3] == 'i')
						{
							iSection = SECTION_SKILLS
						}
					}
					else continue
				}
				default:
				{
					if(iSection == SECTION_NONE)
					{
						continue
					}

					strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
					trim(szKey)
					trim(szValue)
					
					switch(iSection)
					{
						case SECTION_MYSQL:
						{
							if(equal(szKey, "MYSQL_HOST"))
							{
								copy(g_eSetting[MYSQL_HOST], charsmax(g_eSetting[MYSQL_HOST]), szValue)
							}
							else if(equal(szKey, "MYSQL_USER"))
							{
								copy(g_eSetting[MYSQL_USER], charsmax(g_eSetting[MYSQL_USER]), szValue)
							}
							else if(equal(szKey, "MYSQL_PASSWORD"))
							{
								copy(g_eSetting[MYSQL_PASSWORD], charsmax(g_eSetting[MYSQL_PASSWORD]), szValue)
							}
							else if(equal(szKey, "MYSQL_DATABASE"))
							{
								copy(g_eSetting[MYSQL_DATABASE], charsmax(g_eSetting[MYSQL_DATABASE]), szValue)
							}	
							else if(equal(szKey, "MYSQL_TABLE"))
							{
								copy(g_eSetting[MYSQL_TABLE], charsmax(g_eSetting[MYSQL_TABLE]), szValue)
							}
							else if(equal(szKey, "MYSQL_TABLE2"))
							{
								copy(g_eSetting[MYSQL_TABLE2], charsmax(g_eSetting[MYSQL_TABLE2]), szValue)
							}
							else if(equal(szKey, "MYSQL_TABLE3"))
							{
								copy(g_eSetting[MYSQL_TABLE3], charsmax(g_eSetting[MYSQL_TABLE3]), szValue)
							}
							else if(equal(szKey, "MYSQL_REALTIME"))
							{
								g_eSetting[MYSQL_REALTIME] = str_to_num(szValue)
							}
						}
						case SECTION_SETTINGS:
						{
							if(equal(szKey, "WEBSITE_LINK"))
							{
								copy(g_eSetting[WEBSITE_LINK], charsmax(g_eSetting[WEBSITE_LINK]), szValue)
							}
							else if(equal(szKey, "STEAM_API_KEY"))
							{
								copy(g_eSetting[STEAM_API_KEY], charsmax(g_eSetting[STEAM_API_KEY]), szValue)
							}
							else if(equal(szKey, "SAVE_TYPE"))
							{
								g_eSetting[SAVE_TYPE] = str_to_num(szValue)
							}
							else if(equal(szKey, "CHAT_PREFIX"))
							{
								copy(g_eSetting[CHAT_PREFIX], charsmax(g_eSetting[CHAT_PREFIX]), szValue)
								replace_string(g_eSetting[CHAT_PREFIX], charsmax(g_eSetting[CHAT_PREFIX]), "$1", "^1")
								replace_string(g_eSetting[CHAT_PREFIX], charsmax(g_eSetting[CHAT_PREFIX]), "$3", "^3")
								replace_string(g_eSetting[CHAT_PREFIX], charsmax(g_eSetting[CHAT_PREFIX]), "$4", "^4")
							}
							else if(equal(szKey, "RANK_INFO"))
							{
								g_eSetting[RANK_INFO] = str_to_num(szValue)
							}
							else if(equal(szKey, "RANK_BOTS"))
							{
								g_eSetting[RANK_BOTS] = str_to_num(szValue)
							}
							else if(equal(szKey, "TIME_NEW"))
							{
								g_eSetting[TIME_NEW] = str_to_num(szValue)
							}
							else if(equal(szKey, "DEFAULT_ORDER"))
							{
								g_eSetting[DEFAULT_ORDER] = str_to_num(szValue)
							}
							else if(equal(szKey, "MINIMUM_PLAYERS"))
							{
								g_eSetting[MINIMUM_PLAYERS] = str_to_num(szValue)
							}
							else if(equal(szKey, "TEAM_SET"))
							{
								g_eSetting[TEAM_SET] = str_to_num(szValue)
							}
							else if(equal(szKey, "HUD_ENABLE"))
							{
								g_eSetting[HUD_ENABLE] = str_to_num(szValue)
							}
							else if(equal(szKey, "HUD_TYPE"))
							{
								g_eSetting[HUD_TYPE] = str_to_num(szValue)

								if(!g_eSetting[HUD_TYPE])
								{
									g_iObject[RANK_HUD] = CreateHudSyncObj()
								}
							}
							else if(equal(szKey, "HUD_INFO"))
							{
								copy(g_eSetting[HUD_INFO], charsmax(g_eSetting[HUD_INFO]), szValue)
							}
							else if(equal(szKey, "HUD_INFO_MAX"))
							{
								copy(g_eSetting[HUD_INFO_MAX], charsmax(g_eSetting[HUD_INFO_MAX]), szValue)
							}
							else if(equal(szKey, "HUD_VALUES"))
							{
								new szHudValues[HudValues - 2][MAX_NUM_LENGTH]
								parse(szValue, szHudValues[HUD_COLOR1], charsmax(szHudValues[]), szHudValues[HUD_COLOR2], charsmax(szHudValues[]), szHudValues[HUD_COLOR3], charsmax(szHudValues[]),
								szHudValues[HUD_POS_X], charsmax(szHudValues[]), szHudValues[HUD_POS_Y], charsmax(szHudValues[]))
								
								for(new i; i < HudValues - 2; i++)
								{
									g_eSetting[HUD_VALUES][i] = _:str_to_float(szHudValues[i])
								}
							}
							else if(equal(szKey, "LEVEL_MESSAGE_TYPE"))
							{
								g_eSetting[LEVEL_MESSAGE_TYPE] = str_to_num(szValue)
							}
							else if(equal(szKey, "LEVELUP_EFFECTS"))
							{
								new szFade[ScreenValues][MAX_NUM_LENGTH]
								parse(szValue, szFade[SCREEN_COLOR1], charsmax(szFade[]), szFade[SCREEN_COLOR2], charsmax(szFade[]), szFade[SCREEN_COLOR3], charsmax(szFade[]), szFade[SCREEN_ALPHA],
								charsmax(szFade[]), szFade[SCREEN_HOLD_TIME], charsmax(szFade[]))
								
								for(new i; i < ScreenValues; i++)
								{
									g_eSetting[LEVELUP_EFFECTS][i] = _:str_to_float(szFade[i])
								}
							}
							else if(equal(szKey, "LEVELUP_SOUND"))
							{
								copy(g_eSetting[LEVELUP_SOUND], charsmax(g_eSetting[LEVELUP_SOUND]), szValue)
								if(szValue[0] != EOS) precache_sound(szValue)
							}
							else if(equal(szKey, "LEVELDN_EFFECTS"))
							{
								new szFade[ScreenValues][MAX_NUM_LENGTH]
								parse(szValue, szFade[SCREEN_COLOR1], charsmax(szFade[]), szFade[SCREEN_COLOR2], charsmax(szFade[]), szFade[SCREEN_COLOR3], charsmax(szFade[]), szFade[SCREEN_ALPHA],
								charsmax(szFade[]), szFade[SCREEN_HOLD_TIME], charsmax(szFade[]))
								
								for(new i; i < ScreenValues; i++)
								{
									g_eSetting[LEVELDN_EFFECTS][i] = _:str_to_float(szFade[i])
								}
							}
							else if(equal(szKey, "LEVELDN_SOUND"))
							{
								copy(g_eSetting[LEVELDN_SOUND], charsmax(g_eSetting[LEVELDN_SOUND]), szValue)
								if(szValue[0] != EOS) precache_sound(szValue)
							}
							else if(equal(szKey, "ASSIST_VALUES"))
							{
								new szAssist[AssistValues][MAX_NUM_LENGTH]
								parse(szValue, szAssist[ASSIST_MIN_DMG], charsmax(szAssist[]), szAssist[ASSIST_MONEY], charsmax(szAssist[]))
								
								for(new i; i < AssistValues; i++)
								{
									g_eSetting[ASSIST_VALUES][i] = str_to_num(szAssist[i])
								}
							}
							else if(equal(szKey, "XP_HUD_ENABLE"))
							{
								g_eSetting[XP_HUD_ENABLE] = str_to_num(szValue)
							}
							else if(equal(szKey, "XP_HUD_TEAM_ENABLE"))
							{
								g_eSetting[XP_HUD_TEAM_ENABLE] = str_to_num(szValue)
							}
							else if(equal(szKey, "XP_HUD_TYPE"))
							{
								g_eSetting[XP_HUD_TYPE] = str_to_num(szValue)

								if(!g_eSetting[XP_HUD_TYPE])
								{
									g_iObject[XP_HUD] = CreateHudSyncObj()
								}
							}
							else if(equal(szKey, "XP_HUD_TEAM_TYPE"))
							{
								g_eSetting[XP_HUD_TEAM_TYPE] = str_to_num(szValue)

								if(!g_eSetting[XP_HUD_TEAM_TYPE])
								{
									g_iObject[XP_TEAM_HUD] = CreateHudSyncObj()
								}
							}
							else if(equal(szKey, "XP_HUD_GET"))
							{
								copy(g_eSetting[XP_HUD_GET], charsmax(g_eSetting[XP_HUD_GET]), szValue)
							}
							else if(equal(szKey, "XP_HUD_TEAM_GET"))
							{
								copy(g_eSetting[XP_HUD_TEAM_GET], charsmax(g_eSetting[XP_HUD_TEAM_GET]), szValue)
							}
							else if(equal(szKey, "XP_HUD_LOSE"))
							{
								copy(g_eSetting[XP_HUD_LOSE], charsmax(g_eSetting[XP_HUD_LOSE]), szValue)
							}
							else if(equal(szKey, "XP_HUD_TEAM_LOSE"))
							{
								copy(g_eSetting[XP_HUD_TEAM_LOSE], charsmax(g_eSetting[XP_HUD_TEAM_LOSE]), szValue)
							}
							else if(equal(szKey, "XP_HUD_VALUES"))
							{
								new szHudValues[HudValues][MAX_NUM_LENGTH]
								parse(szValue, szHudValues[HUD_COLOR1], charsmax(szHudValues[]), szHudValues[HUD_COLOR2], charsmax(szHudValues[]), szHudValues[HUD_COLOR3], charsmax(szHudValues[]),
								szHudValues[HUD_POS_X], charsmax(szHudValues[]), szHudValues[HUD_POS_Y], charsmax(szHudValues[]), szHudValues[HUD_EFFECT], charsmax(szHudValues[]),
								szHudValues[HUD_HOLD_TIME], charsmax(szHudValues[]))
								
								for(new i; i < HudValues; i++)
								{
									g_eSetting[XP_HUD_VALUES][i] = _:str_to_float(szHudValues[i])
								}
							}
							else if(equal(szKey, "XP_HUD_TEAM_VALUES"))
							{
								new szHudValues[HudValues][MAX_NUM_LENGTH]
								parse(szValue, szHudValues[HUD_COLOR1], charsmax(szHudValues[]), szHudValues[HUD_COLOR2], charsmax(szHudValues[]), szHudValues[HUD_COLOR3], charsmax(szHudValues[]),
								szHudValues[HUD_POS_X], charsmax(szHudValues[]), szHudValues[HUD_POS_Y], charsmax(szHudValues[]), szHudValues[HUD_EFFECT], charsmax(szHudValues[]),
								szHudValues[HUD_HOLD_TIME], charsmax(szHudValues[]))
								
								for(new i; i < HudValues; i++)
								{
									g_eSetting[XP_HUD_TEAM_VALUES][i] = _:str_to_float(szHudValues[i])
								}
							}
							else if(equal(szKey, "MVP_HUD_ENABLE"))
							{
								g_eSetting[MVP_HUD_ENABLE] = str_to_num(szValue)
							}
							else if(equal(szKey, "MVP_HUD_TYPE"))
							{
								g_eSetting[MVP_HUD_TYPE] = str_to_num(szValue)
							}
							else if(equal(szKey, "MVP_HUD_VALUES"))
							{
								new szHudValues[HudValues - 2][MAX_NUM_LENGTH]
								parse(szValue, szHudValues[HUD_COLOR1], charsmax(szHudValues[]), szHudValues[HUD_COLOR2], charsmax(szHudValues[]), szHudValues[HUD_COLOR3], charsmax(szHudValues[]),
								szHudValues[HUD_POS_X], charsmax(szHudValues[]), szHudValues[HUD_POS_Y], charsmax(szHudValues[]))
								
								for(new i; i < HudValues - 2; i++)
								{
									g_eSetting[MVP_HUD_VALUES][i] = _:str_to_float(szHudValues[i])
								}
							}
						}
						case SECTION_COMMANDS:
						{
							if(equal(szKey, "STATS_COMMANDS"))
							{
								while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ','))
								{
									trim(szKey)
									trim(szValue)
									register_clcmd(szKey, "cmdStats")
								}
							}
							else if(equal(szKey, "XP_COMMANDS"))
							{
								while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ','))
								{
									trim(szKey)
									trim(szValue)
									register_clcmd(szKey, "cmdXp")
								}
							}
							else if(equal(szKey, "RANK_COMMANDS"))
							{
								while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ','))
								{
									trim(szKey)
									trim(szValue)
									register_clcmd(szKey, "cmdRank")
								}
							}
							else if(equal(szKey, "STATSVIEWER_COMMANDS"))
							{
								while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ','))
								{
									trim(szKey)
									trim(szValue)
									register_clcmd(szKey, "menuStatsViewer")
								}
							}
							else if(equal(szKey, "HUDINFO_COMMANDS"))
							{
								while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ','))
								{
									trim(szKey)
									trim(szValue)
									register_clcmd(szKey, "cmdHudInfo")
								}
							}
							else if(equal(szKey, "RANKINFO_COMMANDS"))
							{
								while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ','))
								{
									trim(szKey)
									trim(szValue)
									register_clcmd(szKey, "cmdRankInfo")
								}
							}
						}
						case SECTION_RANKS:
						{
							if(g_iRanks)
							{
								ArrayPushArray(g_aRanks, eRanks)
							}
							
							g_iRanks++
							copy(eRanks[RankName], charsmax(eRanks[RankName]), szKey)
							eRanks[RankXp] = str_to_num(szValue)
						}
						case SECTION_SKILLS:
						{
							if(g_iSkills)
							{
								ArrayPushArray(g_aSkills, eSkills)
							}

							g_iSkills++
							copy(eSkills[SkillName], charsmax(eSkills[SkillName]), szKey)
							eSkills[SkillRange] = _:str_to_float(szValue)
						}
						case SECTION_REWARDS:
						{
							new szReward[2][MAX_NUM_LENGTH]
							parse(szValue, szReward[XP_REWARD], charsmax(szReward[]), szReward[XP_TEAM_REWARD], charsmax(szReward[]))

							TrieSetCell(g_tRewards, szKey, str_to_num(szReward[XP_REWARD]))
							TrieSetCell(g_tTeamRewards, szKey, str_to_num(szReward[XP_TEAM_REWARD]))
							
							if(equal(szKey, "vip_flags"))
							{
								copy(g_eSetting[VIP_FLAGS], charsmax(g_eSetting[VIP_FLAGS]), szValue)
							}
						}
					}
				}
			}
		}

		if(g_iRanks)
		{
			ArrayPushArray(g_aRanks, eRanks)
		}

		if(g_iSkills)
		{
			ArrayPushArray(g_aSkills, eSkills)
		}

		fclose(iFile)
	}
}

public client_connect(id)
{
	g_iHudInfo[id] = 1
	g_iRankInfo[id] = 1

	static szInfo[2][MAX_NUM_LENGTH]
	if(get_user_info(id, "_hudinfo", szInfo[SETINFO_HUD], charsmax(szInfo[])))
	{
		g_iHudInfo[id] = szInfo[SETINFO_HUD][0] ? str_to_num(szInfo[SETINFO_HUD]) : 0
	}

	if(get_user_info(id, "_rankinfo", szInfo[SETINFO_RANK], charsmax(szInfo[])))
	{
		g_iRankInfo[id] = szInfo[SETINFO_RANK][0] ? str_to_num(szInfo[SETINFO_RANK]) : 0
	}
	
	get_user_info(id, "*sid", g_szAuthID64[id], charsmax(g_szAuthID64[]))
	formatex(g_szPlayerFile[id], charsmax(g_szPlayerFile[]), "%s/%s.txt", g_szSteamData, g_szAuthID64[id])
	curl_save_player_info(id, g_szPlayerFile[id], g_szAuthID64[id])
}

public client_putinserver(id)
{
	if(!g_eSetting[RANK_BOTS] && is_user_bot(id))
	{
		return  
	}

	GetMapInfo(id)
	set_task(1.0, "taskShowRank", id + TASK_RANK, .flags = "b")
	set_task(0.1, "taskShowHud",  id + TASK_HUD,  .flags = "b")
}

public curl_save_player_info(id, szFile[], szAuthID64[])
{
	new iData[2]; iData[0] = fopen(szFile, "wb"); iData[1] = id

	new CURL:iCurl = curl_easy_init()
	curl_easy_setopt(iCurl, CURLOPT_BUFFERSIZE, MAX_DATA_LENGTH)

	new szLink[MAX_USER_INFO_LENGTH]
	format(szLink, charsmax(szLink), "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=%s&steamids=%s&format=vdf", g_eSetting[STEAM_API_KEY], szAuthID64)
	curl_easy_setopt(iCurl, CURLOPT_URL, szLink)
	curl_easy_setopt(iCurl, CURLOPT_WRITEDATA, iData[0])
	curl_easy_setopt(iCurl, CURLOPT_WRITEFUNCTION, "write")
	curl_easy_perform(iCurl, "complite", iData, sizeof(iData))
}

public write(iData[], iSize, iNmemb, iFile)
{
	new iCurrentSize = iSize * iNmemb
	fwrite_blocks(iFile, iData, iCurrentSize, BLOCK_CHAR)
	return iCurrentSize
}

public complite(CURL:iCurl, CURLcode:iCode, iData[])
{
	fclose(iData[0])
	curl_easy_cleanup(iCurl)
	LoadStats(iData[1])
}

LoadStats(id)
{
	g_blLoaded[id][LOAD_STATS] = false 
	g_blLoaded[id][LOAD_KILLS] = false

	get_steamdata(id, g_szSteam[id][STEAM_AVATAR], charsmax(g_szSteam[][]), "avatarfull")
	get_steamdata(id, g_szSteam[id][STEAM_PROFILE], charsmax(g_szSteam[][]), "profileurl")

	if(contain(g_szSteam[id][STEAM_AVATAR], "http") != -1) replace_string(g_szSteam[id][STEAM_AVATAR], charsmax(g_szSteam[][]), "https", "http")
	if(contain(g_szSteam[id][STEAM_PROFILE], "http") != -1) replace_string(g_szSteam[id][STEAM_PROFILE], charsmax(g_szSteam[][]), "https", "http")

	set_task(0.1, "taskLoadStats", id)
}

public get_steamdata(const id, szBuffer[], iLen, szSteamData[])
{
	new iFile = fopen(g_szPlayerFile[id], "r")
	while(!feof(iFile)) 
	{
		new szFileData[MAX_DATA_LENGTH], szData[2][MAX_USER_INFO_LENGTH]

		fgets(iFile, szFileData, charsmax(szFileData))
		parse(szFileData, szData[0], charsmax(szData[]), szData[1], charsmax(szData[]))

		if(szData[0][0] == '{' || szData[0][0] == '}' || szData[0][0] == ' ' || equal(szData[0], "response") || equal(szData[0], "players") || equal(szData[0], "0"))
		{
			continue
		}

		if(equal(szSteamData, szData[0]))
		{
			formatex(szBuffer, iLen, szData[1])
		}
	}

	fclose(iFile)
}

public taskLoadStats(id)
{
	get_user_name(id, g_szName[id], charsmax(g_szName[]))

	switch(g_eSetting[SAVE_TYPE])
	{
		case SAVE_NAME: 	get_user_name(id, g_szSaveInfo[id], charsmax(g_szSaveInfo[]))
		case SAVE_IP: 		get_user_ip(id, g_szSaveInfo[id], charsmax(g_szSaveInfo[]), 1)
		case SAVE_STEAMID: 	get_user_authid(id, g_szSaveInfo[id], charsmax(g_szSaveInfo[]))
	}
	
	ResetStats(id)
	SqlSaveOrLoad(id, MYSQL_LOAD, g_szSaveInfo[id])
	SqlSaveOrLoadKills(id, MYSQL_LOAD, g_szSaveInfo[id])
	GetRows()
}

public client_disconnected(id)
{
	if(!g_eSetting[RANK_BOTS] && is_user_bot(id))
	{
		return  
	}

	g_blLogged[id] = false

	new iTask =  id + TASK_RANK
	new iTask2 = id + TASK_HUD

	if(task_exists(iTask))
	{
		remove_task(iTask)
	}
	
	if(task_exists(iTask2))
	{
		remove_task(iTask2)
	}

	arrayset(g_pAssistData[id][AssistDamage], 0, sizeof g_pAssistData[][AssistDamage])
	for(new i = 1; i < g_iMaxPlayers; i++) g_pAssistData[i][AssistDamage][id] = 0

	SqlSaveOrLoad(id, MYSQL_SAVE, g_szSaveInfo[id])

	if(!g_eSetting[MYSQL_REALTIME])
	{
		SqlSaveOrLoadKills(id, MYSQL_SAVE, g_szSaveInfo[id])
	}

	static szQuery[MAX_USER_INFO_LENGTH], szPlayer[2][MAX_NAME_LENGTH * 2]
	SQL_QuoteString(Empty_Handle, szPlayer[PLAYER], charsmax(szPlayer[]), g_szSaveInfo[id])
	SQL_QuoteString(Empty_Handle, szPlayer[NICK], charsmax(szPlayer[]), g_szName[id])

	formatex(szQuery, charsmax(szQuery), "UPDATE `%s` SET Online = '0' WHERE Player = '%s'; DELETE FROM `%s` WHERE Nick = '%s';", g_eSetting[MYSQL_TABLE], szPlayer[PLAYER],
	g_eSetting[MYSQL_TABLE3], szPlayer[NICK])
	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery)
}

public client_infochanged(id)
{
	get_user_info(id, "name", g_pAssistData[id][AssistName], charsmax(g_pAssistData[][AssistName]))
}

public CBase_Player_Spawn(id)
{
	if(is_user_alive(id))
	{
		g_blGoodKill[id] = true

		if(g_eSetting[RANK_INFO])
		{
			set_task(0.1, "taskCheckRank", id)
		}

		arrayset(g_pAssistData[id][AssistDamage], 0, sizeof g_pAssistData[][AssistDamage])
		for(new i = 1; i < g_iMaxPlayers; i++) g_pAssistData[i][AssistDamage][id] = 0
	}
}

public taskCheckRank(id)
{
	set_task(0.1, "taskSetRank", id)

	if(g_iOldRank[id] == g_pPlayerData[id][RankID] || !g_iOldRank[id] || !g_blLoaded[id][LOAD_STATS] || !g_pPlayerData[id][RankID] || !g_iRankInfo[id])
	{
		return
	}

	new bool:blTop15 = g_pPlayerData[id][RankID] <= 15
	if(g_iOldRank[id] > g_pPlayerData[id][RankID])
	{
		CPC(id, "%L", id, "RSU_GOT_UP_WITH", (g_iOldRank[id] - g_pPlayerData[id][RankID]))
	}
	else if(g_iOldRank[id] < g_pPlayerData[id][RankID])
	{
		CPC(id, "%L", id, "RSU_GOT_DOWN_WITH", (g_pPlayerData[id][RankID] - g_iOldRank[id]))
	}

	if(blTop15 && !g_blLoggedTop15[id])
	{
		CPC(id, "%L", id, "RSU_TOP15_LOGGED_IN")
		g_blLoggedTop15[id] = true
	}
	else if(!blTop15 && g_blLoggedTop15[id])
	{
		CPC(id, "%L", id, "RSU_TOP15_LOGGED_OUT")
		g_blLoggedTop15[id] = false
	}

	CPC(id, "%L", id, "RSU_RANK_NOW", g_pPlayerData[id][RankID], g_iRows)
}

public taskSetRank(id)
{
	g_iOldRank[id] = g_pPlayerData[id][RankID]
}

public SetClientUserInfoName(id, const szInfoBuffer[], const szNewName[])
{
	if(!g_eSetting[RANK_BOTS] && is_user_bot(id))
	{
		return  
	}

	static szQuery[MAX_USER_INFO_LENGTH], szPlayer[2][MAX_NAME_LENGTH * 2]
	SQL_QuoteString(Empty_Handle, szPlayer[PLAYER], charsmax(szPlayer[]), g_szSaveInfo[id])
	SQL_QuoteString(Empty_Handle, szPlayer[NICK], charsmax(szPlayer[]), g_szName[id])

	if(g_eSetting[SAVE_TYPE] == SAVE_NAME)
	{
		SqlSaveOrLoad(id, MYSQL_SAVE, g_szSaveInfo[id])
		SqlSaveOrLoadKills(id, MYSQL_SAVE, g_szSaveInfo[id])

		formatex(szQuery, charsmax(szQuery), "UPDATE `%s` SET Online = '0' WHERE Player = '%s'; DELETE FROM `%s` WHERE Nick = '%s';", g_eSetting[MYSQL_TABLE], szPlayer,
		g_eSetting[MYSQL_TABLE3], szPlayer[NICK])
		SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery)

		set_task(0.1, "taskLoadStats", id)
	}
	else 
	{
		formatex(szQuery, charsmax(szQuery), "DELETE FROM `%s` WHERE Nick = '%s';", g_eSetting[MYSQL_TABLE3], szPlayer[NICK])
		SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery)

		set_task(0.1, "taskGetPlayerInfo", id)
	}
}

public taskGetPlayerInfo(id)
{
	GetPlayerInfo(id, true)
	GetMapInfo(id)
}

public CSGameRules_OnRoundFreezeEnd()
{
	new iPlayers[MAX_PLAYERS], iPnum
	get_players_ex(iPlayers, iPnum)
	
	for(new i; i < iPnum; i++)
	{
		g_iRoundKills[iPlayers[i]] = 0
		g_iRoundHs[iPlayers[i]] = 0
	}

	g_blMVP = false
}

public RG__RoundEnd(WinStatus:iStatus, ScenarioEventEndRound:iEvent, Float:tmDelay)
{
	new i_Xp[eWinData], bWinTeam[TeamName], iPlayers[MAX_PLAYERS], iPnum
	switch (iEvent)
	{
		case ROUND_TERRORISTS_WIN, ROUND_HOSTAGE_NOT_RESCUED, ROUND_VIP_ASSASSINATED, ROUND_TARGET_BOMB:
		{
			i_Xp[TERR_WIN] = GetXpReward("t_win", XP_REWARD)
			i_Xp[CTs_LOSE] = GetXpReward("ct_lose", XP_REWARD)

			bWinTeam[TEAM_TERRORIST] = true
			bWinTeam[TEAM_CT] = false
		}
		case ROUND_CTS_WIN, ROUND_BOMB_DEFUSED, ROUND_ALL_HOSTAGES_RESCUED, ROUND_VIP_ESCAPED:
		{
			i_Xp[TERR_LOSE] = GetXpReward("t_lose", XP_REWARD)
			i_Xp[CTs_WIN] = GetXpReward("ct_win", XP_REWARD)

			bWinTeam[TEAM_TERRORIST] = false
			bWinTeam[TEAM_CT] = true
		}
	}

	get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, "TERRORIST")

	for(new i; i < iPnum; i++)
	{
		if(bWinTeam[TEAM_TERRORIST]) g_pPlayerData[iPlayers[i]][RoundsWon]++
		UpdateXpAndRank(iPlayers[i], bWinTeam[TEAM_TERRORIST] ? i_Xp[TERR_WIN] : i_Xp[TERR_LOSE], true)
	}

	get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, "CT")

	for(new i; i < iPnum; i++)
	{
		if(bWinTeam[TEAM_CT]) g_pPlayerData[iPlayers[i]][RoundsWon]++
		UpdateXpAndRank(iPlayers[i], bWinTeam[TEAM_CT] ? i_Xp[CTs_WIN] : i_Xp[CTs_LOSE], true)
	}

	set_task(0.1, "ShowMVP")
}

public CBaseEntity_FireBullets(const iEnt)
{
	if(is_user_connected(iEnt))
	{
		g_pPlayerData[iEnt][Shots]++
	}

	return HC_CONTINUE
}

public CBasePlayer_TakeDamage(iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageType)
{
	if(!is_user_connected(iAttacker) || !is_user_connected(iVictim) || !rg_is_player_can_takedamage(iAttacker, iVictim) || iAttacker == iVictim)
	{
		return HC_CONTINUE
	}

	g_pPlayerData[iAttacker][Hits]++
	g_pPlayerData[iAttacker][Damage] += floatround(flDamage)

	new Float:fHealth; get_entvar(iVictim, var_health, fHealth)
	if(flDamage > fHealth) flDamage = fHealth

	g_pAssistData[iAttacker][AssistDamage][iVictim] += floatround(flDamage)
	g_pAssistData[iAttacker][AssistDamageOnTime][iVictim] = get_gametime()

	return HC_CONTINUE
}

public RG__PlayerBlind(const iVictim, const Inflictor, const iAttacker, const Float:flFadeTime, const Float:flFadeHold, iAlpha, Float:flColor[3])
{
	if(!rg_is_user_blinded(iVictim))
	{
		g_pAssistData[iAttacker][IsFlashed][iVictim] = true

		new iArg[1]; iArg[0] = iVictim
		set_task(flFadeHold, "taskResetFlash", iAttacker, iArg, sizeof(iArg))
	}

	return HC_CONTINUE
}

public taskResetFlash(iArg[1], iAttacker)
{
	g_pAssistData[iAttacker][IsFlashed][iArg[0]] = false
}

public CBasePlayer_Killed_Pre(iVictim, iKiller, iShouldGib)
{
	new iTotalDamage, iAssistant, iMaxDamage, iPlayers[MAX_PLAYERS], iPnum, iXp, iTeamXp
	for(new iMax = 1; iMax < g_iMaxPlayers; iMax++)
	{
		if(is_user_connected(iMax))
		{
			if(iMax != iKiller)
			{
				if(g_pAssistData[iMax][AssistDamage][iVictim] > 0)
				{
					if(g_pAssistData[iMax][AssistDamage][iVictim] > iMaxDamage)
					{
						iAssistant = iMax
						iMaxDamage = g_pAssistData[iMax][AssistDamage][iVictim]
					}
				}

				if(g_pAssistData[iMax][IsFlashed][iVictim]) iAssistant = iMax
			}
			else if(g_pAssistData[iMax][AssistDamage][iVictim] == iMaxDamage) 
			{
				iAssistant = g_pAssistData[iMax][AssistDamageOnTime][iVictim] > g_pAssistData[iAssistant][AssistDamageOnTime][iVictim] ? iMax : iAssistant
			}

			iTotalDamage += g_pAssistData[iMax][AssistDamage][iVictim]
		}
	}
	if((float(iMaxDamage) / float(iTotalDamage)) * 100.0 < g_eSetting[ASSIST_VALUES][ASSIST_MIN_DMG]) iAssistant = 0

	if(iAssistant && iKiller != iVictim)
	{	
		new szName[2][MAX_NAME_LENGTH], iLen[2], iExcess
		copy(szName[1], charsmax(szName[]), g_pAssistData[iAssistant][AssistName])
		iLen[1] = strlen(szName[1])

		EnableHookChain(g_pSV_WriteFullClientUpdate)
		
		static const szWorldName[] = "world"
		new bool:bIsAssistantConnected = bool:is_user_connected(iAssistant)

		if(!is_user_valid(iKiller))
		{
			if(bIsAssistantConnected)
			{
				iExcess = iLen[1] - NAMES_LENGTH - (sizeof szWorldName)
				if(iExcess > 0) strclip(szName[1], iExcess)
				formatex(g_szDeathString, charsmax(g_szDeathString), "%s + %s", szWorldName, szName[1])

				g_iAssistKiller = iAssistant
				rh_update_user_info(iAssistant)
			}
		}
		else if(is_user_connected(iKiller))
		{
			g_pAssistData[iKiller][AssistDamage][iVictim] = 0
			
			copy(szName[0], charsmax(szName[]), g_pAssistData[iKiller][AssistName])
			iLen[0] = strlen(szName[0])

			new iLenSum = (iLen[0] + iLen[1])
			iExcess = iLenSum - NAMES_LENGTH

			if(iExcess > 0)
			{
				new iLongest = iLen[0] > iLen[1] ? 0 : 1
				new iShortest = iLongest == 1 ? 0 : 1

				if(float(iExcess) / float(iLen[iLongest]) > 0.60)
				{
					new iNewLongest = floatround(float(iLen[iLongest]) / float(iLenSum) * float(iExcess))
					strclip(szName[iLongest], iNewLongest)
					strclip(szName[iShortest], iExcess - iNewLongest)
				}
				else strclip(szName[iLongest], iExcess)
			}
			formatex(g_szDeathString, charsmax(g_szDeathString), "%s + %s", szName[0], szName[1])

			g_iAssistKiller = iKiller
			rh_update_user_info(g_iAssistKiller)
		}
		if(bIsAssistantConnected)
		{   
			g_pAssistData[iAssistant][AssistDamage][iVictim] = 0
			g_pAssistData[iAssistant][IsFlashed][iVictim] = false

			if(g_eSetting[ASSIST_VALUES][ASSIST_MONEY])
			{
				rg_add_account(iAssistant, g_eSetting[ASSIST_VALUES][ASSIST_MONEY])
			}

			g_pPlayerData[iAssistant][Assists]++
			UpdateXpAndRank(iAssistant, GetXpReward("assist", XP_REWARD), false)

			get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, rg_get_user_team(iAssistant) == TEAM_TERRORIST ? "TERRORIST" : rg_get_user_team(iAssistant) == TEAM_CT ? "CT" : "")
			for(new i; i < iPnum; i++)
			{
				UpdateXpAndRank(iPlayers[i], GetXpReward("assist", XP_TEAM_REWARD), true)
			}
		}

		DisableHookChain(g_pSV_WriteFullClientUpdate)
		if(g_iAssistKiller) EnableHookChain(g_pCBasePlayer_Killed_Post)
 	}

	if(!is_user_connected(iKiller) || !is_user_connected(iVictim))
	{
		return HC_CONTINUE
	}

	new szWeapon[MAX_NAME_LENGTH], WeaponIdType:iWeapon = rg_get_user_active_weapon(iKiller)
	if(iWeapon != WEAPON_NONE)
	{
		rg_get_weapon_info(iWeapon, WI_NAME, szWeapon, charsmax(szWeapon))
		replace_string(szWeapon, charsmax(szWeapon), "weapon_", "")
	}

	if (rg_get_user_team(iKiller) == rg_get_user_team(iVictim))
	{
		iXp += GetXpReward("teamkill", XP_REWARD)
		iTeamXp += GetXpReward("teamkill", XP_TEAM_REWARD)
		g_blGoodKill[iKiller] = false
	}

	if (iKiller == iVictim)
	{
		iXp += GetXpReward("suicide", XP_REWARD)
		iTeamXp += GetXpReward("suicide", XP_TEAM_REWARD)
		g_blGoodKill[iKiller] = false
	}

	if(g_blGoodKill[iKiller])
	{
		iXp += GetXpReward("kill", XP_REWARD)
		iTeamXp += GetXpReward("kill", XP_TEAM_REWARD)
		iXp += GetXpReward(szWeapon, XP_REWARD)
		iTeamXp += GetXpReward(szWeapon, XP_TEAM_REWARD)

		if(rg_user_killed_by_headshot(iVictim))
		{
			iXp += GetXpReward("headshot", XP_REWARD)
			iTeamXp += GetXpReward("headshot", XP_TEAM_REWARD)

			g_pPlayerData[iKiller][Headshots]++
			g_iRoundHs[iKiller]++
		}

		if(get_user_flags(iKiller) & read_flags(g_eSetting[VIP_FLAGS]))
		{
			iXp += GetXpReward("vip", XP_REWARD)
			iTeamXp += GetXpReward("vip", XP_TEAM_REWARD)
		}

		if(rg_is_user_blinded(iKiller))
		{
			iXp += GetXpReward("blind", XP_REWARD)
			iTeamXp += GetXpReward("blind", XP_TEAM_REWARD)
		}

		for(new i; i < MAX_WEAPONS_EX; i++)
		{
			if(equal(szWeapon, g_szWeapon[i]))
			{
				get_member(iVictim, m_bKilledByGrenade) ? g_iWeaponKills[iKiller][MAX_WEAPONS_EX - 1]++ : g_iWeaponKills[iKiller][i]++
			}
		}

		g_pPlayerData[iKiller][Kills]++
		g_iRoundKills[iKiller]++
	}

	g_pPlayerData[iVictim][Deaths]++
	UpdateXpAndRank(iKiller, iXp, false)

	GetMapInfo(iKiller)
	GetMapInfo(iVictim)

	if(g_eSetting[MYSQL_REALTIME])
	{
		SqlSaveOrLoadKills(iKiller, MYSQL_SAVE, g_szSaveInfo[iKiller])
		GetPlayerInfo(iVictim, false)
	}

	get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, rg_get_user_team(iKiller) == TEAM_TERRORIST ? "TERRORIST" : rg_get_user_team(iKiller) == TEAM_CT ? "CT" : "")
	for(new i; i < iPnum; i++)
	{
		UpdateXpAndRank(iPlayers[i], iTeamXp, true)
	}

	return HC_CONTINUE
}

public CBasePlayer_Killed_Post(iVictim, iKiller)
{
	DisableHookChain(g_pCBasePlayer_Killed_Post)

	new iAssistKiller = g_iAssistKiller; g_iAssistKiller = 0
	rh_update_user_info(iAssistKiller)
}

public SV_WriteFullClientUpdate(id, pBuffer)
{
	if(id == g_iAssistKiller)
	{
		set_key_value(pBuffer, "name", g_szDeathString)
	}
}

public Message_DeathMsg()
{
	new iWorld = get_msg_arg_int(1)
	if(iWorld == 0 && g_iAssistKiller)
	{
		set_msg_arg_int(1, ARG_BYTE, g_iAssistKiller)
	}
}

public RG_PlantBomb_Hook(const id)
{
	new iPlayers[MAX_PLAYERS], iPnum
	get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, "TERRORIST")

	for(new i; i < iPnum; i++)
	{
		UpdateXpAndRank(iPlayers[i], GetXpReward("bomb_plant", XP_TEAM_REWARD), true)
	}

	g_iPlantID = id
	g_pPlayerData[id][Planted]++
	UpdateXpAndRank(id, GetXpReward("bomb_plant", XP_REWARD), false)
}

public RG_CGrenade_DefuseBombEnd_Hook(const this, id, bool:blDefused)
{
	if(g_blMVP || !blDefused)
	{
		return
	}

	new iPlayers[MAX_PLAYERS], iPnum
	get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, "CT")
	
	for(new i; i < iPnum; i++)
	{
		UpdateXpAndRank(iPlayers[i], GetXpReward("bomb_defuse", XP_TEAM_REWARD), true)
	}

	g_pPlayerData[id][Defused]++
	GetMVP(id, BOMB_DEFUSE)
	UpdateXpAndRank(id, GetXpReward("bomb_defuse", XP_REWARD), false)
}

public RG_CGrenade_ExplodeBomb_Hook(const this)
{
	if(g_blMVP)
	{
		return
	}
	
	new iPlayers[MAX_PLAYERS], iPnum
	get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, "TERRORIST")
	
	for(new i; i < iPnum; i++)
	{
		UpdateXpAndRank(iPlayers[i], GetXpReward("bomb_explode", XP_TEAM_REWARD), true)
	}

	if(is_user_connected(g_iPlantID))
	{
		g_pPlayerData[g_iPlantID][Exploded]++
		GetMVP(g_iPlantID, BOMB_EXPLODE)
		UpdateXpAndRank(g_iPlantID, GetXpReward("bomb_explode", XP_REWARD), false)
	}
}

public taskShowRank(id)
{
	if(!g_eSetting[HUD_ENABLE])
	{
		return
	}

	id -= TASK_RANK
	
	new iTarget = id
	if(!is_user_alive(id))
	{
		iTarget = get_entvar(id, var_iuser2)
	}
	
	if(!iTarget || !g_iHudInfo[id])
	{
		return
	}
	
	new iRed = 			floatround(g_eSetting[HUD_VALUES][HUD_COLOR1])
	new iGreen = 		floatround(g_eSetting[HUD_VALUES][HUD_COLOR2])
	new iBlue = 		floatround(g_eSetting[HUD_VALUES][HUD_COLOR3])
	new Float:flPosX = 	g_eSetting[HUD_VALUES][HUD_POS_X]
	new Float:flPosY = 	g_eSetting[HUD_VALUES][HUD_POS_Y]

	if(iRed < 0) 	iRed = 		random(256)
	if(iGreen < 0) 	iGreen = 	random(256)
	if(iBlue < 0) 	iBlue = 	random(256)

	static szHudInfo[MAX_DATA_LENGTH], szReplace[MAX_RESOURCE_PATH_LENGTH]
	new bool:blMaxLevel = g_pPlayerData[iTarget][Level] == g_iRanks - 1

	if(blMaxLevel)
	{
		copy(szHudInfo, charsmax(szHudInfo), g_eSetting[HUD_INFO_MAX])
	}
	else
	{
		copy(szHudInfo, charsmax(szHudInfo), g_eSetting[HUD_INFO])
	}
	
	new iLevel, eMaxRanks[RankInfo]
	for(new i = 1; i < g_iRanks - 1; i++)
	{
		ArrayGetArray(g_aRanks, i, eMaxRanks)

		if(g_pPlayerData[iTarget][Xp] >= eMaxRanks[RankXp])
		{
			iLevel++
		}
	}

	static eRank[RankInfo], eNextRank[RankInfo]
	ArrayGetArray(g_aRanks, iLevel, eRank)
	ArrayGetArray(g_aRanks, iLevel + 1, eNextRank)

	new iSkill, eMaxSkills[SkillInfo], eLastSkill[SkillInfo]
	for(new i = 1; i < g_iSkills - 1; i++)
	{
		ArrayGetArray(g_aSkills, i, eMaxSkills)
		ArrayGetArray(g_aSkills, i + 1, eLastSkill)

		if(GetSkillRange(iTarget) >= eMaxSkills[SkillRange])
		{
			iSkill++
		}
	}

	static eSkill[SkillInfo], eNextSkill[SkillInfo]
	ArrayGetArray(g_aSkills, iSkill, eSkill)
	ArrayGetArray(g_aSkills, iSkill + 1, eNextSkill)

	if(contain(szHudInfo, "%name%") != -1)
	{
		replace_string(szHudInfo, charsmax(szHudInfo), "%name%", g_szName[iTarget])
	}

	if(contain(szHudInfo, "%xp%") != -1)
	{
		num_to_str(g_pPlayerData[iTarget][Xp], szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%xp%", szReplace)
	}

	if(contain(szHudInfo, "%level%") != -1)
	{
		num_to_str(g_pPlayerData[iTarget][Level] + 1, szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%level%", szReplace)
	}

	if(contain(szHudInfo, "%rank%") != -1)
	{
		formatex(szReplace, charsmax(szReplace), "%s", eRank[RankName])
		replace_string(szHudInfo, charsmax(szHudInfo), "%rank%", blMaxLevel ? "%next_rank%" : szReplace)
	}

	if(contain(szHudInfo, "%next_xp%") != -1)
	{
		num_to_str(eNextRank[RankXp], szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%next_xp%", szReplace)
	}

	if(contain(szHudInfo, "%next_level%") != -1)
	{
		num_to_str(g_pPlayerData[iTarget][Level] + 2, szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%next_level%", szReplace)
	}
	
	if(contain(szHudInfo, "%next_rank%") != -1)
	{
		replace_string(szHudInfo, charsmax(szHudInfo), "%next_rank%", eNextRank[RankName])
	}
	
	if(contain(szHudInfo, "%max_levels%") != -1)
	{
		num_to_str(g_iRanks, szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%max_levels%", szReplace)
	}
	
	if(contain(szHudInfo, "%server_rank%") != -1)
	{
		num_to_str(g_pPlayerData[iTarget][RankID], szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%server_rank%", szReplace)
	}

	if(contain(szHudInfo, "%max_server_ranks%") != -1)
	{
		num_to_str(g_iRows, szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%max_server_ranks%", szReplace)
	}

	if(contain(szHudInfo, "%skill%") != -1)
	{
		formatex(szReplace, charsmax(szReplace), "%s", eSkill[SkillName])
		replace_string(szHudInfo, charsmax(szHudInfo), "%skill%", GetSkillRange(id) >= eLastSkill[SkillRange] ? "%next_skill%" : szReplace)
	}
	
	if(contain(szHudInfo, "%skill_range%") != -1)
	{
		formatex(szReplace, charsmax(szReplace), "%.2f", GetSkillRange(iTarget))
		replace_string(szHudInfo, charsmax(szHudInfo), "%skill_range%", szReplace)
	}
	
	if(contain(szHudInfo, "%next_skill%") != -1)
	{
		replace_string(szHudInfo, charsmax(szHudInfo), "%next_skill%", eNextSkill[SkillName])
	}
	
	if(contain(szHudInfo, "%next_skill_range%") != -1)
	{
		formatex(szReplace, charsmax(szReplace), "%.2f", eNextSkill[SkillRange])
		replace_string(szHudInfo, charsmax(szHudInfo), "%next_skill_range%", szReplace)
	}

	if(contain(szHudInfo, "%minutes%") != -1)
	{
		num_to_str(((get_user_time(iTarget, 1) / 60) % 60), szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%minutes%", szReplace)
	}

	if(contain(szHudInfo, "%seconds%") != -1)
	{
		num_to_str((get_user_time(iTarget, 1) % 60), szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%seconds%", szReplace)
	}

	if(contain(szHudInfo, "%newline%") != -1)
	{
		replace_string(szHudInfo, charsmax(szHudInfo), "%newline%", "^n")
	}

	switch(g_eSetting[HUD_TYPE])
	{
		case 0: 
		{
			set_hudmessage(iRed, iGreen, iBlue, flPosX, flPosY, 0, 0.1, 1.0, 0.1, 0.1, -1)
			ShowSyncHudMsg(id, g_iObject[RANK_HUD], szHudInfo)
		}
		case 1: 
		{
			set_dhudmessage(iRed, iGreen, iBlue, flPosX, flPosY, 0, 0.1, 1.0, 0.1, 0.1)
			show_dhudmessage(id, szHudInfo)
		}
	}
}

public taskShowHud(id)
{
	id -= TASK_HUD

	new iXp = g_iTotalXp[id]
	new iTeamXp = g_iTotalTeamXp[id]

	if(iXp != 0 && g_eSetting[XP_HUD_ENABLE])
	{
		ShowHudMessage(id, iXp, false)
	}

	if(iTeamXp != 0 && g_eSetting[XP_HUD_TEAM_ENABLE])
	{
		ShowHudMessage(id, iTeamXp, true)
	}
}

public CSGameRules_GoToIntermission() 
{
	new iTeamWin
	new iWinT = get_member_game(m_iNumTerroristWins)
	new iWinCT = get_member_game(m_iNumCTWins)

	if(iWinT > iWinCT) 			iTeamWin = TERR_WIN
	else if(iWinT == iWinCT) 	iTeamWin = ROUND_DRAW
	else if(iWinT < iWinCT) 	iTeamWin = CTs_WIN

	static szQuery[MAX_QUERY_LENGTH], szMap[MAX_MAPNAME_LENGTH]
	get_mapname(szMap, charsmax(szMap))

	formatex(szQuery, charsmax(szQuery), "UPDATE `%s` SET `Map Name` = '%s', `Team Win` = '%i';", g_eSetting[MYSQL_TABLE3], szMap, iTeamWin)
	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery)

	new iPlayers[MAX_PLAYERS], iPnum
	get_players_ex(iPlayers, iPnum)

	for(new i; i < iPnum; i++)
	{
		set_task(0.01, "taskDelayMapEnd", iPlayers[i], .flags = "b")
	}

	message_begin(MSG_ALL, SVC_FINALE)
	write_string("")
	message_end()

	return HC_CONTINUE
}

public taskDelayMapEnd(id)
{
	static szMapEnd[MAX_DATA_LENGTH], szTitle[MAX_RESOURCE_PATH_LENGTH]

	if(is_user_steam(id)) 
	{
		formatex(szMapEnd, charsmax(szMapEnd), "<meta http-equiv=refresh content='0;%smapend.php?player=%s&style=1&default_order=%d&db_table1=%s&db_table2=%s&db_table3=%s'>",
		g_eSetting[WEBSITE_LINK], g_szSaveInfo[id], g_eSetting[DEFAULT_ORDER], g_eSetting[MYSQL_TABLE], g_eSetting[MYSQL_TABLE2], g_eSetting[MYSQL_TABLE3])
	}
	else
	{
		formatex(szMapEnd, charsmax(szMapEnd), "<body style='margin:0;'><iframe width='100%%' height='100%%' frameborder=0 scrolling='yes' align='center' src=\
		'%smapend.php?player=%s&style=0&default_order=%d&db_table1=%s&db_table2=%s&db_table3=%s'>", g_eSetting[WEBSITE_LINK], g_szSaveInfo[id], g_eSetting[DEFAULT_ORDER],
		g_eSetting[MYSQL_TABLE], g_eSetting[MYSQL_TABLE2], g_eSetting[MYSQL_TABLE3])
	}

	formatex(szTitle, charsmax(szTitle), "%L", id, "RSU_MATCH_END")
	show_motd(id, szMapEnd, szTitle)
}

public cmdTop(id) 
{
	new szArgs[MAX_INFO_LENGTH]
	read_args(szArgs, charsmax(szArgs))
	remove_quotes(szArgs)
	
	new iArgs = str_to_num(szArgs[4])
	if(equal(szArgs[0], "/top", 4))
	{
		cmdTopX(id, iArgs ? iArgs : 15, true)
		return PLUGIN_HANDLED
	}
	else if(equal(szArgs[0], "/bot", 4))
	{
		cmdTopX(id, iArgs ? iArgs : 15, false)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public cmdTopX(id, iTop, bool:blTop)
{
	static szTop15[MAX_DATA_LENGTH], szTitle[MAX_RESOURCE_PATH_LENGTH]

	if(is_user_steam(id)) 
	{
		formatex(szTop15, charsmax(szTop15), "<meta http-equiv=refresh content='0;%stop15.php?top=%d&player=%s&order=%d&default_order=%d&style=1&db_table1=%s&db_table2=%s&search='>",
		g_eSetting[WEBSITE_LINK], blTop ? iTop : (g_iRows - (iTop - 15)), g_szSaveInfo[id], g_eSetting[DEFAULT_ORDER], g_eSetting[DEFAULT_ORDER], g_eSetting[MYSQL_TABLE], g_eSetting[MYSQL_TABLE2])
	}
	else
	{
		formatex(szTop15, charsmax(szTop15), "<body style='margin:0;'><iframe width='100%%' height='100%%' frameborder=0 scrolling='yes' align='center' src=\
		'%stop15.php?top=%d&player=%s&order=%d&default_order=%d&style=0&db_table1=%s&db_table2=%s&search='>", g_eSetting[WEBSITE_LINK], blTop ? iTop : (g_iRows - (iTop - 15)), g_szSaveInfo[id],
		g_eSetting[DEFAULT_ORDER], g_eSetting[DEFAULT_ORDER], g_eSetting[MYSQL_TABLE], g_eSetting[MYSQL_TABLE2])
	}

	formatex(szTitle, charsmax(szTitle), "%L %d", id, blTop ? "RSU_TOP_HEADER" : "RSU_BOT_HEADER", iTop)
	show_motd(id, szTop15, szTitle)
}

public cmdXp(id)
{
	new eMaxRanks[RankInfo], iLevel
	for(new i = 1; i < g_iRanks - 1; i++)
	{
		ArrayGetArray(g_aRanks, i, eMaxRanks)

		if(g_pPlayerData[id][Xp] >= eMaxRanks[RankXp])
		{
			iLevel++
		}
	}

	static eRank[RankInfo], eNextRank[RankInfo]
	ArrayGetArray(g_aRanks, iLevel, eRank)
	ArrayGetArray(g_aRanks, iLevel + 1, eNextRank)

	if(g_pPlayerData[id][Level] != g_iRanks -1)
	{
		CPC(id, "%L", id, "RSU_XP_INFO", g_pPlayerData[id][Level] + 1, eRank[RankName], g_pPlayerData[id][Xp], eNextRank[RankXp], eNextRank[RankName])
	}
	else
	{
		CPC(id, "%L", id, "RSU_XP_INFO_MAX", g_pPlayerData[id][Level] + 1, eNextRank[RankName], g_pPlayerData[id][Xp])
	}

	return PLUGIN_HANDLED
}

public cmdRank(id)
{
	new iSkill, eMaxSkills[SkillInfo]
	for(new i = 1; i < g_iSkills; i++)
	{
		ArrayGetArray(g_aSkills, i, eMaxSkills)

		if(GetSkillRange(id) >= eMaxSkills[SkillRange])
		{
			iSkill = i
		}
	}

	static eSkill[SkillInfo]
	ArrayGetArray(g_aSkills, iSkill, eSkill)
	CPC(id, "%L", id, "RSU_RANK_INFO", g_pPlayerData[id][RankID], g_iRows, g_pPlayerData[id][Kills], g_pPlayerData[id][Headshots], eSkill[SkillName], GetSkillRange(id))

	return PLUGIN_HANDLED
}

public cmdStats(id)
{
	displayStats(id, id)
	return PLUGIN_HANDLED
}

displayStats(const id, const iPlayer)
{
	if(!is_user_connected(iPlayer))
	{
		return
	}

	static szStats[MAX_DATA_LENGTH], szTitle[MAX_RESOURCE_PATH_LENGTH]

	if(is_user_steam(id)) 
	{
		formatex(szStats, charsmax(szStats), "<meta http-equiv=refresh content='0;%suser.php?player=%s&me=%s&top=15&style=1&order=%d&default_order=%d&show=0&db_table1=%s&db_table2=%s&search=&page=1'>",
		g_eSetting[WEBSITE_LINK], g_szSaveInfo[iPlayer], g_szSaveInfo[id], g_eSetting[DEFAULT_ORDER], g_eSetting[DEFAULT_ORDER], g_eSetting[MYSQL_TABLE], g_eSetting[MYSQL_TABLE2])
	}
	else
	{
		formatex(szStats, charsmax(szStats), "<body style='margin:0;'><iframe width='100%%' height='100%%' frameborder=0 scrolling='yes' align='center' src=\
		'%suser.php?player=%s&me=%s&top=15&style=0&order=%d&default_order=%d&show=0&db_table1=%s&db_table2=%s&search=&page=1'>", g_eSetting[WEBSITE_LINK], g_szSaveInfo[iPlayer],
		g_szSaveInfo[id], g_eSetting[DEFAULT_ORDER], g_eSetting[DEFAULT_ORDER], g_eSetting[MYSQL_TABLE], g_eSetting[MYSQL_TABLE2])
	}
	
	formatex(szTitle, charsmax(szTitle), "%L", id, "RSU_RANK_STATS", iPlayer)
	show_motd(id, szStats, szTitle)
}

public cmdHudInfo(id)
{
	if(g_iHudInfo[id])
	{
		CPC(id, "%L", id, "RSU_HUDINFO_DISABLED")
		g_iHudInfo[id] = 0
	}
	else
	{
		CPC(id, "%L", id, "RSU_HUDINFO_ENABLED")
		g_iHudInfo[id] = 1
	}

	static szInfo[MAX_NUM_LENGTH]
	num_to_str(g_iHudInfo[id], szInfo, charsmax(szInfo))
	client_cmd(id, "setinfo _hudinfo %s", szInfo)

	return PLUGIN_HANDLED
}

public cmdRankInfo(id)
{
	if(g_iRankInfo[id])
	{
		CPC(id, "%L", id, "RSU_RANKINFO_DISABLED")
		g_iRankInfo[id] = 0
	}
	else
	{
		CPC(id, "%L", id, "RSU_RANKINFO_ENABLED")
		g_iRankInfo[id] = 1
	}

	static szInfo[MAX_NUM_LENGTH]
	num_to_str(g_iRankInfo[id], szInfo, charsmax(szInfo))
	client_cmd(id, "setinfo _rankinfo %s", szInfo)

	return PLUGIN_HANDLED
}

public cmdGiveXP(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 1))
	{
		return PLUGIN_HANDLED
	}
	
	static szPlayer[MAX_PLAYERS], szXp[MAX_NUM_LENGTH]
	read_argv(1, szPlayer, charsmax(szPlayer))
	read_argv(2, szXp, charsmax(szXp))
	
	new iPlayer = cmd_target(id, szPlayer, 0)
	new iXp = str_to_num(szXp)

	if(!iPlayer)
	{
		return PLUGIN_HANDLED
	}
 
 	if(szXp[0] != '-')
 	{
		client_print(id, print_console, "%L", id, "RSU_GIVE_XP_CONSOLE", iXp, iPlayer)
		CPC(0, "%L", id, "RSU_GIVE_XP", id, iXp, iPlayer)
	}
	else
	{
		client_print(id, print_console, "%L", id, "RSU_TAKE_XP_CONSOLE", iXp, iPlayer)
		CPC(0, "%L", id, "RSU_TAKE_XP", id, iXp, iPlayer)
	}

	UpdateXpAndRank(iPlayer, iXp, false)
	return PLUGIN_HANDLED
}

public cmdResetStats(id, iLevel, iCid)
{
	if (!cmd_access(id, iLevel, iCid, 1))
	{
		return PLUGIN_HANDLED
	}
	
	static szPlayer[MAX_PLAYERS]
	read_argv(1, szPlayer, charsmax(szPlayer))
	
	new iPlayer = cmd_target(id, szPlayer, 0)

	if(!iPlayer)
	{
		return PLUGIN_HANDLED
	}

	client_print(id, print_console, "%L", id, "RSU_RESET_STATS_CONSOLE", iPlayer)
	CPC(0, "%L", id, "RSU_RESET_STATS", id, iPlayer)

	ResetStats(iPlayer)
	UpdateRank(iPlayer)
	GetPlayerInfo(iPlayer, false)
	
	return PLUGIN_HANDLED
}

public cmdResetTable(id, iLevel, iCid)
{
	if (!cmd_access(id, iLevel, iCid, 1))
	{
		return PLUGIN_HANDLED
	}
	
	ResetMySQLTables()
	client_print(id, print_console, "%L", id, "RSU_RESET_TABLES")

	return PLUGIN_HANDLED
}

public menuStatsViewer(id)
{
	new szItem[MAX_ITEM_LENGTH], iPlayers[MAX_PLAYERS], iPnum, eMaxSkills[SkillInfo], iSkill, eSkill[SkillInfo], szSkill[MAX_NUM_LENGTH], iOrderNum, szKey[5]
	static szTitle[MAX_ITEM_LENGTH], szOrder[MAX_RESOURCE_PATH_LENGTH]
	formatex(szTitle, charsmax(szTitle), "%L", id, "RSU_STATS_TITLE")

	new iMenu = menu_create(szTitle, "handlerStats")

	formatex(szOrder, charsmax(szOrder), "%L", id, "RSU_ORDER_BY", id, g_szOrder[g_iOrder[id]])
	menu_additem(iMenu, szOrder)
	menu_addblank(iMenu, 0)

	get_players_ex(iPlayers, iPnum)

	switch(g_iOrder[id])
	{
		case ORDER_XP: 				SortCustom1D(iPlayers, iPnum, "SortPlayersByXp")
		case ORDER_KILLS: 			SortCustom1D(iPlayers, iPnum, "SortPlayersByTotalKills")
		case ORDER_MVPS: 			SortCustom1D(iPlayers, iPnum, "SortPlayersByMVPs")
		case ORDER_ROUNDS_WON: 		SortCustom1D(iPlayers, iPnum, "SortPlayersByRoundsWon")
		case ORDER_BOMBS_PLANTED: 	SortCustom1D(iPlayers, iPnum, "SortPlayersByBombsPlanted")
		case ORDER_BOMBS_EXPLODED: 	SortCustom1D(iPlayers, iPnum, "SortPlayersByBombsExploded")
		case ORDER_BOMBS_DEFUSED: 	SortCustom1D(iPlayers, iPnum, "SortPlayersByBombsDefused")
		case ORDER_PLAYED_TIME: 	SortCustom1D(iPlayers, iPnum, "SortPlayersByPlayedTime")
		case ORDER_SKILL: 			SortCustom1D(iPlayers, iPnum, "SortPlayersBySkill")
	}

	for(new i; i < iPnum; i++)
	{
		switch(g_iOrder[id])
		{
			case ORDER_XP: 				iOrderNum = g_pPlayerData[iPlayers[i]][Xp]
			case ORDER_KILLS: 			iOrderNum = g_pPlayerData[iPlayers[i]][Kills]
			case ORDER_MVPS: 			iOrderNum = g_pPlayerData[iPlayers[i]][MVP]
			case ORDER_ROUNDS_WON: 		iOrderNum = g_pPlayerData[iPlayers[i]][RoundsWon]
			case ORDER_BOMBS_PLANTED: 	iOrderNum = g_pPlayerData[iPlayers[i]][Planted]
			case ORDER_BOMBS_EXPLODED: 	iOrderNum = g_pPlayerData[iPlayers[i]][Exploded]
			case ORDER_BOMBS_DEFUSED: 	iOrderNum = g_pPlayerData[iPlayers[i]][Defused]
			case ORDER_PLAYED_TIME: 	iOrderNum = g_pPlayerData[iPlayers[i]][PlayedTime]
			case ORDER_SKILL:
			{
				for(new j = 1; j < g_iSkills; j++)
				{
					ArrayGetArray(g_aSkills, j, eMaxSkills)

					if(GetSkillRange(iPlayers[i]) >= eMaxSkills[SkillRange])
					{
						iSkill = j
					}
				}

				if(!GetSkillRange(iPlayers[i]))
				{
					iSkill = 0
				}

				ArrayGetArray(g_aSkills, iSkill, eSkill)
				copy(szSkill, charsmax(szSkill), eSkill[SkillName])
			}
		}

		num_to_str(iPlayers[i], szKey, charsmax(szKey))

		switch(g_iOrder[id])
		{
			case ORDER_PLAYED_TIME: formatex(szItem, charsmax(szItem), "\w%n \r[\y%d%L %d%L\r]", iPlayers[i], iOrderNum / 3600, id, "RSU_HOURS",(iOrderNum / 60) % 60, id, "RSU_MINUTES")
			case ORDER_SKILL: 		formatex(szItem, charsmax(szItem), "\w%n \r[\y%s %.2f\r]", iPlayers[i], szSkill, GetSkillRange(iPlayers[i]))
			default: 				formatex(szItem, charsmax(szItem), "\w%n \r[\y%d %L\r]", iPlayers[i], iOrderNum, id, g_szOrder[g_iOrder[id]])
		}

		menu_additem(iMenu, szItem, szKey)
	}
	
	if(menu_pages(iMenu) > 1)
	{
		static szPage[MAX_RESOURCE_PATH_LENGTH]
		formatex(szPage, charsmax(szPage), "%L", id, "RSU_STATS_PAGE")
		add(szTitle, charsmax(szTitle), szPage)
		menu_setprop(iMenu, MPROP_TITLE, szTitle)
	}

	menu_display(id, iMenu)
	return PLUGIN_HANDLED
}

public handlerStats(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
	{
		goto @MENU_DESTROY
	}
	
	if(!iItem)
	{
		if(g_iOrder[id] == MAX_ORDERS - 1)
		{
			g_iOrder[id] = 0
		}
		else g_iOrder[id]++

		menuStatsViewer(id)
		goto @MENU_DESTROY
	}

	static szData[MAX_NAME_LENGTH], iAccess, iCallback
	menu_item_getinfo(iMenu, iItem, iAccess, szData, charsmax(szData), .callback = iCallback)
	
	new iPlayer = str_to_num(szData)
	
	displayStats(id, iPlayer)
	menuStatsViewer(id)
	
	@MENU_DESTROY:
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

public SortPlayersByXp(id1, id2)
{
	return g_pPlayerData[id2][Xp] - g_pPlayerData[id1][Xp]
}

public SortPlayersByTotalKills(id1, id2)
{
	return g_pPlayerData[id2][Kills] - g_pPlayerData[id1][Kills]
}

public SortPlayersByMVPs(id1, id2)
{
	return g_pPlayerData[id2][MVP] - g_pPlayerData[id1][MVP]
}

public SortPlayersByRoundsWon(id1, id2)
{
	return g_pPlayerData[id2][RoundsWon] - g_pPlayerData[id1][RoundsWon]
}

public SortPlayersByBombsPlanted(id1, id2)
{
	return g_pPlayerData[id2][Planted] - g_pPlayerData[id1][Planted]
}

public SortPlayersByBombsExploded(id1, id2)
{
	return g_pPlayerData[id2][Exploded] - g_pPlayerData[id1][Exploded]
}

public SortPlayersByBombsDefused(id1, id2)
{
	return g_pPlayerData[id2][Defused] - g_pPlayerData[id1][Defused]
}

public SortPlayersByPlayedTime(id1, id2)
{
	return g_pPlayerData[id2][PlayedTime] - g_pPlayerData[id1][PlayedTime]
}

public SortPlayersBySkill(id1, id2)
{
    return _:GetSkillRange(id2) - _:GetSkillRange(id1)
}

public ShowMVP()
{	
	if(g_blMVP)
	{
		return
	}
	
	new iBest, iMostKills
	for(new i = 1; i < g_iMaxPlayers; i++)
	{
		if(is_user_connected(i))
		{
			if(g_iRoundKills[i] >= iMostKills)
			{
				iBest = i
				iMostKills = g_iRoundKills[i]
			}
		}
	}
	
	if(iMostKills && is_user_valid(iBest))
	{
		GetMVP(iBest, MOST_KILLS)
	}
}

public GetRows()
{
	static szQuery[MAX_USER_INFO_LENGTH]
	formatex(szQuery, charsmax(szQuery), "SELECT COUNT(*) FROM `%s`;", g_eSetting[MYSQL_TABLE])
	SQL_ThreadQuery(g_iSqlTuple, "GetRows_QueryHandler", szQuery)
}

public GetRows_QueryHandler(iFailState, Handle:iQuery, szError[], iErrcode, iData[], iDataSize)
{
	if(SQL_NumResults(iQuery))
	{
		g_iRows = SQL_ReadResult(iQuery, 0)
	}
}

ResetMySQLTables()
{
	static szQuery[MAX_USER_INFO_LENGTH]
	formatex(szQuery, charsmax(szQuery), "TRUNCATE TABLE `%s`; TRUNCATE TABLE `%s`;", g_eSetting[MYSQL_TABLE], g_eSetting[MYSQL_TABLE2])
	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery)

	new iPlayers[MAX_PLAYERS], iPnum
	get_players_ex(iPlayers, iPnum)

	for(new i; i < iPnum; i++)
	{
		ResetStats(iPlayers[i])

		for(new j; j < MAX_WEAPONS_EX; j++)
		{
			g_iWeaponKills[iPlayers[i]][j] = 0
		}
	}
}

public GetPlayerRank(id)
{
	new iData[1]; iData[0] = id

	static szQuery[MAX_QUERY_LENGTH], szPlayer[MAX_NAME_LENGTH * 2], szKey[MAX_DATA_LENGTH]
	SQL_QuoteString(Empty_Handle, szPlayer, charsmax(szPlayer), g_szSaveInfo[id])

	switch(g_eSetting[DEFAULT_ORDER])
	{
		case 0: formatex(szKey, charsmax(szKey), "XP DESC, Nick ASC")
		case 1: formatex(szKey, charsmax(szKey), "Nick ASC")
		case 2: formatex(szKey, charsmax(szKey), "Kills DESC, Nick ASC")
		case 3: formatex(szKey, charsmax(szKey), "Assists DESC, Nick ASC")
		case 4: formatex(szKey, charsmax(szKey), "Deaths DESC, Nick ASC")
		case 5: formatex(szKey, charsmax(szKey), "`Skill Range` DESC, Nick ASC")
		case 6: formatex(szKey, charsmax(szKey), "Headshots DESC, Nick ASC")
		case 7: formatex(szKey, charsmax(szKey), "Planted DESC, Nick ASC")
		case 8: formatex(szKey, charsmax(szKey), "Exploded DESC, Nick ASC")
		case 9: formatex(szKey, charsmax(szKey), "Defused DESC, Nick ASC")
		case 10: formatex(szKey, charsmax(szKey), "`Rounds Won` DESC, Nick ASC")
		case 11: formatex(szKey, charsmax(szKey), "MVP DESC, Nick ASC")
		case 12: formatex(szKey, charsmax(szKey), "Level DESC, XP DESC, Nick ASC")
		case 13: formatex(szKey, charsmax(szKey), "(Kills - Deaths) DESC, Assists DESC, Headshots DESC, MVP DESC, `Rounds Won` DESC, Planted DESC, Exploded DESC, Defused DESC, XP DESC, Nick ASC")
	}

	formatex(szQuery, charsmax(szQuery), "SELECT k.id, k.Player FROM (SELECT (@row_number:=@row_number+1) AS id, Player FROM (SELECT Player FROM `%s`, (SELECT @row_number:=0) AS rn ORDER BY \
	%s) AS subquery) AS k WHERE k.Player = '%s';", g_eSetting[MYSQL_TABLE], szKey, szPlayer)
	SQL_ThreadQuery(g_iSqlTuple, "GetPlayerRank_QueryHandler", szQuery, iData, sizeof(iData))
}

public GetPlayerRank_QueryHandler(iFailState, Handle:iQuery, szError[], iErrcode, iData[], iDataSize)
{
	new id = iData[0]
	if(SQL_NumResults(iQuery))
	{
		g_pPlayerData[id][RankID] = SQL_ReadResult(iQuery, 0)
	}
}

public SqlSaveOrLoad(id, iType, szInfo[])
{	
	if(g_blSqlFailed || szInfo[0] == EOS)
	{
		return
	}

	static szQuery[2][MAX_QUERY_LENGTH], szPlayer[2][MAX_NAME_LENGTH * 2], szIP[MAX_IP_LENGTH], eRank[RankInfo], eNextRank[RankInfo], eSkill[SkillInfo], szFlags[MAX_USER_INFO_LENGTH],
	szRankName[MAX_NAME_LENGTH], szLastLogin[MAX_INFO_LENGTH], szDate[2][MAX_INFO_LENGTH * 2]
	
	new iTime = g_pPlayerData[id][PlayedTime] + get_user_time(id)
	new eMaxRanks[RankInfo], eMaxSkills[SkillInfo], iLevel, iSkill

	if(g_pPlayerData[id][FirstLogin][0] == EOS)
	{
		get_time("%m/%d/%Y - %H:%M:%S", g_pPlayerData[id][FirstLogin], charsmax(g_pPlayerData[][FirstLogin]))
	}

	if(!g_blLogged[id])
	{
		g_blLogged[id] = true
		get_time("%m/%d/%Y - %H:%M:%S", szLastLogin, charsmax(szLastLogin))
	}

	for(new i = 1; i < g_iRanks - 1; i++)
	{
		ArrayGetArray(g_aRanks, i, eMaxRanks)

		if(g_pPlayerData[id][Xp] >= eMaxRanks[RankXp])
		{
			iLevel++
		}
	}

	for(new i = 1; i < g_iSkills; i++)
	{
		ArrayGetArray(g_aSkills, i, eMaxSkills)

		if(GetSkillRange(id) >= eMaxSkills[SkillRange])
		{
			iSkill = i
		}
	}

	ArrayGetArray(g_aRanks, iLevel, eRank)
	ArrayGetArray(g_aRanks, iLevel + 1, eNextRank)
	ArrayGetArray(g_aSkills, iSkill, eSkill)

	if(g_pPlayerData[id][Level] < g_iRanks - 1) copy(szRankName, charsmax(szRankName), eRank[RankName])
	else 										copy(szRankName, charsmax(szRankName), eNextRank[RankName])

	get_user_ip(id, szIP, charsmax(szIP), 1)
	get_flags(get_user_flags(id), szFlags, charsmax(szFlags))

	SQL_QuoteString(Empty_Handle, szPlayer[PLAYER], charsmax(szPlayer[]), szInfo)
	SQL_QuoteString(Empty_Handle, szPlayer[NICK], charsmax(szPlayer[]), g_szName[id])
	SQL_QuoteString(Empty_Handle, szDate[FIRST_LOGIN], charsmax(szDate[]), g_pPlayerData[id][FirstLogin])
	SQL_QuoteString(Empty_Handle, szDate[LAST_LOGIN], charsmax(szDate[]), szLastLogin)

	switch(iType)
	{
		case MYSQL_SAVE:
		{
			if(!g_blLoaded[id][LOAD_STATS])
			{
				return
			}

			formatex(szQuery[0], charsmax(szQuery[]), "UPDATE `%s` SET Nick = '%s', `Steam ID` = '%s', IP = '%s', XP = '%i', `Rank XP` = '%i', `Next Rank XP` = '%i', Level = '%i',\
			`Rank Name` = '%s', Kills = '%i', Deaths = '%i', Headshots = '%i', Assists = '%i', Shots = '%i', Hits = '%i', Damage = '%i', Planted = '%i', Exploded = '%i', Defused = '%i',\
			MVP = '%i', `Rounds Won` = '%i', `Played Time` = '%i', `First Login` = '%s', `Last Login` = '%s', Skill = '%s', `Skill Range` = '%.2f', Flags = '%s', Online  = '1', New = '%i',\
			Steam = '%i', Avatar = '%s', Profile = '%s' WHERE Player = '%s';", g_eSetting[MYSQL_TABLE], szPlayer[NICK], g_szAuthID64[id], szIP, g_pPlayerData[id][Xp], eRank[RankXp],
			eNextRank[RankXp], g_pPlayerData[id][Level], szRankName, g_pPlayerData[id][Kills], g_pPlayerData[id][Deaths], g_pPlayerData[id][Headshots], g_pPlayerData[id][Assists],
			g_pPlayerData[id][Shots], g_pPlayerData[id][Hits], g_pPlayerData[id][Damage], g_pPlayerData[id][Planted], g_pPlayerData[id][Exploded], g_pPlayerData[id][Defused],
			g_pPlayerData[id][MVP], g_pPlayerData[id][RoundsWon], iTime, szDate[FIRST_LOGIN], szDate[LAST_LOGIN], eSkill[SkillName], GetSkillRange(id), szFlags,
			iTime >= g_eSetting[TIME_NEW] ? 0 : 1, is_user_steam(id) ? 1 : 0, g_szSteam[id][STEAM_AVATAR], g_szSteam[id][STEAM_PROFILE], szPlayer[PLAYER])
			SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[0])
		}
		case MYSQL_LOAD:
		{
			new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT * FROM `%s` WHERE Player = '%s';", g_eSetting[MYSQL_TABLE], szPlayer[PLAYER])

			if(!SQL_Execute(iQuery))
			{
				static szError[MAX_ITEM_LENGTH]
				SQL_QueryError(iQuery, szError, charsmax(szError))
				log_amx(szError)
				return
			}

			if(SQL_NumResults(iQuery))
			{
				new iData[1]; iData[0] = id
				formatex(szQuery[0], charsmax(szQuery[]), "SELECT XP, Level, Kills, Deaths, Headshots, Assists, Shots, Hits, Damage, Planted, Exploded, Defused, MVP, `Rounds Won`,\
				`Played Time`, `First Login` FROM `%s` WHERE Player = '%s';", g_eSetting[MYSQL_TABLE], szPlayer[PLAYER])
				SQL_ThreadQuery(g_iSqlTuple, "LoadData_QueryHandler", szQuery[0], iData, sizeof(iData))
			}
			else
			{
				formatex(szQuery[1], charsmax(szQuery[]), "INSERT INTO `%s` (Player, Nick, `Steam ID`, IP, XP, `Rank XP`, `Next Rank XP`, Level, `Rank Name`, Kills, Deaths, Headshots, Assists,\
				Shots, Hits, Damage, Planted, Exploded, Defused, MVP, `Rounds Won`, `Played Time`, `First Login`, `Last Login`, Skill, `Skill Range`, Flags, Online, New, Steam, Avatar, Profile)\
				VALUES ('%s', '%s', '%s', '%s', '%i', '%i', '%i', '%i', '%s', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%s', '%s', '%s', '%.2f', '%s',\
				'1', '1', '%i', '%s', '%s');", g_eSetting[MYSQL_TABLE], szPlayer[PLAYER], szPlayer[NICK], g_szAuthID64[id], szIP, g_pPlayerData[id][Xp], eRank[RankXp], eNextRank[RankXp],
				g_pPlayerData[id][Level], szRankName, g_pPlayerData[id][Kills], g_pPlayerData[id][Deaths], g_pPlayerData[id][Headshots], g_pPlayerData[id][Assists], g_pPlayerData[id][Shots],
				g_pPlayerData[id][Hits], g_pPlayerData[id][Damage], g_pPlayerData[id][Planted], g_pPlayerData[id][Exploded], g_pPlayerData[id][Defused], g_pPlayerData[id][MVP],
				g_pPlayerData[id][RoundsWon], iTime, szDate[FIRST_LOGIN], szDate[LAST_LOGIN], eSkill[SkillName], GetSkillRange(id), szFlags, is_user_steam(id) ? 1 : 0,
				g_szSteam[id][STEAM_AVATAR], g_szSteam[id][STEAM_PROFILE])
				SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[1])

				g_blLoaded[id][LOAD_STATS] = true
				GetPlayerRank(id)
			}

			SQL_FreeHandle(iQuery)
		}
	}
}

public LoadData_QueryHandler(iFailState, Handle:iQuery, szError[], iErrcode, iData[], iDataSize)
{
	new id = iData[0]
	if(SQL_NumResults(iQuery))
	{
		g_pPlayerData[id][Xp] = 			SQL_ReadResult(iQuery, 0)
		g_pPlayerData[id][Level] = 			SQL_ReadResult(iQuery, 1)
		g_pPlayerData[id][Kills] = 			SQL_ReadResult(iQuery, 2)
		g_pPlayerData[id][Deaths] = 		SQL_ReadResult(iQuery, 3)
		g_pPlayerData[id][Headshots] = 		SQL_ReadResult(iQuery, 4)
		g_pPlayerData[id][Assists] = 		SQL_ReadResult(iQuery, 5)
		g_pPlayerData[id][Shots] = 			SQL_ReadResult(iQuery, 6)
		g_pPlayerData[id][Hits] = 			SQL_ReadResult(iQuery, 7)
		g_pPlayerData[id][Damage] = 		SQL_ReadResult(iQuery, 8)
		g_pPlayerData[id][Planted] = 		SQL_ReadResult(iQuery, 9)
		g_pPlayerData[id][Exploded] = 		SQL_ReadResult(iQuery, 10)
		g_pPlayerData[id][Defused] = 		SQL_ReadResult(iQuery, 11)
		g_pPlayerData[id][MVP] = 			SQL_ReadResult(iQuery, 12)
		g_pPlayerData[id][RoundsWon] = 		SQL_ReadResult(iQuery, 13)
		g_pPlayerData[id][PlayedTime] = 	SQL_ReadResult(iQuery, 14)

		SQL_ReadResult(iQuery, 15, g_pPlayerData[id][FirstLogin], charsmax(g_pPlayerData[][FirstLogin]))
		
		g_blLoaded[id][LOAD_STATS] = true
		GetPlayerInfo(id, true)
	}
}

public SqlSaveOrLoadKills(id, iType, szInfo[])
{	
	if(!g_eSetting[RANK_BOTS] && is_user_bot(id) || g_blSqlFailed || szInfo[0] == EOS)
	{
		return  
	}

	static szQuery[2][MAX_USER_INFO_LENGTH], szPlayer[MAX_NAME_LENGTH * 2]
	SQL_QuoteString(Empty_Handle, szPlayer, charsmax(szPlayer), szInfo)

	switch(iType)
	{
		case MYSQL_SAVE:
		{
			if(!g_blLoaded[id][LOAD_KILLS])
			{
				return
			}

			for(new i; i < MAX_WEAPONS_EX; i++)
			{
				formatex(szQuery[0], charsmax(szQuery[]), "UPDATE `%s` SET `Weapon Kills` = '%i' WHERE Player = '%s' AND `Weapon ID` = '%i';", g_eSetting[MYSQL_TABLE2], g_iWeaponKills[id][i],
				szPlayer, i)
				SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[0])
			}
		}
		case MYSQL_LOAD:
		{
			new Handle:iQuery = SQL_PrepareQuery(g_iSqlConnection, "SELECT * FROM `%s` WHERE Player = '%s';", g_eSetting[MYSQL_TABLE2], szPlayer)

			if(!SQL_Execute(iQuery))
			{
				static szError[MAX_ITEM_LENGTH]
				SQL_QueryError(iQuery, szError, charsmax(szError))
				log_amx(szError)
				return
			}

			if(SQL_NumResults(iQuery))
			{
				new iData[1]; iData[0] = id
				formatex(szQuery[0], charsmax(szQuery[]), "SELECT `Weapon Kills` FROM `%s` WHERE Player = '%s' ORDER BY `Weapon ID` ASC;", g_eSetting[MYSQL_TABLE2], szPlayer)
				SQL_ThreadQuery(g_iSqlTuple, "LoadKills_QueryHandler", szQuery[0], iData, sizeof(iData))
			}
			else
			{
				for(new i; i < MAX_WEAPONS_EX; i++)
				{
					formatex(szQuery[1], charsmax(szQuery[]), "INSERT INTO `%s` (Player, `Weapon ID`, `Weapon Kills`) VALUES ('%s', '%i', '0');", g_eSetting[MYSQL_TABLE2], szPlayer, i)
					SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[1])
				}

				g_blLoaded[id][LOAD_KILLS] = true
			}

			SQL_FreeHandle(iQuery)
		}
	}
}

public LoadKills_QueryHandler(iFailState, Handle:iQuery, szError[], iErrcode, iData[], iDataSize)
{
	new id = iData[0], i
	if(SQL_NumResults(iQuery))
	{
		while(SQL_MoreResults(iQuery))
		{
			g_iWeaponKills[id][i] = SQL_ReadResult(iQuery, 0)
			i++
			SQL_NextRow(iQuery)
		}

		g_blLoaded[id][LOAD_KILLS] = true
	}
}

public SqlSaveMapStats(id, szInfo[])
{
	if(szInfo[0] == EOS)
	{
		return 
	}

	static szQuery[2][MAX_QUERY_LENGTH], szPlayer[2][MAX_NAME_LENGTH * 2], szIP[MAX_IP_LENGTH], szFlags[MAX_USER_INFO_LENGTH]

	get_user_ip(id, szIP, charsmax(szIP), 1)
	get_flags(get_user_flags(id), szFlags, charsmax(szFlags))

	SQL_QuoteString(Empty_Handle, szPlayer[PLAYER], charsmax(szPlayer[]), szInfo)
	SQL_QuoteString(Empty_Handle, szPlayer[NICK], charsmax(szPlayer[]), g_szName[id])

	formatex(szQuery[0], charsmax(szQuery[]), "DELETE FROM `%s` WHERE Nick = '%s';", g_eSetting[MYSQL_TABLE3], szPlayer[NICK])
	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[0])

	formatex(szQuery[1], charsmax(szQuery[]), "REPLACE INTO `%s` (Player, Nick, `Steam ID`, IP, `Map Kills`, `Map Deaths`, `Map MVP`, `Map XP`, Level, Flags, Online, New, Steam, Avatar, Profile)\
	VALUES ('%s', '%s', '%s', '%s', '%i', '%i', '%i', '%i', '%i', '%s', '1', '%i', '%i', '%s', '%s');", g_eSetting[MYSQL_TABLE3], szPlayer[PLAYER], szPlayer[NICK], g_szAuthID64[id], szIP,
	floatround(get_entvar(id, var_frags)), get_member(id, m_iDeaths), g_pMapData[id][MAP_MVP], g_pMapData[id][MAP_XP], g_pPlayerData[id][Level], szFlags,
	(g_pPlayerData[id][PlayedTime] + get_user_time(id)) >= g_eSetting[TIME_NEW] ? 0 : 1, is_user_steam(id) ? 1 : 0, g_szSteam[id][STEAM_AVATAR], g_szSteam[id][STEAM_PROFILE])
	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[1])
}

public taskResetXp(id)
{
	id -= TASK_RESETXP
	g_iTotalXp[id] = 0
}

public taskResetTeamXp(id)
{
	id -= TASK_TEAM_XP
	g_iTotalTeamXp[id] = 0
}

GetMVP(const id, iType)
{
	g_blMVP = true
	g_pPlayerData[id][MVP]++
	g_pMapData[id][MAP_MVP]++

	GetPlayerInfo(id, false)
	GetMapInfo(id)

	if(g_eSetting[MVP_HUD_ENABLE])
	{
		new iArg[1]; iArg[0] = iType
		set_task(0.1, "taskShowMVP", id, iArg, sizeof(iArg))
	}
}

public taskShowMVP(iArg[1], id)
{
	if(!g_blMVP || !is_user_connected(id) || !is_user_valid(id))
	{
		return
	}

	new iRed = 			floatround(g_eSetting[MVP_HUD_VALUES][HUD_COLOR1])
	new iGreen = 		floatround(g_eSetting[MVP_HUD_VALUES][HUD_COLOR2])
	new iBlue = 		floatround(g_eSetting[MVP_HUD_VALUES][HUD_COLOR3])
	new Float:flPosX = 	g_eSetting[MVP_HUD_VALUES][HUD_POS_X]
	new Float:flPosY = 	g_eSetting[MVP_HUD_VALUES][HUD_POS_Y]

	if(iRed < 0) 	iRed = 		random(256)
	if(iGreen < 0) 	iGreen = 	random(256)
	if(iBlue < 0) 	iBlue = 	random(256)

	static szHudMessage[MAX_DATA_LENGTH]
	switch(iArg[0])
	{
		case MOST_KILLS: 	formatex(szHudMessage, charsmax(szHudMessage), "%L", id, "RSU_MVP_MOST_KILLS", id, g_iRoundKills[id], g_iRoundHs[id])
		case BOMB_EXPLODE: 	formatex(szHudMessage, charsmax(szHudMessage), "%L", id, "RSU_MVP_BOMB_EXPLODE", id)
		case BOMB_DEFUSE: 	formatex(szHudMessage, charsmax(szHudMessage), "%L", id, "RSU_MVP_BOMB_DEFUSE", id)
	}

	switch(g_eSetting[MVP_HUD_TYPE])
	{
		case 0:
		{
			set_hudmessage(iRed, iGreen, iBlue, flPosX, flPosY, .holdtime = 1.0)
			show_hudmessage(0, szHudMessage)
		}
		case 1:
		{
			set_dhudmessage(iRed, iGreen, iBlue, flPosX, flPosY, .holdtime = 1.0)
			show_dhudmessage(0, szHudMessage)
		}
	}

	set_task(1.0, "taskShowMVP", id, iArg, sizeof(iArg))
}

GetPlayerInfo(const id, bool:blOnLoad)
{
	if(!g_eSetting[RANK_BOTS] && is_user_bot(id) || !g_eSetting[MYSQL_REALTIME] && !blOnLoad)
	{
		return  
	}

	SqlSaveOrLoad(id, MYSQL_SAVE, g_szSaveInfo[id])
	GetPlayerRank(id)
}

GetMapInfo(const id)
{
	set_task(0.1, "taskGetMapInfo", id)
}

public taskGetMapInfo(id)
{
	SqlSaveMapStats(id, g_szSaveInfo[id])
}

ResetStats(const id)
{
	arrayset(g_pPlayerData[id], 0, sizeof g_pPlayerData[] - 1)
	g_pPlayerData[id][FirstLogin][0] = EOS

	for(new i; i < MAX_WEAPONS_EX; i++)
	{
		g_iWeaponKills[id][i] = 0
	}
}

GetXpReward(const szTrie[], iType)
{
	new iReward
	switch(iType)
	{
		case XP_REWARD:
		{
			if(TrieKeyExists(g_tRewards, szTrie))
			{
				TrieGetCell(g_tRewards, szTrie, iReward)
				return iReward
			}
		}
		case XP_TEAM_REWARD:
		{
			if(TrieKeyExists(g_tTeamRewards, szTrie))
			{
				TrieGetCell(g_tTeamRewards, szTrie, iReward)
				return iReward
			}
		}
	}

	return 0
}

UpdateXpAndRank(const id, iXp, bool:blTeam)
{
	if(!g_eSetting[RANK_BOTS] && is_user_bot(id) || g_eSetting[MINIMUM_PLAYERS] && get_playersnum() < g_eSetting[MINIMUM_PLAYERS] || g_eSetting[TEAM_SET] && get_member(id, m_iTeam) != g_eSetting[TEAM_SET])
	{
		return  
	}

	g_pPlayerData[id][Xp] += iXp
	g_pMapData[id][MAP_XP] += iXp

	if(iXp != 0)
	{
		UpdateRank(id)
		GetPlayerInfo(id, false)
	}

	switch(blTeam)
	{
		case true:
		{
			g_iTotalTeamXp[id] += iXp
			ResetTotalTeamXp(id)
		}
		case false:
		{
			g_iTotalXp[id] += iXp
			ResetTotalXp(id)
		}
	}

	new iReturn
	ExecuteForward(g_fwdXPUpdated, iReturn, id, iXp, blTeam)
}

ResetTotalXp(const id)
{
	new iTask = id + TASK_RESETXP
	if(task_exists(iTask))
	{
		remove_task(iTask)
	}

	set_task(g_eSetting[XP_HUD_VALUES][HUD_HOLD_TIME], "taskResetXp", iTask)
}

ResetTotalTeamXp(const id)
{
	new iTask = id + TASK_TEAM_XP
	if(task_exists(iTask))
	{
		remove_task(iTask)
	}

	set_task(g_eSetting[XP_HUD_TEAM_VALUES][HUD_HOLD_TIME], "taskResetTeamXp", iTask)
}

ShowHudMessage(const id, iXp, bool:blTeam)
{
	new iRed = 			blTeam ? floatround(g_eSetting[XP_HUD_TEAM_VALUES][HUD_COLOR1]) : floatround(g_eSetting[XP_HUD_VALUES][HUD_COLOR1])
	new iGreen =  		blTeam ? floatround(g_eSetting[XP_HUD_TEAM_VALUES][HUD_COLOR2]) : floatround(g_eSetting[XP_HUD_VALUES][HUD_COLOR2]) 
	new iBlue =  		blTeam ? floatround(g_eSetting[XP_HUD_VALUES][HUD_COLOR3]) 		: floatround(g_eSetting[XP_HUD_VALUES][HUD_COLOR3])
	new Float:flPosX =  blTeam ? g_eSetting[XP_HUD_TEAM_VALUES][HUD_POS_X] 				: g_eSetting[XP_HUD_VALUES][HUD_POS_X]
	new Float:flPosY =  blTeam ? g_eSetting[XP_HUD_TEAM_VALUES][HUD_POS_Y] 				: g_eSetting[XP_HUD_VALUES][HUD_POS_Y]
	new iEffects =  	blTeam ? floatround(g_eSetting[XP_HUD_TEAM_VALUES][HUD_EFFECT]) : floatround(g_eSetting[XP_HUD_VALUES][HUD_EFFECT])

	if(iRed < 0) 	iRed = 		random(256)
	if(iGreen < 0) 	iGreen = 	random(256)
	if(iBlue < 0) 	iBlue = 	random(256)

	static szHudInfo[MAX_DATA_LENGTH]
	new blGetXp = iXp >= 0

	switch(blGetXp)
	{
		case true: 	blTeam ? copy(szHudInfo, charsmax(szHudInfo), g_eSetting[XP_HUD_TEAM_GET]) 	: copy(szHudInfo, charsmax(szHudInfo), g_eSetting[XP_HUD_GET])
		case false: blTeam ? copy(szHudInfo, charsmax(szHudInfo), g_eSetting[XP_HUD_TEAM_LOSE]) : copy(szHudInfo, charsmax(szHudInfo), g_eSetting[XP_HUD_LOSE])
	}

	if(contain(szHudInfo, "%xp%") != -1)
	{
		replace_string(szHudInfo, charsmax(szHudInfo), "-", "")
		replace_string(szHudInfo, charsmax(szHudInfo), "%xp%", "%d")
	}

	new iType = blTeam ? g_eSetting[XP_HUD_TEAM_TYPE] : g_eSetting[XP_HUD_TYPE]
	switch(iType)
	{
		case 0:
		{
			set_hudmessage(iRed, iGreen, iBlue, flPosX, flPosY, iEffects, 1.0, iEffects != 1 ? 0.15 : 0.05, 0.01, 0.01, -1)
			ShowSyncHudMsg(id, blTeam ? g_iObject[XP_HUD] : g_iObject[XP_TEAM_HUD], szHudInfo, iXp)
		}
		case 1:
		{
			set_dhudmessage(iRed, iGreen, iBlue, flPosX, flPosY, iEffects, 1.0, iEffects != 1 ? 0.15 : 0.05, 0.01, 0.01)
			show_dhudmessage(id, szHudInfo, iXp)
		}
	}
}

UpdateRank(const id)
{
	new iLevel, eMaxRanks[RankInfo]
	for(new i; i < g_iRanks - 1; i++)
	{
		ArrayGetArray(g_aRanks, i + 1, eMaxRanks)

		if(g_pPlayerData[id][Xp] >= eMaxRanks[RankXp])
		{
			iLevel++
		}
	}

	if(iLevel != g_pPlayerData[id][Level])
	{
		new bool:blLevelUp = iLevel > g_pPlayerData[id][Level], iReturn
		static eRank[RankInfo]
		ArrayGetArray(g_aRanks, iLevel, eRank)

		if(blLevelUp)
		{
			g_pPlayerData[id][Level] = iLevel
			CPC(g_eSetting[LEVEL_MESSAGE_TYPE] ? 0 : id, "%L", id, "RSU_RANK_UP", id, g_pPlayerData[id][Level] + 1, eRank[RankName])
			LevelEffect(id, LEVEL_UP)
		}
		else
		{
			g_pPlayerData[id][Level] = iLevel
			CPC(g_eSetting[LEVEL_MESSAGE_TYPE] ? 0 : id, "%L", id, "RSU_RANK_DN", id, g_pPlayerData[id][Level] + 1, eRank[RankName])
			LevelEffect(id, LEVEL_DN)
		}

		ExecuteForward(g_fwdLevelUpdated, iReturn, id, iLevel + 1, blLevelUp)
	}
}

LevelEffect(const id, iType)
{
	new iRed = 		iType == LEVEL_UP ? floatround(g_eSetting[LEVELUP_EFFECTS][SCREEN_COLOR1]) : floatround(g_eSetting[LEVELDN_EFFECTS][SCREEN_COLOR1])
	new iGreen = 	iType == LEVEL_UP ? floatround(g_eSetting[LEVELUP_EFFECTS][SCREEN_COLOR2]) : floatround(g_eSetting[LEVELDN_EFFECTS][SCREEN_COLOR2])
	new iBlue = 	iType == LEVEL_UP ? floatround(g_eSetting[LEVELUP_EFFECTS][SCREEN_COLOR3]) : floatround(g_eSetting[LEVELDN_EFFECTS][SCREEN_COLOR3])

	if(iRed < 0) 	iRed = 		random(256)
	if(iGreen < 0) 	iGreen = 	random(256)
	if(iBlue < 0) 	iBlue = 	random(256)

	message_begin(MSG_ONE, g_iScreenFade, {0, 0, 0}, id)
	write_short(floatround(4096.0 * (iType == LEVEL_UP ? g_eSetting[LEVELUP_EFFECTS][SCREEN_HOLD_TIME] : g_eSetting[LEVELDN_EFFECTS][SCREEN_HOLD_TIME]), floatround_round))
	write_short(floatround(4096.0 * (iType == LEVEL_UP ? g_eSetting[LEVELUP_EFFECTS][SCREEN_HOLD_TIME] : g_eSetting[LEVELDN_EFFECTS][SCREEN_HOLD_TIME]), floatround_round))
	write_short(0x0000)
	write_byte(iRed)
	write_byte(iGreen)
	write_byte(iBlue)
	write_byte(iType == LEVEL_UP ? floatround(g_eSetting[LEVELUP_EFFECTS][SCREEN_ALPHA]) : floatround(g_eSetting[LEVELDN_EFFECTS][SCREEN_ALPHA]))
	message_end()

	if(iType == LEVEL_UP)
	{
		emit_sound(id, CHAN_AUTO, g_eSetting[LEVELUP_SOUND], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else
	{
		emit_sound(id, CHAN_AUTO, g_eSetting[LEVELDN_SOUND], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

SQL_IsFail(iFailState, iErrcode, const szError[])
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED: 
		{
			g_blSqlFailed = true
			log_amx("%L", LANG_PLAYER, "RSU_CONNECT_FAILED", szError)
		}
		case TQUERY_QUERY_FAILED: 	log_amx("%L", LANG_PLAYER, "RSU_QUERY_FAILED", szError)
		default: g_blSqlFailed = false
	}

	if(iErrcode)
	{
		log_amx("%L", LANG_PLAYER, "RSU_QUERY_ERROR", szError)
	}

	return false
}

strclip(szString[], iClip, szEnding[] = "..")
{
	new iLen = strlen(szString) - 1 - strlen(szEnding) - iClip
	format(szString[iLen], iLen, szEnding)
}

stock CPC(const pPlayer, const szInputMessage[], any:...)
{
	static szMessage[191]
	new iLen = formatex(szMessage, charsmax(szMessage), "%s ", g_eSetting[CHAT_PREFIX])
	vformat(szMessage[iLen], charsmax(szMessage) - iLen, szInputMessage, 3)
	client_print_color(pPlayer, print_team_default, szMessage)
}