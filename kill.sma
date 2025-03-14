#include <amxmodx>
#include <amxmisc>
#include <reapi>  

#define PLUGIN "Kill Sound"
#define VERSION "1.0"
#define AUTHOR "PROTECTOR"

new g_KillSoundPath[] = "kill/blip1.wav"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
    register_event("DeathMsg", "EventDeathMsg", "a")
}

public plugin_precache()
{
    precache_sound(g_KillSoundPath)
}

public EventDeathMsg()
{
    new killer = read_data(1)
    
    new victim = read_data(2)
    
    if (killer && is_user_connected(killer) && killer != victim)
    {
        rg_play_user_sound(killer, g_KillSoundPath, true)
    }
}