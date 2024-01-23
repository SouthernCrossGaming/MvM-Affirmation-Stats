#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define	STR_AUTO_CHAT	"\x01[\x07A6FF00SCG\x01]"

int stat_banner_deploy = 0; //How many times did our team use buff banners
int stat_bomb_reset = 0; //How many times have players reset the bomb
int stat_cash_scoutspy = 0; //Cash collected by the Scout or the Spy
int stat_cash_other = 0; //Cash collected by anyone else
int stat_deploy_reset = 0; //How many times the players stopped the bomb as it was getting deployed
int stat_revived_players = 0; //How many times were players brought back to life by the medic
int stat_sentry_buster_killed = 0; //How many sentry busters did the players kill before they had reached their target explosive point
int stat_player_teleported = 0; //How many times an Engineer's teleporter was used
int stat_uber_deployed = 0; //How many times our medics used an uber

int ind_stat_dmg_taken[MAXPLAYERS+1] = {};
//int ind_stat_times_revived[MAXPLAYERS+1] = {0};

/*
Note: For the sake of memory efficiency, we should limit the number of large stat tracks to be carried on a per wave basis and can display them at the end; 
Stat tracks like damage dealt should probably be cautioned aagainst because they would run up a really high tally?
*/

/**
 * TODO
 * 1. When do we want these to play, at the end of each wave or at the end of the game?
 * 
 * We can toy with the idea of displaying stats at the end of each wave, but it might be more effective if we displayed stats at the end of the game.
 * I want to believe that displaying stats at the end of a mission will motivate players to stick around through the tough bits, as opposed to giving up or leaving half-way through.
 * Perhaps we can have a !stats command which will display stats for the previous wave and then at the end of the wave notable values will be displayed automatically.
 * 
 * 2. Do we want these global, so all players can see, or for the individual affected?
 * 
 * Absolutely we should have individual stats, but for now we can focus just on global stats. Maybe later we can expand on some of these stats to track them individually.
 * 
 * 3. Is it best to go by general class stats rather than individual performance?
 * 
 * Why not both?
 * Ultimately I think it depends on the stat in question. Your suggestion below for canteen sharing works well globally, but I don't think there's much reason to track that stat
 * individually. Heck, it might even be harmful. Consider a situation in which two medics have decided that the "best medic" is the one that shares the most canteens. Then canteens
 * will be all that they're focused on and spending money on and that will dilute their effectiveness. It's an admittedly silly example but we want to make sure our stats are
 * promoting teamwork and not competition. Any individual stat that could give a player a sense of superiority might better serve as a global stat instead. Of course, I might just
 * be overthinking, but this is something we should keep in mind as we're working all of this out.
 * 
 * Some of these may be too messy to track, lots of data being stored
 * 
 * Note that we do not need to do all of the below, but they are the ideas that immediately popped into my head
 * Some of them might not even be possible :P
 * 
 * Ideas for individual stats (which can then be summed up to a global stat)
 * Damage taken - DONE
 * Times revived - Unable to do I think
 * 
 * 
 * Ideas for global stats (organized roughly according to class)
 * 
 * Cash collected by scout/spy - DONE - WORKING
 * Cash not collected by scout/spy (to encourage people to pick up money) - DONE - WORKING
 * Teammates milked
 * Opponents milked - Too much
 * 
 * Banners deployed by teammates - DONE
 * Banners deployed by opponents - MAYBE?
 * Projectiles fired by teammates - Too much data?
 * Projectiles fired by opponents - Too much data?
 * 
 * Airblasts - Too much data?
 * Opponents gassed - Too much data?
 * Bomb resets - DONE
 * Bomb deploy resets - DONE
 * 
 * Stickies placed - Too much data?
 * Stickies detonated - Too much data?
 * Teammate charges - Maybe?
 * Opponent charges - Too much data?
 * Heads taken by teammates
 * Heads taken by opponents - Too much data?
 * Sentry busters detonated (do we include busters that don't explode?) - DONE
 * Players killed by sentry busters (heehoo) - Mean!
 * 
 * Meals donated (As in, a heavy drops his food and another player picks it up)
 * Projectiles deflected - Too much
 * Penetration kills (technically applies to every penetrating weapon but heavy has the penetration upgrades) - Maybe
 * Penetration damage - Too much
 * Times raged - Maybe?
 * 
 * Buildings destroyed by teammates
 * Buildings destroyed by opponents
 * Teammates teleported - DONE
 * Opponents teleported - Too much
 * Health given by dispensers
 * Ammo given by dispensers * -- _ZN16CObjectDispenser12DispenseAmmoEP9CTFPlayer BAD IDEA
 * bool CObjectDispenser::DispenseAmmo( CTFPlayer *pPlayer ) ^
 * 
 * Shared canteens (mvm_medic_powerup_shared)
 * Shield deployments - Look for entity_medigun_shield, find owner
 * Teammates revived - DONE
 * Teammate deaths (only count these while a wave is active?) (Heehoo)
 * Opponent deaths - Tracked elsewhere
 * Ubercharges used 
 * 
 * Teammates jarated
 * Opponents jarated
 * Opponents killed by explosive headshot
 * Teammates sniped - Too many
 * Support snipers killed (Might not be possible if we can't figure out if a sniper is support) - Scary
 * 
 * Times disguised
 * Teammates backstabbed
 * Opponents sapped
 * Support spies killed (See above)
 * 
 * Wave attempts (if wave attempts == waves then the bomb never got deployed)
 * Most difficult wave
 * Longest wave in terms of bots (compare the number of bots killed on each wave)
 * Longest wave in terms of time
 */

