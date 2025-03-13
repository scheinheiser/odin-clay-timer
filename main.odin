package main

import clay "clay-odin"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

raylibFont :: struct {
	fontId: u16,
	font:   rl.Font,
}

raylibFonts := [10]raylibFont{}

error_handler :: proc "c" (errorData: clay.ErrorData) {
	//fmt.eprintf("[ERROR] Error Occurred: %v\n", errorData.Clay_String)
}

measure_text :: proc "c" (
	text: clay.StringSlice,
	config: ^clay.TextElementConfig,
	userData: rawptr,
) -> clay.Dimensions {
	return {width = f32(text.length * i32(config.fontSize)), height = f32(config.fontSize)}
}

main :: proc() {
	min_memory_size: u32 = clay.MinMemorySize()
	memory := make([^]u8, min_memory_size)
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(cast(uint)min_memory_size, memory)

	clay.Initialize(arena, {width = 500, height = 500}, {handler = error_handler})
	clay.SetMeasureTextFunction(measure_text, nil)

	render_commands := create_layout()
	for i in 0 ..< i32(render_commands.length) {
		rc := clay.RenderCommandArray_Get(&render_commands, i)
		boundingBox := rc.boundingBox

		#partial switch rc.commandType {
		case .Text:
			config := rc.renderData.text

			text := string(config.stringContents.chars[:config.stringContents.length])
			cloned_string := strings.clone_to_cstring(text)
			fontToUse: rl.Font = raylibFonts[config.fontId].font
			rl.DrawTextEx(
				fontToUse,
				cloned_string,
				rl.Vector2{boundingBox.x, boundingBox.y},
				cast(f32)config.fontSize,
				cast(f32)config.letterSpacing,
				rl.Color {
					cast(u8)config.textColor.r,
					cast(u8)config.textColor.g,
					cast(u8)config.textColor.b,
					cast(u8)config.textColor.a,
				},
			)

		case .Rectangle:
			config := rc.renderData.rectangle
			fmt.println("hi")
			rl.DrawRectangle(
				cast(i32)rc.boundingBox.x,
				cast(i32)rc.boundingBox.y,
				cast(i32)rc.boundingBox.width,
				cast(i32)rc.boundingBox.height,
				rl.Color {
					cast(u8)config.backgroundColor.r,
					cast(u8)config.backgroundColor.g,
					cast(u8)config.backgroundColor.b,
					cast(u8)config.backgroundColor.a,
				},
			)
		}
	}
}

create_layout :: proc() -> clay.ClayArray(clay.RenderCommand) {
	clay.BeginLayout()

	if clay.UI()(
	{
		id = clay.ID("outercontainer"),
		layout = {
			sizing = {width = clay.SizingGrow({}), height = clay.SizingGrow({})},
			childGap = 10,
		},
		backgroundColor = {250, 250, 250, 255},
	},
	) {
		clay.Text(
			"Hello World!",
			clay.TextConfig({textColor = clay.Color{0, 0, 0, 0}, fontSize = 16}),
		)
	}

	render_commands: clay.ClayArray(clay.RenderCommand) = clay.EndLayout()
	return render_commands
}
