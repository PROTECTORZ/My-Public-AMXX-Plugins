/**
 * Decompiled by AMXX Decompiler
 * Debug info was available - original names recovered
 * Original source: string.inc
 * Original source: amxmisc.inc
 * Original source: colorchat.inc
 * Original source: mdbBansEN.sma
 */

#include <amxmodx>
#include <file>
#include <string>
#include <messages>
#include <cellarray>

new TeamName[4][0]
new admin[17]
new banfile[] = "addons/amxmodx/configs/mdbBans/bans.cfg"
new Array:banlist
new banmode
new bool:chatactive
new chatfile[64]
new configfile[] = "addons/amxmodx/configs/mdbBans/config.rc"
new cvarovi[18]
new dbanfile[] = "addons/amxmodx/configs/mdbBans/banlist.txt"
new debug_enable
new debugfile[] = "addons/amxmodx/configs/mdbBans/debug.txt"
new delay
new Array:g_bantimes
new g_menuOption[33]
new g_menuPlayerName[33][33]
new g_menuPlayers[33][32]
new g_menuPlayersNum[33]
new g_menuPosition[33]
new g_menuSettings[33]
new g_menuUserid[33]
new infofile[64]
new ip[17]
new logfile[65]
new logpath[64]
new Color:msgcolor_bans = 5
new Color:msgcolor_sys = 6
new noviCS[33]
new playermID[33][33]
new razlog[63]
new tempbanip[17]
new vreme

bool:is_str_num(sString[])
{
    new i

    while (sString[i] && isdigit(sString[i]))
    {
        i++
    }
    return !(sString[i]) && i
}

is_user_admin(id)
{
    new __flags

    __flags = get_user_flags(id, "%L")
    return (0 < __flags) && !((__flags & 33554432))
}

cmd_access(id, level, cid, num, bool:accesssilent)
{
    new hflag
    new hinfo[128]
    new hcmd[32]
    new has_access

    if ((id == !(is_dedicated_server())))
    {
        has_access = 1
    }
    else
    {
        if ((level == 16777216))
        {
            if (is_user_admin(id))
            {
                has_access = 1
            }
        }
        else
        {
            if ((level & get_user_flags(id, "%L")))
            {
                has_access = 1
            }
            else
            {
                if (!(level))
                {
                    has_access = 1
                }
            }
        }
    }
    if (!(has_access))
    {
        if (!(accesssilent))
        {
            console_print(id, "%L", id, "NO_ACC_COM")
        }
        return 0
    }
    if ((read_argc() < num))
    {
        // fill(hcmd, 0, 128)
        // fill(hinfo, 0, 512)
        get_concmd(cid, hcmd, g_var_1F, hflag, hinfo, g_var_7F, level, -1)
        console_print(id, "%L:  %s %s", id, "USAGE", hcmd, hinfo)
        return 0
    }
    return 1
}

access(id, level)
{
    if ((level == 16777216))
    {
        return is_user_admin(id)
    }
    if (!(level))
    {
        return 1
    }
    return (level & get_user_flags(id, "%L"))
}

cmd_target(id, arg[], flags)
{
    new imname[32]
    new player

    player = find_player("bl", arg)
    if (player)
    {
        if ((player != find_player("blj", arg)))
        {
            console_print(id, "%L", id, "MORE_CL_MATCHT")
            return 0
        }
    }
    else
    {
        player = find_player("c", arg)
        if (!(player) && (arg[0] == 35) && arg[1])
        {
            player = find_player("k", str_to_num((arg + 4)))
        }
    }
    if (!(player))
    {
        console_print(id, "%L", id, "CL_NOT_FOUND")
        return 0
    }
    if ((flags & IN_ATTACK))
    {
        get_user_flags(player, "%L")
        if ((get_user_flags(player, "%L") & IN_ATTACK) && pri)
        {
            // fill(imname, 0, 128)
            get_user_name(player, imname, g_var_1F)
            console_print(id, "%L", id, "CLIENT_IMM", imname)
            return 0
        }
    }
    if ((flags & "L"))
    {
        if (!(is_user_alive(player)))
        {
            // fill(imname, 0, 128)
            get_user_name(player, imname, g_var_1F)
            console_print(id, "%L", id, "CANT_PERF_DEAD", imname)
            return 0
        }
    }
    if ((flags & IN_FORWARD))
    {
        if (is_user_bot(player))
        {
            // fill(imname, 0, 128)
            get_user_name(player, imname, g_var_1F)
            console_print(id, "%L", id, "CANT_PERF_BOT", imname)
            return 0
        }
    }
    return player
}

ColorChat(id, Color:type, msg[])
{
    new MSG_Type
    new index
    new ColorChange
    new team
    new message[256]

    // fill(message, 0, 1024)
    switch (type)
    {
        case 1:
            message[0] = 1
            break
        case 2:
            message[0] = "L"
            break
        default:
    }
    message[0] = 3
    // goto 0xC08
    vformat((message + 4), g_var_FB, msg, 4)
    message[192] = 0
    if (id)
    {
        MSG_Type = 1
        index = id
    }
    else
    {
        index = FindPlayer()
        MSG_Type = 2
    }
    team = get_user_team(index, "%L")
    ColorChange = ColorSelection(index, MSG_Type, type)
    ShowColorMessage(index, MSG_Type, message)
    if (ColorChange)
    {
        Team_Info(index, MSG_Type, TeamName[team] * 2)
    }
}

ShowColorMessage(id, type, message[])
{
    static get_user_msgid_saytext
    static bool:saytext_used

    if (!(saytext_used))
    {
        get_user_msgid_saytext = get_user_msgid("SayText")
        saytext_used = 1
    }
    message_begin(type, get_user_msgid_saytext, g_var_290, id)
    write_byte(id)
    write_string(message)
    message_end()
}

Team_Info(id, type, team[])
{
    static get_user_msgid_teaminfo
    static bool:teaminfo_used

    if (!(teaminfo_used))
    {
        get_user_msgid_teaminfo = get_user_msgid("TeamInfo")
        teaminfo_used = 1
    }
    message_begin(type, get_user_msgid_teaminfo, g_var_290, id)
    write_byte(id)
    write_string(team)
    message_end()
    return 1
}

ColorSelection(index, type, Color:Type)
{
    switch (Type)
    {
        case 4:
            return Team_Info(index, type, (TeamName[0] + TeamName))
            break
        case 5:
            return Team_Info(index, type, (TeamName[1] + (TeamName + 4)))
            break
        case 6:
            return Team_Info(index, type, (TeamName[2] + (TeamName + 8)))
            break
        default:
    }
}

FindPlayer()
{
    new i

    while ((i <= get_maxplayers()))
    {
        i++
        if (is_user_connected(i))
        {
            return i
        }
    }
    return -1
}

rmdir2(dir[])
{
    static tempfile[1024]

    new len
    new hDir

    len = strlen(dir)
    copy(tempfile, g_var_3FF, dir)
    if (!(((tempfile[(len - 1)] == 47) || (tempfile[(len - 1)] == g_var_5C))))
    {
        len++
        tempfile[len] = g_var_5C
        tempfile[len] = 0
    }
    hDir = open_dir(dir, tempfile[len], (g_var_3FF - len))
    if (!(hDir))
    {
        return 0
    }
    if ((equal(tempfile[len], ".", "%L") || equal(tempfile[len], "..", "%L")))
    {
    }
    else
    {
        if (dir_exists(tempfile))
        {
            if (!(rmdir2(tempfile)))
            {
                return 0
            }
        }
        else
        {
            if (!(delete_file(tempfile)))
            {
                return 0
            }
        }
    }
    if (next_file(hDir, tempfile[len], (g_var_3FF - len)))
    {
        continue
    }
    close_dir(hDir)
    dir[len] = 0
    rmdir(dir)
    return 1
}

