# Implementation Plan for Hands Diff v2

## Overview
Our current state is that we have a working OBS plugin and a web application that creates interactive data visualizations for League of Legends game data. Our goal is to combine the already available Riot API data with the OBS plugin to allow for League of Legends players and streamers to see how they play the game and its relationship to their individual and team performance. 

Now that we've added D3.js to the web application, I see there are a number of new possibilities for data capture and visualization that would better suit the needs of League of Legends players and streamers.

## v2 Goals

### Data Capture
I want to simplify and unify the main engine for data capture and processing. This new data structure should be a highly accurate time series that captures all user input events throughout the game. We should keep our current design of only capturing data when the game is in progress as this will produce the best quality data for analysis.

The new data structure will capture a new datapoint every time the user presses a key or clicks a mouse button. Each datapoint will include a timestamp, x and y coordinates of the mouse cursor, and the key that was pressed or the mouse button that was clicked. We will use this time series data to derive all of our statistics and insights. It's important that we get an accurate time sync with the game to ensure that the data can be properly correlated with the game state.

### Riot API and Game Client API
#### Riot API Docs
- https://developer.riotgames.com/docs/lol

#### Riot API - Match-v5
- https://developer.riotgames.com/apis#match-v5
- Get games by PUUID - `/lol/match/v5/matches/by-puuid/{puuid}/ids`
- Get match data - `/lol/match/v5/matches/{matchId}`
- Get timeline data - `/lol/match/v5/matches/{matchId}/timeline`

#### Game Client API
**Active Player**
`GET ​https://127.0.0.1:2999/liveclientdata/activeplayer`
```
{
    "abilities": {...},
    "championStats": {
      "abilityHaste": 0.00000000000000,
      "abilityPower": 0.00000000000000,
      "armor": 0.00000000000000,
      "armorPenetrationFlat": 0.0,
      "armorPenetrationPercent": 0.0,
      "attackDamage": 0.00000000000000,
      "attackRange": 0.0,
      "attackSpeed": 0.00000000000000,
      "bonusArmorPenetrationPercent": 0.0,
      "bonusMagicPenetrationPercent": 0.0,
      "cooldownReduction": 0.00,
      "critChance": 0.0,
      "critDamage": 0.0,
      "currentHealth": 0.0,
      "healthRegenRate": 0.00000000000000,
      "lifeSteal": 0.0,
      "magicLethality": 0.0,
      "magicPenetrationFlat": 0.0,
      "magicPenetrationPercent": 0.0,
      "magicResist": 0.00000000000000,
      "maxHealth": 0.00000000000000,
      "moveSpeed": 0.00000000000000,
      "physicalLethality": 0.0,
      "resourceMax": 0.00000000000000,
      "resourceRegenRate": 0.00000000000000,
      "resourceType": "MANA",
      "resourceValue": 0.00000000000000,
      "spellVamp": 0.0,
      "tenacity": 0.0
    }
    "currentGold": 0.0,
    "fullRunes": {...},
    "level": 1,
    "summonerName": "Riot Tuxedo",
    "riotId": "Riot Tuxedo#TXC1",
    "riotIdGameName": "Riot Tuxedo",
    "riotIdTagLine": "TXC1"
}
```
We will use this data to track the player's `currentGold`, `level`, and ability levels for the active player.
We can also use this for a one-time snapshot of the player's runes. We can use the value of 'currentGold' and it's change when purchasing items to track a player's total gold and total gold spent. We can verify gold totals by cross-referencing with an end of game endpoint.


**All Players**
`GET ​https://127.0.0.1:2999/liveclientdata/playerlist`
```
[
    {
        "championName": "Annie",
        "isBot": false,
        "isDead": false,
        "items": [...],
        "level": 1,
        "position": "MIDDLE",
        "rawChampionName": "game_character_displayname_Annie",
        "respawnTimer": 0.0,
        "runes": {...},
        "scores": {...},
        "skinID": 0,
        "summonerName": "Riot Tuxedo",
        "riotId": "Riot Tuxedo#TXC1",
        "riotIdGameName": "Riot Tuxedo",
        "riotIdTagLine": "TXC1",
        "summonerSpells": {...},
        "team": "ORDER"
    },
    ...
]
```
We will use this data to track death timers, player levels, and player positions. Death timers will be used to track when players die and respawn which create critical power plays in the game. Player levels are often used to determine catchup mechanics like bonus xp, shutdown gold, and other game elements. All we need to worry about is tracking our player's level, their matchup's level (enemy team same position), and the average level of all players in the game.

`GET ​https://127.0.0.1:2999/liveclientdata/playeritems?riotId=`
```
[
    {
        "canUse": true,
        "consumable": false,
        "count": 1,
        "displayName": "Warding Totem (Trinket)",
        "itemID": 3340,
        "price": 0,
        "rawDescription": "game_item_description_3340",
        "rawDisplayName": "game_item_displayname_3340",
        "slot": 6
    },
    ...
]
```
We will use this data to track changes to the player's inventory and items. We can use the data dragon to get the item names, descriptions, gold values, and other item-related data (https://ddragon.leagueoflegends.com/cdn/16.15.1/data/en_US/item.json). 


**Game Events**
GET ​https://127.0.0.1:2999/liveclientdata/eventdata
```
{
    "Events": [
        {
            "EventID": 0,
            "EventName": "GameStart",
            "EventTime": 0.0325561985373497
        },
        ...
    ]
}
```
We will use this to help us construct the game timeline and track when events occur.

