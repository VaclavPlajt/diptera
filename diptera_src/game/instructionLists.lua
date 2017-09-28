local instructionsLists = {};

local defaultStartDelay = 250;
local defaultDuration = 2500;

-- instruction  {textKey="string", tipKey = "string",
--      startDelay= in ms, duration=in ms , 
--      endEvent = string , endEventParams={{key=string, val=value}, ...},
--      startEvent = string , startEventParams={{key=string, val=value}, ...},
--      arrowTarget=string }
-- one line form: {textKey="string", tipKey = "string", startDelay= in ms, duration=in ms , endEvent = string , endEventParams={{key=string, val=value}, ...}, startEvent = string , startEventParams={{key=string, val=value}, ...}, arrowTarget=string }

instructionsLists.tutorial =
{   
    
    -- opening
    {textKey="inst.opening", startDelay=2000,  duration=2500},
    -- send minion to clean up spreading disease
    {textKey="inst.assignTocleaning", tipKey = "inst.assignToCleaningTip",
        --startEvent = "minionActionRequest", startEventParams={{key="action", val="repair"}},
        startEvent = "unitCreated", startEventParams={{key="unit", subkey="unitType", val="EnemyMissile"}},
        endEvent = "minionAssigmentRequest", endEventParams={{key="change", val="add"},{key="workType", val="repair"}},
        highlightUI="minionAssigner", highlightUIParams = "repair"},
    -- great you have made it
    {textKey="inst.minionAssigned", startDelay=defaultStartDelay
        --startEvent = "minionRequestEnd", startEventParams={{key="action", val="repair"}}
    ,duration=defaultDuration},
    -- now build walls to fill the gap
    {textKey="inst.fillWallGap", tipKey ="inst.fillWallGapTip",
        startDelay=3000,
        endEvent = "actionsAvailable", endEventParams={{key="actions", val="myEmptyTileSelected"}},
        --endEvent = "buildingCreated", endEventParams={
        --{key="building", subkey="typeName", val="BuildingSite"},
        --{key="building", subkey="targetBuildingType", val="Wall"}}
        },
    {textKey="inst.chooseActionWall", tipKey ="inst.chooseActionWallTip",
        startDelay=1000,
        --endEvent = "actionSelected", endEventParams={{key="action", val="buildWalls"},}},
        endEvent = "buildingCreated", endEventParams={
        {key="building", subkey="typeName", val="BuildingSite"},
        {key="building", subkey="targetBuildingType", val="Wall"}},
        arrowTarget="actionMenu"},
    -- great you start building walls
    --{textKey="inst.geatFirstWall", startDelay=defaultStartDelay, duration=defaultDuration}, 
    -- but now you wil need one transporter
    {textKey="inst.assignTransporter", tipKey = "inst.assignTransporterTip" ,  startDelay=defaultStartDelay,
        endEvent = "minionAssigmentRequest", endEventParams={{key="change", val="add"},{key="workType", val="transport"}},
        highlightUI="minionAssigner", highlightUIParams = "transport"}, 
    -- and also one worker 
    {textKey="inst.assignWorker", tipKey = "inst.assignWorkerTip", startDelay=defaultStartDelay,
        endEvent = "minionAssigmentRequest", endEventParams={{key="change", val="add"},{key="workType", val="work"}},
        highlightUI="minionAssigner", highlightUIParams = "work"}, 
    -- wall is now build
    {textKey="inst.wallBuild", 
        startEvent = "buildingCreated", startEventParams={{key="building",subkey="typeName", val="Wall"}},
        duration=defaultDuration}, 
    -- continue to fill all gaps 
    {textKey="inst.continueToFillGap", startDelay=defaultStartDelay, duration=defaultDuration}, 
    -- now expansion, build the gun
    {textKey="inst.nowExpansion", tipKey="inst.nowExpansionTip", startDelay=10000,
        endEvent = "buildingCreated", endEventParams={{key="building",subkey="typeName", val="Gun"}},},
    -- great, gun is build. Now set target.
    {textKey="inst.targetGun", tipKey="inst.targetGunTip",  startDelay=defaultStartDelay,
        --startEvent = "buildingCreated", startEventParams={{key="building",subkey="typeName", val="Gun"}},
        --endEvent = "actionSelected", endEventParams={{key="action", val="setTarget"},
        endEvent = "infoevent", endEventParams={{key="info", val="gunTargeted"},}
        },
    -- gun tips
    {textKey="inst.gunTips", startDelay=defaultStartDelay, duration=defaultDuration},
    -- deliver enough medicine to cure one location
    {textKey="inst.deliverMedicine", startDelay=defaultStartDelay, 
        endEvent = "keepDestroyed"},
    -- now quickly send workers to remove rest of the disease, you may need to clear the way to it
    {textKey="inst.nowConvertIt", tipKey="inst.nowConvertItTip" , startDelay=defaultStartDelay, 
        endEvent = "actionSelected", endEventParams={{key="action", val="convert"}},
    },
    -- clear the path
    {textKey="inst.nowClearPath",  startDelay=defaultStartDelay, 
        --delay=250,
    },
    -- superb, you just cleaned up your first area
    {textKey="inst.firstTakenArea",
        startEvent = "buildingCreated", endEventParams={{key="building",subkey="typeName", val="Keep"}},
    },
    {textKey="inst.endInstructions",  startDelay=defaultStartDelay, 
        duration=defaultDuration,
    },
    
}



instructionsLists.lvl1 = {
    {textKey="inst.lvl1UncoverTreasures",  startDelay=defaultStartDelay, 
        duration=defaultDuration,
    }
}





return instructionsLists;