public plugin_init()
{
    register_plugin("mdbBans", "4.8", "Desikac")
    register_concmd("amx_tban", "cmd_tban", "", "<nick> <time> <reason> - Smart ban.", -1)
    register_concmd("amx_mban", "cmd_tban", "", "<nick> <time> <reason> - Smart ban.", -1)
    register_concmd("amx_mkick", "cmd_mkick", "", "<nick> <reason> - Kick a player.", -1)
    register_concmd("amx_mbanid", "cmd_tban", "", "<STEAM/VALVE ID> - Ban a player by Steam ID.", -1)
    register_concmd("amx_mbanip", "cmd_tban", "", "<IP> - Ban a player by IP..", -1)
    register_concmd("amx_munban", "RemoveBan", "", "<STEAM/VALVE ID/IP> - Unbans a player.", -1)
    register_concmd("amx_writeban", "cmd_writeban", "", "<STEAM ID/IP/mID> <time> - Write the specified ID into the banlist.", -1)
    register_concmd("amx_bann", "cmd_tban", "", "<nick> <time> <reason> - Smart ban.", -1)
    register_concmd("amx_pwn", "cmd_tban", "", "<nick> <time> <reason> - Smart ban + causes lag to the player.", -1)
    register_concmd("amx_dynban", "cmd_tban", "", "<nick> <time> <reason> - Smart ban.", -1)
    register_concmd("amx_mcensure", "cmd_tban", "", "<nick> <time> <reason> - Smart ban + causes lag to the player.", -1)
    register_concmd("amx_addban", "cmd_writeban", "", "<STEAM ID/IP/mID> <time> - Ban the specified ID/IP/mID.", -1)
    register_concmd("amx_ss", "cmdExec", "", "-  <nick> - Take a screenshot of the player.", -1)
    register_concmd("amx_mexec", "cmdExec", "", "-  <nick> <komanda> - Execute a command on the player.", -1)
    register_concmd("amx_mbanmenu", "cmdBanMenu", "", "- Ban menu.", -1)
    register_clcmd("mdbbansmenu", "mdb_menu", "", "- mdbBans plugin menu.", -1)
    register_concmd("mstatus", "mstatus", "", "- List of players and their IDs.", -1)
    register_clcmd("say /mid", "showmID", -1, g_var_63BC, -1)
    register_srvcmd("amx_mbantimes", "setbantimes", -1, g_var_6428)
    register_menucmd(register_menuid("Ban Menu", "%L"), g_var_3FF, "actionBanMenu")
    register_menucmd(register_menuid("banmenu_forward", "%L"), g_var_3FF, "BanMenuForward")
    register_menucmd(register_menuid("mdb Menu", "%L"), g_var_3FF, "actionmdbMenu")
    register_menucmd(register_menuid("Profile Menu", "%L"), g_var_3FF, "actionprofileMenu")
    register_menucmd(register_menuid("Reset Menu", "%L"), g_var_3FF, "actionresetMenu")
    register_clcmd("say", "logsay", -1, g_var_63BC, -1)
    register_clcmd("say_team", "logteamsay", -1, g_var_63BC, -1)
    register_clcmd("logadminsay", "logadmin", -1, g_var_63BC, -1)
    register_clcmd("cheat", "cheat", -1, g_var_63BC, -1)
    register_clcmd("checkeXec", "cscheck", -1, g_var_63BC, -1)
    g_bantimes = ArrayCreate(1, g_var_20)
    ArrayPushCell(g_bantimes, g_var_12C)
    ArrayPushCell(g_bantimes, "%L")
    ArrayPushCell(g_bantimes, "")
    ArrayPushCell(g_bantimes, 10)
    ArrayPushCell(g_bantimes, g_var_1E)
    ArrayPushCell(g_bantimes, g_var_3C)
    ArrayPushCell(g_bantimes, g_var_78)
    cvarovi[0] = register_cvar("mdb_show_activity", "2", "%L", "%L")
    cvarovi[1] = register_cvar("amx_bantext", g_var_6810, "%L", "%L")
    cvarovi[2] = register_cvar("amx_kicktext", g_var_6848, "%L", "%L")
    cvarovi[3] = register_cvar("amx_demotext", "Welcome to the server! A demo is automatically being recorded.", "%L", "%L")
    cvarovi[4] = register_cvar("amx_demoname", "mdbBans", "%L", "%L")
    cvarovi[5] = register_cvar("amx_autodemo", "1", "%L", "%L")
    cvarovi[6] = register_cvar("amx_announce", "3", "%L", "%L")
    cvarovi[7] = register_cvar("amx_banmenu_mode", "3", "%L", "%L")
    cvarovi[8] = register_cvar("amx_banmode", "1", "%L", "%L")
    cvarovi[9] = register_cvar("amx_logchat", "1", "%L", "%L")
    cvarovi[10] = register_cvar("amx_infologger", "1", "%L", "%L")
    cvarovi[11] = register_cvar("amx_immunity", "0", "%L", "%L")
    cvarovi[12] = register_cvar("amx_webban", "0", "%L", "%L")
    cvarovi[13] = register_cvar("amx_pwn_enable", "1", "%L", "%L")
    cvarovi[16] = register_cvar("amx_msgcolor_bans", "2", "%L", "%L")
    cvarovi[17] = register_cvar("amx_msgcolor_system", "3", "%L", "%L")
    cvarovi[14] = register_cvar("mdb_banduritation", "5", "%L", "%L")
    cvarovi[15] = register_cvar("mIDprefix", "0", "%L", "%L")
    register_cvar("mdbBans", "2", g_var_44, "%L")
    register_cvar("mdb_profile", "0", "%L", "%L")
    server_cmd("exec addons/amxmodx/configs/mdbBans/config.rc")
    server_cmd("bannedcfgfile temp_bans.cfg")
    banlist = ArrayCreate(g_var_55, g_var_20)
    set_task(0.5, "precache", "%L", g_var_6ED0, "%L", g_var_6ED4, "%L")
    set_task(1.0, "firstrun", "%L", g_var_6ED0, "%L", g_var_6ED4, "%L")
    set_task(1.5, "masstask", "%L", g_var_6ED0, "%L", g_var_6ED4, "%L")
    set_task(60.0, "ifbanned", 4322633, g_var_6ED0, "%L", g_var_6ED4, "%L")
}

public client_command(id)
{
    new params[96]
    new command[15]

    // fill(command, 0, 60)
    read_argv("%L", command, 14)
    // fill(params, 0, 384)
    read_args(params, g_var_5F)
    if ((equali(command, "amx_ban", "%L") || equali(command, "amx_kick", "%L") || equali(command, "amx_banid", "%L") || equali(command, "amx_banip", "%L") || equali(command, "amx_unban", "%L") || equali(command, "amx_censure", "%L") || equali(command, "amx_banmenu", "%L")))
    {
        client_cmd(id, "amx_m%s %s", (command + 16), params)
        return 1
    }
    if (equali(command, "amx_addban", "%L"))
    {
        client_cmd(id, "amx_writeban %s", params)
        return 1
    }
    if ((equali(command, "amx_say", "%L") || equali(command, "amx_chat", "%L") || equali(command, "amx_csay", "%L") || equali(command, "amx_tsay", "%L") || equali(command, "amx_fsay", "%L") || equali(command, "amx_psay", "%L")))
    {
        if (((get_user_flags(id, "%L") & g_var_100) || equali(command, "amx_chat", "%L")))
        {
            client_cmd(id, "logadminsay (*%s): %s", command, params)
        }
    }
}

public cmd_tban(id, level, cid)
{
    new banduritation
    new shouldi
    new nomid
    new bantype
    new koliko[32]
    new mip[16]
    new times[20]
    new banurl[128]
    new debugtext[397]
    new bantext[96]
    new authid[24]
    new madmin[32]
    new name[32]
    new logtext[255]
    new player
    new pwnage
    new cmd[16]
    new minutesi
    new reason[64]
    new minutes[9]
    new customban
    new arg[32]

    // fill(arg, 0, 128)
    read_argv(1, arg, g_var_1F)
    if (!(cmd_access(id, level, cid, 2, "%L")))
    {
        if (strlen(arg))
        {
            ColorChat(id, msgcolor_sys, "[mdbBans] You have no access to use that command!")
        }
        return 1
    }
    if (delay)
    {
        ColorChat(id, msgcolor_sys, "[mdbBans] A ban is already in progress. Please wait...")
        return 1
    }
    // fill(minutes, 0, 36)
    // fill(reason, 0, 256)
    // fill(cmd, 0, 64)
    read_argv(2, minutes, "")
    read_argv(3, reason, g_var_3F)
    read_argv("%L", cmd, 15)
    if ((equal(cmd, "amx_pwn", "%L") || equal(cmd, "amx_mcensure", "%L")))
    {
        if (!(get_pcvar_num(cvarovi[13])))
        {
            client_print(id, print_console, "[mdbBans] The server owner has disabled that type of ban.")
            return 1
        }
        pwnage = 1
    }
    if (equal(cmd, "amx_mbanid", "%L"))
    {
        customban = 2
        client_print(id, print_console, "[mdbBans] Banning client's ID...")
    }
    if (equal(cmd, "amx_mbanip", "%L"))
    {
        client_print(id, print_console, "[mdbBans] Banning client's IP...")
        customban = 1
    }
    if (!(get_pcvar_num(cvarovi[11])) && (get_user_flags(id, "%L") & IN_ATTACK2))
    {
        player = cmd_target(id, arg, 10)
    }
    else
    {
        player = cmd_target(id, arg, 11)
    }
    if (!(is_user_connected(player)))
    {
        return 1
    }
    if ((get_user_protocol(player) == 1) && (customban == 2))
    {
        customban = 0
        ColorChat(id, msgcolor_sys, "[mdbBans] Targeted player can't be banned by ID.")
        client_print(id, print_console, "[mdbBans] Targeted player can't be banned by ID.")
        return 1
    }
    if (!(is_str_num(minutes)))
    {
        client_print(id, print_console, "[mdbBans] Command argument missmatch. Correct usage: \"<nick>\" <time> \"<reason>\"")
        return 1
    }
    minutesi = str_to_num(minutes)
    // fill(logtext, 0, 1020)
    // fill(name, 0, 128)
    // fill(madmin, 0, 128)
    // fill(authid, 0, 96)
    // fill(bantext, 0, 384)
    // fill(debugtext, 0, 1588)
    // fill(banurl, 0, 512)
    // fill(times, 0, 80)
    // fill(mip, 0, 64)
    get_fixed_ip(player)
    // fill(koliko, 0, 128)
    shouldi = get_pcvar_num(cvarovi[0])
    banduritation = get_pcvar_num(cvarovi[14])
    if ((!(minutesi) || (" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -" < minutesi)))
    {
        banduritation = (banduritation + 44000)
    }
    else
    {
        banduritation = (minutesi + banduritation)
    }
    get_time("[%d.%m - %H:%M]", times, 19)
    get_user_name(id, madmin, g_var_1F)
    get_user_name(player, name, g_var_1F)
    get_user_authid(player, authid, g_var_17)
    get_pcvar_string(cvarovi[1], banurl, g_var_7F)
    if (((get_user_protocol(player) == 1) && (2 != customban) || (customban == 1)))
    {
        bantype = 2
    }
    else
    {
        bantype = 1
    }
    if (!(playermID[player][0]))
    {
        nomid = 1
    }
    formatex(admin, 16, "%s", madmin)
    formatex(razlog, g_var_1F, "%s", reason)
    vreme = minutesi
    formatex(ip, 16, "%s", mip)
    formatex(logtext, g_var_FE, "%s Admin %s %s %s for %s minutes. Reason: %s. ID: %s , IP: %s , mID: %s", times, madmin, pri)
    switch (bantype)
    {
        case 1:
            if (((customban == 2) || (get_user_protocol(player) == 3)))
            {
                formatex(bantext, g_var_5F, "%s -- %s -- +%d", name, authid, banduritation)
            }
            else
            {
                if ((nomid || !(banmode)))
                {
                    formatex(bantext, g_var_5F, "%s -- %s -- %s -- +%d", name, mip, authid, banduritation)
                }
                else
                {
                    formatex(bantext, g_var_5F, "%s -- m%s -- %s -- +%d", name, playermID[player] * 2, authid, banduritation)
                }
            }
            break
        case 2:
            if ((nomid || !(banmode) || (customban == 1)))
            {
                formatex(bantext, g_var_5F, "%s -- %s -- +%d", name, mip, banduritation)
            }
            else
            {
                formatex(bantext, g_var_5F, "%s -- m%s -- %s -- +%d", name, playermID[player] * 2, mip, banduritation)
            }
            break
        default:
    }
    customban = 0
    write_file(logfile, logtext, -1)
    write_file(banfile, bantext, -1)
    ArrayPushString(banlist, bantext)
    delay = 1
    set_task(2.5, "remove_delay", "%L", g_var_6ED0, "%L", g_var_6ED4, "%L")
    if ((shouldi == 2))
    {
        formatex(logtext, g_var_FE, "%s+%d %s -%%- %s -%%- %s -%%- %s -%%- %s -%%- %s -%%- %s -%%- %s", pri)
    }
    else
    {
        formatex(logtext, g_var_FE, "%s+%d %s -%%- %s -%%- %s -%%- %s -%%- %s -%%- %s -%%- [hidden] -%%- %s", pri)
    }
    if (get_pcvar_num(cvarovi[12]))
    {
        write_file(dbanfile, logtext, -1)
    }
    if (pwnage)
    {
        set_task(0.3, "ovnovanje", player, g_var_6ED0, "%L", g_var_6ED4, "%L")
        client_cmd(player, "fps_max 4")
        switch (shouldi)
        {
            case 0:
                break
            case 2:
                ColorChat("%L", msgcolor_bans, "^x01 Admin^x03 %s:^x01 pwned^x03 %s^x01 for^x04 %s^x01 minutes , reason:^x04 %s.", madmin, name, minutes, reason)
                break
            default:
        }
        ColorChat("%L", msgcolor_bans, "^x01 Admin pwned^x03 %s^x01 for^x04 %s^x01 minutes , reason:^x04 %s.", name, minutes, reason)
        // goto 0x44CC
        return 1
    }
    set_task(2.5, "bantask", player, g_var_6ED0, "%L", g_var_6ED4, "%L")
    if ((1 > minutesi))
    {
        formatex(koliko, g_var_1F, "^x04permanently")
    }
    else
    {
        formatex(koliko, g_var_1F, "for^x04 %d minutes", minutesi)
    }
    client_cmd(player, "stop; net_graph 3")
    client_print(player, print_console, "- - - - - - - - YOU ARE BANNED - - - - - - -")
    switch (shouldi)
    {
        case 2:
            client_print(player, print_console, "Admin %s banned you %s, reason: %s.", madmin, koliko, reason)
            ColorChat("%L", msgcolor_bans, "^x01 Admin^x03 %s:^x01 ban^x03 %s^x01 %s^x01 , reason:^x04 %s.", madmin, name, koliko, reason)
            client_print(player, print_console, "%s", banurl)
            client_print(player, print_console, "Admin: %s ---- Time: %s ---- IP: %s", madmin, times, mip)
            ColorChat(player, msgcolor_bans, "Admin:^x04 %s^x03 ---- Time:^x04 %s^x03 ---- IP:^x04 %s", madmin, times, mip)
            break
        default:
    }
    client_print(player, print_console, "Admin banned you %s, reason: %s.", koliko, reason)
    if (shouldi)
    {
        ColorChat("%L", msgcolor_bans, "^x01 Admin: ban^x03 %s^x04 %s,^x01 reason:^x04 %s.", name, koliko, reason)
    }
    client_print(player, print_console, "%s", banurl)
    ColorChat(player, msgcolor_bans, "Admin:^x04 <hidden>^x03 ---- Time:^x04 %s^x03 ---- IP:^x04 %s", times, mip)
    client_print(player, print_console, "Admin: <hidden> ---- Time: %s ---- IP: %s", times, mip)
    client_print(player, print_console, "Admi name si hidden due to settings on the server.")
    // goto 0x4954
    ColorChat(player, msgcolor_bans, "Nick:^x04 %s^x03  ----- ID:^x04 %s^x03 ---- mID:^x04 %s", name, authid, playermID[player] * 2)
    ColorChat(player, msgcolor_bans, "Reason:^x04 %s^x03 ---- Duration:^x04 %s", reason, koliko)
    client_print(player, print_chat, "%s", banurl)
    client_print(player, print_console, "Nick: %s  ----- ID: %s ---- mID: %s", name, authid, playermID[player] * 2)
    client_print(player, print_console, "Reason: %s ---- Duration: %s", reason, koliko)
    client_print(player, print_console, "- - - - - - - - - - - - - - - - - - - - -")
    set_task(0.7, "takess", player, g_var_6ED0, "%L", g_var_6ED4, "%L")
    if ((5 < minutesi))
    {
        set_task(3.8, "mbankick", player, g_var_6ED0, "%L", g_var_6ED4, "%L")
    }
    if (debug_enable)
    {
        formatex(debugtext, g_var_18C, "%s BAN admin %s^nbanmode: %d, bantype: %d, customban: %d, nomid: %d, protocol: %d^nbantext: %s^ncmd: %s, authid: %s, ip: %s, mid: %s^n", times, madmin, banmode, bantype, customban, nomid, get_user_protocol(player), bantext, cmd, authid, mip, playermID[player] * 2)
        write_file(debugfile, debugtext, -1)
    }
    return 1
}

