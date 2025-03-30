package clock_app

import "base:runtime"
import clay "clay-odin"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

UI_WHITEMODE_BACKGROUND :: clay.Color{237, 235, 230, 255}
UI_WHITEMODE_FRAME :: clay.Color{171, 179, 173, 100}

UI_DARKMODE_BACKGROUND :: clay.Color{77, 76, 74, 255}
UI_DARKMODE_FRAME :: clay.Color{107, 106, 103, 100}

SCREEN_WIDTH :: 600
SCREEN_HEIGHT :: 400

UI_state :: enum {
	STOPWATCH,
	TIMER,
}

UI_ctx :: struct {
	current_screen:  UI_state,
	current_time:    i32,
	timer_changed:   bool,
	start_stopwatch: bool,
	start_timer:     bool,
	reset_time:      bool,
	white_mode:      bool,
	textures:        [2]rl.Texture2D,
}

UI_button_interaction :: proc "c" (
	elementId: clay.ElementId,
	pointerInfo: clay.PointerData,
	userData: rawptr,
) {
	context = runtime.default_context()
	button_ctx := cast(^UI_ctx)userData

	if pointerInfo.state == clay.PointerDataInteractionState.PressedThisFrame {
		button_id := strings.string_from_ptr(
			elementId.stringId.chars,
			cast(int)elementId.stringId.length,
		)

		switch button_id {
		// stopwatch buttons
		case "start_button":
			button_ctx.start_stopwatch = true

		case "stop_button":
			button_ctx.start_stopwatch = false

		case "reset_button":
			button_ctx.current_time = 0
			button_ctx.reset_time = true

		case "colour_swap_button":
			button_ctx.white_mode = !button_ctx.white_mode

		// timer buttons
		case "big_pos_inc":
			button_ctx.current_time += 60
			button_ctx.timer_changed = true

		case "big_neg_dec":
			button_ctx.current_time -= 60
			if button_ctx.current_time < 0 do button_ctx.current_time = 0
			button_ctx.timer_changed = true

		case "small_pos_inc":
			button_ctx.current_time += 30
			button_ctx.timer_changed = true

		case "small_neg_dec":
			button_ctx.current_time -= 30
			if button_ctx.current_time < 0 do button_ctx.current_time = 0
			button_ctx.timer_changed = true
		}
	}
}

