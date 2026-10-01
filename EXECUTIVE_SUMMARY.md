# UniSphere Smart University Digital Campus

## Executive Summary

**Document date:** 1 October 2026  
**Application:** UniSphere  
**Current verified client:** Windows desktop  
**Platform goal:** A unified digital campus for academic administration, student services, parent visibility, operational governance, and data-supported student success.

UniSphere replaces disconnected university-office processes with one role-based platform. Administrators create the institutional structure, register students and parents, plan academics, operate examinations and attendance, allocate hostel and transport services, manage certificates and support requests, and monitor student risk. Students receive a personalized portal containing only their live records. Parents receive controlled access only to students formally linked to their accounts.

The application uses a Flutter client, a FastAPI backend, SQLAlchemy data models, JWT authentication, SQLite for local demonstration, and PostgreSQL for production deployment. Gemini powers general conversational assistance, while personal campus questions are answered from authenticated UniSphere records. Conversation history still needs redaction review before external provider use.

## Business Value

- Provides one digital identity and one login for each user.
- Reduces visits to multiple university offices.
- Establishes clear ownership of academic and service data.
- Gives students transparent access to their current records.
- Gives parents permission-controlled visibility into linked students.
- Supports early identification and follow-up of students needing assistance.
- Creates auditable workflows instead of disconnected static screens.
- Supports future mobile deployment from the same Flutter codebase.

## User Roles

| Role | Primary responsibility | Available experience |
| --- | --- | --- |
| Administrator | Configure and operate the university | Command center, master data, Student 360, academics, attendance, examinations, services, risk, parents, analytics, and reports |
| Student | View records and request services | Personalized dashboard, academics, services, AI assistant, certificates, student success, profile, and notifications |
| Parent | Monitor formally linked students | Linked-student selector, attendance, fees, examinations, identity details, and attention indicators |

## End-to-End Operating Workflow

### 1. Institutional Setup

The administrator creates or imports the university structure in this order:

1. University
2. Departments
3. Programmes and specializations
4. Academic sessions
5. Curricula and semester structures
6. Courses and course offerings

The current catalogue includes the imported Vikram University programme and curriculum data. This master data drives student registration, course enrollment, timetable, attendance, examinations, and reporting.

### 2. Student Registration and Academic Assignment

1. The administrator opens **Students** and registers a student.
2. The backend creates the user account and student record.
3. A unique Uni-ID is generated; university and enrollment identifiers are stored when provided.
4. The administrator assigns a programme, specialization, curriculum, academic session, and current semester.
5. The academic-plan workflow can enroll the student in course offerings, create a standard timetable, and generate an initial fee invoice.
6. The student logs in and sees only records associated with that authenticated account.

### 3. Academic Operations

1. Administrators create semesters, courses, and course offerings.
2. Students are enrolled into course offerings.
3. Timetable entries connect offerings with day, time, room, building, and faculty information.
4. Attendance sessions are created for course offerings.
5. Administrators record attendance in bulk and lock completed sessions.
6. Examinations and paper schedules are created for an academic session and semester.
7. Students are registered for eligible examinations; registrations can be approved or locked.
8. Results are published against the student and course.
9. The same live records appear in the student portal, Student 360, parent portal, dashboards, and predictive workflows.

### 4. Parent Registration and Linking

Parent access is controlled by university staff; there is no unsafe public claim-student workflow.

1. Register the student first.
2. Open **Admin > Parents**.
3. Select **Register parent**.
4. Enter parent name, email, phone, temporary password, and relationship.
5. Select the student to link.
6. The backend creates the parent account, parent profile, and active student link in one transaction.
7. The parent selects the Parent role at login.
8. Additional students can be attached through **Link another student**.

The parent portal reads V2 live data and supports switching between linked students. Desktop sign-out is visible in the top-right header; mobile uses the logout icon.

### 5. Hostel Workflow

1. Admin registers hostel buildings.
2. Admin creates rooms under the correct building, including capacity and room details.
3. The occupancy view distinguishes available, partly occupied, and full rooms.
4. Admin allocates a room to a student.
5. The student sees building, room, floor, room type, allocation number, occupancy, and status.
6. Students create hostel requests or complaints.
7. Admin reviews and resolves those requests.

### 6. Transport Workflow

1. Admin creates routes and route stops.
2. Admin registers vehicles and assigns vehicles to routes.
3. Admin allocates a route, stop, and pass to a student.
4. The student sees route, boarding stop, pickup time, vehicle, driver, contact, and pass information.
5. Students report transport issues.
6. Admin tracks and resolves those issues.

