package main

import clay "clay-odin"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

UI_BACKGROUND_COLOUR :: clay.Color{57, 116, 153, 255}
UI_FRAME_COLOUR :: clay.Color{188, 192, 194, 100}

SCREEN_WIDTH :: 1000
SCREEN_HEIGHT :: 500

UI_create_layout :: proc() -> clay.ClayArray(clay.RenderCommand) {
	clay.BeginLayout()

	if clay.UI()(
	{
		id = clay.ID("background_container"),
		layout = {
			sizing = {width = clay.SizingGrow({}), height = clay.SizingGrow({})},
			childGap = 5,
			padding = clay.Padding{left = 5, bottom = 5, top = 5},
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
				childGap = 10,
			},
			backgroundColor = clay.Color{0, 0, 0, 0},
		},
		) {
			if clay.UI()(
			{
				id = clay.ID("timer_display"),
				layout = {
					sizing = {width = clay.SizingGrow({}), height = clay.SizingPercent(0.65)},
					padding = clay.Padding{left = 125, top = 125},
				},
				backgroundColor = UI_FRAME_COLOUR,
				cornerRadius = clay.CornerRadiusAll(0.4),
			},
			) {
				clay.Text(
					"Time, coming soon...",
					clay.TextConfig({fontSize = 50, textColor = clay.Color{0, 0, 0, 0}}),
				)
			}

			if clay.UI()(
			{
				id = clay.ID("timer_interface"),
				layout = {
					sizing = {width = clay.SizingGrow({}), height = clay.SizingPercent(0.35)},
				},
				backgroundColor = UI_FRAME_COLOUR,
				cornerRadius = clay.CornerRadiusAll(0.4),
			},
			) {}
		}
	}

	render_commands: clay.ClayArray(clay.RenderCommand) = clay.EndLayout()
	return render_commands
}
