import sys

with open('lib/screens/restaurant_detail_screen.dart', 'r') as f:
    lines = f.readlines()

depth = 0
bracket_depth = 0
in_string = False
in_comment = False
in_line_comment = False
prev_char = ''
stack = []

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
        if c == "'" or c == '"':
            # Skip strings
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
            stack.append(('(', i+1))
        elif c == ')':
            depth -= 1
            if stack:
                stack.pop()
        elif c == '[':
            bracket_depth += 1
        elif c == ']':
            bracket_depth -= 1
        
        j += 1

print(f"Final paren depth: {depth}")
print(f"Final bracket depth: {bracket_depth}")

# Now find where we have the most unbalanced parens
# Re-scan showing depth at key lines
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
    
    # Show lines around the error locations and when depth increases
    stripped = line.strip()
    if i+1 in [397, 452, 457, 663, 700, 730, 814, 1276, 1305, 1534, 1585, 1592, 1596, 1823]:
        print(f"L{i+1:4d}: paren={depth:2d} bracket={bracket_depth:2d} | {stripped[:80]}")
