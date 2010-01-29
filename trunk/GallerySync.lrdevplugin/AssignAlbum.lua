local LrDialogs = import 'LrDialogs'
local LrBinding = import 'LrBinding'
local LrErrors = import 'LrErrors'
local LrView = import 'LrView'
local bind = LrView.bind
local LrFunctionContext = import 'LrFunctionContext'
local LrProgressScope = import 'LrProgressScope'
local catalog = import 'LrApplication'.activeCatalog()
local logger = import 'LrLogger'('GallerySync.AssignAlbum')
logger:enable('print')

require 'TableUtils'
require 'Utils'

local Service = nil

local function updateAlbums(p)
    p.albums = {}
    for i,album in ipairs(Service.findAlbums()) do
        table.insert(p.albums, {title=album.title, value=album.id})
    end
    logger:debug('p.albums='..table.tostring(p.albums))
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
    }
end

function AssignAlbum(context)
    LrDialogs.attachErrorDialogToFunctionContext(context)
    
    logger:debug('targetPhotos: ' .. #catalog.targetPhotos)
    if #catalog.targetPhotos == 0 then
        LrErrors.throwUserError("You haven't selected any photo.")
    end
    
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
    
    -- current album detection
    local sameAlbums = true
    local previousAlbum = nil
    for i,photo in ipairs(catalog.targetPhotos) do
        if not previousAlbum then
            catalog:withReadAccessDo(function()
                previousAlbum = photo:getPropertyForPlugin(_PLUGIN, 'album_id')
            end)
        end
        local currentAlbum
        catalog:withReadAccessDo(function()
            currentAlbum = photo:getPropertyForPlugin(_PLUGIN, 'album_id')
        end)
        if currentAlbum~=previousAlbum then
            sameAlbums = false
            break
        end
    end
    if sameAlbums then
        p.selectedAlbum = previousAlbum
    end
    logger:debug('p.selectedAlbum='..p.selectedAlbum)
    --logger:debug('TEST ' .. table.tostring(getAlbum(Service.findAlbums(), p.selectedAlbum, nil)))
    
    local res = LrDialogs.presentModalDialog {
        title = 'Select album',
        contents = albumsDialog(f,p),
    }
    if res == 'ok' and p.selectedAlbum then
        catalog:withWriteAccessDo('Change online album', function()
            for i,photo in ipairs(catalog.targetPhotos) do
                -- change settings only if album changed!
                if photo:getPropertyForPlugin(_PLUGIN, 'album_id') ~= p.selectedAlbum then
                    photo:setPropertyForPlugin(_PLUGIN, 'id', nil)
                    photo:setPropertyForPlugin(_PLUGIN, 'album_id', tostring(p.selectedAlbum))
                    photo:setPropertyForPlugin(_PLUGIN, 'album', nil)
                    photo:setPropertyForPlugin(_PLUGIN, 'sync_options', 'resync')
                end
            end
        end)
    else
        LrErrors.throwCanceled()
    end
end

LrFunctionContext.postAsyncTaskWithContext('AssignAlbum', AssignAlbum)

