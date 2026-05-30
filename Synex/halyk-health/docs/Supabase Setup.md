# Supabase Setup

Use Supabase as the shared PostgreSQL database for the team. The frontend apps must still call only the backend API; do not connect Flutter or React directly to Supabase.

## 1. Create Project

1. Create a Supabase project.
2. Open `Project Settings -> Database`.
3. Copy the PostgreSQL connection string.
4. Use the direct database URL for Prisma migrations and seed:

```bash
DATABASE_URL="postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres?schema=public&sslmode=require"
```

## 2. Backend Env

Create `/backend/.env`:

```bash
DATABASE_URL="postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres?schema=public&sslmode=require"
JWT_SECRET="replace-with-long-random-secret"
QWEN_PROVIDER="dashscope"
QWEN_API_KEY=""
QWEN_API_URL="https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions"
QWEN_MODEL="qwen3.6-plus"
QWEN_TIMEOUT_MS="20000"
PORT=4000
```

For production, store these variables in the deployment platform, not in Git.

## 3. Apply Schema And Seed

```bash
cd backend
npm install
npm run prisma:generate
npm run prisma:deploy
npm run prisma:seed
```

`prisma:deploy` applies committed migrations from `backend/prisma/migrations`.

`prisma:seed` clears MVP demo data and recreates test users, family patient profiles, clinics, appointments, prescriptions, schedules, matches, and market products. Run it only for demo/dev Supabase projects.

## 4. Local Database Cleanup

Prisma remains in the project because it is the ORM and schema source for Supabase. The old local Docker PostgreSQL database is optional after Supabase works.

After the team confirms the Supabase database has the schema and data:

```bash
docker compose -f docker-compose.local.yml down -v
```

This deletes the local Docker volume only. It does not delete Supabase data.

## 5. Team Workflow

- One shared Supabase project can be used by all developers for demo data.
- Each developer runs backend locally with the same `DATABASE_URL`.
- React doctor panel uses `VITE_API_URL=http://localhost:4000/api`.
- Flutter uses `--dart-define=API_URL=http://localhost:4000/api`.
- Never commit `.env`, Supabase passwords, JWT secrets or Qwen keys.

## 6. Local Qwen3 Through Ollama

For local development without a cloud Qwen key, install/run Ollama and pull Qwen3:

```bash
ollama pull qwen3
ollama serve
```

Use these backend env values:

```bash
QWEN_PROVIDER="ollama"
QWEN_API_KEY=""
QWEN_API_URL="http://127.0.0.1:11434/api/chat"
QWEN_MODEL="qwen3:latest"
QWEN_TIMEOUT_MS="60000"
```

If backend runs inside Docker on macOS, use:

```bash
QWEN_API_URL="http://host.docker.internal:11434/api/chat"
```

## 7. Needed From Project Owner

To perform the actual remote migration, provide:

- Supabase direct PostgreSQL connection string.
- Confirmation whether to run demo seed on Supabase or preserve/import current local data.
- Production `JWT_SECRET`.
- Qwen3 API key, API URL and model name if real remote AI should be enabled.
- Deployed backend URL for Flutter/doctor-panel production builds.
