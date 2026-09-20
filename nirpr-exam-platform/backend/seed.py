"""
NIRPR RSO Examination Platform - Database Seed Script
Run once after installation: python seed.py

Creates:
  - A Super Admin account (from env vars or the defaults below)
  - Two demo RSO training programs (different practice areas)
  - A question bank per program with sample questions

IMPORTANT: change the default admin password immediately after first login,
or set ADMIN_EMAIL / ADMIN_PASSWORD environment variables before running this.
"""

import asyncio
import os
from dotenv import load_dotenv
load_dotenv()  # must run before database.py / auth.py read env vars at import time

from database import init_db, AsyncSessionLocal
from models import User, UserRole, TrainingProgram, QuestionBank, Question, QuestionType
from auth import get_password_hash
from sqlalchemy import select

ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "admin@nirpr.gov.ng")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "ChangeMe#2026")


async def seed():
    await init_db()

    async with AsyncSessionLocal() as db:
        # --- Super admin -----------------------------------------------------
        result = await db.execute(select(User).where(User.email == ADMIN_EMAIL))
        if not result.scalar_one_or_none():
            admin = User(
                email=ADMIN_EMAIL,
                hashed_password=get_password_hash(ADMIN_PASSWORD),
                first_name="NIRPR", other_name="System", surname="Administrator",
                role=UserRole.SUPER_ADMIN,
                is_active=True,
                email_verified=True,
            )
            db.add(admin)
            print(f"Created super admin: {ADMIN_EMAIL} / {ADMIN_PASSWORD}")
        else:
            print(f"Super admin {ADMIN_EMAIL} already exists, skipping.")

        # --- Demo examiner account --------------------------------------------
        EXAMINER_EMAIL = os.getenv("EXAMINER_EMAIL", "examiner@nirpr.gov.ng")
        EXAMINER_PASSWORD = os.getenv("EXAMINER_PASSWORD", "Examiner#2026")
        result = await db.execute(select(User).where(User.email == EXAMINER_EMAIL))
        if not result.scalar_one_or_none():
            examiner = User(
                email=EXAMINER_EMAIL,
                hashed_password=get_password_hash(EXAMINER_PASSWORD),
                first_name="Demo", surname="Examiner",
                role=UserRole.EXAMINER,
                is_active=True,
                email_verified=True,
                created_by_admin=True,
            )
            db.add(examiner)
            print(f"Created demo examiner: {EXAMINER_EMAIL} / {EXAMINER_PASSWORD}")

        # --- Demo training programs -------------------------------------------
        programs_data = [
            dict(
                code="RSO-DIAG-RAD",
                name="RSO Certification - Diagnostic Radiology",
                description="Radiation Safety Officer certification for diagnostic and interventional radiology practice.",
                practice_area="Diagnostic Radiology",
                duration_days=5,
                passing_score=70.0,
            ),
            dict(
                code="RSO-NUC-MED",
                name="RSO Certification - Nuclear Medicine",
                description="Radiation Safety Officer certification for nuclear medicine practice.",
                practice_area="Nuclear Medicine",
                duration_days=5,
                passing_score=70.0,
            ),
            dict(
                code="RSO-IND-RAD",
                name="RSO Certification - Industrial Radiography",
                description="Radiation Safety Officer certification for industrial radiography and NDT practice.",
                practice_area="Industrial Radiography",
                duration_days=5,
                passing_score=75.0,
            ),
        ]

        created_programs = []
        for pdata in programs_data:
            result = await db.execute(select(TrainingProgram).where(TrainingProgram.code == pdata["code"]))
            program = result.scalar_one_or_none()
            if not program:
                program = TrainingProgram(**pdata)
                db.add(program)
                await db.flush()
                print(f"Created training program: {program.code}")
            created_programs.append(program)

        await db.commit()

        # --- Demo question bank + sample questions for the first program -----
        program = created_programs[0]
        result = await db.execute(select(QuestionBank).where(QuestionBank.training_program_id == program.id))
        bank = result.scalars().first()
        if not bank:
            bank = QuestionBank(
                training_program_id=program.id,
                name=f"{program.code} - Core Question Bank",
                description="Core radiation safety and regulatory question bank.",
            )
            db.add(bank)
            await db.flush()
            print(f"Created question bank for {program.code}")

            sample_questions = [
                dict(
                    question_text="What is the annual effective dose limit for occupationally exposed radiation workers, as recommended by ICRP and typically adopted in national regulations?",
                    options={"A": "1 mSv/year", "B": "20 mSv/year averaged over 5 years", "C": "50 mSv/year with no upper limit", "D": "100 mSv/year"},
                    correct_answer=["B"],
                    explanation="ICRP recommends an occupational dose limit of 20 mSv/year averaged over defined 5-year periods, with no single year exceeding 50 mSv.",
                    difficulty="medium", topic="Dose Limits",
                ),
                dict(
                    question_text="Which of the following is the primary responsibility of a Radiation Safety Officer (RSO)?",
                    options={"A": "Marketing hospital services", "B": "Ensuring compliance with radiation protection regulations and safe practice", "C": "Procuring imaging equipment only", "D": "Scheduling patient appointments"},
                    correct_answer=["B"],
                    explanation="The RSO is responsible for day-to-day implementation and oversight of the radiation protection programme and regulatory compliance.",
                    difficulty="easy", topic="RSO Roles & Responsibilities",
                ),
                dict(
                    question_text="The three basic principles of radiation protection (ALARA framework) are:",
                    options={"A": "Time, Distance, Shielding", "B": "Speed, Weight, Shielding", "C": "Time, Voltage, Current", "D": "Distance, Dose, Density"},
                    correct_answer=["A"],
                    explanation="Time, Distance, and Shielding are the three practical means of minimising radiation exposure.",
                    difficulty="easy", topic="ALARA Principles",
                ),
                dict(
                    question_text="Which regulatory body is responsible for licensing and regulating the use of ionising radiation sources in Nigeria?",
                    options={"A": "NAFDAC", "B": "Nigerian Nuclear Regulatory Authority (NNRA)", "C": "Federal Ministry of Health", "D": "Standards Organisation of Nigeria"},
                    correct_answer=["B"],
                    explanation="NNRA is Nigeria's national regulatory authority for nuclear and radiation safety, established under the NNRA Act.",
                    difficulty="easy", topic="Nigerian Regulatory Framework",
                ),
                dict(
                    question_text="Select ALL personal protective measures appropriate for staff performing fluoroscopy-guided procedures.",
                    options={"A": "Lead apron", "B": "Thyroid shield", "C": "Personal dosimeter", "D": "Surgical mask only"},
                    correct_answer=["A", "B", "C"],
                    question_type=QuestionType.MULTIPLE_SELECT,
                    explanation="Lead apron, thyroid shield, and a personal dosimeter are standard radiation protection measures for fluoroscopy staff; a surgical mask provides no radiation shielding.",
                    difficulty="medium", topic="Personal Protective Equipment",
                ),
                dict(
                    question_text="A Diagnostic Reference Level (DRL) is best described as:",
                    options={"A": "A dose limit that must never be exceeded for any patient", "B": "An investigation level used to identify unusually high patient doses for a given examination", "C": "The maximum permissible dose to staff", "D": "A regulatory penalty threshold"},
                    correct_answer=["B"],
                    explanation="DRLs are investigation levels, not dose limits — they help identify when doses for a standard examination are unusually high and trigger a local review.",
                    difficulty="hard", topic="Diagnostic Reference Levels",
                ),
                dict(
                    question_text="True or False: Pregnant radiation workers should be reassigned duties to keep the equivalent dose to the embryo/fetus below 1 mSv for the remainder of the pregnancy.",
                    options={"A": "True", "B": "False"},
                    correct_answer=["A"],
                    question_type=QuestionType.TRUE_FALSE,
                    explanation="ICRP recommends limiting fetal dose to about 1 mSv for the remainder of the declared pregnancy.",
                    difficulty="medium", topic="Special Groups",
                ),
                dict(
                    question_text="Which quantity is measured directly by a personal dosimeter (TLD/OSL badge)?",
                    options={"A": "Absorbed dose in air only", "B": "Personal dose equivalent, Hp(10)", "C": "Kerma-area product", "D": "Exposure rate"},
                    correct_answer=["B"],
                    explanation="Personal dosimeters are calibrated to report the personal dose equivalent Hp(10), used as an estimate of effective dose for whole-body monitoring.",
                    difficulty="hard", topic="Radiation Dosimetry",
                ),
                dict(
                    question_text="The ALARA principle stands for As Low As _____ Achievable.",
                    options={},
                    correct_answer=["Reasonably"],
                    question_type=QuestionType.FILL_IN_GAP,
                    explanation="ALARA = As Low As Reasonably Achievable — the guiding principle of radiation protection optimisation.",
                    difficulty="easy", topic="ALARA Principles",
                ),
                dict(
                    question_text="The three practical means of reducing radiation exposure are Time, Distance and _____.",
                    options={},
                    correct_answer=["Shielding/Shield"],
                    question_type=QuestionType.FILL_IN_GAP,
                    explanation="Time, Distance and Shielding are the three basic means of controlling occupational exposure.",
                    difficulty="easy", topic="ALARA Principles",
                ),
                dict(
                    question_text="State the name of the Nigerian regulatory authority responsible for licensing ionising radiation practices.",
                    options={},
                    correct_answer=["Nigerian Nuclear Regulatory Authority/NNRA"],
                    question_type=QuestionType.SHORT_ANSWER,
                    explanation="NNRA — the Nigerian Nuclear Regulatory Authority.",
                    difficulty="easy", topic="Nigerian Regulatory Framework",
                ),
            ]
            for q in sample_questions:
                q.setdefault("question_type", QuestionType.MULTIPLE_CHOICE)
                db.add(Question(question_bank_id=bank.id, **q))
            print(f"Added {len(sample_questions)} sample questions to {bank.name}")

        await db.commit()

    print("\nSeeding complete.")
    print(f"Log in as super admin at /  ->  {ADMIN_EMAIL} / {ADMIN_PASSWORD}")
    print("IMPORTANT: change this password immediately in production.")


if __name__ == "__main__":
    asyncio.run(seed())