public cmd_mkick(id, level, cid)
{
    new times[20]
    new madmin[32]
    new name[32]
    new logtext[128]
    new player
    new reason[64]
    new arg[32]

    // fill(arg, 0, 128)
    read_argv(1, arg, g_var_1F)
    if (!(cmd_access(id, level, cid, 2, "%L")))
    {
        if (strlen(arg))
        {
            ColorChat(id, msgcolor_sys, "[mdbBans] You have no access to use that command!")
        }
        return 1
    }
    // fill(reason, 0, 256)
    read_argv(2, reason, g_var_3F)
    if (!(get_pcvar_num(cvarovi[11])) && (get_user_flags(id, "%L") & IN_ATTACK2))
    {
        player = cmd_target(id, arg, 10)
    }
    else
    {
        player = cmd_target(id, arg, 11)
    }
    if (!(is_user_connected(player)))
    {
        return 1
    }
    // fill(logtext, 0, 512)
    // fill(name, 0, 128)
    // fill(madmin, 0, 128)
    // fill(times, 0, 80)
    get_time("[%d.%m - %H:%M]", times, 19)
    get_user_name(id, madmin, g_var_1F)
    get_user_name(player, name, g_var_1F)
    formatex(logtext, g_var_7F, "%s Admin %s kicked %s. Reason: %s.", times, madmin, name, reason)
    write_file(logfile, logtext, -1)
    switch (get_pcvar_num(cvarovi[0]))
    {
        case 0:
            server_cmd("wait; wait; kick #%d  \"You got kicked. Reason: %s.\"", get_user_userid(player), reason)
            break
        case 2:
            server_cmd("wait; wait; kick #%d  \"Admin %s kicked you. Reason: %s.\"", get_user_userid(player), madmin, reason)
            ColorChat("%L", msgcolor_bans, "^x01 Admin^x03 %s:^x01 kicked^x03 %s^x01 , reason:^x04 %s.", madmin, name, reason)
            break
        default:
    }
    server_cmd("wait; wait; kick #%d  \"You got kicked. Reason: %s.\"", get_user_userid(player), reason)
    ColorChat("%L", msgcolor_bans, "^x01 Admin: kick^x03 %s^x01 , reaosn:^x04 %s.", name, reason)
    // goto 0x53A0
    return 1
}

public cmd_writeban(id, level, cid)
{
    new banduritation
    new time[32]
    new minutesi
    new bantext[96]
    new madmin[32]
    new logtext[128]
    new minutes[8]
    new authid[32]

    if (!(cmd_access(id, level, cid, 2, "%L")))
    {
        return 1
    }
    // fill(authid, 0, 128)
    // fill(minutes, 0, 32)
    read_argv(1, authid, g_var_1F)
    read_argv(2, minutes, "")
    if (!(is_str_num(minutes)))
    {
        client_print(id, print_console, "[mdbBans] Command argument missmatch... Correct usage: \"<SteamID/mID/IP>\" <time>")
        return 1
    }
    // fill(logtext, 0, 512)
    // fill(madmin, 0, 128)
    // fill(bantext, 0, 384)
    minutesi = str_to_num(minutes)
    // fill(time, 0, 128)
    get_time("[%d.%m - %H:%M]", time, g_var_1F)
    banduritation = get_pcvar_num(cvarovi[14])
    if (!(minutesi))
    {
        banduritation = (banduritation + 44000)
    }
    else
    {
        if ((" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -" < minutesi))
        {
            banduritation = (banduritation + 44000)
        }
        else
        {
            banduritation = (minutesi + banduritation)
        }
    }
    get_user_name(id, madmin, g_var_1F)
    formatex(logtext, g_var_7F, "%s Admin %s banned %s for %s minutes. (writeban)", time, madmin, authid, minutes)
    write_file(logfile, logtext, -1)
    formatex(bantext, g_var_5F, "%s -- +%d (custom)", authid, banduritation)
    write_file(banfile, bantext, -1)
    ArrayPushString(banlist, bantext)
    ColorChat(id, msgcolor_sys, "[mdbBans] Write to ban list was successful (%s for %s minutes).", authid, minutes)
    return 1
}

public bantask(id)
{
    new kicktext[96]
    new shouldi

    shouldi = get_pcvar_num(cvarovi[0])
    // fill(kicktext, 0, 384)
    get_pcvar_string(cvarovi[2], kicktext, g_var_5F)
    switch (shouldi)
    {
        case 2:
            if (!(vreme))
            {
                server_cmd("wait; wait; kick #%d  \"Admin %s banned you permanently. Reason: %s. See console for details. %s.\"", get_user_userid(id), admin, razlog, kicktext)
            }
            else
            {
                server_cmd("wait; wait; kick #%d  \"Admin %s banned you for %d minutes. Reason: %s. See console ofr details. %s.\"", get_user_userid(id), admin, vreme, razlog, kicktext)
            }
            break
        default:
    }
    if (!(vreme))
    {
        server_cmd("wait; wait; kick #%d  \"Admin banned you permanently. Reason: %s. See console ofr details. %s.\"", get_user_userid(id), razlog, kicktext)
    }
    else
    {
        server_cmd("wait; wait; kick #%d  \"Admin banned you for %d minutes. Reason: %s.  See console ofr details. %s.\"", get_user_userid(id), vreme, razlog, kicktext)
    }
    // goto 0x5B9C
}

