return function (config, source)
	if config.Voice_Config or config.Options then
		warn(`-----------------------------------------------`)
		warn(`CORTEX VOICE CONFIG: Old config detected!`)
		if config.Voice_Config then
			warn(`Please rename 'Voice_Config' to 'Floor_Announcements'`)
		end
		if config.Options then
			warn(`Please rename 'Options' to 'Settings'`)
		end
		warn(`Or replace the whole file with the updated version`)
		warn(`Elevator location: {source:GetFullName()}`)
		warn(`-----------------------------------------------`)
	end
	return {
		['SoundId'] = config.SoundId and config.SoundId or config.Voice_ID and config.Voice_ID or 0,
		['Volume'] = config.Volume and config.Volume or 1,
		['Pitch'] = config.Pitch and config.Pitch or 1,

		['Voice_Clips'] = config.Voice_Clips and config.Voice_Clips or {},
		['Floor_Announcements'] = config.Floor_Announcements and config.Floor_Announcements or config.Voice_Config and config.Voice_Config or {},

		['Settings'] = {
			['Floor_Announcements'] = {
				['Announce_Floor_On_Arrival'] = config.Settings and config.Settings.Floor_Announcements and config.Settings.Floor_Announcements.Announce_Floor_On_Arrival or false, --Announces the floor the elevators arriving on
				['Announce_Floor_On_Stop'] = config.Settings and config.Settings.Floor_Announcements and config.Settings.Floor_Announcements.Announce_Floor_On_Stop or false, --Announces the floor the elevators on when the car comes to a full stop
			},

			['Directional_Announcements'] = {
				['Announce_After_Floor_Announcement'] = config.Settings and config.Settings.Directional_Announcements and config.Settings.Directional_Announcements.Announce_After_Floor_Announcement or false, --Announces the direction after the floor announcement
				['Announce_After_Door_Open'] = config.Settings and config.Settings.Directional_Announcements and config.Settings.Directional_Announcements.Announce_After_Door_Open or false, --Announces the direction after the doors have fully opened
				['Up_Announcement'] = {
					['Enabled'] = config.Settings and config.Settings.Directional_Announcements and config.Settings.Directional_Announcements.Up_Announcement and config.Settings.Directional_Announcements.Up_Announcement.Enabled or false,
					['Sequence'] = config.Settings and config.Settings.Directional_Announcements and config.Settings.Directional_Announcements.Up_Announcement and config.Settings.Directional_Announcements.Up_Announcement.Sequence or {},
				},
				['Down_Announcement'] = {
					['Enabled'] = config.Settings and config.Settings.Directional_Announcements and config.Settings.Directional_Announcements.Down_Announcement and config.Settings.Directional_Announcements.Down_Announcement.Enabled or false,
					['Sequence'] = config.Settings and config.Settings.Directional_Announcements and config.Settings.Directional_Announcements.Down_Announcement and config.Settings.Directional_Announcements.Down_Announcement.Sequence or {},
				},
			},

			['Door_Announcements'] = {
				['Open_Announcement'] = {
					['Enabled'] = config.Settings and config.Settings.Door_Announcements and config.Settings.Door_Announcements.Open_Announcement and config.Settings.Door_Announcements.Open_Announcement.Enabled or false,
					['Sequence'] = config.Settings and config.Settings.Door_Announcements and config.Settings.Door_Announcements.Open_Announcement and config.Settings.Door_Announcements.Open_Announcement.Sequence or {},
				},
				['Close_Announcement'] = {
					['Enabled'] = config.Settings and config.Settings.Door_Announcements and config.Settings.Door_Announcements.Close_Announcement and config.Settings.Door_Announcements.Close_Announcement.Enabled or false,
					['Sequence'] = config.Settings and config.Settings.Door_Announcements and config.Settings.Door_Announcements.Close_Announcement and config.Settings.Door_Announcements.Close_Announcement.Sequence or {},
				},
				['Nudge_Announcement'] = {
					['Enabled'] = config.Settings and config.Settings.Door_Announcements and config.Settings.Door_Announcements.Nudge_Announcement and config.Settings.Door_Announcements.Nudge_Announcement.Enabled or false,
					['Sequence'] = config.Settings and config.Settings.Door_Announcements and config.Settings.Door_Announcements.Nudge_Announcement and config.Settings.Door_Announcements.Nudge_Announcement.Sequence or {},
				},
			},

			['Other_Announcements'] = {
				['Independent_Service_Announcement'] = {
					['Enabled'] = config.Settings and config.Settings.Other_Announcements and config.Settings.Other_Announcements.Independent_Service_Announcement and config.Settings.Other_Announcements.Independent_Service_Announcement.Enabled or false,
					['Sequence'] = config.Settings and config.Settings.Other_Announcements and config.Settings.Other_Announcements.Independent_Service_Announcement and config.Settings.Other_Announcements.Independent_Service_Announcement.Sequence or {},
				},
				['Fire_Recall_Announcement'] = {
					['Enabled'] = config.Settings and config.Settings.Other_Announcements and config.Settings.Other_Announcements.Fire_Recall_Announcement and config.Settings.Other_Announcements.Fire_Recall_Announcement.Enabled or false,
					['Sequence'] = config.Settings and config.Settings.Other_Announcements and config.Settings.Other_Announcements.Fire_Recall_Announcement and config.Settings.Other_Announcements.Fire_Recall_Announcement.Sequence or {},
				},
				['Safety_Brake_Announcement'] = {
					['Enabled'] = config.Settings and config.Settings.Other_Announcements and config.Settings.Other_Announcements.Safety_Brake_Announcement and config.Settings.Other_Announcements.Safety_Brake_Announcement.Enabled or false,
					['Sequence'] = config.Settings and config.Settings.Other_Announcements and config.Settings.Other_Announcements.Safety_Brake_Announcement and config.Settings.Other_Announcements.Safety_Brake_Announcement.Sequence or {},
				},
				['Inspection_Service_Announcement'] = {
					['Enabled'] = config.Settings and config.Settings.Other_Announcements and config.Settings.Other_Announcements.Inspection_Service_Announcement and config.Settings.Other_Announcements.Inspection_Service_Announcement.Enabled or false,
					['Sequence'] = config.Settings and config.Settings.Other_Announcements and config.Settings.Other_Announcements.Inspection_Service_Announcement and config.Settings.Other_Announcements.Inspection_Service_Announcement.Sequence or {},
				},
				['Out_Of_Service_Announcement'] = {
					['Enabled'] = config.Settings and config.Settings.Other_Announcements and config.Settings.Other_Announcements.Out_Of_Service_Announcement and config.Settings.Other_Announcements.Out_Of_Service_Announcement.Enabled or false,
					['Sequence'] = config.Settings and config.Settings.Other_Announcements and config.Settings.Other_Announcements.Out_Of_Service_Announcement and config.Settings.Other_Announcements.Out_Of_Service_Announcement.Sequence or {},
				}
			}
		},
	}
end