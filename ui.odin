package main

import "base:runtime"
import clay "clay-odin"
import "core:fmt"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

UI_BACKGROUND_COLOUR :: clay.Color{57, 116, 153, 255}
UI_FRAME_COLOUR :: clay.Color{188, 192, 194, 100}

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 500

UI_manager :: struct {
	current_time: i32,
	timer_state:  bool,
	reset_time:   bool,
	white_mode:   bool,
}

UI_button_interaction :: proc "c" (
	elementId: clay.ElementId,
	pointerInfo: clay.PointerData,
	userData: rawptr,
) {
	context = runtime.default_context()
	button_manager := cast(^UI_manager)userData

	if pointerInfo.state == clay.PointerDataInteractionState.PressedThisFrame {
		str := strings.string_from_ptr(
			elementId.stringId.chars,
			cast(int)elementId.stringId.length,
		)

		switch str {
		case "start_button":
			button_manager.timer_state = true

		case "stop_button":
			button_manager.timer_state = false

		case "reset_button":
			button_manager.current_time = 0
			button_manager.reset_time = true
		}
	}
}

UI_create_layout :: proc(ctx: ^UI_manager) -> clay.ClayArray(clay.RenderCommand) {
	clay.BeginLayout()

	if clay.UI()(
	{
		id = clay.ID("background_container"),
		layout = {
			sizing = {width = clay.SizingGrow({}), height = clay.SizingGrow({})},
			childGap = 5,
			padding = clay.Padding{left = 5, bottom = 5, top = 5, right = 5},
		},
		backgroundColor = UI_BACKGROUND_COLOUR,
	},
	) {
		if clay.UI()(
		{
			id = clay.ID("timer_container"),
			layout = {
				layoutDirection = .TopToBottom,
				sizing = {width = clay.SizingPercent(0.8), height = clay.SizingGrow({})},
				childGap = 5,
			},
			backgroundColor = clay.Color{0, 0, 0, 0},
		},
		) {
			if clay.UI()(
			{
				id = clay.ID("timer_display"),
				layout = {
					sizing = {width = clay.SizingGrow({}), height = clay.SizingPercent(0.65)},
					padding = clay.Padding{left = 190, top = 110},
				},
				backgroundColor = UI_FRAME_COLOUR,
				cornerRadius = clay.CornerRadiusAll(0.3),
			},
			) {
				hours: i32 = ctx.current_time / 3600
				minutes: i32 = (ctx.current_time - (hours * 3600)) / 60
				seconds: i32 = ctx.current_time - ((hours * 3600) + (minutes * 60))

				time_str := fmt.tprintf("0%v:0%v:0%v", hours, minutes, seconds)

				clay.Text(
					time_str,
					clay.TextConfig({fontSize = 100, textColor = clay.Color{0, 0, 0, 0}}),
				)
			}

			if clay.UI()(
			{
				id = clay.ID("timer_interface"),
				layout = {
					sizing = {width = clay.SizingGrow({}), height = clay.SizingPercent(0.35)},
					padding = clay.PaddingAll(40),
					childGap = 20,
				},
				backgroundColor = UI_FRAME_COLOUR,
				cornerRadius = clay.CornerRadiusAll(0.2),
			},
			) {
				if clay.UI()(
				{
					id = clay.ID("start_button"),
					layout = {
						sizing = {width = clay.SizingPercent(0.5), height = clay.SizingGrow({})},
						padding = clay.Padding{left = 60, right = 40, top = 40, bottom = 40},
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
						sizing = {width = clay.SizingPercent(0.5), height = clay.SizingGrow({})},
						padding = clay.Padding{left = 80, right = 40, top = 20, bottom = 40},
					},
					backgroundColor = clay.Color{199, 30, 30, 255},
					cornerRadius = clay.CornerRadiusAll(0.3),
				},
				) {
					clay.OnHover(UI_button_interaction, ctx)
					clay.Text(
						"Stop",
						clay.TextConfig({fontSize = 50, textColor = clay.Color{0, 0, 0, 0}}),
					)
				}
			}
		}

		if clay.UI()(
		{
			id = clay.ID("display_swap_container"),
			layout = {
				layoutDirection = .TopToBottom,
				sizing = {width = clay.SizingGrow({}), height = clay.SizingGrow({})},
				childGap = 235,
				padding = clay.Padding{top = 20, bottom = 20},
			},
			backgroundColor = clay.Color{0, 0, 0, 0},
			cornerRadius = clay.CornerRadiusAll(0.3),
		},
		) {
			if clay.UI()(
			{
				id = clay.ID("display_swap_button"),
				layout = {
					sizing = {width = clay.SizingGrow({}), height = clay.SizingPercent(0.5)},
				},
				backgroundColor = clay.Color{0, 0, 0, 255},
				cornerRadius = clay.CornerRadiusAll(0.3),
			},
			) {}

			if clay.UI()(
			{
				id = clay.ID("reset_button"),
				layout = {
					sizing = {width = clay.SizingGrow({}), height = clay.SizingPercent(0.4)},
					padding = clay.Padding{left = 40, top = 25},
				},
				backgroundColor = clay.Color{78, 82, 79, 255},
				cornerRadius = clay.CornerRadiusAll(0.3),
			},
			) {
				clay.OnHover(UI_button_interaction, ctx)
				clay.Text(
					"Reset",
					clay.TextConfig({fontSize = 40, textColor = clay.Color{252, 255, 253, 255}}),
				)
			}
		}
	}

	render_commands: clay.ClayArray(clay.RenderCommand) = clay.EndLayout()
	return render_commands
}
