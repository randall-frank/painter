
def by(v):
    s = ""
    for j in range(8):
        if j == 7:
            s += " "
        if v & (1 << j):
            s += "1"
        else:
            s += "0"
    return s
    

lows = []
highs = []
for i in range(256):
    t = 0
    for j in range(7):
        if i & (1 << j):
            t = t | (0x03 << j*2)
    lo = t & 0x7f
    hi = (t >> 7) & 0x7f
    if i & 0x80:
        lo = lo | 0x80
        hi = hi | 0x80
    lows.append(lo)
    highs.append(hi)


print("wide_byte_lo")
s = ""
for v in lows:
    s += f"{v:02X}"
    if len(s) == 16:
        print(f"         hex   {s}")
        s = ""

print("wide_byte_hi")
s = ""
for v in highs:
    s += f"{v:02X}"
    if len(s) == 16:
        print(f"         hex   {s}")
        s = ""
