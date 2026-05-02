import os
import re

def fix_build_context_gaps(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # This is a complex issue that needs manual fixing
    # We'll just identify files that need attention
    if 'use_build_context_synchronously' in content.lower():
        print(f"  {file_path} has BuildContext async gaps - needs manual review")
        return False
    
    return False

def main():
    lib_dir = 'lib'
    
    print("Files with BuildContext async gaps (need manual fixing):")
    print("=" * 60)
    
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                fix_build_context_gaps(file_path)

if __name__ == '__main__':
    main()