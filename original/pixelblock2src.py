
s = ""

with open("SPLASH.IMG#068000", "rb") as f:
    data = f.read()

s += "IMG_SPLASH\n"
s += f"         dfb   25, 109\n"
t = ""
for v in data:
    t += f"{v:02x}"
    if len(t) == 16:
        s += f"         hex   {t}\n"
        t = ""
s += f"         hex   {t}\n"
    
with open("PAINT.IMG#068000", "rb") as f:
    data = f.read()

s += "IMG_PAINT\n"
s += f"         dfb   31, 57\n"
t = ""
for v in data:
    t += f"{v:02x}"
    if len(t) == 16:
        s += f"         hex   {t}\n"
        t = ""
s += f"         hex   {t}\n"

with open("src/SPLASH.S", "w") as f:
    f.write(s)
