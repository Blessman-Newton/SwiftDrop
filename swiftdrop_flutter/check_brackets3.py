import sys

with open('lib/screens/restaurant_detail_screen.dart', 'r') as f:
    lines = f.readlines()

depth = 0
bracket_depth = 0
in_string = False
in_comment = False
in_line_comment = False

# Show running depth for lines 570-720
for i, line in enumerate(lines):
    if i < 569 or i > 720:
        # Still need to track state
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
            if c == "'" or c == '"':
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
        continue

    in_line_comment = False
    old_depth = depth
    old_bracket = bracket_depth
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
        if c == "'" or c == '"':
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
    
    delta_p = depth - old_depth
    delta_b = bracket_depth - old_bracket
    stripped = line.rstrip()
    if delta_p != 0 or delta_b != 0:
        marker = ""
        if delta_p < 0: marker += ")"
        if delta_p > 0: marker += "("
        if delta_b < 0: marker += "]"
        if delta_b > 0: marker += "["
        print(f"L{i+1:4d}: p={depth:2d} b={bracket_depth:2d} {marker:4s} | {stripped[:90]}")
