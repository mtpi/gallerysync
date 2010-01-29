local LrDialogs = import 'LrDialogs'
local LrBinding = import 'LrBinding'
local LrView = import 'LrView'
local bind = LrView.bind
local LrFunctionContext = import 'LrFunctionContext'
local LrProgressScope = import 'LrProgressScope'
local catalog = import 'LrApplication'.activeCatalog()
local logger = import 'LrLogger'('GallerySync.AssignAlbum')
logger:enable('print')

require 'Utils'

local Service = nil

local function updateAlbums(p)
    p.albums = {}
    for i,album in ipairs(Service.findAlbums()) do
        table.insert(p.albums, {title=album.title, value=album.id})
    end
end

local function createAlbumDialog(f, p)
    return f:row {
        fill_horizontal = 1,
        spacing = f:control_spacing(),
        bind_to_object = p,
        f:static_text {
            fill_horizontal = 1,
            title = 'Album name:',
        },
        f:edit_field {
            fill_horizontal = 1,
            value = bind 'albumName',
        },
    }
end

local function albumsDialog(f, p)
    return f:row {
        fill_horizontal = 1,
        spacing = f:control_spacing(),
        bind_to_object = p,
        f:static_text {
            fill_horizontal = 1,
            title = 'Album name:',
        },
        f:popup_menu {
            fill_horizontal = 1,
            items = bind 'albums',
            value = bind 'selectedAlbum',
        },
		f:push_button {
			title = 'Add',
			width = 50,
			height = 15,
			action = function()
                local res = LrDialogs.presentModalDialog {
                    title = 'Create album',
                    contents = createAlbumDialog(f,p),
                }
                if res == 'ok' and p.albumName then
                    Service.createAlbum(p.albumName)
                    updateAlbums()
                end
			end,
		},
    }
end

function AssignAlbum(context)
    LrDialogs.attachErrorDialogToFunctionContext(context)
    local progressScope = LrProgressScope {
        title = 'Updating album info',
        functionContext = context,
    }
    
    local f = LrView.osFactory()
    local p = LrBinding.makePropertyTable( context )
    
    Service = getService()
    if not Service.login() then
        LrDialogs.message('Login failed', 'Failed to login to ' .. Service.name .. '.', 'critical')
        return
    end
    updateAlbums(p)
    
    -- TODO: implement current album detection
    p.selectedAlbum = nil
    
    local res = LrDialogs.presentModalDialog {
        title = 'Select album',
        contents = albumsDialog(f,p),
    }
    if res == 'ok' and p.selectedAlbum then
        catalog:withWriteAccessDo('Change album', function()
            for i,photo in ipairs(catalog.targetPhotos) do
                photo:setPropertyForPlugin(_PLUGIN, 'album_id', tostring(p.selectedAlbum))
                photo:setPropertyForPlugin(_PLUGIN, 'album', nil)
                photo:setPropertyForPlugin(_PLUGIN, 'id', nil)
                photo:setPropertyForPlugin(_PLUGIN, 'needs_syncing', '1')
            end
        end)
    end
end

LrFunctionContext.postAsyncTaskWithContext('AssignAlbum', AssignAlbum)

