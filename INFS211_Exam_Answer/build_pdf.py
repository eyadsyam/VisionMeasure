"""
Generates INFS-211 Final Lab Exam Answer Sheet as a clean PDF.
"""

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import cm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, PageBreak
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT, TA_JUSTIFY
from reportlab.platypus import KeepTogether

OUT = '/home/user/VisionMeasure/INFS211_Exam_Answer/INFS211_LabExam_Answer_Final.pdf'

doc = SimpleDocTemplate(
    OUT, pagesize=A4,
    leftMargin=2*cm, rightMargin=2*cm,
    topMargin=1.8*cm, bottomMargin=1.8*cm
)

# ── Colour palette ────────────────────────────────────────────────────────────
NAVY   = colors.HexColor('#1F3864')
RED    = colors.HexColor('#C00000')
WHITE  = colors.white
BLACK  = colors.black
LGREY  = colors.HexColor('#D9D9D9')
DGREY  = colors.HexColor('#2E4057')
GREEN  = colors.HexColor('#DDE8CB')
ORANGE = colors.HexColor('#FCE4D6')
BLUE_H = colors.HexColor('#000080')
ALTROW = colors.HexColor('#F2F2F2')

styles = getSampleStyleSheet()

def S(name, **kw):
    return ParagraphStyle(name, **kw)

sNormal = S('sNormal', fontName='Helvetica', fontSize=10, leading=14,
            textColor=BLACK)
sBold   = S('sBold',   fontName='Helvetica-Bold', fontSize=10, leading=14,
            textColor=BLACK)
sTitle  = S('sTitle',  fontName='Helvetica-Bold', fontSize=15, leading=20,
            alignment=TA_CENTER, textColor=NAVY)
sSub    = S('sSub',    fontName='Helvetica', fontSize=11, leading=15,
            alignment=TA_CENTER, textColor=BLACK)
sCenter = S('sCenter', fontName='Helvetica', fontSize=10, leading=13,
            alignment=TA_CENTER)
sCenterB= S('sCenterB',fontName='Helvetica-Bold', fontSize=10, leading=13,
            alignment=TA_CENTER)
sSmall  = S('sSmall',  fontName='Helvetica', fontSize=8,  leading=11)
sSmallB = S('sSmallB', fontName='Helvetica-Bold', fontSize=8, leading=11)
sFooter = S('sFooter', fontName='Helvetica-Oblique', fontSize=8, leading=11,
            alignment=TA_CENTER, textColor=colors.grey)
sAns    = S('sAns',    fontName='Helvetica-Bold', fontSize=11, leading=16,
            textColor=BLUE_H)
sFormula= S('sFormula',fontName='Helvetica-Bold', fontSize=18, leading=24,
            alignment=TA_CENTER, textColor=BLUE_H)
sExp    = S('sExp',    fontName='Helvetica', fontSize=10, leading=15,
            textColor=BLACK)
sArabic = S('sArabic', fontName='Helvetica', fontSize=9, leading=13,
            alignment=TA_RIGHT)

story = []

# ══════════════════════════════════════════════════════════════════════════════
# PAGE 1
# ══════════════════════════════════════════════════════════════════════════════

# ── University header (3 columns) ────────────────────────────────────────────
hdr_data = [[
    Paragraph('<b>KINGDOM OF SAUDI ARABIA<br/>MINISTRY OF EDUCATION – JAZAN UNIVERSITY<br/>'
              'COLLEGE OF ENGINEERING &amp; COMPUTER SCIENCE</b>', sSmall),
    Paragraph('<b>〔 JAZAN UNIVERSITY 〕<br/>College of Engineering<br/>&amp; Computer Science</b>',
              S('logo', fontName='Helvetica-Bold', fontSize=9, leading=13, alignment=TA_CENTER)),
    Paragraph('<b>المملكة العربية السعودية<br/>وزارة التعليم - جامعة جازان<br/>كلية الهندسة وعلوم الحاسب</b>',
              S('ar', fontName='Helvetica-Bold', fontSize=9, leading=13, alignment=TA_RIGHT)),
]]
hdr_tbl = Table(hdr_data, colWidths=[6.5*cm, 4*cm, 6.5*cm])
hdr_tbl.setStyle(TableStyle([
    ('VALIGN',    (0,0),(-1,-1), 'MIDDLE'),
    ('LINEBELOW', (0,0),(-1,-1), 1.5, NAVY),
    ('TOPPADDING',(0,0),(-1,-1), 6),
    ('BOTTOMPADDING',(0,0),(-1,-1), 6),
]))
story.append(hdr_tbl)
story.append(Spacer(1, 8))

