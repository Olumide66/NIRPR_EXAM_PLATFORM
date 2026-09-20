-- Run in pgAdmin Query Tool while connected to the maintenance database
-- "postgres" as an administrator. First create a LOGIN role named nirpr_user
-- in pgAdmin and set its password. Run this statement on its own: PostgreSQL
-- does not permit CREATE DATABASE inside a transaction block.

CREATE DATABASE nirpr_exam OWNER nirpr_user;
