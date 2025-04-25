#include <amxmodx>
#include <amxmisc>
#include <cromchat>
#include <customshop>
#include <fun>
#include <cstrike>

#define PLUGIN "Race System"
#define VERSION "1.2"
#define AUTHOR "IDK Who is the author"

new g_Challenger[33];
new g_RacingWith[33];
new g_Terrorist = 0;
new bool:g_RaceStarted = false;
new g_CountdownTimer = 0;

forward race_countdown()
forward event_death()
forward event_round_end()
forward client_disconnected(id)

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_clcmd("say /race", "cmd_race");
    register_event("DeathMsg", "event_death", "a");
    register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
    register_event("SendAudio", "event_round_end", "a", "2=%!MRAD_terwin", "2=%!MRAD_ctwin", "2=%!MRAD_rounddraw");
    register_logevent("event_round_restart", 2, "1=Round_Start");
}

public event_round_start()
{
    arrayset(g_Challenger, 0, 33);
    arrayset(g_RacingWith, 0, 33);
    g_Terrorist = 0;
    respawn_racers();
    new players[32], num;
    get_players(players, num, "he", "TERRORIST");
    if (num > 0)
    {
        g_Terrorist = players[0];
    }
}

public respawn_racers()
{
    for (new id = 1; id <= 32; id++)
    {
        if (g_RacingWith[id] != 0 && is_user_connected(id) && is_user_alive(id))
        {
            user_kill(id);
            set_task(0.1, "respawn_player", id);
        }
    }
}

public respawn_player(id)
{
    if (is_user_connected(id))
    {
        cs_user_spawn(id);
    }
}