public Plugin myinfo = 
{
    name = "[MVM] Unnamed Stat Project",
    author = "Rowedahelicon / Seabass",
    description = "Rewards players with good affirmations!",
    version = "0.0",
    url = "https://scg.wtf"
}

public void OnPluginStart()
{  
    //These do not need to be pre hooks
    HookEvent("deploy_buff_banner", Event_DeployBanner);
    HookEvent("mvm_begin_wave", Event_BeginWave);
    HookEvent("mvm_bomb_reset_by_player", Event_BombResetByPlayer);
    HookEvent("mvm_bomb_deploy_reset_by_player", Event_BombDeployResetByPlayer);
    HookEvent("mvm_pickup_currency", Event_PickupCurrency);
    HookEvent("mvm_reset_stats", Event_ResetStats);
    HookEvent("mvm_sentrybuster_killed", Event_SentryBusterKilled);
    HookEvent("mvm_wave_complete", Event_WaveComplete);
    HookEvent("player_chargedeployed", Event_ChargeDeployed);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("player_teleported", Event_PlayerTeleported);
    //HookEvent("mvm_mission_complete", Event_WaveComplete); //If we want this at the end instead?
    HookEvent("revive_player_complete", Event_RevivePlayer);

    RegConsoleCmd("mvmstats", commandStats);
}

/*ACTIONS*/
public Action commandStats(int client, int args)
{
    // char arg[128];
    // char full[256];

    // GetCmdArgString(full, sizeof(full));
    PrintToChatAll("Stats!");
    Menu menu = new Menu(StatHandler1);
    menu.SetTitle("Stats Menu");
    menu.AddItem("mission_stats", "Mission Stats");
    menu.AddItem("indiv_stats", "Your Stats");
    menu.Display(client, 20);
    //menu.SetTitle("Stats Menu");

    return Plugin_Handled;
}

public int StatHandler1(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        PrintToChatAll("%N asked for %d | %s", param1, param2, info);

        char strValue[48];

        Panel panel = new Panel();
        panel.SetTitle("Individual Stats");
        Format(strValue, sizeof(strValue), "Cash from Spies / Scouts: %i", stat_cash_scoutspy);
        panel.DrawItem(strValue);        
        Format(strValue, sizeof(strValue), "Cash from Everyone Else: %i", stat_cash_other);
        panel.DrawItem(strValue);
        panel.Send(param1, PanelHandle, 20);

        delete panel;

        PrintToChatAll("Stats!");
        PrintToChatAll("%N: %d", param1, ind_stat_dmg_taken[param1]);


        //Open Stat Menu
    }
    else if (action == MenuAction_Cancel)
    {

    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}

public int PanelHandle(Menu menu, MenuAction action, int param1, int param2)
{
    return 0;
}

/*EVENTS*/

public Action Event_DeployBanner(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("buff_owner"));

    if (!IsValidClient(client) || GetClientTeam(client) != 2)
    {
        return Plugin_Handled;
    }

    stat_banner_deploy ++;

    return Plugin_Continue;
}

public Action Event_BeginWave(Event event, const char[] name, bool dontBroadcast)
{
    resetAllStats(); //If we want to do this per wave, we do this here, otherwise get rid of this
    return Plugin_Continue;
}

public Action Event_BombResetByPlayer(Event event, const char[] name, bool dontBroadcast)
{
    stat_bomb_reset++;
    return Plugin_Continue;
}

