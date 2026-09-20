"""Compose display names and split names from legacy inputs."""


def split_full_name(full_name: str) -> tuple[str, str, str | None]:
    """Best-effort split for legacy names; staff can correct ambiguous names."""
    parts = full_name.strip().split()
    if len(parts) < 2:
        return parts[0] if parts else "", "", None
    return parts[-1], parts[0], " ".join(parts[1:-1]) or None


def compose_full_name(surname: str, first_name: str, other_name: str | None = None) -> str:
    return " ".join(part.strip() for part in (first_name, other_name or "", surname) if part and part.strip())
