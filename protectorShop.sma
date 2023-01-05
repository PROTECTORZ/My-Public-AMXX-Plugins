/* PROTECTOR`S POINTS SHOP * Visual Studio Code Linux.. */
/* Version 1.0 First Release*/
/* This Plugin Can be Used in Every mod , but for Respawn/Deathmatch servers is better*/
/* You Can edit the Prices from 51 line , for prime members has cvars you can edit them from game or here*/
/* Prefix you can change in Line 17 for Menu prefix , and Line 18 for Chat Prefix*/

#include <amxmodx>
#include <reapi>

#define PLUGIN  "PROTECTOR`S POINTS SHOP"
#define VERSION "1.0"
#define AUTHOR  "PROTECTOR"

native st_account_currency_get(id)
native st_account_currency_add(id, iCurrencyAmount)
native st_account_currency_remove(id, iCurrencyAmount)

new const g_szMenuPrefix[] = "\rPROTECTOR \wPoints \ySHOP"
new const g_szChatPrefix[] = "^4[PRShop]"


enum _:eItemType
{
	ITEM_RESET,
	ITEM_HP,
	ITEM_ARMOR,
	ITEM_SPEED,
	ITEM_HP_ARMOR,
	ITEM_NO_FOOTSTEPS,
	ITEM_INVINCIBILITY,
	ITEM_VAMPIRE,
	ITEM_DOUBLE_POINTS,
	ITEM_GRENADES,
	ITEM_HP_REGENERATION,
	ITEM_GRAVITY,
	ITEM_INVISIBILITY,
	ITEM_CAMOUFLAGE,
	ITEM_UNLIMITED_AMMO,

	MAX_ITEMS
}

enum _:eItemData
{
	ITEM_NAME[MAX_NAME_LENGTH],
	ITEM_VALUE,
	ITEM_PRICE,
	ITEM_LIMIT
}

new const g_szItemData[][eItemData] =
{
	// Item name    		Value   	Price   	Limit
	{ "Health", 			150, 		30, 		2 },
	{ "Armor", 				150, 		20, 		2 },
	{ "Speed", 				350, 		20, 		2 },
	{ "HP & Armor", 		100, 		30, 		2 },
	{ "No Footsteps", 		1, 			20, 		2 },
	{ "Invincibility", 		10, 		50, 		2 },
	{ "Vampire", 			1, 			30, 		2 },
	{ "2x Points", 			1, 			50, 		2 },
	{ "Grenades", 			60, 		20, 		2 },
	{ "HP Regeneration", 	60, 		30, 		2 },
	{ "Gravity", 			1, 			20, 		2 },
	{ "Invisibility", 		60, 		80, 		2 },
	{ "Camouflage", 		1, 			50, 		2 },
	{ "Unlimited Ammo",		30, 		20, 		2 },
}

enum _:ePlayerData
{
	CURRENT_BOUGHTS,
	LIMIT,
	ACTIVE_ITEM,
	ACTIVE_TIME
}

new g_iPlayerItemsData[MAX_CLIENTS + 1][ePlayerData][MAX_ITEMS]

new const g_szT_Models[][] = { "arctic", "leet", "guerilla", "terror" }
new const g_szCT_Models[][] = { "gign", "urban", "sas", "gsg9" }

new g_iThinkingEnt

enum _:eCvars
{
	KILL_REWARD,
	FLAG_ACCESS[5],
	SHOP_DISCOUNT[10]
}

new g_eCvars[eCvars]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed", true)
	RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn", true)
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "CBasePlayer_ResetMaxSpeed", true)

	bind_pcvar_num(create_cvar("pshop_points_per_kill", "3"), g_eCvars[KILL_REWARD])
	bind_pcvar_string(create_cvar("pshop_premium_flag_access", "m"), g_eCvars[FLAG_ACCESS], charsmax(g_eCvars[FLAG_ACCESS]))
	bind_pcvar_string(create_cvar("pshop_premium_discount", "-50%"), g_eCvars[SHOP_DISCOUNT], charsmax(g_eCvars[SHOP_DISCOUNT]))

	register_clcmd("say /pshop", "ClCmd_ToggleShopMenu")
	register_clcmd("nightvision", "ClCmd_ToggleShopMenu")

	g_iThinkingEnt = rg_create_entity("info_target")
	set_entvar(g_iThinkingEnt, var_nextthink, get_gametime() + 0.1)
	SetThink(g_iThinkingEnt, "Entity_Think")
}

