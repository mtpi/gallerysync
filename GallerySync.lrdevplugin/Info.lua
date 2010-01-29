return {
    
	LrSdkVersion = 2.0,
	LrSdkMinimumVersion = 2.0, -- minimum SDK version required by this plug-in
    
	LrToolkitIdentifier = 'opensourcelrplugins.gallerysync',
	LrPluginName = 'Online gallery sync',
	LrPluginInfoUrl = 'http://code.google.com/p/gallerysync',
	
	LrInitPlugin = 'Init.lua',
	LrMetadataProvider = 'Metadata.lua',
	LrPluginInfoProvider = 'InfoProvider.lua',
	
	LrLibraryMenuItems = {
	    {
    		title = 'Online Gallery Sync',
    		file = 'Sync.lua',	        
	    },
	    {
    		title = '(Re)Assign to online album',
    		file = 'AssignAlbum.lua',
    		enabledWhen = 'photosAvailable',
	    },
	    {
    		title = 'Stop syncing to online album',
    		file = 'DisableSync.lua',
    		enabledWhen = 'photosAvailable',
	    },
	},
	
	--[[
	LrExportMenuItems = {
		{
			title = LOC "$$$/Flickr/EnterAPIKey=Enter Flickr API Key...",
			file = 'EnterApiKey.lua',
		},
		{
			title = LOC "$$$/Flickr/ExportUsingDefaults=Export to Flickr Using Defaults",
			file = 'ExportToFlickr.lua',
			enabledWhen = 'photosAvailable',
		},
	},
	
	LrExportServiceProvider = {
		title = LOC "$$$/Flickr/Flickr=Flickr",
		file = 'FlickrExportServiceProvider.lua',
		builtInPresetsDir = "presets",
	},
    --]]
	VERSION = { major=0, minor=0, revision=0, build=1, },
    
}
