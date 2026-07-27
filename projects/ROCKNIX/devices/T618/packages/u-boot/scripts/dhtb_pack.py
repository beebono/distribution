#!/usr/bin/env python3
"""Portable DHTB packer for Spreadtrum sharkl5pro SPL images.

This reproduces the on disk format produced by the vendored tools/imgheaderinsert
binary, so the build works even on a host without 32 bit multilib support.

DHTB header layout (512 bytes) as produced by imgheaderinsert for this platform:
  0x000  "DHTB"                     magic
  0x004  0x00000001                 version, little endian
  0x008  32 byte SHA256 of payload  hash over the whole payload
  0x028  zero
  0x030  payload length             little endian uint32
  ...    zero up to 0x200

The 512 byte header is followed by the raw SPL payload. The result is then
padded with 0x00 up to the partition size (4 MiB for spl_a/spl_b).

Usage:
  dhtb_pack.py <spl_payload.bin> <output.img> [partition_size_bytes]
"""
import sys
import hashlib
import struct

DHTB_HEADER_SIZE = 512
DEFAULT_PART_SIZE = 4 * 1024 * 1024


def pack(payload: bytes) -> bytes:
    header = bytearray(DHTB_HEADER_SIZE)
    header[0:4] = b"DHTB"
    struct.pack_into("<I", header, 0x04, 1)
    header[0x08:0x28] = hashlib.sha256(payload).digest()
    struct.pack_into("<I", header, 0x30, len(payload))
    return bytes(header) + payload


def main():
    if len(sys.argv) < 3:
        sys.stderr.write(__doc__)
        return 2
    payload = open(sys.argv[1], "rb").read()
    out_path = sys.argv[2]
    part_size = int(sys.argv[3], 0) if len(sys.argv) > 3 else DEFAULT_PART_SIZE

    img = pack(payload)
    if len(img) > part_size:
        sys.stderr.write(
            "error: DHTB image (%d bytes) is larger than partition size (%d)\n"
            % (len(img), part_size)
        )
        return 1
    img = img + b"\x00" * (part_size - len(img))
    open(out_path, "wb").write(img)
    print(
        "wrote %s: payload %d bytes, padded to %d bytes"
        % (out_path, len(payload), len(img))
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