public takess(id)
{
    if (is_user_connected(id))
    {
        client_cmd(id, "snapshot")
    }
}

public mbankick()
{
    server_cmd("addip 5.0 %s", ip)
}

public tempkick()
{
    server_cmd("addip 5.0 %s", tempbanip)
}

public ovnovanje(id)
{
    if (!(is_user_connected(id)))
    {
        return 1
    }
    client_cmd(id, "snapshot;wait;snapshot;wait")
    set_task(0.3, "ovnovanje", id, g_var_6ED0, "%L", g_var_6ED4, "%L")
    return 1
}

public remove_delay()
{
    delay = 0
}

public cheat(id)
{
    client_cmd(id, "amx_chat [mdbBans] Player pressed a cheat button.")
}

public censurecheck(id)
{
    new demotext[96]
    new demoname[16]

    if (!(is_user_connected(id)))
    {
        return 1
    }
    if (get_pcvar_num(cvarovi[5]))
    {
        // fill(demoname, 0, 64)
        get_pcvar_string(cvarovi[4], demoname, 15)
        // fill(demotext, 0, 384)
        client_cmd(id, "stop")
        client_cmd(id, "record %s", demoname)
        if (get_pcvar_num(cvarovi[6]))
        {
            get_pcvar_string(cvarovi[3], demotext, g_var_5F)
            client_print(id, print_chat, "A demo is automatically being recorded: %s.dem", demoname)
            client_print(id, print_chat, "%s", demotext)
        }
    }
    if (get_pcvar_num(cvarovi[6]))
    {
        if (banmode)
        {
            client_print(id, print_console, "Your mID is: \"%s\"", playermID[id] * 2)
        }
        client_print(id, print_console, "mdbBans plugin version: v4.8 english")
        client_print(id, print_console, "mID prefix of this server: %d", get_pcvar_num(cvarovi[15]))
    }
    return 1
}

public showmID(id)
{
    if (!(banmode))
    {
        client_print(id, print_chat, "*That option is disabled on this server.*")
        return 1
    }
    client_print(id, print_chat, "Your mID is: %s", playermID[id] * 2)
}

public cmdExec(id, level, cid)
{
    new shouldi
    new authid[24]
    new name[32]
    new times[32]
    new madmin[32]
    new logtext[128]
    new player
    new arg[32]
    new ss
    new cmd[32]
    new command[64]

    // fill(command, 0, 256)
    // fill(cmd, 0, 128)
    read_argv("%L", cmd, g_var_1F)
    read_argv(2, command, g_var_3F)
    if ((equal(command, "ss", "%L") || equal(command, "snapshot", "%L") || equal(cmd, "amx_ss", "%L")))
    {
        ss = 1
        if (!((get_user_flags(id, "%L") & IN_FORWARD)))
        {
            client_print(id, print_console, "You have no access to use that command.")
            if (strlen(command))
            {
                ColorChat(id, msgcolor_sys, "[mdbBans] You have no access to use that command!")
            }
            return 1
        }
    }
    else
    {
        if (!(cmd_access(id, level, cid, 2, "%L")))
        {
            return 1
        }
    }
    // fill(arg, 0, 128)
    read_argv(1, arg, g_var_1F)
    if (!(get_pcvar_num(cvarovi[11])) && (get_user_flags(id, "%L") & IN_ATTACK2))
    {
        player = cmd_target(id, arg, 10)
    }
    else
    {
        player = cmd_target(id, arg, 11)
    }
    if (!(is_user_connected(player)))
    {
        return 1
    }
    // fill(logtext, 0, 512)
    // fill(madmin, 0, 128)
    // fill(times, 0, 128)
    // fill(name, 0, 128)
    // fill(authid, 0, 96)
    shouldi = get_pcvar_num(cvarovi[0])
    get_time("[%d.%m - %H:%M]", times, g_var_1F)
    get_user_name(id, madmin, g_var_1F)
    get_user_name(player, name, g_var_1F)
    get_user_authid(player, authid, g_var_17)
    formatex(logtext, g_var_7F, "%s Admin %s executed command %s on player %s (%s).", times, madmin, command, name, authid)
    write_file(logfile, logtext, -1)
    if (ss)
    {
        client_cmd(player, "stop")
        switch (shouldi)
        {
            case 0:
                break
            case 2:
                ColorChat("%L", msgcolor_bans, "^x01 Admin^x03 %s^x01 took a screenshot of player^x03 %s.", madmin, name)
                break
            default:
        }
        ColorChat("%L", msgcolor_bans, "^x01 Admin took a screenshot of player^x03 %s.", name)
        // goto 0x6A28
        set_task(0.4, "ispisi", player, g_var_6ED0, "%L", g_var_6ED4, "%L")
        set_task(0.5, "onlyss", player, g_var_6ED0, "%L", g_var_6ED4, "%L")
        return 1
    }
    switch (shouldi)
    {
        case 0:
            break
        case 2:
            ColorChat("%L", msgcolor_bans, "^x01 Admin^x03 %s^x01 executed command^x04 %s^x01 on player^x03 %s.", madmin, command, name)
            break
        default:
    }
    ColorChat("%L", msgcolor_bans, "^x01 Admin executed command^x04 %s^x01 on player^x03 %s.", command, name)
    // goto 0x6BB0
    client_cmd(player, "%s", command)
    return 1
}

public onlyss(id)
{
    new demoname[32]

    if (is_user_connected(id))
    {
        // fill(demoname, 0, 128)
        get_pcvar_string(cvarovi[4], demoname, g_var_1F)
        client_cmd(id, "snapshot;record %s2", demoname)
    }
}

public ispisi(id)
{
    new times[31]

    // fill(times, 0, 124)
    if (is_user_connected(id))
    {
        get_time("[%d.%m - %H:%M]", times, g_var_1F)
        client_print(id, print_chat, "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -")
        client_print(id, print_chat, "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -")
        ColorChat(id, msgcolor_bans, "Admin took a screenshot of you. Time:^x04 %s", times)
        client_print(id, print_chat, "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -")
        client_print(id, print_chat, "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -")
    }
}

public logsay(id)
{
    new said[128]

    // fill(said, 0, 512)
    read_args(said, g_var_7F)
    remove_quotes(said)
    format(said, g_var_7F, "(all): %s", said)
    chatlog(id, said)
}

public logteamsay(id)
{
    new said[128]

    // fill(said, 0, 512)
    read_args(said, g_var_7F)
    remove_quotes(said)
    format(said, g_var_7F, "(team): %s", said)
    chatlog(id, said)
}

public logadmin(id)
{
    new said[128]

    // fill(said, 0, 512)
    read_args(said, g_var_7F)
    remove_quotes(said)
    chatlog(id, said)
    return 1
}

chatlog(id, said[])
{
    new times[32]
    new name[30]
    new chattext[135]

    if (get_pcvar_num(cvarovi[9]) && chatactive)
    {
        // fill(chattext, 0, 540)
        // fill(name, 0, 120)
        get_user_name(id, name, g_var_1D)
        // fill(times, 0, 128)
        get_time("[%d.%m - %H:%M]", times, g_var_1F)
        formatex(chattext, g_var_86, "%s %s%s", times, name, said)
        write_file(chatfile, chattext, -1)
    }
}

public loadbans()
{
    new f
    new sadrzaj[100]

    if (!(file_exists(banfile)))
    {
        return 0
    }
    ArrayClear(banlist)
    // fill(sadrzaj, 0, 400)
    f = fopen(banfile, "rt")
    while (!(feof(f)))
    {
        fgets(f, sadrzaj, g_var_63)
        trim(sadrzaj)
        if (!(sadrzaj[0]))
        {
            continue
        }
        ArrayPushString(banlist, sadrzaj)
    }
    fclose(f)
}

public tempbancheck(unbantext[], bool:delete)
{
    new j
    new size
    new timesfound
    new pos[22]
    new key[85]

    // fill(key, 0, 340)
    // fill(pos, 0, 88)
    for (size = ArraySize(banlist); (size > j); j++)
    {
        ArrayGetString(banlist, j, key, g_var_54)
        if ((-1 != containi(key, unbantext)))
        {
            timesfound++
            pos[timesfound] = j
        }
    }
    if (delete)
    {
        for (; (timesfound >= j); j++)
        {
            ArrayDeleteItem(banlist, (pos[j] - j))
        }
    }
    return (timesfound + 1)
}

public bancheck(unbantext[], path)
{
    new sadrzaj[96]
    new fajl
    new announce
    new returnage
    new filepath[64]
    new linija

    // fill(filepath, 0, 256)
    announce = get_pcvar_num(cvarovi[6])
    switch (path)
    {
        case 1:
            break
        case 2:
            break
        default:
    }
    fajl = fopen(filepath, "r+t")
    linija = 0
    // fill(sadrzaj, 0, 384)
    while (!(feof(fajl)))
    {
        fgets(fajl, sadrzaj, g_var_5F)
        linija++
        if ((-1 != containi(sadrzaj, unbantext)))
        {
            write_file(filepath, g_var_AEDC, (linija - 1))
            if ((1 < announce) && (path == 1))
            {
                trim(sadrzaj)
                client_print("%L", print_console, "Removed ban: %s", sadrzaj)
            }
            returnage++
        }
    }
    fclose(fajl)
    return returnage
}

