/*This plugin shows When user Connects with STEAM or Without STEAM

	- 1.0 Original Release
	- 1.1 Simplified
*/

#include <amxmodx>

public plugin_init()
	register_plugin("Connect Message STEAM Info", "1.1", "PROTECTOR");

public client_putinserver(id)
{
	if(is_user_steam(id))
		client_print_color(0, print_team_default, "^4[INFO] ^1Player ^3%n ^1Connected ^4With STEAM!", id);
	else
		client_print_color(0, print_team_default, "^4[INFO] ^1Player ^3%n ^1Connected ^4Without STEAM!", id);
}

bool:is_user_steam(id)
{
	static iPointer;

	if(iPointer || (iPointer = get_cvar_pointer("dp_r_id_provider")))
	{
		server_cmd("dp_clientinfo %d", id);
		server_exec();

		return get_pcvar_num(iPointer) == 2;
	}

	return false;
}