"""
Recreates the INFS-211 Final Lab Exam exactly as the original PDF,
with answers filled in for Q1.1(a) and Q1.1(b).
"""

from docx import Document
from docx.shared import Pt, RGBColor, Inches, Cm, Twips
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

doc = Document()

# ── Page setup (A4, narrow margins to match PDF) ──────────────────────────────
sec = doc.sections[0]
sec.page_width    = Cm(21.0)
sec.page_height   = Cm(29.7)
sec.top_margin    = Cm(1.5)
sec.bottom_margin = Cm(1.5)
sec.left_margin   = Cm(2.0)
sec.right_margin  = Cm(2.0)

# ── Utility helpers ───────────────────────────────────────────────────────────
def shd(cell, fill):
    tc = cell._tc
    pr = tc.get_or_add_tcPr()
    s  = OxmlElement('w:shd')
    s.set(qn('w:val'),   'clear')
    s.set(qn('w:color'), 'auto')
    s.set(qn('w:fill'),  fill)
    pr.append(s)

def borders(cell, color='000000', sz=4):
    tc = cell._tc
    pr = tc.get_or_add_tcPr()
    b  = OxmlElement('w:tcBorders')
    for side in ('top','left','bottom','right','insideH','insideV'):
        el = OxmlElement(f'w:{side}')
        el.set(qn('w:val'),   'single')
        el.set(qn('w:sz'),    str(sz))
        el.set(qn('w:space'),'0')
        el.set(qn('w:color'), color)
        b.append(el)
    pr.append(b)

def no_borders(cell):
    tc = cell._tc
    pr = tc.get_or_add_tcPr()
    b  = OxmlElement('w:tcBorders')
    for side in ('top','left','bottom','right','insideH','insideV'):
        el = OxmlElement(f'w:{side}')
        el.set(qn('w:val'),   'none')
        el.set(qn('w:sz'),    '0')
        el.set(qn('w:space'),'0')
        el.set(qn('w:color'), 'auto')
        b.append(el)
    pr.append(b)

def cell_para(cell, text, bold=False, size=10, align=WD_ALIGN_PARAGRAPH.LEFT,
              color='000000', italic=False, font='Times New Roman',
              space_b=0, space_a=0, underline=False, clear=True):
    if clear:
        p = cell.paragraphs[0]
    else:
        p = cell.add_paragraph()
    p.alignment = align
    p.paragraph_format.space_before = Pt(space_b)
    p.paragraph_format.space_after  = Pt(space_a)
    if text:
        r = p.add_run(text)
        r.bold      = bold
        r.italic    = italic
        r.underline = underline
        r.font.name = font
        r.font.size = Pt(size)
        r.font.color.rgb = RGBColor(*bytes.fromhex(color))
    return p

def add_para(text='', bold=False, size=11, align=WD_ALIGN_PARAGRAPH.LEFT,
             color='000000', italic=False, font='Times New Roman',
             space_b=0, space_a=4, underline=False):
    p = doc.add_paragraph()
    p.alignment = align
    p.paragraph_format.space_before = Pt(space_b)
    p.paragraph_format.space_after  = Pt(space_a)
    if text:
        r = p.add_run(text)
        r.bold      = bold
        r.italic    = italic
        r.underline = underline
        r.font.name = font
        r.font.size = Pt(size)
        r.font.color.rgb = RGBColor(*bytes.fromhex(color))
    return p

def set_col_width(table, col_idx, width_cm):
    for row in table.rows:
        row.cells[col_idx].width = Cm(width_cm)

def merge_row_cells(table, row_idx, start, end):
    row = table.rows[row_idx]
    a = row.cells[start]
    b = row.cells[end]
    a.merge(b)
    return a

# ══════════════════════════════════════════════════════════════════════════════
#  PAGE 1
# ══════════════════════════════════════════════════════════════════════════════

# ── TOP HEADER (3-column) ────────────────────────────────────────────────────
hdr_tbl = doc.add_table(rows=1, cols=3)
hdr_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
hdr_tbl.style = 'Table Grid'
for cell in hdr_tbl.rows[0].cells:
    no_borders(cell)

# Left column – English
lc = hdr_tbl.rows[0].cells[0]
lc.width = Cm(6.0)
cell_para(lc, 'KINGDOM OF SAUDI ARABIA', bold=True, size=8,
          align=WD_ALIGN_PARAGRAPH.LEFT)