public Entity_Think(iEnt)
{
	if (iEnt != g_iThinkingEnt)
		return

	static iPlayers[MAX_PLAYERS], iPlayersNum, id
	get_players(iPlayers, iPlayersNum, "a")

	for (--iPlayersNum; iPlayersNum >= 0; iPlayersNum--)
	{
		id = iPlayers[iPlayersNum]

		if (g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_INVINCIBILITY] >= 1 || g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_GRENADES] >= 1 || 
			g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_HP_REGENERATION] >= 1 || g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_UNLIMITED_AMMO] >= 1 || g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_INVISIBILITY] >= 1)
		{
			new text[48], text_to_show[256]

			if (g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_INVINCIBILITY] >= 1)
			{
				g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_INVINCIBILITY]--
				format(text, charsmax(text), "^nInvincible: %i", g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_INVINCIBILITY])
				add(text_to_show, charsmax(text_to_show), text)

				if (g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_INVINCIBILITY] == 0)
				{
					rg_set_user_godmode(id, false)
					CPC(id, print_team_red, "^3You are no longer invincible.")
				}
			}

			if (g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_GRENADES] >= 1)
			{
				g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_GRENADES]--
				format(text, charsmax(text), "^nGrenades Resupply: %i", g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_GRENADES])
				add(text_to_show, charsmax(text_to_show), text)

				switch (g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_GRENADES])
				{
					case 0, 10, 20, 30, 40, 50:
					{
						Task_Handle_Grenades(id)
					}
				}
			}

			if (g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_HP_REGENERATION] >= 1)
			{
				g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_HP_REGENERATION]--
				format(text, charsmax(text), "^nHP Regeneration: %i", g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_HP_REGENERATION])
				add(text_to_show, charsmax(text_to_show), text)

				if (g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_HP_REGENERATION] == 0)
					CPC(id, print_team_red, "^3HP Regeneration is no longer available.")
				else
					TaskHealing(id)
			}

			if (g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_UNLIMITED_AMMO] >= 1)
			{
				g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_UNLIMITED_AMMO]--
				format(text, charsmax(text), "^nUnlimited Ammo: %i", g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_UNLIMITED_AMMO])
				add(text_to_show, charsmax(text_to_show), text)

				if (g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_UNLIMITED_AMMO] == 0)
				{
					rg_set_user_unlimited_ammo(id, false)
					CPC(id, print_team_red, "^3Unlimited ammo is no longer available.")
				}
			}

			if (g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_INVISIBILITY] >= 1)
			{
				g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_INVISIBILITY]--
				format(text, charsmax(text), "^nInvisible: %i", g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_INVISIBILITY])
				add(text_to_show, charsmax(text_to_show), text)

				if (g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_INVISIBILITY] == 0)
				{
					rg_set_user_invisibility_ex(id, false)
					CPC(id, print_team_red, "^3You are no longer invisible.")
				}
			}

			set_hudmessage(random(256), random(256), random(256), -1.0, 0.25, 1, 0.0, 0.9, 0.01, 0.01, -1)
			show_hudmessage(id, text_to_show)
		}
	}
	set_entvar(iEnt, var_nextthink, get_gametime() + 1.0)
}

public CBasePlayer_Spawn(id)
{
	if (is_user_alive(id))
	{
		ResetShopData(id)
	}
}

