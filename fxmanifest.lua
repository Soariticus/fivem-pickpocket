fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_script '@ox_lib/init.lua'

client_scripts {
    'client/rpuk-functions-client.lua',
    'client/outcomes.lua',
    'client/client.lua',
}

server_scripts {
    'server/config.lua',
    'server/rpuk-functions.lua',
    'server/server.lua',
}

dependency 'ox_lib'