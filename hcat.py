#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Usage: hcat.py [OPTION]... [FILE]...
Concatenate FILE(s) horizontally to standard output.

If only one file, it will be repeated twice

  -ns       no separator between columns
  -ew       equal column widths instead of the first taking all remaining space
  -nf       don't fix bidirectionl text leaking into other columns
  -as       consider all characters as spacing characters when counting characters per line"""

import unicodedata
import sys, shutil

files, flags = [], set()
for v in sys.argv[1:]: (flags.add if v.startswith("-") else files.append)(v)

fsi, pdi = "\u2068", "\u2069"
sep = "│" if not "-ns" in flags else "" # ns: no separator
if not "-nf" in flags: start, end = fsi, pdi # nf: don't fix bidirectional
else: start, end = "", ""
width, height = shutil.get_terminal_size((80, 25))

def generator(fname, count, flags):
    all_spacing = "-as" in flags
    with open(fname, encoding="utf-8") as f:
        for i, l in enumerate(f):
            l = l.rstrip("\n")
            start = 0; end = 0
            cs = len(l)
            while True:
                spacing = 0
                for k in range(start, cs):
                    if unicodedata.category(l[k]) != "Mn" or all_spacing: spacing +=1
                    if spacing>count: break
                    end += 1
                part = l[start:end]; remaining = count-spacing
                if remaining: part += " "*remaining
                yield part
                start = end
                if end==cs: break

def main(files, flags):
    if len(files)==0 or {"-h", "--help"} & flags: print(__doc__, file=sys.stderr); exit(1)
    if len(files)==1: files *= 2
    total = len(files)
    ss = len(sep)
    widths = [int(width/total)-ss for i in range(total)]
    if not "-ew" in flags: widths[0] = width - sum(widths[:-1]) - (total-1)*ss # ew: equal width
    gens = tuple(generator(f, w, flags) for f, w in zip(files, widths))

    while True:
        done = 0
        line = ""
        for j, (gen, w) in enumerate(zip(gens, widths)):
            try: p = next(gen)
            except StopIteration: p = " "*(w); done += 1
            except FileNotFoundError: print("Couldn't open file: %s\n\n%s"%(files[j], __doc__), file=sys.stderr); exit(1)
            line += start + p + end + ("" if j+1==total else sep)
        if done==total: break
        print(line)

if __name__ == "__main__": main(files, flags)
