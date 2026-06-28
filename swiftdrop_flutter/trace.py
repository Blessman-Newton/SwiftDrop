with open('lib/screens/restaurant_detail_screen.dart', 'r') as f:
    lines = f.readlines()

depth = 0
bracket_depth = 0
in_comment = False
in_line_comment = False

for i, line in enumerate(lines):
    in_line_comment = False
    j = 0
    while j < len(line):
        c = line[j]
        if in_line_comment:
            j += 1
            continue
        if in_comment:
            if c == '*' and j+1 < len(line) and line[j+1] == '/':
                in_comment = False
                j += 2
                continue
            j += 1
            continue
        if c in ("'", '"'):
            quote = c
            j += 1
            while j < len(line):
                if line[j] == '\\':
                    j += 2
                    continue
                if line[j] == quote:
                    j += 1
                    break
                j += 1
            continue
        if c == '/' and j+1 < len(line):
            if line[j+1] == '/':
                in_line_comment = True
                j += 2
                continue
            elif line[j+1] == '*':
                in_comment = True
                j += 2
                continue
        if c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
        elif c == '[':
            bracket_depth += 1
        elif c == ']':
            bracket_depth -= 1
        j += 1
    
    if depth >= 10:
        print(f"L{i+1:4d}: p={depth:2d} b={bracket_depth:2d} | {line.rstrip()[:90]}")

print(f"\nFinal: paren={depth} bracket={bracket_depth}")
