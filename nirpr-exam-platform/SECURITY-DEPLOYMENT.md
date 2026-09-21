# Security hardening and reCAPTCHA deployment

Prepared locally on September 21, 2026. These changes are not live until the owner approves committing, pushing, merging, and deploying them.

## reCAPTCHA v2 checkbox setup

The existing UI already uses the v2 checkbox, so no site key needs to be pasted into HTML.

1. In Google's reCAPTCHA settings, add `nirpr-exam-platform.onrender.com` to the allowed domains (no `https://` or path). Add any custom domain actually used by this app. Keep domain validation enabled.
2. In Render, open **NIRPR_EXAM_PLATFORM → Environment** and enter these values privately:
   - `RECAPTCHA_SITE_KEY`: your public v2 site key.
   - `RECAPTCHA_SECRET_KEY`: the matching private v2 secret key.
   - `RECAPTCHA_ALLOWED_HOSTNAMES`: `nirpr-exam-platform.onrender.com` (comma-separated if there are additional real domains).
   - `APP_BASE_URL`: `https://nirpr-exam-platform.onrender.com`.
3. Verify `SECRET_KEY` is a private, randomly generated value of at least 32 characters. Do not use the old example value. Changing an existing signing key invalidates existing login tokens; coordinate any rotation.
4. Store changes without deploying if Render offers that choice. Saving with deployment restarts the application and invokes its existing startup database maintenance, so obtain deployment approval first.
5. After approval and deployment, check `/api/auth/recaptcha-config`: it should return the public site key and provider only. Complete the checkbox yourself and test candidate/staff login and password recovery. Google tokens expire after two minutes and are single-use.

Never put the secret key in the frontend, GitHub, a pull request, or chat. Production now refuses missing/public test keys, missing hostname configuration, or an insecure signing key. Local development can explicitly configure Google's v2 test keys and their test hostname; there is no automatic test-key fallback.

## Changes in this patch

- Replace the publicly known default signing key with production validation and an ephemeral local fallback.
- Require expiring JWTs tied to a live session belonging to the authenticated principal. Validate administrator status on every impersonated request. Old sessionless tokens will require a new login.
- Revoke the server session when the user presses Sign out.
- Prevent an MFA setup request from silently replacing enabled MFA.
- Prevent regular admins from creating, importing, editing, resetting, or deleting Super Admin accounts.
- Validate reCAPTCHA server-side success and the hostname, fail closed on errors, and display configuration/load errors in the UI.
- Use the ASGI server's client address instead of blindly trusting client-supplied forwarding headers. Bound the in-memory rate limiter and make Redis counter expiry atomic.
- Limit API request bodies to 6 MiB before parsing, CSV files to 5 MiB, validate receipt images/PDF headers, and serve receipts as attachments. PDF header checking is not malware scanning.
- Add CSP restrictions for embedded objects, base URLs, framing, and form targets; enable HSTS in production.
- Update vulnerable dependency pins and replace python-jose/ecdsa with PyJWT for HS256 tokens. Add a dependency audit to CI.

## Validation and limits

Validation passed: 36 backend tests on Python 3.12 using a disposable SQLite database and mocked Google responses; Python/JavaScript syntax checks; workflow YAML parsing; and frontend reCAPTCHA initialization and logout checks. The tests emitted 38 deprecation warnings. Dependency auditing of the updated local Python environment reported no known vulnerabilities, and pip reported no broken requirements. GitHub's Linux dependency resolution, live reCAPTCHA keys, actual browser login, PostgreSQL behavior, and production configuration must still be verified before rollout. A clean dependency scan is not proof that the application cannot be hacked.

This patch does not change database models or migrate production data. The pre-existing automatic database changes during startup remain and require a separate migration approval design.

Further work remains: remove inline-script dependencies and audit all HTML insertion sites, consider HttpOnly-cookie authentication with CSRF protection instead of browser localStorage tokens, test full exam/admin workflows, verify Render's trusted proxy handling before tuning IP limits, configure shared Redis for multiple workers, and establish backups, restore tests, monitoring, and incident response. The local rate-limit fallback is process-local and is not a distributed denial-of-service defense. Production penetration testing and paid infrastructure changes require separately scoped work.

## GitHub and Render status

PR #1 was merged. It changed only `.github/` files, outside Render's `nirpr-exam-platform` root directory, so Render did not redeploy the application. At inspection Render still used **On Commit**. **After CI Checks Pass**, required checks, branch protection, and the owner approval identity arrangement remain to be configured with approval. This patch does not silently change those settings.

References: [Google verification](https://developers.google.com/recaptcha/docs/verify), [Google domain validation](https://developers.google.com/recaptcha/docs/domain_validation), [Render deploys](https://render.com/docs/deploys), [Render monorepo filtering](https://render.com/docs/monorepo-support).
