# NIRPR PostgreSQL setup files

The live database structure is defined by `backend/models.py` (SQLAlchemy).
`01_postgresql_schema.sql` is a portable PostgreSQL 18 baseline schema export of
the original 26 tables, enum types, sequences, indexes, and foreign keys. It does
not contain passwords or candidate records.
Run `04_candidate_tag_signature.sql` after the baseline schema to add the
separate, single candidate tag signature table. The app also creates it on startup.

For a new installation or a later move to another PostgreSQL server:

1. In pgAdmin, create a login role `nirpr_user` and set its password. Connect
   to the maintenance database `postgres` as an administrator and run
   `00_create_database.sql`. Adjust the names in the SQL if you choose other
   names. The database must be empty.
2. Connect pgAdmin's Query Tool to the new `nirpr_exam` database and run
   `01_postgresql_schema.sql`, then `04_candidate_tag_signature.sql`. The application or migration script can also
   create this schema automatically, so this step is optional.
3. To copy data **from SQLite**, stop the app, set `DATABASE_URL` in
   `backend/.env`, and run `python migrate_sqlite_to_postgres.py` from
   `backend/`. This script handles data types, foreign keys, IDs, backups,
   and count checks. SQL alone cannot read the separate SQLite file from
   within PostgreSQL. Run `02_verify_counts.sql` to inspect the result.
4. To move an **existing PostgreSQL** installation to another server, use
   pgAdmin's Backup and Restore or `pg_dump`/`pg_restore` to preserve both
   schema and data. Do not run the SQLite migration again against a populated
   PostgreSQL database.

Keep the `backend/uploads/` and `backend/assets/` folders with the app when
moving servers; database backups do not include those files.
