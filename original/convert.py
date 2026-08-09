from PIL import Image
import numpy as np

# Apple II HGR line interleaving formula
def get_hgr_line_offset(y):
    return ((y % 8) * 0x0400) + (((y // 8) % 8) * 0x0080) + ((y // 64) * 0x0028)

def convert_to_hgr(image_path, output_path="PAINTER.HGR"):
    # Load image and resize to standard Apple II HGR resolution (280x192)
    img = Image.open(image_path).convert("RGB")
    img = img.resize((280, 192), Image.Resampling.LANCZOS)
    pixels = np.array(img, dtype=int)

    # 8KB buffer initialized to zero
    hgr_buffer = bytearray(8192)

    # Reference RGB colors for HGR mapping
    # Note: Even X = Purple/Blue, Odd X = Green/Orange
    COLOR_BLACK  = np.array([0, 0, 0])
    COLOR_WHITE  = np.array([255, 255, 255])
    COLOR_GREEN  = np.array([0, 192, 0])     # Palette 0 (Bit 7 = 0, Odd X)
    COLOR_PURPLE = np.array([192, 0, 192])   # Palette 0 (Bit 7 = 0, Even X)
    COLOR_ORANGE = np.array([255, 106, 0])   # Palette 1 (Bit 7 = 1, Odd X)
    COLOR_BLUE   = np.array([0, 106, 255])   # Palette 1 (Bit 7 = 1, Even X)

    for y in range(192):
        line_offset = get_hgr_line_offset(y)
        
        for byte_idx in range(40):
            x_start = byte_idx * 7
            chunk_pixels = pixels[y, x_start:x_start + 7]

            best_byte = 0
            best_error = float("inf")

            # Test both palette bit options (Bit 7 = 0 and Bit 7 = 1)
            for palette_bit in [0, 1]:
                # Test all 128 bit combinations for bits 0..6
                for bit_pattern in range(128):
                    simulated_rgbs = []

                    for bit_idx in range(7):
                        x = x_start + bit_idx
                        curr_bit = (bit_pattern >> bit_idx) & 1
                        prev_bit = (bit_pattern >> (bit_idx - 1) & 1) if bit_idx > 0 else 0
                        next_bit = (bit_pattern >> (bit_idx + 1) & 1) if bit_idx < 6 else 0

                        # White requires adjacent set bits; Black is adjacent zeros
                        if curr_bit == 1 and (prev_bit == 1 or next_bit == 1):
                            simulated_rgb = COLOR_WHITE
                        elif curr_bit == 0 and prev_bit == 0 and next_bit == 0:
                            simulated_rgb = COLOR_BLACK
                        elif curr_bit == 1:
                            is_odd = (x % 2 != 0)
                            if palette_bit == 0:
                                simulated_rgb = COLOR_GREEN if is_odd else COLOR_PURPLE
                            else:
                                simulated_rgb = COLOR_ORANGE if is_odd else COLOR_BLUE
                        else:
                            simulated_rgb = COLOR_BLACK

                        simulated_rgbs.append(simulated_rgb)

                    # Calculate total mean squared color error for this 7-pixel chunk
                    error = np.sum((chunk_pixels - np.array(simulated_rgbs)) ** 2)

                    if error < best_error:
                        best_error = error
                        best_byte = (palette_bit << 7) | bit_pattern

            # Write byte into interleaved HGR memory layout
            hgr_buffer[line_offset + byte_idx] = best_byte

    # Save raw 8192-byte headerless binary file
    with open(output_path, "wb") as f:
        f.write(hgr_buffer)

    print(f"Successfully exported {len(hgr_buffer)} bytes to '{output_path}'.")

if __name__ == "__main__":
    convert_to_hgr("painter_splash.png", "PAINT_SPLASH#062000")
