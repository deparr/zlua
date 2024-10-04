#!/usr/bin/env python

import os

b = bytearray(
    [
        0x2d,
        0x2d,
        0x6C,  # local
        0x6F,
        0x63,
        0x61,
        0x6C,
        0x20,

        0x61,  # a

        0x20,

        0x3D,  # =

        0x20,

        0x22,  # "123
        0x31,
        0x32,
        0x33,

        0x00,  # target

        0x34,  # 456"
        0x35,
        0x36,
        0x22,

        # 0x0A,

        # 0x70,  # print(a)
        # 0x72,
        # 0x69,
        # 0x6E,
        # 0x74,
        # 0x28,
        # 0x61,
        # 0x29,
    ]
)

fd = os.open("test.lua", os.O_RDWR)
os.write(fd, b)
os.close(fd)
