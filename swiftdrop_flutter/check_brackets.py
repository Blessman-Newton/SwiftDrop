import sys

with open('lib/screens/restaurant_detail_screen.dart', 'r') as f:
    lines = f.readlines()

depth = 0
bracket_depth = 0
in_string = False
in_comment = False
in_line_comment = False
prev_char = ''

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
            # Simple string handling
            in_string = not in_string
            j += 1
            continue
        if in_string:
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
        
        if depth < 0 or bracket_depth < 0:
            print(f"Line {i+1}: paren={depth} bracket={bracket_depth} -> {line.rstrip()}")
        
        j += 1

print(f"\nFinal: paren={depth} bracket={bracket_depth}")
