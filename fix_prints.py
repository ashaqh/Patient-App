import os
import re

def fix_print_statements(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check if ErrorUtils is imported
    has_error_utils_import = 'import' in content and 'error_utils' in content.lower()
    
    # Replace print statements with ErrorUtils.logInfo for debug prints
    # This pattern captures print('something')
    pattern = r'print\((\'[^\']*\'|\"[^\"]*\")(?:\s*\+\s*[^)]+)?\)'
    
    def replace_print(match):
        # Extract the message
        full_match = match.group(0)
        # For now, replace with ErrorUtils.logInfo
        # We'll need to manually review debug vs error prints
        return f'ErrorUtils.logInfo({match.group(1)})'
    
    new_content = re.sub(pattern, replace_print, content)
    
    if new_content != content:
        print(f"Fixed prints in {file_path}")
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
                if fix_print_statements(file_path):
                    fixed_count += 1
    
    print(f"Fixed print statements in {fixed_count} files")

if __name__ == '__main__':
    main()