# Try to fix file_picker v1 embedding issue
# One solution is to use file_picker version 4.1.6 which doesn't have v2 embedding

import os

# Update pubspec.yaml to use file_picker 4.1.6
pubspec_path = 'pubspec.yaml'

with open(pubspec_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace file_picker version
new_content = content.replace('file_picker: ^6.1.1', 'file_picker: ^4.1.6')

with open(pubspec_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Updated file_picker to version 4.1.6 to avoid v1 embedding issue")
print("Note: This is an older version but should work for beta release")