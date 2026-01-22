# AroundTally Ticketing Platform

AroundTally is a Flutter + Supabase stack that links three delivery surfaces:

1. **Agent App** (desktop/web/mobile) used by admins, support leads, support engineers, accountants, and sales.
2. **Customer Portal** (Flutter web) that lets B2B clients raise and track tickets, update company profiles, and review AMC/billing details.
3. **Tally Prime Plugin** (TDL) that injects ticket creation directly into customers’ Tally installations with API-key authentication.

This README documents the end-to-end workflows, Supabase schema, and environment setup so you can replicate or extend the system from scratch.

---

## 1. High-Level Architecture

```
Tally Plugin  ──► Supabase REST/RPC ──► Tickets, Customers, Audit Log
Customer Portal ─┘                      ▲
                                         │ realtime subscriptions, RPCs
Agent App ───────────────────────────────┘
```

- **Flutter clients** share UI foundations (FlexColorScheme, Google Fonts, GoRouter) but target different users.
- **Supabase** hosts PostgreSQL tables, row-level policies, RPC functions, storage buckets, and realtime channels.
- **Riverpod + Clean Architecture** organize presentation/data layers; each feature has domain entities, use cases, providers, and widgets.

---

## 2. Core Workflows

### 2.1 Agent App (role-driven)

| Role            | Landing Experience | Key Modules | Typical Actions |
|-----------------|--------------------|-------------|-----------------|
| Admin           | Global KPIs, SLA health, shortcuts to Settings and Reports | Tickets, Customers, Billing, Productivity | Review KPIs, trigger reports, adjust settings |
| Support Head    | Unclaimed queues split by AMC vs. Normal customers | Ticket triage, assignment tools | Assign owners, escalate SLA breaches |
| Support Engineer| Personal workload summary, quick actions to claim/raise tickets | My Tickets, Unclaimed, Ticket detail view | Work tickets, log comments, record service reports |
| Accountant      | Billing queue (Pending vs. Completed), AMC visibility | Billing dashboard, Ticket filters | Raise invoices, mark collections, audit billing history |
| Sales/Moderator | Productivity widgets, deals pipeline | Deals board, Wiki/Notifications | Track deals, share announcements |

Dashboards subscribe to Supabase streams so SLA cards and queues update immediately when new tickets or comments arrive.@docs/APP_FEATURES.md#1-75

### 2.2 Customer Portal

- **Authentication**: Company admins or teammates sign in/claim their account. Metadata keeps `customer_id`, `company_name`, and role in sync between Supabase Auth and the `customers` table.@lib/website/services/supabase_service.dart#54-140
- **Shell**: Persistent sidebar (Dashboard, My Tickets, My Profile) plus a responsive header that exposes context buttons like “Create Ticket.”
- **Flows**:
  1. *Dashboard*: Shows six most recent tickets, quick links (Open/Closed), and a hero Create Ticket CTA.
  2. *Ticket Lifecycle*: Raise, comment, reopen, filter by status—scoped to the signed-in customer.
  3. *Profile*: Update company and contact info; changes immediately reflect in agent views to keep CRM data accurate.@docs/APP_FEATURES.md#38-60

### 2.3 Tally Plugin

- Side-loaded `.tdl` file exposes “Support Tickets” inside Tally Prime.
- When a ticket is submitted, the plugin posts to `rest/v1/rpc/create_ticket` with a company-specific `x-tally-api-key` header, which Supabase verifies before inserting the ticket and audit log.@docs/SETUP.md#11-34 @supabase/migrations/20250524000000_initial_schema.sql#98-254

### 2.4 Ticket Lifecycle Summary

1. Customer or Tally plugin raises a ticket (New).
2. Supabase `tickets` row is created, audit log updated.
3. Agent dashboards show the new ticket in unclaimed/AMC lists via realtime.
4. Support assigns ticket, works it, logs service reports/comments.
5. Accountant updates status to `BillRaised` / `BillProcessed`.
6. Customer portal mirrors changes, enabling reopening or closing.

---

## 3. Supabase Data Model & RPC Surface

| Table            | Purpose | Key Columns / Notes |
|------------------|---------|---------------------|
| `customers`      | Master companies + AMC metadata | `api_key` authenticates Tally plugin requests; contact fields feed both clients.@supabase/migrations/20250524000000_initial_schema.sql#11-34 |
| `agents`         | Custom auth for the Agent App | Plaintext `username`/`password` (MVP) plus `role`. Used by `login_agent` RPC.@supabase/migrations/20250524000000_initial_schema.sql#26-35 |
| `tickets`        | Core ticket records | Enforces priority/status enums, tracks `assigned_to` (agent UUID), SLA timestamps.@supabase/migrations/20250524000000_initial_schema.sql#36-54 |
| `ticket_comments`| Conversation history | `author`, `body`, `internal` flag for private notes.@supabase/migrations/20250524000000_initial_schema.sql#55-64 |
| `service_reports`| Digital job cards | Records resolution details, time spent, signatures.@supabase/migrations/20250524000000_initial_schema.sql#65-78 |
| `audit_log`      | Traceability across flows | Stores structured payloads for ticket events.@supabase/migrations/20250524000000_initial_schema.sql#80-88 |

**Row-Level Security (MVP)**: Policies currently allow `anon` to access all tables; tighten for production by splitting roles or adding Supabase Auth JWT claims.@supabase/migrations/20250524000000_initial_schema.sql#90-149

