fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'txApi'
author 'Arceas'
version '1.1.3'
repository 'https://github.com/NickTacke/txApi'
description 'A sketchy FiveM resource that uses txAdmin web-endpoints to access players/actions'

server_only 'yes'
server_scripts {
    'settings/config.lua',
    'src/api.lua',
    'src/actions.lua',
    'src/players.lua',
    'src/server.lua',
    'main.lua'
}