# Fluently — Backend

Rails 8 API-only backend for Fluently, a multi-teacher SaaS languages learning platform for teachers and small schools.

---

## Tech Stack

- **Ruby** 3.3.10
- **Rails** 8.1
- **PostgreSQL** 16
- **Devise + devise-jwt** — authentication via JWT
- **Active Storage + S3** — file uploads
- **Stripe** — subscription billing
- **LiveKit** — real-time video lessons
- **OpenAI** — AI homework generation
- **Mailjet** — transactional email
- **Puma** — web server

---

## Getting Started

### Prerequisites

- Docker & Docker Compose

### Run with Docker (recommended)

```bash
cd backend
docker compose up
```

The API will be available at `http://localhost:3001`.

### Run locally (requires PostgreSQL)

```bash
bundle install
bundle exec rails db:create db:migrate db:seed
bundle exec rails server
```

---

## Environment Variables

Copy `.env.example` to `.env` and fill in the values:

| Variable                | Description                                             |
| ----------------------- | ------------------------------------------------------- |
| `FRONTEND_URL`          | Frontend origin for CORS (e.g. `http://localhost:5174`) |
| `DEVISE_JWT_SECRET_KEY` | Secret key for signing JWTs                             |
| `MAILER_FROM`           | From address for transactional emails                   |
| `MAILJET_API_KEY`       | Mailjet API key                                         |
| `MAILJET_SECRET_KEY`    | Mailjet secret key                                      |
| `AWS_ACCESS_KEY_ID`     | AWS credentials for S3                                  |
| `AWS_SECRET_ACCESS_KEY` | AWS credentials for S3                                  |
| `AWS_REGION`            | S3 bucket region                                        |
| `AWS_S3_BUCKET`         | S3 bucket name                                          |
| `STRIPE_SECRET_KEY`     | Stripe secret key                                       |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook signing secret                           |
| `LIVEKIT_URL`           | LiveKit server URL                                      |
| `LIVEKIT_API_KEY`       | LiveKit API key                                         |
| `LIVEKIT_API_SECRET`    | LiveKit API secret                                      |
| `OPENAI_API_KEY`        | OpenAI API key                                          |
| `OPEN_API_MODEL`        | OpenAI model (e.g. `gpt-4.1-mini`)                     |

Rails credentials can also be used instead of env vars — edit with:

```bash
cd backend && EDITOR=nano bundle exec rails credentials:edit
```

---

## Database

```bash
# Create and migrate
bundle exec rails db:create db:migrate

# Seed
bundle exec rails db:seed

# Docker
docker compose exec web bundle exec rails db:migrate
```

---

## Testing

Tests use Rails' built-in Minitest and live in `test/`.

```bash
# Run all tests
docker compose exec web bundle exec rails test

# Run a specific file
docker compose exec web bundle exec rails test test/controllers/api/lessons_controller_test.rb
```

---

## Linting & Security

```bash
# RuboCop (auto-fix)
bundle exec rubocop -A

# Brakeman (security scan)
bundle exec brakeman

# Bundler Audit (dependency vulnerabilities)
bundle exec bundler-audit
```

---

## CI

GitHub Actions runs on every push to `main` and on pull requests:

- **scan_ruby** — Brakeman + Bundler Audit
- **lint** — RuboCop
- **test** — Full Minitest suite against a PostgreSQL service container

---

## Key Architecture Notes

- **Auth**: Devise + devise-jwt. The JWT is expected in the `Authorization: Bearer <token>` header. Roles (`admin`, `student`) live on the `users` table.
- **Multi-tenancy**: Students belong to an admin via `admin_id` on the `users` table. All queries are scoped through `current_api_user`.
- **File uploads**: Active Storage with S3. The frontend uses direct uploads via `POST /api/rails/active_storage/direct_uploads` and passes back the `signed_id`.
- **Stripe webhooks**: Handled at `POST /api/stripe/webhooks`. Set the webhook secret in env vars.
- **Filtering**: Models support a `Filterable` pattern — `Model.filtering(params)` dispatches to `filter_by_<field>` scopes.
