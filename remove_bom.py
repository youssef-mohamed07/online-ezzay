import os

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'rb') as f:
                data = f.read()
            if data.startswith(b'\xef\xbb\xbf'):
                with open(path, 'wb') as f:
                    f.write(data[3:])
                print(f"Removed BOM from {path}")
