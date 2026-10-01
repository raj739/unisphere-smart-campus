# UniSphere Evaluator Presentation Guide

Deck: 23 slides. Suggested use: a concise pitch with selected evidence slides, followed by the live demonstration.

Screenshots show the local Windows prototype and demonstration records. Do not present catalogue counts as deployment scale or the cover illustration as a photograph of Vikram University.

## 1. UniSphere

UniSphere is a unified campus platform connecting administration, students and linked parents. This presentation shows a working Windows prototype and its operating workflows. The cover is a concept illustration, not a photograph of the university.

Source: `EXECUTIVE_SUMMARY.md; assets/submission/unisphere-campus-cover.png`

## 2. The Campus Service Problem

The challenge is not just putting forms online. It is connecting ownership, status and authenticated records across the student lifecycle. These are the problem-statement assumptions, not findings from a quantified campus survey.

Source: `User-supplied Smart University Digital Campus problem statement`

## 3. One Platform, Three Accountable Roles

All portals use a shared backend. A student is resolved from the authenticated user, rather than a hardcoded demo name. Parent access depends on an active parent-student link. Record updates appear when the view loads or refreshes; do not claim that every view is automatically pushed in real time.

Source: `lib/features/admin/admin_shell.dart; lib/services/auth_service.dart; backend/app/api/v1/parent_v2.py`

## 4. Student Lifecycle Workflow

A new account is not automatically a complete student record. Administrators first configure master data and then provision an academic plan. Service allocations and parent registration are explicit operations. The demo curriculum may provision sample timetable, fee invoice and examination records; it is not an official syllabus.

Source: `lib/features/admin/admin_academic_plans_screen.dart; EXECUTIVE_SUMMARY.md`

## 5. Administration and Governance

Explain how dashboard counts are calculated from configured records. The screenshot contains a small demonstration cohort and imported catalogue data; the counts are not proof of deployment scale. The catalogue includes demo curriculum papers.

Source: `lib/features/admin/admin_dashboard_screen.dart`

## 6. Academic Planning

Show Raj selected in the register. The programme, specialization, curriculum, session and semester are connected. Optional provisioning covers courses, standard timetable, fee invoice and demo examination plan. The visible demo-curriculum warning is an important disclosure.

Source: `lib/features/admin/admin_academic_plans_screen.dart`

## 7. Attendance Operations

The screenshot shows a locked session and Raj in its roster. Recording is controlled by administrators in the current prototype. Attendance contributes to student visibility and risk signals. Aggregate metric consistency across views remains an acceptance-test item; do not describe any screenshot percentage as an audited institutional KPI.

Source: `lib/features/admin/admin_attendance_screen.dart`

## 8. Examination Operations

Show the examination window and five-paper schedule. Explain the registration/approval workflow and publication of results against students and courses. The visible plan is explicitly a demonstration schedule.

Source: `lib/features/admin/admin_examinations_screen.dart`

## 9. The Personalized Student Portal

Raj is the logged-in student, with programme and semester in the header. The dashboard links to academics, attendance, results, exams, success, AI, passport and services. Demo percentages are illustrative records, not measured impact; the dashboard and risk pages currently expose different attendance aggregation scopes, requiring reconciliation before a production pilot.

Source: `lib/features/dashboard/dashboard_screen.dart; lib/app/app_shell.dart`

## 10. Hostel Allocation: Admin to Student

These are two authentic views of Raj's existing allocation to Shaligram, room A1. Occupancy is one of two beds. Admin sees the available bed; Raj sees his building, room, allocation number and residence status. Complaints have a separate request workflow. No new allocation was created for the deck.

Source: `lib/features/admin/admin_hostel_screen.dart; lib/features/hostel/hostel_screen.dart`

## 11. Transport Allocation: Admin to Student

Admin sees the route, vehicle, seat position and passengers. Raj sees the linked route, stop, pass and vehicle and can report an issue. The current demonstration record has no pickup time or driver configured: the UI explicitly shows missing values instead of inventing information. GPS tracking is not an implemented claim.

Source: `lib/features/admin/admin_transport_screen.dart; lib/features/transport/transport_screen.dart`

## 12. Digital Certificate Operations

The screenshot shows issued requests belonging to Raj and Aarav. Describe purpose, approval/rejection, certificate number, PDF, QR verification and revocation. Focus on service certificates such as bonafide, residence and no-dues. No blockchain, DigiLocker or government identity integration is claimed. The loopback verification URL needs a public deployment URL before institutional use.

Source: `lib/features/admin/admin_certificates_screen.dart; backend/app/api/v1/certificates.py`

## 13. Parent Account Registration

The administrator registers a parent with name, contact, password, relationship and selected student. An additional student may be linked to an existing parent. Registering a student does not silently create a parent account. Credential delivery by verified email/SMS is a future integration.

Source: `lib/features/admin/admin_parents_screen.dart; backend/app/api/v1/parent_v2.py`

## 14. The Parent Portal

The parent experience uses live V2 profile, student-link and dashboard APIs. The demonstration parent is linked to Aarav; Raj has a separate parent relationship. This slide describes the implemented workflow from source code; it is not a screenshot of the parent portal. Results detail, hostel and transport are not claimed as parent features.

Source: `lib/features/parent/parent_portal_screen.dart; backend/app/api/v1/parent_v2.py`

