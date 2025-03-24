package main

import clay "clay-odin"
import "core:fmt"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

error_handler :: proc "c" (errorData: clay.ErrorData) {}

measure_text :: proc "c" (
	text: clay.StringSlice,
	config: ^clay.TextElementConfig,
	userData: rawptr,
) -> clay.Dimensions {
	return {width = f32(text.length * i32(config.fontSize)), height = f32(config.fontSize)}
}

clay_to_raylib_colour :: proc(clay_colour: clay.Color) -> rl.Color {
	return rl.Color {
		cast(u8)clay_colour.r,
		cast(u8)clay_colour.g,
		cast(u8)clay_colour.b,
		cast(u8)clay_colour.a,
	}
}

main :: proc() {
	min_memory_size: u32 = clay.MinMemorySize()
	memory := make([^]u8, min_memory_size)
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(cast(uint)min_memory_size, memory)
	ctx: UI_manager

	clay.Initialize(
		arena,
		{width = SCREEN_WIDTH, height = SCREEN_HEIGHT},
		{handler = error_handler},
	)
	clay.SetMeasureTextFunction(measure_text, nil)

	rl.SetTargetFPS(60)

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "oaxaca")
	defer rl.CloseWindow()

	font: rl.Font = rl.LoadFontEx("resources/OpenSans_SemiCondensed-Medium.ttf", 50, nil, 0)
	defer rl.UnloadFont(font)
	ctx.current_time = 0

	render_commands := UI_create_layout(&ctx)
	frame_counter := 0

	fmt.printf("time -> %v\n", time.now())

	for !rl.WindowShouldClose() {
		clay.SetPointerState(
			transmute(clay.Vector2)rl.GetMousePosition(),
			rl.IsMouseButtonDown(.LEFT),
		)

		frame_counter += 1
		if frame_counter > 60 do frame_counter = 0

		if ctx.timer_state {
			if frame_counter % 60 == 0 && frame_counter != 0 {
				ctx.current_time += 1
				render_commands = UI_create_layout(&ctx)
			}
		}

		if ctx.reset_time {
			render_commands = UI_create_layout(&ctx)
			ctx.reset_time = false
		}

		rl.BeginDrawing()
		render_UI(font, &render_commands)
		rl.EndDrawing()
	}
}

render_UI :: proc(font: rl.Font, render_commands: ^clay.ClayArray(clay.RenderCommand)) {
	for i in 0 ..< i32(render_commands.length) {
		rc := clay.RenderCommandArray_Get(render_commands, i)

		#partial switch rc.commandType {
		case .None:
			{}
		case .Text:
			config := rc.renderData.text
			text := string(config.stringContents.chars[:config.stringContents.length])
			cloned_string := strings.clone_to_cstring(text)

			rl.DrawTextEx(
				font,
				cloned_string,
				rl.Vector2{cast(f32)rc.boundingBox.x, cast(f32)rc.boundingBox.y},
				cast(f32)config.fontSize,
				cast(f32)config.letterSpacing,
				rl.BLACK,
			)

		case .Rectangle:
			config := rc.renderData.rectangle
			if config.cornerRadius.topRight > 0 {
				rl.DrawRectangleRounded(
					rl.Rectangle {
						cast(f32)rc.boundingBox.x,
						cast(f32)rc.boundingBox.y,
						cast(f32)rc.boundingBox.width,
						cast(f32)rc.boundingBox.height,
					},
					cast(f32)config.cornerRadius.topRight,
					10,
					clay_to_raylib_colour(config.backgroundColor),
				)
			} else {
				rl.DrawRectangle(
					cast(i32)rc.boundingBox.x,
					cast(i32)rc.boundingBox.y,
					cast(i32)rc.boundingBox.width,
					cast(i32)rc.boundingBox.height,
					clay_to_raylib_colour(config.backgroundColor),
				)
			}

		case .ScissorStart:
			config := rc.renderData.rectangle
			rl.BeginScissorMode(
				cast(i32)rc.boundingBox.x,
				cast(i32)rc.boundingBox.y,
				cast(i32)rc.boundingBox.width,
				cast(i32)rc.boundingBox.height,
			)

		case .ScissorEnd:
			rl.EndScissorMode()
		}
	}
}
