import os
import re

def add_error_utils_import(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check if ErrorUtils is already imported
    if 'ErrorUtils' in content and 'import' in content:
        # Check if it's properly imported from the right path
        if 'error_utils' in content.lower():
            return False
    
    # Check if ErrorUtils is used in the file
    if 'ErrorUtils.' in content:
        # Need to add import
        lines = content.split('\n')
        
        # Find the last import line
        last_import_index = -1
        for i, line in enumerate(lines):
            if line.strip().startswith('import ') or line.strip().startswith('export '):
                last_import_index = i
        
        # Add import after the last import
        if last_import_index >= 0:
            import_line = "import '../utils/error_utils.dart';"
            # Check if it's a relative import
            if 'lib/core' in file_path:
                import_line = "import '../utils/error_utils.dart';"
            elif 'lib/data' in file_path:
                import_line = "import '../core/utils/error_utils.dart';"
            elif 'lib/presentation' in file_path:
                import_line = "import '../../core/utils/error_utils.dart';"
            
            lines.insert(last_import_index + 1, import_line)
            new_content = '\n'.join(lines)
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Added ErrorUtils import to {file_path}")
            return True
    
    return False

def main():
    lib_dir = 'lib'
    files_with_errorutils = []
    
    # First, find all files that use ErrorUtils
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if 'ErrorUtils.' in content:
                        files_with_errorutils.append(file_path)
    
    # Add imports to files that need it
    added_count = 0
    for file_path in files_with_errorutils:
        if add_error_utils_import(file_path):
            added_count += 1
    
    print(f"Added ErrorUtils import to {added_count} files")

if __name__ == '__main__':
    main()