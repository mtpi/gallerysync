local LrFunctionContext = import 'LrFunctionContext'
local LrErrors import 'LrErrors'
local LrDialogs = import 'LrDialogs'
local LrDate = import 'LrDate'
local LrExportSession = import 'LrExportSession'
local LrPrefs = import 'LrPrefs'
local LrProgressScope = import 'LrProgressScope'
local catalog = import 'LrApplication'.activeCatalog()
local prefs = import 'LrPrefs'.prefsForPlugin()
local logger = import 'LrLogger'('GallerySync.Sync')
logger:enable('print')

local Service = nil
require 'TableUtils'
require 'StringUtils'
require 'Utils'

local function getAlbum(albums, id, title)
    for i, album in ipairs(albums) do
        if id and album.id==id then
            return album
        end
        if title and album.title==title then
            return album
        end
    end
    return nil
end

local function StartSync(context)
    -- TODO: better progressScope and make cancellable
    -- TODO: what if users cancels export operation?
    
    local progressScope = LrProgressScope {
        title = 'Syncing catalog with ' .. Service.name,
        functionContext = context,
    }
    
    if not prefs.lastUpdate[catalog.path] then
        prefs.lastUpdate[catalog.path] = 0
    end
    
    if not Service.login() then
        LrDialogs.message('Login failed', 'Failed to login to ' .. Service.name .. '.', 'critical')
        return
    end
    
    local syncablePhotos
    catalog:withReadAccessDo(function()
        syncablePhotos = catalog:findPhotosWithProperty(_G.ToolkitIdentifier, 'album_id')
    end)
    
    -- check deleted albums (on server), update local album names, list outdated photos
    local outdatedPhotos = {}
    for i,photo in ipairs(syncablePhotos) do
        local albumID, ID, localAlbumName, lastEditTime, forcedSyncing
        catalog:withReadAccessDo(function()
            albumID = photo:getPropertyForPlugin(_PLUGIN, 'album_id')
            ID = photo:getPropertyForPlugin(_PLUGIN, 'id')
            localAlbumName = photo:getPropertyForPlugin(_PLUGIN, 'album')
            lastEditTime = photo:getRawMetadata 'lastEditTime'
            forcedSyncing = photo:getPropertyForPlugin(_PLUGIN, 'needs_syncing')
        end)
        -- does photo need forcedSyncing?
        if forcedSyncing and forcedSyncing~='' then
            catalog:withPrivateWriteAccessDo(function()
                photo:setPropertyForPlugin(_PLUGIN, 'needs_syncing', nil)
            end)
            lastEditTime = LrDate.currentTime()
        end
        local remoteAlbumName = Service.albumName(albumID)
        -- album removed on server, disable photo syncing
        if not remoteAlbumName then
            catalog:withPrivateWriteAccessDo(function()
                photo:setPropertyForPlugin(_PLUGIN, 'album_id', nil)
                photo:setPropertyForPlugin(_PLUGIN, 'album', nil)
                photo:setPropertyForPlugin(_PLUGIN, 'id', nil)
                photo:setPropertyForPlugin(_PLUGIN, 'needs_syncing', nil)
            end)
        -- album exists. Does the photo still exists?
        elseif ID and ID~='' and not Service.findPhoto(ID) then
            -- doesnt exist, new upload
            catalog:withPrivateWriteAccessDo(function()
                photo:setPropertyForPlugin(_PLUGIN, 'id', nil)
            end)
            lastEditTime = LrDate.currentTime()
        end
        -- update local name if it's changed on server
        if remoteAlbumName and localAlbumName~=remoteAlbumName then
            catalog:withPrivateWriteAccessDo(function()
                photo:setPropertyForPlugin(_PLUGIN, 'album', remoteAlbumName)
            end)
        end
        -- check if photo is outdated
        if remoteAlbumName and lastEditTime > prefs.lastUpdate[catalog.path] then
            table.insert(outdatedPhotos, photo)
        end
    end
    logger:debug('Outdated Photos: ' .. #outdatedPhotos)
    
    -- Export outdated photos
    if #outdatedPhotos == 0 then
        -- no outdated photo
        return
    end
    local aPhotoFailedUpload = false
    local exportSettings = prefs.exportSettings
    exportSettings['LR_export_destinationPathSuffix'] = LrDate.timeToUserFormat(LrDate.currentTime(), '%Y%m%d%H%M%S')
    local exportSession = LrExportSession { 
        photosToExport=outdatedPhotos,
        exportSettings=exportSettings,
        }
    exportSession:doExportOnNewTask()
    for i, rendition in exportSession:renditions{ stopIfCanceled = true } do
        local photo = rendition.photo
		local success, pathOrMessage = rendition:waitForRender()
		if success then
		    logger:debug('Rendition COMPLETE, photo path=' .. pathOrMessage)
		    local photoData
			
			photo.catalog:withCatalogDo( function()
			    photoData = {
    				title = photo:getFormattedMetadata 'title',
    				caption = photo:getFormattedMetadata 'caption',
    				keywords = photo:getFormattedMetadata 'keywordTags',
    				copyright = photo:getFormattedMetadata 'copyright',
    				photoID = photo:getPropertyForPlugin(_PLUGIN, 'id'),
    				albumID = photo:getPropertyForPlugin(_PLUGIN, 'album_id'),
    				modifiedTime = photo:getRawMetadata 'lastEditTime',
    				originalFileName = photo:getFormattedMetadata 'fileName',
				}
			end )
			
			photoData['photoPath'] = pathOrMessage
		    local newID
			if photoData.photoID and photoData.photoID~='' then
			    -- record newID for services that dont support replacing photo
			    logger:debug('update existing PHOTO')
			    newID = Service.updatePhoto(photoData)
		    else
		        logger:debug('upload NEW PHOTO')
    		    newID = Service.uploadPhoto(photoData)
		    end
		    
		    -- Update photo ID only if it's changed
		    if not newID then
		        aPhotoFailedUpload = true
	        elseif newID ~= photoData.photoID then
    		    catalog:withWriteAccessDo('Update online photo ID and update time', function()
                    photo:setPropertyForPlugin(_PLUGIN, 'id', newID)
                end)
            end
	    end
    end
    if aPhotoFailedUpload then
        LrDialogs.message('Error', 'At least a photo failed upload.')
    else
        prefs.lastUpdate[catalog.path] = LrDate.currentTime()
        prefs.lastUpdate = prefs.lastUpdate
    end
end

function GallerySyncMain(context)
    LrDialogs.attachErrorDialogToFunctionContext(context)
    Service = getService()
    StartSync(context)
end

LrFunctionContext.postAsyncTaskWithContext('GallerySyncMain', GallerySyncMain)