public RemoveBan(id, level, cid)
{
    new putova
    new times[32]
    new madmin[32]
    new logtext[194]
    new arg[35]

    if (!(cmd_access(id, level, cid, 1, "%L")))
    {
        return 1
    }
    // fill(arg, 0, 140)
    // fill(logtext, 0, 776)
    // fill(madmin, 0, 128)
    // fill(times, 0, 128)
    get_user_name(id, madmin, g_var_1F)
    get_time("[%d.%m - %H:%M]", times, g_var_1F)
    read_argv(1, arg, g_var_22)
    if (!(arg[0]))
    {
        client_print(id, print_console, "[mdbBans] Usage: amx_unban <nick/IP/steamID> - Removes an entry from the ban list.")
        return 1
    }
    if (equal(arg, "STEAM_0", "%L"))
    {
        client_print(id, print_console, "[mdbBans] Use quotes when unbanning a SteamID.")
        return 1
    }
    if ((!(arg[0]) || !(arg[3])))
    {
        client_print(id, print_console, "[mdbBans] Argument is too short. Minimum 4 characters.")
        return 1
    }
    if (tempbancheck(arg, 1))
    {
        putova = bancheck(arg, 1)
        if (get_pcvar_num(cvarovi[12]))
        {
            bancheck(arg, 2)
        }
        formatex(logtext, g_var_C1, "%s Admin %s unbanned %s.", times, madmin, arg)
        write_file(logfile, logtext, -1)
        switch (putova)
        {
            case 0:
                console_print(id, "%s *found in the temporary ban list but not in the main ban list.", arg)
                break
            case 1:
                console_print(id, "%s *successfully removed from the ban list.", arg)
                break
            default:
        }
        console_print(id, "%s *successfully removed from the ban list. Found %d entries.", arg, putova)
        // goto 0x7F78
        switch (get_cvar_num("amx_show_activity"))
        {
            case 1:
                ColorChat("%L", msgcolor_bans, "^x01 Admin unbanned^x03 %s", arg)
                break
            case 2:
                ColorChat("%L", msgcolor_bans, "^x01 Admin^x03 %s^x01 unbanned^x03 %s", madmin, arg)
                break
            default:
        }
    }
    else
    {
        console_print(id, "%s *not found in the ban list.", arg)
    }
    return 1
}

public ifbanned()
{
    new timesfound
    new announce
    new unbantext[10]
    new configtext[32]
    new mTime

    mTime = get_pcvar_num(cvarovi[14])
    // fill(configtext, 0, 128)
    // fill(unbantext, 0, 40)
    announce = get_pcvar_num(cvarovi[6])
    formatex(unbantext, 9, "+%d", mTime)
    set_pcvar_num(cvarovi[14], (mTime + 1))
    formatex(configtext, g_var_1F, "mdb_banduritation %d", (mTime + 1))
    write_file(configfile, configtext, "%L")
    if (!((mTime % 1440)))
    {
        set_task(15.0, "ocisti", "%L", g_var_6ED0, "%L", g_var_6ED4, "%L")
        admin_msg("[mdbBans] Ban list cleaning will start soon. Don't change the map in the next 20 seconds!")
    }
    if (!((mTime % 5)))
    {
        loadbans()
    }
    if ((1 < announce))
    {
        client_print("%L", print_console, "[mdbBans] Checking if there are expired bnas...")
    }
    timesfound = tempbancheck(unbantext, 1)
    if ((timesfound > 0))
    {
        bancheck(unbantext, 1)
        if (cvarovi[12])
        {
            bancheck(unbantext, 2)
        }
        if ((1 < announce))
        {
            client_print("%L", print_chat, "-----------------^n[mdbBans] %d ban(s) have just expired.", timesfound)
        }
    }
    set_task(60.0, "ifbanned", 4322633, g_var_6ED0, "%L", g_var_6ED4, "%L")
}

public checkban(id, bool:nomid)
{
    new kicktext[256]
    new i
    new size
    new key[85]
    new times[32]
    new debugtext[257]
    new found
    new authid[25]
    new mip[16]

    if (!(is_user_connected(id)))
    {
        return 0
    }
    // fill(mip, 0, 64)
    // fill(authid, 0, 100)
    get_fixed_ip(id)
    get_user_authid(id, authid, g_var_18)
    // fill(debugtext, 0, 1028)
    // fill(times, 0, 128)
    // fill(key, 0, 340)
    for (size = ArraySize(banlist); (size > i); i++)
    {
        ArrayGetString(banlist, i, key, g_var_54)
        contain(key, authid)
        if (((-1 != contain(key, authid)) || (-1 != contain(key, mip)) || !(nomid) && (-1 != contain(key, playermID[id] * 2))))
        {
            found = 1
            if (debug_enable)
            {
                get_time("[%d.%m - %H:%M]", times, g_var_1F)
                formatex(debugtext, g_var_100, "%s BANNED: %s , %s , %s,^n match on line: %i // contents: %s^n", times, mip, authid, playermID[id] * 2, i, key)
                write_file(debugfile, debugtext, -1)
            }
        }
        else
        {
            continue
        }
    }
    if (found)
    {
        // fill(kicktext, 0, 1024)
        get_pcvar_string(cvarovi[2], kicktext, g_var_FF)
        formatex(tempbanip, 16, "%s", mip)
        set_task(0.5, "tempkick", "%L", g_var_6ED0, "%L", g_var_6ED4, "%L")
        server_cmd("wait; wait; kick #%d  \"You are banned from this server... %s\"", get_user_userid(id), kicktext)
        if ((get_pcvar_num(cvarovi[6]) == 3))
        {
            get_user_name(id, times, g_var_1F)
            formatex(debugtext, g_var_96, "[mdbBans] Banned player %s connected. They have been kicked.", times)
            admin_msg(debugtext)
            client_print("%L", print_console, debugtext)
        }
    }
}

public actionBanMenu(id, key)
{
    new shouldi
    new name[32]
    new player

    switch (key)
    {
        case 7:
            g_menuOption[id]++
            g_menuOption[id] = (g_menuOption[id] % ArraySize(g_bantimes))
            g_menuSettings[id] = ArrayGetCell(g_bantimes, g_menuOption[id])
            displayBanMenu(id, g_menuPosition[id])
            break
        case 8:
            g_menuPosition[id]++
            displayBanMenu(id, g_menuPosition[id])
            break
        case 9:
            g_menuPosition[id]--
            displayBanMenu(id, g_menuPosition[id])
            break
        default:
    }
    player = g_menuPlayers[id][(key + (g_menuPosition[id] * 7))]
    if (!(is_user_connected(player)))
    {
        ColorChat(id, msgcolor_sys, "[mdbBans] That player is no longer on the server.")
        return 1
    }
    // fill(name, 0, 128)
    get_user_name(player, name, g_var_1F)
    g_menuUserid[id] = get_user_userid(player)
    shouldi = get_pcvar_num(cvarovi[7])
    switch (shouldi)
    {
        case 0:
            client_cmd(id, "amx_mban #%d %d", g_menuUserid[id], g_menuSettings[id])
            break
        case 1:
            client_cmd(id, "messagemode \"amx_mban #%d %d\"", g_menuUserid[id], g_menuSettings[id])
            ColorChat(id, msgcolor_sys, "[mdbBans] Input reason without quotes and press ENTER.")
            break
        case 2:
            formatex(g_menuPlayerName[id] * 2, g_var_1F, "%s", name)
            banmenu_forward(id)
            break
        case 3:
            formatex(g_menuPlayerName[id] * 2, g_var_1F, "%s", name)
            banmenu_forward(id)
            break
        default:
    }
    // goto 0x91C8
    return 1
}

displayBanMenu(id, pos)
{
    new a
    new keys
    new end
    new len
    new start
    new name[32]
    new i
    new b
    new menuBody[512]

    if ((pos < 0))
    {
        return 0
    }
    get_players(g_menuPlayers[id] * 2, g_menuPlayersNum[id], g_var_C060, g_var_C064)
    // fill(menuBody, 0, 2048)
    // fill(name, 0, 128)
    start = (pos * 7)
    if ((start >= g_menuPlayersNum[id]))
    {
        g_menuPosition[id] = 0
        pos = 0
        start = 0
    }
    __heap[1] = ((g_menuPlayersNum[id] % 7) + (g_menuPlayersNum[id] / 7))
    len = formatex(menuBody, g_var_1FF, "\\yBan menu\\R%d/%d^n\\w^n", (pos + 1), (pos + 1))
    end = (start + 7)
    if ((end > g_menuPlayersNum[id]))
    {
        end = g_menuPlayersNum[id]
    }
    for (a = start; (end > a); a++)
    {
        i = g_menuPlayers[id][a]
        get_user_name(i, name, g_var_1F)
        keys = ((b << 1) | keys)
        if ((get_user_flags(i, "%L") & IN_ATTACK))
        {
            b++
            len = (formatex(menuBody[len], (g_var_1FF - len), "%d. %s \\r[*]^n\\w", b, name) + len)
        }
        else
        {
            b++
            len = (formatex(menuBody[len], (g_var_1FF - len), "%d. %s^n", b, name) + len)
        }
    }
    if (g_menuSettings[id])
    {
        len = (formatex(menuBody[len], (g_var_1FF - len), "^n8. Ban for %d minutes^n", g_menuSettings[id]) + len)
    }
    else
    {
        len = (formatex(menuBody[len], (g_var_1FF - len), "^n8. Permanent ban^n") + len)
    }
    if ((end != g_menuPlayersNum[id]))
    {
        formatex(menuBody[len], (g_var_1FF - len), "^n9. More...^n0. Back")
        keys = (keys | g_var_100)
    }
    else
    {
        formatex(menuBody[len], (g_var_1FF - len), "^n0. Back")
    }
    show_menu(id, keys, menuBody, -1, "Ban Menu")
}

public banmenu_forward(id)
{
    static MenuBody[512]

    new keys

    MenuBody[0] = 0
    if (!(MenuBody[0]))
    {
        if (g_menuSettings[id])
        {
            keys = formatex(MenuBody, g_var_1FF, "Select ban type:^nSelected player: \\r%s ^n\\wSelected time: \\r%d^n", g_menuPlayerName[id] * 2, g_menuSettings[id])
        }
        else
        {
            keys = formatex(MenuBody, g_var_1FF, "Select ban type:^nSelected player: \\r%s ^n\\wSelected time: \\rPermanent ban^n", g_menuPlayerName[id] * 2)
        }
        if (!(banmode))
        {
            keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\y1. Ban") + keys)
        }
        else
        {
            keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\y1. Dynamic ban") + keys)
        }
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\d2. Censure") + keys)
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\%s3. Pwn", pri) + pop())
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\y4. Kick") + keys)
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\y5. Take screenshot without banning") + keys)
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n^n\\y8. SteamID ban") + keys)
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\y9. IP ban") + keys)
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n^n\\w0. Back") + keys)
    }
    show_menu(id, keys, MenuBody, -1, "banmenu_forward")
}