public CBasePlayer_Killed(iVictim, iKiller, iShouldGib)
{
	if (iVictim == iKiller || !is_user_connected(iKiller))
		return HC_CONTINUE

	if (g_iPlayerItemsData[iKiller][ACTIVE_ITEM][ITEM_VAMPIRE])
		rg_add_user_health(iKiller, 10.0, _, get_entvar(iKiller, var_max_health), true)

	if (g_iPlayerItemsData[iKiller][ACTIVE_ITEM][ITEM_DOUBLE_POINTS])
		st_account_currency_add(iKiller, g_eCvars[KILL_REWARD] * 2)
	else
		st_account_currency_add(iKiller, g_eCvars[KILL_REWARD])

	return HC_CONTINUE
}

public CBasePlayer_ResetMaxSpeed(id)
{
	if (!is_user_alive(id))
		return HC_CONTINUE

	if (g_iPlayerItemsData[id][ACTIVE_ITEM][ITEM_SPEED])
		rg_set_user_maxspeed(id, float(g_szItemData[ITEM_SPEED][ITEM_VALUE]))

	if (g_iPlayerItemsData[id][ACTIVE_ITEM][ITEM_GRAVITY])
		rg_set_user_gravity(id, 0.6)

	return HC_CONTINUE
}


public ClCmd_ToggleShopMenu(id)
{
	new menu = menu_create(fmt("%s\R%i \yPTS ^nStatus: %s", g_szMenuPrefix, st_account_currency_get(id), is_user_premium(id) ? "\yPremium Member": "\wNormal Member"), "ShopMenu_Handler")
	static szItem[128]

	new iCallBack = menu_makecallback("CallBack_ShopMenu");

	for (new i = 0; i < sizeof g_szItemData; i++)
	{
		if (i == 0)
		{
			formatex(szItem, charsmax(szItem), "%s \d[\y%i Pts\d][\y%i\w/\r%i\d]^n", g_szItemData[i][ITEM_NAME], 
															(is_user_premium(id) ? (math_add_fix(g_szItemData[i][ITEM_PRICE], g_eCvars[SHOP_DISCOUNT])) : g_szItemData[i][ITEM_PRICE]),
															g_iPlayerItemsData[id][CURRENT_BOUGHTS][i], g_szItemData[i][ITEM_LIMIT])

			menu_additem(menu, szItem, .callback = iCallBack)
		}
		else
		{
			formatex(szItem, charsmax(szItem), "%s \d[\y%i Pts\d][\y%i\w/\r%i\d]", g_szItemData[i][ITEM_NAME], 
														(is_user_premium(id) ? (math_add_fix(g_szItemData[i][ITEM_PRICE], g_eCvars[SHOP_DISCOUNT])) : g_szItemData[i][ITEM_PRICE]),
														g_iPlayerItemsData[id][CURRENT_BOUGHTS][i], g_szItemData[i][ITEM_LIMIT])

			menu_additem(menu, szItem, .callback = iCallBack)
		}
	}
	menu_setprop(menu, MPROP_EXITNAME, "\rExit")
	menu_display(id, menu)
}

public CallBack_ShopMenu(id, menu, item)
{
	if (g_iPlayerItemsData[id][LIMIT][item] == g_szItemData[item][ITEM_LIMIT])
		return ITEM_DISABLED

	new iTotalItemPrice = is_user_premium(id) ? (math_add_fix(g_szItemData[item][ITEM_PRICE], g_eCvars[SHOP_DISCOUNT])) : g_szItemData[item][ITEM_PRICE]
	
	if (st_account_currency_get(id) < iTotalItemPrice)
		return ITEM_DISABLED

	return ITEM_ENABLED
}

