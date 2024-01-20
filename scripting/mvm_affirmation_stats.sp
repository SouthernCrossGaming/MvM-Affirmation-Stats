#pragma newdecls required
#include <sourcemod>

#define	STR_AUTO_CHAT	"\x01[\x07A6FF00SCG\x01]"

int stat_bomb_reset = 0; //How many times have players reset the bomb
int stat_deploy_reset = 0; //How many times the players stopped the bomb as it was getting deployed
int stat_revived_players = 0; //How many times were players brought back to life by the medic

/**
 * TODO
 * 1. When do we want these to play, at the end of each wave or at the end of the game?
 * 2. Do we want these global, so all players can see, or for the individual affected?
 * 3. Is it best to go by general class stats rather than individual performance?
 * 
 * Ideas for stats
 * mvm_medic_powerup_shared = How many times medics shared canteens
 * Total robots killed overall
 * Cash collected
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
    HookEvent("mvm_begin_wave", Event_BeginWave);
    HookEvent("mvm_bomb_reset_by_player", Event_BombResetByPlayer);
    HookEvent("mvm_bomb_deploy_reset_by_player", Event_BombDeployResetByPlayer);
    HookEvent("mvm_reset_stats", Event_ResetStats);
    HookEvent("mvm_wave_complete", Event_WaveComplete);
    //HookEvent("mvm_mission_complete", Event_WaveComplete); //If we want this at the end instead?
    HookEvent("revive_player_complete", Event_RevivePlayer);
}

/*EVENTS*/

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

public Action Event_ResetStats(Event event, const char[] name, bool dontBroadcast)
{
    /*
        If we do keep the begin wave, we can delete this one because it is just redundant. 
        This is when a new mission is loaded.
    */
    resetAllStats();
    return Plugin_Continue;
}

public Action Event_WaveComplete(Event event, const char[] name, bool dontBroadcast)
{

    //Not sure what to do this this yet, but we can probably use it
    int dropped = GetEntProp(iEnt, Prop_Send, "m_previousWaveStats", 4, 0);
    int pickedup = GetEntProp(iEnt, Prop_Send, "m_previousWaveStats", 8, 0);
    int bonus = GetEntProp(iEnt, Prop_Send, "m_previousWaveStats", 12, 0);
    // int deaths = GetEntProp(iEnt, Prop_Send, "m_previousWaveStats", 16, 0); //Does not work at all
    int buybacks = GetEntProp(iEnt, Prop_Send, "m_previousWaveStats", 20, 0);

    int total_dropped = GetEntProp(iEnt, Prop_Send, "m_runningTotalWaveStats", 4, 0);
    int total_pickedup = GetEntProp(iEnt, Prop_Send, "m_runningTotalWaveStats", 8, 0);
    int total_bonus = GetEntProp(iEnt, Prop_Send, "m_runningTotalWaveStats", 12, 0);
    // int total_deaths = GetEntProp(iEnt, Prop_Send, "m_runningTotalWaveStats", 16, 0); //Does not work at all
    int total_buybacks = GetEntProp(iEnt, Prop_Send, "m_runningTotalWaveStats", 20, 0);

    //There is also m_currentWaveStats but this will be empty at the start of a new wave
}

 public Action Event_RevivePlayer(Event event, const char[] name, bool dontBroadcast)
{
    stat_revived_players++;
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