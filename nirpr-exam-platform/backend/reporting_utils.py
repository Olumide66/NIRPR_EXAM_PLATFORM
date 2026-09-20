from io import BytesIO
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle


def official_exam_report_pdf(data: dict) -> bytes:
    buffer = BytesIO(); styles = getSampleStyleSheet()
    doc = SimpleDocTemplate(buffer, pagesize=landscape(A4), leftMargin=18*mm, rightMargin=18*mm, topMargin=16*mm, bottomMargin=16*mm,
                            title=f"Official Examination Report - {data['examination']}")
    story = [Paragraph("NIRPR OFFICIAL EXAMINATION REPORT", styles['Title']), Spacer(1, 8*mm)]
    rows = [["Field", "Official record"], ["Examination", data['examination']], ["Date", data['date']],
            ["Programme", data['programme']], ["Number registered", data['number_registered']],
            ["Number present", data['number_present']], ["Number absent", data['number_absent']],
            ["Number passed", data['number_passed']], ["Number failed", data['number_failed']],
            ["Average score", f"{data['average_score']:.2f}%"], ["Pass rate", f"{data['pass_rate']:.2f}%"],
            ["Examiner", data['examiner']], ["Approval date", data['approval_date'] or "Pending"]]
    table=Table(rows, colWidths=[65*mm, 160*mm]); table.setStyle(TableStyle([
        ('BACKGROUND',(0,0),(-1,0),colors.HexColor('#102A43')),('TEXTCOLOR',(0,0),(-1,0),colors.white),
        ('FONTNAME',(0,0),(-1,0),'Helvetica-Bold'),('GRID',(0,0),(-1,-1),.5,colors.HexColor('#B8C5D1')),
        ('VALIGN',(0,0),(-1,-1),'TOP'),('PADDING',(0,0),(-1,-1),7),('BACKGROUND',(0,1),(0,-1),colors.HexColor('#EAF0F6'))]))
    story += [table, Spacer(1,7*mm), Paragraph("Generated from approved examination records. This report must follow the institute's internal approval and records-retention process.", styles['Normal'])]
    doc.build(story); return buffer.getvalue()
