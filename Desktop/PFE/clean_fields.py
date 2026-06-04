import os
import re

dir_path = r'c:\Users\yotub\Desktop\PFE\skillspace_front\lib\features\landing\presentation\widgets'

for filename in os.listdir(dir_path):
    if filename.endswith('.dart'):
        filepath = os.path.join(dir_path, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # remove imports containing field_selection_page
        content = re.sub(r'import\s+.*field_selection_page\.dart[\'\"];?\n?', '', content)
        
        # replace the sector check blocks
        pattern = r'final\s+sector\s*=\s*userData\?\[\'sector\'\];\s*if\s*\(\s*sector\s*==\s*null\s*\|\|\s*sector\.toString\(\)\.isEmpty\s*\)\s*\{\s*return\s+const\s+FieldSelectionPage\(\);\s*\}'
        
        content = re.sub(pattern, '', content)
        
        # Also check for inline ternary: sector == null ? const FieldSelectionPage() : DashboardShell(...)
        # Wait, if we use ternary, let's just replace it entirely with the DashboardShell
        pattern2 = r'sector\s*==\s*null\s*\|\|\s*sector\.toString\(\)\.isEmpty\s*\?\s*const\s+FieldSelectionPage\(\)\s*:\s*(DashboardShell\([^\)]+\))'
        content = re.sub(pattern2, r'\1', content)

        # Another variation:
        pattern3 = r'if\s*\(\s*sector\s*==\s*null\s*\|\|\s*sector\.toString\(\)\.isEmpty\s*\)\s*\{\s*return\s+const\s+FieldSelectionPage\(\);\s*\}'
        content = re.sub(pattern3, '', content)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
