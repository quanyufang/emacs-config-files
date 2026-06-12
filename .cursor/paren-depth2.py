#!/usr/bin/env python3
path = "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el"
depth = 0
for i, line in enumerate(open(path), 1):
    for c in line:
        if c == '(': depth += 1
        elif c == ')': depth -= 1
    if 'defun inline-crypt' in line or (820 <= i <= 865):
        print(f"{i:4d} depth={depth:3d} {line.rstrip()[:100]}")
