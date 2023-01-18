-- this is where we'll store our hooks
local hooks = {}

-- this is the function used for registering hooks
function RegisterHook(priority, cb)

    -- get the calling resource
    local caller = GetInvokingResource()
    caller = caller == nil and GetCurrentResourceName() or caller

    -- validate priority type
    if(priority ~= nil and type(priority) == "number") then

        -- check if a hook already exists with the given priority, and print a warning if so
        if(hooks[priority] ~= nil) then
            print(("[deferralmanager] WARNING: A hook already exists with priority ^3%i ^7from ^3%s^7! (%s)"):format(
                priority, hooks[priority].resource, caller
            ))
        end

        -- "register" our hook object, potentially overwriting any present hook with the given priority
        hooks[priority] = {
            resource = caller,
            callback = cb
        }

    else
        error(("Invalid priority provided! Type was %s (number expected)"):format(type(priority)))
    end
end

-- listen for the playerConnecting event
AddEventHandler("playerConnecting", function(_, __, deferrals)

    -- store the connecting player here for future use
    local src = source

    -- if there are any hooks registered, then defer the connection
    if(#hooks > 0) then
        deferrals.defer()
        Wait(1)
    end

    -- hasCancelled is used for checking if the player has been rejected by a hook
    local hasCancelled = false

    -- we store the default done() function before we override it for hooks
    local done = deferrals.done

    -- loop through every hook function in the table in reversed order (priority support)
    for priority, obj in pairs(hooks) do
        local hook = obj.callback

        -- complete is used for determining if the hook has called done() or not
        local complete = false

        -- the text given by a hook for rejecting a player
        local rejectionText = nil

        -- override the done() function with our own behaviour
        local obj = deferrals
        obj.done = function(str)
            complete = true
            rejectionText = str
        end

        -- call the current hook with the source and our new deferrals object
        hook(src, obj)
            
        -- wait for the hook to complete
        while(not complete) do
            Wait(0)
        end

        -- if the rejection text is set, then reject the connecting player with its contents
        if(rejectionText ~= nil) then
            done(rejectionText)
            hasCancelled = true
            break
        end
    end

    -- automatically call done() if all of the hooks completed without rejection
    if(not hasCancelled) then
        done()
    end
end)

-- export the register function to be used by other scripts :)
exports("RegisterHook", RegisterHook)
