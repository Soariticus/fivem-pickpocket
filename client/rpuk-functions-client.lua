-- Idk how RPUK handles any of these, to be routed later
RPUK = {}


-- UI message to player
function RPUK.notify(message) -- message: string
    lib.notify({ description = message })
end

-- Start progress bar
function RPUK.progressBar(options) -- options: table{duration: int, label: string, canCancel: bool}
    return lib.progressBar(options)
end

-- Cancel progress bar early
function RPUK.cancelProgress()
    lib.cancelProgress()
end