public cmd_race(id)
{
    if (g_RaceStarted)
    {
        CC_SendMessage(id, "&x04[RACE]: &x01A race is already in progress!");
        return PLUGIN_HANDLED;
    }

    if (cs_get_user_team(id) != CS_TEAM_CT)
    {
        CC_SendMessage(id, "&x04[RACE]: &x04Only CTs can use /race&x01.");
        return PLUGIN_HANDLED;
    }

    new menu = menu_create("Select a player to challenge:", "menu_handler");
    new players[32], num, player;
    get_players(players, num, "he", "CT");
    
    new added = 0;
    for (new i = 0; i < num; i++)
    {
        player = players[i];
        if (player != id)
        {
            new name[32];
            get_user_name(player, name, 31);
            menu_additem(menu, name, fmt("%d", player));
            added++;
        }
    }
    
    if (added == 0)
    {
        CC_SendMessage(id, "&x04[CSBG]: &x04No other CT players to challenge&x01.");
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    new challenger_name[32];
    get_user_name(id, challenger_name, 31);
    CC_SendMessage(0, "&x04[RACE]: &x03%s &x01is looking for a race! Type /race to challenge them.", challenger_name);
    
    menu_display(id, menu);
    return PLUGIN_HANDLED;
}

public menu_handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new info[6], name[32];
    menu_item_getinfo(menu, item, _, info, 5, name, 31);
    new target = str_to_num(info);

    if (!is_user_connected(target))
    {
        CC_SendMessage(id, "&x04[CSBG]: &x04Player is no longer connected&x01.");
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    if (g_Challenger[target] != 0)
    {
        CC_SendMessage(id, "&x04[CSBG]: &x04That player has already been challenged&x01.");
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    g_Challenger[target] = id;
    new challenger_name[32], target_name[32];
    get_user_name(id, challenger_name, 31);
    get_user_name(target, target_name, 31);
    
    CC_SendMessage(0, "&x04[RACE]: &x03%s &x04has challenged &x03%s &x04to a race!", challenger_name, target_name);
    CC_SendMessage(target, "&x04[RACE]: &x03%s &x04has challenged you to a race! Check the menu to accept or decline.", challenger_name);
    CC_SendMessage(id, "&x04[RACE]: &x01You have challenged &x03%s &x01to a race.", target_name);

    new challenge_menu = menu_create(fmt("%s has challenged you to a race!", challenger_name), "challenge_menu_handler");
    menu_additem(challenge_menu, "Accept", fmt("%d", id));
    menu_additem(challenge_menu, "Decline", fmt("%d", id));
    menu_display(target, challenge_menu);

    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

public challenge_menu_handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new info[6];
    menu_item_getinfo(menu, item, _, info, 5);
    new challenger = str_to_num(info);

    if (!is_user_connected(challenger))
    {
        CC_SendMessage(id, "&x04[CSBG]: &x04The challenger is no longer connected&x01.");
        g_Challenger[id] = 0;
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    if (item == 0)
    {
        if (g_RacingWith[id] != 0 || g_RacingWith[challenger] != 0)
        {
            CC_SendMessage(id, "&x04[CSBG]: &x04You or the challenger is already in a race&x01.");
            g_Challenger[id] = 0;
            menu_destroy(menu);
            return PLUGIN_HANDLED;
        }

        g_RacingWith[id] = challenger;
        g_RacingWith[challenger] = id;
        g_Challenger[id] = 0;

        new name1[32], name2[32];
        get_user_name(id, name1, 31);
        get_user_name(challenger, name2, 31);
        CC_SendMessage(0, "&x04[RACE]: &x03%s &x04accepted &x01the race challenge from &x03%s&x01. Prepare for race!", name1, name2);
    
        cs_user_spawn(id);
        cs_user_spawn(challenger);
    
        set_user_godmode(id, 1);
        set_user_godmode(challenger, 1);
        set_user_maxspeed(id, 0.1);
        set_user_maxspeed(challenger, 0.1);
        
        g_CountdownTimer = 3;
        set_task(1.0, "race_countdown", 0, "", 0, "a", 4);
    }
    else if (item == 1)
    {
        new name1[32], name2[32];
        get_user_name(id, name1, 31);
        get_user_name(challenger, name2, 31);
        CC_SendMessage(challenger, "&x04[RACE]: &x03%s &x01declined your race challenge.", name1);
        CC_SendMessage(id, "&x04[RACE]: &x01You declined the race challenge from &x03%s&x01.", name2);
        g_Challenger[id] = 0;
    }

    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

public race_countdown()
{
    g_CountdownTimer--;
    
    if (g_CountdownTimer > 0)
    {
        CC_SendMessage(0, "&x04[RACE]: &x01Race starts in &x03%d&x01...", g_CountdownTimer);
    }
    else
    {
        CC_SendMessage(0, "&x04[RACE]: &x04GO! &x01The race has begun!");
        
        for (new id = 1; id <= 32; id++)
        {
            if (g_RacingWith[id] != 0 && is_user_connected(id))
            {
                set_user_godmode(id, 0);
                set_user_maxspeed(id, 250.0);
            }
        }
        
        g_RaceStarted = true;
    }
}

public event_death()
{
    new killer = read_data(1);
    new victim = read_data(2);

    if (killer == victim || !killer)
        return;

    if (cs_get_user_team(killer) == CS_TEAM_CT && victim == g_Terrorist)
    {
        if (g_RacingWith[killer] != 0)
        {
            new opponent = g_RacingWith[killer];
            if (is_user_connected(opponent))
            {
                cshop_give_points(killer, 20);
                cshop_give_points(opponent, -20);

                new killer_name[32], opponent_name[32];
                get_user_name(killer, killer_name, 31);
                get_user_name(opponent, opponent_name, 31);
                CC_SendMessage(0, "&x04[CSBG]: &x03%s &x04wins &x01the race vs &x03%s&x01. &x04Gained 20 points&x01.", killer_name, opponent_name);
                CC_SendMessage(0, "&x04[CSBG]: &x03%s &x01loses the race vs &x03%s&x01. Lost 20 points.", opponent_name, killer_name);
            }

            g_RacingWith[killer] = 0;
            g_RacingWith[opponent] = 0;
            g_RaceStarted = false;
        }
    }
    else if (cs_get_user_team(victim) == CS_TEAM_CT && g_RacingWith[victim] != 0)
    {
        new opponent = g_RacingWith[victim];
        if (is_user_connected(opponent))
        {
            cshop_give_points(victim, -20);
            cshop_give_points(opponent, 20);

            new victim_name[32], opponent_name[32];
            get_user_name(victim, victim_name, 31);
            get_user_name(opponent, opponent_name, 31);
            CC_SendMessage(0, "&x04[CSBG]: &x03%s &x01died during the race and loses! Lost 20 points.", victim_name);
            CC_SendMessage(0, "&x04[CSBG]: &x03%s &x04wins &x01the race because opponent died! &x04Gained 20 points&x01.", opponent_name);
        }

        g_RacingWith[victim] = 0;
        g_RacingWith[opponent] = 0;
        g_RaceStarted = false;
    }
}

public event_round_end()
{
    for (new id = 1; id <= 32; id++)
    {
        if (g_RacingWith[id] != 0)
        {
            new opponent = g_RacingWith[id];
            if (is_user_connected(opponent) && id < opponent)
            {
                if (g_Terrorist == 0 || is_user_alive(g_Terrorist) || !is_user_connected(g_Terrorist))
                {
                    cshop_give_points(id, -20);
                    cshop_give_points(opponent, -20);

                    new name1[32], name2[32];
                    get_user_name(id, name1, 31);
                    get_user_name(opponent, name2, 31);
                    CC_SendMessage(0, "&x04[CSBG]: &x03%s &x01and &x03%s &x01both lose the race. Lost 20 points each.", name1, name2);
                }
            }
            g_RacingWith[id] = 0;
        }
    }
    g_RaceStarted = false;
}

public client_disconnected(id)
{
    if (g_RacingWith[id] != 0)
    {
        new opponent = g_RacingWith[id];
        if (is_user_connected(opponent))
        {
            new id_name[32], opponent_name[32];
            get_user_name(id, id_name, 31);
            get_user_name(opponent, opponent_name, 31);
            
            cshop_give_points(opponent, 20);
            
            CC_SendMessage(0, "&x04[CSBG]: &x03%s &x01disconnected during the race against &x03%s&x01!", id_name, opponent_name);
            CC_SendMessage(0, "&x04[CSBG]: &x03%s &x04wins &x01the race by default! &x04Gained 20 points&x01.", opponent_name);
            
            g_RacingWith[opponent] = 0;
        }
        g_RacingWith[id] = 0;
    }

    if (g_Challenger[id] != 0)
    {
        new challenger = g_Challenger[id];
        if (is_user_connected(challenger))
        {
            new id_name[32], challenger_name[32];
            get_user_name(id, id_name, 31);
            get_user_name(challenger, challenger_name, 31);
            
            CC_SendMessage(0, "&x04[CSBG]: &x03%s &x01disconnected before responding to &x03%s's &x01race challenge!", id_name, challenger_name);
            CC_SendMessage(challenger, "&x04[CSBG]: &x04Your challenge has been canceled &x01because the player disconnected.");
        }
        g_Challenger[id] = 0;
    }

    for (new i = 1; i <= 32; i++)
    {
        if (g_Challenger[i] == id)
        {
            new i_name[32], id_name[32];
            get_user_name(i, i_name, 31);
            get_user_name(id, id_name, 31);
            
            g_Challenger[i] = 0;
            if (is_user_connected(i))
            {
                CC_SendMessage(0, "&x04[CSBG]: &x03%s &x01disconnected after challenging &x03%s &x01to a race!", id_name, i_name);
                CC_SendMessage(i, "&x04[CSBG]: &x04The challenge has been canceled &x01because the challenger disconnected.");
            }
        }
    }
}