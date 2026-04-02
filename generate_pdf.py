import markdown
import pdfkit

input_filename = 'Backend_API_Requirements.md'
output_filename = 'Backend_API_Requirements.pdf'

# Read Markdown
with open(input_filename, 'r', encoding='utf-8') as f:
    text = f.read()

# Convert Markdown to HTML
html_text = markdown.markdown(text)

# Add basic RTL styling for Arabic
styled_html = f'''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body {{
            font-family: Arial, sans-serif;
            direction: rtl;
            text-align: right;
            padding: 20px;
            line-height: 1.6;
        }}
        h1 {{ color: #E71D24; text-align: center; border-bottom: 2px solid #eee; padding-bottom: 10px; }}
        h2 {{ color: #1E293B; margin-top: 25px; }}
        ul {{ margin-right: 20px; }}
        li {{ margin-bottom: 5px; }}
        code {{ background: #f1f5f9; padding: 2px 6px; border-radius: 4px; direction: ltr; display: inline-block; }}
    </style>
</head>
<body>
    {html_text}
</body>
</html>
'''

# Convert HTML to PDF
try:
    pdfkit.from_string(styled_html, output_filename)
    print("PDF created successfully generated!")
except Exception as e:
    print(f"pdfkit not installed or wkhtmltopdf missing. Error: {e}")
