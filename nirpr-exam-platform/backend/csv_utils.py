"""
NIRPR RSO Examination Platform - CSV Import/Export Utilities

Handles bulk CSV import of users and questions, and generates downloadable
CSV templates so admins know exactly what columns are expected.
"""

import csv
import io
import secrets
import string
from typing import List, Dict, Any, Tuple


def generate_temp_password(length: int = 10) -> str:
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def _read_csv_rows(file_bytes: bytes) -> List[Dict[str, str]]:
    text = file_bytes.decode("utf-8-sig", errors="replace")
    reader = csv.DictReader(io.StringIO(text))
    rows = []
    for row in reader:
        # Normalize keys: strip whitespace, lowercase, replace spaces with underscores
        clean = { (k or "").strip().lower().replace(" ", "_"): (v or "").strip() for k, v in row.items() }
        if any(v for v in clean.values()):
            rows.append(clean)
    return rows


# ---------------------------------------------------------------------------
# Users CSV
# ---------------------------------------------------------------------------
USER_CSV_COLUMNS = [
    "full_name", "email", "phone", "role", "password",
    "training_program_code", "institution", "qualification", "practice_type",
]

VALID_ROLES = {"super_admin", "admin", "examiner", "candidate"}


def parse_users_csv(file_bytes: bytes) -> Tuple[List[Dict[str, Any]], List[str]]:
    """Parse a users CSV. Returns (rows, parse_errors).
    Expected columns (header row required):
      full_name, email, phone, role, password, training_program_code,
      institution, qualification, practice_type

    - role defaults to 'candidate' if blank.
    - password is auto-generated if left blank (credentials get emailed).
    - training_program_code / institution / qualification / practice_type
      only apply to candidate rows.
    """
    errors: List[str] = []
    try:
        raw_rows = _read_csv_rows(file_bytes)
    except Exception as e:
        return [], [f"Could not read CSV file: {e}"]

    if not raw_rows:
        return [], ["CSV file is empty or has no valid data rows."]

    parsed = []
    for i, row in enumerate(raw_rows, start=2):  # row 1 is the header
        full_name = row.get("full_name", "")
        email = row.get("email", "")
        if not full_name or not email:
            errors.append(f"Row {i}: 'full_name' and 'email' are required — skipped.")
            continue
        role = (row.get("role") or "candidate").lower()
        if role not in VALID_ROLES:
            errors.append(f"Row {i}: unknown role '{role}', defaulting to 'candidate'.")
            role = "candidate"
        password = row.get("password") or generate_temp_password()
        parsed.append({
            "full_name": full_name,
            "email": email.lower(),
            "phone": row.get("phone") or None,
            "role": role,
            "password": password,
            "password_was_generated": not bool(row.get("password")),
            "training_program_code": row.get("training_program_code") or None,
            "institution": row.get("institution") or None,
            "qualification": row.get("qualification") or None,
            "practice_type": row.get("practice_type") or None,
        })
    return parsed, errors


def users_csv_template() -> str:
    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow(USER_CSV_COLUMNS)
    writer.writerow([
        "Jane Doe", "jane.doe@example.com", "08012345678", "candidate", "",
        "RSO-DIAG-RAD", "General Hospital Ibadan", "Radiographer", "Diagnostic Radiology",
    ])
    writer.writerow([
        "John Examiner", "john.examiner@nirpr.gov.ng", "08098765432", "examiner", "",
        "", "", "", "",
    ])
    return buf.getvalue()


# ---------------------------------------------------------------------------
# Questions CSV
# ---------------------------------------------------------------------------
QUESTION_CSV_COLUMNS = [
    "question_text", "question_type", "option_a", "option_b", "option_c", "option_d",
    "correct_answer", "explanation", "marks", "difficulty", "topic",
]

VALID_QUESTION_TYPES = {"multiple_choice", "multiple_select", "true_false", "short_answer", "fill_in_gap"}


