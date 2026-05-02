import os
import re

def revert_with_opacity(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern to match .withValues(opacity: 0.xx)
    pattern = r'\.withValues\(opacity:\s*([0-9]*\.?[0-9]+)\)'
    
    def replace_with_opacity(match):
        opacity_value = match.group(1)
        return f'.withOpacity({opacity_value})'
    
    new_content = re.sub(pattern, replace_with_opacity, content)
    
    if new_content != content:
        print(f"Reverted withValues to withOpacity in {file_path}")
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    
    return False

def main():
    lib_dir = 'lib'
    fixed_count = 0
    
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                if revert_with_opacity(file_path):
                    fixed_count += 1
    
    print(f"\nReverted {fixed_count} files back to withOpacity")

if __name__ == '__main__':
    main()