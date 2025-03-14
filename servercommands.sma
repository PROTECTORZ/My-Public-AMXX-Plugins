/*PROTECTOR`s Server Commands Plugin*
if you need help for adding new commands contact with ryrixz_ from discord*/

#include <amxmodx>
#include <amxmisc>
#include <reapi>

#define CHAT_PREFIX "^1[^4CD2^1]"

public plugin_init()
{
	register_plugin("Commands", "1.0", "PROTECTOR")
	
	register_clcmd("say", "Hook_Say_SayTeam")
	register_clcmd("say_team", "Hook_Say_SayTeam")
}

public Hook_Say_SayTeam(id)
{
	new szArgsMessage[192], szArgCommand[32], szArgName[32], szArgValue[10]

	read_args(szArgsMessage, charsmax(szArgsMessage))
	remove_quotes(szArgsMessage)

	parse(szArgsMessage, szArgCommand, charsmax(szArgCommand), szArgName, charsmax(szArgName), szArgValue, charsmax(szArgValue))

	if (equali(szArgCommand, "ip"))
	{
		CPC(id, print_team_red, "^3Server IP: 91.212.121.162:27030", id)
	}

	if (equali(szArgCommand, "owner"))
	{
		CPC(id, print_team_red, "^4Owner is: *OneManArmy*", id)
	}

	if (equali(szArgCommand, "discord"))
	{
		CPC(id, print_team_red, "^4Owner Discord: onemanarmy1_", id)
	}

	if (equali(szArgCommand, "game"))
	{
		CPC(id, print_team_red, "^4The Terrorists must plant the bomb and CT`s must defuse the bomb!", id)
	}

	if (equali(szArgCommand, "admin"))
	{
		CPC(id, print_team_red, "^4IF you want to be admin please sent me DM. For my discord write in chat discord!", id)
	}

	if (equali(szArgCommand, "vip"))
	{
		CPC(id, print_team_red, "^4For Now server doesn`t have a VIP Extras: VIP Extras Comming Soon!", id)
	}

}

stock CPC(const pPlayer, iColor, const szInputMessage[], any:...)
{
	static szMessage[191];
	new iLen = formatex(szMessage, charsmax(szMessage), "%s ", CHAT_PREFIX);
	vformat(szMessage[iLen], charsmax(szMessage) - iLen, szInputMessage, 3);
	
	client_print_color(pPlayer, iColor, szMessage);
}