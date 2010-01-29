local Info = require('Info')
function versionString()
    return Info.VERSION.major .. '.' .. Info.VERSION.minor .. '.' ..
        Info.VERSION.revision .. '.' .. Info.VERSION.build
end

_G.userAgent = Info.LrPluginName .. ' v' .. versionString() .. ' (' .. Info.LrPluginInfoUrl .. ')'
_G.headers = {
    {field='User-Agent', value=_G.userAgent},
    }

_G.ToolkitIdentifier = Info.LrToolkitIdentifier

local prefs = import 'LrPrefs'.prefsForPlugin()
prefs.exportSettings = {
	LR_collisionHandling = "ask",
	LR_exportServiceProvider = "com.adobe.ag.export.file",
	LR_export_addCopyrightWatermark = false,
	LR_export_colorSpace = "sRGB",
	LR_export_destinationPathPrefix = '/Users/mtpi/Pictures/GallerySync/',
	LR_export_destinationType = "specificFolder",
	LR_export_useSubfolder = true,
	LR_format = "JPEG",
	LR_initialSequenceNumber = 1,
	LR_jpeg_quality = 0.6,
	LR_metadata_keywordOptions = "flat",
	LR_minimizeEmbeddedMetadata = false,
	LR_outputSharpeningLevel = 2,
	LR_outputSharpeningMedia = "screen",
	LR_outputSharpeningOn = false,
	LR_reimportExportedPhoto = false,
	LR_reimport_stackWithOriginal = false,
	LR_size_doConstrain = false,
	LR_size_resolution = 150,
	LR_size_resolutionUnits = "inch",
	LR_tokenCustomString = "",
	LR_tokens = "{{image_name}}",
}

if not prefs.lastUpdate then
    prefs.lastUpdate = {}
end