## 15. Student AI Assistance

Explain the answer routing: authenticated personal records first, approved campus knowledge, curated general facts and Gemini for open-ended general questions. The screen demonstrates a grounded answer and recommendations; it is not a screenshot of model training. Direct student-context payloads are excluded from Gemini requests, but conversation history requires privacy review/redaction before production. Additional Indian-language and Bhashini integrations remain future work.

Source: `backend/app/api/v1/ai_v2.py; backend/app/services/ai_prompt_service.py; lib/features/ai/ai_screen.dart`

## 16. Explainable Student Risk

The current RiskEngine uses explicit weighted rules. High >=70; medium >=40; low <40. Missing evidence can produce an insufficient-data state. The UI's dropout-likelihood value currently mirrors the risk score: it is NOT a calibrated probability, a trained dropout model or a measured accuracy result. Human review is required; no punitive automated decisions are proposed.

Source: `backend/app/services/risk_engine.py; backend/app/api/v1/risk.py; lib/features/admin/risk_analytics_screen.dart`

## 17. Early Warning and Intervention

The screenshot shows existing warnings and a case already in intervention. Staff can decide whether support is needed, document the intervention and track status. Creating a warning is not the same as proving a student will drop out. Outcome measurements and false-positive review belong in the pilot.

Source: `lib/features/admin/admin_early_warning_screen.dart; lib/features/admin/intervention_screen.dart`

## 18. Innovation in the Overall Solution

Describe these as design differentiators in this implementation, not world-first inventions. The strongest example is a named student whose academic plan, allocations, assistant and support workflow share the same identity. General language assistance and deterministic institutional records are intentionally different responsibilities.

Source: `EXECUTIVE_SUMMARY.md; backend/app/api/v1/ai_v2.py; backend/app/services/risk_engine.py`

## 19. Technical Architecture

Read this top to bottom as request and ownership layers. API keys stay on the backend, not in the Flutter client or slides. PostgreSQL is the deployment configuration, whereas the screenshot instance uses SQLite. A Flutter codebase targets mobile/web, but this deck evidences Windows only; device acceptance testing remains. Production controls require explicit testing, not inference from framework choice.

Source: `backend/app/main.py; backend/app/core; backend/docker-compose.production.yml; pubspec.yaml`

## 20. Expected Impact and Pilot Measures

Collect a baseline before a limited institutional pilot, then compare the same tasks after adoption. Record both successful completions and errors. Do not claim percentage reductions, prediction accuracy, student satisfaction or government compliance without data. Alignment is with Digital Campus, Ease of Governance, Smart Universities and Viksit Bharat; this is not an official endorsement.

Source: `User-supplied expected outcome and strategic alignment; EXECUTIVE_SUMMARY.md`

## 21. Current Readiness and Remaining Work

Unavailable admin modules include grievance, dedicated voice administration, admin passport, secure sharing, permission configuration, audit-log UI, realtime administration and settings. Backend foundations do not establish full UI support. Existing fee invoices and recorded payments are not evidence of live gateway settlement. Campus records shown are demonstration data. Audit aggregate consistency, refresh behavior, authorization, AI history handling, public certificate URLs and operational recovery before pilot approval.

Source: `lib/features/admin/admin_shell.dart; EXECUTIVE_SUMMARY.md; captured demo screens`

## 22. Evaluator Demonstration Sequence

Use existing demo records. Avoid creating duplicate students or allocating a second room during the presentation. Load each screen once before the session and confirm the backend/provider are available. If a model call fails, explain fallback behavior and use the captured UI as evidence rather than asserting an external result. All demo credentials should remain private. Allow 6-8 minutes for this route and keep the technical material for Q&A.

Source: `Captured Windows prototype screens; EXECUTIVE_SUMMARY.md`

## 23. Evaluation Summary

Close with the connected journey, not a feature count. Invite evaluation against the actual screenshot workflows and the live demo. The strongest evidence is the same Raj identity visible in academic planning, attendance, exams, residence, transport and student assistance. State the limitations clearly and request a controlled pilot, not an unrestricted production rollout.

Source: `EXECUTIVE_SUMMARY.md; captured Windows prototype screens`

## Likely Evaluator Questions

**Is the predictive model trained?** No. The current implementation is an explainable weighted risk engine. A validated, historically trained dropout model is future work.

**Why not just a chatbot?** Staff-owned academic and service transactions are the core; AI helps students navigate and understand those records.

**Where does a new student's data come from?** University staff register the student, assign the academic plan and create service allocations. Parent access is a separate authorized registration/link step.

**Does it support real payments?** Invoice and recorded-payment workflows exist. Live gateway settlement and reconciliation are not established in this demonstration.

**Can the parent see any student?** No. The intended workflow restricts parent data to active staff-created links; test these authorization boundaries before deployment.

**Does Gemini receive student records?** Personal-record queries are answered locally and the direct student-context payload is empty for external calls. Conversation history may still include personal details and needs explicit redaction/privacy review.

**What is the mobile status?** Flutter supports additional targets, but this deck demonstrates Windows desktop. Mobile device acceptance testing remains.

**What needs fixing before a pilot?** Consistent metric aggregation, privacy handling, production verification URLs, security/recovery testing and unavailable admin workflows.