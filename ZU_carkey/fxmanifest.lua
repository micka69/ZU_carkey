fx_version 'cerulean'
game 'gta5'

author 'Votre Nom'
description 'Script de verrouillage de véhicule ESX Legacy avec ox_target'
version '1.0.0'
lua54 'yes'
shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

dependencies {
    'es_extended',
    'ox_target'
}