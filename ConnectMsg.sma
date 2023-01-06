/*This plugin shows When user Connects with STEAM or Without STEAM */

#include <amxmodx>

#define PLUGIN  "Connect Message Info"
#define VERSION "1.0"
#define AUTHOR  "PROTECTOR"


public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
}

public client_putinserver(id)
{
	set_task(5.0, "showinfo", id)
}

public showinfo(id)
{
new nick[32];
get_user_name(id, nick, charsmax(nick));
if(is_user_steam(id))
    {
        new message[64]
        for (new i = 0; i < 32; i++) {
            if(is_user_connected(i)){
                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, i);
                write_byte(i);
                formatex(message, charsmax(message), "^x04[INFO] ^x01Player ^x03%s ^x01Connected ^x04With STEAM!",nick)
                write_string(message);
                message_end();
            }
        }

    }
if(!is_user_steam(id))
    {
        new message[64]
        for (new i = 0; i < 32; i++) {
            if(is_user_connected(i)){
                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, i);
                write_byte(i);
                formatex(message, charsmax(message), "^x04[INFO] ^x01Player ^x03%s ^x04Connected ^x01Without STEAM!",nick)
                write_string(message);
                message_end();
            }
        }

    }
}

stock bool:is_user_steam(id)
{
    static dp_pointer;

    if(dp_pointer || (dp_pointer = get_cvar_pointer("dp_r_id_provider")))
    {
        server_cmd("dp_clientinfo %d", id);
        server_exec();
        return (get_pcvar_num(dp_pointer) == 2) ? true : false;
    }

    new szAuthid[34];
    get_user_authid(id, szAuthid, charsmax(szAuthid));

    return (containi(szAuthid, "LAN") < 0);
}