# ── Exam title ────────────────────────────────────────────────────────────────
story.append(Paragraph('FINAL LAB EXAM', sTitle))
story.append(Paragraph('BACHELOR IN INFORMATION TECHNOLOGY',
             S('st2', fontName='Helvetica-Bold', fontSize=12, leading=17,
               alignment=TA_CENTER, textColor=BLACK)))
story.append(Spacer(1, 4))
story.append(Paragraph(
    'Academic Year: 2025 – 2026&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
    'Term: &nbsp;● First &nbsp;/☑ (Second)', sSub))
story.append(Spacer(1, 8))

# ── Student info table ────────────────────────────────────────────────────────
si_data = [
    [Paragraph('<b>Student Name:</b> ________________________________', sNormal),
     Paragraph('<b>Student ID:</b> _______________', sNormal)],
    [Paragraph('<b>Section Number:</b> <font color="red">14611</font>', sNormal),
     Paragraph('<b>Exam Date:</b> <font color="red">20/05/2026</font>', sNormal)],
    [Paragraph('<b>Course Name:</b> Database Concepts and Design', sNormal),
     Paragraph('<b>Exam Time:</b>', sNormal)],
    [Paragraph('<b>Course Code:</b> INFS-211&nbsp;&nbsp;&nbsp;'
               '<b>Course Level:</b> 3/4&nbsp;&nbsp;&nbsp;<b>Total Marks:</b>', sNormal),
     Paragraph('<b>10</b>', sCenterB)],
]
si_tbl = Table(si_data, colWidths=[10*cm, 7*cm])
si_tbl.setStyle(TableStyle([
    ('BOX',        (0,0),(-1,-1), 1, BLACK),
    ('INNERGRID',  (0,0),(-1,-1), 0.5, BLACK),
    ('VALIGN',     (0,0),(-1,-1), 'MIDDLE'),
    ('TOPPADDING', (0,0),(-1,-1), 4),
    ('BOTTOMPADDING',(0,0),(-1,-1), 4),
    ('LEFTPADDING',(0,0),(-1,-1), 6),
]))
story.append(si_tbl)
story.append(Spacer(1, 10))

# ── Marks Summary ─────────────────────────────────────────────────────────────
story.append(Paragraph('<b>Marks Summary (10)</b>',
             S('ms', fontName='Helvetica-Bold', fontSize=12, leading=16,
               alignment=TA_CENTER)))
story.append(Spacer(1, 4))
ms_data = [
    [Paragraph('<b>Question #</b>', sCenterB),
     Paragraph('<b>Performance Indicator</b>', sCenterB),
     Paragraph('<b>Total Marks</b>', sCenterB),
     Paragraph('<b>Obtained Marks</b>', sCenterB)],
    [Paragraph('Q1', sCenter),
     Paragraph('PI – (2.3)', sCenter),
     Paragraph('10', sCenter),
     Paragraph('', sCenter)],
]
ms_tbl = Table(ms_data, colWidths=[4*cm, 5*cm, 3.5*cm, 4.5*cm])
ms_tbl.setStyle(TableStyle([
    ('BOX',         (0,0),(-1,-1), 1, BLACK),
    ('INNERGRID',   (0,0),(-1,-1), 0.5, BLACK),
    ('BACKGROUND',  (0,0),(-1,0), LGREY),
    ('TOPPADDING',  (0,0),(-1,-1), 4),
    ('BOTTOMPADDING',(0,0),(-1,-1), 4),
    ('VALIGN',      (0,0),(-1,-1), 'MIDDLE'),
]))
story.append(ms_tbl)
story.append(Spacer(1, 6))

