# Troubleshooting

!!!note
    Make sure that your Octagon module is completely up to date. It isn't a module which trades in reliability for laziness!

## False positives

Octagon is a server sided anti exploit, meaning there *will be* sometimes false positives of physics exploits. Octagon is designed in such a way that it will never punish players (such as bans, kicks) for exploiting, as server sided anti exploits can't be perfect due to replication latency. Instead, it teleports them to their last position and temporarily takes away the player's network owner.

!!!note
     Also make sure to require Octagon on the client side so it checks the humanoid state of the local player and prevents them from bouncing hard when they land on the ground to prevent false positives and prevent them from flinging.


## Players being monitored/detected despite being black listed in the config module

This is due to HTTP requests failing in a rare case, as Octagon checks player's group rank which send in an internal HTTP GET request to determine if they are the owner of the game's group or to determine if they are black listed from being monitored. 

If that is not the case, then the problem lies with [game.CreatorId](https://developer.roblox.com/en-us/api-reference/property/DataModel/CreatorId) returning an invalid userid of the game's owner's actual user id due to internal reasons. This only happens in Studio and make sure to test this out in an actual published game.

## Players being flagged for serverside teleportation 

Octagon will respect serverside teleportations, walk speed, velocity, jump power changes, etc. However, Octagon will not respect serverside teleportation of the player through the changing of [Position](https://developer.roblox.com/en-us/api-reference/property/BasePart/Position), but rather through [CFrame](https://developer.roblox.com/en-us/api-reference/datatype/CFrame) for internal reasons. Make sure you change the [CFrame](https://developer.roblox.com/en-us/api-reference/datatype/CFrame) of the player's primary part, not [Position](https://developer.roblox.com/en-us/api-reference/property/BasePart/Position).
