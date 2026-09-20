-- Read-only pgAdmin view with the name fields immediately after email.
-- PostgreSQL does not support rearranging columns in an existing table.
CREATE OR REPLACE VIEW users_ordered AS
SELECT
    id,
    email,
    surname,
    first_name,
    other_name,
    phone,
    role,
    is_active,
    email_verified,
    last_login,
    created_at
FROM users;
