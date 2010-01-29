local LrFunctionContext = import 'LrFunctionContext'
local LrDialogs = import 'LrDialogs'
local LrErrors = import 'LrErrors'
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

-- FIXME: why searching for photos with album_id set works with empty, instead of notEmpty??
-- reported as bug to adobe
local HAS_ALBUMID = {
    criteria = 'sdktext:'.._G.ToolkitIdentifier..'.album_id',
    operation = 'empty'
}
local NOT_DISABLED = {
    criteria = 'sdktext:'.._G.ToolkitIdentifier..'.sync_options',
    operation = 'noneOf',
    value = 'disabled invalid_album invalid_id error_rendering error_uploading'
}

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
    
    -- retrieve remote albums
    local remoteAlbums = Service.findAlbums()
    
    -- make a space separated string with valid album IDs
    local validAlbumIDs = ''
    for i,album in ipairs(remoteAlbums) do
        validAlbumIDs = validAlbumIDs .. album.id .. ' '
    end
    validAlbumIDs = string.gsub(validAlbumIDs, ' $', '')
    logger:debug('validAlbumIDs='..validAlbumIDs)
    
    -- mark photos with invalid album_id with invalid sync_option
    local invalidAlbumPhotos = catalog:findPhotos {
        searchDesc = {
            combine = 'intersect',
            HAS_ALBUMID,
            NOT_DISABLED,
            { criteria = 'sdktext:'.._G.ToolkitIdentifier..'.album_id', operation = 'noneOf', value = validAlbumIDs },
        }
    }
    logger:debug('invalidAlbumPhotos: ' .. #invalidAlbumPhotos)
    catalog:withPrivateWriteAccessDo(function()
        for i,photo in ipairs(invalidAlbumPhotos) do
            photo:setPropertyForPlugin(_PLUGIN, 'sync_options', 'invalid_album')
        end
    end)
    
    local syncablePhotos = catalog:findPhotos {
        searchDesc = {
            combine = 'intersect',
            HAS_ALBUMID,
            NOT_DISABLED,
        }
    }
    logger:debug('syncablePhotos: ' .. #syncablePhotos)
    local outdatedPhotos = {}
    for i,photo in ipairs(syncablePhotos) do
        local photoData
        catalog:withReadAccessDo(function()
            photoData = {
				photoID = photo:getPropertyForPlugin(_PLUGIN, 'id'),
				albumID = photo:getPropertyForPlugin(_PLUGIN, 'album_id'),
				albumName = photo:getPropertyForPlugin(_PLUGIN, 'album'),
				modifiedTime = photo:getRawMetadata 'lastEditTime',
				syncOptions = photo:getPropertyForPlugin(_PLUGIN, 'sync_options'),
            }
        end)
        -- update album names
        local photoAlbumName = getAlbum(remoteAlbums, photoData.albumID, nil).title
        if photoAlbumName ~= photoData.albumName then
            logger:debug('UPDATE photo album name')
            catalog:withPrivateWriteAccessDo(function()
                photo:setPropertyForPlugin(_PLUGIN, 'album', photoAlbumName)
            end)
        end
        
        if photoData.photoID and not Service.validPhotoID(photoData.photoID) then
            -- invalid present photo id
            catalog:withPrivateWriteAccessDo(function()
                photo:setPropertyForPlugin(_PLUGIN, 'sync_options', 'invalid_id')
            end)
        else
            -- photo id not recorded or valid photo id
            
            -- check if needs resync
            if photoData.syncOptions == 'resync' then
                table.insert(outdatedPhotos, photo)
                catalog:withPrivateWriteAccessDo(function()
                    photo:setPropertyForPlugin(_PLUGIN, 'sync_options', nil)
                end)
            end
            -- check if outdated
            if photoData.modifiedTime > prefs.lastUpdate[catalog.path] then
                table.insert(outdatedPhotos, photo)
            end
        end
    end
    
    logger:debug('outdatedPhotos: ' .. #outdatedPhotos)
    
    -- Export outdated photos
    if #outdatedPhotos == 0 then
        -- no outdated photo
        return
    end
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
			
			catalog:withReadAccessDo( function()
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
		    
		    if not newID then
		        -- error uploading
		        catalog:withPrivateWriteAccessDo(function()
                    photo:setPropertyForPlugin(_PLUGIN, 'sync_options', 'error_uploading')
                end)
	        elseif newID ~= photoData.photoID then
	            -- Update photo ID only if it's changed
    		    catalog:withPrivateWriteAccessDo(function()
                    photo:setPropertyForPlugin(_PLUGIN, 'id', newID)
                end)
            end
	    else    
	        -- error rendering photo
	        catalog:withPrivateWriteAccessDo(function()
                photo:setPropertyForPlugin(_PLUGIN, 'sync_options', 'error_rendering')
            end)
        end
    end
    prefs.lastUpdate[catalog.path] = LrDate.currentTime()
    prefs.lastUpdate = prefs.lastUpdate
end

function GallerySyncMain(context)
    LrDialogs.attachErrorDialogToFunctionContext(context)
    Service = getService()
    StartSync(context)
end

LrFunctionContext.postAsyncTaskWithContext('GallerySyncMain', GallerySyncMain)
