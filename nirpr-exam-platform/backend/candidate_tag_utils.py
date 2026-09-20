"""Printable candidate identification tag (separate from exam results/certificates)."""

from io import BytesIO
from pathlib import Path
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph


NAVY = colors.HexColor("#12324A")
TEAL = colors.HexColor("#126F70")
GOLD = colors.HexColor("#C69A3C")
MUTED = colors.HexColor("#5B6978")


def _paragraph(pdf, value: str, x: float, top: float, width: float, size: float = 10,
               color=NAVY, bold: bool = False, max_height: float | None = None) -> float:
    while True:
        style = ParagraphStyle("tag", fontName="Helvetica-Bold" if bold else "Helvetica",
                               fontSize=size, leading=size * 1.18, textColor=color,
                               alignment=TA_LEFT, spaceAfter=0)
        paragraph = Paragraph(escape(value or ""), style)
        _, height = paragraph.wrap(width, 35 * mm)
        if max_height is None or height <= max_height or size <= 5.2:
            break
        size -= .25
    paragraph.drawOn(pdf, x, top - height)
    return top - height


def build_candidate_tag_pdf(*, full_name: str, candidate_number: str,
                            course_name: str, institution: str | None = None,
                            general_manager: dict | None = None,
                            logo_path: str | Path | None = None) -> bytes:
    buffer = BytesIO()
    # Standard ID-1 card dimensions, rotated to portrait.
    width, height = 53.98 * mm, 85.60 * mm
    pdf = canvas.Canvas(buffer, pagesize=(width, height), pageCompression=1)
    pdf.setTitle(f"NIRPR Candidate Tag - {candidate_number}")
    pdf.setAuthor("National Institute of Radiation Protection and Research")

    pdf.setFillColor(colors.white); pdf.rect(0, 0, width, height, fill=1, stroke=0)
    pdf.setStrokeColor(colors.HexColor("#CFDDE1")); pdf.setLineWidth(.6)
    pdf.rect(.5 * mm, .5 * mm, width - mm, height - mm, fill=0, stroke=1)
    if logo_path and Path(logo_path).is_file():
        pdf.drawImage(str(logo_path), 4 * mm, height - 15 * mm, width - 8 * mm, 12 * mm,
                      preserveAspectRatio=True, anchor="c", mask="auto")
    pdf.setFillColor(GOLD); pdf.rect(0, height - 17 * mm, width, .7 * mm, fill=1, stroke=0)
    pdf.setFillColor(MUTED); pdf.setFont("Helvetica", 5.2)
    pdf.drawCentredString(width / 2, height - 21 * mm, "NIRPR  |  Ibadan, Oyo State")

    left = 4 * mm
    pdf.setFillColor(TEAL); pdf.setFont("Helvetica-Bold", 5.5)
    pdf.drawString(left, height - 27 * mm, "CANDIDATE NAME")
    _paragraph(pdf, full_name, left, height - 28.5 * mm, width - 8 * mm, 9.5, NAVY, True, max_height=7 * mm)

    pdf.setFillColor(TEAL); pdf.setFont("Helvetica-Bold", 5.5)
    pdf.drawString(left, height - 37 * mm, "ORGANISATION / INSTITUTION")
    _paragraph(pdf, institution or "Not provided", left, height - 38.5 * mm,
               width - 8 * mm, 7.2, NAVY, False, max_height=6.5 * mm)

    pdf.setFillColor(TEAL); pdf.setFont("Helvetica-Bold", 5.5)
    pdf.drawString(left, height - 47 * mm, "TRAINING COURSE")
    _paragraph(pdf, course_name, left, height - 48.5 * mm, width - 8 * mm,
               7.4, NAVY, True, max_height=11.5 * mm)

    pdf.setStrokeColor(colors.HexColor("#D6E1E5"))
    pdf.line(left, 23 * mm, width - left, 23 * mm)
    pdf.setFillColor(MUTED); pdf.setFont("Helvetica-Bold", 5.1)
    pdf.drawString(left, 20 * mm, "CANDIDATE NUMBER")
    pdf.setFillColor(NAVY); pdf.setFont("Helvetica-Bold", 8.2)
    pdf.drawString(left, 16.3 * mm, candidate_number)

    sig_x = 4 * mm
    signature_path = (general_manager or {}).get("image_path")
    if signature_path and Path(signature_path).is_file():
        pdf.drawImage(str(signature_path), sig_x, 5.5 * mm, 24 * mm, 9 * mm,
                      preserveAspectRatio=True, anchor="c", mask="auto")
    _paragraph(pdf, (general_manager or {}).get("name", "General Manager"),
               width - 25 * mm, 12 * mm, 21 * mm, 5.3, NAVY, True, max_height=4 * mm)
    pdf.setFillColor(MUTED); pdf.setFont("Helvetica", 4.3)
    _paragraph(pdf, (general_manager or {}).get("title") or "General Manager",
               width - 25 * mm, 7 * mm, 21 * mm, 4.3, MUTED, max_height=3 * mm)
    pdf.setFillColor(MUTED); pdf.setFont("Helvetica", 4.3)
    pdf.drawString(left, 1.5 * mm, "For candidate identification only")
    pdf.save()
    return buffer.getvalue()
