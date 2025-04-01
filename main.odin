package clock_app

import "base:runtime"
import clay "clay-odin"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

error_handler :: proc "c" (errorData: clay.ErrorData) {
	context = runtime.default_context()
	error_text := strings.string_from_ptr(
		errorData.errorText.chars,
		cast(int)errorData.errorText.length,
	)

	fmt.eprintfln("A Clay Error was detected: %v", error_text)
}

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
	ctx: UI_ctx

	clay.Initialize(
		arena,
		{width = SCREEN_WIDTH, height = SCREEN_HEIGHT},
		{handler = error_handler},
	)
	clay.SetMeasureTextFunction(measure_text, nil)

	rl.SetTargetFPS(60)
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Odin Timer")

	font: rl.Font = rl.LoadFontEx("resources/OpenSans_SemiCondensed-Medium.ttf", 200, nil, 0)

	darkmode_image: rl.Image = rl.LoadImage("resources/moon_icon.png")
	whitemode_image: rl.Image = rl.LoadImage("resources/sun_icon.png")

	darkmode_icon := rl.LoadTextureFromImage(darkmode_image)
	whitemode_icon := rl.LoadTextureFromImage(whitemode_image)

	defer {
		rl.CloseWindow()

		rl.UnloadFont(font)
		rl.UnloadImage(darkmode_image)
		rl.UnloadImage(whitemode_image)

		rl.UnloadTexture(darkmode_icon)
		rl.UnloadTexture(whitemode_icon)
	}

	ctx.textures = [2]rl.Texture2D{darkmode_icon, whitemode_icon}
	ctx.current_time = 0
	ctx.white_mode = true
	ctx.current_screen = UI_state.STOPWATCH

	render_commands :=
		ctx.current_screen == .STOPWATCH ? UI_create_stopwatch_layout(&ctx) : UI_create_timer_layout(&ctx)
	frame_counter := 0
	curr_mode := ctx.white_mode
	curr_time := ctx.current_time

	for !rl.WindowShouldClose() {
		clay.SetPointerState(
			transmute(clay.Vector2)rl.GetMousePosition(),
			rl.IsMouseButtonDown(.LEFT),
		)

		if rl.IsKeyPressed(rl.KeyboardKey.S) {
			switch ctx.current_screen {
			case .STOPWATCH:
				ctx.current_screen = .TIMER
				ctx.current_time = 0
				render_commands = UI_create_timer_layout(&ctx)

			case .TIMER:
				ctx.current_screen = .STOPWATCH
				ctx.current_time = 0
				render_commands = UI_create_stopwatch_layout(&ctx)
			}
		}

		frame_counter += 1
		if frame_counter > 60 do frame_counter = 0

		switch ctx.current_screen {
		case .STOPWATCH:
			if ctx.start_stopwatch {
				if frame_counter % 60 == 0 && frame_counter != 0 {
					ctx.current_time += 1
					render_commands = UI_create_stopwatch_layout(&ctx)
				}
			}

			if ctx.white_mode != curr_mode {
				curr_mode = ctx.white_mode
				render_commands = UI_create_stopwatch_layout(&ctx)
			}

			if ctx.reset_stopwatch {
				render_commands = UI_create_stopwatch_layout(&ctx)
				ctx.reset_stopwatch = false
			}

		case .TIMER:
			if ctx.start_timer {
				if frame_counter % 60 == 0 && frame_counter != 0 {
					ctx.current_time -= 1
					render_commands = UI_create_timer_layout(&ctx)
				}
			}

			if ctx.current_time != curr_time {
				render_commands = UI_create_timer_layout(&ctx)
				curr_time = ctx.current_time
			}
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

		case .Image:
			config := rc.renderData.image
			background_colour := config.backgroundColor
			position_vec := rl.Vector2{rc.boundingBox.x, rc.boundingBox.y}

			if config.backgroundColor.rgba == 0 {
				background_colour = {255, 255, 255, 255}
			}

			image_texture := cast(^rl.Texture2D)config.imageData
			rl.DrawTextureEx(
				image_texture^,
				position_vec,
				0,
				rc.boundingBox.width / cast(f32)config.sourceDimensions.width,
				clay_to_raylib_colour(background_colour),
			)
		}
	}
}
