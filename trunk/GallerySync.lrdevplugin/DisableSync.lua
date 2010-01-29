local LrFunctionContext = import 'LrFunctionContext'
local LrProgressScope = import 'LrProgressScope'
local catalog = import 'LrApplication'.activeCatalog()

function DisableGallerySync(context)
    local progressScope = LrProgressScope {
        title = 'Disabling syncing for selected photos',
        functionContext = context,
    }
    catalog:withWriteAccessDo('Stop syncing to online album', function()
        for i,photo in ipairs(catalog.targetPhotos) do
            photo:setPropertyForPlugin(_PLUGIN, 'album_id', nil)
            photo:setPropertyForPlugin(_PLUGIN, 'album', nil)
            photo:setPropertyForPlugin(_PLUGIN, 'id', nil)
            photo:setPropertyForPlugin(_PLUGIN, 'needs_syncing', nil)
        end
    end)
end

LrFunctionContext.postAsyncTaskWithContext('DisableGallerySync', DisableGallerySync)
