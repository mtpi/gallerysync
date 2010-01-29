local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'
local LrDate = import 'LrDate'
local bind = LrView.bind
local share = LrView.share
local prefs = import 'LrPrefs'.prefsForPlugin()
local catalog = import 'LrApplication'.activeCatalog()

local PluginManager = {}

local function updateSyncStatus(p)
    p.syncStatus = 'Last update for this catalog: ' .. LrDate.timeToUserFormat(prefs.lastUpdate[catalog.path], '%d %b %Y %H.%M.%S')
end

function PluginManager.saveSettings(p)
    prefs.serviceProvider = p.serviceProvider
    prefs.serviceEMail = p.serviceEMail
    prefs.servicePassword = p.servicePassword
    prefs.exportFormat = p.exportFormat
end

function PluginManager.endDialog(p, why)
    PluginManager.saveSettings(p)
end

function PluginManager.startDialog(p)
    p.serviceProvider = prefs.serviceProvider
    p.serviceEMail = prefs.serviceEMail
    p.servicePassword = prefs.servicePassword
    p.exportFormat = prefs.exportFormat
    updateSyncStatus(p)
end

function PluginManager.sectionsForTopOfDialog(f, p)
	return {
			{
				title = 'Account information',
				spacing = f:control_spacing(),
				bind_to_object = p,
				
				f:row {
				    spacing = f:label_spacing(),
					f:static_text {
						title = 'Service provider:',
				        alignment = 'right',
						fill_horizontal = 1,
					},
					f:popup_menu {
                        items = {
                            --{ title='SmugMug', value='SmugMug' },
                            { title='Zenfolio', value='Zenfolio' },
                        },
                        value = bind 'serviceProvider',
                        size = 'small',
                        fill_horizontal = 1,
                    },
				},
				
				f:row {
				    spacing = f:label_spacing(),
				    f:static_text {
				        title = 'eMail/Username:',
				        alignment = 'right',
				        fill_horizontal = 1,
				    },
			        f:edit_field {
			            value = bind 'serviceEMail',
			            fill_horizontal = 1,
			        },
				},
				
				f:row {
				    spacing = f:label_spacing(),
				    f:static_text {
				        title = 'Password:',
				        alignment = 'right',
				        fill_horizontal = 1,
				    },
			        f:password_field {
			            value = bind 'servicePassword',
			            fill_horizontal = 1,
			        },
				},
				
				f:row {
					f:static_text {
						title = bind 'syncStatus',
						fill_horizontal = 1,
					},
					f:push_button {
						title = 'Reset Last Sync',
						width = 150,
						height = 15,
						enabled = true,
						action = function()
							prefs.lastUpdate[catalog.path] = 0
							updateSyncStatus(p)
						end,
					},
				},
			},
			-- TODO: implement export settings
			{
			    title = 'Export Settings',
			    bind_to_object = p,
			    spacing = f:control_spacing(),
			    f:row{
			        f:static_text {
			            title = 'Format:',
			            fill_horizontal = 1,
			        },
					f:popup_menu {
                        items = {
                            { title='JPEG', value='jpeg' },
                            { title='TIFF', value='tiff' },
                        },
                        value = bind 'exportFormat',
                        size = 'small',
                        fill_horizontal = 1,
                    },
			    }
			}
	
		}
end

return PluginManager
