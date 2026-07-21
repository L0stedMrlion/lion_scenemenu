return {
    -- _______  _______  _______  _        _______  _______  _______  _
    --(  ____ \(  ____ \(  ____ \( (    /|(  ____ \(       )(  ____ \( (    /||\     /|
    --| (    \/| (    \/| (    \/|  \  ( || (    \/| () () || (    \/|  \  ( || )   ( |
    --| (_____ | |      | (__    |   \ | || (__    | || || || (__    |   \ | || |   | |
    --(_____  )| |      |  __)   | (\ \) ||  __)   | |(_)| ||  __)   | (\ \) || |   | |
    --      ) || |      | (      | | \   || (      | |   | || (      | | \   || |   | |
    --/\____) || (____/\| (____/\| )  \  || (____/\| )   ( || (____/\| )  \  || (___) |
    --\_______)(_______/(_______/|/    )_)(_______/|/     \|(_______/|/    )_)(_______)
    versioncheck = true,
    scenemenu = {
        -- Command & Keybind Settings
        command = "scenemenu", -- Command name used in-game
        enableKeybind = false, -- Enables / disables the keybind
        defaultKeybind = "F6", -- Only works if enableKeybind = true

        -- Access to create zones
        allowedJobs = {
            'police',
            'sheriff',
            'sahp',
            'firedept',
            'ambulance'
        },

        -- Minimum Job Grades required for Supervisor Menu (Manage/Delete ANY zone !FROM ANY JOB!)
        supervisorGrades = {
            ['police'] = 4,
            ['sheriff'] = 4,
            ['sahp'] = 5,
            ['firedept'] = 4,
            ['ambulance'] = 4
        },

        -- Speed Zones
        zones = {
            minRadius = 10,           -- Minimum radius in meters (in metres)
            maxRadius = 250,          -- Maximum radius that can be set (in metres)
            defaultRadius = 100,      -- Pre-filled radius in input dialog
            preventZoneinZone = true, -- Block creating a zone inside an existing zone
            maxZonesPerPlayer = 5     -- Max active zones per player (0 = unlimited)
        },

        -- Available Speed Options in the Dropdown Menu (in MPH)
        speedOptions = {
            { value = '0',  label = 'Stop Traffic (0 mp/h)' },
            { value = '5',  label = '5 mp/h' },
            { value = '10', label = '10 mp/h' },
            { value = '15', label = '15 mp/h' },
            { value = '20', label = '20 mp/h' },
            { value = '25', label = '25 mp/h' },
            { value = '30', label = '30 mp/h' },
            { value = '40', label = '40 mp/h' },
            { value = '50', label = '50 mp/h' },
            { value = '60', label = '60 mp/h' },
            { value = '70', label = '70 mp/h' }
        },
        defaultSpeed = '0', -- Default speed set in the menu

        -- Map Blip Customization
        blips = {
            centerSprite = 564, -- Blip icon ID (564 = Traffic Radar) // Link to all blips https://docs.fivem.net/docs/game-references/blips/
            centerScale = 0.75, -- Icon size on minimap
            radiusAlpha = 80,   -- Transparency of radius circle (0 to 255)
            shortRange = true,  -- Only visible on minimap when nearby

            -- Blip colors based on set speed limit // Link to all colors https://docs.fivem.net/docs/game-references/blips/
            colors = {
                stop = 1,      -- Red (0 mp/h)
                verySlow = 17, -- Orange (up to 20 mp/h)
                moderate = 5,  -- Yellow (up to 40 mp/h)
                fast = 3       -- Blue (up to 60 mp/h)
            }
        },
        locales = {
            menuTitle = 'Traffic Control Menu',
            menuSubtitle = 'Select an option that you want to perform',
            noPermission = 'You do not have permission to use the scene menu',
            preventZoneinZoneError = 'You cannot create a speed zone while inside an existing one!',
            maxZonesReached = 'You have reached the maximum allowed active zones!',
            zoneCreated = 'Speed zone created (%d m radius, %d mp/h)',
            zoneRemoved = 'Zone #%d (%d mp/h) has been removed',
            clearedOwnZones = 'All your speed zones have been cleared',
            noZonesToClear = 'There are no active speed zones to clear'
        },

        -- Notifications
        Notify = function(title, description, type, icon, iconColor)
            lib.notify({
                title = title,
                description = description,
                type = type,
                icon = icon,
                iconColor = iconColor
            })
        end
    }
}