public Action Event_BombDeployResetByPlayer(Event event, const char[] name, bool dontBroadcast)
{
    stat_deploy_reset++;
    return Plugin_Continue;
}

public Action Event_PickupCurrency(Event event, const char[] name, bool dontBroadcast)
{
    int client = event.GetInt("player");
    int cash = event.GetInt("currency");

    if (!IsValidClient(client) || GetClientTeam(client) != 2)
    {
        return Plugin_Handled;
    }

    TFClassType class = TF2_GetPlayerClass(client);

    if (class == TFClass_Scout || class == TFClass_Spy)
    {
        stat_cash_scoutspy += cash;
    }
    else
    {
        stat_cash_other += cash;
    }

    return Plugin_Continue;
}

public Action Event_ResetStats(Event event, const char[] name, bool dontBroadcast)
{
    /*
        If we do keep the begin wave, we can delete this one because it is just redundant. 
        This is when a new mission is loaded.
    */
    resetAllStats();
    return Plugin_Continue;
}

public Action Event_SentryBusterKilled(Event event, const char[] name, bool dontBroadcast)
{
    stat_sentry_buster_killed ++;
    return Plugin_Continue;
}

public Action Event_WaveComplete(Event event, const char[] name, bool dontBroadcast)
{

    // int iEnt = 0;
    // while ((iEnt = FindEntityByClassname(iEnt, "tf_mann_vs_machine_stats")) != -1)
    // {
    //     //Not sure what to do this this yet, but we can probably use it
    //     int dropped = GetEntProp(iEnt, Prop_Send, "m_previousWaveStats", 4, 0);
    //     int pickedup = GetEntProp(iEnt, Prop_Send, "m_previousWaveStats", 8, 0);
    //     int bonus = GetEntProp(iEnt, Prop_Send, "m_previousWaveStats", 12, 0);
    //     // int deaths = GetEntProp(iEnt, Prop_Send, "m_previousWaveStats", 16, 0); //Does not work at all
    //     int buybacks = GetEntProp(iEnt, Prop_Send, "m_previousWaveStats", 20, 0);

    //     int total_dropped = GetEntProp(iEnt, Prop_Send, "m_runningTotalWaveStats", 4, 0);
    //     int total_pickedup = GetEntProp(iEnt, Prop_Send, "m_runningTotalWaveStats", 8, 0);
    //     int total_bonus = GetEntProp(iEnt, Prop_Send, "m_runningTotalWaveStats", 12, 0);
    //     // int total_deaths = GetEntProp(iEnt, Prop_Send, "m_runningTotalWaveStats", 16, 0); //Does not work at all
    //     int total_buybacks = GetEntProp(iEnt, Prop_Send, "m_runningTotalWaveStats", 20, 0);

    //     //There is also m_currentWaveStats but this will be empty at the start of a new wave
    // }

    return Plugin_Continue;
}

public Action Event_ChargeDeployed(Event event, const char[] name, bool dontBroadcast)
{
    int player = GetClientOfUserId(event.GetInt("userid"));

    if (IsValidClient(player) && GetClientTeam(player) == 2)
    {
        stat_uber_deployed ++;
    }

    return Plugin_Continue;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int player = GetClientOfUserId(event.GetInt("userid"));

    if (IsValidClient(player) && GetClientTeam(player) == 2)
    {
        ind_stat_dmg_taken[player] += event.GetInt("damageamount");
    }

    return Plugin_Continue;
}

public Action Event_PlayerTeleported(Event event, const char[] name, bool dontBroadcast)
{
    int player = GetClientOfUserId(event.GetInt("builderid"));

    if (IsValidClient(player) && GetClientTeam(player) == 2)
    {
        stat_player_teleported++;
    }

    return Plugin_Continue;
}


public Action Event_RevivePlayer(Event event, const char[] name, bool dontBroadcast)
{
    stat_revived_players++;
    //ind_stat_times_revived[]
    return Plugin_Continue;
}

/* STOCKS */

stock void resetAllStats()
{
    stat_bomb_reset = 0;
    stat_deploy_reset = 0;
    stat_revived_players = 0;
}

stock void printOutStats()
{
    PrintToChatAll("%s This is just sample text!", STR_AUTO_CHAT);
}

stock bool IsValidClient(int client)
{
    if (!client || client > MaxClients || client < 1)
    {
        return false;
    }

    if (!IsClientInGame(client))
    {
        return false;
    }

    //We deliberately ignore checking for STV clients to not break rafmod
    if (IsFakeClient(client))
    {
        return false;
    }

    return true;
}