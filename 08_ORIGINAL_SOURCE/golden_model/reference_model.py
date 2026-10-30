def gray(b):
    return (b ^ (b >> 1)) & 0xFF


def hamming(a, b):
    return (a ^ b).bit_count()


def step(binary_state, rst_n, enable):
    if not rst_n:
        return 0
    if enable:
        return (binary_state + 1) & 0xFF
    return binary_state


def run():
    # Reset and hold.
    assert step(123, 0, 1) == 0
    assert step(123, 1, 0) == 123

    # Basic mapping.
    assert gray(0x00) == 0x00
    assert gray(0x01) == 0x01
    assert gray(0x02) == 0x03
    assert gray(0x03) == 0x02
    assert gray(0xFF) == 0x80

    # Exhaustive Gray-cycle checks.
    sequence = [gray(i) for i in range(256)]
    assert len(set(sequence)) == 256

    for i in range(255):
        assert hamming(sequence[i], sequence[i+1]) == 1

    # Explicit cyclic rollover.
    assert hamming(sequence[255], sequence[0]) == 1
    assert sequence[255] == 0x80
    assert sequence[0] == 0x00

    # Binary state cycle.
    b = 0
    seen = []
    for _ in range(256):
        seen.append(b)
        b = step(b, 1, 1)
    assert len(set(seen)) == 256
    assert b == 0

    print("D05 reference model PASS")
    print("All 256 Gray states are unique.")
    print("All 256 cyclic adjacent transitions have Hamming distance 1.")


if __name__ == "__main__":
    run()
