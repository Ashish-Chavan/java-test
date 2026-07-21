"""
Python 3.6 Feature: Underscores in Numeric Literals (PEP 515)
Underscores can be used as visual separators in numeric literals
for readability. They are ignored by the parser.
"""

# ── Integer literals ───────────────────────────────────────────────────────
population_earth   = 8_000_000_000
national_debt_usd  = 33_000_000_000_000
bytes_in_terabyte  = 1_099_511_627_776
seconds_per_year   = 31_536_000
max_int_32         = 2_147_483_647

print(f"Earth population:  {population_earth:,}")
print(f"Bytes in TB:       {bytes_in_terabyte:,}")
print(f"Max int32:         {max_int_32:,}")

# ── Hex literals — group by byte or nibble ────────────────────────────────
mac_address     = 0x00_1A_2B_3C_4D_5E
rgb_color       = 0xFF_A5_00          # orange: R=255, G=165, B=0
memory_address  = 0xDEAD_BEEF
file_magic      = 0xCA_FE_BA_BE       # Java class file magic number
ipv4_packed     = 0xC0_A8_01_01       # 192.168.1.1

print(f"\nMAC address:     {mac_address:#018x}")
print(f"RGB orange:      {rgb_color:#08x}")
print(f"Memory address:  {memory_address:#010x}")
print(f"Java magic:      {file_magic:#010x}")
print(f"IPv4 192.168.1.1: {ipv4_packed:#010x}")

# ── Binary literals — group by nibble or byte ─────────────────────────────
byte_value   = 0b1010_0101      # 0xA5 = 165
two_bytes    = 0b1111_0000_1010_0101
permissions  = 0b111_101_101    # rwxr-xr-x = 755
ipv4_mask    = 0b1111_1111_1111_1111_0000_0000_0000_0000  # /16 mask

print(f"\nByte 0xA5:    {byte_value:#010b} = {byte_value}")
print(f"Permissions:  {permissions:#011b} = {permissions} (octal {permissions:o})")
print(f"Subnet mask:  {ipv4_mask:#034b}")

# ── Octal literals ─────────────────────────────────────────────────────────
file_mode_755 = 0o755
file_mode_644 = 0o644
file_mode_600 = 0o600

print(f"\nFile mode 755: {file_mode_755:o} = {file_mode_755}")
print(f"File mode 644: {file_mode_644:o} = {file_mode_644}")

# ── Float literals ─────────────────────────────────────────────────────────
avogadro      = 6.022_140_76e23
planck        = 6.626_070_15e-34
speed_of_light = 299_792_458.0       # m/s
gravitational  = 6.674_30e-11        # N⋅m²/kg²
fine_structure = 7.297_352_569_3e-3

print(f"\nAvogadro:       {avogadro:.6e}")
print(f"Planck const:   {planck:.6e}")
print(f"Speed of light: {speed_of_light:,.1f} m/s")
print(f"Gravitational:  {gravitational:.5e}")
print(f"Fine structure: {fine_structure:.10f}")

# ── Complex literals ───────────────────────────────────────────────────────
impedance = 1_000 + 500j
resonance = 2_400_000_000 + 0j     # 2.4 GHz in Hz

print(f"\nImpedance:  {impedance}")
print(f"Resonance:  {resonance.real:,.0f} Hz")

# ── In expressions ────────────────────────────────────────────────────────
chunk_size = 64_000
total_data = 1_000_000
chunks = total_data // chunk_size
remainder = total_data % chunk_size
print(f"\n{total_data:,} bytes / {chunk_size:,} = {chunks} chunks, {remainder} bytes remainder")

# ── Underscores do NOT appear in the value ────────────────────────────────
assert 1_000_000 == 1000000
assert 0xFF_FF == 0xFFFF
assert 0b1111_0000 == 0b11110000
assert 1_2_3 == 123                   # valid but unusual
print("\nAll assertions passed — underscores are purely visual")

# ── Practical: bitmask operations ─────────────────────────────────────────
STATUS_OK       = 0b0000_0001
STATUS_WARN     = 0b0000_0010
STATUS_ERROR    = 0b0000_0100
STATUS_CRITICAL = 0b0000_1000
STATUS_OFFLINE  = 0b0001_0000

current_status = STATUS_OK | STATUS_WARN
print(f"\nStatus flags: {current_status:#010b}")
print(f"Has warning:  {bool(current_status & STATUS_WARN)}")
print(f"Has error:    {bool(current_status & STATUS_ERROR)}")