#### Data Dragon - League of Legends Game Assets
- Items - https://ddragon.leagueoflegends.com/cdn/16.15.1/data/en_US/item.json
- Champions - https://ddragon.leagueoflegends.com/cdn/16.15.1/data/en_US/champion.json


## Changes for v1
### Plugin Architecture
Our most widely used feature will be (1) the minimap cover and (2) the camera positioning helper. My research shows that most streamers, especially at apex tiers, use a webcam and a map cover. I think our plugin structure should be organized around these two features by default with the ability to expand to the input overlay and other features. The bottom of the screen should be reserved for these two features and nothing else. We need to also allow for a second camera position that is between the central bottom HUD and the minimap. This is because streamers use both webcam positions in their setups and we want to give them control over where the camera is positioned.

Everything above the minimap should be reserved for input activity features. We should allow users to choose which input activity features they want to display and where they want to display them. We should have this configured as top, left, and right sections. These should all be able to be toggled on and off independently.

#### Top Section
The top section should be able to display up to 4 input activity features. These should be able to be toggled on and off independently. The features that should be allowed up here are as follows:
- Cumulative totals - Total number of clicks, keypressed, and actions performed during the game.
- Live key row - Shows the current state of the keyboard keys being pressed. This should be just the row of live keys that are currently being pressed, not the top keys that are always visible.
- Mouse distance traveled - Shows the total distance the mouse has traveled during the game.
- Input intensity - Shows mouse velocity, APM, CPM, and KPM based on user preference. 

#### Left/Right Sections
The left and right sections should be identical in functionality but positioned on opposite sides of the screen. The following features should be allowed in these sections:
- Mouse activity map - Shows a visual representation of mouse activity on the map.
- Cumulative totals - Total number of clicks, keypressed, and actions performed during the game.
- Live key row - Shows the current state of the keyboard keys being pressed. 
- Top keys - Shows the top keys that are always visible.

#### Mouse activity changes
While dwell time with the hexbins felt like a good idea at the time, I've found that it doesn't provide much value to users. I'd like to remove this feature and replace it with a simple mouse activity map that shows the current position of the mouse on the map and a line that connects the last 20 clicks in a fading trail that reduces each segment's opacity by 5% each click. That makes it so the most recent clicks are the most visible and the oldest clicks are the least visible. This also better aligns with the way we are capturing input information. 

This 'click trail' should also indicate whether a click was left right or middle. We can indicate these through color where right click is blue, left click is red, and middle click is yellow. If a key is pressed, we should add to the trail a point that shows the key that was pressed. The user should be able to select which keys are shown in the trail and which are not. By defaut we should present the user with 'left/right' as the default option with a checkbox for middle mouse button and a checkbox for keys. There should be another checkbox for 'advanced' that allows the user to whitelist or blacklist keys.

This change is partially motivated by us switching to time series data for our input capture. Ultimately each time series element should consist of a timestamp, mouse location, input type, and input value. We can derive all other analysis from this data structure.

### Plugin Settings UX
Here is a rough outline of how I imagine the settings UX flow:

#### General Settings
- Link user's config file to plugin settings
- Checkbox for map cover (default: checked)
    - Checkbox for custom image
        - File picker for custom image
- Checkbox for camera (default: checked)
    - Dropdown to link source camera
        - Tooltip to make sure camera is above 'Hands Diff' plugin layer
    - Sliders for camera (translate-x, translate-y, scale, % of safe area height, % of safe area width) with default values. Please just copy the existing camera preferences from the current plugin.
- Checkbox for auto-switch between game and client (default: checked)
    - Dropdown to select client capture from sources
    - Dropdown to select game capture from sources
    - Checkbox for advanced poisitioning (default: unchecked)
        - Number input for 'Game frame left', and 'Game frame top'. We should pre-populate the game screen dimensions below these inputs just as text and based on the game config file. This can help ensure that we are reading the screen resolution in the config file properly. For reference, this is listed as follows in the config file:
        ```
        [General]
        EnableScreenShake=0
        Height=1440
        Width=2560
        ```
        We should list it as 'Screen resolution: 2560x1440' below the inputs.
- 

#### Input Analysis Settings
- Checkbox for input analysis (default: unchecked). If checked, the following settings will be available:
    - Connect OBS to input analysis website (see existing setup)
    - Checkbox for Top HUD (default: unchecked)
        - Select number of columns (default: 2, between 1 and 4)
        - Default data - Col 1 = Mouse velocity boxplot, Col 2 = APM boxplot
        - From a number of dropdowns equal to the number of columns, select what to display in each column (keep in mind each column can have a different width. Only the spacing between the elements should remain consistent)
            - See plugin architecture for options
    - Checkbox for Left HUD (default: unchecked)
        - Select number of rows (default: 3, between 1 and 4)
        - Default data - Row 1 = mouse activity map, Row 2 = total clicks, Row 3 = total mouse distance
        - From a number of dropdowns equal to the number of rows, select what to display in each row (keep in mind each row can have a different width. Only the spacing between the elements should remain consistent)
            - See plugin architecture for options
    - Checkbox for Right HUD (default: unchecked)
        - Select number of rows (default: 2, between 1 and 4)
        - Default data - Row 1 = live keys row (max 4 showing), Row 2 = top keys (top 8)
        - From a number of dropdowns equal to the number of rows, select what to display in each row (keep in mind each row can have a different width. Only the spacing between the elements should remain consistent)
            - See plugin architecture for options

#### Default Settings
- Look at the current state of my plugin locally and use that as the hard coded values for element spacing, color, and typography. In a future release we can make these customizable for each user but for now we need to maintain consistency with the current plugin.