public BanMenuForward(id, key)
{
    new shouldi

    shouldi = get_pcvar_num(cvarovi[7])
    switch (key)
    {
        case 0:
            switch (shouldi)
            {
                case 2:
                    client_cmd(id, "amx_mban #%d %d", g_menuUserid[id], g_menuSettings[id])
                    break
                case 3:
                    client_cmd(id, "messagemode \"amx_mban #%d %d\"", g_menuUserid[id], g_menuSettings[id])
                    break
                default:
            }
            break
        case 1:
            banmenu_forward(id)
            ColorChat(id, msgcolor_sys, "[mdbBans] Censure is no longer available due to slowhacking protection. :(")
            return 1
            break
        case 2:
            if (!(get_pcvar_num(cvarovi[13])))
            {
                ColorChat(id, msgcolor_sys, "[mdbBans] Error: Pwn is disabled on this server.")
                banmenu_forward(id)
                return 1
            }
            switch (shouldi)
            {
                case 2:
                    client_cmd(id, "amx_pwn #%d %d", g_menuUserid[id], g_menuSettings[id])
                    break
                case 3:
                    client_cmd(id, "messagemode \"amx_pwn #%d %d\"", g_menuUserid[id], g_menuSettings[id])
                    break
                default:
            }
            break
        case 3:
            switch (shouldi)
            {
                case 2:
                    client_cmd(id, "amx_kick #%d", g_menuUserid[id])
                    break
                case 3:
                    client_cmd(id, "messagemode \"amx_kick #%d\"", g_menuUserid[id])
                    break
                default:
            }
            break
        case 4:
            client_cmd(id, "amx_ss #%d", g_menuUserid[id])
            displayBanMenu(id, g_menuPosition[id])
            return 1
            break
        case 7:
            switch (shouldi)
            {
                case 2:
                    client_cmd(id, "amx_mbanid #%d %d", g_menuUserid[id], g_menuSettings[id])
                    break
                case 3:
                    client_cmd(id, "messagemode \"amx_mbanid #%d %d\"", g_menuUserid[id], g_menuSettings[id])
                    break
                default:
            }
            break
        case 8:
            switch (shouldi)
            {
                case 2:
                    client_cmd(id, "amx_mbanip #%d %d", g_menuUserid[id], g_menuSettings[id])
                    break
                case 3:
                    client_cmd(id, "messagemode \"amx_mbanip #%d %d\"", g_menuUserid[id], g_menuSettings[id])
                    break
                default:
            }
            break
        case 9:
            break
        default:
    }
    if ((shouldi == 3))
    {
        ColorChat(id, msgcolor_sys, "[mdbBans] Inupt reason without quotes and press ENTER.")
        if (g_menuSettings[id])
        {
            ColorChat(id, msgcolor_sys, "[mdbBans] Selected player: %s , duration: %d minuta", g_menuPlayerName[id] * 2, g_menuSettings[id])
        }
        else
        {
            ColorChat(id, msgcolor_sys, "[mdbBans] Selected player: %s , duration: permanent", g_menuPlayerName[id] * 2)
        }
    }
    displayBanMenu(id, g_menuPosition[id])
    return 1
}

public mdb_menu(id)
{
    static MenuBody[512]

    new keys
    new acs

    if (!((get_user_flags(id, "%L") & IN_FORWARD)))
    {
        return 1
    }
    MenuBody[0] = 0
    if ((get_user_flags(id, "%L") & IN_ATTACK2))
    {
        acs = 1
    }
    if (!(MenuBody[0]))
    {
        keys = formatex(MenuBody, g_var_1FF, "mdbBans 4.8^n")
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\y1. Ban menu") + keys)
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\d2. Komande plugina (detalji)") + keys)
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\d3. Vesti o pluginu") + keys)
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\%s4. New version search", pri) + pop())
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\d5. Globalna banlista") + keys)
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\d6. Pomoc") + keys)
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\d7. Rezim rada...") + keys)
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\d8. Resetovanje plugina...") + keys)
        keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n^n^n\\w0. Zatvori") + keys)
    }
    if (acs)
    {
        keys = 767
    }
    else
    {
        keys = g_var_207
    }
    show_menu(id, keys, MenuBody, -1, "mdb Menu")
    client_print(id, print_console, "[mdbBans] The text displayed here is from an external source and cannot be currently translated.")
    return 1
}

public actionmdbMenu(id, key)
{
    static MenuBody[512]

    new vesti[256]
    new keys
    new vesti[256]

    // fill(vesti, 0, 1024)
    switch (key)
    {
        case 0:
            client_cmd(id, "amx_mbanmenu")
            break
        case 1:
            formatex(vesti, g_var_FF, "<html><body bgcolor=\"Black\" ><img class=\"floatcenter\" src=\"http://ehrs.info/mdbbans/dtljops.PNG\" height=\"100%%\" width=\"100%%\"></body></html>")
            show_motd(id, vesti, "mdbBans - Komande i cvarovi")
            break
        case 2:
            // fill(vesti, 0, 1024)
            formatex(vesti, g_var_FF, "<html><body bgcolor=\"Black\" ><img class=\"floatcenter\" src=\"http://ehrs.info/mdbbans/vesti.PNG\" height=\"100%%\" width=\"100%%\"></body></html>")
            show_motd(id, vesti, "mdbBans v4.8 - Vesti")
            break
        case 3:
            // fill(vesti, 0, 1024)
            formatex(vesti, g_var_FF, "<html><body bgcolor=\"Black\" ><img class=\"floatcenter\" src=\"http://ehrs.info/mdbbans/v48beta.PNG\" height=\"100%%\" width=\"100%%\"></body></html>")
            show_motd(id, vesti, "mdbBans v4.8 - Update")
            break
        case 4:
            ColorChat(id, msgcolor_sys, "[mdbBans] Ova opcija je izbacena jer je bagovala.")
            ColorChat(id, msgcolor_sys, "[mdbBans] Bice vracena u nekoj od sledecih verzija. :)")
            mdb_menu(id)
            break
        case 5:
            // fill(vesti, 0, 1024)
            formatex(vesti, g_var_FF, "<html><body bgcolor=\"Black\" ><img class=\"floatcenter\" src=\"http://ehrs.info/mdbbans/pomoc.PNG\" height=\"100%%\" width=\"100%%\"></body></html>")
            show_motd(id, vesti, "mdbBans v4.8 - Pomoc")
            break
        case 6:
            MenuBody[0] = 0
            if (!(MenuBody[0]))
            {
                keys = formatex(MenuBody, g_var_1FF, "\\yIzaberi profil:^n")
                keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\w1. Default^n\\ySve opcije plugina su aktivne.") + keys)
                keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\w2. Lite Mod^n\\ySve dodatne opcije plugina ce biti onemogucene.") + keys)
                keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\w3. Safe Mod^n\\ySve dodatne i neke osnovne opcije ce biti onemogucene.^nNamenjeno ukoliko imate ozbiljnih problema sa serverom/pluginom.") + keys)
                keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\w4. Debug^n\\yPravi fajl mdb_debug.txt u mdbBans folderu sa informacijama o banovanim igracima.") + keys)
                keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n^n\\wTrenutni profil: \\r%d", (get_cvar_num("mdb_profile") + 1)) + keys)
                keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\rNAPOMENA: Menjanje profila automatski restartuje server!") + keys)
                keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n^n\\w0. Nazad") + keys)
            }
            show_menu(id, keys, MenuBody, -1, "Profile Menu")
            break
        case 7:
            MenuBody[0] = 0
            if (!(MenuBody[0]))
            {
                keys = formatex(MenuBody, g_var_1FF, "\\yResetovanje plugina^n")
                keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\w1. Master reset^n\\yObrise SVE fajlove koje koristi plugin i ponovo ga instalira.") + keys)
                keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\w2. Reset podesavanja^n\\yVrati sva podesavanja na 'fabricko' stanje. Banovi i logovi ostaju.") + keys)
                keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n\\w3. Obrisi ban listu^n\\yObrise sve banove. Podesavanja i logovi ostaju.") + keys)
                keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n^n\\rNAPOMENA: Master reset zahteva restart servera!") + keys)
                keys = (formatex(MenuBody[keys], (g_var_1FF - keys), "^n^n\\w0. Nazad") + keys)
            }
            show_menu(id, keys, MenuBody, -1, "Reset Menu")
            break
        default:
    }
    return 1
}

public actionprofileMenu(id, key)
{
    if ((key == get_cvar_num("mdb_profile")))
    {
        ColorChat(id, msgcolor_sys, "[mdbBans] Ovaj profil je vec aktivan.")
        return 1
    }
    switch (key)
    {
        case 0:
            write_file(configfile, "mdb_profile 0", 3)
            break
        case 1:
            write_file(configfile, "mdb_profile 1", 3)
            break
        case 2:
            write_file(configfile, "mdb_profile 2", 3)
            break
        case 3:
            write_file(configfile, "mdb_profile 3", 3)
            break
        case 9:
            mdb_menu(id)
            break
        default:
    }
    if (("L" > key))
    {
        ColorChat(id, msgcolor_sys, "[mdbBans] Profil uspesno promenjen. Server ce se restartovati ...")
        set_task(5.0, "restartsrv", "%L", g_var_6ED0, "%L", g_var_6ED4, "%L")
    }
    return 1
}

