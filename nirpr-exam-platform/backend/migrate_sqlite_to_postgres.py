"""Copy NIRPR SQLite data into a new PostgreSQL database with no data.

Run from backend/: python migrate_sqlite_to_postgres.py --check
Then set DATABASE_URL and run: python migrate_sqlite_to_postgres.py
"""

import argparse
import asyncio
import json
import os
import sqlite3
from datetime import date, datetime
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import Boolean, Date, DateTime, Integer, JSON, func, inspect, select, text
from sqlalchemy.ext.asyncio import create_async_engine

from database import Base
import models  # noqa: F401 - registers every table on Base.metadata
from name_utils import split_full_name


HERE = Path(__file__).resolve().parent


def source_summary(source: Path):
    if not source.is_file():
        raise SystemExit(f"SQLite source does not exist: {source}")
    db = sqlite3.connect(f"file:{source.as_posix()}?mode=ro", uri=True)
    try:
        tables = {row[0] for row in db.execute("SELECT name FROM sqlite_master WHERE type='table'")}
        expected = set(Base.metadata.tables)
        missing = expected - tables
        extra = tables - expected - {"sqlite_sequence"}
        if missing or extra:
            raise SystemExit(f"Source schema differs from models. Missing: {sorted(missing)}; extra: {sorted(extra)}")
        counts = {name: db.execute(f'SELECT count(*) FROM "{name}"').fetchone()[0] for name in sorted(expected)}
        return counts
    finally:
        db.close()


def convert(value, column):
    if value is None:
        return None
    if isinstance(column.type, Boolean):
        return bool(value)
    if isinstance(column.type, JSON):
        return json.loads(value) if isinstance(value, str) else value
    if isinstance(column.type, DateTime) and isinstance(value, str):
        return datetime.fromisoformat(value)
    if isinstance(column.type, Date) and isinstance(value, str):
        return date.fromisoformat(value)
    return value


async def migrate(source: Path, url: str, expected: dict[str, int], backup: Path):
    if not url.startswith("postgresql+asyncpg://"):
        raise SystemExit("DATABASE_URL must start with postgresql+asyncpg://")

    # SQLite's backup API gives a consistent copy and leaves the original untouched.
    backup.parent.mkdir(parents=True, exist_ok=True)
    original = sqlite3.connect(f"file:{source.as_posix()}?mode=ro", uri=True)
    snapshot = sqlite3.connect(backup)
    try:
        original.backup(snapshot)
    finally:
        original.close()
        snapshot.close()
    print(f"SQLite backup: {backup}")
    if source_summary(backup) != expected:
        raise SystemExit("Source changed while creating the backup. Stop the app and retry.")

    engine = create_async_engine(url, pool_pre_ping=True)
    try:
        async with engine.begin() as conn:
            existing = await conn.run_sync(lambda c: set(inspect(c).get_table_names()))
            if existing:
                if existing != set(Base.metadata.tables):
                    raise SystemExit(f"Target has an incomplete or unrelated schema: {', '.join(sorted(existing))}")
                for table in Base.metadata.tables.values():
                    count = (await conn.execute(select(func.count()).select_from(table))).scalar_one()
                    if count:
                        raise SystemExit(f"Target must have no data; {table.name} already has {count} rows")
            else:
                await conn.run_sync(Base.metadata.create_all)

            db = sqlite3.connect(f"file:{backup.as_posix()}?mode=ro", uri=True)
            db.row_factory = sqlite3.Row
            try:
                for table in Base.metadata.sorted_tables:
                    source_columns = {row[1] for row in db.execute(f'PRAGMA table_info("{table.name}")')}
                    columns = [column for column in table.columns if column.name in source_columns]
                    rows = db.execute(f'SELECT * FROM "{table.name}"')
                    batch = []
                    for row in rows:
                        values = {col.name: convert(row[col.name], col) for col in columns}
                        if table.name == "users" and (not values.get("surname") or not values.get("first_name")):
                            if "full_name" not in source_columns:
                                raise RuntimeError("SQLite user has no complete name fields")
                            values["surname"], values["first_name"], values["other_name"] = split_full_name(row["full_name"])
                        batch.append(values)
                        if len(batch) == 500:
                            await conn.execute(table.insert(), batch)
                            batch.clear()
                    if batch:
                        await conn.execute(table.insert(), batch)
                    actual = (await conn.execute(select(text("count(*)")).select_from(table))).scalar_one()
                    if actual != expected[table.name]:
                        raise RuntimeError(f"Count mismatch for {table.name}: SQLite={expected[table.name]}, PostgreSQL={actual}")
                    print(f"{table.name}: {actual} rows")

                    for col in table.primary_key.columns:
                        if not isinstance(col.type, Integer) or not col.autoincrement:
                            continue
                        sequence = (await conn.execute(
                            text("SELECT pg_get_serial_sequence(:table_name, :column_name)"),
                            {"table_name": table.name, "column_name": col.name},
                        )).scalar_one_or_none()
                        if sequence:
                            highest = (await conn.execute(select(col).order_by(col.desc()).limit(1))).scalar_one_or_none()
                            await conn.execute(text("SELECT setval(CAST(:sequence AS regclass), :value, :used)"),
                                               {"sequence": sequence, "value": highest or 1, "used": highest is not None})
            finally:
                db.close()
        print(f"Migration committed: {sum(expected.values())} rows across {len(expected)} tables.")
    finally:
        await engine.dispose()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=HERE / "nirpr_exam.db")
    parser.add_argument("--check", action="store_true", help="Inspect SQLite without connecting to PostgreSQL")
    args = parser.parse_args()
    source = args.source.resolve()
    counts = source_summary(source)
    print(f"SQLite source: {source}")
    print(f"{sum(counts.values())} rows across {len(counts)} application tables")
    if args.check:
        for name, count in counts.items():
            print(f"{name}: {count}")
        return
    load_dotenv(HERE / ".env")
    url = os.getenv("DATABASE_URL", "")
    backup = HERE / "backups" / f"nirpr_exam_pre_postgres_{datetime.now():%Y%m%d_%H%M%S}.db"
    asyncio.run(migrate(source, url, counts, backup))


if __name__ == "__main__":
    main()
