fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'txApi'
author 'Nick'
version '2.0.3'
repository 'https://github.com/NickTacke/txApi'
description 'FiveM resource that uses txAdmin web-endpoints to access players/actions'

server_only 'yes'
server_scripts {
    'settings/*.lua',
    'core/loader.lua',
    'core/main.lua',
    'core/**/*.lua'
}