sig_data = [[
    Paragraph("<b>Teacher's Signature</b>", sNormal),
    Paragraph('<b><font color="red">Hussein Rajab</font></b>', sNormal),
    Paragraph('<b>10</b>', sCenterB),
]]
sig_tbl = Table(sig_data, colWidths=[5*cm, 9*cm, 3*cm])
sig_tbl.setStyle(TableStyle([
    ('VALIGN', (0,0),(-1,-1), 'MIDDLE'),
    ('TOPPADDING',(0,0),(-1,-1), 2),
    ('BOTTOMPADDING',(0,0),(-1,-1), 2),
]))
story.append(sig_tbl)
story.append(Spacer(1, 10))

# ── CLO-PI-SO Mapping ─────────────────────────────────────────────────────────
story.append(Paragraph('<b>CLO-PI-SO Mapping</b>',
             S('clo_h', fontName='Helvetica-Bold', fontSize=11, leading=15,
               alignment=TA_CENTER)))
story.append(Spacer(1, 4))
clo_data = [
    ['CLO IDs','SO-1','SO-2','SO-3','SO-4','SO-5','SO-6'],
    ['CLO#01','PI 1.1','-','-','-','-','-'],
    ['CLO#02','PI 1.3','-','-','-','-','-'],
    ['CLO#03','-','PI 2.1','-','-','-','-'],
    ['CLO#04','-','PI 2.3','-','-','-','-'],
    ['CLO#05','PI 3.1','','','','',''],
    ['CLO#06','PI 3.2','','','','',''],
]
clo_tbl = Table(
    [[Paragraph(f'<b>{c}</b>' if r==0 else c,
      S('cc', fontName='Helvetica-Bold' if r==0 or c_i==0 else 'Helvetica',
        fontSize=9, leading=12, alignment=TA_CENTER))
      for c_i,c in enumerate(row)]
     for r,row in enumerate(clo_data)],
    colWidths=[2.5*cm]+[2.4*cm]*6
)
clo_tbl.setStyle(TableStyle([
    ('BOX',         (0,0),(-1,-1), 1, BLACK),
    ('INNERGRID',   (0,0),(-1,-1), 0.5, BLACK),
    ('BACKGROUND',  (0,0),(-1,0), LGREY),
    ('TOPPADDING',  (0,0),(-1,-1), 3),
    ('BOTTOMPADDING',(0,0),(-1,-1), 3),
    ('VALIGN',      (0,0),(-1,-1), 'MIDDLE'),
]))
story.append(clo_tbl)
story.append(Spacer(1, 10))

# ── Instructions ──────────────────────────────────────────────────────────────
story.append(Paragraph('<b><u>Instructions for Students:</u></b>', sBold))
story.append(Spacer(1, 4))
story.append(Paragraph('<b>1.&nbsp; Write your name and student ID in the giving Form</b>', sNormal))
story.append(Paragraph('<b>2.&nbsp; The questions from Ch5</b>', sNormal))
story.append(Spacer(1, 4))
story.append(Paragraph('<b>Submit the answer as a word document</b>', sNormal))
story.append(Spacer(1, 10))
story.append(HRFlowable(width='100%', thickness=1, color=BLACK))
story.append(Spacer(1, 6))
story.append(Paragraph(
    'Q1. Answer <b>the questions</b> of the following questions. '
    '<b>Question 1.1(a) and 1.1(b) is compulsory.</b>', sNormal))

# ══════════════════════════════════════════════════════════════════════════════
# PAGE 2
# ══════════════════════════════════════════════════════════════════════════════
story.append(PageBreak())

