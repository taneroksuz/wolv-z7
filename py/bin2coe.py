#!/usr/bin/env python3

import argparse
import subprocess
import os


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Transform binary files.')
    parser.add_argument('--input',required=True,help='file name')
    parser.add_argument('--address',required=True,help='start address')
    parser.add_argument('--offset',required=True,help='offset')

    args = parser.parse_args()

    bin_file = '{0}.bin'.format(os.path.splitext(args.input)[0])
    coe_file = '{0}.coe'.format(os.path.splitext(args.input)[0])
    start_address = int(args.address,16)
    offset = int(args.offset,16)

    print(coe_file)

    with open(bin_file, 'rb') as f:
        content = f.read()

    output = open(coe_file, 'wb')

    lines = len(content)

    output.write("memory_initialization_radix=16;\n".encode('ascii'))
    output.write("memory_initialization_vector=\n".encode('ascii'))

    address = 0
    while address < offset:
        if address < start_address:
            string0 = "00"
            string1 = "00"
            string2 = "00"
            string3 = "00"
            string4 = "00"
            string5 = "00"
            string6 = "00"
            string7 = "00"
        elif address-start_address < lines:
            if (address-start_address+7) < lines:
                string0 = "{:02X}".format(content[address-start_address+7])
            else:
                string0 = "00"
            if (address-start_address+6) < lines:
                string1 = "{:02X}".format(content[address-start_address+6])
            else:
                string1 = "00"
            if (address-start_address+5) < lines:
                string2 = "{:02X}".format(content[address-start_address+5])
            else:
                string2 = "00"
            if (address-start_address+4) < lines:
                string3 = "{:02X}".format(content[address-start_address+4])
            else:
                string3 = "00"
            if (address-start_address+3) < lines:
                string4 = "{:02X}".format(content[address-start_address+3])
            else:
                string4 = "00"
            if (address-start_address+2) < lines:
                string5 = "{:02X}".format(content[address-start_address+2])
            else:
                string5 = "00"
            if (address-start_address+1) < lines:
                string6 = "{:02X}".format(content[address-start_address+1])
            else:
                string6 = "00"
            if (address-start_address) < lines:
                string7 = "{:02X}".format(content[address-start_address])
            else:
                string7 = "00"
        else:
            string0 = "00"
            string1 = "00"
            string2 = "00"
            string3 = "00"
            string4 = "00"
            string5 = "00"
            string6 = "00"
            string7 = "00"
        if address<(offset-8):
            string = string0 + string1 + string2 + string3 + string4 + string5 + string6 + string7 + ",\n"
        else:
            string = string0 + string1 + string2 + string3 + string4 + string5 + string6 + string7 + ";"
        output.write(string.encode('ascii'))
        address = address + 8

    output.close()
