# EduMarket

> **CSE703102 – E-commerce · Topic 12 – Website for selling online courses and digital content**

EduMarket is a B2C digital-course e-commerce platform built as a university capstone project.

## Architecture

```
Flutter Web  →  REST API  →  Node.js + Express  →  PostgreSQL (Prisma)
```

Payment methods: COD simulation · VNPay Sandbox

## Repository Structure

```
EduMarket/
├── frontend/       Flutter Web application
├── backend/        Node.js + Express + Prisma API
├── database/       Schema exports, migrations, seed scripts
├── docs/           Project documentation
├── testing/        Functional test cases, security checklist
├── PROJECT_CONTEXT.md
└── TODO.md
```

## Quick Start

### Prerequisites

| Tool | Version |
| --- | --- |
| Node.js | ≥ 18 |
| npm | ≥ 9 |
| Flutter | ≥ 3.38 (Web enabled) |
| PostgreSQL | ≥ 14 |

### Backend

```bash
cd backend
cp .env.example .env      # Fill in DATABASE_URL and secrets
npm install
npx prisma migrate dev    # Requires PostgreSQL to be running
npm run dev               # Starts on http://localhost:4000
```

Verify: `GET http://localhost:4000/api/health`

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome     # Starts on http://localhost:3000
```

### Environment Variables

See [`backend/.env.example`](backend/.env.example) for all required variables.

## Development Status

See [TODO.md](TODO.md) for implementation progress.

## License

University assignment – not for commercial distribution.