cell_para(lc, 'MINISTRY OF EDUCATION – JAZAN UNIVERSITY', bold=True, size=8,
          align=WD_ALIGN_PARAGRAPH.LEFT, clear=False)
cell_para(lc, 'COLLEGE OF ENGINEERING & COMPUTER SCIENCE', bold=True, size=8,
          align=WD_ALIGN_PARAGRAPH.LEFT, clear=False)

# Centre – Logo placeholder (circle with JU text)
cc = hdr_tbl.rows[0].cells[1]
cc.width = Cm(5.0)
cp = cc.paragraphs[0]
cp.alignment = WD_ALIGN_PARAGRAPH.CENTER
cp.paragraph_format.space_before = Pt(2)
cp.paragraph_format.space_after  = Pt(2)
# Draw a simple text-art seal
r = cp.add_run('〔  JAZAN\nUNIVERSITY  〕')
r.font.name = 'Arial'; r.font.size = Pt(9); r.bold = True

# Right column – Arabic
rc = hdr_tbl.rows[0].cells[2]
rc.width = Cm(6.0)
cell_para(rc, 'المملكة العربية السعودية', bold=True, size=9,
          align=WD_ALIGN_PARAGRAPH.RIGHT, font='Arial')
cell_para(rc, 'وزارة التعليم - جامعة جازان', bold=True, size=9,
          align=WD_ALIGN_PARAGRAPH.RIGHT, font='Arial', clear=False)
cell_para(rc, 'كلية الهندسة وعلوم الحاسب', bold=True, size=9,
          align=WD_ALIGN_PARAGRAPH.RIGHT, font='Arial', clear=False)

add_para()

# ── EXAM TITLE ────────────────────────────────────────────────────────────────
add_para('FINAL LAB EXAM', bold=True, size=14,
         align=WD_ALIGN_PARAGRAPH.CENTER, space_b=4, space_a=2)
add_para('BACHELOR IN INFORMATION TECHNOLOGY', bold=True, size=12,
         align=WD_ALIGN_PARAGRAPH.CENTER, space_a=2)
add_para('Academic Year: 2025 – 2026\t\tTerm:  ● First  /þ  (Second)',
         size=11, align=WD_ALIGN_PARAGRAPH.CENTER, space_a=4)

# ── STUDENT INFO TABLE ────────────────────────────────────────────────────────
si = doc.add_table(rows=4, cols=4)
si.alignment = WD_TABLE_ALIGNMENT.CENTER
si.style = 'Table Grid'
for row in si.rows:
    for cell in row.cells:
        borders(cell, '000000', 6)

# Row 0: Student Name | (value) | Student ID: | (value)
r0 = si.rows[0].cells
cell_para(r0[0], 'Student Name:', bold=True, size=10)
r0[0].merge(r0[1])   # name spans 2 cells → then student id
# redo after merge
si.rows[0].cells[0].paragraphs[0].clear()
rr = si.rows[0].cells[0].paragraphs[0]
rr.alignment = WD_ALIGN_PARAGRAPH.LEFT
run1 = rr.add_run('Student Name:')
run1.bold = True; run1.font.name = 'Times New Roman'; run1.font.size = Pt(10)
run2 = rr.add_run('  _____________________________')
run2.font.name = 'Times New Roman'; run2.font.size = Pt(10)

cell_para(si.rows[0].cells[2], 'Student ID:', bold=True, size=10)
cell_para(si.rows[0].cells[3], '_______________', size=10)

# Row 1: Section Number | 14611 | Exam Date | 20/05/2026
r1 = si.rows[1].cells
cell_para(r1[0], 'Section Number:', bold=True, size=10)
p14 = r1[1].paragraphs[0]; p14.alignment = WD_ALIGN_PARAGRAPH.CENTER
ru = p14.add_run('14611'); ru.font.name='Times New Roman'; ru.font.size=Pt(10)
ru.font.color.rgb = RGBColor(0xFF,0x00,0x00)
cell_para(r1[2], 'Exam Date:', bold=True, size=10)
p_date = r1[3].paragraphs[0]; p_date.alignment = WD_ALIGN_PARAGRAPH.CENTER
rd = p_date.add_run('20/05/2026')
rd.font.name='Times New Roman'; rd.font.size=Pt(10)
rd.font.color.rgb = RGBColor(0xFF,0x00,0x00)

