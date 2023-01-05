#include <amxmodx>
#include <reapi>

#define PLUGIN  "KC with Hud"
#define VERSION "1.0"
#define AUTHOR  "PROTECTOR"
new killcounter[MAX_PLAYERS+1], killcounterHS[MAX_PLAYERS+1];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Post", true);
    RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn", true);
    
}
public client_connect(id){
    set_task(1.0, "countermessage", id, _, _, "b");
}
public CBasePlayer_Spawn(id){
    killcounter[id]=0;
    killcounterHS[id]=0;
}
public CBasePlayer_Killed_Post(victim, attacker) {
    if (victim == attacker || !is_user_connected(attacker) || !rg_is_player_can_takedamage(victim, attacker)) {
        return HC_CONTINUE;
    }
    killcounter[attacker]++
    if (get_member(victim, m_LastHitGroup) == HIT_HEAD) {
        killcounterHS[attacker]++;
    }
    return HC_CONTINUE;
}
public countermessage(id){
    set_dhudmessage(0, 255, 0, 0.0, -1.0, 0, 6.0, 0.9);
    show_dhudmessage(id, "%i (%i HS)",killcounter[id],killcounterHS[id]);
}
public client_disconnected(id){
    remove_task(id);
}