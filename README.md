# UniSphere Smart University Digital Campus

UniSphere is a Flutter and FastAPI prototype for connected university
administration, student services, and parent access. The demonstrated client is
Windows desktop. The backend owns the data shown to each authenticated account.

## What works in the prototype

- Admin registration, academic planning, enrolment, attendance, exams, and results
- Student-specific academics, timetable, fees, hostel, transport, and certificates
- Staff-managed parent accounts linked to selected students
- Certificate request, issue, PDF download, verification, and revocation
- Student helpdesk, notifications, early warnings, and staff interventions
- English/Hindi assistant for campus records and general questions; Gemini is optional

The risk score is rule-based, not a trained dropout prediction. Fee invoices and
recorded payments do not constitute a live payment gateway. Catalogue and
curriculum imports in this repository are demonstration data until the university
approves them.

## Local setup (Windows)

Install Flutter with Windows desktop support and Python 3.11 or 3.12. From the
project root:

```powershell
flutter pub get
cd backend
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Edit `backend/.env`: set a new random `JWT_SECRET_KEY` with at least 32
characters. Add a `GEMINI_API_KEY` only if you want provider-backed general
answers. Never commit `.env` or reuse demonstration credentials in deployment.

In the backend directory, prepare the empty database and create the first admin:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe bootstrap_admin.py
.\.venv\Scripts\python.exe run_local_server.py
```

In another terminal at the project root:

```powershell
flutter run -d windows
```

The local API is `http://127.0.0.1:8000/api/v1`; check
`/api/v1/health/database`. The client defaults to this address. Other devices
need their own API address via `--dart-define=API_BASE_URL=...` and separate
acceptance testing.

The first admin can register students and parents through the UI. A fresh clone
contains no populated student database or demo passwords. Programme and
curriculum import scripts are available under `backend/`; use reviewed source
files and validate the results before assigning academic plans.

## Structure

- `lib/`, `test/`: Flutter application and tests
- `backend/app/`, `backend/alembic/`, `backend/tests/`: API, migrations, tests
- `backend/deployment/`: production deployment notes
- `output/pdf/`, `output/evaluator_presentation/`: evaluator documents

The production Compose example uses PostgreSQL. It is a starting point, not a
claim of high availability or institutional security certification. Deployment
needs HTTPS, secret management, backups and restore tests, authorization review,
and institution-approved records.
