#pragma newdecls required
#include <sourcemod>

#define	STR_AUTO_CHAT	"\x01[\x07A6FF00SCG\x01]"

int stat_bomb_reset = 0; //How many times have players reset the bomb
int stat_deploy_reset = 0; //How many times the players stopped the bomb as it was getting deployed
int stat_revived_players = 0; //How many times were players brought back to life by the medic

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
 * 
 * Note that we do not need to do all of the below, but they are the ideas that immediately popped into my head
 * Some of them might not even be possible :P
 * 
 * Ideas for individual stats (which can then be summed up to a global stat)
 * Damage taken
 * Times revived
 * 
 * 
 * Ideas for global stats (organized roughly according to class)
 * 
 * Cash collected by scout/spy
 * Cash not collected by scout/spy (to encourage people to pick up money)
 * Teammates milked
 * Opponents milked
 * 
 * Banners deployed by teammates
 * Banners deployed by opponents
 * Projectiles fired by teammates
 * Projectiles fired by opponents
 * 
 * Airblasts
 * Opponents gassed
 * Bomb resets
 * Bomb deploy resets
 * 
 * Stickies placed
 * Stickies detonated
 * Teammate charges
 * Opponent charges
 * Heads taken by teammates
 * Heads taken by opponents
 * Sentry busters detonated (do we include busters that don't explode?)
 * Players killed by sentry busters (heehoo)
 * 
 * Meals donated (As in, a heavy drops his food and another player picks it up)
 * Projectiles deflected
 * Penetration kills (technically applies to every penetrating weapon but heavy has the penetration upgrades)
 * Penetration damage
 * Times raged
 * 
 * Buildings destroyed by teammates
 * Buildings destroyed by opponents
 * Teammates teleported
 * Opponents teleported
 * Health given by dispensers
 * Ammo given by dispensers * 
 * 
 * Shared canteens (mvm_medic_powerup_shared)
 * Shield deployments
 * Teammates revived
 * Teammate deaths (only count these while a wave is active?)
 * Opponent deaths
 * Ubercharges used
 * 
 * Teammates jarated
 * Opponents jarated
 * Opponents killed by explosive headshot
 * Teammates sniped
 * Support snipers killed (Might not be possible if we can't figure out if a sniper is support)
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