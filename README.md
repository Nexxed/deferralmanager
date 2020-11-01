# Deferral Manager
A simple dependency resource that synchronously chains deferral handlers together, allowing more than one resource to utilize [adaptive cards](https://cookbook.fivem.net/2019/06/29/adaptive-cards-in-deferrals/) on player connect, as well as using deferrals in a specific order via the `hookId` argument.
*You don't have to use adaptive cards, but they are pretty cool so you should if you want to provide any information to the connecting player :)*

## How to use
Both of these examples assume that you have a valid adaptive card object somewhere in the environment.
#### Traditional Method (using the `playerConnecting` event):
```lua
AddEventHandler("playerConnecting", function(playerName, setKickReason, deferrals)
    local player = source

    deferrals.defer()
    Wait(1)

    deferrals.presentCard(card, function(data, rawData)
        deferrals.presentCard(card, function(data, rawData)
            -- ... chaining cards!

            deferrals.done()
        end)
    end)
end)
```

#### DM Method (using the `RegisterHook` export):
Since deferral manager comes with an export for registering a callback/hook (similar to the default `playerConnecting` event), you can use this instead:
```lua
exports.deferralmanager:RegisterHook(1, function(source, deferrals)
    local player = source

    deferrals.presentCard(card, function(data, rawData)
        -- ... chaining cards!

        -- this will stop any hooks after this one from
        -- firing and will reject the player from connecting
        -- with the given string as a reason
        deferrals.done("Not allowed")
    end)
end)
```
You can use/port any existing event callbacks for `playerConnecting` with some minor changes to the arguments as its *somewhat* backwards compatible with such.
*Though keep in mind that this hasn't really been extensively tested, but it **should** work out-of-the-box.*

The first argument to the RegisterHook function is a hook index value - this lets you have full control over what deferrals get fired first, just like a priority system with the lowest index being fired first and the highest being fired last.
An example use case for this is a simple "check if player is banned" with a hook index of 1, and then check other stuff if they're not banned with a greater hook index.
*Calling `deferrals.done` with a string as the first parameter rejects the player and prevents any other hooks (after the one it was used in) to fire. But not using `deferrals.done` at all will let it go to the next hook. Simple stuff!*

## Detailed explanation & using it with callbacks
### The syntax:
```lua
exports.deferralmanager:RegisterHook(hookId, callback[source, deferrals])
```
The deferrals parameter is just like how it is in the `playerConnecting` event, except that when you call `deferrals.done` without a string, it goes onto the next hook.

This is a synchronous function, meaning that the deferral manager will wait until the current hook has finished completing its task(s) before moving-on to the next.

### Using it with "async" callbacks:
Here's how to use it with "async" functions (callbacks) in Lua:
```lua
exports.deferralmanager:RegisterHook(10, function(source, deferrals)
    deferrals.update("Doing some checks...")
    Wait(1)

    local complete = false
    someFunctionCallWithACallback(function(...)
        complete = true
    end)

    while not complete do
        Wait(0)
    end

    -- you don't need to call deferrals.done if you're not
    -- rejecting the player, as DM does that for you to prevent hangs
    --
    -- but obviously, this can and *will* work against you if you don't wait for any
    -- callbacks to complete, as it'll let the player through before the callback is actually called
end)
```

## Handling duplicate hook indexes
By default, the resource will send a warning to the server console if a resource tries to register a hook with an already-existing index.
The manager cannot have two hooks with the same index, so the callback will be overwritten and the previous hook to use that specific index will no longer work.
So make sure you construct a "map" of some kind to keep track of which deferrals use which indexes - the resource will warn about any duplicates so it'll be easy to spot them anyway.

# Notable projects that use this resource
- None yet!