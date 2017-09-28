# Events
The game uses a system of events so different parts can communicate to each other.

## User input events

* **"tiletapped"** - broadcasted when map tile has beed tapped
    - r, u  - tile coordiantes

* **"actionSelected"** -  broadcasted when user choose one of available actions
    - actionName - action name
    - params - parameters previously received by "actionsAvailable" event

## UI releated events

* **"actionsAvailable"** - broadcasted when new acions can be shown to the user
    -   actions - name of actions menu: emptyTileSelected/itemSelected
    -   keepHistory - enables backbutton on action panel
    -   params - other parameters releated to actions type
            - Item - selected map item, when action is itemSelected
            - r, u - coordinates of selected tile, when emptyTileSelected

> TODO possible future extension of tutorial, not implemented
> * "eventsBlocking" - broadcasted to switch event blocking on or off
>    -   action - "startBlocking"/"startBlocking"
>    -   scope - "tileTaps"/"userActions"/"all"
>    -   exeption

## Map and buildings graphics related events

* **"mapItemSelected"** - broadcasted when user taps/select item on map
    -   typeName - name of the item type
    -   item - selected item

* **"unitCreated"** -  broadcasted by new unit, when created, it is received by graphic objects to init graphics of unit
    - unit - the created unit
    - r,u - unit start coordinates

* **"unitDestroyed"** -  broadcasted by new unit, when created, it is received by graphic objects to init graphics of unit
    - unit - the created unit

* **"buildingCreated"** - broadcasted by new building, when created, it is received by graphic objects to init graphics of building
    - building  - the newly created building

## Minion events, control requests etc..

* **"minionActionRequest"** - broadcasted when some action from minios is requested
    -   action - action name: "work"/"transport"/"repair"
    -   request - table with request parameters
            - parameters:  
            -  gr, gu, - coordinates of place where the action is required
            -  amount - amount of action needed (e.g. work units), not needed for "repair" request
            -  onDelivery - optional, function called when one action is deleivered, called amount times 
            - action specific parameters:
                -  itemType - "trasport" action parameter, determines type of transported resourrces
                -  bannedItem - "transport" optional action parameter, bans one source of trasported items
                -  building - "repair" action parameter, building to repair

* **"minionRequestEnd"** - broadcasted when request is either done or cancelled
    -   action  - action name: "work"/"transport"/"repair"
    -   request - done or canceled request

* **"minionAssigmentChanged"** - broadcasted by minion controller, when minions are assigned to new work
    - assigments - new table of assigments

* **"minionAssigmentRequest"** - braodcasted when user inputs request to chnge minion assigments
    -   change - "add"/"remove" - ad or remove minion from work type assigment
    -   workType - work type name

## Main game events

* **"keepDestroyed"** - broadcasted when AI or human keep destroyed
    - keep  - destroyed keep

* **"keepRegenerated"** - broadcasted when untaken keep is regenerated
    - keep  - regenerated keep (its typeName is "DestroyedKeep")

* **"keepConverted"** - broadcasted when untaken keep is regenerated
    - keep  - regenerated keep (its typeName is "DestroyedKeep")

* **"bombLanded"** - broadcasted when AI player bombing human area
    -   r, u     - bombing coorginates
    -   areaSize - size of area damage
    -   damage   - amount of damage to dealt to buildings in area

* **"bombardmentUpdate"** - broadcasted when AI player updates its bobardment state
    -   bombardment - bombardment state

* **"treasureUnlocked"** - broadcasted when human player unlocks a treasure
    -   treasure - unlocked treasure map item

## Info events - mainly used by tutorial

* **"infoevent"** - broadcasted to pass some information, mostly to tutorial or in-game instructions
    -   info - passed info, possible values: "gunTargeted"/"matTaken"/"matAdded"/"matCount"

## Sound releated events

* **"soundsettings"** - broadcasted when player uses ui to tweak some sound setting 
    - ... add other options

* **"soundrequest"** - broadcasted when any components want to play a sound
    - type - type of played sound : "music"/"button"/""/"" ... 
    - soundName - when type=="playnammed", sound with given name will be played
    - x,y - location based sound, played only when x,y are within screen bounds. x,y have to e global content coordinates obtained by dispObj:localToContent()
    - musicParam - additional parameter for music type