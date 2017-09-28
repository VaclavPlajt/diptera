-- game constants

local gameConst =
{
    ---- buildings
    Wall =          {toughness=50, materialCost = 1,  workCost = 3 , repairRequestLimitMultip = 0.75},
    Gun =           {toughness=1,  materialCost = 10, workCost = 10, firePeriod = 7000, misilesDamage = 5, chargingWorkCost = 10},
    Keep =          {              materialCost = 0,  workCost = 0 },
    HomeKeep =      {toughness=50, materialCost = 0,  workCost = 0 },
    EnemyKeep =     {              materialCost = 0,  workCost = 0, firePeriod = 5000, misilesDamage = 1 },
    DestroyedKeep = {toughness=1,                                   conversionWorkCost = 20, regenerationTime =  45000},
    BuildingSite =  {toughness=1                                   },
    
    ---- cluster power categories 
    -- some properties are characterized by normal distribution where:
    -- mean - mean value
    -- sigma - standart deviation, follows 68-95-99.7 rule also called the 3-sigma rule
    clustersPowerCategories = {
        {damage = 1,                                    keepToughness = {mean=15, sigma =1}, firePeriod = 8000  }, -- 1
        {damage = 2,                                    keepToughness = {mean=20, sigma =2}, firePeriod = 6000 }, -- 2
        {damage = {mean=3, sigma =0.5, min =2, max =4}, keepToughness = {mean=30, sigma =3}, firePeriod = {mean = 6000, sigma = 500} }, -- 3
        {damage = {mean=3, sigma =1  , min =3, max =6}, keepToughness = {mean=40, sigma =4}, firePeriod = {mean = 5000, sigma = 500}}, -- 4
        {damage = {mean=4, sigma =1  , min =3, max =8}, keepToughness = {mean=50, sigma =5}, firePeriod = {mean = 4000, sigma = 500}}, -- 5
    },
    
    
    --- treasure categories
    treasures = {
        empty=   { workCost = 20, minPowerCategory = 1, params = {}},
        movementBoost= { workCost = 40, minPowerCategory = 3, params = {multiplier = 1.3}},
        wallBoost =    { workCost = 30, minPowerCategory = 2, params = {multiplier = 1.5}},
        workBoost =    { workCost = 30, minPowerCategory = 2, params = {multiplier = 0.75}},
        gunBoost =    { workCost = 30, minPowerCategory = 2, params = {multiplier = 1.6}},
        newMinions =   { workCost = 40, minPowerCategory = 2, params = {amount = 1}},
        newMaterial=   { workCost = 30, minPowerCategory = 1, params = {amount = 50}},
    },
    
    ---- units
    -- minions
    minionWorkUnitDelay = 700, -- in ms
    minionRepairDelay = 400, -- in ms
    minionMovementSpeed = 3, -- in tiles per second
    minionWorkTypes = {"repair","work", "transport", "idle"},
    
    -- player missiles
    missile = {
        movementSpeed = 2, -- in tiles per second
        --movementSpeed = 1, -- in tiles per second
    },
    
    -- AI parameters
    AIParams = {
        enemyMissileMovementSpeed = 4, -- in tiles per second
        --enemyMissileMovementSpeed = 2,
        
        --[[
        -- bombardment
        startBombardingPeriod = 600000, -- in ms
        bombardingPeriodShortening = 0.95, -- dimension less
        minBonbardmentPeriod = 10000, -- in ms
        startBombardingDamage = 5,
        bombardingDamageGrowt = 1.3,
        maxBombardingDamage = 10,
        bombardingAreaSize = 3, 
        ]]
    },
         
    
    ---- other constants
    deconstructMaterialReturnRatio = 0.75,
}




return gameConst;

