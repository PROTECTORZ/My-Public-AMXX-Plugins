#include <amxmodx>
#include <geoip>
#include <reapi>

#define PLUGIN "Connect Message Info With ADM"
#define VERSION "1.0"
#define AUTHOR "PROTECTOR"

#define TAG "[INFO]"

#define Sound "buttons/bell1"

public plugin_init() register_plugin(PLUGIN, VERSION, AUTHOR);

public client_putinserver(id)
{
	static nick[32];
	static ip[16];
	static country[45];
	static city[45];
	
	get_user_name(id, nick, charsmax(nick));
	get_user_ip(id, ip, charsmax(ip), 1);
	geoip_country_ex(ip, country, charsmax(country));
	geoip_city(ip, city, charsmax(city));
	
	new name[33];
	get_user_name(id, name, 32);
	
	if(get_user_flags(id) & ADMIN_RESERVATION && is_user_steam(id)) client_print_color(0, 0, "^3%s ^4STEAM ADMIN ^3%s ^4Has Connected From ^1[^3%s^1]", TAG, name, country);
	else if(get_user_flags(id) & ADMIN_RESERVATION) client_print_color(0, 0, "^3%s ^4ADMIN ^3%s ^4Has Connected From ^1[^3%s^1]", TAG, name, country);
	else if(is_user_steam(id)) client_print_color(0, 0, "^3%s ^4STEAM Player ^3%s ^4Has Connected From^1[^3%s^1]", TAG, name, country);
	else client_print_color(0, 0, "^3%s ^4Player ^3%s ^4Has Connected From ^1[^3%s^1]", TAG, name, country);
	client_cmd(id,"spk ^"sound/%s^"", Sound)
}
