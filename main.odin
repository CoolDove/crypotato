package main

import stb_image "vendor:stb/image"
import "core:os"
import "core:fmt"
import "core:runtime"
import "core:strings"
import "core:bytes"
import "core:path/filepath"

main :: proc() {
    if len(os.args) == 3 {
        write(os.args[1], os.args[2])
    } else if len(os.args) == 2 {
        msg := read(os.args[1])
        fmt.printf("Secret message:\n{}\n", msg)
    } else {
        fmt.printf("Invalid args.\n")
    }
}


read :: proc(input_path : string) -> string {
    png_raw, ok := os.read_entire_file(input_path)
    defer delete(png_raw)
    
    if !ok {
        fmt.printf("Failed to load png file: {}.\n", input_path)
        return ""
    }

    width, height, channel : i32

    pixels := stb_image.load_from_memory(raw_data(png_raw), cast(i32)len(png_raw), &width, &height, &channel, 4)
    defer stb_image.image_free(pixels)

    if pixels != nil {
        sb : strings.Builder
        strings.builder_init(&sb)
        defer strings.builder_destroy(&sb)
        
        using strings

        current :u8= 0
        bit_pos :u8= 0
        finish: for x in 0..<width {
            for y in 0..<height {
                pidx := y * width + x
                current = current | ((pixels[pidx] & 0b0000_0001)<<bit_pos)
                bit_pos += 1
                if bit_pos >= 8 {
                    bit_pos = 0
                    if current == 0 {
                        break finish
                    } else {
                        write_byte(&sb, current)
                        current = 0
                    }
                }
            }
        }
        return to_string(sb)
    }
    return ""
}

write :: proc(input_path : string, message : string) {
    png_raw, ok := os.read_entire_file(input_path)
    defer delete(png_raw)

    // Make a cstring.
    buffer := make_slice([]u8, len(message)+1)
    defer delete(buffer)
    for i in 0..<len(message) {
        buffer[i] = message[i]
    }
    buffer[len(buffer)-1]=0

    msg := buffer

    if !ok {
        fmt.printf("Failed to load png file: {}.\n", input_path)
        return
    }

    width, height, channel : i32

    pixels := stb_image.load_from_memory(raw_data(png_raw), cast(i32)len(png_raw), &width, &height, &channel, 4)
    defer stb_image.image_free(pixels)

    if pixels != nil {
        fmt.printf("File is loaded.\nWrite message...\n")
        {// Writing...
            msg_idx :i32= 0
            current := msg[msg_idx]
            bit_pos :u8= 0
            finish: for x in 0..<width {
                for y in 0..<height {
                    pidx := y * width + x
                    pixel := pixels[pidx]
                    pixel = (pixel & 0b1111_1110) | ((current>>bit_pos)&0b0000_0001)
                    pixels[pidx] = pixel

                    bit_pos += 1
                    if bit_pos >= 8 {
                        bit_pos = 0
                        msg_idx += 1
                        if msg_idx >= cast(i32)len(msg) do break finish
                        current = msg[msg_idx]
                    }
                }
            }
        }

        {// Save the image.
            ext := filepath.ext(input_path)
            save_path := fmt.aprintf("{}_cry.png", input_path[:len(input_path)-len(ext)])
            defer delete(save_path)

            csave_path := strings.clone_to_cstring(save_path)
            defer delete(csave_path)
            fmt.printf("Save path: {}", csave_path)
            stb_image.write_png(strings.unsafe_string_to_cstring(save_path), width, height, 4, pixels, 4 * width)
        }
    }
}

DOVE_WORK :string: `A DOVE WORK`