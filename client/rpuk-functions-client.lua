-- Idk how RPUK handles any of these, to be routed later
RPUK = {}

-- UI message to player
function RPUK.notify(data)
    lib.notify(data)
end

-- Start progress bar
function RPUK.progressBar(options)
    return lib.progressBar(options)
end

-- Cancel progress bar early
function RPUK.cancelProgress()
    lib.cancelProgress()
end
