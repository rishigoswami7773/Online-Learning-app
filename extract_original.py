import json
import os

log_path = r'C:\Users\hetvi\.gemini\antigravity\brain\4b73fac9-9fa8-48c5-93b6-5d16c11592a3\.system_generated\logs\overview.txt'

def extract_file(file_path):
    print(f"Searching for {file_path}...")
    with open(log_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                data = json.loads(line)
                if data.get('type') == 'TOOL_RESPONSE' and 'file_path' in data.get('content', '') or 'File Path:' in data.get('content', ''):
                    content = data['content']
                    if file_path in content:
                        # Extract the code between the code blocks or just the whole content
                        # Since view_file output is formatted, we look for '1: ' patterns
                        print(f"Found match for {file_path}")
                        return content
            except:
                continue
    return None

# Files to revert
files = [
    'lib/routes/app_router.dart',
    'lib/controllers/auth_controller.dart',
    'lib/views/screens/login_screen.dart',
    'lib/controllers/app_auth_controller.dart'
]

for f in files:
    res = extract_file(f)
    if res:
        with open(f"original_{os.path.basename(f)}.txt", 'w', encoding='utf-8') as out:
            out.write(res)
        print(f"Saved original_{os.path.basename(f)}.txt")
    else:
        print(f"Could not find original for {f}")
