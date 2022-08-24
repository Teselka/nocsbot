#include <sourcemod>
#include <dhooks>

public Plugin myinfo = {
    name        = "nocsbot",
    author      = "Teselka",
    description = "Removes annoying notification from the console",
    version     = "1.0.0",
    url         = "https://github.com/Teselka/nocsbot"
};

Handle hConfigFile;
DHookSetup hParseAllEntitiesDetour;
DynamicDetour hShouldCreateEntityDetour;
Address pLastHookedFilter = Address_Null;

// 
MRESReturn Detour_ShouldCreateEntity(DHookReturn hReturn, DHookParam hParams)
{
    Address pClassName = DHookGetParamAddress(hParams, 1);
    if (pClassName != Address_Null)
    {
        static char sClassName[32];
        DHookGetParamString(hParams, 1, sClassName, sizeof(sClassName));
        
        if (strcmp(sClassName, "cs_bot_patrol_route_waypoint", true) == 0)
        {
            DHookSetReturn(hReturn, 0);
            return MRES_Override;
        }
    }
    
    return MRES_Handled;
}


// MapEntity_ParseAllEntities
MRESReturn Detour_ParseAllEntities(DHookReturn hReturn, DHookParam hParams) 
{
    Address pFilter = DHookGetParamAddress(hParams, 2);
    if (pFilter != Address_Null && pFilter != pLastHookedFilter)
    {
        if (pFilter != Address_Null)
        {
            if (hShouldCreateEntityDetour)
                delete hShouldCreateEntityDetour;
            
            hShouldCreateEntityDetour = DHookCreateDetour(
                LoadFromAddress(LoadFromAddress(pFilter, NumberType_Int32), NumberType_Int32), 
                CallConv_THISCALL, 
                ReturnType_Bool, 
                ThisPointer_Ignore
            );
            DHookAddParam(hShouldCreateEntityDetour, HookParamType_CharPtr, 0, DHookPass_ByVal, DHookRegister_Default);
            DHookEnableDetour(hShouldCreateEntityDetour, false, Detour_ShouldCreateEntity);
        }
    }
    else
        DHookEnableDetour(hShouldCreateEntityDetour, false, Detour_ShouldCreateEntity);
    
    return MRES_Handled;
}

MRESReturn Detour_ParseAllEntitiesPost(DHookReturn hReturn, DHookParam hParams) 
{
    // That's because it's a compiler shared function :sunglasses:
    if (hShouldCreateEntityDetour)
        DHookDisableDetour(hShouldCreateEntityDetour, false, Detour_ShouldCreateEntity);
    
    return MRES_Handled;   
}

public void OnPluginStart()
{
    hConfigFile = LoadGameConfigFile("nocsbot");
    if (hConfigFile == INVALID_HANDLE)
        SetFailState("Failed to load nocsbot gamedata.");

    if ((hParseAllEntitiesDetour = DHookCreateFromConf(hConfigFile, "MapEntity_ParseAllEntities")) == INVALID_HANDLE)
        SetFailState("Failed to load MapEntity_ParseAllEntities signature from gamedata");

    if (!DHookEnableDetour(hParseAllEntitiesDetour, false, Detour_ParseAllEntities))
        SetFailState("Failed to detour MapEntity_ParseAllEntities.");
        
    if (!DHookEnableDetour(hParseAllEntitiesDetour, true, Detour_ParseAllEntitiesPost))
        SetFailState("Failed to detour MapEntity_ParseAllEntities.");
}

public void OnPluginEnd()
{
    DHookDisableDetour(hParseAllEntitiesDetour, false, Detour_ParseAllEntities);
    DHookDisableDetour(hParseAllEntitiesDetour, true, Detour_ParseAllEntitiesPost)
}