# ── Figure 6.1 ────────────────────────────────────────────────────────────────
story.append(Paragraph('<b>Figure 6.1</b>', sSmallB))
story.append(Paragraph(
    'Results of SELECT and PROJECT operations. '
    '(a) σ<sub>(Dno=4 AND Salary&gt;25000) OR (Dno=5 AND Salary&gt;30000)</sub>(EMPLOYEE). '
    '(b) π<sub>Lname, Fname, Salary</sub>(EMPLOYEE). '
    '(c) π<sub>Sex, Salary</sub>(EMPLOYEE).', sSmall))
story.append(Spacer(1, 8))

# ── EMPLOYEE relation table ───────────────────────────────────────────────────
story.append(Paragraph('<b>EMPLOYEE Relation (Reference Table):</b>',
             S('ref', fontName='Helvetica-Bold', fontSize=10, leading=14)))
story.append(Spacer(1, 4))

emp_cols = ['Fname','Minit','Lname','Ssn','Bdate','Address','Sex','Salary','Super_ssn','Dno']
emp_rows = [
    ('John',    'B','Smith',  '123456789','09-Jan-65','731 Fondren, Houston TX',  'M','30,000','333445555','5'),
    ('Franklin','T','Wong',   '333445555','08-Dec-55','638 Voss, Houston TX',     'M','40,000','888665555','5'),
    ('Alicia',  'J','Zelaya', '999887777','19-Jan-68','3321 Castle, Spring TX',   'F','25,000','987654321','4'),
    ('Jennifer','S','Wallace','987654321','20-Jun-41','291 Berry, Bellaire TX',   'F','43,000','888665555','4'),
    ('Ramesh',  'K','Narayan','666884444','15-Sep-62','975 Fire Oak, Humble TX',  'M','38,000','333445555','5'),
    ('Joyce',   'A','English','453453453','31-Jul-72','5631 Rice, Houston TX',    'F','25,000','333445555','5'),
    ('Ahmad',   'V','Jabbar', '987987987','29-Mar-69','980 Dallas, Houston TX',   'M','25,000','987654321','4'),
    ('James',   'E','Borg',   '888665555','10-Nov-37','450 Stone, Houston TX',    'M','55,000','NULL',     '1'),
]

def emp_cell(txt, hdr=False):
    style = S('ec', fontName='Helvetica-Bold' if hdr else 'Helvetica',
              fontSize=7.5, leading=10, alignment=TA_CENTER,
              textColor=WHITE if hdr else BLACK)
    return Paragraph(txt, style)

emp_tbl_data = [[emp_cell(c, hdr=True) for c in emp_cols]]
for i, row in enumerate(emp_rows):
    emp_tbl_data.append([emp_cell(v) for v in row])

emp_tbl = Table(emp_tbl_data,
    colWidths=[1.6*cm,1.0*cm,1.7*cm,2.0*cm,1.8*cm,3.5*cm,0.8*cm,1.5*cm,2.0*cm,0.8*cm])

emp_style = [
    ('BACKGROUND',  (0,0),(-1,0), DGREY),
    ('BOX',         (0,0),(-1,-1), 1, BLACK),
    ('INNERGRID',   (0,0),(-1,-1), 0.3, colors.HexColor('#AAAAAA')),
    ('TOPPADDING',  (0,0),(-1,-1), 3),
    ('BOTTOMPADDING',(0,0),(-1,-1), 3),
    ('VALIGN',      (0,0),(-1,-1), 'MIDDLE'),
]
for i in range(len(emp_rows)):
    bg = ALTROW if i%2==0 else WHITE
    emp_style.append(('BACKGROUND',(0,i+1),(-1,i+1), bg))

emp_tbl.setStyle(TableStyle(emp_style))
story.append(emp_tbl)
story.append(Spacer(1, 12))

# ── Q1.1 heading ──────────────────────────────────────────────────────────────
story.append(Paragraph(
    '<b>1.1&nbsp; Use above relation EMPLOYEE and write the relational algebra query.</b>',
    S('q11', fontName='Helvetica-Bold', fontSize=11, leading=16)))
story.append(Spacer(1, 10))

