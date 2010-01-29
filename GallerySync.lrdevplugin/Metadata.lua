return {
    metadataFieldsForPhotos = {
        {
            id = 'id',
            title = 'Online ID',
            dataType = 'string',
            searchable = true,
            version = 2,
        },
        {
            id = 'album_id',
            title = 'Online Album ID',
            dataType = 'string',
            searchable = true,
            version = 2,
        },
        {
            id = 'album',
            title = 'Online Album',
            dataType = 'string',
            searchable = true,
            browsable = true,
            version = 3,
        },
        {
            id = 'needs_syncing',
            title = 'Needs forced syncing?',
            dataType = 'string',
            version = 1,
        },
    },
    schemaVersion = 6,
    updateFromEarlierSchemaVersion = function( catalog, previousSchemaVersion )
        catalog:assertHasPrivateWriteAccess( "Metadata.updateFromEarlierSchemaVersion" )
        for i, photo in ipairs(catalog:findPhotosWithProperty(_G.ToolkitIdentifier,'album')) do
            photo:setPropertyForPlugin(_PLUGIN, 'album', photo:getPropertyForPlugin(_G.ToolkitIdentifier, 'album'))
        end
        for i, photo in ipairs(catalog:findPhotosWithProperty(_G.ToolkitIdentifier,'album_id')) do
            photo:setPropertyForPlugin(_PLUGIN, 'album_id', photo:getPropertyForPlugin(_G.ToolkitIdentifier, 'album_id'))
        end
        for i, photo in ipairs(catalog:findPhotosWithProperty(_G.ToolkitIdentifier,'id')) do
            photo:setPropertyForPlugin(_PLUGIN, 'id', photo:getPropertyForPlugin(_G.ToolkitIdentifier, 'id'))
        end
        for i, photo in ipairs(catalog:findPhotosWithProperty(_G.ToolkitIdentifier,'needs_syncing')) do
            photo:setPropertyForPlugin(_PLUGIN, 'id', photo:getPropertyForPlugin(_G.ToolkitIdentifier, 'needs_syncing'))
        end
    end,
}
