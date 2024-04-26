return function(config, coreScript)
	local DefaultConfig = {
		['Doors'] = {
			['Door_Open_Speed'] = config.Doors.Door_Open_Speed, -- Doors take 1.68 seconds to open fully.
			['Door_Close_Speed'] = config.Doors.Door_Close_Speed, -- Doors take 2.48 seconds to close fully.
			['Nudge_Speed'] = config.Doors.Nudge_Speed or config.Doors.Door_Close_Speed,

			['Door_Timer'] = if (typeof(config.Doors.Door_Timer) == 'number') then config.Doors.Door_Timer+4 else 4,
			['Call_Door_Timer'] = config.Doors.Call_Door_Timer or if (typeof(config.Doors.Door_Timer) == 'number') then config.Doors.Door_Timer+4 else 4,
			['Nudge_Timer'] = config.Doors.Nudge_Timer,

			['Use_Old_Door_Sensors'] = config.Doors.Use_Old_Door_Sensors,

			['Open_Easing_Style'] = config.Doors.Open_Easing_Style or 'In_Out_Quad',
			['Close_Easing_Style'] = config.Doors.Close_Easing_Style or 'In_Out_Sine',

			['Door_Sensors'] = config.Doors.Door_Sensors,

			['Door_Open_Delay_Pattern'] = config.Doors.Door_Open_Delay_Pattern, -- Example: ['Door_Open_Delay_Pattern'] = {'Outer', 'Inner'} - Outer doors open, then the inner doors
			['Door_Close_Delay_Pattern'] = config.Doors.Door_Close_Delay_Pattern, -- Example: ['Door_Close_Delay_Pattern'] = {'Inner', 'Outer'} - Inner doors close, then the outer doors

			['Door_Open_Pattern_Delay'] = config.Doors.Door_Open_Pattern_Delay,
			['Door_Close_Pattern_Delay'] = config.Doors.Door_Close_Pattern_Delay,

			['Door_Delay_Sequence_Config'] = {
				['Opening'] = {
					['Enable'] = if (config.Doors.Door_Delay_Sequence_Config and config.Doors.Door_Delay_Sequence_Config.Opening and typeof(config.Doors.Door_Delay_Sequence_Config.Opening.Enable) == 'boolean') then config.Doors.Door_Delay_Sequence_Config.Opening.Enable elseif (typeof(config.Doors.Door_Open_Delay_Pattern) == 'table') then config.Doors.Door_Open_Delay_Pattern ~= nil else false, --// Enable or disable the door delay sequence
					['Sequence_Order'] = if (config.Doors.Door_Delay_Sequence_Config and config.Doors.Door_Delay_Sequence_Config.Opening and typeof(config.Doors.Door_Delay_Sequence_Config.Opening.Sequence_Order) == 'table') then config.Doors.Door_Delay_Sequence_Config.Opening.Sequence_Order elseif (typeof(config.Doors.Door_Open_Delay_Pattern) == 'table') then config.Doors.Door_Open_Delay_Pattern else {'Outer', 'Inner'}, --// [Inner, Outer] - The order in which each door opens
					['Delay'] = if (config.Doors.Door_Delay_Sequence_Config and config.Doors.Door_Delay_Sequence_Config.Opening and typeof(config.Doors.Door_Delay_Sequence_Config.Opening.Delay) == 'number') then config.Doors.Door_Delay_Sequence_Config.Opening.Delay elseif (typeof(config.Doors.Door_Open_Pattern_Delay) == 'number') then config.Doors.Door_Open_Speed-config.Doors.Door_Open_Pattern_Delay else 1, --// Delay in seconds the door delay lasts
				},
				['Closing'] = {
					['Enable'] = if (config.Doors.Door_Delay_Sequence_Config and config.Doors.Door_Delay_Sequence_Config.Closing and typeof(config.Doors.Door_Delay_Sequence_Config.Closing.Enable) == 'boolean') then config.Doors.Door_Delay_Sequence_Config.Closing.Enable elseif (typeof(config.Doors.Door_Close_Delay_Pattern) == 'table') then config.Doors.Door_Close_Delay_Pattern ~= nil else false, --// Enable or disable the door delay sequence
					['Sequence_Order'] = if (config.Doors.Door_Delay_Sequence_Config and config.Doors.Door_Delay_Sequence_Config.Closing and typeof(config.Doors.Door_Delay_Sequence_Config.Closing.Sequence_Order) == 'table') then config.Doors.Door_Delay_Sequence_Config.Closing.Sequence_Order elseif (typeof(config.Doors.Door_Close_Delay_Pattern) == 'table') then config.Doors.Door_Close_Delay_Pattern else {'Outer', 'Inner'}, --// [Inner, Outer] - The order in which each door opens
					['Delay'] = if (config.Doors.Door_Delay_Sequence_Config and config.Doors.Door_Delay_Sequence_Config.Closing and typeof(config.Doors.Door_Delay_Sequence_Config.Closing.Delay) == 'number') then config.Doors.Door_Delay_Sequence_Config.Closing.Delay elseif (typeof(config.Doors.Door_Close_Pattern_Delay) == 'number') then config.Doors.Door_Close_Speed-config.Doors.Door_Close_Pattern_Delay else 1, --// Delay in seconds the door delay lasts
				},
			},

			['Door_Close_Button_Delay'] = if (typeof(config.Doors.Door_Close_Button_Delay) == 'number') then config.Doors.Door_Close_Button_Delay else 0,

			['Sensor_LED_Data'] = {

				['Opening_Color'] = {
					['Delay'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Opening_Color.Delay or .25,
					['Tween_Time'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Opening_Color.Tween_Time or .035, --Time in seconds for the sensor LED to change color
					['Flash_Time'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Opening_Color.Flash_Time or .15, --Time in seconds for flashing
					['Behavior'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Opening_Color.Behavior or 'Solid', --Flash/Solid
					['Active'] = {
						['Color'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Opening_Color.Active.Color or Color3.fromRGB(77, 194, 56),
						['Material'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Opening_Color.Active.Material or Enum.Material.Neon,
					},
					['Inactive'] = {
						['Color'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Opening_Color.Inactive.Color or Color3.fromRGB(50, 50, 50),
						['Material'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Opening_Color.Inactive.Material or Enum.Material.SmoothPlastic,
					},
				},
				['Closing_Color'] = {
					['Delay'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Closing_Color.Delay or .25,
					['Tween_Time'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Closing_Color.Tween_Time or .035, --Time in seconds for the sensor LED to change color
					['Flash_Time'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Closing_Color.Flash_Time or .15, --Time in seconds for flashing
					['Behavior'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Closing_Color.Behavior or 'Flash', --Flash/Solid
					['Active'] = {
						['Color'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Closing_Color.Active.Color or Color3.fromRGB(194, 81, 52),
						['Material'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Closing_Color.Active.Material or Enum.Material.Neon,
					},
					['Inactive'] = {
						['Color'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Closing_Color.Inactive.Color or Color3.fromRGB(50, 50, 50),
						['Material'] = config.Doors.Sensor_LED_Data and config.Doors.Sensor_LED_Data.Closing_Color.Inactive.Material or Enum.Material.SmoothPlastic,
					},
				},

			},
			['Realistic_Doors_Data'] = {
				['Enable_Open'] = config.Doors.Realistic_Doors_Data and config.Doors.Realistic_Doors_Data.Enable_Open or false,
				['Enable_Close'] = config.Doors.Realistic_Doors_Data and config.Doors.Realistic_Doors_Data.Enable_Close or false,
				['Open_Time'] = config.Doors.Realistic_Doors_Data and config.Doors.Realistic_Doors_Data.Open_Time or .5,
				['Close_Time'] = config.Doors.Realistic_Doors_Data and config.Doors.Realistic_Doors_Data.Close_Time or .6,
				['Open_Easing_Style'] = config.Doors.Realistic_Doors_Data and config.Doors.Realistic_Doors_Data.Open_Easing_Style or 'Linear',
				['Close_Easing_Style'] = config.Doors.Realistic_Doors_Data and config.Doors.Realistic_Doors_Data.Close_Easing_Style or 'Linear',
				['Open_Ratio'] = config.Doors.Realistic_Doors_Data and config.Doors.Realistic_Doors_Data.Open_Ratio and math.clamp(config.Doors.Realistic_Doors_Data.Open_Ratio, 1.0000001, math.huge) or config.Doors.Realistic_Doors_Data and config.Doors.Realistic_Doors_Data.Ratio or 1.05, --How much the door gaps when transitioning to the animation. The larger the value, the larger the gap gets
				['Close_Ratio'] = config.Doors.Realistic_Doors_Data and config.Doors.Realistic_Doors_Data.Close_Ratio and math.clamp(config.Doors.Realistic_Doors_Data.Close_Ratio, 1.0000001, math.huge) or config.Doors.Realistic_Doors_Data and config.Doors.Realistic_Doors_Data.Ratio or 1.05, --How much the door gaps when transitioning to the animation. The larger the value, the larger the gap gets
				['Open_Delay'] = {
					['Enable'] = config.Doors.Realistic_Doors_Data and config.Doors.Realistic_Doors_Data.Open_Delay and config.Doors.Realistic_Doors_Data.Open_Delay.Enable or false,
					['Duration'] = config.Doors.Realistic_Doors_Data and config.Doors.Realistic_Doors_Data.Open_Delay and config.Doors.Realistic_Doors_Data.Open_Delay.Duration or 0,
				},
				['Close_Delay'] = {
					['Enable'] = config.Doors.Realistic_Doors_Data and config.Doors.Realistic_Doors_Data.Close_Delay and config.Doors.Realistic_Doors_Data.Close_Delay.Enable or false,
					['Duration'] = config.Doors.Realistic_Doors_Data and config.Doors.Realistic_Doors_Data.Close_Delay and config.Doors.Realistic_Doors_Data.Close_Delay.Duration or 0,
				},
			},
			['Realistic_Outer_Doors_Data'] = {
				['Enable_Open'] = config.Doors.Realistic_Outer_Doors_Data and config.Doors.Realistic_Outer_Doors_Data.Enable_Open or false,
				['Enable_Close'] = config.Doors.Realistic_Outer_Doors_Data and config.Doors.Realistic_Outer_Doors_Data.Enable_Close or false,
				['Open_Time'] = config.Doors.Realistic_Outer_Doors_Data and config.Doors.Realistic_Outer_Doors_Data.Open_Time or .5,
				['Close_Time'] = config.Doors.Realistic_Outer_Doors_Data and config.Doors.Realistic_Outer_Doors_Data.Close_Time or .6,
				['Open_Easing_Style'] = config.Doors.Realistic_Outer_Doors_Data and config.Doors.Realistic_Outer_Doors_Data.Open_Easing_Style or 'Linear',
				['Close_Easing_Style'] = config.Doors.Realistic_Outer_Doors_Data and config.Doors.Realistic_Outer_Doors_Data.Close_Easing_Style or 'Linear',
				['Open_Ratio'] = config.Doors.Realistic_Outer_Doors_Data and config.Doors.Realistic_Outer_Doors_Data.Open_Ratio and math.clamp(config.Doors.Realistic_Outer_Doors_Data.Open_Ratio, 1.0000001, math.huge) or config.Doors.Realistic_Outer_Doors_Data and config.Doors.Realistic_Outer_Doors_Data.Ratio or 1.05, --How much the door gaps when transitioning to the animation. The larger the value, the larger the gap gets
				['Close_Ratio'] = config.Doors.Realistic_Outer_Doors_Data and config.Doors.Realistic_Outer_Doors_Data.Close_Ratio and math.clamp(config.Doors.Realistic_Outer_Doors_Data.Close_Ratio, 1.0000001, math.huge) or config.Doors.Realistic_Outer_Doors_Data and config.Doors.Realistic_Outer_Doors_Data.Ratio or 1.05, --How much the door gaps when transitioning to the animation. The larger the value, the larger the gap gets
				['Open_Delay'] = {
					['Enable'] = config.Doors.Realistic_Outer_Doors_Data and config.Doors.Realistic_Outer_Doors_Data.Open_Delay and config.Doors.Realistic_Outer_Doors_Data.Open_Delay.Enable or false,
					['Duration'] = config.Doors.Realistic_Outer_Doors_Data and config.Doors.Realistic_Outer_Doors_Data.Open_Delay and config.Doors.Realistic_Outer_Doors_Data.Open_Delay.Duration or 0,
				},
				['Close_Delay'] = {
					['Enable'] = config.Doors.Realistic_Outer_Doors_Data and config.Doors.Realistic_Outer_Doors_Data.Close_Delay and config.Doors.Realistic_Outer_Doors_Data.Close_Delay.Enable or false,
					['Duration'] = config.Doors.Realistic_Outer_Doors_Data and config.Doors.Realistic_Outer_Doors_Data.Close_Delay and config.Doors.Realistic_Outer_Doors_Data.Close_Delay.Duration or 0,
				},
			},

			['Door_Motor'] = if (typeof(config.Doors.Door_Motor) == 'boolean') then config.Doors.Door_Motor else true,

			['Open_Delay'] = if (typeof(config.Doors.Open_Delay) == 'number') then config.Doors.Open_Delay else 0,
			['Reopen_Delay'] = if (typeof(config.Doors.Reopen_Delay) == 'number') then config.Doors.Reopen_Delay else .5,
			['Close_Delay'] = if (typeof(config.Doors.Close_Delay) == 'number') then config.Doors.Close_Delay else 0,

			['Reopen_When_Nudge_Obstruction'] = config.Doors.Reopen_When_Nudge_Obstruction,
			['Hold_On_Nudge_Obstruction'] = config.Doors.Reopen_When_Nudge_Obstruction,

			['Stay_Open_When_Idle'] = config.Doors.Stay_Open_When_Idle,

			['Close_On_Button_Press'] = {
				['Enable'] = if (typeof(config.Doors.Close_On_Button_Press) == 'table' and typeof(config.Doors.Close_On_Button_Press.Enable) == 'boolean') then config.Doors.Close_On_Button_Press.Enable else false,
				['Delay'] = if (typeof(config.Doors.Close_On_Button_Press) == 'table' and typeof(config.Doors.Close_On_Button_Press.Delay) == 'number') then config.Doors.Close_On_Button_Press.Delay else 0,
			},

			['Disable_Door_Close'] = if (typeof(config.Doors.Disable_Door_Close) == 'boolean') then config.Doors.Disable_Door_Close else false,

			['Manual_Door_Controls'] = config.Doors.Manual_Door_Controls,

			['Custom_Door_Operator_Config'] = {

				['Inner'] = {
					['Opening'] = {
						['Enable'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Opening) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Opening.Enable) == 'boolean') then
							config.Doors.Custom_Door_Operator_Config.Inner.Opening.Enable
							else false,
						['Acceleration'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Opening) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Opening.Acceleration) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Inner.Opening.Acceleration
							else 0,
						['Deceleration_Distance'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Opening) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Opening.Deceleration_Distance) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Inner.Opening.Deceleration_Distance
							else 0,
						['Minimum_Speed'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Opening) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Opening.Minimum_Speed) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Inner.Opening.Minimum_Speed
							else 0,
						['Deceleration_Rate'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Opening) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Opening.Deceleration_Rate) == 'string') then
							config.Doors.Custom_Door_Operator_Config.Inner.Opening.Deceleration_Rate
							else 'Constant',
						['Custom_Acceleration_Stages'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Opening) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Opening.Custom_Acceleration_Stages) == 'table') then
							config.Doors.Custom_Door_Operator_Config.Inner.Opening.Custom_Acceleration_Stages
							else {},
						['Deceleration_Offset'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Opening) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Opening.Deceleration_Offset) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Inner.Opening.Deceleration_Offset
							else 0,
					},
					['Closing'] = {
						['Enable'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Closing) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Closing.Enable) == 'boolean') then
							config.Doors.Custom_Door_Operator_Config.Inner.Closing.Enable
							else false,
						['Acceleration'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Closing) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Closing.Acceleration) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Inner.Closing.Acceleration
							else 0,
						['Deceleration_Distance'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Closing) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Closing.Deceleration_Distance) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Inner.Closing.Deceleration_Distance
							else 0,
						['Minimum_Speed'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Closing) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Closing.Minimum_Speed) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Inner.Closing.Minimum_Speed
							else 0,
						['Deceleration_Rate'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Closing) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Closing.Deceleration_Rate) == 'string') then
							config.Doors.Custom_Door_Operator_Config.Inner.Closing.Deceleration_Rate
							else 'Constant',
						['Custom_Acceleration_Stages'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Closing) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Closing.Custom_Acceleration_Stages) == 'table') then
							config.Doors.Custom_Door_Operator_Config.Inner.Closing.Custom_Acceleration_Stages
							else {},
						['Deceleration_Offset'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Closing) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Inner.Closing.Deceleration_Offset) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Inner.Closing.Deceleration_Offset
							else 0,
					},
				},
				['Outer'] = {
					['Opening'] = {
						['Enable'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Opening) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Opening.Enable) == 'boolean') then
							config.Doors.Custom_Door_Operator_Config.Outer.Opening.Enable
							else false,
						['Acceleration'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Opening) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Opening.Acceleration) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Outer.Opening.Acceleration
							else 0,
						['Deceleration_Distance'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Opening) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Opening.Deceleration_Distance) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Outer.Opening.Deceleration_Distance
							else 0,
						['Minimum_Speed'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Opening) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Opening.Minimum_Speed) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Outer.Opening.Minimum_Speed
							else 0,
						['Deceleration_Rate'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Opening) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Opening.Deceleration_Rate) == 'string') then
							config.Doors.Custom_Door_Operator_Config.Outer.Opening.Deceleration_Rate
							else 'Constant',
						['Custom_Acceleration_Stages'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Opening) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Opening.Custom_Acceleration_Stages) == 'table') then
							config.Doors.Custom_Door_Operator_Config.Outer.Opening.Custom_Acceleration_Stages
							else {},
						['Deceleration_Offset'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Opening) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Opening.Deceleration_Offset) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Outer.Opening.Deceleration_Offset
							else 0,
					},
					['Closing'] = {
						['Enable'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Closing) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Closing.Enable) == 'boolean') then
							config.Doors.Custom_Door_Operator_Config.Outer.Closing.Enable
							else false,
						['Acceleration'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Closing) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Closing.Acceleration) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Outer.Closing.Acceleration
							else 0,
						['Deceleration_Distance'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Closing) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Closing.Deceleration_Distance) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Outer.Closing.Deceleration_Distance
							else 0,
						['Minimum_Speed'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Closing) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Closing.Minimum_Speed) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Outer.Closing.Minimum_Speed
							else 0,
						['Deceleration_Rate'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Closing) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Closing.Deceleration_Rate) == 'string') then
							config.Doors.Custom_Door_Operator_Config.Outer.Closing.Deceleration_Rate
							else 'Constant',
						['Custom_Acceleration_Stages'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Closing) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Closing.Custom_Acceleration_Stages) == 'table') then
							config.Doors.Custom_Door_Operator_Config.Outer.Closing.Custom_Acceleration_Stages
							else {},
						['Deceleration_Offset'] = if (typeof(config.Doors.Custom_Door_Operator_Config) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Closing) == 'table' and
							typeof(config.Doors.Custom_Door_Operator_Config.Outer.Closing.Deceleration_Offset) == 'number') then
							config.Doors.Custom_Door_Operator_Config.Outer.Closing.Deceleration_Offset
							else 0,
					},
				},

			},

			['Door_Open_Sound_Delay'] = if (typeof(config.Doors.Door_Open_Sound_Delay) == 'table') then config.Doors.Door_Open_Sound_Delay elseif (typeof(config.Doors.Open_Delay) == 'table') then config.Doors.Open_Delay else 0,
			['Door_Close_Sound_Delay'] = if (typeof(config.Doors.Door_Close_Sound_Delay) == 'table') then config.Doors.Door_Close_Sound_Delay elseif (typeof(config.Doors.Close_Delay) == 'table') then config.Doors.Close_Delay else 0,

			['New_Attachment_Doors_Config'] = {
				['Enable'] = if (typeof(config.Doors.New_Attachment_Doors_Config) == 'table' and typeof(config.Doors.New_Attachment_Doors_Config.Enable) == 'boolean') then config.Doors.New_Attachment_Doors_Config.Enable else false, -- When enabled, the outer doors will be "attached" to the inner doors instead of running independently
				['Attachment_Threshold'] = if (typeof(config.Doors.New_Attachment_Doors_Config) == 'table' and typeof(config.Doors.New_Attachment_Doors_Config.Attachment_Threshold) == 'number') then config.Doors.New_Attachment_Doors_Config.Attachment_Threshold else .05, -- Offset in studs the outer doors are positioned when moving with the inner doors
				['Closing_Min_Threshold'] = if (typeof(config.Doors.New_Attachment_Doors_Config) == 'table' and typeof(config.Doors.New_Attachment_Doors_Config.Closing_Min_Threshold) == 'number') then config.Doors.New_Attachment_Doors_Config.Closing_Min_Threshold else 0, -- Minimum distance in studs the doors can be from the closing position before the elevator is able to move
			},

		},
		['Movement'] = {
			['Movement_Type'] = config.Movement.Movement_Type or 1, --[1]: CFrame  [2]: AlignPosition

			['Weld_On_Move'] = config.Movement.Weld_On_Move,
			['Disable_Jumping'] = config.Movement.Disable_Jumping or false,
			--['Use_New_Welding'] = config.Movement.Weld_On_Move and ((config.Movement.Weld_On_Move ~= nil and config.Movement.Weld_On_Move) or (config.Movement.Weld_On_Move == nil and false)) or false,
			['Use_New_Welding'] = config.Movement.Use_New_Welding or false,
			--['Use_New_Welding'] = false,

			['Start_Delay'] = config.Movement.Start_Delay,
			['Motor_Start_Delay'] = {
				['Up'] = if (typeof(config.Movement.Motor_Start_Delay) == 'table' and typeof(config.Movement.Motor_Start_Delay.Up) == 'number') then config.Movement.Motor_Start_Delay.Up else 0,
				['Down'] = if (typeof(config.Movement.Motor_Start_Delay) == 'table' and typeof(config.Movement.Motor_Start_Delay.Down) == 'number') then config.Movement.Motor_Start_Delay.Down else 0,
			},
			['Down_Start_Delay'] = if (typeof(config.Movement.Down_Start_Delay) == 'number') then config.Movement.Down_Start_Delay else config.Movement.Start_Delay,

			['Use_Dynamic_Acceleration'] = config.Movement.Use_Dynamic_Acceleration,
			['Dynamic_Acceleration_Time'] = if (typeof(config.Movement.Dynamic_Acceleration_Time) == 'number') then config.Movement.Dynamic_Acceleration_Time else .75,

			['Acceleration'] = config.Movement.Acceleration,
			['Down_Acceleration'] = config.Movement.Down_Acceleration or config.Movement.Acceleration,

			['Travel_Speed'] = config.Movement.Travel_Speed,
			['Level_Speed'] = config.Movement.Level_Speed,
			['Floor_Pass_Chime_On_Stop'] = if (typeof(config.Movement.Floor_Pass_Chime_On_Stop) == 'boolean') then config.Movement.Floor_Pass_Chime_On_Stop else false,

			['Braking_Data'] = {
				['Mode'] = if (typeof(config.Movement.Braking_Data) == 'table' and typeof(config.Movement.Braking_Data.Mode) == 'string') then if (config.Movement.Braking_Data.Mode == 'Auto') then 'Default' else config.Movement.Braking_Data.Mode elseif (typeof(config.Movement.Braking_Mode) == 'string') then if (config.Movement.Braking_Mode == 'Auto') then 'Default' else config.Movement.Braking_Mode else 'Linear',
					['Increment'] = if (typeof(config.Movement.Braking_Data) == 'table' and typeof(config.Movement.Braking_Data.Increment) == 'number') then config.Movement.Braking_Data.Increment elseif (typeof(config.Movement.Braking_Amount) == 'number') then config.Movement.Braking_Amount else 0,
					['Linear_Mode_Offset_Up'] = if (typeof(config.Movement.Braking_Data) == 'table' and typeof(config.Movement.Braking_Data.Linear_Mode_Offset_Up) == 'number') then config.Movement.Braking_Data.Linear_Mode_Offset_Up elseif (typeof(config.Movement.Braking_Data) == 'table' and typeof(config.Movement.Braking_Data.Linear_Mode_Offset) == 'number') then config.Movement.Braking_Data.Linear_Mode_Offset else 0,
					['Linear_Mode_Offset_Down'] = if (typeof(config.Movement.Braking_Data) == 'table' and typeof(config.Movement.Braking_Data.Linear_Mode_Offset_Down) == 'number') then config.Movement.Braking_Data.Linear_Mode_Offset_Down elseif (typeof(config.Movement.Braking_Data) == 'table' and typeof(config.Movement.Braking_Data.Linear_Mode_Offset) == 'number') then config.Movement.Braking_Data.Linear_Mode_Offset else 0,

					['Advanced_Leveling'] = {
						['Stage_1_Min_Speed'] = config.Movement.Braking_Data and config.Movement.Braking_Data.Advanced_Leveling and config.Movement.Braking_Data.Advanced_Leveling.Stage_1_Min_Speed or 1+config.Movement.Level_Speed*2.0,
						['Stage_2_Decel_Offset'] = config.Movement.Braking_Data and config.Movement.Braking_Data.Advanced_Leveling and config.Movement.Braking_Data.Advanced_Leveling.Stage_2_Decel_Offset or 1.6,
					},
					['Smart_Linear_Transition_Dist'] = config.Movement.Braking_Data and config.Movement.Braking_Data.Smart_Linear_Transition_Dist or 1.75,

					['Custom_Leveling_Stages'] = config.Movement.Braking_Data and typeof(config.Movement.Braking_Data.Custom_Leveling_Stages) == 'table' and config.Movement.Braking_Data.Custom_Leveling_Stages or {},

			},

			['Jolt_Start_Data'] =
				{
					['Enable'] = config.Movement.Jolt_Start_Data and config.Movement.Jolt_Start_Data.Enable,
					['Ratio'] = config.Movement.Jolt_Start_Data and config.Movement.Jolt_Start_Data.Ratio or 1,
					['Depth'] = config.Movement.Jolt_Start_Data and config.Movement.Jolt_Start_Data.Depth or -1,
					['Speed'] = config.Movement.Jolt_Start_Data and config.Movement.Jolt_Start_Data.Speed or .4,
					['Start_Delay'] = config.Movement.Jolt_Start_Data and config.Movement.Jolt_Start_Data.Start_Delay or 0
				},

			['Bounce_Stop_Config'] = {
				['Enable'] = if (typeof(config.Movement.Bounce_Stop_Config) == 'table' and typeof(config.Movement.Bounce_Stop_Config.Enable) == 'boolean') then config.Movement.Bounce_Stop_Config.Enable elseif (typeof(config.Movement.Bounce_Stop) == 'string') then config.Movement.Bounce_Stop == 'Enable' and true or false else false,
				['Amount'] = config.Movement.Bounce_Stop_Config and config.Movement.Bounce_Stop_Config.Amount or .5,
				['Times'] = config.Movement.Bounce_Stop_Config and config.Movement.Bounce_Stop_Config.Times or 1,
				['Stop_Sound'] = config.Movement.Bounce_Stop_Config and config.Movement.Bounce_Stop_Config.Stop_Sound or {['Enable']=false,['Sound_Id']=0,['Volume']=0,['Pitch']=0},
			},
			['Motor_Stop_On_Open'] = config.Movement.Motor_Stop_On_Open or false,

			['Enable_Smooth_Stop'] = if (typeof(config.Movement.Enable_Smooth_Stop) == 'boolean') then config.Movement.Enable_Smooth_Stop else false,
			['Smooth_Stop_Min_Speed'] = typeof(config.Movement.Smooth_Stop_Min_Speed) ~= 'number' and .0025 or config.Movement.Smooth_Stop_Min_Speed,
			-- ! SMOOTH STOP OVERHAUL - NOW AS A THRESHOLD VALUE ! --
			['Smooth_Stop_Threshold'] = typeof(config.Movement.Smooth_Stop_Threshold) == 'number' and config.Movement.Smooth_Stop_Threshold or .15, -- Distance in studs from the floor that the elevator comes to a gradual stop

			['Smooth_Stop_V2'] = {
				['Enable'] = if (typeof(config.Movement.Smooth_Stop_V2) == 'table' and typeof(config.Movement.Smooth_Stop_V2.Enable) == 'boolean') then config.Movement.Smooth_Stop_V2.Enable else false,
				['Threshold'] = if (typeof(config.Movement.Smooth_Stop_V2) == 'table' and typeof(config.Movement.Smooth_Stop_V2.Threshold) == 'number') then config.Movement.Smooth_Stop_V2.Threshold else .4,
			},

			['Overdrive_Chance_Max'] = config.Movement.Overdrive_Chance_Max or 100000000,
			['Pre_Start_Data'] = config.Movement.Pre_Start_Data or {
				['Enabled'] = false,
				['Floor_Change_Delay'] = .3,
				['Chime_Delay'] = .3,
			},
			['Motor_Sound'] = if (config.Movement.Motor_Sound == nil) then true else config.Movement.Motor_Sound,
			['Depart_Pre_Start'] = {

				['Enable'] = config.Movement.Depart_Pre_Start and config.Movement.Depart_Pre_Start.Enable or false,
				['Delay'] = config.Movement.Depart_Pre_Start and config.Movement.Depart_Pre_Start.Delay or .1,
				['Ignore_Start_Delay'] = config.Movement.Depart_Pre_Start and config.Movement.Depart_Pre_Start.Ignore_Start_Delay or true,
				['Cancel_On_Door_Reopen'] = config.Movement.Depart_Pre_Start and config.Movement.Depart_Pre_Start.Cancel_On_Door_Reopen ~= nil and config.Movement.Depart_Pre_Start.Cancel_On_Door_Reopen or (not config.Movement.Depart_Pre_Start) and true or config.Movement.Depart_Pre_Start.Cancel_On_Door_Reopen,

			}, --If you enter a call while the doors are closing, the elevator ignores the start delay (like the SchindIer 5500).
			['Relevel_Tolerance'] = config.Movement.Relevel_Tolerance or .1,
			['Inspection_Start_Delay'] = {
				['Up'] = config.Movement.Inspection_Start_Delay and typeof(config.Movement.Inspection_Start_Delay) == 'table' and config.Movement.Inspection_Start_Delay.Up or config.Movement.Inspection_Start_Delay or .5,
				['Down'] = config.Movement.Inspection_Start_Delay and typeof(config.Movement.Inspection_Start_Delay) == 'table' and config.Movement.Inspection_Start_Delay.Down or config.Movement.Inspection_Start_Delay or .5,
			},

			['Inspection_Config'] = {

				['Max_Speed'] = config.Movement.Inspection_Config and config.Movement.Inspection_Config.Max_Speed or config.Movement.Travel_Speed/2, --The maximum speed the elevator can travel in inspection mode
				['Accceleration_Rate'] = config.Movement.Inspection_Config and config.Movement.Inspection_Config.Accceleration_Rate or config.Movement.Acceleration, --The rate of acceleration in inspection
				['Deceleration_Rate'] = config.Movement.Inspection_Config and config.Movement.Inspection_Config.Deceleration_Rate or config.Movement.Acceleration*2, --The rate of deceleration in inspection

			},
			['Level_Offset_Ratio'] = config.Movement.Level_Offset_Ratio or .2,
			['Floor_Pass_Chime_On_Stop_Config'] = {
				['Enable'] = 'UNSET',
				['Delay'] = 'UNSET',
				['Play_On_Arrival_Floor'] = 'UNSET',
			},
			['Parking_Config'] = config.Movement.Parking_Config or {

				['Enable'] = config.Movement.Parking_Config and config.Movement.Parking_Config.Enable or false,
				['Idle_Time'] = config.Movement.Parking_Config and config.Movement.Parking_Config.Idle_Time or 60,
				['Park_Floor'] = config.Movement.Parking_Config and config.Movement.Parking_Config.Park_Floor or 1,

			},
			['Releveling_Speed'] = typeof(config.Movement.Releveling_Speed) == 'number' and config.Movement.Releveling_Speed or config.Movement.Level_Speed,

			['Stop_Delay'] = config.Movement.Stop_Delay,

			['Open_Doors_On_Stop'] = config.Movement.Open_Doors_On_Stop,
			['Open_Doors_On_Call'] = config.Movement.Open_Doors_On_Call,

		},
		['Sensors'] = {

			['Up_Level_Offset'] = config.Sensors.Up_Level_Offset or config.Sensors.Level_Offset,
			['Down_Level_Offset'] = config.Sensors.Down_Level_Offset or config.Sensors.Level_Offset,

			['Stop_Offset'] = config.Sensors.Stop_Offset,
			['Pre_Door_Data'] = {
				['Enable'] = config.Sensors.Pre_Door,
				['Offset'] = config.Sensors.Pre_Door_Offset
			},

			['Floor_Position_Offset'] = config.Sensors.Floor_Position_Offset or 0,
			['Floor_Value_Offset'] = config.Sensors.Floor_Value_Offset or 0,

		},
		['Freight'] = {
			['Same_Floor_Call'] = {
				['With_Doors_Open'] = {
					['Enable'] = config.Freight and config.Freight.Same_Floor_Call and config.Freight.Same_Floor_Call.With_Doors_Open and config.Freight.Same_Floor_Call.With_Doors_Open.Enable or false,
					['Bell'] = config.Freight and config.Freight.Same_Floor_Call and config.Freight.Same_Floor_Call.With_Doors_Open and config.Freight.Same_Floor_Call.With_Doors_Open.Bell or false,
					['Call_Elevator'] = config.Freight and config.Freight.Same_Floor_Call and config.Freight.Same_Floor_Call.With_Doors_Open and config.Freight.Same_Floor_Call.With_Doors_Open.Call_Elevator or false
				},
				['With_Doors_Closed'] = {
					['Enable'] = config.Freight and config.Freight.Same_Floor_Call and config.Freight.Same_Floor_Call.With_Doors_Closed and config.Freight.Same_Floor_Call.With_Doors_Closed.Enable or false,
					['Bell'] = config.Freight and config.Freight.Same_Floor_Call and config.Freight.Same_Floor_Call.With_Doors_Closed and config.Freight.Same_Floor_Call.With_Doors_Closed.Bell or false,
					['Call_Elevator'] = config.Freight and config.Freight.Same_Floor_Call and config.Freight.Same_Floor_Call.With_Doors_Closed and config.Freight.Same_Floor_Call.With_Doors_Closed.Call_Elevator or false
				}
			},
			['Other_Floor_Call'] = {
				['With_Doors_Open'] = {
					['Enable'] = config.Freight and config.Freight.Other_Floor_Call and config.Freight.Other_Floor_Call.With_Doors_Open and config.Freight.Other_Floor_Call.With_Doors_Open.Enable or false,
					['Bell'] = config.Freight and config.Freight.Other_Floor_Call and config.Freight.Other_Floor_Call.With_Doors_Open and config.Freight.Other_Floor_Call.With_Doors_Open.Bell or false,
					['Call_Elevator'] = config.Freight and config.Freight.Other_Floor_Call and config.Freight.Other_Floor_Call.With_Doors_Open and config.Freight.Other_Floor_Call.With_Doors_Open.Call_Elevator or false
				},
				['With_Doors_Closed'] = {
					['Enable'] = config.Freight and config.Freight.Other_Floor_Call and config.Freight.Other_Floor_Call.With_Doors_Closed and config.Freight.Other_Floor_Call.With_Doors_Closed.Enable or false,
					['Bell'] = config.Freight and config.Freight.Other_Floor_Call and config.Freight.Other_Floor_Call.With_Doors_Closed and config.Freight.Other_Floor_Call.With_Doors_Closed.Bell or false,
					['Call_Elevator'] = config.Freight and config.Freight.Other_Floor_Call and config.Freight.Other_Floor_Call.With_Doors_Closed and config.Freight.Other_Floor_Call.With_Doors_Closed.Call_Elevator or false
				}
			}
		},
		['Color_Database'] = {
			['Lanterns'] = {
				['Active_On_Door_Open'] = {
					['Interior'] = {
						['Enable'] = if typeof(config.Color_Database.Lanterns.Active_On_Door_Open and config.Color_Database.Lanterns.Active_On_Door_Open.Interior.Enable) == 'boolean' then config.Color_Database.Lanterns.Active_On_Door_Open.Interior.Enable elseif typeof(config.Color_Database.Lanterns.Lantern_On_Door_Open) == 'boolean' then config.Color_Database.Lanterns.Lantern_On_Door_Open else false,
						['Delay'] = if typeof(config.Color_Database.Lanterns.Active_On_Door_Open and config.Color_Database.Lanterns.Active_On_Door_Open.Interior.Delay) == 'number' then config.Color_Database.Lanterns.Active_On_Door_Open.Interior.Delay else 0,
						['Call_Only'] = if typeof(config.Color_Database.Lanterns.Active_On_Door_Open and config.Color_Database.Lanterns.Active_On_Door_Open.Interior.Call_Only) == 'boolean' then config.Color_Database.Lanterns.Active_On_Door_Open.Interior.Call_Only else false,
					},
					['Exterior'] = {
						['Enable'] = if typeof(config.Color_Database.Lanterns.Active_On_Door_Open and config.Color_Database.Lanterns.Active_On_Door_Open.Exterior.Enable) == 'boolean' then config.Color_Database.Lanterns.Active_On_Door_Open.Exterior.Enable elseif typeof(config.Color_Database.Lanterns.Lantern_On_Door_Open) == 'boolean' then config.Color_Database.Lanterns.Lantern_On_Door_Open else false,
						['Delay'] = if typeof(config.Color_Database.Lanterns.Active_On_Door_Open and config.Color_Database.Lanterns.Active_On_Door_Open.Exterior.Delay) == 'number' then config.Color_Database.Lanterns.Active_On_Door_Open.Exterior.Delay else 0,
						['Call_Only'] = if typeof(config.Color_Database.Lanterns.Active_On_Door_Open and config.Color_Database.Lanterns.Active_On_Door_Open.Exterior.Call_Only) == 'boolean' then config.Color_Database.Lanterns.Active_On_Door_Open.Exterior.Call_Only else false,
					},
				},
				['Active_After_Door_Open'] = {
					['Interior'] = {
						['Enable'] = if typeof(config.Color_Database.Lanterns.Active_After_Door_Open and config.Color_Database.Lanterns.Active_After_Door_Open.Interior.Enable) == 'boolean' then config.Color_Database.Lanterns.Active_After_Door_Open.Interior.Enable elseif typeof(config.Color_Database.Lanterns.Lantern_After_Door_Open) == 'boolean' then config.Color_Database.Lanterns.Lantern_After_Door_Open else false,
						['Delay'] = if typeof(config.Color_Database.Lanterns.Active_After_Door_Open and config.Color_Database.Lanterns.Active_After_Door_Open.Interior.Delay) == 'number' then config.Color_Database.Lanterns.Active_After_Door_Open.Interior.Delay else 0,
						['Call_Only'] = if typeof(config.Color_Database.Lanterns.Active_After_Door_Open and config.Color_Database.Lanterns.Active_After_Door_Open.Interior.Call_Only) == 'boolean' then config.Color_Database.Lanterns.Active_After_Door_Open.Interior.Call_Only else false,
					},
					['Exterior'] = {
						['Enable'] = if typeof(config.Color_Database.Lanterns.Active_After_Door_Open and config.Color_Database.Lanterns.Active_After_Door_Open.Exterior.Enable) == 'boolean' then config.Color_Database.Lanterns.Active_After_Door_Open.Exterior.Enable elseif typeof(config.Color_Database.Lanterns.Lantern_After_Door_Open) == 'boolean' then config.Color_Database.Lanterns.Lantern_After_Door_Open else false,
						['Delay'] = if typeof(config.Color_Database.Lanterns.Active_After_Door_Open and config.Color_Database.Lanterns.Active_After_Door_Open.Exterior.Delay) == 'number' then config.Color_Database.Lanterns.Active_After_Door_Open.Exterior.Delay else 0,
						['Call_Only'] = if typeof(config.Color_Database.Lanterns.Active_After_Door_Open and config.Color_Database.Lanterns.Active_After_Door_Open.Exterior.Call_Only) == 'boolean' then config.Color_Database.Lanterns.Active_After_Door_Open.Exterior.Call_Only else false,
					},
				},
				['Active_On_Arrival'] = {
					['Interior'] = {
						['Enable'] = if typeof(config.Color_Database.Lanterns.Active_On_Arrival) == 'table' and typeof(config.Color_Database.Lanterns.Active_On_Arrival.Interior.Enable) == 'boolean' then config.Color_Database.Lanterns.Active_On_Arrival.Interior.Enable elseif typeof(config.Color_Database.Lanterns.Lantern_On_Arrival) == 'boolean' then config.Color_Database.Lanterns.Lantern_On_Arrival else false,
						['Delay'] = if typeof(config.Color_Database.Lanterns.Active_On_Arrival) == 'table' and typeof(config.Color_Database.Lanterns.Active_On_Arrival.Interior.Delay) == 'number' then config.Color_Database.Lanterns.Active_On_Arrival.Interior.Delay else 0,
						['Call_Only'] = if typeof(config.Color_Database.Lanterns.Active_On_Arrival) == 'table' and typeof(config.Color_Database.Lanterns.Active_On_Arrival.Interior.Call_Only) == 'boolean' then config.Color_Database.Lanterns.Active_On_Arrival.Interior.Call_Only else false,
					},
					['Exterior'] = {
						['Enable'] = if typeof(config.Color_Database.Lanterns.Active_On_Arrival) == 'table' and typeof(config.Color_Database.Lanterns.Active_On_Arrival.Exterior.Enable) == 'boolean' then config.Color_Database.Lanterns.Active_On_Arrival.Exterior.Enable elseif typeof(config.Color_Database.Lanterns.Lantern_On_Arrival) == 'boolean' then config.Color_Database.Lanterns.Lantern_On_Arrival else false,
						['Delay'] = if typeof(config.Color_Database.Lanterns.Active_On_Arrival) == 'table' and typeof(config.Color_Database.Lanterns.Active_On_Arrival.Exterior.Delay) == 'number' then config.Color_Database.Lanterns.Active_On_Arrival.Exterior.Delay else 0,
						['Call_Only'] = if typeof(config.Color_Database.Lanterns.Active_On_Arrival) == 'table' and typeof(config.Color_Database.Lanterns.Active_On_Arrival.Exterior.Call_Only) == 'boolean' then config.Color_Database.Lanterns.Active_On_Arrival.Exterior.Call_Only else false,
					},
				},
				['Active_On_Call_Enter'] = {
					['Interior'] = {
						['Enable'] = if typeof(config.Color_Database.Lanterns.Active_On_Call_Enter) == 'table' and typeof(config.Color_Database.Lanterns.Active_On_Call_Enter.Interior.Enable) == 'boolean' then config.Color_Database.Lanterns.Active_On_Call_Enter.Interior.Enable elseif typeof(config.Color_Database.Lanterns.Lantern_On_Arrival) == 'boolean' then config.Color_Database.Lanterns.Lantern_On_Arrival else false,
						['Delay'] = if typeof(config.Color_Database.Lanterns.Active_On_Call_Enter and config.Color_Database.Lanterns.Active_On_Call_Enter.Interior.Delay) == 'number' then config.Color_Database.Lanterns.Active_On_Call_Enter.Interior.Delay else 0,
						['Call_Only'] = if typeof(config.Color_Database.Lanterns.Active_On_Call_Enter and config.Color_Database.Lanterns.Active_On_Call_Enter.Interior.Call_Only) == 'boolean' then config.Color_Database.Lanterns.Active_On_Call_Enter.Interior.Call_Only else false,
					},
					['Exterior'] = {
						['Enable'] = if typeof(config.Color_Database.Lanterns.Active_On_Call_Enter and config.Color_Database.Lanterns.Active_On_Call_Enter.Exterior.Enable) == 'boolean' then config.Color_Database.Lanterns.Active_On_Call_Enter.Exterior.Enable elseif typeof(config.Color_Database.Lanterns.Lantern_On_Arrival) == 'boolean' then config.Color_Database.Lanterns.Lantern_On_Arrival else false,
						['Delay'] = if typeof(config.Color_Database.Lanterns.Active_On_Call_Enter and config.Color_Database.Lanterns.Active_On_Call_Enter.Exterior.Delay) == 'number' then config.Color_Database.Lanterns.Active_On_Call_Enter.Exterior.Delay else 0,
						['Call_Only'] = if typeof(config.Color_Database.Lanterns.Active_On_Call_Enter and config.Color_Database.Lanterns.Active_On_Call_Enter.Exterior.Call_Only) == 'boolean' then config.Color_Database.Lanterns.Active_On_Call_Enter.Exterior.Call_Only else false,
					},
				},
				['Active_On_Button_Press'] = {
					['Interior'] = {
						['Enable'] = if typeof(config.Color_Database.Lanterns.Active_On_Button_Press and config.Color_Database.Lanterns.Active_On_Button_Press.Interior.Enable) == 'boolean' then config.Color_Database.Lanterns.Active_On_Button_Press.Interior.Enable elseif typeof(config.Color_Database.Lanterns.Lantern_On_Call_Enter) == 'boolean' then config.Color_Database.Lanterns.Lantern_On_Call_Enter else false,
						['Delay'] = if typeof(config.Color_Database.Lanterns.Active_On_Button_Press and config.Color_Database.Lanterns.Active_On_Button_Press.Interior.Delay) == 'number' then config.Color_Database.Lanterns.Active_On_Button_Press.Interior.Delay else 0,
						['Call_Only'] = if typeof(config.Color_Database.Lanterns.Active_On_Button_Press and config.Color_Database.Lanterns.Active_On_Button_Press.Interior.Call_Only) == 'boolean' then config.Color_Database.Lanterns.Active_On_Button_Press.Interior.Call_Only else false,
					},
					['Exterior'] = {
						['Enable'] = if typeof(config.Color_Database.Lanterns.Active_On_Button_Press and config.Color_Database.Lanterns.Active_On_Button_Press.Exterior.Enable) == 'boolean' then config.Color_Database.Lanterns.Active_On_Button_Press.Exterior.Enable elseif typeof(config.Color_Database.Lanterns.Lantern_On_Call_Enter) == 'boolean' then config.Color_Database.Lanterns.Lantern_On_Call_Enter else false,
						['Delay'] = if typeof(config.Color_Database.Lanterns.Active_On_Button_Press and config.Color_Database.Lanterns.Active_On_Button_Press.Exterior.Delay) == 'number' then config.Color_Database.Lanterns.Active_On_Button_Press.Exterior.Delay else 0,
						['Call_Only'] = if typeof(config.Color_Database.Lanterns.Active_On_Button_Press and config.Color_Database.Lanterns.Active_On_Button_Press.Exterior.Call_Only) == 'boolean' then config.Color_Database.Lanterns.Active_On_Button_Press.Exterior.Call_Only else false,
					},
				},
				['Active_On_Exterior_Call'] = {
					['Interior'] = {
						['Enable'] = if typeof(config.Color_Database.Lanterns.Active_On_Exterior_Call and config.Color_Database.Lanterns.Active_On_Exterior_Call.Interior.Enable) == 'boolean' then config.Color_Database.Lanterns.Active_On_Exterior_Call.Interior.Enable elseif typeof(config.Color_Database.Lanterns.Lantern_On_Exterior_Call) == 'boolean' then config.Color_Database.Lanterns.Lantern_On_Exterior_Call else false,
						['Delay'] = if typeof(config.Color_Database.Lanterns.Active_On_Exterior_Call and config.Color_Database.Lanterns.Active_On_Exterior_Call.Interior.Delay) == 'number' then config.Color_Database.Lanterns.Active_On_Exterior_Call.Interior.Delay else 0,
						['Call_Only'] = false --[[config.Color_Database.Lanterns.Active_On_Exterior_Call and if typeof(config.Color_Database.Lanterns.Active_On_Exterior_Call.Interior.Call_Only) == 'boolean' then config.Color_Database.Lanterns.Active_On_Exterior_Call.Interior.Call_Only else 0]],
					},
					['Exterior'] = {
						['Enable'] = if typeof(config.Color_Database.Lanterns.Active_On_Exterior_Call and config.Color_Database.Lanterns.Active_On_Exterior_Call.Exterior.Enable) == 'boolean' then config.Color_Database.Lanterns.Active_On_Exterior_Call.Exterior.Enable elseif typeof(config.Color_Database.Lanterns.Lantern_On_Exterior_Call) == 'boolean' then config.Color_Database.Lanterns.Lantern_On_Exterior_Call else false,
						['Delay'] = if typeof(config.Color_Database.Lanterns.Active_On_Exterior_Call and config.Color_Database.Lanterns.Active_On_Exterior_Call.Exterior.Delay) == 'number' then config.Color_Database.Lanterns.Active_On_Exterior_Call.Exterior.Delay else 0,
						['Call_Only'] = false --[[config.Color_Database.Lanterns.Active_On_Exterior_Call and if typeof(config.Color_Database.Lanterns.Active_On_Exterior_Call.Exterior.Call_Only) == 'boolean' then config.Color_Database.Lanterns.Active_On_Exterior_Call.Exterior.Call_Only else 0]],
					},
				},

				['Door_Distance_Reset_Ratio'] = config.Color_Database.Lanterns.Door_Distance_Reset_Ratio or 0,

				['Exterior'] = {

					['Repeat_Data'] = config.Color_Database.Lanterns.Exterior and config.Color_Database.Lanterns.Exterior.Repeat_Data or config.Color_Database.Lanterns.Repeat_Data or {
						['Enable'] = false,
						['Times'] = 1,
						['Delay'] = .33,
						['Play_Chime_On_Light'] = false,
						['Allowed_Directions'] = {'D'} --List of elevator directions when the repeat feature is supposed to run. Available directions: U, D, N
					},

					['Up'] = config.Color_Database.Lanterns.Exterior and config.Color_Database.Lanterns.Exterior.Up or config.Color_Database.Lanterns.Up,
					['Down'] = config.Color_Database.Lanterns.Exterior and config.Color_Database.Lanterns.Exterior.Down or config.Color_Database.Lanterns.Down,

					['Reset_After_Door_Close'] = config.Color_Database.Lanterns.Exterior and config.Color_Database.Lanterns.Exterior.Reset_After_Door_Close,

				},
				['Interior'] = {

					['Repeat_Data'] = config.Color_Database.Lanterns.Interior and config.Color_Database.Lanterns.Interior.Repeat_Data or config.Color_Database.Lanterns.Repeat_Data or {
						['Enable'] = false,
						['Times'] = 1,
						['Delay'] = .33,
						['Play_Chime_On_Light'] = false,
						['Allowed_Directions'] = {'D'} --List of elevator directions when the repeat feature is supposed to run. Available directions: U, D, N
					},

					['Up'] = config.Color_Database.Lanterns.Interior and config.Color_Database.Lanterns.Interior.Up or config.Color_Database.Lanterns.Up,
					['Down'] = config.Color_Database.Lanterns.Interior and config.Color_Database.Lanterns.Interior.Down or config.Color_Database.Lanterns.Down,

					['Reset_After_Door_Close'] = config.Color_Database.Lanterns.Interior and config.Color_Database.Lanterns.Interior.Reset_After_Door_Close,
				},
			},
			['Car'] = {

				['Lit_Delay'] = config.Color_Database.Car.Lit_Delay or .1,
				['Floor_Button'] = {
					['Lit_State'] = {
						['Color'] = config.Color_Database.Car.Floor_Button.Lit_State.Color, ['Material'] = config.Color_Database.Car.Floor_Button.Lit_State.Material
					}, 
					['Neautral_State'] = {
						['Color'] = config.Color_Database.Car.Floor_Button.Neautral_State.Color, ['Material'] = config.Color_Database.Car.Floor_Button.Neautral_State.Material
					},
				},
				['Alarm_Button'] = {
					['Lit_State'] = {
						['Color'] = config.Color_Database.Car.Alarm_Button.Lit_State.Color, ['Material'] = config.Color_Database.Car.Alarm_Button.Lit_State.Material
					}, 
					['Neautral_State'] = {
						['Color'] = config.Color_Database.Car.Alarm_Button.Neautral_State.Color, ['Material'] = config.Color_Database.Car.Alarm_Button.Neautral_State.Material
					},
				},

				['Doors'] = {

					['Open'] = {

						['Active'] = {
							['Color'] = config.Color_Database.Car.Doors and config.Color_Database.Car.Doors.Open.Active.Color or config.Color_Database.Car.Floor_Button.Lit_State.Color,
							['Material'] = config.Color_Database.Car.Doors and config.Color_Database.Car.Doors.Open.Active.Material or config.Color_Database.Car.Floor_Button.Lit_State.Material,
						},
						['Neutral'] = {
							['Color'] = config.Color_Database.Car.Doors and config.Color_Database.Car.Doors.Open.Neutral.Color or config.Color_Database.Car.Floor_Button.Neautral_State.Color,
							['Material'] = config.Color_Database.Car.Doors and config.Color_Database.Car.Doors.Open.Neutral.Material or config.Color_Database.Car.Floor_Button.Neautral_State.Material,
						}

					},
					['Close'] = {

						['Active'] = {
							['Color'] = config.Color_Database.Car.Doors and config.Color_Database.Car.Doors.Close.Active.Color or config.Color_Database.Car.Floor_Button.Lit_State.Color,
							['Material'] = config.Color_Database.Car.Doors and config.Color_Database.Car.Doors.Close.Active.Material or config.Color_Database.Car.Floor_Button.Lit_State.Material,
						},
						['Neutral'] = {
							['Color'] = config.Color_Database.Car.Doors and config.Color_Database.Car.Doors.Close.Neutral.Color or config.Color_Database.Car.Floor_Button.Neautral_State.Color,
							['Material'] = config.Color_Database.Car.Doors and config.Color_Database.Car.Doors.Close.Neutral.Material or config.Color_Database.Car.Floor_Button.Neautral_State.Material,
						}

					},
					['Hold'] = {

						['Active'] = {
							['Color'] = config.Color_Database.Car.Doors and config.Color_Database.Car.Doors.Hold.Active.Color or config.Color_Database.Car.Floor_Button.Lit_State.Color,
							['Material'] = config.Color_Database.Car.Doors and config.Color_Database.Car.Doors.Hold.Active.Material or config.Color_Database.Car.Floor_Button.Lit_State.Material,
						},
						['Neutral'] = {
							['Color'] = config.Color_Database.Car.Doors and config.Color_Database.Car.Doors.Hold.Neutral.Color or config.Color_Database.Car.Floor_Button.Neautral_State.Color,
							['Material'] = config.Color_Database.Car.Doors and config.Color_Database.Car.Doors.Hold.Neutral.Material or config.Color_Database.Car.Floor_Button.Neautral_State.Material,
						}

					},

				},

				['Custom_Color_Data'] = config.Color_Database.Car.Custom_Color_Data or {},

			},
			['Floor'] = {
				['Active_Duration'] = config.Color_Database.Floor.Active_Duration or config.Color_Database.Floor.Lit_Delay or .1,
				['Up'] = {
					['Lit_State'] = {
						['Color'] = config.Color_Database.Floor.Up.Lit_State.Color, ['Material'] = config.Color_Database.Floor.Up.Lit_State.Material
					}, 
					['Neautral_State'] = {
						['Color'] = config.Color_Database.Floor.Up.Neautral_State.Color, ['Material'] = config.Color_Database.Floor.Up.Neautral_State.Material
					},
				},
				['Down'] = {
					['Lit_State'] = {
						['Color'] = config.Color_Database.Floor.Down.Lit_State.Color, ['Material'] = config.Color_Database.Floor.Down.Lit_State.Material
					}, 
					['Neautral_State'] = {
						['Color'] = config.Color_Database.Floor.Down.Neautral_State.Color, ['Material'] = config.Color_Database.Floor.Down.Neautral_State.Material
					},
				},
			},

		},
		['Extra_Config'] = config.Extra_Config or
			{
				['Debug'] = false,
				['Enable_Parking'] = false,
				['Parking'] = {
					['Park_Floor'] = 1,
					['Park_Time'] = 1,
				},
			},
		['Locking'] = {
			['Locked_Floors'] = config.Locking and config.Locking.Locked_Floors or {},
			['Locked_Hall_Floors'] = config.Locking and config.Locking.Locked_Hall_Floors or {},
			['Disable_Door_Open_On_Locked_Floor'] = {
				['Car'] = {
					['When_Doors_Closing'] = config.Locking and config.Locking.Disable_Door_Open_On_Locked_Floor and config.Locking.Disable_Door_Open_On_Locked_Floor.Car and config.Locking.Disable_Door_Open_On_Locked_Floor.Car.When_Doors_Closing or false,
					['When_Doors_Closed'] = config.Locking and config.Locking.Disable_Door_Open_On_Locked_Floor and config.Locking.Disable_Door_Open_On_Locked_Floor.Car and config.Locking.Disable_Door_Open_On_Locked_Floor.Car.When_Doors_Closed or false
				},
				['Hall'] = {
					['When_Doors_Closing'] = config.Locking and config.Locking.Disable_Door_Open_On_Locked_Floor and config.Locking.Disable_Door_Open_On_Locked_Floor.Hall and config.Locking.Disable_Door_Open_On_Locked_Floor.Hall.When_Doors_Closing or false,
					['When_Doors_Closed'] = config.Locking and config.Locking.Disable_Door_Open_On_Locked_Floor and config.Locking.Disable_Door_Open_On_Locked_Floor.Hall and config.Locking.Disable_Door_Open_On_Locked_Floor.Hall.When_Doors_Closed or false
				}
			},
			['Lock_Opposite_Travel_Direction_Floors'] = config.Locking and config.Locking.Lock_Opposite_Travel_Direction_Floors or false
		},
		['Custom_Floor_Label'] = config.Custom_Floor_Label or {},
		['Camera_Force_Data'] = config.Cam_Force_Data or
			{
				['Enable'] = true, --Whether the effect is enabled or not.
				['Acceleration_Amount'] = 1, --How many times this value is multiplied by the default value.
				['Show_When_Leaving'] = true, --Whether the effect shows when the elevator accelerates (leaves a floor) or not.
				['Show_When_Leveling'] = true, --Whether the effect shows when the elevator is leveling (slowing down to a stop).
			},
		['ClientRefresh_Movement_Config'] = {
			['Enable'] = config.ClientRefresh_Movement_Config and config.ClientRefresh_Movement_Config.Enable,
			['Priority'] = 1, --Unused for now.
		},

		['Call_Limiting'] = {
			['Enable'] = if (typeof(config.Call_Limiting) == 'table' and typeof(config.Call_Limiting.Enable) == 'boolean') then config.Call_Limiting.Enable else false,
			['Max_Calls'] = if (typeof(config.Call_Limiting) == 'table' and typeof(config.Call_Limiting.Max_Calls) == 'number') then config.Call_Limiting.Max_Calls else math.huge,
		},

		['Sound_Database'] = {
			['Chime_On_Door_Open'] = config.Sound_Database.Chime_On_Door_Open,
			['Chime_After_Door_Open'] = config.Sound_Database.Chime_After_Door_Open,
			['Chime_On_Arrival'] = config.Sound_Database.Chime_On_Arrival,
			['Chime_On_Button_Press'] = config.Sound_Database.Chime_On_Button_Press,
			['Chime_On_Call_Enter'] = config.Sound_Database.Chime_On_Call_Enter,
			['Chime_On_Exterior_Call'] = config.Sound_Database.Chime_On_Exterior_Call,

			['Chime_Events'] = {

				['On_Open'] = {
					['Interior'] = {
						Enable = if (typeof(config.Sound_Database.Chime_On_Door_Open) == 'table' and
							typeof(config.Sound_Database.Chime_On_Door_Open.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Door_Open.Interior.Enable) == 'boolean') then config.Sound_Database.Chime_On_Door_Open.Interior.Enable
							elseif (typeof(config.Sound_Database.Chime_On_Door_Open) == 'boolean') then
							config.Sound_Database.Chime_On_Door_Open
							else false,

						Delay = if (typeof(config.Sound_Database.Chime_On_Door_Open) == 'table' and
							typeof(config.Sound_Database.Chime_On_Door_Open.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Door_Open.Interior.Delay) == 'number') then
							config.Sound_Database.Chime_On_Door_Open.Interior.Delay else
							0,
						Call_Only = if (typeof(config.Sound_Database.Chime_On_Door_Open) == 'table' and
							typeof(config.Sound_Database.Chime_On_Door_Open.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Door_Open.Interior.Call_Only) == 'boolean') then
							config.Sound_Database.Chime_On_Door_Open.Interior.Call_Only else
							false,
					},
					['Exterior'] = {
						Enable = if (typeof(config.Sound_Database.Chime_On_Door_Open) == 'table' and
							typeof(config.Sound_Database.Chime_On_Door_Open.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Door_Open.Exterior.Enable) == 'boolean') then config.Sound_Database.Chime_On_Door_Open.Exterior.Enable
							elseif (typeof(config.Sound_Database.Chime_On_Door_Open) == 'boolean') then
							config.Sound_Database.Chime_On_Door_Open
							else false,

						Delay = if (typeof(config.Sound_Database.Chime_On_Door_Open) == 'table' and
							typeof(config.Sound_Database.Chime_On_Door_Open.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Door_Open.Exterior.Delay) == 'number') then
							config.Sound_Database.Chime_On_Door_Open.Exterior.Delay else
							0,
						Call_Only = if (typeof(config.Sound_Database.Chime_On_Door_Open) == 'table' and
							typeof(config.Sound_Database.Chime_On_Door_Open.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Door_Open.Exterior.Call_Only) == 'boolean') then
							config.Sound_Database.Chime_On_Door_Open.Exterior.Call_Only else
							false,
					},
				},
				['After_Open'] = {
					['Interior'] = {
						Enable = if (typeof(config.Sound_Database.Chime_After_Door_Open) == 'table' and
							typeof(config.Sound_Database.Chime_After_Door_Open.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_After_Door_Open.Interior.Enable) == 'boolean') then config.Sound_Database.Chime_After_Door_Open.Interior.Enable
							elseif (typeof(config.Sound_Database.Chime_After_Door_Open) == 'boolean') then
							config.Sound_Database.Chime_After_Door_Open
							else false,

						Delay = if (typeof(config.Sound_Database.Chime_After_Door_Open) == 'table' and
							typeof(config.Sound_Database.Chime_After_Door_Open.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_After_Door_Open.Interior.Delay) == 'number') then
							config.Sound_Database.Chime_After_Door_Open.Interior.Delay else
							0,
						Call_Only = if (typeof(config.Sound_Database.Chime_After_Door_Open) == 'table' and
							typeof(config.Sound_Database.Chime_After_Door_Open.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_After_Door_Open.Interior.Call_Only) == 'boolean') then
							config.Sound_Database.Chime_After_Door_Open.Interior.Call_Only else
							false,
					},
					['Exterior'] = {
						Enable = if (typeof(config.Sound_Database.Chime_After_Door_Open) == 'table' and
							typeof(config.Sound_Database.Chime_After_Door_Open.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_After_Door_Open.Exterior.Enable) == 'boolean') then config.Sound_Database.Chime_After_Door_Open.Exterior.Enable
							elseif (typeof(config.Sound_Database.Chime_After_Door_Open) == 'boolean') then
							config.Sound_Database.Chime_After_Door_Open
							else false,

						Delay = if (typeof(config.Sound_Database.Chime_After_Door_Open) == 'table' and
							typeof(config.Sound_Database.Chime_After_Door_Open.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_After_Door_Open.Exterior.Delay) == 'number') then
							config.Sound_Database.Chime_After_Door_Open.Exterior.Delay else
							0,
						Call_Only = if (typeof(config.Sound_Database.Chime_After_Door_Open) == 'table' and
							typeof(config.Sound_Database.Chime_After_Door_Open.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_After_Door_Open.Exterior.Call_Only) == 'boolean') then
							config.Sound_Database.Chime_After_Door_Open.Exterior.Call_Only else
							false,
					},
				},
				['On_Arrival'] = {
					['Interior'] = {
						Enable = if (typeof(config.Sound_Database.Chime_On_Arrival) == 'table' and
							typeof(config.Sound_Database.Chime_On_Arrival.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Arrival.Interior.Enable) == 'boolean') then config.Sound_Database.Chime_On_Arrival.Interior.Enable
							elseif (typeof(config.Sound_Database.Chime_On_Arrival) == 'boolean') then
							config.Sound_Database.Chime_On_Arrival
							else false,

						Delay = if (typeof(config.Sound_Database.Chime_On_Arrival) == 'table' and
							typeof(config.Sound_Database.Chime_On_Arrival.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Arrival.Interior.Delay) == 'number') then
							config.Sound_Database.Chime_On_Arrival.Interior.Delay else
							0,
						Call_Only = if (typeof(config.Sound_Database.Chime_On_Arrival) == 'table' and
							typeof(config.Sound_Database.Chime_On_Arrival.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Arrival.Interior.Call_Only) == 'boolean') then
							config.Sound_Database.Chime_On_Arrival.Interior.Call_Only else
							false,
					},
					['Exterior'] = {
						Enable = if (typeof(config.Sound_Database.Chime_On_Arrival) == 'table' and
							typeof(config.Sound_Database.Chime_On_Arrival.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Arrival.Exterior.Enable) == 'boolean') then config.Sound_Database.Chime_On_Arrival.Exterior.Enable
							elseif (typeof(config.Sound_Database.Chime_On_Arrival) == 'boolean') then
							config.Sound_Database.Chime_On_Arrival
							else false,

						Delay = if (typeof(config.Sound_Database.Chime_On_Arrival) == 'table' and
							typeof(config.Sound_Database.Chime_On_Arrival.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Arrival.Exterior.Delay) == 'number') then
							config.Sound_Database.Chime_On_Arrival.Exterior.Delay else
							0,
						Call_Only = if (typeof(config.Sound_Database.Chime_On_Arrival) == 'table' and
							typeof(config.Sound_Database.Chime_On_Arrival.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Arrival.Exterior.Call_Only) == 'boolean') then
							config.Sound_Database.Chime_On_Arrival.Exterior.Call_Only else
							false,
					},
				},
				['Floor_Button_Pressed'] = {
					['Interior'] = {
						Enable = if (typeof(config.Sound_Database.Chime_On_Call_Enter) == 'table' and
							typeof(config.Sound_Database.Chime_On_Call_Enter.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Call_Enter.Interior.Enable) == 'boolean') then config.Sound_Database.Chime_On_Call_Enter.Interior.Enable
							elseif (typeof(config.Sound_Database.Chime_On_Call_Enter) == 'boolean') then
							config.Sound_Database.Chime_On_Call_Enter
							else false,

						Delay = if (typeof(config.Sound_Database.Chime_On_Call_Enter) == 'table' and
							typeof(config.Sound_Database.Chime_On_Call_Enter.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Call_Enter.Interior.Delay) == 'number') then
							config.Sound_Database.Chime_On_Call_Enter.Interior.Delay else
							0,
						Call_Only = if (typeof(config.Sound_Database.Chime_On_Call_Enter) == 'table' and
							typeof(config.Sound_Database.Chime_On_Call_Enter.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Call_Enter.Interior.Call_Only) == 'boolean') then
							config.Sound_Database.Chime_On_Call_Enter.Interior.Call_Only else
							false,
					},
					['Exterior'] = {
						Enable = if (typeof(config.Sound_Database.Chime_On_Call_Enter) == 'table' and
							typeof(config.Sound_Database.Chime_On_Call_Enter.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Call_Enter.Exterior.Enable) == 'boolean') then config.Sound_Database.Chime_On_Call_Enter.Exterior.Enable
							elseif (typeof(config.Sound_Database.Chime_On_Call_Enter) == 'boolean') then
							config.Sound_Database.Chime_On_Call_Enter
							else false,

						Delay = if (typeof(config.Sound_Database.Chime_On_Call_Enter) == 'table' and
							typeof(config.Sound_Database.Chime_On_Call_Enter.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Call_Enter.Exterior.Delay) == 'number') then
							config.Sound_Database.Chime_On_Call_Enter.Exterior.Delay else
							0,
						Call_Only = if (typeof(config.Sound_Database.Chime_On_Call_Enter) == 'table' and
							typeof(config.Sound_Database.Chime_On_Call_Enter.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Call_Enter.Exterior.Call_Only) == 'boolean') then
							config.Sound_Database.Chime_On_Call_Enter.Exterior.Call_Only else
							false,
					},
				},
				['New_Call_Input'] = {
					['Interior'] = {
						Enable = if (typeof(config.Sound_Database.New_Call_Input) == 'table' and
							typeof(config.Sound_Database.New_Call_Input.Interior) == 'table' and
							typeof(config.Sound_Database.New_Call_Input.Interior.Enable) == 'boolean') then config.Sound_Database.New_Call_Input.Interior.Enable
							elseif (typeof(config.Sound_Database.New_Call_Input) == 'boolean') then
							config.Sound_Database.New_Call_Input
							else false,

						Delay = if (typeof(config.Sound_Database.New_Call_Input) == 'table' and
							typeof(config.Sound_Database.New_Call_Input.Interior) == 'table' and
							typeof(config.Sound_Database.New_Call_Input.Interior.Delay) == 'number') then
							config.Sound_Database.New_Call_Input.Interior.Delay else
							0,
						Call_Only = if (typeof(config.Sound_Database.New_Call_Input) == 'table' and
							typeof(config.Sound_Database.New_Call_Input.Interior) == 'table' and
							typeof(config.Sound_Database.New_Call_Input.Interior.Call_Only) == 'boolean') then
							config.Sound_Database.New_Call_Input.Interior.Call_Only else
							false,
					},
					['Exterior'] = {
						Enable = if (typeof(config.Sound_Database.New_Call_Input) == 'table' and
							typeof(config.Sound_Database.New_Call_Input.Exterior) == 'table' and
							typeof(config.Sound_Database.New_Call_Input.Exterior.Enable) == 'boolean') then config.Sound_Database.New_Call_Input.Exterior.Enable
							elseif (typeof(config.Sound_Database.New_Call_Input) == 'boolean') then
							config.Sound_Database.New_Call_Input
							else false,

						Delay = if (typeof(config.Sound_Database.New_Call_Input) == 'table' and
							typeof(config.Sound_Database.New_Call_Input.Exterior) == 'table' and
							typeof(config.Sound_Database.New_Call_Input.Exterior.Delay) == 'number') then
							config.Sound_Database.New_Call_Input.Exterior.Delay else
							0,
						Call_Only = if (typeof(config.Sound_Database.New_Call_Input) == 'table' and
							typeof(config.Sound_Database.New_Call_Input.Exterior) == 'table' and
							typeof(config.Sound_Database.New_Call_Input.Exterior.Call_Only) == 'boolean') then
							config.Sound_Database.New_Call_Input.Exterior.Call_Only else
							false,
					},
				},
				['Exterior_Call_Only'] = {
					['Interior'] = {
						Enable = if (typeof(config.Sound_Database.Chime_On_Exterior_Call) == 'table' and
							typeof(config.Sound_Database.Chime_On_Exterior_Call.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Exterior_Call.Interior.Enable) == 'boolean') then config.Sound_Database.Chime_On_Exterior_Call.Interior.Enable
							elseif (typeof(config.Sound_Database.Chime_On_Exterior_Call) == 'boolean') then
							config.Sound_Database.Chime_On_Exterior_Call
							else false,

						Delay = if (typeof(config.Sound_Database.Chime_On_Exterior_Call) == 'table' and
							typeof(config.Sound_Database.Chime_On_Exterior_Call.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Exterior_Call.Interior.Delay) == 'number') then
							config.Sound_Database.Chime_On_Exterior_Call.Interior.Delay else
							0,
						Call_Only = if (typeof(config.Sound_Database.Chime_On_Exterior_Call) == 'table' and
							typeof(config.Sound_Database.Chime_On_Exterior_Call.Interior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Exterior_Call.Interior.Call_Only) == 'boolean') then
							config.Sound_Database.Chime_On_Exterior_Call.Interior.Call_Only else
							false,
					},
					['Exterior'] = {
						Enable = if (typeof(config.Sound_Database.Chime_On_Exterior_Call) == 'table' and
							typeof(config.Sound_Database.Chime_On_Exterior_Call.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Exterior_Call.Exterior.Enable) == 'boolean') then config.Sound_Database.Chime_On_Exterior_Call.Exterior.Enable
							elseif (typeof(config.Sound_Database.Chime_On_Exterior_Call) == 'boolean') then
							config.Sound_Database.Chime_On_Exterior_Call
							else false,

						Delay = if (typeof(config.Sound_Database.Chime_On_Exterior_Call) == 'table' and
							typeof(config.Sound_Database.Chime_On_Exterior_Call.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Exterior_Call.Exterior.Delay) == 'number') then
							config.Sound_Database.Chime_On_Exterior_Call.Exterior.Delay else
							0,
						Call_Only = if (typeof(config.Sound_Database.Chime_On_Exterior_Call) == 'table' and
							typeof(config.Sound_Database.Chime_On_Exterior_Call.Exterior) == 'table' and
							typeof(config.Sound_Database.Chime_On_Exterior_Call.Exterior.Call_Only) == 'boolean') then
							config.Sound_Database.Chime_On_Exterior_Call.Exterior.Call_Only else
							false,
					},
				},

			},

			['Chime_Database'] = {
				['Interior_Up_Chime'] = {['Sound_Id'] = config.Sound_Database.Chime_Database.Up_Chime.Sound_Id, ['Volume'] = config.Sound_Database.Chime_Database.Up_Chime.Volume, ['Pitch'] = config.Sound_Database.Chime_Database.Up_Chime.Pitch},
				['Interior_Down_Chime'] = {['Sound_Id'] = config.Sound_Database.Chime_Database.Down_Chime.Sound_Id, ['Volume'] = config.Sound_Database.Chime_Database.Down_Chime.Volume, ['Pitch'] = config.Sound_Database.Chime_Database.Down_Chime.Pitch},
			},
			['Arrival_Chime_Database'] = {
				['Exterior_Up_Chime'] = {['Sound_Id'] = config.Sound_Database.Arrival_Chime_Database.Up_Chime.Sound_Id, ['Volume'] = config.Sound_Database.Arrival_Chime_Database.Up_Chime.Volume, ['Pitch'] = config.Sound_Database.Arrival_Chime_Database.Up_Chime.Pitch},
				['Exterior_Down_Chime'] = {['Sound_Id'] = config.Sound_Database.Arrival_Chime_Database.Down_Chime.Sound_Id, ['Volume'] = config.Sound_Database.Arrival_Chime_Database.Down_Chime.Volume, ['Pitch'] = config.Sound_Database.Arrival_Chime_Database.Down_Chime.Pitch},
			},
			['Motors'] =
				{
					['Up'] = {
						['Motor_Start_Up'] = {['Sound_Id'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Up.Start.Sound_Id or 0, ['Volume'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Up.Start.Volume or 0, ['Pitch'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Up.Start.Pitch or 1},
						['Motor_Run_Up'] = {['Sound_Id'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Up.Run.Sound_Id or 0, ['Volume'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Up.Run.Volume or 0, ['Pitch'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Up.Run.Pitch or 1},
						['Motor_Stop_Up'] = {['Sound_Id'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Up.Stop.Sound_Id or 0, ['Volume'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Up.Stop.Volume or 0, ['Pitch'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Up.Stop.Pitch or 1},
					},
					['Down'] = {
						['Motor_Start_Down'] = {['Sound_Id'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Down.Start.Sound_Id or 0, ['Volume'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Down.Start.Volume or 0, ['Pitch'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Down.Start.Pitch or 1},
						['Motor_Run_Down'] = {['Sound_Id'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Down.Run.Sound_Id or 0, ['Volume'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Down.Run.Volume or 0, ['Pitch'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Down.Run.Pitch or 1},
						['Motor_Stop_Down'] = {['Sound_Id'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Down.Stop.Sound_Id or 0, ['Volume'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Down.Stop.Volume or 0, ['Pitch'] = config.Sound_Database.Motors and config.Sound_Database.Motors.Down.Stop.Pitch or 1},
					},
				},
			['Doors'] = {
				['Open_Sound'] = {['Sound_Id'] = config.Sound_Database.Doors and config.Sound_Database.Doors.Open_Sound and config.Sound_Database.Doors.Open_Sound.Sound_Id or 0, ['Volume'] = config.Sound_Database.Doors and config.Sound_Database.Doors.Open_Sound and config.Sound_Database.Doors.Open_Sound.Volume or 0, ['Pitch'] = config.Sound_Database.Doors and config.Sound_Database.Doors.Open_Sound and config.Sound_Database.Doors.Open_Sound.Pitch or 0},
				['Close_Sound'] = {['Sound_Id'] = config.Sound_Database.Doors and config.Sound_Database.Doors.Close_Sound and config.Sound_Database.Doors.Close_Sound.Sound_Id or 0, ['Volume'] = config.Sound_Database.Doors and config.Sound_Database.Doors.Close_Sound and config.Sound_Database.Doors.Close_Sound.Volume or 0, ['Pitch'] = config.Sound_Database.Doors and config.Sound_Database.Doors.Close_Sound and config.Sound_Database.Doors.Close_Sound.Pitch or 0},
			},
			['Others'] = {
				['Floor_Pass_Chime'] = {['Sound_Id'] = config.Sound_Database.Others.Floor_Pass_Chime.Sound_Id, ['Volume'] = config.Sound_Database.Others.Floor_Pass_Chime.Volume, ['Pitch'] = config.Sound_Database.Others.Floor_Pass_Chime.Pitch, ['Append']=config.Sound_Database.Others.Floor_Pass_Chime.Append},
				['Nudge_Buzzer'] = {['Sound_Id'] = config.Sound_Database.Others.Nudge_Buzzer.Sound_Id, ['Volume'] = config.Sound_Database.Others.Nudge_Buzzer.Volume, ['Pitch'] = config.Sound_Database.Others.Nudge_Buzzer.Pitch},
				['Alarm'] = {['Sound_Id'] = config.Sound_Database.Others.Alarm.Sound_Id, ['Volume'] = config.Sound_Database.Others.Alarm.Volume, ['Pitch'] = config.Sound_Database.Others.Alarm.Pitch, ['Pause_On_Release'] = config.Sound_Database.Others.Alarm.Pause_On_Release},
				['Alarm_Release'] = {['Sound_Id'] = config.Sound_Database.Others.Alarm_Release and config.Sound_Database.Others.Alarm_Release.Sound_Id or 0, ['Volume'] = config.Sound_Database.Others.Alarm_Release and config.Sound_Database.Others.Alarm_Release.Volume or 0, ['Pitch'] = config.Sound_Database.Others.Alarm_Release and config.Sound_Database.Others.Alarm_Release.Pitch or 0},
				['Button_Beep'] = {['Sound_Id'] = config.Sound_Database.Others.Button_Beep.Sound_Id, ['Volume'] = config.Sound_Database.Others.Button_Beep.Volume, ['Pitch'] = config.Sound_Database.Others.Button_Beep.Pitch},
				['Call_Button_Beep'] = {['Sound_Id'] = config.Sound_Database.Others.Call_Button_Beep and config.Sound_Database.Others.Call_Button_Beep.Sound_Id or config.Sound_Database.Others.Button_Beep.Sound_Id, ['Volume'] = config.Sound_Database.Others.Call_Button_Beep and config.Sound_Database.Others.Call_Button_Beep.Volume or config.Sound_Database.Others.Button_Beep.Volume, ['Pitch'] = config.Sound_Database.Others.Call_Button_Beep and config.Sound_Database.Others.Call_Button_Beep.Pitch or config.Sound_Database.Others.Button_Beep.Pitch},

				['Button_Beep_Sound'] = {
					['Enable'] = config.Sound_Database.Others.Button_Beep_Sound and (config.Sound_Database.Others.Button_Beep_Sound.Enable ~= nil and config.Sound_Database.Others.Button_Beep_Sound.Enable or config.Sound_Database.Others.Button_Beep_Sound == nil and false or config.Sound_Database.Others.Button_Beep_Sound.Enable),
					['Delay'] = config.Sound_Database.Others.Button_Beep_Sound and config.Sound_Database.Others.Button_Beep_Sound.Delay or 0,

					['Sound_Id'] = config.Sound_Database.Others.Button_Beep_Sound and config.Sound_Database.Others.Button_Beep_Sound.Sound_Id or 0,
					['Volume'] = config.Sound_Database.Others.Button_Beep_Sound and config.Sound_Database.Others.Button_Beep_Sound.Volume or 0,
					['Pitch'] = config.Sound_Database.Others.Button_Beep_Sound and config.Sound_Database.Others.Button_Beep_Sound.Pitch or 0,
				},

				['Call_Recognition_Beep'] = {['Sound_Id'] = config.Sound_Database.Others.Call_Recognition_Beep and config.Sound_Database.Others.Call_Recognition_Beep.Sound_Id or 0, ['Volume'] = config.Sound_Database.Others.Call_Recognition_Beep and config.Sound_Database.Others.Call_Recognition_Beep.Volume or 0, ['Pitch'] = config.Sound_Database.Others.Call_Recognition_Beep and config.Sound_Database.Others.Call_Recognition_Beep.Pitch or 1, ['Delay'] = config.Sound_Database.Others.Call_Recognition_Beep and config.Sound_Database.Others.Call_Recognition_Beep.Delay or .1},
				['Door_Obstruction_Signal'] = {},
				['Door_Motor_Sound'] = {},
				['Traveling_Sound'] = {

					['Enable'] = config.Sound_Database.Others.Traveling_Sound and (config.Sound_Database.Others.Traveling_Sound.Enable ~= nil and config.Sound_Database.Others.Traveling_Sound.Enable or config.Sound_Database.Others.Traveling_Sound.Enable == nil and true) or config.Sound_Database.Others.Traveling_Sound == nil and true,
					['Sound_Id'] = config.Sound_Database.Others.Traveling_Sound and config.Sound_Database.Others.Traveling_Sound.Sound_Id or 10419439335,
					['Speed_Factor'] = ((not config.Sound_Database.Others.Traveling_Sound) or (not config.Sound_Database.Others.Traveling_Sound.Speed_Factor)) and 1 or config.Sound_Database.Others.Traveling_Sound.Speed_Factor,
					['Factor_Type'] = ((not config.Sound_Database.Others.Traveling_Sound) or (not config.Sound_Database.Others.Traveling_Sound.Factor_Type)) and 'Absolute_Speed' or 'Travel_Speed_Ratio',
					['Constraints'] = {
						['Volume'] = {
							['Min'] = ((not config.Sound_Database.Others.Traveling_Sound) or (not config.Sound_Database.Others.Traveling_Sound.Constraints) or (not config.Sound_Database.Others.Traveling_Sound.Constraints.Volume) or (not config.Sound_Database.Others.Traveling_Sound.Constraints.Volume.Min)) and 0 or config.Sound_Database.Others.Traveling_Sound.Constraints.Volume.Min,
							['Max'] = ((not config.Sound_Database.Others.Traveling_Sound) or (not config.Sound_Database.Others.Traveling_Sound.Constraints) or (not config.Sound_Database.Others.Traveling_Sound.Constraints.Volume) or (not config.Sound_Database.Others.Traveling_Sound.Constraints.Volume.Max)) and .2 or config.Sound_Database.Others.Traveling_Sound.Constraints.Volume.Max,
						},
						['Pitch'] = {
							['Min'] = ((not config.Sound_Database.Others.Traveling_Sound) or (not config.Sound_Database.Others.Traveling_Sound.Constraints) or (not config.Sound_Database.Others.Traveling_Sound.Constraints.Pitch) or (not config.Sound_Database.Others.Traveling_Sound.Constraints.Pitch.Min)) and 1 or (not config.Sound_Database.Others.Traveling_Sound.Min_Pitch) and 1 or config.Sound_Database.Others.Traveling_Sound.Constraints.Pitch.Min,
							['Max'] = ((not config.Sound_Database.Others.Traveling_Sound) or (not config.Sound_Database.Others.Traveling_Sound.Constraints) or (not config.Sound_Database.Others.Traveling_Sound.Constraints.Pitch) or (not config.Sound_Database.Others.Traveling_Sound.Constraints.Pitch.Max)) and 1 or (not config.Sound_Database.Others.Traveling_Sound.Max_Pitch) and 1 or config.Sound_Database.Others.Traveling_Sound.Constraints.Pitch.Max,
						}
					},

				},
				['Safety_Brake_Sound'] = {},
				['Fire_Recall_Buzzer_Type'] = config.Sound_Database.Others.Fire_Recall_Buzzer_Type or 'Continuous', --[[
				Continuous - Buzzer plays continuously until the elevator recalls to the designated recall floor
				Repeat - Buzzer plays, then pauses, then plays again (like OTIS recall buzzers)
			]]--
				['Elevator_Stop_Beep'] = {
					['Sound_Id'] = config.Sound_Database.Others.Elevator_Stop_Beep and config.Sound_Database.Others.Elevator_Stop_Beep.Sound_Id or 0,
					['Volume'] = config.Sound_Database.Others.Elevator_Stop_Beep and config.Sound_Database.Others.Elevator_Stop_Beep.Volume or 0,
					['Pitch'] = config.Sound_Database.Others.Elevator_Stop_Beep and config.Sound_Database.Others.Elevator_Stop_Beep.Pitch or 0,
					['Enable'] = config.Sound_Database.Others.Elevator_Stop_Beep and config.Sound_Database.Others.Elevator_Stop_Beep.Enable
				},
			},

			['Voice_Config'] = config.Sound_Database.Voice_Config or require(coreScript.Voice_Module.STOCK_VoiceModule),
			['Floor_Pass_Chime_Delay'] = config.Sound_Database.Floor_Pass_Chime_Delay or 0,

		}
	}
	return DefaultConfig
end