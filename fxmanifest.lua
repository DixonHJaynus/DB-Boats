fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* break once RedM ships.'

name 'DB-Boats'
description 'Boat ownership, storage, and upgrade system for RSG Framework'
author 'DB Scripts'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/menus.lua',
    'client/certificate.lua',
    'client/features.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

lua54 'yes'

dependencies {
    'ox_lib',
    'ox_target',
    'rsg-core',
    'rsg-inventory',
}