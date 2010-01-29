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
    		title = 'GallerySync - Run Sync',
    		file = 'Sync.lua',	        
	    },
	    {
    		title = 'GallerySync - Assign online album',
    		file = 'AssignAlbum.lua',
    		enabledWhen = 'photosAvailable',
	    },
	    {
    		title = 'GallerySync - Remove photo online',
    		file = 'RemovePhoto.lua',
    		enabledWhen = 'photosAvailable',
	    },
	},

	VERSION = { major=0, minor=0, revision=0, build=1, },
    
}