### 7. Certificate Workflow

1. Admin maintains the available certificate types.
2. A student submits a certificate request with its purpose.
3. Admin reviews, approves, rejects, or issues the request.
4. Issuance generates a unique certificate number and downloadable PDF.
5. The PDF contains verification information and a QR code.
6. A certificate can be verified by its certificate number.
7. Admin can revoke a certificate; verification then reflects its current status.

### 8. Helpdesk and Notifications

Students create categorized helpdesk tickets for academics, fees, hostel, transport, examinations, technical issues, or other services. Each ticket has a priority and status. Admin can review the ticket list and service activity. Notifications are targeted to users and can be marked as read by the recipient.

## Student Portal Features

| Module | What it does |
| --- | --- |
| Dashboard | Shows live identity, attendance, CGPA/results, course count, outstanding fees, recommendations, and upcoming timetable |
| Academics | Shows the assigned academic plan, enrolled courses, credits, faculty, results, and examinations |
| Attendance | Shows course-level recorded attendance and no-data states |
| Results | Shows published marks, grade, and grade points |
| Timetable | Shows day, time, course, faculty, building, and room |
| Examinations | Shows registration, papers, dates, venue, and registration status |
| Student Success | Shows risk outlook, support alerts, interventions, and personalized recommendations |
| AI Assistant | Supports campus questions, general questions, follow-ups, English/Hindi, speech input, and spoken responses |
| Academic Passport | Generates a consolidated verified academic identity snapshot |
| Services | Summarizes fees, payment history, and examinations |
| Hostel | Shows active allocation and supports complaints/requests |
| Transport | Shows active allocation and supports issue reporting |
| Certificates | Requests, tracks, downloads, cancels, and verifies digital certificates |
| Timeline | Shows lifecycle events associated with the authenticated student |
| Helpdesk | Creates and tracks university support tickets |
| Profile | Shows account and academic identity and provides sign-out |
| Notifications | Shows personal notifications and read status |

## Administrator Features

### Operational Modules

- Live dashboard and institutional counts
- Student registration and identity generation
- Student 360 consolidated record and actions
- Academic-plan assignment and result publication
- University, department, programme, specialization, and session master data
- Semester, course, offering, enrollment, and timetable operations
- Attendance session, roster, bulk marking, and locking
- Examination, paper schedule, registration, approval, and locking
- Digital document creation and status management
- Certificate request review, issue, PDF generation, verification, and revocation
- Fee structures, invoices, adjustments, payment records, and transaction views
- Hostel building, room, occupancy, allocation, and complaint management
- Transport route, stop, vehicle, assignment, allocation, and issue management
- Parent registration and student linking
- Notification delivery
- Predictive risk dashboard and recalculation
- Early-warning review and resolution
- Intervention creation, assignment, status tracking, and follow-up
- University analytics and downloadable reports
- AI knowledge-base management through backend-supported workflows

### Modules Explicitly Marked Unavailable in the Current Admin UI

- Grievance
- Dedicated admin Voice Assistant page
- Admin Academic Passport page
- Secure Sharing page
- RBAC and Permissions page
- Audit Logs page
- Realtime operations page
- System Settings

Several of these have backend foundations, but they are not presented as completed admin workflows and should not be demonstrated as finished features.

## AI Assistant Architecture

The AI assistant uses a layered approach:

1. **Authenticated live context:** UniSphere gathers only the logged-in student's courses, attendance, timetable, examinations, fees, hostel, transport, certificates, helpdesk, warnings, interventions, and recommendations.
2. **Grounded local answers:** Personal questions are answered by deterministic backend logic using those live records.
3. **Approved university knowledge:** Relevant active knowledge-base records are retrieved for campus-policy questions.
4. **Curated general information:** Common general questions can be answered locally.
5. **Gemini fallback:** Unanswered general questions are sent to Gemini. Private student context is deliberately excluded from this external request.
6. **Reliability:** Temporary Gemini `429` and `5xx` failures trigger retries and fallback models.
7. **Language and interaction:** The assistant supports automatic language selection, English, Hindi, voice input, text-to-speech, conversation sessions, and follow-up suggestions.

The application does not currently train a custom language model. It combines live database grounding, approved knowledge retrieval, curated responses, and Gemini generation.

## Predictive Student Success

The current predictive component is an explainable weighted risk engine, not a trained machine-learning model. It uses:

- Attendance: 40%
- Academic performance: 30%
- Outstanding fees: 15%
- Engagement: 15%

