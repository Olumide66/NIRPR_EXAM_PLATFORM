-- Run once on an existing PostgreSQL installation before using tag signatures.
-- New installations create this table automatically during app startup.
CREATE TABLE IF NOT EXISTS public.candidate_tag_signatures (
    id integer PRIMARY KEY CHECK (id = 1),
    signatory_name varchar(150) NOT NULL,
    title varchar(150) NOT NULL,
    image_path text NOT NULL,
    uploaded_by integer NOT NULL REFERENCES public.users(id),
    uploaded_at timestamp without time zone
);
