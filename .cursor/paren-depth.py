#!/usr/bin/env python3
"""Print paren depth at each line of prepare function."""
path = "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el"
depth = 0
for i, line in enumerate(open(path), 1):
    for c in line:
        if c == '(': depth += 1
        elif c == ')': depth -= 1
    if 189 <= i <= 225:
        print(f"{i:4d} depth={depth:3d} {line.rstrip()[:90]}")
