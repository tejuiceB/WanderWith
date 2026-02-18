
import os

file_path = r'c:\Users\Tejas\OneDrive\Desktop\WanderWith\lib\screens\trip_dashboard_screen.dart'

if os.path.exists(file_path):
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    clean_lines = []
    for line in lines:
        # Strip trailing whitespace and ensure a clean newline
        # If a line is excessively long (more than 1000 chars), it's likely garbage
        if len(line) > 1000:
            # Try to keep the first part if it looks like code
            stripped = line.strip()
            if stripped:
                clean_lines.append(stripped + '\n')
            else:
                clean_lines.append('\n')
        else:
            clean_lines.append(line.rstrip() + '\n')
            
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(clean_lines)
    print(f"Cleaned {len(lines)} lines.")
else:
    print("File not found.")
