# fivem-pickpocketing
A simple and basic setup to allow for the player to pickpocket local peds, with tiered loot depending on skill progression, success chances based on street cred (even if that doesn't make 100% sense), and police dispatches with variable chance depending on whether or not there is a second local that witnesses it.

Put together for RPUK, in preparation of my application as dev.

### Showcase
[GIF TBA] [GIF TBA]  
[GIF TBA] [GIF TBA]

## Features
### Gameplay
- Pickpocket locals by staying near them whilst a progress bar runs
- Per-ped cooldown
- Always a chance of a police dispatch, increased if there is a 'witness'
- Success chance scales up with street cred
	- Unsure how else to incorporate street cred
- Rewards scale up with pickpocket level
- Successful attempts reward:
	- Loot based on level loot tables
	- Street cred
	- Pickpocket skill progression
- Unsuccessful attempts:
	- Makes ped flee or fight
	- Lose some street cred

### AntiCheat
- Outcome is decided server-side
- Suspicious activity output to Discord
- Every instance of pickpocketing is logged
- Server-side verification for
	- Distance between player and ped
	- Per-ped cooldown
	- Duration between initiating and finishing a pickpocket
	- Confirming completion of a pickpocket without first being initiated

## Config
- Timings & range (pickpocket duration, cooldown, max distance)
	- `PickpocketTime` and `CooldownTime` are duplicated in `client/client.lua`, to avoid a shared config, need to be kept in sync
- Success chance, + street cred scaling
- Police dispatch chances
- Success & failure outcome weights
- Street cred gain/loss
- Skill progression
- Loot tables per skill level

## Implementation
Start a pickpocket by triggering the client event `pickpocket:start`:
```lua
TriggerEvent('pickpocket:start', { entity = ped })
```
All RPUK-specific code is isolated in `server/rpuk-functions.lua` and `client/rpuk-functions-client.lua`, and documented inline.