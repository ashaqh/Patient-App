import os
import re

def fix_deprecated_apis(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    changes_made = False
    
    # Fix background -> surface
    if 'colorScheme.background' in content:
        new_content = content.replace('colorScheme.background', 'colorScheme.surface')
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix onBackground -> onSurface  
    if 'colorScheme.onBackground' in content:
        new_content = content.replace('colorScheme.onBackground', 'colorScheme.onSurface')
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix surfaceVariant -> surfaceContainerHighest
    if 'surfaceVariant' in content:
        new_content = content.replace('surfaceVariant', 'surfaceContainerHighest')
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix withOpacity -> withValues (basic replacement, may need manual review)
    # This is more complex as withOpacity takes a double, withValues takes ColorValues
    # We'll just comment these out for manual fixing
    if 'withOpacity(' in content:
        print(f"  Warning: {file_path} contains withOpacity() - needs manual fixing")
    
    # Fix activeColor -> activeThumbColor
    if 'activeColor:' in content:
        new_content = content.replace('activeColor:', 'activeThumbColor:')
        if new_content != content:
            content = new_content
            changes_made = True
    
    # Fix value -> initialValue for TextFormField
    if 'value:' in content and 'TextFormField' in content:
        # More careful replacement
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if 'TextFormField' in line or i > 0 and 'TextFormField' in lines[i-1]:
                if 'value:' in line and 'initialValue:' not in line:
                    lines[i] = line.replace('value:', 'initialValue:')
                    changes_made = True
        content = '\n'.join(lines)
    
    if changes_made:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed deprecated APIs in {file_path}")
    
    return changes_made

def main():
    lib_dir = 'lib'
    fixed_count = 0
    
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                if fix_deprecated_apis(file_path):
                    fixed_count += 1
    
    print(f"\nFixed deprecated APIs in {fixed_count} files")
    print("\nNote: withOpacity() replacements need manual fixing as they require Color.withValues()")

if __name__ == '__main__':
    main()