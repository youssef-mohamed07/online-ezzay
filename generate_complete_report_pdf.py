from pathlib import Path
import html
import re

import arabic_reshaper
from bidi.algorithm import get_display
from reportlab.lib.enums import TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer

INPUT_MD = Path('Backend_Integration_Stripe_Complete_Report.md')
OUTPUT_PDF = Path('Backend_Integration_Stripe_Complete_Report.pdf')


FONT_CANDIDATES = [
    Path('/System/Library/Fonts/Supplemental/SFArabic.ttf'),
    Path('/System/Library/Fonts/SFArabic.ttf'),
    Path('/System/Library/Fonts/Supplemental/Arial Unicode.ttf'),
    Path('/System/Library/Fonts/Supplemental/Arial.ttf'),
]


def find_font() -> Path:
    for candidate in FONT_CANDIDATES:
        if candidate.exists():
            return candidate
    raise FileNotFoundError('No Arabic-compatible font found in expected system paths.')


def has_arabic(text: str) -> bool:
    return re.search(r'[\u0600-\u06FF]', text) is not None


def shape_text(text: str) -> str:
    if not text.strip():
        return text
    if has_arabic(text):
        return get_display(arabic_reshaper.reshape(text))
    return text


def parse_markdown_to_story(md_text: str, styles: dict) -> list:
    story = []

    for raw_line in md_text.splitlines():
        line = raw_line.rstrip()
        stripped = line.strip()

        if not stripped:
            story.append(Spacer(1, 8))
            continue

        if stripped.startswith('### '):
            text = shape_text(stripped[4:])
            story.append(Paragraph(html.escape(text), styles['h3']))
            story.append(Spacer(1, 4))
            continue

        if stripped.startswith('## '):
            text = shape_text(stripped[3:])
            story.append(Paragraph(html.escape(text), styles['h2']))
            story.append(Spacer(1, 6))
            continue

        if stripped.startswith('# '):
            text = shape_text(stripped[2:])
            story.append(Paragraph(html.escape(text), styles['h1']))
            story.append(Spacer(1, 10))
            continue

        if stripped.startswith('- '):
            text = shape_text(f"• {stripped[2:]}")
            story.append(Paragraph(html.escape(text), styles['bullet']))
            continue

        text = shape_text(stripped)
        story.append(Paragraph(html.escape(text), styles['body']))

    return story


def main() -> None:
    if not INPUT_MD.exists():
        raise FileNotFoundError(f'Missing input markdown file: {INPUT_MD}')

    font_path = find_font()
    font_name = 'ArabicReportFont'
    pdfmetrics.registerFont(TTFont(font_name, str(font_path)))

    styles = {
        'h1': ParagraphStyle(
            'h1',
            fontName=font_name,
            fontSize=20,
            leading=28,
            alignment=TA_RIGHT,
            spaceAfter=6,
            textColor='#B91C1C',
        ),
        'h2': ParagraphStyle(
            'h2',
            fontName=font_name,
            fontSize=15,
            leading=22,
            alignment=TA_RIGHT,
            spaceBefore=4,
            textColor='#0F172A',
        ),
        'h3': ParagraphStyle(
            'h3',
            fontName=font_name,
            fontSize=13,
            leading=19,
            alignment=TA_RIGHT,
            textColor='#1E293B',
        ),
        'body': ParagraphStyle(
            'body',
            fontName=font_name,
            fontSize=11,
            leading=18,
            alignment=TA_RIGHT,
            textColor='#111827',
        ),
        'bullet': ParagraphStyle(
            'bullet',
            fontName=font_name,
            fontSize=11,
            leading=18,
            alignment=TA_RIGHT,
            rightIndent=12,
            textColor='#111827',
        ),
    }

    md_text = INPUT_MD.read_text(encoding='utf-8')
    story = parse_markdown_to_story(md_text, styles)

    doc = SimpleDocTemplate(
        str(OUTPUT_PDF),
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=36,
        bottomMargin=36,
        title='Backend Integration and Stripe Report',
        author='GitHub Copilot',
    )
    doc.build(story)

    print(f'PDF generated: {OUTPUT_PDF.resolve()}')


if __name__ == '__main__':
    main()
