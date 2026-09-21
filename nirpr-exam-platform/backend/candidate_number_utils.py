"""Public candidate numbers use the programme's configured initials."""

import re


def candidate_number(course_code: str, sequence: int) -> str:
    parts = re.findall(r"[A-Z0-9]+", course_code.upper())
    initials = "-".join(part for part in parts if part != "RSO")
    if not initials:
        raise ValueError("Training programme code must include its course initials")
    if sequence < 1:
        raise ValueError("Candidate sequence must be positive")
    # Minimum width three: 001, 010, 100, 1000. Never truncate larger numbers.
    return f"NIRPR-{initials}-{sequence:03d}"
