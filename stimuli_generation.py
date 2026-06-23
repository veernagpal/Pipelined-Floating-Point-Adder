import random
import struct

def float_to_hex(f):
    return hex(struct.unpack('!I', struct.pack('!f', f))[0])[2:].zfill(8)

def clamp_float(x):
    # avoid Inf / NaN explosions
    if abs(x) > 1e6:
        x = random.uniform(-1e6, 1e6)
    return x


#float generator

def smart_float():
    mode = random.randint(0, 4)

    if mode == 0:
        # small decimals (precision stress)
        return random.uniform(-10, 10)

    elif mode == 1:
        # larger range
        return random.uniform(-1000, 1000)

    elif mode == 2:
        # very small numbers (alignment stress)
        return random.uniform(-1e-4, 1e-4)

    elif mode == 3:
        # powers of 2 (exponent edge cases)
        exp = random.randint(-10, 10)
        return float(2 ** exp)

    else:
        # decimals with structure (realistic cases)
        base = random.uniform(-100, 100)
        frac = random.choice([0.1, 0.25, 0.5, 0.75, 0.125])
        return base + frac

N = 1000

with open("stimulus.txt", "w") as f:

    for _ in range(N):

        a = clamp_float(smart_float())
        b = clamp_float(smart_float())

        # optional: inject cancellation cases occasionally
        if random.random() < 0.05:
            a = random.uniform(-100, 100)
            b = -a

        a_hex = float_to_hex(a)
        b_hex = float_to_hex(b)

        f.write(f"{a_hex} {b_hex}\n")

print("Generated 1000 test vectors -> stimulus.txt")