# ══════════════════════════════════════════════════════════════════════════════
# ANSWER (a)
# ══════════════════════════════════════════════════════════════════════════════
story.append(Paragraph(
    '<b>a.&nbsp;&nbsp; Retrieve the records from EMPLOYEE whose department is 4.</b>',
    S('qa', fontName='Helvetica-Bold', fontSize=11, leading=16)))
story.append(Spacer(1, 6))

story.append(Paragraph('<b><u>Answer (a):</u></b>',
             S('al', fontName='Helvetica-Bold', fontSize=11, leading=16,
               textColor=BLUE_H)))
story.append(Spacer(1, 4))
story.append(Paragraph(
    'We apply the <b>SELECT operation (σ)</b> to the EMPLOYEE relation with the '
    'condition <b>Dno = 4</b>.  This returns all tuples where the department '
    'number attribute equals 4, preserving all 10 columns.', sExp))
story.append(Spacer(1, 8))

# Formula box (a)
formula_a = Table(
    [[Paragraph('σ<sub>Dno = 4</sub>  (EMPLOYEE)',
        S('fa', fontName='Helvetica-Bold', fontSize=20, leading=28,
          alignment=TA_CENTER, textColor=BLUE_H))]],
    colWidths=[17*cm]
)
formula_a.setStyle(TableStyle([
    ('BOX',         (0,0),(-1,-1), 2, BLUE_H),
    ('BACKGROUND',  (0,0),(-1,-1), colors.HexColor('#EBF3FB')),
    ('TOPPADDING',  (0,0),(-1,-1), 10),
    ('BOTTOMPADDING',(0,0),(-1,-1), 10),
    ('ALIGN',       (0,0),(-1,-1), 'CENTER'),
]))
story.append(formula_a)
story.append(Spacer(1, 8))

story.append(Paragraph('<b>Result — 3 tuples returned (employees in Department 4):</b>',
             S('rh', fontName='Helvetica-Bold', fontSize=10, leading=14,
               textColor=BLUE_H)))
story.append(Spacer(1, 4))

res_a = [
    ('Alicia',  'J','Zelaya', '999887777','19-Jan-68','3321 Castle, Spring TX',  'F','25,000','987654321','4'),
    ('Jennifer','S','Wallace','987654321','20-Jun-41','291 Berry, Bellaire TX',  'F','43,000','888665555','4'),
    ('Ahmad',   'V','Jabbar', '987987987','29-Mar-69','980 Dallas, Houston TX',  'M','25,000','987654321','4'),
]
res_a_data = [[emp_cell(c, hdr=True) for c in emp_cols]]
for row in res_a:
    res_a_data.append([emp_cell(v) for v in row])

res_a_tbl = Table(res_a_data,
    colWidths=[1.6*cm,1.0*cm,1.7*cm,2.0*cm,1.8*cm,3.5*cm,0.8*cm,1.5*cm,2.0*cm,0.8*cm])
res_a_tbl.setStyle(TableStyle([
    ('BACKGROUND',  (0,0),(-1,0), BLUE_H),
    ('BACKGROUND',  (0,1),(-1,-1), GREEN),
    ('BOX',         (0,0),(-1,-1), 1, BLACK),
    ('INNERGRID',   (0,0),(-1,-1), 0.3, colors.HexColor('#336633')),
    ('TOPPADDING',  (0,0),(-1,-1), 3),
    ('BOTTOMPADDING',(0,0),(-1,-1), 3),
    ('VALIGN',      (0,0),(-1,-1), 'MIDDLE'),
    ('TEXTCOLOR',   (9,1),(9,-1), colors.HexColor('#225511')),
    ('FONTNAME',    (9,1),(9,-1), 'Helvetica-Bold'),
]))
story.append(res_a_tbl)
story.append(Spacer(1, 16))

# ══════════════════════════════════════════════════════════════════════════════
# ANSWER (b)
# ══════════════════════════════════════════════════════════════════════════════
story.append(Paragraph(
    '<b>b.&nbsp;&nbsp; Select the tuples where salary &gt; 40000.</b>',
    S('qb', fontName='Helvetica-Bold', fontSize=11, leading=16)))
