local LrPrefs = import 'LrPrefs'
local LrDialogs = import 'LrDialogs'
local prefs = import 'LrPrefs'.prefsForPlugin()
local logger = import 'LrLogger'('GallerySync.Utils')
logger:enable('print')

function getService()
    if (not prefs.serviceProvider) or (not prefs.exportSettings) then
        LrDialogs.message('Gallery Sync Error', 'You must set plugin settings before launching sync.', 'critical')
        return
    end
    logger:info('Selected service provider ' .. prefs.serviceProvider)
    return require(prefs.serviceProvider .. 'Service')
end

