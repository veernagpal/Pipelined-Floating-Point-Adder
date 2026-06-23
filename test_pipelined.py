import struct

def hex_to_float(hex_str):
    # Convert 32-bit hex string to Python float
    integer = int(hex_str, 16)
    return struct.unpack('!f', integer.to_bytes(4, byteorder='big'))[0]

def to_float32(value):
    # Force Python result into FP32 format
    return struct.unpack('!f', struct.pack('!f', value))[0]


# Read input vectors: A_HEX B_HEX
stimulus = []

with open("stimulus.txt", "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        parts = line.strip().split()

        if len(parts) == 2:
            a_hex, b_hex = parts
            stimulus.append((a_hex, b_hex))


# Read pipelined RTL outputs: RESULT_HEX
rtl_results = []

with open("rtl_results_pipelined.txt", "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        line = line.strip()

        if line:
            rtl_results.append(line)


pass_count = 0
fail_count = 0
total_count = 0

total_error = 0.0
max_error = 0.0
avg_error = 0.0

# Compare input i with output i
num_tests = min(len(stimulus), len(rtl_results))

for i in range(num_tests):
    a_hex, b_hex = stimulus[i]
    r_hex = rtl_results[i]

    a = hex_to_float(a_hex)
    b = hex_to_float(b_hex)
    r = hex_to_float(r_hex)

    expected = to_float32(a + b)

    total_count += 1

    error = abs(expected - r)
    total_error += error

    if error > max_error:
        max_error = error

    avg_error = total_error / total_count

    print(f"Test No. = {total_count}")
    print(f"A Hex  = {a_hex}")
    print(f"B Hex = {b_hex}")
    print(f"Result Hex = {r_hex}")
    print(f"A = {a}")
    print(f"B = {b}")
    print(f"RTL Result = {r}")
    print(f"Expected  = {expected}")
    print(f"Error  = {error}")

    # Tolerance because RTL may not be exact IEEE-rounded yet
    if error < 1e-4: #adjust based on requirement
        print("Status      = PASS")
        pass_count += 1
    else:
        print("Status      = FAIL")
        fail_count += 1

    print("-" * 40)


print("\n======= SUMMARY =======")
print(f"Stimulus Count : {len(stimulus)}")
print(f"RTL Count      : {len(rtl_results)}")
print(f"Checked Tests  : {total_count}")
print(f"Passed         : {pass_count}")
print(f"Failed         : {fail_count}")
print(f"Max Error      : {max_error:.6e}")
print(f"Avg Error      : {avg_error:.6e}")

if len(stimulus) != len(rtl_results):
    print("\nWARNING: stimulus count and RTL result count do not match.")