story.append(Spacer(1, 6))

story.append(Paragraph('<b><u>Answer (b):</u></b>',
             S('bl', fontName='Helvetica-Bold', fontSize=11, leading=16,
               textColor=BLUE_H)))
story.append(Spacer(1, 4))
story.append(Paragraph(
    'We apply the <b>SELECT operation (σ)</b> to the EMPLOYEE relation with the '
    'condition <b>Salary &gt; 40000</b>.  This returns every tuple whose Salary '
    'attribute is strictly greater than 40,000, preserving all 10 columns.', sExp))
story.append(Spacer(1, 8))

# Formula box (b)
formula_b = Table(
    [[Paragraph('σ<sub>Salary &gt; 40000</sub>  (EMPLOYEE)',
        S('fb', fontName='Helvetica-Bold', fontSize=20, leading=28,
          alignment=TA_CENTER, textColor=BLUE_H))]],
    colWidths=[17*cm]
)
formula_b.setStyle(TableStyle([
    ('BOX',         (0,0),(-1,-1), 2, BLUE_H),
    ('BACKGROUND',  (0,0),(-1,-1), colors.HexColor('#EBF3FB')),
    ('TOPPADDING',  (0,0),(-1,-1), 10),
    ('BOTTOMPADDING',(0,0),(-1,-1), 10),
    ('ALIGN',       (0,0),(-1,-1), 'CENTER'),
]))
story.append(formula_b)
story.append(Spacer(1, 8))

story.append(Paragraph('<b>Result — 2 tuples returned (employees with Salary &gt; 40,000):</b>',
             S('rh2', fontName='Helvetica-Bold', fontSize=10, leading=14,
               textColor=BLUE_H)))
story.append(Spacer(1, 4))

res_b = [
    ('Jennifer','S','Wallace','987654321','20-Jun-41','291 Berry, Bellaire TX','F','43,000','888665555','4'),
    ('James',   'E','Borg',   '888665555','10-Nov-37','450 Stone, Houston TX', 'M','55,000','NULL',     '1'),
]
res_b_data = [[emp_cell(c, hdr=True) for c in emp_cols]]
for row in res_b:
    res_b_data.append([emp_cell(v) for v in row])

res_b_tbl = Table(res_b_data,
    colWidths=[1.6*cm,1.0*cm,1.7*cm,2.0*cm,1.8*cm,3.5*cm,0.8*cm,1.5*cm,2.0*cm,0.8*cm])
res_b_tbl.setStyle(TableStyle([
    ('BACKGROUND',  (0,0),(-1,0), BLUE_H),
    ('BACKGROUND',  (0,1),(-1,-1), ORANGE),
    ('BOX',         (0,0),(-1,-1), 1, BLACK),
    ('INNERGRID',   (0,0),(-1,-1), 0.3, colors.HexColor('#C55A11')),
    ('TOPPADDING',  (0,0),(-1,-1), 3),
    ('BOTTOMPADDING',(0,0),(-1,-1), 3),
    ('VALIGN',      (0,0),(-1,-1), 'MIDDLE'),
    ('TEXTCOLOR',   (7,1),(7,-1), colors.HexColor('#843200')),
    ('FONTNAME',    (7,1),(7,-1), 'Helvetica-Bold'),
]))
story.append(res_b_tbl)
story.append(Spacer(1, 20))

# ── Page 2 footer ─────────────────────────────────────────────────────────────
story.append(HRFlowable(width='100%', thickness=0.8, color=BLACK))
story.append(Spacer(1, 4))
story.append(Paragraph(
    'ITEC-211 / Database Concepts and Design / 2025-2026 / Second Semester'
    '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
    'Page 2 of 2', sFooter))

# ── Build PDF ─────────────────────────────────────────────────────────────────
doc.build(story)
print(f'PDF saved → {OUT}')
