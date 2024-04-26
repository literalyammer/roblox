return {

	['SoundId'] = 8492151402;
	['Volume'] = 2;
	['Pitch'] = 1;

	['Voice_Clips'] = {
		
		--[[ Options
			['SoundId'] = Id - Optional
			['Start'] = number -- If not provided it will default to 0
			['End'] = number -- If not provided it will default to clip time length
			['Volume'] = number - Optional
			['Pitch'] = number - Optional
			
			Optional options fallback to the main values at the top of the script if not present
		]]

		--//Floors\\--
		['1st'] = {['Start']=36.709, ['End']=37.334};
		['2nd'] = {['Start']=37.505, ['End']=38.086};
		['3rd'] = {['Start']=38.364, ['End']=38.903};
		['4th'] = {['Start']=39.142, ['End']=39.771};
		['5th'] = {['Start']=39.892, ['End']=40.430};

		--//Labels\\--
		['Floor'] = {['Start']=12.788, ['End']=13.360};
		['Level'] = {['Start']=14.657, ['End']=15.129};
		['Level_Suffix'] = {['Start']=67.700, ['End']=68.209};

		['Lobby'] = {['Start']=66.186, ['End']=66.749};
		['Parking'] = {['Start']=168.366, ['End']=168.992};

		--//Door Announcements\\--
		['Doors_Opening'] = {['Start']=165.380, ['End']=166.381};
		['Doors_Closing'] = {['Start']=166.678, ['End']=167.763};
		['Please_Remove_Obstruction'] = {['Start']=162.309, ['End']=164.397};

		--//Directional Announcements\\--
		['Going_Up'] = {['Start']=159.886, ['End']=160.686};
		['Going_Down'] = {['Start']=160.903, ['End']=161.741};

		--//Other Destination Dispatch Messages\\--
		['Select_Destination'] = {['Start']=0.022, ['End']=1.672};
		['Take_Car'] = {['Start']=1.800, ['End']=2.652};
		['Please_Scan_Access_Card'] = {['Start']=2.986, ['End']=4.469};
		['Handicap_Message'] = {['Start']=5.259, ['End']=10.653};
		['Fire_Recall'] = {['Start']=11.302, ['End']=12.227};
		['Through'] = {['Start']=15.645, ['End']=16.340};
		['And'] = {['Start']=16.456, ['End']=16.968};
		['Going_To'] = {['Start']=13.545, ['End']=14.371};

		--//DESTINATION DISPATCH LETTERING\\--
		['A'] = {['Start']=18.888, ['End']=19.326};
		['B'] = {['Start']=19.524, ['End']=19.889};
		['C'] = {['Start']=20.050, ['End']=20.543};
		['D'] = {['Start']=20.860, ['End']=21.293};
		['E'] = {['Start']=21.585, ['End']=22.033};
		['F'] = {['Start']=22.253, ['End']=22.651};
		['G'] = {['Start']=22.928, ['End']=23.366};
		['H'] = {['Start']=23.391, ['End']=24.578};

		--//FLOOR NUMBERS\\--
		['1'] = {['Start']=111.744, ['End']=112.268};
		['2'] = {['Start']=112.517, ['End']=113.019};
		['3'] = {['Start']=113.325, ['End']=113.942};

	};

	['Floor_Announcements'] = { --To add a voice segment for a floor, add: {{'Segment', ['Delay'] = .1}}
		['1'] = {{'Lobby', ['Delay'] = 0}, {'Level', ['Delay'] = 0}, {'1', ['Delay'] = 0}};
		['2'] = {{'Lobby', ['Delay'] = 0}, {'Level', ['Delay'] = 0}, {'2', ['Delay'] = 0}};
		['3'] = {{'Lobby', ['Delay'] = 0}, {'Level', ['Delay'] = 0}, {'3', ['Delay'] = 0}};
	};
	['Settings'] = {

		['Floor_Announcements'] = {
			['Announce_Floor_On_Arrival'] = true; --Announces the floor the elevators arriving on
			['Announce_Floor_On_Stop'] = false; --Announces the floor the elevators on when the car comes to a full stop
		};
		['Directional_Announcements'] = {
			['Announce_After_Floor_Announcement'] = false; --Announces the direction after the floor announcement
			['Announce_After_Door_Open'] = true; --Announces the direction after the doors have fully opened
			['Up_Announcement'] = {['Enabled'] = true; ['Sequence'] = {{'Going_Up', ['Delay'] = 0}}};
			['Down_Announcement'] = {['Enabled'] = true; ['Sequence'] = {{'Going_Down', ['Delay'] = 0}}};
		};
		['Door_Announcements'] = {
			['Open_Announcement'] = {['Enabled'] = false; ['Sequence'] = {{'Doors_Opening', ['Delay'] = 0}}};
			['Close_Announcement'] = {['Enabled'] = false; ['Sequence'] = {{'Doors_Closing', ['Delay'] = 0}}};
			['Nudge_Announcement'] = {['Enabled'] = true; ['Sequence'] = {{'Please_Remove_Obstruction', ['Delay'] = 0}}};
		};
		['Other_Announcements'] = {
			['Independent_Service_Announcement'] = {['Enabled'] = true; ['Sequence'] = {{'Out_Of_Service', ['Delay'] = 0}}},
			['Fire_Recall_Announcement'] = {['Enabled'] = true; ['Sequence'] = {{'Out_Of_Service', ['Delay'] = 0}}},
			['Safety_Brake_Announcement'] = {['Enabled'] = true; ['Sequence'] = {{'Out_Of_Service', ['Delay'] = 0}}}
		};

	};

};