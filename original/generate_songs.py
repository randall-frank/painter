# Generate Yankee Doodle song data
# Pitch mapping based on C Major scale analysis of sound hardware
# Higher hex values = lower frequencies

# Estimated pitch values for C Major scale
# Based on analysis of La Cucaracha pitch table
pitches = {
    'G3': 0x82, 
    'A3': 0x78, 
    'B3': 0x6E,
    'C4': 0x64,  # Base frequency (100)
    'D4': 0x5a,  # ~90
    'E4': 0x50,  # ~80
    'F4': 0x4B,  # ~71
    'G4': 0x41,  # ~60
    'A4': 0x3c,  # ~51
    'B4': 0x37,  # ~42
    'C5': 0x33,  # ~42
    'D5': 0x2f,  # ~42
    'E5': 0x2a,  # ~42
}

G3 = 0x82 
A3 = 0x78 
B3 = 0x6E
C4 = 0x64
D4 = 0x5a
E4 = 0x50
F4 = 0x4B
G4 = 0x41
A4 = 0x3c
B4 = 0x37
C5 = 0x33
D5 = 0x2f
E5 = 0x2a


# Jarabe Tapatío melody notes
melody = [
    [G4,1],
    [C5,2],
    [C5,1],
    [C5,2],
    [B4,1],
    [C5,2],
    [D5,1],
    [B4,2],
    [G4,1],
    [B4,2],
    [B4,1],
    [B4,2],
    [A4,1],
    [B4,2],
    [C5,1],
    [G4,2],
    [G4,1],
    [C5,2],
    [C5,1],
    [C5,2],
    [B4,1],
    [C5,2],
    [D5,1],
    [B4,2],
    [G4,1],
    [D5,2],
    [D5,1],
    [D5,2],
    [C5,1],
    [B4,2],
    [A4,1],
    [G4,2]
]

# Yankee Doodle melody notes
melody =[
    [C4,2],
    [C4,2],
    [D4,2],
    [E4,2],
    [C4,2],
    [E4,2],
    [D4,4],
    [C4,2],
    [C4,2],
    [D4,2],
    [E4,2],
    [C4,4],
    [B3,4],
    [C4,2],
    [C4,2],
    [D4,2],
    [E4,2],
    [F4,2],
    [E4,2],
    [D4,2],
    [C4,2],
    [B3,2],
    [G3,2],
    [A3,2],
    [B3,2],
    [C4,2],
    [C4,4]
]

# Pop goes the Weasel
melody = [
    [C4,1],
    [C4,2],
    [D4,1],
    [D4,2],
    [E4,1],
    [G4,2],
    [E4,1],
    [C4,3],
    [C4,1],
    [C4,2],
    [D4,1],
    [D4,2],
    [E4,1],
    [C4,3],
    [E4,3],
    [C4,1],
    [C4,2],
    [D4,1],
    [D4,2],
    [E4,1],
    [G4,2],
    [E4,1],
    [C4,3],
    [A4,2],
    [F4,1],
    [D4,2],
    [E4,1],
    [C4,3]
]


full_song = []
for p,l in melody:
    full_song.extend([p]*l*4)
    full_song.append(1)

# Format as hex output, 8 values per line (matching SONG0.S format)
output = ""
for i, val in enumerate(full_song):
    if i % 8 == 0:
        if i > 0:
            output += "\n"
        output += "         hex   "
    output += f"{val:02x}"
    if (i + 1) % 8 != 0 and i < len(full_song) - 1:
        output += ""

# Generate the assembly file
asm_output = """* Sound table

SONG1_START
"""
asm_output += output + "\n"
asm_output += "SONG1_END\n"

print(asm_output)

# Also save to file
with open("src/SONG1.S", "w") as f:
    f.write(asm_output)

print("\nFile created: src/SONG1.S")
print(f"Song length: {len(full_song)} bytes")
