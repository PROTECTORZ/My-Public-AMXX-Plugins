#include <amxmodx>
#include <customshop>
#include <reapi>
#include <fakemeta>
#include <hamsandwich>

enum Cvars
{
    ENABLED,
    Float:HEIGHT,
    Float:LENGTH,
    Float:COOLDOWN
}

new item_longjump;
new g_Cvars[Cvars];
new Float:g_fLastJumpTime[MAX_PLAYERS + 1];
new bool:g_bLongjump[33];
new SpeedLimit;

public plugin_init()
{
    register_plugin("LongJump", "1.1", "PROTECTOR");
    
    bind_pcvar_num(create_cvar("jump_enabled", "1", FCVAR_NONE, "Enable/Disable the longjump plugin"), g_Cvars[ENABLED]);
    bind_pcvar_float(create_cvar("jump_height", "300.0", FCVAR_NONE, "Height of the jump"), g_Cvars[HEIGHT]);
    bind_pcvar_float(create_cvar("jump_length", "500.0", FCVAR_NONE, "Length of the jump"), g_Cvars[LENGTH]);
    bind_pcvar_float(create_cvar("jump_cooldown", "5.0", FCVAR_NONE, "Cooldown between jumps in seconds"), g_Cvars[COOLDOWN]);
    
    RegisterHookChain(RG_CBasePlayer_Jump, "Hook_PlayerJump", 1);
    RegisterHam(Ham_Player_Jump, "player", "Hook_BunnyHop", 1);
    
    SpeedLimit = get_cvar_id("speed_limit");
}

public plugin_precache()
{
    for (new i = 0; i <= MAX_PLAYERS; i++) {
        g_fLastJumpTime[i] = 0.0;
    }
    
    item_longjump = cshop_register_item("longjump", "LongJump + BunnyHop", 5000);
}

public cshop_item_selected(id, item)
{
    if(item == item_longjump) {
        g_bLongjump[id] = true;
    }
    
    return BUY_ITEM;
}

public cshop_item_removed(id, item)
{
    if(item == item_longjump) {
        g_bLongjump[id] = false;
    }
}

public Hook_BunnyHop(id)
{
    if (!g_bLongjump[id] || !is_user_alive(id))
        return HAM_IGNORED;
        
    if(pev(id, pev_flags) & FL_ONGROUND && pev(id, pev_oldbuttons) & IN_JUMP)
    {
        static Float:velocity[3];
        pev(id, pev_velocity, velocity);
        velocity[2] = velocity[2] + 285.0;
        set_pev(id, pev_velocity, velocity);
        set_pev(id, pev_gaitsequence, 6);
        
        if(xvar_speed_limita != -1)
        {
            set_xvar_num(xvar_speed_limita, get_xvar_num(xvar_speed_limita) | (1 << (id & 31)));
        }
    }
    
    return HAM_IGNORED;
}

public Hook_PlayerJump(const id)
{
    if (!g_Cvars[ENABLED])
        return HC_CONTINUE;
    
    if (!is_user_alive(id))
        return HC_CONTINUE;
    
    if (!g_bLongjump[id])
        return HC_CONTINUE;
    
    new Float:currentTime = get_gametime();
    
    if (currentTime - g_fLastJumpTime[id] < g_Cvars[COOLDOWN]) {
        return HC_CONTINUE;
    }
    
    if (!(get_entvar(id, var_button) & IN_JUMP) || !(get_entvar(id, var_button) & IN_FORWARD))
        return HC_CONTINUE;
    
    new Float:velocity[3];
    get_entvar(id, var_velocity, velocity);
    
    new Float:angles[3];
    get_entvar(id, var_angles, angles);
    
    new Float:forwardVector[3];
    angle_vector(angles, ANGLEVECTOR_FORWARD, forwardVector);
    
    velocity[0] += forwardVector[0] * g_Cvars[LENGTH];
    velocity[1] += forwardVector[1] * g_Cvars[LENGTH];
    velocity[2] = g_Cvars[HEIGHT];
    
    set_entvar(id, var_velocity, velocity);
    
    g_fLastJumpTime[id] = currentTime;
    
    return HC_CONTINUE;
}