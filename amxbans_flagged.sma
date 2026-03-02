#include <amxmodx>
#include <amxmisc>
#include <amxbans_main>
#include "amxbans/color_chat.inl"

#define PLUGIN "AMXBans: Flagged"
#define VERSION "Gm 1.6"
#define AUTHOR "Larte Team"
#define PREFIX "!y[!tAMXBans!y]"

new player_reasons[33][100]  // Global array to store reasons
new flagged_left[33]
new g_maxplayers

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_dictionary("amxbans.txt")
   
    g_maxplayers = get_maxplayers()
   
    return color_chat_init()
}

public amxbans_player_flagged(id, sec_left, reason[])
{
    if(!is_user_connected(id))
    {
        return PLUGIN_HANDLED
    }
   
    if(sec_left <= 0)
    {
        flagged_left[id] = -1  // Permanent flag
    }
    else
    {
        flagged_left[id] = sec_left  // Time left in seconds
    }
    
    copy(player_reasons[id], 99, reason)
    
    return set_task(5.0, "announce", id)
}

public amxbans_player_unflagged(id)
{
    return remove_task(id)
}

public announce(id)
{
    new name[32], left_str[64]
    get_user_name(id, name, 31)
   
    if(flagged_left[id] == -1)
    {
        formatex(left_str, 63, "(!t%L!y)", LANG_PLAYER, "PERMANENT")
    }
    else if(flagged_left[id])
    {
        formatex(left_str, 63, "%L", LANG_PLAYER, "FLAGGED_TLEFT", flagged_left[id] / 60)
    }
    
    for(new i = 1; i <= g_maxplayers; i++)
    {
        if(!is_user_connected(i))
        {
            continue
        }
       
        if(get_user_flags(i) & ADMIN_CHAT)
        {
            ColorChat(i, RED, "%s %L", PREFIX, i, "FLAGGED_PLAYER", name, left_str, player_reasons[id])
        }
    }
   
    return PLUGIN_CONTINUE
}

public client_disconnected(id)
{
    return remove_task(id)
}