# Row 2: Course Name | Database Concepts and Design | Exam Time | (blank)
r2 = si.rows[2].cells
cell_para(r2[0], 'Course Name:', bold=True, size=10)
p_cn = r2[1].paragraphs[0]
rcn1 = p_cn.add_run('Database Concepts and Design')
rcn1.font.name='Times New Roman'; rcn1.font.size=Pt(10)
rcn2_p = p_cn.add_run('')
cell_para(r2[2], 'Exam Time:', bold=True, size=10)
cell_para(r2[3], '', size=10)

# Row 3: Course Code | INFS-211 | Course Level | 3/4 | Total Marks | 10
r3 = si.rows[3].cells
cell_para(r3[0], 'Course Code:', bold=True, size=10)
p_cc = r3[1].paragraphs[0]
rcc = p_cc.add_run('INFS-211')
rcc.font.name='Times New Roman'; rcc.font.size=Pt(10)
cell_para(r3[2], 'Course Level:  3/4        Total Marks:', bold=True, size=10)
p_tm = r3[3].paragraphs[0]; p_tm.alignment = WD_ALIGN_PARAGRAPH.CENTER
rtm = p_tm.add_run('10')
rtm.bold=True; rtm.font.name='Times New Roman'; rtm.font.size=Pt(11)

add_para()

# ── MARKS SUMMARY ─────────────────────────────────────────────────────────────
add_para('Marks Summary (10)', bold=True, size=12,
         align=WD_ALIGN_PARAGRAPH.CENTER, space_a=4)

ms = doc.add_table(rows=2, cols=4)
ms.alignment = WD_TABLE_ALIGNMENT.CENTER
ms.style = 'Table Grid'
for row in ms.rows:
    for cell in row.cells:
        borders(cell, '000000', 6)

ms_hdr = ms.rows[0].cells
for c, h in zip(ms_hdr, ['Question #','Performance Indicator','Total Marks','Obtained Marks']):
    cell_para(c, h, bold=True, size=10, align=WD_ALIGN_PARAGRAPH.CENTER)

ms_r1 = ms.rows[1].cells
cell_para(ms_r1[0], 'Q1', size=10, align=WD_ALIGN_PARAGRAPH.CENTER)
cell_para(ms_r1[1], 'PI – (2.3)', size=10, align=WD_ALIGN_PARAGRAPH.CENTER)
cell_para(ms_r1[2], '10', size=10, align=WD_ALIGN_PARAGRAPH.CENTER)
cell_para(ms_r1[3], '', size=10)

# Teacher signature row (no borders on left, just text)
add_para()
p_sig = doc.add_paragraph()
p_sig.paragraph_format.space_before = Pt(2)
p_sig.paragraph_format.space_after  = Pt(4)
rs1 = p_sig.add_run("Teacher's Signature\t\t")
rs1.bold=True; rs1.font.name='Times New Roman'; rs1.font.size=Pt(11)
rs2 = p_sig.add_run('Hussein Rajab')
rs2.bold=True; rs2.font.name='Times New Roman'; rs2.font.size=Pt(11)
rs2.font.color.rgb = RGBColor(0xFF,0x00,0x00)
rs3 = p_sig.add_run('\t\t\t10')
rs3.bold=True; rs3.font.name='Times New Roman'; rs3.font.size=Pt(11)

add_para()

# ── CLO-PI-SO MAPPING ─────────────────────────────────────────────────────────
add_para('CLO-PI-SO Mapping', bold=True, size=11,
         align=WD_ALIGN_PARAGRAPH.CENTER, space_a=2)

clo = doc.add_table(rows=7, cols=7)
clo.alignment = WD_TABLE_ALIGNMENT.CENTER
clo.style = 'Table Grid'
for row in clo.rows:
    for cell in row.cells:
        borders(cell, '000000', 4)

clo_headers = ['CLO IDs','SO-1','SO-2','SO-3','SO-4','SO-5','SO-6']
for i, h in enumerate(clo_headers):
    cell_para(clo.rows[0].cells[i], h, bold=True, size=9,
              align=WD_ALIGN_PARAGRAPH.CENTER)
    shd(clo.rows[0].cells[i], 'D9D9D9')

