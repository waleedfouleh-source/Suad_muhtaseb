# Schema Gap Review — Suad Muhtaseb Platform

Status: review only. No database was created or modified by this document. The existing SQL migration has not been confirmed as applied to any Supabase project.

Reviewed file: `supabase/migrations/001_initial_schema.sql`

## Summary

The existing migration is a useful starting point for user roles, content paths, questions, recommendation rules, assessments, answers, session requests, and audit events. It is not yet a RAG implementation or a production-ready case-management system.

Do not apply a new migration until Waleed confirms the dedicated Supabase project and Suad approves the data-access and safety workflow.

## Gaps for RAG

The current schema has no tables for:
- Knowledge sources and provenance metadata.
- Document versions and review/publishing lifecycle.
- Text chunks, chunk-to-source/page/section references, embeddings, or vector index.
- Ingestion job status and errors.
- RAG response trace: retrieved chunk IDs/source versions, prompt/model version, and review status.
- Content retirement/re-indexing and duplicate detection.

Recommended design: store only approved/published source chunks in the shared retrieval index. Keep private assessment answers and session requests outside that shared index. If case-specific retrieval is later required, enforce user/case scope in database policies and server-side authorization.

## Access-control and workflow questions to resolve

1. **Admin access:** The current comments intentionally do not grant the admin direct access to patient answers. Confirm that Waleed should manage configuration and accounts without routinely seeing sensitive case narratives.
2. **Suad access:** Current policies let Suad review all assessments. Decide whether she should see every submitted case or only cases assigned to her / cases where the user explicitly requests a session.
3. **Assessment creation:** The current schema requires an authenticated account. Decide whether anonymous/guest screening is required. Do not silently change this because it affects privacy, recovery, and follow-up.
4. **Answer lifecycle:** Current policies allow a user to insert answers for their own assessment without a database-level check that the assessment is still a draft. Consider server-only submission, or a strict draft-state policy.
5. **Recommendation integrity:** Define whether automated recommendations are drafts until Suad reviews them, and prevent unapproved rules from triggering user-facing outcomes.
6. **Session contact data:** Contact details are separated from answers, which is good. Decide what contact fields are essential and how long they are retained.
7. **Audit events:** The current schema has no client insert policy, so writes should occur only through a trusted server process. Decide which events are necessary and avoid logging sensitive narrative text.
8. **Account deletion and retention:** Add a tested deletion/retention approach before collecting real data. Deleting an account currently cascades to some linked data; this needs an explicit policy and review.
9. **Safety pathway:** Agree on reviewed urgent-risk questions, localized escalation wording, and who owns updates. Do not rely on RAG similarity alone for crisis decisions.
10. **Consent:** Define consent text and versioning, including what is stored, who can review it, whether AI is used, limitations, and how users request deletion.

## Proposed RAG data model (design only)

Potential tables to add after review:
- `knowledge_sources`: title, publisher/author, canonical URL/DOI, source type, language, publication date, access date, rights notes, review status, reviewer, version.
- `knowledge_documents`: source ID, storage path, content hash, ingestion status, extractor version, timestamps.
- `knowledge_chunks`: document ID, chunk index, section/page locator, text, metadata, embedding, embedding-model version, publication status.
- `rag_runs`: user/assessment scope, prompt/model version, created time, safety-path outcome, status; store minimal metadata.
- `rag_run_sources`: run ID, chunk ID, source/document version, relevance score if retained, citation locator.
- `content_review_events` (optional): review decisions and publication/retirement history, if not adequately covered by audit events.

Use foreign keys, appropriate indexes, RLS on every exposed table, and server-only writes for ingestion and RAG traces. Do not expose raw embeddings or private source files through public APIs. Store vector dimensions only after selecting the embedding model; do not guess them prematurely.

## Suggested implementation sequence

1. Meeting with Suad: confirm scope, access, consent, safety, retention, and approved content.
2. Confirm a dedicated Supabase project; inspect its current schema before any migration.
3. Review and test existing RLS policies using separate user, Suad, and admin accounts.
4. Finalize a migration draft for knowledge sources/documents/chunks and vector search.
5. Build a server-side ingestion pipeline and verify citations/provenance.
6. Build the server-side RAG endpoint with deterministic safety checks and an abstain path.
7. Run synthetic-data isolation and prompt-injection tests; run Supabase security advisors.
8. Only then consider a limited pilot, with Suad reviewing the outputs.

## Not done

- No Supabase project has been created or changed.
- No SQL migration has been applied.
- No AI or embedding provider has been selected or connected.
- No patient/case data has been ingested.
- No claim is made that the platform is production-ready.
