# CI and deployment approval setup

This is a local proposal. Adding this file does not enable branch protection or change Render settings.

## Proposed workflow

1. Prepare changes locally and show the owner the diff.
2. Obtain explicit approval before committing and pushing a feature branch.
3. Open a pull request to `main`. Platform CI runs the existing backend smoke tests.
4. The owner reviews the exact changes and authorizes the merge. Do not enable auto-merge.
5. After the approved merge, CI runs again on `main`. Configure Render to deploy only after checks pass.

CI uses a disposable in-memory SQLite database, no production secrets, and read-only repository permissions. It does not deploy, merge, or run commands against the Render database. These four smoke tests cover health/CAPTCHA/verification-page responses and PDF generation; they do not establish PostgreSQL migration compatibility or full examination-flow correctness.

## GitHub settings to apply separately after approval

- Require pull requests for `main`; block force pushes and branch deletion.
- Require the `Backend smoke tests` check after it has run successfully on GitHub.
- For a formal owner approval requirement, use a separate PR author identity, designate `@Olumide66` as code owner, require code-owner review, dismiss stale approvals, and prevent unauthorized bypasses.
- The currently connected account is `Olumide66`. GitHub does not allow an author to approve their own PR. Do not enable a review rule that leaves the owner unable to merge without first resolving the author/reviewer arrangement.
- Approval before local changes, commits, and pushes must be obtained by the agent; branch protection alone does not implement those prompts.

## Existing Render service (inspected September 21, 2026)

- Service: `NIRPR_EXAM_PLATFORM` (`srv-dao335bm8hqs73d3calg`)
- Repository: `Olumide66/NIRPR_EXAM_PLATFORM`, branch `main`
- Root directory: `nirpr-exam-platform`
- Build: `pip install -r backend/requirements.txt`
- Start: `cd backend && uvicorn main:app --host 0.0.0.0 --port $PORT`
- Current auto-deploy: **On Commit**
- Proposed auto-deploy: **After CI Checks Pass**, once CI is active and the approval policy is established.

Render root-directory filtering may skip deployment for changes confined to `.github/`; an initial CI-only merge need not deploy application code. Do not trigger a production deployment just to test this workflow.

## Database approval limitation

`backend/main.py` calls `init_db()` during application startup. `backend/database.py` creates tables and can alter existing columns, migrate names, and drop the old `full_name` column. Startup also performs candidate-identity maintenance.

Therefore, the current application has no independent database-migration approval gate: starting or deploying it may change the database. Separating migrations from startup requires a separately reviewed application change and migration procedure. Until then, review database effects and obtain explicit approval before any production deployment that may execute them. CI passing is not migration approval.

## References

- https://docs.github.com/en/actions/tutorials/build-and-test-code/python
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches
- https://docs.github.com/en/enterprise-cloud@latest/pull-requests/how-tos/review-pull-requests/approving-a-pull-request-with-required-reviews
- https://render.com/docs/deploys
