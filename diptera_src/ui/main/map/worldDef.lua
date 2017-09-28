local worldDef={
    --[[
    {
        mapSize = 3, 
        --cleared = true, -- level cleared (done)
        powerCat =5, -- keep power category, 1-5 or "home"
        gameName = "test",
    },
    ]]
    {
        mapSize = 3, 
        --cleared = true, -- level cleared (done)
        powerCat =1, -- keep power category, 1-5 or "home"
        gameName = "tutorial",
    },
    {
        mapSize = 3, 
        --cleared = false, -- level cleared (done)
        powerCat =2, -- keep power category, 1-5 or "home"
        gameName = "lvl1",
        items = {{name="Treasure", r=2, u=1}, {name="Treasure", r=3, u=3}},
    },
    {
        mapSize = 5, 
        --cleared = false, -- level cleared (done)
        powerCat =3, -- keep power category, 1-5 or "home"
        gameName = "lvl2",
        items = {{name="Material",r=5,u=4}, {name="Bullet",r=2,u=2},{name="Treasure", r=3, u=2},{name="Bullet",r=4,u=1}, {name="Treasure", r=5, u=2} },
    },
    {
        mapSize = 7, 
        --cleared = false, -- level cleared (done)
        powerCat =4, -- keep power category, 1-5 or "home"
        gameName = "lvl3",
        items = {
            {name="Material",r=2,u=2},{name="Material",r=6,u=4},
            {name="Bullet",r=2,u=6},{name="Bullet",r=7,u=1},{name="Bullet",r=4,u=6},
            {name="Treasure", r=4, u=2}, {name="Treasure", r=7, u=5},
        },
    },
    {
        mapSize = 9, 
        --cleared = false, -- level cleared (done)
        powerCat =5, -- keep power category, 1-5 or "home"
        gameName = "lvl4",
        items = {
            {name="Material",r=2,u=2},{name="Material",r=9,u=8},{name="Material",r=3,u=4},
            {name="Bullet",r=2,u=6},{name="Bullet",r=7,u=1},{name="Bullet",r=4,u=7},{name="Bullet",r=8,u=6},
            {name="Treasure", r=4, u=1}, {name="Treasure", r=7, u=5},{name="Treasure", r=6, u=8},{name="Treasure", r=8, u=2},{name="Treasure", r=2, u=7}
        },
    },
    {
        mapSize = 11, 
        --cleared = false, -- level cleared (done)
        powerCat ="home", -- keep power category, 1-5 or "home"
        gameName = "lvl5",
        items = {
            {name="Material",r=3,u=2},{name="Material",r=9,u=8},{name="Material",r=11,u=6},{name="Material",r=2,u=10},
            {name="Bullet",r=2,u=5},{name="Bullet",r=7,u=1},{name="Bullet",r=4,u=9},{name="Bullet",r=8,u=6},{name="Bullet",r=11,u=1},{name="Bullet",r=10,u=9},
            {name="Treasure", r=4, u=1}, {name="Treasure", r=7, u=5},{name="Treasure", r=6, u=8},{name="Treasure", r=8, u=2},{name="Treasure", r=2, u=7},{name="Treasure", r=5, u=10},{name="Treasure", r=4, u=4},{name="Treasure", r=8, u=4},
        },
    },

}

return worldDef;