UI_create_stopwatch_layout :: proc(ctx: ^UI_ctx) -> clay.ClayArray(clay.RenderCommand) {
	clay.BeginLayout()

	if clay.UI()(
	{
		id = clay.ID("background_container"),
		layout = {
			sizing = {width = clay.SizingGrow({}), height = clay.SizingGrow({})},
			childGap = 5,
			padding = clay.Padding{left = 5, bottom = 5, top = 5, right = 5},
		},
		backgroundColor = (ctx.white_mode ? UI_WHITEMODE_BACKGROUND : UI_DARKMODE_BACKGROUND),
	},
	) {
		if clay.UI()(
		{
			id = clay.ID("timer_container"),
			layout = {
				layoutDirection = .TopToBottom,
				sizing = {width = clay.SizingPercent(1), height = clay.SizingGrow({})},
				childGap = 5,
			},
			backgroundColor = clay.Color{0, 0, 0, 0},
		},
		) {
			if clay.UI()(
			{
				id = clay.ID("timer_display"),
				layout = {
					layoutDirection = .TopToBottom,
					sizing = {width = clay.SizingGrow({}), height = clay.SizingPercent(0.65)},
				},
				backgroundColor = (ctx.white_mode ? UI_WHITEMODE_FRAME : UI_DARKMODE_FRAME),
				cornerRadius = clay.CornerRadiusAll(0.3),
			},
			) {
				hours := (ctx.current_time / 3600)
				minutes := (ctx.current_time - (hours * 3600)) / 60
				seconds := ctx.current_time - ((hours * 3600) + (minutes * 60))

				display_hours :=
					fmt.tprintf("%v", hours) if hours >= 10 else fmt.tprintf("0%v", hours)
				display_minutes :=
					fmt.tprintf("%v", minutes) if minutes >= 10 else fmt.tprintf("0%v", minutes)
				display_seconds :=
					fmt.tprintf("%v", seconds) if seconds >= 10 else fmt.tprintf("0%v", seconds)

				time_str := fmt.tprintf(
					"%v:%v:%v",
					display_hours,
					display_minutes,
					display_seconds,
				)

				if clay.UI()(
				{
					id = clay.ID("colour_swap_button"),
					layout = {
						sizing = {
							width = clay.SizingPercent(0.15),
							height = clay.SizingPercent(0.15),
						},
					},
					image = {
						imageData = (ctx.white_mode ? &ctx.textures[0] : &ctx.textures[1]),
						sourceDimensions = {150, 150},
					},
				},
				) {
					clay.OnHover(UI_button_interaction, ctx)
				}

				if clay.UI()(
				{
					id = clay.ID("timer_text_container"),
					layout = {
						sizing = {width = clay.SizingGrow({}), height = clay.SizingGrow({})},
						padding = clay.Padding {
							left = SCREEN_WIDTH * 0.3,
							top = SCREEN_HEIGHT * 0.1,
						},
					},
					cornerRadius = clay.CornerRadiusAll(0.3),
				},
				) {
					clay.Text(
						time_str,
						clay.TextConfig({fontSize = 100, textColor = clay.Color{0, 0, 0, 0}}),
					)
				}
			}

			if clay.UI()(
			{
				id = clay.ID("timer_interface"),
				layout = {
					sizing = {width = clay.SizingGrow({}), height = clay.SizingPercent(0.35)},
					padding = clay.PaddingAll(40),
					childGap = 20,
				},
				backgroundColor = (ctx.white_mode ? UI_WHITEMODE_FRAME : UI_DARKMODE_FRAME),
				cornerRadius = clay.CornerRadiusAll(0.2),
			},
			) {
				if clay.UI()(
				{
					id = clay.ID("start_button"),
					layout = {
						sizing = {width = clay.SizingPercent(0.33), height = clay.SizingGrow({})},
						padding = clay.Padding {
							left = SCREEN_WIDTH * 0.08,
							top = SCREEN_HEIGHT * 0.02,
						},
					},
					backgroundColor = clay.Color{85, 201, 116, 255},
					cornerRadius = clay.CornerRadiusAll(0.3),
				},
				) {
					clay.OnHover(UI_button_interaction, ctx)
					clay.Text(
						"Start",
						clay.TextConfig({fontSize = 40, textColor = clay.Color{0, 0, 0, 0}}),
					)
				}

				if clay.UI()(
				{
					id = clay.ID("stop_button"),
					layout = {
						sizing = {width = clay.SizingPercent(0.33), height = clay.SizingGrow({})},
						padding = clay.Padding {
							left = SCREEN_WIDTH * 0.08,
							top = SCREEN_HEIGHT * 0.02,
						},
					},
					backgroundColor = clay.Color{199, 30, 30, 255},
					cornerRadius = clay.CornerRadiusAll(0.3),
				},
				) {
					clay.OnHover(UI_button_interaction, ctx)
					clay.Text(
						"Stop",
						clay.TextConfig({fontSize = 40, textColor = clay.Color{0, 0, 0, 0}}),
					)
				}

				if clay.UI()(
				{
					id = clay.ID("reset_button"),
					layout = {
						sizing = {width = clay.SizingPercent(0.33), height = clay.SizingGrow({})},
						padding = clay.Padding {
							left = SCREEN_WIDTH * 0.075,
							top = SCREEN_HEIGHT * 0.02,
						},
					},
					backgroundColor = clay.Color{78, 82, 79, 255},
					cornerRadius = clay.CornerRadiusAll(0.3),
				},
				) {
					clay.OnHover(UI_button_interaction, ctx)
					clay.Text(
						"Reset",
						clay.TextConfig(
							{fontSize = 40, textColor = clay.Color{252, 255, 253, 255}},
						),
					)
				}
			}
		}
	}

	render_commands: clay.ClayArray(clay.RenderCommand) = clay.EndLayout()
	return render_commands
}

_UI_timer_shortcut_button :: proc(ctx: ^UI_ctx, id, length: string) {
	if clay.UI()(
	{
		id = clay.ID(id),
		layout = {sizing = {width = clay.SizingGrow({}), height = clay.SizingPercent(0.18)}},
		backgroundColor = clay.Color{138, 137, 135, 255},
		cornerRadius = clay.CornerRadiusAll(0.3),
	},
	) {
		clay.OnHover(UI_button_interaction, ctx)
		clay.Text(
			length,
			clay.TextConfig({fontSize = 20, textColor = clay.Color{252, 255, 253, 255}}),
		)
	}
}

