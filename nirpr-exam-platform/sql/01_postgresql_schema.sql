-- NIRPR PostgreSQL schema. Run only against a new, empty database.
-- Data is transferred by backend/migrate_sqlite_to_postgres.py.

--
-- PostgreSQL database dump
--


-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: attemptstatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.attemptstatus AS ENUM (
    'NOT_STARTED',
    'IN_PROGRESS',
    'SUBMITTED',
    'AUTO_SUBMITTED',
    'UNDER_REVIEW',
    'APPROVED',
    'REJECTED'
);


--
-- Name: examstatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.examstatus AS ENUM (
    'DRAFT',
    'SCHEDULED',
    'ACTIVE',
    'COMPLETED',
    'ARCHIVED'
);


--
-- Name: questiontype; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.questiontype AS ENUM (
    'MULTIPLE_CHOICE',
    'MULTIPLE_SELECT',
    'TRUE_FALSE',
    'SHORT_ANSWER',
    'FILL_IN_GAP'
);


--
-- Name: userrole; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.userrole AS ENUM (
    'SUPER_ADMIN',
    'ADMIN',
    'EXAMINER',
    'CANDIDATE'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: answers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.answers (
    id integer NOT NULL,
    attempt_id integer NOT NULL,
    question_id integer NOT NULL,
    selected_answer json,
    is_correct boolean,
    marks_obtained double precision,
    answered_at timestamp without time zone,
    time_spent_seconds integer
);


--
-- Name: answers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.answers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: answers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.answers_id_seq OWNED BY public.answers.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    user_id integer,
    action character varying(100) NOT NULL,
    entity_type character varying(50),
    entity_id integer,
    details json,
    ip_address character varying(45),
    user_agent text,
    created_at timestamp without time zone
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: auth_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_sessions (
    id character varying(64) NOT NULL,
    user_id integer NOT NULL,
    ip_address character varying(45),
    user_agent text,
    device_label character varying(200),
    created_at timestamp without time zone,
    last_seen_at timestamp without time zone,
    expires_at timestamp without time zone NOT NULL,
    revoked_at timestamp without time zone
);


--
-- Name: candidate_identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.candidate_identities (
    id integer NOT NULL,
    user_id integer NOT NULL,
    candidate_number character varying(40) NOT NULL,
    examination_number character varying(40) NOT NULL,
    created_at timestamp without time zone
);


--
-- Name: candidate_identities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.candidate_identities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: candidate_identities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.candidate_identities_id_seq OWNED BY public.candidate_identities.id;


--
-- Name: candidate_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.candidate_profiles (
    id integer NOT NULL,
    user_id integer NOT NULL,
    training_program_id integer NOT NULL,
    institution character varying(200),
    department character varying(100),
    qualification character varying(100),
    years_of_experience integer,
    nnra_registration_number character varying(50),
    practice_type character varying(100),
    accreditation_status character varying(50)
);


--
-- Name: candidate_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.candidate_profiles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: candidate_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.candidate_profiles_id_seq OWNED BY public.candidate_profiles.id;


--
-- Name: exam_access_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_access_grants (
    id integer NOT NULL,
    user_id integer NOT NULL,
    exam_id integer NOT NULL,
    granted_by integer NOT NULL,
    granted_at timestamp without time zone NOT NULL
);


--
-- Name: exam_access_grants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exam_access_grants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exam_access_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exam_access_grants_id_seq OWNED BY public.exam_access_grants.id;


--
-- Name: exam_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_attempts (
    id integer NOT NULL,
    exam_id integer NOT NULL,
    user_id integer NOT NULL,
    attempt_number integer NOT NULL,
    status public.attemptstatus,
    started_at timestamp without time zone,
    submitted_at timestamp without time zone,
    time_spent_seconds integer,
    total_score double precision,
    total_possible_marks double precision,
    percentage double precision,
    passed boolean,
    approved_by integer,
    approved_at timestamp without time zone,
    approval_notes text,
    result_released boolean,
    ip_address character varying(45),
    user_agent text,
    tab_switch_count integer,
    fullscreen_exit_count integer,
    suspicious_activity json,
    question_set json,
    created_at timestamp without time zone
);


--
-- Name: exam_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exam_attempts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exam_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exam_attempts_id_seq OWNED BY public.exam_attempts.id;


--
-- Name: exam_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_policies (
    id integer NOT NULL,
    exam_id integer NOT NULL,
    allow_resume boolean,
    allow_previous boolean,
    allow_revisit boolean,
    sequential boolean,
    allow_skip boolean,
    unanswered_zero boolean,
    negative_marking double precision,
    random_question_selection boolean,
    random_option_order boolean,
    topic_distribution json,
    require_fullscreen boolean,
    max_tab_switches integer,
    block_clipboard boolean,
    block_printing boolean,
    snapshot_questions boolean,
    payment_required boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: exam_policies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exam_policies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exam_policies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exam_policies_id_seq OWNED BY public.exam_policies.id;


--
-- Name: exam_question_association; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_question_association (
    exam_id integer NOT NULL,
    question_id integer NOT NULL,
    order_index integer NOT NULL
);


--
-- Name: exam_schedule_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exam_schedule_overrides (
    id integer NOT NULL,
    exam_id integer NOT NULL,
    user_id integer NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    reason text,
    created_by integer NOT NULL,
    created_at timestamp without time zone
);


--
-- Name: exam_schedule_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exam_schedule_overrides_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exam_schedule_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exam_schedule_overrides_id_seq OWNED BY public.exam_schedule_overrides.id;


--
-- Name: exams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exams (
    id integer NOT NULL,
    training_program_id integer NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    duration_minutes integer,
    passing_score double precision,
    total_marks double precision,
    questions_per_exam integer,
    randomize_questions boolean,
    randomize_options boolean,
    allow_review boolean,
    max_attempts integer,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    status public.examstatus,
    instructions text,
    created_by integer,
    created_at timestamp without time zone
);


--
-- Name: exams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exams_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exams_id_seq OWNED BY public.exams.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    title character varying(200) NOT NULL,
    message text NOT NULL,
    notification_type character varying(40),
    read_at timestamp without time zone,
    scheduled_for timestamp without time zone,
    email_sent_at timestamp without time zone,
    created_at timestamp without time zone
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: payment_receipts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_receipts (
    id integer NOT NULL,
    user_id integer NOT NULL,
    exam_id integer NOT NULL,
    file_name character varying(255) NOT NULL,
    stored_path text NOT NULL,
    content_type character varying(100),
    amount double precision,
    reference character varying(100),
    status character varying(30),
    review_notes text,
    reviewed_by integer,
    uploaded_at timestamp without time zone,
    reviewed_at timestamp without time zone
);


--
-- Name: payment_receipts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_receipts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_receipts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_receipts_id_seq OWNED BY public.payment_receipts.id;


--
-- Name: programme_signatures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programme_signatures (
    id integer NOT NULL,
    training_program_id integer NOT NULL,
    role_key character varying(50) NOT NULL,
    signatory_name character varying(150) NOT NULL,
    title character varying(150) NOT NULL,
    image_path text NOT NULL,
    uploaded_by integer NOT NULL,
    uploaded_at timestamp without time zone
);


--
-- Name: programme_signatures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.programme_signatures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: programme_signatures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.programme_signatures_id_seq OWNED BY public.programme_signatures.id;


--
-- Name: question_banks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_banks (
    id integer NOT NULL,
    training_program_id integer NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    is_active boolean,
    created_at timestamp without time zone,
    created_by integer
);


--
-- Name: question_banks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.question_banks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_banks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.question_banks_id_seq OWNED BY public.question_banks.id;


--
-- Name: question_revisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_revisions (
    id integer NOT NULL,
    question_id integer NOT NULL,
    version integer NOT NULL,
    snapshot json NOT NULL,
    action character varying(30),
    changed_by integer NOT NULL,
    changed_at timestamp without time zone,
    review_status character varying(30),
    reviewed_by integer,
    reviewed_at timestamp without time zone,
    review_notes text
);


--
-- Name: question_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.question_revisions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.question_revisions_id_seq OWNED BY public.question_revisions.id;


--
-- Name: questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.questions (
    id integer NOT NULL,
    question_bank_id integer NOT NULL,
    question_text text NOT NULL,
    question_type public.questiontype,
    options json NOT NULL,
    correct_answer json NOT NULL,
    explanation text,
    marks double precision,
    difficulty character varying(20),
    topic character varying(100),
    is_active boolean,
    created_at timestamp without time zone
);


--
-- Name: questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.questions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.questions_id_seq OWNED BY public.questions.id;


--
-- Name: result_appeals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.result_appeals (
    id integer NOT NULL,
    attempt_id integer NOT NULL,
    user_id integer NOT NULL,
    reason text NOT NULL,
    evidence_url text,
    status character varying(30),
    resolution text,
    reviewed_by integer,
    submitted_at timestamp without time zone,
    reviewed_at timestamp without time zone
);


--
-- Name: result_appeals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.result_appeals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: result_appeals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.result_appeals_id_seq OWNED BY public.result_appeals.id;


--
-- Name: retake_authorizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.retake_authorizations (
    id integer NOT NULL,
    exam_id integer NOT NULL,
    user_id integer NOT NULL,
    authorized_by integer NOT NULL,
    reason text,
    created_at timestamp without time zone,
    used boolean,
    used_at timestamp without time zone
);


--
-- Name: retake_authorizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.retake_authorizations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: retake_authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.retake_authorizations_id_seq OWNED BY public.retake_authorizations.id;


--
-- Name: saved_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.saved_reports (
    id integer NOT NULL,
    training_program_id integer,
    exam_id integer,
    schedule_key character varying(120) NOT NULL,
    title character varying(250) NOT NULL,
    report_data json NOT NULL,
    created_by integer NOT NULL,
    created_at timestamp without time zone
);


--
-- Name: saved_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.saved_reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: saved_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.saved_reports_id_seq OWNED BY public.saved_reports.id;


--
-- Name: staff_login_approvals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_login_approvals (
    id character varying(64) NOT NULL,
    user_id integer NOT NULL,
    poll_token_hash character varying(128) NOT NULL,
    status character varying(30) NOT NULL,
    ip_address character varying(45),
    user_agent text,
    requested_at timestamp without time zone,
    expires_at timestamp without time zone NOT NULL,
    approved_by integer,
    approver_authority character varying(40),
    decision_notes text,
    decided_at timestamp without time zone,
    consumed_at timestamp without time zone
);


--
-- Name: staff_mfa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_mfa (
    id integer NOT NULL,
    user_id integer NOT NULL,
    secret character varying(64) NOT NULL,
    enabled boolean,
    created_at timestamp without time zone
);


--
-- Name: staff_mfa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.staff_mfa_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_mfa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.staff_mfa_id_seq OWNED BY public.staff_mfa.id;


--
-- Name: staff_signatures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_signatures (
    id integer NOT NULL,
    role_key character varying(50) NOT NULL,
    signatory_name character varying(150) NOT NULL,
    title character varying(150) NOT NULL,
    image_path text NOT NULL,
    uploaded_by integer NOT NULL,
    uploaded_at timestamp without time zone
);


--
-- Name: staff_signatures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.staff_signatures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_signatures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.staff_signatures_id_seq OWNED BY public.staff_signatures.id;


--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_settings (
    id integer NOT NULL,
    key character varying(100) NOT NULL,
    value text,
    description text,
    updated_at timestamp without time zone,
    updated_by integer
);


--
-- Name: system_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.system_settings_id_seq OWNED BY public.system_settings.id;


--
-- Name: training_programs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.training_programs (
    id integer NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    practice_area character varying(100) NOT NULL,
    duration_days integer,
    passing_score double precision,
    is_active boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: training_programs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.training_programs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: training_programs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.training_programs_id_seq OWNED BY public.training_programs.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    hashed_password character varying(255) NOT NULL,
    phone character varying(20),
    role public.userrole,
    is_active boolean,
    email_verified boolean,
    last_login timestamp without time zone,
    login_attempts integer,
    locked_until timestamp without time zone,
    created_at timestamp without time zone,
    verification_token character varying(255),
    verification_token_expires timestamp without time zone,
    reset_token character varying(255),
    reset_token_expires timestamp without time zone,
    created_by_admin boolean,
    must_change_password boolean NOT NULL,
    surname character varying(100) NOT NULL,
    first_name character varying(100) NOT NULL,
    other_name character varying(150)
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: answers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.answers ALTER COLUMN id SET DEFAULT nextval('public.answers_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: candidate_identities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_identities ALTER COLUMN id SET DEFAULT nextval('public.candidate_identities_id_seq'::regclass);


--
-- Name: candidate_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_profiles ALTER COLUMN id SET DEFAULT nextval('public.candidate_profiles_id_seq'::regclass);


--
-- Name: exam_access_grants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_access_grants ALTER COLUMN id SET DEFAULT nextval('public.exam_access_grants_id_seq'::regclass);


--
-- Name: exam_attempts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_attempts ALTER COLUMN id SET DEFAULT nextval('public.exam_attempts_id_seq'::regclass);


--
-- Name: exam_policies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_policies ALTER COLUMN id SET DEFAULT nextval('public.exam_policies_id_seq'::regclass);


--
-- Name: exam_schedule_overrides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_schedule_overrides ALTER COLUMN id SET DEFAULT nextval('public.exam_schedule_overrides_id_seq'::regclass);


--
-- Name: exams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exams ALTER COLUMN id SET DEFAULT nextval('public.exams_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: payment_receipts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_receipts ALTER COLUMN id SET DEFAULT nextval('public.payment_receipts_id_seq'::regclass);


--
-- Name: programme_signatures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_signatures ALTER COLUMN id SET DEFAULT nextval('public.programme_signatures_id_seq'::regclass);


--
-- Name: question_banks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_banks ALTER COLUMN id SET DEFAULT nextval('public.question_banks_id_seq'::regclass);


--
-- Name: question_revisions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_revisions ALTER COLUMN id SET DEFAULT nextval('public.question_revisions_id_seq'::regclass);


--
-- Name: questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions ALTER COLUMN id SET DEFAULT nextval('public.questions_id_seq'::regclass);


--
-- Name: result_appeals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_appeals ALTER COLUMN id SET DEFAULT nextval('public.result_appeals_id_seq'::regclass);


--
-- Name: retake_authorizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retake_authorizations ALTER COLUMN id SET DEFAULT nextval('public.retake_authorizations_id_seq'::regclass);


--
-- Name: saved_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_reports ALTER COLUMN id SET DEFAULT nextval('public.saved_reports_id_seq'::regclass);


--
-- Name: staff_mfa id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_mfa ALTER COLUMN id SET DEFAULT nextval('public.staff_mfa_id_seq'::regclass);


--
-- Name: staff_signatures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_signatures ALTER COLUMN id SET DEFAULT nextval('public.staff_signatures_id_seq'::regclass);


--
-- Name: system_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_settings ALTER COLUMN id SET DEFAULT nextval('public.system_settings_id_seq'::regclass);


--
-- Name: training_programs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.training_programs ALTER COLUMN id SET DEFAULT nextval('public.training_programs_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: answers answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.answers
    ADD CONSTRAINT answers_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: auth_sessions auth_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_sessions
    ADD CONSTRAINT auth_sessions_pkey PRIMARY KEY (id);


--
-- Name: candidate_identities candidate_identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_identities
    ADD CONSTRAINT candidate_identities_pkey PRIMARY KEY (id);


--
-- Name: candidate_identities candidate_identities_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_identities
    ADD CONSTRAINT candidate_identities_user_id_key UNIQUE (user_id);


--
-- Name: candidate_profiles candidate_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_profiles
    ADD CONSTRAINT candidate_profiles_pkey PRIMARY KEY (id);


--
-- Name: candidate_profiles candidate_profiles_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_profiles
    ADD CONSTRAINT candidate_profiles_user_id_key UNIQUE (user_id);


--
-- Name: exam_access_grants exam_access_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_access_grants
    ADD CONSTRAINT exam_access_grants_pkey PRIMARY KEY (id);


--
-- Name: exam_attempts exam_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_attempts
    ADD CONSTRAINT exam_attempts_pkey PRIMARY KEY (id);


--
-- Name: exam_policies exam_policies_exam_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_policies
    ADD CONSTRAINT exam_policies_exam_id_key UNIQUE (exam_id);


--
-- Name: exam_policies exam_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_policies
    ADD CONSTRAINT exam_policies_pkey PRIMARY KEY (id);


--
-- Name: exam_question_association exam_question_association_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_question_association
    ADD CONSTRAINT exam_question_association_pkey PRIMARY KEY (exam_id, question_id);


--
-- Name: exam_schedule_overrides exam_schedule_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_schedule_overrides
    ADD CONSTRAINT exam_schedule_overrides_pkey PRIMARY KEY (id);


--
-- Name: exams exams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: payment_receipts payment_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_receipts
    ADD CONSTRAINT payment_receipts_pkey PRIMARY KEY (id);


--
-- Name: programme_signatures programme_signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_signatures
    ADD CONSTRAINT programme_signatures_pkey PRIMARY KEY (id);


--
-- Name: question_banks question_banks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_banks
    ADD CONSTRAINT question_banks_pkey PRIMARY KEY (id);


--
-- Name: question_revisions question_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_revisions
    ADD CONSTRAINT question_revisions_pkey PRIMARY KEY (id);


--
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: result_appeals result_appeals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_appeals
    ADD CONSTRAINT result_appeals_pkey PRIMARY KEY (id);


--
-- Name: retake_authorizations retake_authorizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retake_authorizations
    ADD CONSTRAINT retake_authorizations_pkey PRIMARY KEY (id);


--
-- Name: saved_reports saved_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_reports
    ADD CONSTRAINT saved_reports_pkey PRIMARY KEY (id);


--
-- Name: staff_login_approvals staff_login_approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_login_approvals
    ADD CONSTRAINT staff_login_approvals_pkey PRIMARY KEY (id);


--
-- Name: staff_mfa staff_mfa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_mfa
    ADD CONSTRAINT staff_mfa_pkey PRIMARY KEY (id);


--
-- Name: staff_mfa staff_mfa_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_mfa
    ADD CONSTRAINT staff_mfa_user_id_key UNIQUE (user_id);


--
-- Name: staff_signatures staff_signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_signatures
    ADD CONSTRAINT staff_signatures_pkey PRIMARY KEY (id);


--
-- Name: staff_signatures staff_signatures_role_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_signatures
    ADD CONSTRAINT staff_signatures_role_key_key UNIQUE (role_key);


--
-- Name: system_settings system_settings_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_key_key UNIQUE (key);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (id);


--
-- Name: training_programs training_programs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.training_programs
    ADD CONSTRAINT training_programs_pkey PRIMARY KEY (id);


--
-- Name: exam_attempts unique_exam_attempt_number; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_attempts
    ADD CONSTRAINT unique_exam_attempt_number UNIQUE (exam_id, user_id, attempt_number);


--
-- Name: exam_schedule_overrides unique_schedule_override; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_schedule_overrides
    ADD CONSTRAINT unique_schedule_override UNIQUE (exam_id, user_id);


--
-- Name: exam_access_grants uq_exam_access_user_exam; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_access_grants
    ADD CONSTRAINT uq_exam_access_user_exam UNIQUE (user_id, exam_id);


--
-- Name: programme_signatures uq_programme_signature_role; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_signatures
    ADD CONSTRAINT uq_programme_signature_role UNIQUE (training_program_id, role_key);


--
-- Name: question_revisions uq_question_version; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_revisions
    ADD CONSTRAINT uq_question_version UNIQUE (question_id, version);


--
-- Name: payment_receipts uq_receipt_user_exam; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_receipts
    ADD CONSTRAINT uq_receipt_user_exam UNIQUE (user_id, exam_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_audit_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_action ON public.audit_logs USING btree (action, created_at);


--
-- Name: idx_audit_user_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_user_time ON public.audit_logs USING btree (user_id, created_at);


--
-- Name: ix_answers_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_answers_id ON public.answers USING btree (id);


--
-- Name: ix_audit_logs_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_logs_id ON public.audit_logs USING btree (id);


--
-- Name: ix_auth_sessions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_auth_sessions_user_id ON public.auth_sessions USING btree (user_id);


--
-- Name: ix_candidate_identities_candidate_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_candidate_identities_candidate_number ON public.candidate_identities USING btree (candidate_number);


--
-- Name: ix_candidate_identities_examination_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_candidate_identities_examination_number ON public.candidate_identities USING btree (examination_number);


--
-- Name: ix_candidate_profiles_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_candidate_profiles_id ON public.candidate_profiles USING btree (id);


--
-- Name: ix_exam_access_grants_exam_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_exam_access_grants_exam_id ON public.exam_access_grants USING btree (exam_id);


--
-- Name: ix_exam_access_grants_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_exam_access_grants_user_id ON public.exam_access_grants USING btree (user_id);


--
-- Name: ix_exam_attempts_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_exam_attempts_id ON public.exam_attempts USING btree (id);


--
-- Name: ix_exam_schedule_overrides_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_exam_schedule_overrides_id ON public.exam_schedule_overrides USING btree (id);


--
-- Name: ix_exams_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_exams_id ON public.exams USING btree (id);


--
-- Name: ix_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: ix_payment_receipts_exam_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_payment_receipts_exam_id ON public.payment_receipts USING btree (exam_id);


--
-- Name: ix_payment_receipts_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_payment_receipts_status ON public.payment_receipts USING btree (status);


--
-- Name: ix_payment_receipts_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_payment_receipts_user_id ON public.payment_receipts USING btree (user_id);


--
-- Name: ix_programme_signatures_training_program_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_programme_signatures_training_program_id ON public.programme_signatures USING btree (training_program_id);


--
-- Name: ix_question_banks_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_question_banks_id ON public.question_banks USING btree (id);


--
-- Name: ix_question_revisions_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_question_revisions_question_id ON public.question_revisions USING btree (question_id);


--
-- Name: ix_questions_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_questions_id ON public.questions USING btree (id);


--
-- Name: ix_result_appeals_attempt_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_result_appeals_attempt_id ON public.result_appeals USING btree (attempt_id);


--
-- Name: ix_result_appeals_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_result_appeals_status ON public.result_appeals USING btree (status);


--
-- Name: ix_retake_authorizations_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_retake_authorizations_id ON public.retake_authorizations USING btree (id);


--
-- Name: ix_saved_reports_exam_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_saved_reports_exam_id ON public.saved_reports USING btree (exam_id);


--
-- Name: ix_saved_reports_training_program_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_saved_reports_training_program_id ON public.saved_reports USING btree (training_program_id);


--
-- Name: ix_staff_login_approvals_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_staff_login_approvals_status ON public.staff_login_approvals USING btree (status);


--
-- Name: ix_staff_login_approvals_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_staff_login_approvals_user_id ON public.staff_login_approvals USING btree (user_id);


--
-- Name: ix_system_settings_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_system_settings_id ON public.system_settings USING btree (id);


--
-- Name: ix_training_programs_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_training_programs_code ON public.training_programs USING btree (code);


--
-- Name: ix_training_programs_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_training_programs_id ON public.training_programs USING btree (id);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- Name: ix_users_reset_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_users_reset_token ON public.users USING btree (reset_token);


--
-- Name: ix_users_verification_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_users_verification_token ON public.users USING btree (verification_token);


--
-- Name: answers answers_attempt_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.answers
    ADD CONSTRAINT answers_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.exam_attempts(id);


--
-- Name: answers answers_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.answers
    ADD CONSTRAINT answers_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: auth_sessions auth_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_sessions
    ADD CONSTRAINT auth_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: candidate_identities candidate_identities_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_identities
    ADD CONSTRAINT candidate_identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: candidate_profiles candidate_profiles_training_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_profiles
    ADD CONSTRAINT candidate_profiles_training_program_id_fkey FOREIGN KEY (training_program_id) REFERENCES public.training_programs(id);


--
-- Name: candidate_profiles candidate_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_profiles
    ADD CONSTRAINT candidate_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: exam_access_grants exam_access_grants_exam_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_access_grants
    ADD CONSTRAINT exam_access_grants_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(id);


--
-- Name: exam_access_grants exam_access_grants_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_access_grants
    ADD CONSTRAINT exam_access_grants_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(id);


--
-- Name: exam_access_grants exam_access_grants_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_access_grants
    ADD CONSTRAINT exam_access_grants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: exam_attempts exam_attempts_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_attempts
    ADD CONSTRAINT exam_attempts_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id);


--
-- Name: exam_attempts exam_attempts_exam_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_attempts
    ADD CONSTRAINT exam_attempts_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(id);


--
-- Name: exam_attempts exam_attempts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_attempts
    ADD CONSTRAINT exam_attempts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: exam_policies exam_policies_exam_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_policies
    ADD CONSTRAINT exam_policies_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(id);


--
-- Name: exam_question_association exam_question_association_exam_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_question_association
    ADD CONSTRAINT exam_question_association_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(id);


--
-- Name: exam_question_association exam_question_association_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_question_association
    ADD CONSTRAINT exam_question_association_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: exam_schedule_overrides exam_schedule_overrides_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_schedule_overrides
    ADD CONSTRAINT exam_schedule_overrides_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: exam_schedule_overrides exam_schedule_overrides_exam_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_schedule_overrides
    ADD CONSTRAINT exam_schedule_overrides_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(id);


--
-- Name: exam_schedule_overrides exam_schedule_overrides_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exam_schedule_overrides
    ADD CONSTRAINT exam_schedule_overrides_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: exams exams_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: exams exams_training_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_training_program_id_fkey FOREIGN KEY (training_program_id) REFERENCES public.training_programs(id);


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: payment_receipts payment_receipts_exam_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_receipts
    ADD CONSTRAINT payment_receipts_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(id);


--
-- Name: payment_receipts payment_receipts_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_receipts
    ADD CONSTRAINT payment_receipts_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id);


--
-- Name: payment_receipts payment_receipts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_receipts
    ADD CONSTRAINT payment_receipts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: programme_signatures programme_signatures_training_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_signatures
    ADD CONSTRAINT programme_signatures_training_program_id_fkey FOREIGN KEY (training_program_id) REFERENCES public.training_programs(id);


--
-- Name: programme_signatures programme_signatures_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_signatures
    ADD CONSTRAINT programme_signatures_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id);


--
-- Name: question_banks question_banks_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_banks
    ADD CONSTRAINT question_banks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: question_banks question_banks_training_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_banks
    ADD CONSTRAINT question_banks_training_program_id_fkey FOREIGN KEY (training_program_id) REFERENCES public.training_programs(id);


--
-- Name: question_revisions question_revisions_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_revisions
    ADD CONSTRAINT question_revisions_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.users(id);


--
-- Name: question_revisions question_revisions_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_revisions
    ADD CONSTRAINT question_revisions_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: question_revisions question_revisions_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_revisions
    ADD CONSTRAINT question_revisions_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id);


--
-- Name: questions questions_question_bank_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_question_bank_id_fkey FOREIGN KEY (question_bank_id) REFERENCES public.question_banks(id);


--
-- Name: result_appeals result_appeals_attempt_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_appeals
    ADD CONSTRAINT result_appeals_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.exam_attempts(id);


--
-- Name: result_appeals result_appeals_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_appeals
    ADD CONSTRAINT result_appeals_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id);


--
-- Name: result_appeals result_appeals_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result_appeals
    ADD CONSTRAINT result_appeals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: retake_authorizations retake_authorizations_authorized_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retake_authorizations
    ADD CONSTRAINT retake_authorizations_authorized_by_fkey FOREIGN KEY (authorized_by) REFERENCES public.users(id);


--
-- Name: retake_authorizations retake_authorizations_exam_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retake_authorizations
    ADD CONSTRAINT retake_authorizations_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(id);


--
-- Name: retake_authorizations retake_authorizations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retake_authorizations
    ADD CONSTRAINT retake_authorizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: saved_reports saved_reports_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_reports
    ADD CONSTRAINT saved_reports_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: saved_reports saved_reports_exam_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_reports
    ADD CONSTRAINT saved_reports_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(id);


--
-- Name: saved_reports saved_reports_training_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_reports
    ADD CONSTRAINT saved_reports_training_program_id_fkey FOREIGN KEY (training_program_id) REFERENCES public.training_programs(id);


--
-- Name: staff_login_approvals staff_login_approvals_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_login_approvals
    ADD CONSTRAINT staff_login_approvals_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id);


--
-- Name: staff_login_approvals staff_login_approvals_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_login_approvals
    ADD CONSTRAINT staff_login_approvals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: staff_mfa staff_mfa_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_mfa
    ADD CONSTRAINT staff_mfa_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: staff_signatures staff_signatures_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_signatures
    ADD CONSTRAINT staff_signatures_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id);


--
-- Name: system_settings system_settings_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--


