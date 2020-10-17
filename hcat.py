#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import math
import unicodedata
import sys, shutil

fix = True

fsi, pdi = "\u2068", "\u2069"
vert = "│"
start, end = "", ""
if fix: start, end = fsi, pdi
width, height = shutil.get_terminal_size((80, 25))

def generator(fname, count):
    with open(fname, encoding="utf-8") as f:
        for i, l in enumerate(f):
            l = l.rstrip("\n")
            start = 0; end = 0
            cs = len(l)
            while True:
                spacing = 0
                for k in range(start, cs):
                    if unicodedata.category(l[k]) != "Mn": spacing +=1
                    if spacing>count: break
                    end += 1
                part = l[start:end]; remaining = count-spacing
                if remaining: part += " "*remaining
                yield part
                start = end
                if end==cs: break

files = sys.argv[1:]
if len(files)==0: print("Usage: %s file1 file2..."%(__file__), file=sys.stderr); exit(1)
if len(files)==1: files *= 2
total = len(files)
widths = [math.ceil(width/total)-1 for _ in range(total)]
widths[-1] = width - sum(widths[:-1]) - (total-1)
gens = tuple(generator(f, w) for f, w in zip(files, widths))

while True:
    done = 0
    line = ""
    for j, (gen, w) in enumerate(zip(gens, widths)):
        try: p = next(gen)
        except: p = " "*(w); done += 1
        line += start + p + end + ("" if j+1==total else vert)
    if done==total: break
    print(line)
