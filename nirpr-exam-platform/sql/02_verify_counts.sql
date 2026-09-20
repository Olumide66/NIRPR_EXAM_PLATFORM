-- Run in pgAdmin Query Tool while connected to nirpr_exam.
-- Compare these counts with the SQLite --check output before switching apps.
SELECT 'users' AS table_name, count(*) AS rows FROM public.users
UNION ALL SELECT 'candidate_profiles', count(*) FROM public.candidate_profiles
UNION ALL SELECT 'candidate_identities', count(*) FROM public.candidate_identities
UNION ALL SELECT 'training_programs', count(*) FROM public.training_programs
UNION ALL SELECT 'question_banks', count(*) FROM public.question_banks
UNION ALL SELECT 'questions', count(*) FROM public.questions
UNION ALL SELECT 'exams', count(*) FROM public.exams
UNION ALL SELECT 'exam_attempts', count(*) FROM public.exam_attempts
UNION ALL SELECT 'answers', count(*) FROM public.answers
UNION ALL SELECT 'exam_question_association', count(*) FROM public.exam_question_association
UNION ALL SELECT 'exam_policies', count(*) FROM public.exam_policies
UNION ALL SELECT 'exam_access_grants', count(*) FROM public.exam_access_grants
UNION ALL SELECT 'exam_schedule_overrides', count(*) FROM public.exam_schedule_overrides
UNION ALL SELECT 'retake_authorizations', count(*) FROM public.retake_authorizations
UNION ALL SELECT 'result_appeals', count(*) FROM public.result_appeals
UNION ALL SELECT 'payment_receipts', count(*) FROM public.payment_receipts
UNION ALL SELECT 'notifications', count(*) FROM public.notifications
UNION ALL SELECT 'audit_logs', count(*) FROM public.audit_logs
UNION ALL SELECT 'auth_sessions', count(*) FROM public.auth_sessions
UNION ALL SELECT 'staff_login_approvals', count(*) FROM public.staff_login_approvals
UNION ALL SELECT 'staff_mfa', count(*) FROM public.staff_mfa
UNION ALL SELECT 'staff_signatures', count(*) FROM public.staff_signatures
UNION ALL SELECT 'programme_signatures', count(*) FROM public.programme_signatures
UNION ALL SELECT 'question_revisions', count(*) FROM public.question_revisions
UNION ALL SELECT 'saved_reports', count(*) FROM public.saved_reports
UNION ALL SELECT 'system_settings', count(*) FROM public.system_settings;