UI_create_timer_layout :: proc(ctx: ^UI_ctx) -> clay.ClayArray(clay.RenderCommand) {
	clay.BeginLayout()

	if clay.UI()(
	{
		id = clay.ID("background_container"),
		layout = {
			sizing = {width = clay.SizingGrow({}), height = clay.SizingGrow({})},
			childGap = 5,
			padding = clay.Padding{left = 5, bottom = 5, top = 5, right = 5},
		},
		backgroundColor = (ctx.white_mode ? UI_WHITEMODE_BACKGROUND : UI_DARKMODE_BACKGROUND),
	},
	) {
		if clay.UI()(
		{
			id = clay.ID("timer_container"),
			layout = {
				layoutDirection = .TopToBottom,
				sizing = {width = clay.SizingPercent(0.75), height = clay.SizingGrow({})},
				childGap = 5,
			},
			backgroundColor = clay.Color{0, 0, 0, 0},
		},
		) {
			if clay.UI()(
			{
				id = clay.ID("timer_display"),
				layout = {
					layoutDirection = .TopToBottom,
					sizing = {width = clay.SizingGrow({}), height = clay.SizingGrow({})},
					childGap = 5,
				},
				backgroundColor = (ctx.white_mode ? UI_WHITEMODE_FRAME : UI_DARKMODE_FRAME),
				cornerRadius = clay.CornerRadiusAll(0.3),
			},
			) {
				hours := (ctx.current_time / 3600)
				minutes := (ctx.current_time - (hours * 3600)) / 60
				seconds := ctx.current_time - ((hours * 3600) + (minutes * 60))

				display_hours :=
					fmt.tprintf("%v", hours) if hours >= 10 else fmt.tprintf("0%v", hours)
				display_minutes :=
					fmt.tprintf("%v", minutes) if minutes >= 10 else fmt.tprintf("0%v", minutes)
				display_seconds :=
					fmt.tprintf("%v", seconds) if seconds >= 10 else fmt.tprintf("0%v", seconds)

				time_str := fmt.tprintf(
					"%v:%v:%v",
					display_hours,
					display_minutes,
					display_seconds,
				)

				if clay.UI()(
				{
					id = clay.ID("timer_text_container"),
					layout = {
						sizing = {width = clay.SizingGrow({}), height = clay.SizingPercent(0.60)},
						padding = clay.Padding {
							left = SCREEN_WIDTH * 0.15,
							top = SCREEN_HEIGHT * 0.19,
						},
					},
					cornerRadius = clay.CornerRadiusAll(0.3),
				},
				) {
					clay.Text(
						time_str,
						clay.TextConfig({fontSize = 100, textColor = clay.Color{0, 0, 0, 0}}),
					)
				}

				if clay.UI()(
				{
					id = clay.ID("big_inc_container"),
					layout = {
						sizing = {width = clay.SizingGrow({}), height = clay.SizingPercent(0.15)},
						childGap = 10,
						childAlignment = {x = .Center, y = .Center},
					},
				},
				) {
					if clay.UI()(
					{
						id = clay.ID("big_pos_inc"),
						layout = {
							sizing = {
								width = clay.SizingPercent(0.40),
								height = clay.SizingGrow({}),
							},
						},
						backgroundColor = clay.Color{85, 201, 116, 255},
						cornerRadius = clay.CornerRadiusAll(0.4),
					},
					) {
						clay.OnHover(UI_button_interaction, ctx)
					}

					if clay.UI()(
					{
						id = clay.ID("big_neg_dec"),
						layout = {
							sizing = {
								width = clay.SizingPercent(0.40),
								height = clay.SizingGrow({}),
							},
						},
						backgroundColor = clay.Color{199, 30, 30, 255},
						cornerRadius = clay.CornerRadiusAll(0.4),
					},
					) {
						clay.OnHover(UI_button_interaction, ctx)
					}
				}

				if clay.UI()(
				{
					id = clay.ID("small_inc_container"),
					layout = {
						sizing = {width = clay.SizingGrow({}), height = clay.SizingPercent(0.15)},
						childGap = 10,
						childAlignment = {x = .Center, y = .Center},
					},
				},
				) {
					if clay.UI()(
					{
						id = clay.ID("small_pos_inc"),
						layout = {
							sizing = {
								width = clay.SizingPercent(0.30),
								height = clay.SizingGrow({}),
							},
						},
						backgroundColor = clay.Color{85, 201, 116, 255},
						cornerRadius = clay.CornerRadiusAll(0.5),
					},
					) {
						clay.OnHover(UI_button_interaction, ctx)
					}

					if clay.UI()(
					{
						id = clay.ID("small_neg_dec"),
						layout = {
							sizing = {
								width = clay.SizingPercent(0.30),
								height = clay.SizingGrow({}),
							},
						},
						backgroundColor = clay.Color{199, 30, 30, 255},
						cornerRadius = clay.CornerRadiusAll(0.5),
					},
					) {
						clay.OnHover(UI_button_interaction, ctx)
					}
				}
			}
		}

		if clay.UI()(
		{
			layout = {
				layoutDirection = .TopToBottom,
				sizing = {width = clay.SizingPercent(0.25), height = clay.SizingGrow({})},
				childGap = 5,
				padding = clay.Padding{top = 10, bottom = 10, right = 5, left = 5},
			},
			backgroundColor = ctx.white_mode ? UI_WHITEMODE_FRAME : UI_DARKMODE_FRAME,
			cornerRadius = clay.CornerRadiusAll(0.3),
		},
		) {
			// notes for another time; convenient times are 10, 5, 3 and 1 minute(s)
			// this'll also have the start button, so 5 buttons in total.
			shortcut_list := [4]string {
				"Ten Minutes",
				"Five Minutes",
				"Three Minutes",
				"One Minute",
			}
			shortcut_ids := [4]string{"ten_mins", "five_mins", "three_mins", "one_min"}

			for shortcut_name, i in shortcut_list {
				_UI_timer_shortcut_button(ctx, shortcut_ids[i], shortcut_name)
			}
		}
	}

	render_commands: clay.ClayArray(clay.RenderCommand) = clay.EndLayout()
	return render_commands
}
