#include <amxmodx>
#include <fakemeta>

#define VERSION "1.3"

public plugin_init() 
{
    register_plugin("ScreenFade on Head Hit", VERSION, "PROTECTOR")
    register_event("Damage", "on_damage", "b", "2>0", "3=0")
}

public on_damage(victim)
{
    new attacker = get_user_attacker(victim)
    new damage = read_data(2)
    new weapon = get_user_weapon(attacker)
    
    if(!is_user_connected(attacker) || attacker == victim)
        return
        
    new hitgroup = get_pdata_int(victim, 75) 
    
    if(hitgroup == 1 && damage > 0 && weapon != CSW_KNIFE) 
    {
        message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, attacker)
        write_short(1<<10)    // Duration
        write_short(1<<10)    // Hold time
        write_short(0x0000)   // Fade type
        write_byte(0)         // Red
        write_byte(0)         // Green
        write_byte(200)       // Blue
        write_byte(80)        // Alpha
        message_end()
    }
}