public actionresetMenu(id, key)
{
    if ((2 > key))
    {
        server_cmd("amx_bantext \"\";amx_kicktext \"\";amx_demotext \"Dobrodosao na server! Automatski ti se snima demo.\";amx_demoname mdbBans;amx_autodemo 1;amx_announce 3")
        server_cmd("amx_banmenu_mode 3;amx_banmode 1;amx_logchat 1;amx_infologger 1;amx_immunity 0;amx_webban 0;amx_pwn_enable 1")
        server_exec()
    }
    switch (key)
    {
        case 0:
            server_cmd("mdb_banduritation 5;mIDprefix 0;mdbBans 2;mdb_profile 0")
            rmdir2("addons/amxmodx/configs/mdbBans")
            ColorChat(id, msgcolor_sys, "[mdbBans] Zapoceto resetovanje plugina. Server ce se restartovati!")
            ColorChat(id, msgcolor_sys, "[mdbBans] Plugin ce biti ponovo instaliran nakog restarta.")
            remove_task(4322633, "%L")
            set_task(6.0, "restartsrv", "%L", g_var_6ED0, "%L", g_var_6ED4, "%L")
            break
        case 1:
            podesavanja()
            ColorChat(id, msgcolor_sys, "[mdbBans] Podesavanja plugina su uspesno resetovana.")
            break
        case 2:
            if (file_exists(banfile))
            {
                delete_file(banfile)
                write_file(banfile, "mdbBans banlist:", -1)
            }
            ColorChat(id, msgcolor_sys, "[mdbBans] Uspesno obrisana ban lista. Sacekaj minut da se refreshuje ili promeni mapu.")
            break
        case 9:
            mdb_menu(id)
            break
        default:
    }
    return 1
}

public restartsrv()
{
    new map[32]

    // fill(map, 0, 128)
    get_mapname(map, g_var_1F)
    server_cmd("changelevel %s", map)
}

public cmdBanMenu(id, level, cid)
{
    if (!(cmd_access(id, level, cid, 1, "%L")))
    {
        return 1
    }
    g_menuOption[id] = 0
    if ((random_num(1, "") == 7))
    {
        ColorChat(id, msgcolor_sys, "[mdbBans] Za kontrolni meni plugina kucaj 'mdbbansmenu'")
    }
    if ((ArraySize(g_bantimes) > 0))
    {
        g_menuSettings[id] = ArrayGetCell(g_bantimes, g_menuOption[id])
    }
    else
    {
        g_menuSettings[id] = 0
    }
    g_menuPosition[id] = 0
    displayBanMenu(id, 0)
    return 1
}

public setbantimes()
{
    new i
    new args
    new buff[32]

    // fill(buff, 0, 128)
    args = read_argc()
    if ((1 >= args))
    {
        server_print("Usage: amx_mbantimes <duration1> [duration2] [duration3] ...")
        server_print("   use 0 for permanent ban.")
        return 0
    }
    ArrayClear(g_bantimes)
    for (; (args > i); i++)
    {
        read_argv(i, buff, g_var_1F)
        ArrayPushCell(g_bantimes, str_to_num(buff))
    }
}

public mstatus(id, level, cid)
{
    new a
    new authid[32]
    new name[32]
    new inum
    new players[32]

    if (!(cmd_access(id, level, cid, 1, "%L")))
    {
        return 1
    }
    if (!(banmode))
    {
        client_print(id, print_console, "[mdbBans] That option is unavailable because dynamic banning is disabled.")
        return 1
    }
    // fill(players, 0, 128)
    // fill(name, 0, 128)
    // fill(authid, 0, 128)
    get_players(players, inum, g_var_C060, g_var_C064)
    console_print(id, "List of players on the server and their IDs:")
    for (; (inum > a); a++)
    {
        get_user_authid(players[a], authid, g_var_1F)
        get_user_name(players[a], name, g_var_1F)
        console_print(id, "%2d. %s ---- %s ---- %s", players[a], name, authid, (playermID[players[a]] + playermID[players[a]]))
    }
    console_print(id, "Total online players: %d", inum)
    return 1
}

public precache()
{
    new pathlog[6]

    if (!(dir_exists("addons/amxmodx/configs/mdbBans")))
    {
        mkdir("addons/amxmodx/configs/mdbBans")
    }
    if (!(dir_exists("addons/amxmodx/configs/mdbBans/chatlogs")))
    {
        mkdir("addons/amxmodx/configs/mdbBans/chatlogs")
    }
    if (!(dir_exists("addons/amxmodx/configs/mdbBans/infologs")))
    {
        mkdir("addons/amxmodx/configs/mdbBans/infologs")
    }
    if (!(dir_exists("addons/amxmodx/configs/mdbBans/logs")))
    {
        mkdir("addons/amxmodx/configs/mdbBans/logs")
    }
    if (!(file_exists(banfile)))
    {
        write_file(banfile, "mdbBans banlist:", -1)
    }
    // fill(pathlog, 0, 24)
    get_time("%y%m", pathlog, "")
    formatex(logfile, g_var_3F, "addons/amxmodx/configs/mdbBans/logs/%s.txt", pathlog)
    get_time("%y%m%d", logpath, g_var_1F)
    formatex(infofile, g_var_3F, "addons/amxmodx/configs/mdbBans/infologs/%s.txt", logpath)
    formatex(chatfile, g_var_3F, "addons/amxmodx/configs/mdbBans/chatlogs/%s.txt", logpath)
    chatactive = 1
    server_cmd("exec addons/amxmodx/configs/mdbBans/podesavanja.cfg")
    banmode = get_pcvar_num(cvarovi[8])
    set_task(300.0, "precache", "%L", g_var_6ED0, "%L", g_var_6ED4, "%L")
    loadbans()
}

public firstrun()
{
    new filetext2[17]
    new shouldi[5]
    new mIDprefix
    new logtext[96]
    new times[32]

    // fill(times, 0, 128)
    get_time("[%d.%m - %H:%M]", times, g_var_1F)
    // fill(logtext, 0, 384)
    if ((get_pcvar_num(cvarovi[14]) == 5))
    {
        set_pcvar_num(cvarovi[14], g_var_C350)
        set_cvar_string("mdbBans", "4.8")
        mIDprefix = random_num(1, g_var_3E7)
        // fill(filetext2, 0, 68)
        formatex(filetext2, 16, "mIDprefix %d", mIDprefix)
        set_pcvar_num(cvarovi[15], mIDprefix)
        write_file(configfile, "mdb_banduritation 50000", "%L")
        write_file(configfile, filetext2, 1)
        write_file(configfile, "mdbBans 4.8", 2)
        write_file(configfile, "mdb_profile 0", 3)
        formatex(logtext, g_var_60, "%s mdbBans v4.8 is successfully installed!", times)
        write_file(logfile, logtext, -1)
        format(logtext, g_var_60, "%s See file podesavanja.cfg for settings.", times)
        write_file(logfile, logtext, -1)
        set_task(1.0, "podesavanja", "%L", g_var_6ED0, "%L", g_var_6ED4, "%L")
    }
    else
    {
        // fill(shouldi, 0, 20)
        get_cvar_string("mdbBans", shouldi, 4)
        if ((equal(shouldi, "4.0", "%L") || equal(shouldi, "4.1", "%L") || equal(shouldi, "4.2", "%L") || equal(shouldi, "4.5", "%L") || equal(shouldi, "4.6", "%L") || equal(shouldi, "4.7", "%L")))
        {
            formatex(logtext, g_var_60, "%s Found version %s. Updating...", times, shouldi)
            write_file(logfile, logtext, -1)
            set_cvar_string("mdbBans", "4.8")
            write_file(configfile, "mdbBans 4.8", 2)
            write_file(configfile, "mdb_profile 0", 3)
            formatex(logtext, g_var_60, "%s mdbBans successfully updated to version 4.8!", times)
            write_file(logfile, logtext, -1)
            set_task(1.0, "podesavanja", "%L", g_var_6ED0, "%L", g_var_6ED4, "%L")
            set_task(0.1, "ocisti", "%L", g_var_6ED0, "%L", g_var_6ED4, "%L")
        }
    }
}

public podesavanja()
{
    new shouldi[64]
    new ptext[256]
    new fajl[64]

    // fill(fajl, 0, 256)
    formatex(fajl, g_var_3F, "addons/amxmodx/configs/mdbBans/podesavanja.cfg")
    // fill(ptext, 0, 1024)
    // fill(shouldi, 0, 256)
    formatex(ptext, g_var_80, "amx_banmode %d    //0 = simple banning (steamID + ip) , 1 = dynamic banning (steamID/IP + mID)", banmode)
    write_file(fajl, ptext, "%L")
    formatex(ptext, g_var_96, "mdb_show_activity %d    //should admin name be shown in ban msgs? / 2 - yes / 1 - no / 0 - don't display ban messages", get_pcvar_num(get_cvar_pointer("amx_show_activity")))
    write_file(fajl, ptext, 1)
    formatex(ptext, g_var_80, g_var_13170)
    write_file(fajl, ptext, 2)
    formatex(ptext, g_var_80, "amx_pwn_enable %d        //is pwn enabled? (amx_pwn)?", get_pcvar_num(cvarovi[13]))
    write_file(fajl, ptext, 3)
    get_pcvar_string(cvarovi[1], shouldi, g_var_3F)
    formatex(ptext, g_var_FF, "amx_bantext \"%s\"   //what text should be displayed on the banned player's screenshot?", shouldi)
    write_file(fajl, ptext, 4)
    get_pcvar_string(cvarovi[2], shouldi, g_var_3F)
    formatex(ptext, g_var_BF, "amx_kicktext \"%s\"   //what text should be displayed to the player after the ban? (The \"you have been banned ...\" message)", shouldi)
    write_file(fajl, ptext, "")
    formatex(ptext, g_var_96, "amx_announce %d  //what announcements should the plugin make in chat or console / 0 - none / 1 - only important / 2 - most / 3 - all", get_pcvar_num(cvarovi[6]))
    write_file(fajl, ptext, "")
    formatex(ptext, g_var_80, "amx_banmenu_mode %d  //0 - classic ban menu / 1 - classic + reason / 2 - advanced / 3 - advanced + reason", get_pcvar_num(cvarovi[7]))
    write_file(fajl, ptext, "")
    formatex(ptext, g_var_80, "amx_mbantimes 300 0 5 10 30 60 120  //ban menu durations. Use 0 for permanent.")
    write_file(fajl, ptext, "")
    formatex(ptext, g_var_96, "amx_immunity %d  // 0 - head admins (with L flag) can ban over immunity / 1 - immunity is obeyed", get_pcvar_num(cvarovi[11]))
    write_file(fajl, ptext, 9)
    formatex(ptext, g_var_80, "amx_webban %d  // Do you want to use the web ban list? 1 - yes, 0 - no", get_pcvar_num(cvarovi[12]))
    write_file(fajl, ptext, 10)
    formatex(ptext, g_var_96, "amx_msgcolor_bans 2 //color of ban announce messages. (e.g. Admin X banned X for X minutes)")
    write_file(fajl, ptext, 11)
    formatex(ptext, g_var_96, "amx_msgcolor_system 3 //color of system messages (errors and information, messages with the [mdbBans] tag)")
    write_file(fajl, ptext, "NO_ACC_COM")
    write_file(fajl, "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *", 14)
    write_file(fajl, "//  //  //       Additional options      //  //  //", 15)
    write_file(fajl, "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *", 16)
    formatex(ptext, g_var_80, "amx_autodemo %i   //force players to record a demo?", get_pcvar_num(cvarovi[5]))
    write_file(fajl, ptext, 17)
    get_pcvar_string(cvarovi[4], shouldi, g_var_1F)
    formatex(ptext, g_var_80, "amx_demoname %s   //name of the demo (don't put .dem at the end)?", shouldi)
    write_file(fajl, ptext, 18)
    get_pcvar_string(cvarovi[3], shouldi, g_var_3F)
    formatex(ptext, g_var_FF, "amx_demotext \"%s\"   //Welcome message if a demo is being recorded.", shouldi)
    write_file(fajl, ptext, 19)
    formatex(ptext, g_var_80, "amx_logchat %d   //log server chat in mdbBans/chatlogs folder?", get_pcvar_num(cvarovi[9]))
    write_file(fajl, ptext, g_var_14)
    formatex(ptext, g_var_80, "amx_infologger %d //log connections to the server in mdbBans/infologs folder?", get_pcvar_num(cvarovi[10]))
    write_file(fajl, ptext, g_var_15)
    write_file(fajl, ";COLOR CODES (for msgcolor_bans and msgcolor_sys):", g_var_17)
    write_file(fajl, ";0 - default color (yellow) / 1 - green / 2 - red / 3 - blue / 4 - team dependant (red/blue/white) / 5 - white", g_var_18)
    write_file(fajl, "^n;Thank you for using mdbBans. Check the KGB forum for new versions.", g_var_19)
}