def parse_questions_csv(file_bytes: bytes) -> Tuple[List[Dict[str, Any]], List[str]]:
    """Parse a questions CSV. Returns (rows, parse_errors).
    Expected columns:
      question_text, question_type, option_a, option_b, option_c, option_d,
      correct_answer, explanation, marks, difficulty, topic

    - question_type: multiple_choice | multiple_select | true_false | short_answer | fill_in_gap
    - For multiple_choice/multiple_select/true_false: fill option_a..option_d (blank ones ignored),
      correct_answer = letter(s), e.g. "B" or "A;C".
    - For short_answer/fill_in_gap: leave option columns blank. correct_answer = acceptable
      answer(s), e.g. "ALARA" or "ALARA;As Low As Reasonably Achievable" (semicolon-separated
      alternatives). For fill_in_gap with several blanks, separate blanks with "|" and
      alternatives within a blank with "/", e.g. "ALARA/As Low As Reasonably Achievable|20 mSv".
    """
    errors: List[str] = []
    try:
        raw_rows = _read_csv_rows(file_bytes)
    except Exception as e:
        return [], [f"Could not read CSV file: {e}"]

    if not raw_rows:
        return [], ["CSV file is empty or has no valid data rows."]

    parsed = []
    for i, row in enumerate(raw_rows, start=2):
        text = row.get("question_text", "")
        if not text or len(text) < 5:
            errors.append(f"Row {i}: missing or too-short 'question_text' — skipped.")
            continue
        qtype = (row.get("question_type") or "multiple_choice").lower()
        if qtype not in VALID_QUESTION_TYPES:
            errors.append(f"Row {i}: unknown question_type '{qtype}' — skipped.")
            continue

        options = {}
        for letter in ["a", "b", "c", "d", "e", "f"]:
            val = row.get(f"option_{letter}")
            if val:
                options[letter.upper()] = val

        correct_raw = row.get("correct_answer", "")
        if not correct_raw:
            errors.append(f"Row {i}: missing 'correct_answer' — skipped.")
            continue

        if qtype in ("short_answer", "fill_in_gap"):
            correct_answer = [part.strip() for part in correct_raw.split("|") if part.strip()]
            options = {}
        else:
            correct_answer = [p.strip().upper() for p in correct_raw.replace(",", ";").split(";") if p.strip()]
            if not options:
                errors.append(f"Row {i}: '{qtype}' requires at least option_a/option_b — skipped.")
                continue

        try:
            marks = float(row.get("marks") or 1.0)
        except ValueError:
            marks = 1.0

        difficulty = (row.get("difficulty") or "medium").lower()
        if difficulty not in ("easy", "medium", "hard"):
            difficulty = "medium"

        parsed.append({
            "question_text": text,
            "question_type": qtype,
            "options": options,
            "correct_answer": correct_answer,
            "explanation": row.get("explanation") or None,
            "marks": marks,
            "difficulty": difficulty,
            "topic": row.get("topic") or None,
            "is_active": True,
        })
    return parsed, errors


def questions_csv_template() -> str:
    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow(QUESTION_CSV_COLUMNS)
    writer.writerow([
        "What is the annual occupational effective dose limit recommended by ICRP?",
        "multiple_choice", "1 mSv/year", "20 mSv/year averaged over 5 years",
        "50 mSv/year with no upper limit", "100 mSv/year",
        "B", "ICRP recommends 20 mSv/year averaged over 5 years.", "1", "medium", "Dose Limits",
    ])
    writer.writerow([
        "Select ALL PPE appropriate for fluoroscopy-guided procedures.",
        "multiple_select", "Lead apron", "Thyroid shield", "Personal dosimeter", "Surgical mask only",
        "A;B;C", "Lead apron, thyroid shield and dosimeter are standard PPE.", "1", "medium", "PPE",
    ])
    writer.writerow([
        "True or False: fetal dose should be kept below about 1 mSv for the remainder of a declared pregnancy.",
        "true_false", "True", "False", "", "",
        "A", "ICRP recommendation for declared pregnancy.", "1", "medium", "Special Groups",
    ])
    writer.writerow([
        "The ALARA principle stands for As Low As _____ Achievable.",
        "fill_in_gap", "", "", "", "",
        "Reasonably", "Core radiation protection principle.", "1", "easy", "ALARA",
    ])
    writer.writerow([
        "The three practical means of reducing radiation exposure are Time, Distance and _____.",
        "fill_in_gap", "", "", "", "",
        "Shielding/Shield", "", "1", "easy", "ALARA",
    ])
    writer.writerow([
        "Name the Nigerian regulatory authority for ionising radiation sources.",
        "short_answer", "", "", "", "",
        "Nigerian Nuclear Regulatory Authority;NNRA", "Accept full name or acronym.", "1", "easy", "Regulatory",
    ])
    return buf.getvalue()
