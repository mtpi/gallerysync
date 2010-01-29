local LrPrefs = import 'LrPrefs'
local LrDialogs = import 'LrDialogs'
local prefs = import 'LrPrefs'.prefsForPlugin()
local logger = import 'LrLogger'('GallerySync.Utils')
logger:enable('print')

-- get Service object
function getService()
    if (not prefs.serviceProvider) or (not prefs.exportSettings) then
        LrDialogs.message('Gallery Sync Error', 'You must set plugin settings before launching sync.', 'critical')
        return
    end
    logger:info('Selected service provider ' .. prefs.serviceProvider)
    return require(prefs.serviceProvider .. 'Service')
end

-- get an album given id or title from an array of albums
function getAlbum(albums, id, title)
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
