local LrDate = import 'LrDate'
local prefs = import 'LrPrefs'.prefsForPlugin()
local logger = import 'LrLogger'('GallerySync.ZenfolioService')
logger:enable('print')

require 'APIUtils'
require 'TableUtils'

local Service = { name = 'Zenfolio' }

local APIURL = 'https://www.zenfolio.com/api/1.2/zfapi.asmx'

local function authTokenHeader()
    return {field='X-Zenfolio-Token', value=Service.token or ''}
end

local function getLoginName()
    local res, err = request(APIURL, {}, 'LoadPrivateProfile', {authTokenHeader()})
    if err then
        logger:error('Unable to retrieve LoginName: ' .. table.tostring(err))
        return nil
    else
        return tostring(res.LoginName)
    end
end

local function getRootPhotoSetId()
    local res, err = request(APIURL, {}, 'LoadPublicProfile', {authTokenHeader()}, getLoginName())
    if err then
        logger:error('Unable to retrieve RootGroup.Id: ' .. table.tostring(err))
        return nil
    else
        return tostring(res.RootGroup.Id)
    end
end

local function getUploadURL(id)
    local res, err = request(APIURL, {}, 'LoadPhotoSet', {authTokenHeader()}, id)
    if err then
        logger:error('Unable to retrieve UploadURL: ' .. table.tostring(err))
        return nil
    else
        return tostring(res.UploadUrl)
    end
end

local function getPhotoData(id)
    local res, err = request(APIURL, {}, 'LoadPhoto', {}, id)
    if err then
        logger:error('LoadPhoto ERROR ' .. table.tostring(err))
        return nil
    else
        return res
    end
end

local function getAlbumData(id)
    local res, err = request(APIURL, {}, 'LoadPhotoSet', {}, id)
    if err then
        logger:error('LoadPhotoSet ERROR ' .. table.tostring(err))
        return nil
    else
        return res
    end
end

function Service.login()
    local res, err = request(APIURL, {}, 'AuthenticatePlain', {}, prefs.serviceEMail, prefs.servicePassword)
    if err then
        logger:error('AuthenticatePlain ERROR ' .. table.tostring(err))
        return false
    else
        Service.token = res
        return true
    end
end

function Service.validPhotoID(id)
    local zfphotoData = getPhotoData(id)
    if zfphotoData and zfphotoData.Owner == getLoginName() then
        return true
    end
    return false
end

function Service.albumName(id)
    local zfalbumData = getAlbumData(id)
    if zfalbumData then
        return zfalbumData.Title
    else
        return nil
    end
end

function Service.photoAlbumName(id)
    local zfphotoData = getPhotoData(id)
    if zfphotoData then
        return getAlbumData(zfphotoData.Gallery).Title
    else
        return nil
    end
end

function Service.findAlbums()
    local res, err = request(APIURL, {}, 'LoadGroupHierarchy', {authTokenHeader()}, getLoginName())
    if err then
        logger:error('LoadGroupHierarchy ERROR ' .. table.tostring(err))
        return nil
    else
        local albums = {}
        for i,element in ipairs(res.Elements) do
            if element['$type']=='PhotoSet' and element.Type=='Gallery' then
                table.insert(albums, {title=element.Title, id=tostring(element.Id)})
            end
        end
        return albums
    end
end

function Service.updateAlbumName(id, title)
    local res, err = request(APIURL, {}, 'UpdatePhotoSet', {authTokenHeader()}, id, {Title=title})
    if err then
        logger:error('UpdatePhotoSet ERROR ' .. table.tostring(err))
        return false
    else
        return true
    end
end

function Service.createAlbum(title)
    local res, err = request(APIURL, {}, 'CreatePhotoSet', {authTokenHeader()}, getRootPhotoSetId(), 'Gallery', {Title=title})
    if err then
        logger:error('CreatePhotoSet ERROR ' .. table.tostring(err))
        return nil
    else
        return tostring(res.Id)
    end
end

--[[---------------------------------------
    photoData
    	title
    	caption
    	keywords
    	copyright
    	photoID
    	albumID
    	modifiedTime
    	originalFileName
-----------------------------------------]]
function Service.uploadPhoto(photoData)
    local uploadURL = getUploadURL(photoData.albumID)

    local args = {}
    if photoData.photoID and photoData.photoID~='' then
        args['replace'] = photoData.photoID
    end

    local mimeChunks = {
        { name = photoData.title, fileName = photoData.originalFileName,
          filePath = photoData.photoPath, contentType = 'application/octet-stream' },
    }

    local newID = postMultipart(uploadURL, args, mimeChunks, {authTokenHeader()})
    
    if not newID or newID=='' then
        return nil
    end
    
    -- Update online photo metadata
    local photoUpdater = {
        Caption = photoData.caption,
        Keywords = string.split(photoData.keywords, ','),
        Copyright = photoData.copyright,
    }

    local res, err = request(APIURL, {}, 'UpdatePhoto', {authTokenHeader()}, newID, photoUpdater)
    if err then
        logger:error('uploadPhoto->UpdatePhoto id='.. tostring(newID) ..' ERROR ' .. table.tostring(err))
    end
    return newID    
end

function Service.updatePhoto(photoData)
    return Service.uploadPhoto(photoData)
end

-------------------
return Service
-------------------