clo_data = [
    ('CLO#01','PI 1.1','-','-','-','-','-'),
    ('CLO#02','PI 1.3','-','-','-','-','-'),
    ('CLO#03','-','PI 2.1','-','-','-','-'),
    ('CLO#04','-','PI 2.3','-','-','-','-'),
    ('CLO#05','PI 3.1','','','','',''),
    ('CLO#06','PI 3.2','','','','',''),
]
for r_i, row_d in enumerate(clo_data):
    for c_i, val in enumerate(row_d):
        cell_para(clo.rows[r_i+1].cells[c_i], val, size=9,
                  align=WD_ALIGN_PARAGRAPH.CENTER,
                  bold=(c_i==0))

add_para()

# ── INSTRUCTIONS ──────────────────────────────────────────────────────────────
p_inst_hdr = doc.add_paragraph()
p_inst_hdr.paragraph_format.space_before = Pt(4)
p_inst_hdr.paragraph_format.space_after  = Pt(2)
ri = p_inst_hdr.add_run('Instructions for Students:')
ri.bold=True; ri.underline=True
ri.font.name='Times New Roman'; ri.font.size=Pt(11)

add_para('1.  Write your name and student ID in the giving Form',
         bold=True, size=10, space_a=1)
add_para('2.  The questions from Ch5', bold=True, size=10, space_a=4)
add_para('Submit the answer as a word document', bold=True, size=10,
         space_b=0, space_a=8)

# ── Q1 instruction ────────────────────────────────────────────────────────────
p_q1 = doc.add_paragraph()
p_q1.paragraph_format.space_before = Pt(2)
p_q1.paragraph_format.space_after  = Pt(4)
rq1a = p_q1.add_run('Q1. Answer ')
rq1a.font.name='Times New Roman'; rq1a.font.size=Pt(11)
rq1b = p_q1.add_run('the questions')
rq1b.bold=True; rq1b.font.name='Times New Roman'; rq1b.font.size=Pt(11)
rq1c = p_q1.add_run(' of the following questions. ')
rq1c.font.name='Times New Roman'; rq1c.font.size=Pt(11)
rq1d = p_q1.add_run('Question 1.1(a) and 1.1(b) is compulsory.')
rq1d.bold=True; rq1d.font.name='Times New Roman'; rq1d.font.size=Pt(11)

# ── Page footer line ──────────────────────────────────────────────────────────
add_para('─' * 90, size=7, align=WD_ALIGN_PARAGRAPH.CENTER, space_b=2, space_a=2)

# ══════════════════════════════════════════════════════════════════════════════
#  PAGE 2  (page break, then questions + answers)
# ══════════════════════════════════════════════════════════════════════════════
doc.add_page_break()

# ── Figure 6.1 caption ────────────────────────────────────────────────────────
p_fig = doc.add_paragraph()
p_fig.paragraph_format.space_before = Pt(0)
p_fig.paragraph_format.space_after  = Pt(2)
rf1 = p_fig.add_run('Figure 6.1')
rf1.bold=True; rf1.font.name='Times New Roman'; rf1.font.size=Pt(10)

p_fig2 = doc.add_paragraph()
p_fig2.paragraph_format.space_before = Pt(0)
p_fig2.paragraph_format.space_after  = Pt(6)
rf2 = p_fig2.add_run(
    'Results of SELECT and PROJECT operations.  '
    '(a) σ₍no=4 AND Salary>25000₎ OR (Dno=5 AND Salary>30000)(EMPLOYEE).  '
    '(b) πⱼLname, Fname, Salaryⱽ(EMPLOYEE).  '
    '(c) πⱼSex, Salaryⱽ(EMPLOYEE).')
rf2.font.name='Times New Roman'; rf2.font.size=Pt(9)

# ── EMPLOYEE Relation table (the reference/given data) ───────────────────────
add_para('EMPLOYEE Relation (Given Reference Table):', bold=True, size=10,
         space_b=4, space_a=3)

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

emp_tbl = doc.add_table(rows=len(emp_rows)+1, cols=len(emp_cols))
emp_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
emp_tbl.style = 'Table Grid'

for i, col in enumerate(emp_cols):
    c = emp_tbl.rows[0].cells[i]
    shd(c, '2E4057')
    borders(c, '000000', 6)
    cp = c.paragraphs[0]; cp.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = cp.add_run(col); r.bold=True
    r.font.name='Calibri'; r.font.size=Pt(8)
    r.font.color.rgb = RGBColor(0xFF,0xFF,0xFF)

