from datetime import datetime

def make_source(filename: str) -> None:
    s = "* Generated joystick value table\n"
    s += "* Map joystick value (0-128) to a 16bit 8.8 fixed point number\n"
    s += "* This number can be added to a (16bit) position to update it\n"
    s += f"* Date: {datetime.now().isoformat()}\n"

    min_v = 0
    max_v = 110
    center = 55
    deadzone = 8
    
    tbl = []
    for i in range(128):
        if i < center - deadzone:
            v = (center - i) / center
        elif i > center + deadzone:
            v = (i - center) / center
        else:
            v = 0
        tbl.append(v)

    print(tbl)
    
    highs = []
    lows = []
    for v in tbl:
        if v >= 1.0:
            h = 1
            l = 0
        else:
            h = 0
            l = int(v * 256)
        highs.append(h)
        lows.append(l)

    s += "\nJOYSTICK_MAP_TABLE_HI\n"
    for v in highs:        
        s += f"         db    ${v:02x}\n"

    s += "\nJOYSTICK_MAP_TABLE_LO\n"
    for v in lows:        
        s += f"         db    ${v:02x}\n"
    
    with open(filename,"w") as f:
        f.write(s)
    
