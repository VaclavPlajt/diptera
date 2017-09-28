

local gameTypesDefs ={
    
    
    test = 
    {
        
        startSet = { -- starting set of resources, walls and treasures etc ..
            material = 70, minions = 6, wallsDensity = 0.6,
            materialDepositsNum = 3, materialDepositsAmount = 30, bulletsDepositsNum = 9,
            treasures = {movementBoost=10, wallBoost=20, workBoost=25,gunBoost=25, newMinions=0, newMaterial=10, empty = 0},
            --treasures = {movementBoost=0, wallBoost=0, workBoost=0, newMinions=0, newMaterial=2, empty = 10},
            --treasures = {movementBoost=5, wallBoost=5, workBoost=5, newMinions=5, newMaterial=5, empty = 0},
        },
        
        mapParams = {
            giveMeEverything = true,
            randomSeed = 1317084424,
            size=32, numOfClusters = 16, 
            maxPowerCategory = 3,
            playerHomePosition = "west", 
            goalPosition = "east",
            --startSet = startSet
        },
        
        --instructions = require("game.instructionLists").tutorial;
        
    },
    
    tutorial = 
    {
        
        startSet = { -- starting set of resources, walls and treasures etc ..
            material = 50, minions = 3, wallsDensity = 0.6,
            materialDepositsNum = 3, materialDepositsAmount = 30, bulletsDepositsNum = 3,
            treasures = {movementBoost=0, wallBoost=0, workBoost=0,gunBoost=0, newMinions=0, newMaterial=0, empty = 0},
            --treasures = {movementBoost=0, wallBoost=0, workBoost=0, newMinions=0, newMaterial=2, empty = 10},
            --treasures = {movementBoost=5, wallBoost=5, workBoost=5, newMinions=5, newMaterial=5, empty = 0},
        },
        
        mapParams = {
            randomSeed = 1417082423,
            size=16, numOfClusters = 4, 
            maxPowerCategory = 1,
            playerHomePosition = "west", 
            goalPosition = "east",
            --startSet = startSet
        },
        
        instructions = require("game.instructionLists").tutorial;
        
    },
    
    lvl1 = 
    {
        
        startSet = { -- starting set of resources, walls and treasures etc ..
            material = 50, minions = 3, wallsDensity = 0.5,
            materialDepositsNum = 3, materialDepositsAmount = 25, bulletsDepositsNum = 6,
            treasures = {movementBoost=0, wallBoost=1, workBoost=1,gunBoost=0, newMinions=1, newMaterial=2, empty = 10},
            --treasures = {movementBoost=5, wallBoost=5, workBoost=5, newMinions=5, newMaterial=5, empty = 0},
        },
        
        mapParams = {
            randomSeed = 0,
            size=25, numOfClusters = 9, 
            maxPowerCategory = 3,
            playerHomePosition = "east", 
            goalPosition = "west",
            --startSet = startSet
        },
        
        instructions = require("game.instructionLists").lvl1;
        
    },
    
    lvl2 = 
    {
        
        startSet = { -- starting set of resources, walls and treasures etc ..
            material = 25, minions = 3, wallsDensity = 0.6,
            materialDepositsNum = 6, materialDepositsAmount = 30, bulletsDepositsNum = 12,
            treasures = {movementBoost=1, wallBoost=1, workBoost=1,gunBoost=1, newMinions=2, newMaterial=2, empty = 20},
            --treasures = {movementBoost=5, wallBoost=5, workBoost=5, newMinions=5, newMaterial=5, empty = 0},
        },
        
        mapParams = {
            randomSeed = 0,
            size=30, numOfClusters = 16, 
            maxPowerCategory = 3,
            playerHomePosition = "south", 
            goalPosition = "north",
            --startSet = startSet
        },
        
        --instructions = require("game.instructionLists").tutorial;
        
    },
    
    lvl3 = 
    {
        
        startSet = { -- starting set of resources, walls and treasures etc ..
            material = 60, minions = 2, wallsDensity = 0.1,
            materialDepositsNum = 7, materialDepositsAmount = 40, bulletsDepositsNum = 35,
            treasures = {movementBoost=3, wallBoost=2, workBoost=2, gunBoost=1, newMinions=2, newMaterial=3, empty = 55},
            --treasures = {movementBoost=5, wallBoost=5, workBoost=5, newMinions=5, newMaterial=5, empty = 0},
        },
        
        mapParams = {
            randomSeed = 0,
            size=30, numOfClusters = 25, 
            maxPowerCategory = 4,
            playerHomePosition = "east", 
            goalPosition = "west",
            --startSet = startSet
        },
        
        --instructions = require("game.instructionLists").tutorial;
        
    },
    
    lvl4 = 
    {
        
        startSet = { -- starting set of resources, walls and treasures etc ..
            material = 60, minions = 2, wallsDensity = 0.0,
            materialDepositsNum = 0, materialDepositsAmount = 30, bulletsDepositsNum = 20,
            treasures = {movementBoost=2, wallBoost=2, workBoost=3, gunBoost=3, newMinions=6, newMaterial=17, empty = 100},
            --treasures = {movementBoost=5, wallBoost=5, workBoost=5, newMinions=5, newMaterial=5, empty = 0},
        },
        
        mapParams = {
            randomSeed = 0,
            size=36, numOfClusters = 25, 
            maxPowerCategory = 5,
            playerHomePosition = "west", 
            goalPosition = "east",
            --startSet = startSet
        },
        
        --instructions = require("game.instructionLists").tutorial;
        
    },
    
    lvl5 = 
    {
        
        startSet = { -- starting set of resources, walls and treasures etc ..
            material = 80, minions = 2, wallsDensity = 0.0,
            materialDepositsNum = 10, materialDepositsAmount = 25, bulletsDepositsNum = 20,
            treasures = {movementBoost=3, wallBoost=3, workBoost=3,gunBoost=3,newMinions=10, newMaterial=10, empty = 110},
        },
        
        mapParams = {
            randomSeed = 0,
            size=45, numOfClusters = 36, 
            maxPowerCategory = 5,
            playerHomePosition = "north", 
            goalPosition = "south",
            --startSet = startSet
        },
        
        --instructions = require("game.instructionLists").tutorial;
    }
}













return gameTypesDefs;