public ShopMenu_Handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	if (!is_user_alive(id))
	{
		CPC(id, print_team_default, "^1You must be alive to use shop!")
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	
	if (g_iPlayerItemsData[id][CURRENT_BOUGHTS][item] >= g_szItemData[item][ITEM_LIMIT])
	{
		CPC(id, print_team_default, "^1You have reached ^3max boughts ^1for this item!")
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}

	if (g_iPlayerItemsData[id][ACTIVE_ITEM][item])
	{
		CPC(id, print_team_default, "^1You need to wait till next round to use this item!")
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}
	
	if (st_account_currency_get(id) < g_szItemData[item][ITEM_PRICE])
	{
		CPC(id, print_team_default, "^1You don't have enough ^4Points ^1to buy this item!")
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}

	static szItem[128], iLen
	
	iLen = formatex(szItem, charsmax(szItem), "^1You have bought ^3%s^1 ", g_szItemData[item][ITEM_NAME])

	switch (item)
	{
		case ITEM_RESET:
		{
			for (new i = 1; i < MAX_ITEMS; i++)
			{
				arrayset(g_iPlayerItemsData[id][CURRENT_BOUGHTS][i], 0, sizeof g_iPlayerItemsData[])
			}
		}
		case ITEM_HP:
		{
			rg_add_user_health(id, float(g_szItemData[item][ITEM_VALUE]))
			iLen += formatex(szItem[iLen], charsmax(szItem) - iLen, "(^4%i Health^1) ", g_szItemData[item][ITEM_VALUE])
		}
		case ITEM_ARMOR:
		{
			rg_set_user_armor(id, g_szItemData[item][ITEM_ARMOR], ARMOR_VESTHELM)
			iLen += formatex(szItem[iLen], charsmax(szItem) - iLen, "(^4%i Armor^1) ", g_szItemData[item][ITEM_VALUE])
		}
		case ITEM_SPEED:
		{
			rg_set_user_maxspeed(id, float(g_szItemData[item][ITEM_VALUE]))
			g_iPlayerItemsData[id][ACTIVE_ITEM][item] = true
		}
		case ITEM_HP_ARMOR:
		{
			rg_set_user_health(id, float(g_szItemData[item][ITEM_VALUE]))
			rg_set_user_armor(id, g_szItemData[item][ITEM_VALUE], ARMOR_VESTHELM)
		}
		case ITEM_NO_FOOTSTEPS:
		{
			rg_set_user_footsteps(id, true)
			g_iPlayerItemsData[id][ACTIVE_ITEM][item] = true
		}
		case ITEM_INVINCIBILITY:
		{
			rg_set_user_godmode(id, true)

			g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_INVINCIBILITY] = g_szItemData[item][ITEM_VALUE] + 1
		}
		case ITEM_VAMPIRE:
		{
			g_iPlayerItemsData[id][ACTIVE_ITEM][item] = true
		}
		case ITEM_DOUBLE_POINTS:
		{
			g_iPlayerItemsData[id][ACTIVE_ITEM][item] = true
		}
		case ITEM_GRENADES:
		{
			rg_give_item(id, "weapon_hegrenade")

			g_iPlayerItemsData[id][ACTIVE_TIME][item] = g_szItemData[item][ITEM_VALUE] + 1
		}
		case ITEM_HP_REGENERATION:
		{
			g_iPlayerItemsData[id][ACTIVE_TIME][item] = g_szItemData[item][ITEM_VALUE] + 1
		}
		case ITEM_GRAVITY:
		{
			rg_set_user_gravity(id, 0.6)
			g_iPlayerItemsData[id][ACTIVE_ITEM][item] = true
		}
		case ITEM_INVISIBILITY:
		{
			rg_set_user_invisibility_ex(id, true)

			g_iPlayerItemsData[id][ACTIVE_TIME][item] = g_szItemData[item][ITEM_VALUE] + 1
		}
		case ITEM_CAMOUFLAGE:
		{
			if (rg_get_user_team(id) == TEAM_TERRORIST)
				rg_set_user_model(id, g_szCT_Models[random_num(0, 3)])
			else if (rg_get_user_team(id) == TEAM_CT)
				rg_set_user_model(id, g_szT_Models[random_num(0, 3)])

			g_iPlayerItemsData[id][ACTIVE_ITEM][item] = true
		}
		case ITEM_UNLIMITED_AMMO:
		{
			rg_set_user_unlimited_ammo(id, true)

			g_iPlayerItemsData[id][ACTIVE_TIME][item] = g_szItemData[item][ITEM_VALUE] + 1
		}
	}
	iLen += formatex(szItem[iLen], charsmax(szItem) - iLen, "^1for ^4%i Points", is_user_premium(id) ? (math_add_fix(g_szItemData[item][ITEM_PRICE], g_eCvars[SHOP_DISCOUNT])) : g_szItemData[item][ITEM_PRICE])
	
	CPC(id, print_team_default, szItem)

	st_account_currency_remove(id, is_user_premium(id) ? (math_add_fix(g_szItemData[item][ITEM_PRICE], g_eCvars[SHOP_DISCOUNT])) : g_szItemData[item][ITEM_PRICE])
	g_iPlayerItemsData[id][CURRENT_BOUGHTS][item]++

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public Task_Handle_Grenades(id)
{
	if (!rg_has_item_by_name(id, "weapon_hegrenade"))
		rg_give_item(id, "weapon_hegrenade")
	else
		rg_user_add_ammo(id, AMMO_HEGRENADE, 1, 10, GAT_GIVE_AMMO, true)

	if(g_iPlayerItemsData[id][ACTIVE_TIME][ITEM_GRENADES] == 0)
	{
		CPC(id, print_team_red, "^3You cannot carry anymore ^4HE Grenades^3!")
		return PLUGIN_CONTINUE
	}

	return PLUGIN_HANDLED
}

