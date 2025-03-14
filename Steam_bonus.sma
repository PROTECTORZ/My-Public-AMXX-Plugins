#include <amxmodx>
#include <cromchat>
#include <reapi_stocks>

new bool:g_bSteam[MAX_CLIENTS + 1]

new g_pCvar_Money, Float:g_pCvar_Health, g_pCvar_Armor, g_pCvar_Rounds

public plugin_init()
{
	register_plugin("Steam Bonus", "1.1", "PROTECTOR")

	RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn", 1)

	bind_pcvar_num(create_cvar("steam_bonus_rounds", "1"), g_pCvar_Rounds)
	bind_pcvar_num(create_cvar("steam_bonus_money", "1000"), g_pCvar_Money)
	bind_pcvar_float(create_cvar("steam_bonus_health", "10"), g_pCvar_Health)
	bind_pcvar_num(create_cvar("steam_bonus_armor", "10"), g_pCvar_Armor)

	AutoExecConfig(true, "Steam_Bonus")
}

public client_putinserver(id)
{
	g_bSteam[id] = is_user_steam(id) ? true : false
}

public CBasePlayer_Spawn(id)
{
	if (is_user_alive(id) && g_bSteam[id])
	{
		if (get_member_game(m_iTotalRoundsPlayed) >= g_pCvar_Rounds)
		{
			set_task(5.0, "UTIL_DelayedSteamBonus", id)
		}
	}
}

public UTIL_DelayedSteamBonus(id)
{
	if (is_user_alive(id))
	{
		rg_give_user_money(id, g_pCvar_Money, true)
		rg_set_user_armor(id, rg_get_user_armor(id) + g_pCvar_Armor, ARMOR_VESTHELM)
		rg_add_user_health(id, g_pCvar_Health)

		CC_SendMessage(id, "You Received &x04%i$, %.f Health and %i Armor because you have the &x03Original Game!", g_pCvar_Money , g_pCvar_Health, g_pCvar_Armor)
	}
}

#if !defined _reapi_reunion_included
bool:is_user_steam(id)
{
	static iPointer

	if(iPointer || (iPointer = get_cvar_pointer("dp_r_id_provider")))
	{
		server_cmd("dp_clientinfo %d", id); server_exec()
		return get_pcvar_num(iPointer) == 2
	}
	 
	return false
}
#endif