It produces a score, Low/Medium/High classification, contributing factors, confidence based on available records, and a recommended action. Students without enough evidence are shown as **Insufficient Data** instead of receiving an invented prediction.

Threshold-based early warnings detect issues such as low attendance, weak academic performance, fee pressure, low engagement, and elevated combined risk. Administrators can convert warnings into assigned interventions, while students can see their own support cases and recommendations.

## Authentication, Authorization, and Privacy

- Login is email/password based.
- Passwords are stored as bcrypt hashes.
- Successful login returns a time-limited JWT.
- The Flutter client stores the active session locally.
- Backend routes enforce role requirements for student, parent, and administrator actions.
- Student records are resolved from the authenticated user rather than hard-coded names.
- Parent access requires an active parent-student link.
- Direct student-context payloads are excluded from Gemini requests; conversation history may still contain personal answers and needs redaction before production use.
- Production requires a JWT secret of at least 32 characters.
- API keys and secrets belong in `backend/.env` locally or secure deployment environment variables, never in source code.

## Technical Architecture

| Layer | Technology |
| --- | --- |
| Client | Flutter / Dart with Material UI |
| Verified platform | Windows desktop debug build |
| API | FastAPI with versioned REST endpoints |
| ORM and validation | SQLAlchemy and Pydantic |
| Local database | SQLite |
| Production database | PostgreSQL 18 through Docker Compose |
| Authentication | JWT, HTTP Bearer, bcrypt/passlib |
| AI provider | Gemini Generate Content API |
| Speech | `speech_to_text`, Windows speech integration, and `flutter_tts` |
| Documents | ReportLab PDF generation and QR verification |
| Imports | OpenPyXL for programme and curriculum spreadsheets |

The local API base address is `http://127.0.0.1:8000/api/v1`. Health checks are available at `/api/v1/health` and `/api/v1/health/database`.

## Live-Data Principle

Admin actions create the records displayed elsewhere:

`Admin master data -> student registration -> academic plan -> operational records -> student/parent dashboards -> risk and interventions`

Examples:

- A hostel allocation appears in that student's Hostel page.
- A transport allocation appears in that student's Transport page.
- Recorded attendance updates student, parent, AI, and risk views.
- Published results update academics, recommendations, AI context, and predictive signals.
- Issued certificates become downloadable and independently verifiable.
- Parent data appears only after an administrator creates the account and link.

When no record exists, the interface displays a clear empty state. It should not substitute another student's information or invented sample values.

## Demo Access

Demonstration credentials are intentionally omitted from the public source.
Create the first administrator with `backend/bootstrap_admin.py`, then register
students and parents through the admin portal. Use unique passwords and keep
local account details out of source control.

## Configuration and Operation

Required local backend settings include:

- `JWT_SECRET_KEY`
- `GEMINI_API_KEY`
- `GEMINI_MODEL`
- `DATABASE_URL` when not using the local runner's SQLite default

Production deployment additionally requires PostgreSQL credentials and allowed origins. The repository includes a Docker Compose configuration for the backend and PostgreSQL database.

## Current Limitations and Production Readiness Notes

- The current risk model is rules-based and explainable; a statistically trained dropout model requires historical labeled university data, validation, bias review, and monitoring.
- Fee payment records exist, but a verified external payment-gateway settlement integration is not currently established.
- Email, SMS, or WhatsApp delivery of credentials and notifications is not established.
- Several governance pages remain unavailable in the admin UI as listed above.
- Local demo URLs inside generated certificate verification links must be changed to the production domain.
- Demo credentials, local secrets, and synthetic records must not be used in production.
- Database migrations, backups, retention policies, observability, rate limiting, and disaster recovery should be finalized before institutional rollout.
- The Windows desktop experience is verified; Android, iOS, and web builds require separate device-level acceptance testing.

## Recommended Next Phases

1. Complete grievance management and close the remaining unavailable admin pages.
2. Add verified email/SMS credential delivery and password-reset workflows.
3. Integrate a production payment gateway with reconciliation and receipt generation.
4. Add configurable university policy, branding, and system settings.
5. Perform role-based security, privacy, load, backup, and recovery testing.
6. Run Android/iOS acceptance testing and accessibility review.
7. Collect governed historical data before replacing the explainable risk engine with a validated predictive model.

## Outcome

UniSphere currently demonstrates a substantial end-to-end Smart University platform rather than a collection of static screens. Its strongest capability is the shared live-data flow: an authorized administrative action becomes visible to the correct student and linked parent, contributes to dashboards and AI answers, and can trigger student-success support. This directly supports digital governance, transparency, ease of administration, and a more coherent campus experience.