public TaskHealing(id)
{
	if (is_user_alive(id))
	{
		static Float:flHealth, Float:flMaxHealth, Float:flRegenerationHealth
		flHealth = get_entvar(id, var_health)
		flMaxHealth = get_entvar(id, var_max_health)
		flRegenerationHealth = 10.0

		if (flHealth >= flMaxHealth)
			return PLUGIN_CONTINUE

		rg_add_user_health(id, flRegenerationHealth, flHealth, flMaxHealth, true)
	}
	return PLUGIN_CONTINUE
}

public ResetShopData(id)
{
	for (new i = 1; i < MAX_ITEMS; i++)
	{
		arrayset(g_iPlayerItemsData[id][ACTIVE_ITEM][i], 0, sizeof g_iPlayerItemsData[])
		arrayset(g_iPlayerItemsData[id][ACTIVE_TIME][i], 0, sizeof g_iPlayerItemsData[])
	}
	rg_set_user_footsteps(id, false)
	rg_set_user_godmode(id, false)
	rg_set_user_invisibility_ex(id, false)
	rg_set_user_unlimited_ammo(id, false)
	rg_reset_user_model(id)
	rg_set_user_gravity(id)
	rg_reset_maxspeed(id)
}

stock bool:is_user_premium(id)
{
	if (get_user_flags (id) & read_flags(g_eCvars[FLAG_ACCESS]))
		return true

	return false
}


stock CPC(const pPlayer, const iColor, const szInputMessage[], any:...)
{
	static szMessage[191]
	new iLen = formatex(szMessage, charsmax(szMessage), "%s ", g_szChatPrefix)
	vformat(szMessage[iLen], charsmax(szMessage) - iLen, szInputMessage, 3)
	
	client_print_color(pPlayer, iColor, szMessage)
}

// Credits: OciXCrom for bad calculation of percentage!!
// Credits: Huehue for fixing his bad math..
math_add_fix(iDiscount, const szMath[])
{
	static szNewMath[16], bool:bPercent, cOperator, iMath, iCalculate
	
	copy(szNewMath, charsmax(szNewMath), szMath)
	bPercent = szNewMath[strlen(szNewMath) - 1] == '%'
	cOperator = szNewMath[0]

	if (!isdigit(szNewMath[0]))
		szNewMath[0] = ' '

	if (bPercent)
		replace(szNewMath, charsmax(szNewMath), "%", "")

	trim(szNewMath)
	iMath = str_to_num(szNewMath)

	if (bPercent)
		iCalculate = (iDiscount * iMath) / 100
	   
	switch(cOperator)
	{
		case '+': iDiscount += iCalculate
		case '-': iDiscount -= iCalculate
		case '/': iDiscount /= iCalculate
		case '*': iDiscount *= iCalculate
		default: iDiscount = iCalculate
	}

	return iDiscount
}