for ri, row_d in enumerate(emp_rows):
    bg = 'F2F2F2' if ri%2==0 else 'FFFFFF'
    for ci, val in enumerate(row_d):
        c = emp_tbl.rows[ri+1].cells[ci]
        shd(c, bg)
        borders(c, 'AAAAAA', 4)
        cp = c.paragraphs[0]; cp.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = cp.add_run(val)
        r.font.name='Calibri'; r.font.size=Pt(8)
        if val=='NULL':
            r.font.color.rgb=RGBColor(0x99,0x99,0x99); r.italic=True

add_para()

# ── Q1.1 ──────────────────────────────────────────────────────────────────────
p_11 = doc.add_paragraph()
p_11.paragraph_format.space_before = Pt(6)
p_11.paragraph_format.space_after  = Pt(4)
r11 = p_11.add_run('1.1  Use above relation EMPLOYEE and write the relational algebra query.')
r11.bold=True; r11.font.name='Times New Roman'; r11.font.size=Pt(11)

# ══════════════════════════════════════════════════════════════════════════════
#  ANSWER (a)
# ══════════════════════════════════════════════════════════════════════════════
p_qa = doc.add_paragraph()
p_qa.paragraph_format.space_before = Pt(8)
p_qa.paragraph_format.space_after  = Pt(2)
rqa1 = p_qa.add_run('a.  ')
rqa1.bold=True; rqa1.font.name='Times New Roman'; rqa1.font.size=Pt(11)
rqa2 = p_qa.add_run('Retrieve the records from EMPLOYEE whose department is 4.')
rqa2.font.name='Times New Roman'; rqa2.font.size=Pt(11)

# Answer label
p_ans_a = doc.add_paragraph()
p_ans_a.paragraph_format.space_before = Pt(4)
p_ans_a.paragraph_format.space_after  = Pt(2)
ra_lbl = p_ans_a.add_run('Answer (a):')
ra_lbl.bold=True; ra_lbl.underline=True
ra_lbl.font.name='Times New Roman'; ra_lbl.font.size=Pt(11)
ra_lbl.font.color.rgb = RGBColor(0x00,0x00,0x80)

# Explanation
p_exp_a = doc.add_paragraph()
p_exp_a.paragraph_format.space_before = Pt(2)
p_exp_a.paragraph_format.space_after  = Pt(4)
re_a = p_exp_a.add_run(
    'We use the SELECT operation (σ) to retrieve all tuples from the EMPLOYEE relation '
    'where the department number (Dno) is equal to 4.')
re_a.font.name='Times New Roman'; re_a.font.size=Pt(11)

# Formula – centred box
p_formula_a = doc.add_paragraph()
p_formula_a.alignment = WD_ALIGN_PARAGRAPH.CENTER
p_formula_a.paragraph_format.space_before = Pt(6)
p_formula_a.paragraph_format.space_after  = Pt(6)
pPr = p_formula_a._p.get_or_add_pPr()
pBdr = OxmlElement('w:pBdr')
for side in ('top','left','bottom','right'):
    el = OxmlElement(f'w:{side}')
    el.set(qn('w:val'),   'single')
    el.set(qn('w:sz'),    '12')
    el.set(qn('w:space'), '4')
    el.set(qn('w:color'), '000080')
    pBdr.append(el)
pPr.append(pBdr)

rf_a1 = p_formula_a.add_run('σ')
rf_a1.bold=True; rf_a1.font.name='Cambria Math'; rf_a1.font.size=Pt(16)
rf_a1.font.color.rgb = RGBColor(0x00,0x00,0x80)
rf_a_sub = p_formula_a.add_run('Dno = 4')
rf_a_sub.font.name='Cambria Math'; rf_a_sub.font.size=Pt(10)
rf_a_sub.font.color.rgb = RGBColor(0xC0,0x00,0x00)
rPr = rf_a_sub._r.get_or_add_rPr()
va = OxmlElement('w:vertAlign'); va.set(qn('w:val'),'subscript'); rPr.append(va)
rf_a2 = p_formula_a.add_run(' (EMPLOYEE)')
rf_a2.bold=True; rf_a2.font.name='Cambria Math'; rf_a2.font.size=Pt(14)
rf_a2.font.color.rgb = RGBColor(0x00,0x00,0x80)

