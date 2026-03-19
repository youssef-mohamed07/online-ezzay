import os
import shutil
import re
from pathlib import Path

def ensure_dir(d):
    Path(d).mkdir(parents=True, exist_ok=True)

lib = Path('lib')
src = lib / 'src'

ensure_dir(lib / 'core')
ensure_dir(lib / 'models')
ensure_dir(lib / 'views' / 'screens')
ensure_dir(lib / 'views' / 'widgets')
ensure_dir(lib / 'controllers')
ensure_dir(lib / 'data')

if (src / 'models').exists():
    for f in (src / 'models').iterdir():
        shutil.move(str(f), str(lib / 'models'))

if (src / 'data').exists():
    for f in (src / 'data').iterdir():
        shutil.move(str(f), str(lib / 'data'))

if (src / 'pages').exists():
    for f in (src / 'pages').iterdir():
        shutil.move(str(f), str(lib / 'views' / 'screens'))

if (src / 'widgets').exists():
    for f in (src / 'widgets').iterdir():
        shutil.move(str(f), str(lib / 'views' / 'widgets'))

if (src / 'online_ezzy_app.dart').exists():
    shutil.move(str(src / 'online_ezzy_app.dart'), str(lib / 'core' / 'app.dart'))

try:
    if (src / 'models').exists(): (src / 'models').rmdir()
    if (src / 'data').exists(): (src / 'data').rmdir()
    if (src / 'pages').exists(): (src / 'pages').rmdir()
    if (src / 'widgets').exists(): (src / 'widgets').rmdir()
    if src.exists(): src.rmdir()
except Exception as e:
    print('Failed to rmdir:', e)

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            new_content = content
            
            if file == 'main.dart':
                new_content = new_content.replace("'src/online_ezzy_app.dart'", "'core/app.dart'")
                new_content = new_content.replace("import 'src/online_ezzy_app.dart';", "import 'core/app.dart';")
            elif file == 'app.dart':
                new_content = new_content.replace("import 'pages/", "import 'package:online_ezzy/views/screens/")
            
            new_content = new_content.replace("package:online_ezzy/src/pages/", "package:online_ezzy/views/screens/")
            
            if 'views' in root.replace('\\\\', '/').replace('\\', '/'):
                new_content = re.sub(r"import\s+'(?:\.\./)+models/", "import 'package:online_ezzy/models/", new_content)
                new_content = re.sub(r"import\s+'(?:\.\./)+data/", "import 'package:online_ezzy/data/", new_content)

            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f'Updated {filepath}')

print('Done')
