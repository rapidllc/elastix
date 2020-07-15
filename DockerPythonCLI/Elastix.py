#! /usr/bin/env python3
import argparse
import ctk_cli
import os
import sys
import subprocess

parser = ctk_cli.CLIArgumentParser(os.path.splitext(os.path.abspath(__file__))[0] + '.xml')

inputs = parser.parse_args()


command = '/elastix-rel/bin/elastix'
args = []

for key in vars(inputs).keys():
    if vars(inputs)[key] is not None and str(vars(inputs)[key]) != 'False':
        if str(vars(inputs)[key]) == 'True':
            args.append('-' + key)
        else:
            args.append('-' + key + ' ' + str(vars(inputs)[key]))


subprocess.call([command] + args)