# Result table (a)
add_para('Result — 3 tuples returned (employees in Department 4):',
         bold=True, size=10, space_b=4, space_a=3, color='000080')

res_a_rows = [
    ('Alicia',  'J','Zelaya', '999887777','19-Jan-68','3321 Castle, Spring TX',  'F','25,000','987654321','4'),
    ('Jennifer','S','Wallace','987654321','20-Jun-41','291 Berry, Bellaire TX',  'F','43,000','888665555','4'),
    ('Ahmad',   'V','Jabbar', '987987987','29-Mar-69','980 Dallas, Houston TX',  'M','25,000','987654321','4'),
]
res_a_tbl = doc.add_table(rows=len(res_a_rows)+1, cols=len(emp_cols))
res_a_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
res_a_tbl.style = 'Table Grid'
for i, col in enumerate(emp_cols):
    c = res_a_tbl.rows[0].cells[i]
    shd(c, '000080')
    borders(c,'000080',6)
    cp=c.paragraphs[0]; cp.alignment=WD_ALIGN_PARAGRAPH.CENTER
    r=cp.add_run(col); r.bold=True
    r.font.name='Calibri'; r.font.size=Pt(8)
    r.font.color.rgb=RGBColor(0xFF,0xFF,0xFF)
for ri, row_d in enumerate(res_a_rows):
    for ci, val in enumerate(row_d):
        c = res_a_tbl.rows[ri+1].cells[ci]
        shd(c,'DDE8CB')
        borders(c,'336633',4)
        cp=c.paragraphs[0]; cp.alignment=WD_ALIGN_PARAGRAPH.CENTER
        r=cp.add_run(val)
        r.font.name='Calibri'; r.font.size=Pt(8)
        if ci==9: r.bold=True; r.font.color.rgb=RGBColor(0x22,0x55,0x11)

add_para()

# ══════════════════════════════════════════════════════════════════════════════
#  ANSWER (b)
# ══════════════════════════════════════════════════════════════════════════════
p_qb = doc.add_paragraph()
p_qb.paragraph_format.space_before = Pt(10)
p_qb.paragraph_format.space_after  = Pt(2)
rqb1 = p_qb.add_run('b.  ')
rqb1.bold=True; rqb1.font.name='Times New Roman'; rqb1.font.size=Pt(11)
rqb2 = p_qb.add_run('Select the tuples where salary > 40000.')
rqb2.font.name='Times New Roman'; rqb2.font.size=Pt(11)

p_ans_b = doc.add_paragraph()
p_ans_b.paragraph_format.space_before = Pt(4)
p_ans_b.paragraph_format.space_after  = Pt(2)
rb_lbl = p_ans_b.add_run('Answer (b):')
rb_lbl.bold=True; rb_lbl.underline=True
rb_lbl.font.name='Times New Roman'; rb_lbl.font.size=Pt(11)
rb_lbl.font.color.rgb = RGBColor(0x00,0x00,0x80)

p_exp_b = doc.add_paragraph()
p_exp_b.paragraph_format.space_before = Pt(2)
p_exp_b.paragraph_format.space_after  = Pt(4)
re_b = p_exp_b.add_run(
    'We use the SELECT operation (σ) to retrieve all tuples from the EMPLOYEE relation '
    'where the Salary attribute is strictly greater than 40,000.')
re_b.font.name='Times New Roman'; re_b.font.size=Pt(11)

# Formula – centred box
p_formula_b = doc.add_paragraph()
p_formula_b.alignment = WD_ALIGN_PARAGRAPH.CENTER
p_formula_b.paragraph_format.space_before = Pt(6)
p_formula_b.paragraph_format.space_after  = Pt(6)
pPr2 = p_formula_b._p.get_or_add_pPr()
pBdr2 = OxmlElement('w:pBdr')
for side in ('top','left','bottom','right'):
    el = OxmlElement(f'w:{side}')
    el.set(qn('w:val'),   'single')
    el.set(qn('w:sz'),    '12')
    el.set(qn('w:space'), '4')
    el.set(qn('w:color'), '000080')
    pBdr2.append(el)
pPr2.append(pBdr2)

