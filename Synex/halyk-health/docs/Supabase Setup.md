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
QWEN_API_KEY=""
QWEN_API_URL=""
PORT=4000
```

For production, store these variables in the deployment platform, not in Git.

## 3. Apply Schema And Seed

```bash
cd backend
npm install
npm run prisma:generate
npm run prisma:push
npm run prisma:seed
```

`prisma:seed` clears MVP demo data and recreates test users, clinics, appointments, prescriptions and market products. Run it only for demo/dev Supabase projects.

## 4. Team Workflow

- One shared Supabase project can be used by all developers for demo data.
- Each developer runs backend locally with the same `DATABASE_URL`.
- React doctor panel uses `VITE_API_URL=http://localhost:4000/api`.
- Flutter uses `--dart-define=API_URL=http://localhost:4000/api`.
- Never commit `.env`, Supabase passwords, JWT secrets or Qwen keys.