### RPC Functions

| Function            | Description |
|---------------------|-------------|
| `login_agent(p_username, p_password)` | Validates agent credentials and returns `{ success, agent }` for the Flutter app. Plaintext passwords for MVP; swap with hashed storage before go-live.@supabase/migrations/20250524000000_initial_schema.sql#151-183 |
| `create_ticket(...)`| Accepts ticket payloads from Tally, enforces API-key lookup, idempotent on `(customer_id, client_ticket_uuid)`, and writes audit logs.@supabase/migrations/20250524000000_initial_schema.sql#188-254 |
| `reset_customer_password_by_secret_email` | Enables portal password resets via secret email tokens.@lib/website/services/supabase_service.dart#348-365 |

### Seed Data

Run `supabase/migrations/20251124000000_update_schema_and_seed.sql` after the base migration to load:

- Agents: `admin/admin123`, `moderator/mod123`, `accountant/acc123`, `support/supp123`.
- Customers: `Acme Corp (acme-api-key)`, `Globex Inc (globex-api-key)`.
- Sample tickets spanning New/Open/In Progress/BillRaised to populate dashboards.@supabase/migrations/20251124000000_update_schema_and_seed.sql#1-47

---

## 4. Repository & Feature Structure

```
lib/
├── core/            # design system, theme, logging, errors
├── features/
│   ├── auth/        # login page + AuthNotifier (Supabase RPC) @lib/features/auth/presentation/providers/auth_provider.dart
│   ├── tickets/     # domain entities, repositories, providers
│   ├── dashboard/   # role-based dashboards + widgets
│   ├── customers/   # customer list/forms
│   ├── productivity/# deals board, notifications
│   └── website/     # customer portal pages & Supabase service helpers
└── main.dart        # GoRouter setup + theme bootstrap
```

Each feature follows Clean Architecture layering: `domain` (entities, repos), `data` (supabase services), and `presentation` (providers, widgets).

---

## 5. Environment Setup & Replication Guide

### 5.1 Supabase
1. Create a new Supabase project.
2. In SQL Editor run `supabase/migrations/20250524000000_initial_schema.sql`.
3. Run `supabase/migrations/20251124000000_update_schema_and_seed.sql` (or `supabase/seed.sql` if you only need the earliest seed).@docs/SETUP.md#1-10
4. Capture your Supabase **URL** and **anon/service keys** for Flutter config.

### 5.2 Flutter Apps

```bash
flutter pub get

# Desktop/Web for agents
flutter run -d windows   # or chrome

# Customer portal (web)
flutter run -d chrome --target lib/website/main_portal.dart   # example entrypoint if split
```

Configure Supabase credentials via `lib/core/config/supabase_config.dart` or environment file, depending on how you externalize secrets.

### 5.3 Tally Plugin

1. Open Tally Prime → **Help → TDL & Add-On → Manage Local TDLs**.
2. Add the path to `tally/ticket_plugin.tdl`.
3. Update the plugin with the customer’s `api_key` before deployment so RPC calls are authorized.@docs/SETUP.md#11-23

### 5.4 Testing the Flow

1. Use the portal or Tally to raise a ticket (requires `customers.api_key`).
2. Log into the Agent app with one of the seeded accounts, e.g., `support / supp123`.
3. Verify realtime updates and ticket status transitions.
4. Optional: exercise billing statuses (`BillRaised`, `BillProcessed`) to test accountant dashboards.

---

## 6. Rebuilding or Forking the Platform

1. **Clone repo & install deps**.
2. **Provision Supabase** with the migrations above. Adjust RLS/role policies before production.
3. **Update branding** via `lib/core/design_system/theme` and `lib/core/design_system/components`.
4. **Customize Seeds**: Insert your own agents/customers/tickets using the migration template.
5. **Update Environments**: Ensure Flutter clients point at your Supabase URL/key. For multi-env builds, wire `flutter_dotenv` or a CI secrets store.
6. **Tally rollout**: Recompile the `.tdl` plugin with each customer’s API key and supply deployment instructions.

---

## 7. Credentials & Quick Reference

| Surface      | Default Accounts | Notes |
|--------------|------------------|-------|
| Agent App    | `admin/admin123`, `support/supp123`, `accountant/acc123`, `moderator/mod123` | Defined in migration seed script; add more via Supabase SQL or UI.@supabase/migrations/20251124000000_update_schema_and_seed.sql#6-13 |
| Customer Portal | `Acme Corp`, `Globex Inc` seeded with `contact_email` and company passwords in tickets/table | Portal auth uses Supabase email/password + metadata sync.@supabase/migrations/20251124000000_update_schema_and_seed.sql#15-47 @lib/website/services/supabase_service.dart#368-465 |
| Tally Plugin | `api_key` per customer (`acme-api-key`, `globex-api-key`) | Keep keys secret; rotate via Supabase dashboard when onboarding new clients. |

---

## 8. Future Hardening Checklist

- Replace plaintext agent passwords with hashed storage and Supabase Auth or custom JWT issuance.
- Tighten RLS policies so `anon` cannot access all tables; use service roles for the Tally plugin.
- Add CI to run `flutter test` and `flutter analyze`.
- Extend README with screenshots and deep links once UI stabilizes.

With this document you can provision Supabase, seed initial data, configure Tally, and run both Flutter surfaces to produce a working replica of the AroundTally support stack. Happy building!