rf_b1 = p_formula_b.add_run('σ')
rf_b1.bold=True; rf_b1.font.name='Cambria Math'; rf_b1.font.size=Pt(16)
rf_b1.font.color.rgb = RGBColor(0x00,0x00,0x80)
rf_b_sub = p_formula_b.add_run('Salary > 40000')
rf_b_sub.font.name='Cambria Math'; rf_b_sub.font.size=Pt(10)
rf_b_sub.font.color.rgb = RGBColor(0xC0,0x00,0x00)
rPr2 = rf_b_sub._r.get_or_add_rPr()
va2 = OxmlElement('w:vertAlign'); va2.set(qn('w:val'),'subscript'); rPr2.append(va2)
rf_b2 = p_formula_b.add_run(' (EMPLOYEE)')
rf_b2.bold=True; rf_b2.font.name='Cambria Math'; rf_b2.font.size=Pt(14)
rf_b2.font.color.rgb = RGBColor(0x00,0x00,0x80)

# Result table (b)
add_para('Result — 2 tuples returned (employees with Salary > 40,000):',
         bold=True, size=10, space_b=4, space_a=3, color='000080')

res_b_rows = [
    ('Jennifer','S','Wallace','987654321','20-Jun-41','291 Berry, Bellaire TX','F','43,000','888665555','4'),
    ('James',   'E','Borg',   '888665555','10-Nov-37','450 Stone, Houston TX', 'M','55,000','NULL',     '1'),
]
res_b_tbl = doc.add_table(rows=len(res_b_rows)+1, cols=len(emp_cols))
res_b_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
res_b_tbl.style = 'Table Grid'
for i, col in enumerate(emp_cols):
    c = res_b_tbl.rows[0].cells[i]
    shd(c,'000080')
    borders(c,'000080',6)
    cp=c.paragraphs[0]; cp.alignment=WD_ALIGN_PARAGRAPH.CENTER
    r=cp.add_run(col); r.bold=True
    r.font.name='Calibri'; r.font.size=Pt(8)
    r.font.color.rgb=RGBColor(0xFF,0xFF,0xFF)
for ri, row_d in enumerate(res_b_rows):
    for ci, val in enumerate(row_d):
        c = res_b_tbl.rows[ri+1].cells[ci]
        shd(c,'FCE4D6')
        borders(c,'C55A11',4)
        cp=c.paragraphs[0]; cp.alignment=WD_ALIGN_PARAGRAPH.CENTER
        r=cp.add_run(val)
        r.font.name='Calibri'; r.font.size=Pt(8)
        if ci==7: r.bold=True; r.font.color.rgb=RGBColor(0x84,0x32,0x00)
        if val=='NULL': r.font.color.rgb=RGBColor(0x99,0x99,0x99); r.italic=True

add_para()
add_para()

# ── Page 2 footer ─────────────────────────────────────────────────────────────
p_foot = doc.add_paragraph()
p_foot.paragraph_format.space_before = Pt(14)
p_foot.paragraph_format.space_after  = Pt(0)
pPr3 = p_foot._p.get_or_add_pPr()
pBdr3 = OxmlElement('w:pBdr')
top_el = OxmlElement('w:top')
top_el.set(qn('w:val'),   'single')
top_el.set(qn('w:sz'),    '6')
top_el.set(qn('w:space'), '1')
top_el.set(qn('w:color'), '000000')
pBdr3.append(top_el); pPr3.append(pBdr3)

p_foot2 = doc.add_paragraph()
p_foot2.alignment = WD_ALIGN_PARAGRAPH.CENTER
p_foot2.paragraph_format.space_before = Pt(2)
p_foot2.paragraph_format.space_after  = Pt(0)
rf_foot = p_foot2.add_run(
    'ITEC-211/Database Concepts and Design/2025-2026/Second Semester')
rf_foot.italic=True
rf_foot.font.name='Times New Roman'; rf_foot.font.size=Pt(9)

p_foot3 = doc.add_paragraph()
p_foot3.alignment = WD_ALIGN_PARAGRAPH.RIGHT
p_foot3.paragraph_format.space_before = Pt(0)
rf_foot3 = p_foot3.add_run('Page 2 of 2')
rf_foot3.italic=True
rf_foot3.font.name='Times New Roman'; rf_foot3.font.size=Pt(9)

# ── Save ──────────────────────────────────────────────────────────────────────
out = '/home/user/VisionMeasure/INFS211_Exam_Answer/INFS211_LabExam_Answer_Final.docx'
doc.save(out)
print(f'Saved → {out}')
