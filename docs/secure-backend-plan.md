# Secure backend plan — Suad Muhtaseb platform

## Current state
- The public site and assessment prototype are hosted on GitHub Pages.
- GitHub Pages is static hosting: it does not provide private accounts, a database, or server-side AI execution.
- The current assessment prototype does not submit or persist answers.
- The static dashboard is a prototype, not a protected administration panel. Do not enter real patient data there.

## Proposed roles
- **Waleed (platform admin):** platform configuration and account/role administration. This initial schema deliberately does not grant the admin role direct access to patient answers.
- **Suad (professional content reviewer):** authors and approves pathways, questions, and recommendation rules; reviews submissions and session requests.
- **Patient/user:** gives informed consent, submits an assessment, and can view only their own submissions and recommendations.

## Data minimization
- Do not request names, national IDs, or detailed contact information during the initial screening unless there is a documented need.
- Keep contact details in the separate session_requests table, not in assessment answers.
- Display a clear consent/privacy notice before saving any assessment.
- Define a retention and deletion policy before collecting real data.
- Do not describe the screening as a diagnosis or a substitute for professional care.

## Proposed database
The initial SQL migration at supabase/migrations/001_initial_schema.sql defines:
- role assignments;
- content pathways, questions, and approved recommendation rules;
- assessment submissions and answers;
- recommendations linked to the rule version used;
- session requests;
- a basic audit-events table.

Row Level Security (RLS) is enabled. The SQL is a starting point for review, not a completed production security audit.

## Deployment sequence
1. Confirm the correct Supabase organization and create/use a dedicated project for this platform. Do not reuse an unrelated project.
2. Review the schema and apply the migration to that dedicated project.
3. Configure authentication and assign the first admin and suad roles using a trusted server-side process.
4. Add a server-side endpoint for submissions and recommendation generation. Never put service-role credentials or AI provider secrets in browser JavaScript or the public repository.
5. Replace the prototype dashboard with authenticated views and server-backed save/review actions.
6. Test role boundaries with separate patient, Suad, and admin accounts; run Supabase security advisors; verify patients cannot read another patient's records.
7. Obtain Suad's review of every question, recommendation, safety message, and escalation path before public launch.

## Safety and privacy gate
Do not use real patient information until authentication, authorization, secure storage, retention/deletion, consent wording, and incident handling have been reviewed and tested. A static GitHub Pages page cannot securely store confidential patient records by itself.
