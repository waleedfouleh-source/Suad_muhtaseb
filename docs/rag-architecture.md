# RAG Architecture — Suad Muhtaseb Platform

Status: design proposal only. Do not connect production services or collect real case data until Suad reviews the workflow, consent, safety rules, and access model.

## 1. Goals and boundaries

The platform offers an initial social-support screening and explains possible next steps. It is not a diagnostic tool and must not tell a person that they definitely do or do not need professional help.

RAG (retrieval-augmented generation) supplies the AI with relevant passages from approved knowledge sources at answer time. It does not replace the deterministic safety checks, Suad's professional review, or a qualified clinician when one is needed.

## 2. Separate data domains

### A. Approved shared knowledge
- Suad-authored articles, pathways, questions, recommendation guidance, and approved FAQs.
- Trusted public guidance and research, each with source title, publisher, URL/DOI, publication date, access date, language, rights/usage notes, and review status.
- Every document has a source type, status (draft/reviewed/published/retired), owner/reviewer, version, and timestamps.
- Only reviewed/published documents may be retrieved for user-facing answers.

### B. Private case data
- A user's answers, recommendations, and session requests stay in private application tables.
- Never ingest private case answers into the shared vector index by default.
- Do not use one user's case to answer another user's question.
- Any future case-specific retrieval must be scoped to the authenticated user's own case or an explicitly authorized Suad review; enforce access on the server and database, not in prompt text alone.

### C. Operational and audit data
- Record minimal events needed for security and accountability.
- Do not put full answers, contact details, or sensitive narrative text into logs.
- Define retention, deletion, incident response, and access-review procedures before launch.

## 3. Proposed components

1. Arabic RTL web frontend (the existing static pages can remain a design prototype).
2. Supabase Auth for authenticated accounts.
3. PostgreSQL with Row Level Security (RLS) for users, roles, assessments, answers, approved recommendations, and review workflow.
4. Private Storage for source files, with access policies; no public bucket for confidential case files.
5. Server-side ingestion job: validate document type, extract text, normalize Arabic/English text, split into traceable chunks, attach source/version metadata, and create embeddings.
6. pgvector or an equivalent managed vector index for approved knowledge chunks.
7. Server-side RAG endpoint: authenticate caller, verify authorization, run safety checks, retrieve only published sources, compose a grounded response, validate citations, and return a brief explanation with references.
8. Human review interface for Suad to draft, approve, publish, version, and retire content and recommendation rules.
9. Monitoring and security tests that avoid recording sensitive user content.

## 4. Retrieval and answer flow

1. User sees and accepts a clear privacy/consent notice before any sensitive answers are saved.
2. The server validates the submitted fields and runs explicit safety screening before normal generation.
3. The request is classified into a platform-approved topic/pathway; classification is not a diagnosis.
4. Retrieve relevant chunks from published Suad guidance and published external references. Keep source types distinguishable.
5. Apply source filters and relevance thresholds. If evidence is weak or conflicting, say so and ask for human review rather than inventing an answer.
6. Generate a short, empathetic Arabic response using only retrieved evidence and approved rules.
7. Include source names/links and distinguish general information from Suad's own guidance.
8. Apply output checks: no diagnosis, no unsupported certainty, no promises of treatment, no claim that the person does not need help based solely on the questionnaire.
9. Save the result with the model/prompt version, retrieved source IDs and versions, recommendation-rule version, and review status. Avoid storing unnecessary raw prompts.
10. Suad reviews any case that the approved workflow flags for professional review.

## 5. Safety design

- Safety and crisis routing must not depend solely on vector retrieval or a language model.
- A professionally reviewed, deterministic safety pathway takes precedence over ordinary RAG output.
- For immediate danger, provide clear localized instructions to contact local emergency services or a trusted person and seek urgent in-person help; confirm the exact country-specific contacts with Suad before launch.
- The platform must not make a definitive diagnosis or imply that the screening can rule out a condition.
- Define scope-of-practice and referral rules with Suad and, where needed, a qualified mental-health professional.

## 6. Permissions

- User: create and view only their own submissions, answers, and recommendations.
- Suad: manage approved content and review only the cases assigned/authorized by the agreed workflow.
- Waleed (admin): manage platform configuration and accounts; administrative status alone should not automatically grant access to private case narratives.
- Role assignment and privileged operations must happen through a trusted server-side process.
- Enable and test RLS for every exposed table. Never place service-role keys or AI provider keys in browser JavaScript or a public repository.

## 7. Knowledge-source governance

For every external source, record provenance and review it before publication. Candidate source families for Suad to approve include WHO guidance, NICE guidance, UNICEF child/family guidance, and peer-reviewed literature. These are candidates, not yet an approved corpus. Respect source licensing and do not scrape or embed material without appropriate rights.

Suggested metadata:
- source_id, title, publisher/author, canonical_url_or_doi
- publication_date, accessed_at, language, topic
- source_type (suad_content / public_guidance / research)
- review_status, reviewed_by, reviewed_at, version
- chunk_id, page/section locator, content_hash, embedding_model_version

## 8. Database work still required

The existing `supabase/migrations/001_initial_schema.sql` is a starting schema for roles, content paths, questions, assessments, answers, recommendations, session requests, and audit events. It does not yet implement the RAG document/chunk/vector tables, ingestion pipeline, server-side generation endpoint, or production-ready authentication flow.

Before applying or extending migrations:
1. Confirm the dedicated Supabase project and owner with Waleed.
2. Review the current migration and test all RLS policies with separate admin, Suad, and user accounts.
3. Decide whether guest assessments are needed; the current schema assumes an authenticated user.
4. Confirm who can see a submitted case and whether Suad reviews every case or only explicit session requests.
5. Agree on consent wording, retention/deletion, emergency messaging, and the initial content scope with Suad.
6. Choose the embedding and language-model provider based on Arabic quality, cost, data handling, and contractual terms.
7. Add document/chunk/vector schema and server-side functions only after these decisions.

## 9. Test gates before public launch

- Cross-user isolation: one user cannot read or infer another user's records.
- Role isolation: admin cannot read private case narratives by default; Suad sees only authorized cases.
- Unpublished or retired content is never retrieved.
- Every evidence-based answer has valid source references; unsupported answers abstain.
- Prompt injection inside uploaded documents cannot override system policy or permissions.
- Safety cases bypass ordinary generation and show the professionally approved escalation path.
- Data deletion, account deletion, consent versioning, and audit procedures work as intended.
- No secrets or sensitive case data appear in public source files, browser bundles, or routine logs.

## 10. Current status

- Public-facing design prototype and a static assessment page exist.
- The static dashboard is not a secure authenticated dashboard.
- A preliminary SQL migration exists in the repository but has not been verified as deployed to Supabase.
- No production RAG service or secure case-storage flow has been verified.
- This document records the proposed architecture only; it does not claim that a backend has been deployed.