public ocisti()
{
    new data[256]
    new stxtsize
    new line

    // fill(data, 0, 1024)
    line = read_file(banfile, line, data, g_var_FF, stxtsize)
    while (line)
    {
        if (stxtsize)
        {
            write_file("mdbBans_temp.cfg", data, -1)
        }
    }
    if (get_pcvar_num(cvarovi[12]) && file_exists(dbanfile))
    {
        line = read_file(dbanfile, line, data, g_var_FF, stxtsize)
        while (line)
        {
            if (stxtsize)
            {
                write_file("mdbBans_tempd.cfg", data, -1)
            }
        }
    }
    server_cmd("mp_chattime 100")
    admin_msg("[mdbBans] Ban list optimization started...")
    set_task(2.0, "continue_update", "%L", g_var_6ED0, "%L", g_var_6ED4, "%L")
}

public continue_update()
{
    delete_file(banfile)
    rename_file("mdbBans_temp.cfg", banfile, 1)
    if (get_pcvar_num(cvarovi[12]) && file_exists("mdbBans_tempd.cfg"))
    {
        delete_file(dbanfile)
        rename_file("mdbBans_tempd.cfg", dbanfile, 1)
    }
    server_cmd("mp_chattime 5")
    admin_msg("[mdbBans] Ban list successfully optimised.")
    return 1
}

public masstask()
{
    new shouldi

    shouldi = get_cvar_num("mdb_profile")
    if ((0 < shouldi) && (3 > shouldi))
    {
        server_cmd("amx_autodemo 0; amx_infologger 0; amx_logchat 0")
        if ((shouldi == 2))
        {
            server_cmd("amx_banmode 0")
        }
    }
    if ((shouldi == 3))
    {
        debug_enable = 1
    }
    switch (get_pcvar_num(cvarovi[16]))
    {
        case 0:
            msgcolor_bans = 1
            break
        case 1:
            msgcolor_bans = 2
            break
        case 2:
            msgcolor_bans = 5
            break
        case 3:
            msgcolor_bans = 6
            break
        case 4:
            msgcolor_bans = 3
            break
        case 5:
            msgcolor_bans = "L"
            break
        default:
    }
    switch (get_pcvar_num(cvarovi[17]))
    {
        case 0:
            msgcolor_sys = 1
            break
        case 1:
            msgcolor_sys = 2
            break
        case 2:
            msgcolor_sys = 5
            break
        case 3:
            msgcolor_sys = 6
            break
        case 4:
            msgcolor_sys = 3
            break
        case 5:
            msgcolor_sys = "L"
            break
        default:
    }
}

public client_putinserver(id)
{
    if (is_user_bot(id))
    {
        return 0
    }
    if (!(banmode))
    {
        formatex(playermID[id] * 2, 16, "[no mID]")
        checkban(id, 1)
    }
    else
    {
        set_task(4.5, "loadmID", id, g_var_6ED0, "%L", g_var_6ED4, "%L")
    }
    noviCS[id] = 1
    set_task(2.5, "infolog", id, g_var_6ED0, "%L", g_var_6ED4, "%L")
    set_task(10.0, "censurecheck", id, g_var_6ED0, "%L", g_var_6ED4, "%L")
}

public client_disconnect(id)
{
    playermID[id][0] = 0
    g_menuPlayers[id][0] = 0
    g_menuUserid[id] = 0
    g_menuPlayerName[id][0] = 0
}

public loadmID(id)
{
    new mID[32]
    new announce

    if (!(is_user_connected(id)))
    {
        return 1
    }
    announce = get_pcvar_num(cvarovi[6])
    if ((get_user_protocol(id) == 3))
    {
        if ((announce > 0))
        {
            client_print(id, print_chat, "You don't have a mID because your CS uses the newest protocol.")
        }
        formatex(playermID[id] * 2, g_var_1F, "[NewCS/Steam]")
        noviCS[id] = 2
        checkban(id, 1)
        return 1
    }
    // fill(mID, 0, 128)
    get_user_info(id, "mD", mID, g_var_1F)
    if ((-1 != containi(mID, "STEAM")))
    {
        server_cmd("kick #%d \"Zasto stavljas SteamID umesto mIDa? Jeli? Mater ti jebem u picku da ti jebam ja tebi malo, a?", get_user_userid(id))
        return 1
    }
    if ((strlen(mID) > 8))
    {
        if ((announce > 0))
        {
            client_print(id, print_chat, "Your mID's format is incorrect! It has been deleted.")
        }
    }
    if (!(mID[0]))
    {
        if ((announce > 0))
        {
            client_print(id, print_chat, "You don't have a mID. A new one has been generated.")
        }
        __heap[1] = random_num(g_var_3E8, g_var_270F)
        formatex(mID, g_var_1F, "%d%d", random_num(g_var_3E8, g_var_270F), random_num(g_var_3E8, g_var_270F))
        client_cmd(id, "setinfo _pw \"\"")
        client_cmd(id, "setinfo mD %s", mID)
    }
    else
    {
        if ((announce > 0))
        {
            client_print(id, print_chat, "Your mID is: \"%s\"", mID)
        }
    }
    formatex(playermID[id] * 2, g_var_1F, "%s", mID)
    checkban(id, "%L")
    return 1
}

public infolog(id)
{
    new mip[32]
    new authid[32]
    new joined[256]
    new time[32]
    new name[32]
    new authid[32]

    if (!(is_user_connected(id)))
    {
        return 1
    }
    // fill(authid, 0, 128)
    get_user_authid(id, authid, g_var_1F)
    client_cmd(id, "checkeXec")
    if (get_pcvar_num(cvarovi[10]))
    {
        // fill(name, 0, 128)
        // fill(time, 0, 128)
        // fill(joined, 0, 1024)
        // fill(authid, 0, 128)
        // fill(mip, 0, 128)
        get_user_authid(id, authid, g_var_1F)
        get_user_ip(id, mip, g_var_1F, 1)
        get_user_name(id, name, g_var_1D)
        get_time("[%d.%m - %H:%M]", time, g_var_1F)
        if ((get_user_flags(id, "%L") & IN_FORWARD))
        {
            formatex(joined, g_var_FF, "%s*** Admin %s (%s  ///  %s) connected. ***", time, name, authid, mip)
        }
        else
        {
            formatex(joined, g_var_FF, "%s Player %s (%s  ///  %s) conencted.", time, name, authid, mip)
        }
        write_file(infofile, joined, -1)
    }
    return 1
}

public cscheck(id)
{
    if ((noviCS[id] == 2))
    {
        client_print(id, print_console, "[mdbBans] E PA NEMA !!")
    }
    else
    {
        if (!(noviCS[id]))
        {
            client_print(id, print_console, "[mdbBans] Sta pokusavas?")
        }
        else
        {
            noviCS[id] = 0
        }
    }
    return 1
}

get_user_protocol(id)
{
    new authid[25]

    // fill(authid, 0, 100)
    get_user_authid(id, authid, g_var_18)
    if (((-1 != contain(authid, "L")) || (-1 != contain(authid, "P"))))
    {
        return 1
    }
    if (noviCS[id])
    {
        return 3
    }
    return 2
}

get_fixed_ip(id, param2)
{
    new i
    new fixed[16]
    new after
    new count
    new len
    new mip[16]

    // fill(mip, 0, 64)
    get_user_ip(id, mip, 15, 1)
    len = strlen(mip)
    // fill(fixed, 0, 64)
    for (; (len > i); i++)
    {
        if ((count == 3))
        {
            after++
        }
        if ((mip[i] == 46))
        {
            count++
        }
    }
    switch (after)
    {
        case 1:
            formatex(fixed, 19, "%sXX", mip)
            break
        case 2:
            formatex(fixed, 19, "%sX", mip)
            break
        default:
    }
    return fixed
}

admin_msg(msg[])
{
    new i
    new inum
    new players[32]

    // fill(players, 0, 128)
    get_players(players, inum, g_var_C060, g_var_C064)
    for (; (inum > i); i++)
    {
        if (access(players[i], g_var_100))
        {
            ColorChat(players[i], msgcolor_sys, msg)
        }
    }
}
