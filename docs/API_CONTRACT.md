# Digi5S Backend — Complete API Contract Inventory

Source: `/Users/meghal/Documents/digi5s_backend-production` (Hapi.js 21, Knex/PostgreSQL, read-only survey).
Production base URL used throughout the docs/scripts: `https://api.seichoconsulting.com`

---

## 1. Server basics

From `index.js` (the real entrypoint; `src/core/hapi-core.js` is dead legacy code — it uses ESM `import`, port 3000, basePath `/v1`, title "Jeevan API Documentation", and is never required by `index.js`).

| Item | Value |
|---|---|
| Port | `process.env.PORT` else **8000** (`.env` sets `PORT=8000`) |
| Host | `process.env.HOST` else `0.0.0.0` |
| Route prefix | **none** — all paths are absolute from `/` (no `/v1`, no `/api` except the 5 `/api/audit/*` routes) |
| CORS | `routes.cors = { origin: ['*'], credentials: true }` — fully open |
| Swagger | `hapi-swagger` at `/documentation`, securityDefinition `jwt` = apiKey in header named `Authorization` |
| Auth strategy | single strategy named **`jwt`** (`hapi-auth-jwt2`), registered as `server.auth.default('jwt')` |
| JWT secret | `process.env.JWT_SECRET` else hardcoded fallback `q5w4e*/s1^3d1QSDcz21` |
| Algorithm | HS256 |
| Header / scheme | Header **`Authorization`**. hapi-auth-jwt2 accepts `Authorization: Bearer <token>` (also raw token, and `access_token` query/cookie). Swagger declares it as a plain apiKey header. |
| Migrations | run automatically on boot from `./src/core/migrations` |
| Extra services started | `schedulerService` (subscription expiry cron), `organisationPauseService` |

### Token generation (`src/core/hapi/auth.js` + `src/core/token.js`)

Tokens are signed with **`jwt-simple`** using the hardcoded secret `"q5w4e*/s1^3d1QSDcz21"` (note: `generateToken` does **not** read `JWT_SECRET`, so if `JWT_SECRET` is set in env, verification in `index.js` will fail unless it equals that literal — in the deployed `.env` a `JWT_SECRET` is present, so this is a live mismatch risk).

Payload:
```json
{
  "id":    "<Users.id uuid>",
  "orgId": "<Users.orgId uuid>",
  "sid":   "<aguid session uuid>",
  "exp":   <unix seconds>,
  "scope": ["ORGANISATION-ADMIN"]        // array of role strings
}
```

* No `role` claim as such — the role lives inside `scope` (a JSON array).
* Expiry: `exp = (Date.now() + ttl) / 1000`. `ttl` comes from `GeneralParams.SESSION_EXPIRY_TIME` (seeded value `3000000000` ms ≈ 34.7 days), default 24 h if the row is missing. When `rememberMe` is truthy the ttl becomes `365*30*7*24*60*60*1000` ms (effectively forever). `/users/login` always passes `rememberMe = true`.
* The generated token is also persisted to `Users.authToken`.

### Validation function (`index.js`)

```js
credentials = {
  userId: decoded.id,
  orgId:  decoded.orgId,
  scope:  decoded.scope
}
```
It returns `isValid: true` for **any** decodable token — it does not check the DB, expiry beyond the library check, or user status.

**There is no refresh-token endpoint.** Logout clears `Users.authToken` server-side but the JWT itself stays valid until `exp`.

### Practical note for the mobile app

Almost every route sets `auth: false`. Only these require the `jwt` strategy:

* `POST /auth/logout`
* `GET /dashboard/status/` (also `scope: ['ADMIN']` — a role that does not exist in the seed data; effectively unusable, and the handler references undefined stores → 500)
* `GET /api/audit/questions`, `POST /api/audit/session`, `POST /api/audit/session/{sessionId}/response`, `POST /api/audit/session/{sessionId}/complete`, `GET /api/audit/session/{sessionId}`
* Routes in `invoices.js` and `enquiries.js` have **no** `auth` key at all → they inherit `server.auth.default('jwt')`, so they **do** require a token.

Everything else is publicly reachable. Authorization, where it exists, is done inside handlers by looking up a `userId`/`adminUserId` passed in the payload or query.

---

## 2. Route inventory (grouped by file)

Response envelope varies by file. Two shapes exist:
* **A**: `{ statusCode, status, error, message, data }`
* **B**: `{ statusCode, message, data }` (or `{ statusCode, message, error }` on failure)

Note: HTTP status is almost always **200** even for logical failures — the real code is in the body's `statusCode`. Exceptions: `freeTrial.js`, `paidSubscription.js`, `adminDashboard.js` and `subscriptionExpiry.js` call `.code(n)`.

`src/api/routes/signup.js` and `src/api/routes/customer.js` export **no routes** (signup.js exports helper functions; customer.js exports an empty array — index.js logs an error for signup.js and moves on). `hospitalDashboard.js` exports `[]`.

---

### `auth.js`

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/customer/Signup` | no | `fullName?`, `phoneNumber` (number, req), `fcmToken?` (number) | Creates a CUSTOMER user if new, generates a 6-digit OTP into `UserValidation`, envelope A with `message: "Login OTP send successfully"`. **SMS sending is commented out — OTP is never delivered.** |
| POST | `/customer/login` | no | `phoneNumber` (string, req) | Generates + stores OTP for an existing approved user. Returns A `message: "OTP send successfully"`. Rejects if `approved != true`. |
| PATCH | `/users/fcmToken` | no | `userId` (req), `fcmToken` (string, req) | Updates `Users.fcmToken`; returns A with the updated user row array. |
| POST | `/admin/login` | no | `email`, `password` | bcrypt-compares against `Users.password`; on success returns A `data: [ <full Users row incl. password hash & authToken> ]`. **Does not issue a fresh token.** |
| POST | `/admin/signup` | no | `email`, `password`, `scope` (array) | Creates a `Users` row with `signupType:"Admin"` and an `authToken` = `jwt.encode(email+scope)` (not the standard payload). Returns A with the inserted row. |
| POST | `/auth/password-reset/otp` | no | `email` (req) | Emails a 6-digit OTP (10 min expiry) via `forgot-password/forgotpassword.pug`. A, `data: null`. |
| POST | `/auth/password-reset` | no | `email`, `password`, `otp` | Verifies OTP (1=ok, 2=expired, 3=invalid), bcrypt-hashes and saves the new password, emails confirmation. A, `data: null`. |
| POST | `/auth/forgot-password` | no | `email` (valid email, req) | Generates 32-byte hex token, stores `passwordResetToken` + `passwordResetExpires` (**1 hour**), emails a link `https://api.seichoconsulting.com/reset-password.html?token=…`. A, `data: null`. |
| POST | `/auth/reset-password` | no | `token` (req), `password` (min 6, req) | Looks up user by reset token, checks expiry, sets new password, clears token, emails confirmation. A, `data: null`. |
| POST | `/auth/logout` | **jwt** | — | Sets `Users.authToken = null` for `request.auth.credentials.userId`. A, `data: null`. |
| POST | `/admin/logout` | no | — | No-op success response. A, `data: null`. |

---

### `emailVerification.js` (used by the org-registration wizard)

| Method | Path | Auth | Payload | Returns |
|---|---|---|---|---|
| POST | `/email-verification/send` | no | `email` (email, req), `adminName` (req), `orgName` (req) | Generates a 6-digit code with **30 min** expiry into `UserValidation.emailVerificationCode/ExpTime`, emails `auth/email-verification.pug`. A, `data: null`. Requires the user to already exist (404 otherwise). |
| POST | `/email-verification/verify` | no | `email`, `verificationCode` | On success sets `isEmailValid = true`, clears the code. A, `data: { email, verified: true }`. |
| POST | `/email-verification/resend` | no | `email` | New code + email. A, `data: null`. |

---

### `organisationUsers.js` — **this is where the app login lives**

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/users/organisation-admin` | no | `orgId` (guid), `fullName`, `email`, `password`, `phoneNumber`, `designation`, `signupType:'LOCAL'`, `role` ∈ `ORGANISATION-ADMIN\|ZONE-MEMBER\|ZONE-LEADER\|VIEWER` | Creates the org subscription (FREE→+14 days, else +1 year) from the org's booking, creates the user, creates `UserValidation`, emails credentials. Returns `{ statusCode: 201, message: 'Organization Admin created successfully' }` (no `data`). |
| POST | `/users/organisation-members` | no | **multipart/form-data**: `orgId`,`zoneId`,`roleId` (all guid, req), `fullName`,`email`,`password`,`phoneNumber`,`designation`, `signupType:'LOCAL'`, `role` ∈ `ZONE-MEMBER\|ZONE-LEADER\|VIEWER`, `file` (optional PNG/JPG/JPEG profile photo) | Validates the org has an active `DONE` subscription and enforces `adminUserLimit`/`membersLimit` for non-FREE plans; uploads photo to S3 `Profile-photo/`; emails credentials. A, `statusCode: 201`, `data: null`. |
| POST | **`/users/login`** | no | `email` (email, req), `password` (req), `rememberMe?` (bool — ignored; always `true`) | See §3. |
| POST | `/users/org/zone` | no | `orgId`, `zoneId` (both req strings) | A, `data`: array of full `Users` rows for that org+zone. |
| GET | `/users/organisation-members/{id}` | no | `id` = **user** id (guid) | A, `data`: single `Users` row (`usersStore.getByUserId`) — despite the name, this is one user, not a list. |
| GET | `/users/org/{id}` | no | `id` = org id (guid) | A, `data`: array of `{ fullName, photo, role, zoneName, id }` — only approved users that have a zone assigned. |
| PUT | `/users/organisation-members/inactive/{id}` | no | params `id` (guid); payload `approved` (bool, req) | Sets `Users.approved`. B-ish `{ statusCode, message, data: [updatedUser] }`. |
| POST | `/users/{id}/reset-password` | no | params `id` (guid); no payload | Generates a 12-char secure password, hashes it, emails it via `subscriptions/paid-subscription-credentials.pug`, and **returns the plaintext**: `{ statusCode: 200, message, data: { newPassword } }`. |

---

### `users.js`

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| GET | `/usersBy/{scope}` | no | `scope` string (e.g. `ZONE-LEADER`) | A, `data`: all `Users` rows whose `scope` JSON array contains that value. |
| POST | `/users/add` | no | `roleId?`, `orgId?`, `fullName` (req), `email?`, `phoneNumber?`, `password?`, `scope` ∈ `SUPER-ADMIN\|ADMIN\|USER\|ORGANISATION-ADMIN\|ZONE-MEMBER\|ZONE-LEADER\|VIEWER` (req), `signupType` ∈ `LOCAL\|GOOGLE\|PHONE` (default LOCAL) | Website admin user creation, auto-approved. A, `data`: inserted `Users` rows. |
| DELETE | `/users/{id}` | no | `id` string | `{ statusCode, status, message, data: [deletedId] }`. |
| GET | `/users/{id}` | no | `id` string | `{ statusCode, status, message, data: <Users row> }` or 404-in-body. |

---

### `organisation.js`

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/organisations` | no | `name` (req), `addressLine1?`, `addressLine2?`, `contactNo?`, `email` (req), `gstNo?`, `pancardNo?` | Creates the org **and** an `ORGANISATION-ADMIN` user with a generated 12-char password; emails welcome + notifies `digi5sapp@gmail.com`. B, `data: { organisation, adminCredentials: { email, password }, adminUserId }`. |
| GET | `/organisations` | no | — | B, `data`: all `Organisation` rows. |
| GET | `/organisations/{id}` | no | guid | B, `data`: one org. |
| GET | `/organisations/members/{id}` | no | guid = orgId | B, `data`: all `Users` rows for the org. |
| PUT | `/organisations/{id}` | no | any of `name, addressLine1, addressLine2, contactNo, email, gstNo, pancardNo` | B, `data`: updated rows. |
| PUT | `/organisations/status/{id}` | no | `approved` (bool, req) | Approve/unapprove org. B. |
| PUT | `/organisations/{id}/pause` | no | `expiresAt?` (ISO date) | Sets `isPaused=true, pausedAt, pauseExpiresAt` **and** deactivates the active org subscription. B, `data: { organisation, pauseDetails: { expiresAt } }`. |
| PUT | `/organisations/{id}/unpause` | no | `extendSubscription` (bool, default true) | Clears pause fields, reactivates subscription and extends `endDate` by the pause duration. B, `data: { organisation, subscriptionExtension: { message, originalEndDate, newEndDate, extensionDuration, extensionDays } \| null }`. |
| GET | `/organisations/paused` | no | — | B, `data`: paused orgs. **Route-ordering hazard**: `/organisations/{id}` is registered first and `id` requires a guid, so Hapi's specificity rules still route `/organisations/paused` correctly, but a non-guid id returns a Joi 400. |
| GET | `/organisations/with-pause-info` | no | — | B, `data`: all orgs + computed `isPauseExpired`. |
| DELETE | `/organisations/{id}` | no | guid | B `{ statusCode: 200, message }`. |

---

### `zone.js`

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/zones` | no | `zoneName` (req), `orgId` (guid, req) | B 201, `data`: inserted `Zone` rows. `createdBy` forced to `"super-admin"`. |
| GET | `/zones` | no | — | B, all zones. |
| GET | `/zones/{id}` | no | guid | B, one zone. |
| GET | `/zones/organisation/{id}` | no | guid = orgId | B, `data`: array of zones for the org. |
| PUT | `/zones/{id}` | no | `zoneName?`, `orgId?`, `modifiedBy?` | B, updated rows. |
| DELETE | `/zones/{id}` | no | guid | B; returns `409` in body with a human-readable list when FK constraints (redtaglist / users / tasks / zonescore / manual) block deletion. |

---

### `zoneScore.js` (manual monthly zone score, distinct from audit scores)

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/zone-scores` | no | `orgId` (guid), `zoneId` (guid), `zoneScore` (number), `monthAndYear` (string, e.g. `2025-03`) | Idempotent per (org, zone, month) — returns 201 with a "already inserted" message if present. B. |
| GET | `/zone-scores` | no | — | B, all rows. |
| GET | `/zone-scores/{id}` | no | guid | B, one row. |
| POST | `/zone-scores/org` | no | `zoneId` (guid), `orgId` (guid) | Last 6 months of scores, sorted ascending by `monthAndYear`. B, `data`: `[{ id, orgId, zoneId, zoneScore, monthAndYear, createdAt, … }]`. |
| PUT | `/zone-scores/{id}` | no | `zoneScore?`, `monthAndYear?`, `modifiedBy?` | B. |
| DELETE | `/zone-scores/{id}` | no | guid | B. |

---

### `tasks.js`

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/tasks` | no | **multipart**: `taskName` (req), `description?`, `file?` (png/jpg/jpeg/pdf), `zoneMemberId` (guid, req), `orgId` (guid, req), `zoneId` (guid, req), `targetDate?` (date), `createdBy` (guid, req — the assigner's user id) | Uploads file to S3 `Tasks/`, sets `status: "PENDING"`, seeds `activity` with one entry, emails the assignee (`tasks/new-task.pug`). A, `data`: inserted `Tasks` rows. |
| GET | `/tasks` | no | — | B, all tasks. |
| GET | `/tasks/{id}` | no | guid | B, one task. |
| GET | `/tasks/org/{id}` | no | guid = orgId | B, tasks for the org where `approved = true`. |
| POST | `/tasks/detailsByUserId` | no | `orgId` (guid), `userId` (guid) | B, tasks where `zoneMemberId = userId`. **This is the mobile "my tasks" endpoint.** |
| PUT | `/tasks/{id}` | no | **multipart**: `taskName?`, `description?`, `file?`, `zoneMemberId?`, `zoneId` (guid, req), `targetDate?`, `modifiedBy?` | Resets status to PENDING and **replaces** `activity` with a single entry. B/A hybrid, `data`: updated rows. |
| DELETE | `/tasks/{id}` | **inherits jwt** (no `auth` key on this one route) | guid | B `{ statusCode, message }`. |
| PUT | `/tasks/status/{id}` | no | `status` ∈ `WORK-IN-PROGRESS\|VERIFY\|REJECTED` (req), `activity` (string, req) | Appends to `activity` JSON, updates status. B, `data`: updated rows. |
| PUT | `/tasks/status/completed/{id}` | no | **multipart**: `status:'COMPLETED'` (req), `activity` (string, req), `file?` (png/jpg/jpeg/pdf) | Uploads proof to S3 `Manual/` (note: wrong folder), appends **two** activity entries, and sets the task to **`PENDING_APPROVAL`** (not COMPLETED), emails the zone leader. B, `data`: updated rows. |
| PUT | `/tasks/inactive/{id}` | no | `status` (bool, req) → written to `approved` | Soft delete. B. |
| POST | `/tasks/request-approval/{id}` | no | **multipart**, payload is `Joi.any()`: `activity` (required at runtime), `remarks?`, `photos` (one or many PNG/JPG/JPEG) | Uploads each photo to S3 `TaskApprovals/`, appends an activity entry with `path` = JSON array of `{path}`, sets status `PENDING_APPROVAL`, emails zone leader. B, `data`: updated rows. |
| POST | `/tasks/approve/{id}` | no | `action` ∈ `APPROVE\|REJECT` (req), `remarks` (string, req) | Requires current status `PENDING_APPROVAL`; sets `COMPLETED` or `REJECTED`, appends activity, emails the zone member. B, `data`: updated rows. |

**Task status machine**: `PENDING` → `WORK-IN-PROGRESS` / `VERIFY` / `REJECTED` (via `/tasks/status/{id}`) → `PENDING_APPROVAL` (via `/tasks/status/completed/{id}` or `/tasks/request-approval/{id}`) → `COMPLETED` / `REJECTED` (via `/tasks/approve/{id}`).

---

### `redTagList.js`

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/redtags` | no | **multipart**: `orgId?`, `zoneId?`, `redTagBy?` (all plain strings), `description?`, `file?` (png/jpg/jpeg/pdf), `createdBy` (guid, **required**) | Uploads to S3 `Red-tag-list/`; works with or without a file (`path: null`). Sets `status: "PENDING"`, seeds `activity`. A, `statusCode: 201`, `data`: inserted rows. |
| GET | `/redtags` | no | — | B, `data`: all red tags joined with `Users.email as email` and `Zone.zoneName`. Fields: `id, orgId, zoneId, description, path, status, activity, approved, createdAt, createdBy, email, zoneName`. |
| GET | `/redtags/{id}` | no | guid | B, one raw `RedTagList` row. |
| GET | `/redtags/org/{id}` | no | guid = orgId | B, joined list for the org (same field set as above). |
| PUT | `/redtags/{id}` | no | `description?`, `path?`, `status?`, `modifiedBy?` | B, updated rows. |
| PUT | `/redtags/status/{id}` | no | `status` ∈ `COMPLETED\|VERIFY\|REJECTED` (req), `activity` (string, req), `actionBy` (email string, req) | Appends activity, updates status. B. |
| DELETE | `/redtags/{id}` | no | guid | B. |
| POST | `/redtags/approve/{id}` | no | `action` ∈ `APPROVE\|REJECT` (req), `approvalRemarks` (string, req), `adminUserId` (guid, req) | **Enforces org-admin role in-handler** (`SUPER-ADMIN`, `ORGANISATION-ADMIN`, `ORG-ADMIN`; non-super-admins must match `orgId`). Requires current status `PENDING`. Sets status `APPROVED`/`REJECTED` and `approved` bool. B, `data`: updated row. 403 in body if unauthorized. |
| PUT | `/redtags/reset/{id}` | no | guid | Test helper: resets to `PENDING`, `approved:false`. B. |
| GET | `/redtags/pending/{orgId}` | no | params `orgId` (guid); **query `adminUserId` (guid, required)** | Org-admin-gated list of `PENDING` red tags. B, `data`: joined list. |

**Red tag status machine**: `PENDING` → `APPROVED`/`REJECTED` (org admin, `/redtags/approve/{id}`). A parallel legacy path `/redtags/status/{id}` sets `COMPLETED`/`VERIFY`/`REJECTED`.

---

### `auditSheets.js`

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| GET | `/audit-sheets` | no | **query**: `orgId` (guid, req), `zoneId?` (guid), `userId?` (guid) | If both `userId` and `zoneId` given, requires the user to be a `ZONE-LEADER` of that zone (403 otherwise). B, `data`: `AuditSheets` rows. |
| POST | `/audit-sheets` | no | `name` (req), `orgId` (guid, req), `month` (string, req), `totalQuestions` (int ≥1, req), `maxScore` (int ≥1, req), `userId` (guid, req — permission check), `questions`: `[{ questionId, question }]` min 1 | Requires `userId` to be `SUPER-ADMIN`/`ORGANISATION-ADMIN`/`ORG-ADMIN`. Auto-assigns `questionId` uuids where missing. B 201, `data`: inserted rows. |
| PUT | `/audit-sheets/{id}` | no | same payload as POST (all required) | Same admin gate. B, `data`: updated rows. |
| DELETE | `/audit-sheets/{id}` | no | guid | B. |
| POST | `/audit-sheets/{sheetId}/submit` | no | `submittedBy` (guid, req), `naQuestions` (num), `applicableQuestions` (num), `totalScore` (num), `auditScorePercentage` (num), `auditDate` (ISO string), `auditZone` (guid), `userZone` (guid), `responses: [{ questionId, score (number \| "NA"), remarks?, photos?: [{ file: <data:image/xxx;base64,…>, description? }] }]` | Requires `submittedBy` to be a `ZONE-LEADER` of `userZone`. Validates every question is answered. Uploads base64 photos to S3 `AuditPhotos/`. B 201, `data` echoes the submitted payload. |
| GET | `/audit-sheets/{sheetId}/submissions` | no | params `sheetId`; **query `userId?`** (if given, must be admin or zone leader of the submission's zone) | B, `data: { auditSheet: { id, name, orgId, month, totalQuestions, maxScore }, submissions: [{ submissionId, submittedAt, submittedBy, totalScore, percentage, responses: [{ questionId, question, score, remarks, photos }] }] }`. |
| GET | `/audit-sheets/zone/{zoneId}/statistics` | no | params `zoneId` (guid) | Month-wise aggregation. B, `data: { zoneId, statistics: [{ year, month, monthName, totalSubmissions, averageScore, averagePercentage, totalScore, maxPossibleScore, submissions: [{ submissionId, submittedAt, submittedBy, submittedByName, totalScore, percentage, auditSheetId }] }] }`. |
| DELETE | `/audit-sheets/{sheetId}/submissions/{submissionId}` | no | params both guid; **query `userId` (guid, required)** — must be zone leader of the submission's `auditZone` | B `{ statusCode, message }`. |

---

### `auditScoreView.js` (public read-only audit score screens)

| Method | Path | Auth | Params | Returns |
|---|---|---|---|---|
| GET | `/audit-scores/zones` | no | — | B, `data`: `[{ id, zoneName, orgId }]` for **all** zones system-wide. |
| GET | `/audit-scores/zones/org/{orgId}` | no | `orgId` guid | B, `data`: `[{ id, zoneName, orgId }]` for that org. |
| GET | `/audit-scores/zone/{zoneId}/last-6-months` | no | params `zoneId` guid; **query `orgId` (guid, required)** | B, `data: { zone: { id, zoneName, orgId }, scores: [{ monthAndYear:"YYYY-MM", monthName:"March 2025", score: <int\|null>, hasData, auditCount, audits: [{ id, percentage, storedPercentage, totalScore, applicableQuestions, auditDate, auditSheetName, month }], createdAt }] (always 6 entries), summary: { totalMonthsWithData, averageScore, latestScore } }`. Percentage is recomputed as `round(totalScore / applicableQuestions * 100)`. |
| GET | `/audit-scores/org/{orgId}/summary` | no | `orgId` guid | B, `data: { orgId, totalZones, zonesWithData, zones: [{ id, zoneName, totalDataPoints, averageScore, latestScore, hasData }] }`. |

---

### `audit.js` (legacy integer-PK audit engine — **the only fully JWT-protected group**)

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| GET | `/api/audit/questions` | **jwt** | — | Raw array of `audit_questions` rows where `is_active = true`: `{ id, question_text, max_score, category, is_active, created_at, updated_at }`. |
| POST | `/api/audit/session` | **jwt** | `location` (req), `audit_date` (date, req) | Inserts `audit_sessions` with `zone_leader_id = request.auth.credentials.id` (**bug: credentials expose `userId`, not `id` → this is `undefined`**). Returns `{ id }` 201. |
| POST | `/api/audit/session/{sessionId}/response` | **jwt** | params `sessionId` (number); payload `question_id` (num, req), `score` (num, req), `remarks?`, `attachments?: [{ file_url (req), file_type? }]` | `{ id }` 201. |
| POST | `/api/audit/session/{sessionId}/complete` | **jwt** | params `sessionId`; payload `remarks?` | Sums scores, sets `status:'completed'`. `{ total_score }`. |
| GET | `/api/audit/session/{sessionId}` | **jwt** | `sessionId` number | `{ session, responses, attachments }`. |

---

### `manual.js`

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/manual` | no | **multipart**: `orgId` (string, req), `name` (req), `createdBy?` (guid), `file?` (png/jpg/jpeg/pdf) | S3 folder `Manual/`. A, `data`: inserted `Manual` rows. 404 if the org doesn't exist. |
| GET | `/manual` | no | — | B, all manuals. |
| GET | `/manual/org/{id}` | no | guid = orgId | B, manuals for the org. |
| GET | `/manual/{id}` | no | guid | B, one manual. |
| PUT | `/manual/{id}` | no | `materialType?`, `path?`, `approved?` (note: **no `name`**, and `materialType` isn't a Manual column) | B. |
| DELETE | `/manual/{id}` | no | guid | B. |
| GET | `/upload/assets/{path*}` | no | path | Static directory listing/serving from `./upload` (legacy local-disk uploads). |

---

### `trainingMaterial.js`

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/training-material` | no | **multipart**: `orgId` (req), `materialType` (req), `name` (req), `createdBy?` (guid), `file?` (png/jpg/jpeg/pdf) | Uploaded to S3 folder **`News/`** (not a dedicated folder). A, `data`: inserted rows. |
| GET | `/training-material` | no | — | B, all. |
| GET | `/training-material/{id}` | no | guid | B, one. |
| GET | `/training-material/org/{id}` | no | guid = orgId | B, list for org. |
| GET | `/training-material/debug/available-data` | no | — | B, `data: { organisations: [{id,name}], zones: [{id,zoneName,orgId}] }`. **Broken — `zoneStore` is not imported in this file → 500.** |
| PUT | `/training-material/{id}` | no | **multipart**: `orgId?`, `materialType?`, `name?`, `file?`, `approved?` | B/A, `data`: updated rows. |
| DELETE | `/training-material/{id}` | no | guid | A, `data: null`. |

---

### `bestPractices.js`

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/best-practices` | no | **multipart**: `orgId` (guid, req), `title` (req), `zone` (string, req — a free-text zone name, not a FK), `description?`, `file?` (png/jpg/jpeg/**pdf**/**mp4**) | S3 folder `BestPractices/`. B 201, `data`: inserted rows. |
| GET | `/best-practices` | no | — | B, all. |
| GET | `/best-practices/{id}` | no | guid | B, one. |
| GET | `/best-practices/org/{id}` | no | guid = orgId | B, list. |
| PUT | `/best-practices/{id}` | no | **multipart**: `title?`, `zone?`, `description?`, `file?` | B. |
| DELETE | `/best-practices/{id}` | no | guid | B. |

---

### `news.js`

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/news` | no | **multipart**: `orgId` (guid, req), `title` (req), `file?` (png/jpg/jpeg/pdf/mp4), `description?` | S3 folder `News/`. **If no file is sent the handler returns `undefined` → 500**; a file is effectively mandatory. B 201, `data`: inserted rows. |
| GET | `/news` | no | — | B, all news. |
| GET | `/news/{id}` | no | guid | B, one. |
| GET | `/news/org/{id}` | no | guid = orgId | B, list. |
| PUT | `/news/{id}` | no | `orgId?`, `title?`, `path?`, `description?`, `modifiedBy?` (JSON, not multipart) | B. |
| DELETE | `/news/{id}` | no | guid | B. |

---

### `flashNews.js` (ticker-style announcements; no file, no title, no priority after the Dec-2024 migration)

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/flash-news` | no | `orgId` (guid, req), `content` (string, req), `expiryDate` (date, req) | `createdBy` from JWT if present else `"system"`. B 201, `data`: inserted rows. |
| GET | `/flash-news` | no | — | B, all. |
| GET | `/flash-news/{id}` | no | guid | B, one (404-in-body if missing). |
| GET | `/flash-news/org/{id}` | no | guid = orgId | B, list for org. |
| PUT | `/flash-news/{id}` | no | `orgId?`, `content?`, `expiryDate?`, `modifiedBy?` | B, `data`: single updated row. |
| DELETE | `/flash-news/{id}` | no | guid | B. |

---

### `dashboard.js`

| Method | Path | Auth | Payload | Returns |
|---|---|---|---|---|
| GET | `/dashboard/status/` | **jwt + scope `['ADMIN']`** | — | Legacy ambulance/hospital dashboard. **Dead code — references undefined stores; always 500.** |
| POST | `/dashboard/organisation` | no | `orgId` (guid, req), `zoneId` (guid, req) | **The main mobile home screen payload.** B, `data: { redTagList: { getAllRedTagListData: [...], pendingRedTagListCount, completedRedTagListCount, verifyRedTagListCount }, tasklist: { getAllTasksData: [...], pendingTaskListCount, completedTaskListCount, workInProgressTaskListCount, verifyTasksListCount, pendingApprovalTaskListCount, pendingApprovalTaskList: [...] } }`. |
| POST | `/dashboard/super-admin` | no | none (validation commented out) | B, `data: { freeSubscriptionCount, paidSubscriptionCount }`. |
| POST | `/dashboard/red-tag-list/download` | no | `orgId` (guid), `zoneId` (guid) | Generates a PDF table of red tags. A, `data`: **base64 PDF string**. |
| POST | `/dashboard/task-list/download` | no | `orgId` (guid), `zoneId` (guid) | Same for tasks. A, `data`: base64 PDF string. |
| GET | `/generate-invoice` | no | — | Demo/testing route, returns a base64 PDF from hardcoded sample data. |
| GET | `/generate-invoice/new` | no | — | Demo/testing route, returns a base64 PDF built with pdfkit. |

---

### `adminDashboard.js` (super-admin web console)

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| GET | `/admin/dashboard/overview` | no (`// Temporarily disable auth for testing`) | — | A, `data: { statistics: { totalSubscriptions, pendingApprovals, approvedSubscriptions, failedPayments }, revenue: { totalRevenue, totalPayments, averageRevenue }, recentActivity: [{ bookingId, orgName, adminName, subscriptionName, paymentAmount, paymentId, status, createdAt, approvedAt }], planDistribution: [{ SubscriptionName, count }] }`. |
| GET | `/admin/paid-subscriptions/pending` | no | **query**: `page` (default 1), `limit` (default 10, max 100), `search` (default `''`) | Orgs with `approved = false` and non-null `contactNo`. A, `data: { subscriptions: [{ orgId, orgName, adminName, adminEmail, adminPhone, subscriptionName, membersLimit, pricePerYear, startDate, endDate, createdAt, timeSinceCreation, status:'PENDING_APPROVAL', approved }], pagination: { currentPage, totalPages, totalItems, itemsPerPage } }`. (Note: it selects `Organisation.orgName`/`adminName`, columns that don't exist → always `'N/A'`; search on those columns would error.) |
| GET | `/admin/paid-subscriptions/approved` | no | query `page`, `limit`, `search` (not Joi-validated) | A, `data: { subscriptions: [{ bookingId, orgId, orgName, adminName, adminEmail, subscriptionName, membersLimit, pricePerYear, paymentId, paymentAmount, approvedAt, timeSinceApproval, status:'ACTIVE' }], pagination }`. |
| POST | `/admin/paid-subscriptions/{bookingId}/reject` | no | params `bookingId`; payload `reason` (req), `notes?` | Sets booking `status:'REJECTED'` (also writes a `notes` column that doesn't exist in the schema), emails the applicant. A, `data: { bookingId, rejectionReason, rejectedAt }`. |
| GET | `/admin/paid-subscriptions/analytics` | no | query `period` (days, default 30) | A, `data: { period, subscriptionTrends: [{ date, count, revenue }], conversionRate, totalPayments, approvedPayments, topPerformingPlans }`. |
| GET | `/admin/organisations/pause-stats` | no | — | A, `data: { statistics, pausedOrganisations: [{ id, name, email, pausedAt, pauseExpiresAt, isPauseExpired, timeUntilExpiry, status }] }`. |
| POST | `/admin/organisations/process-expired-pauses` | no | — | Runs the pause service now. A, `data: { message, updatedStatistics }`. |
| GET | `/admin/organisations/{id}/pause-history` | no | guid | A, `data: { id, name, email, currentStatus, isPaused, pausedAt, pauseExpiresAt, modifiedAt, modifiedBy }`. |
| POST | `/admin/paid-subscriptions/{orgId}/approve` | no | params `orgId` (guid) | Approves the org **and** its `ORG-ADMIN`/`ORGANISATION-ADMIN` user, **regenerates the admin's password**, and emails the credentials. A, `data: { orgId, orgName, approved, approvedAt, emailSent, userApproved }`. |

---

### `freeTrial.js`

| Method | Path | Auth | Payload | Returns |
|---|---|---|---|---|
| POST | `/free-trial/start` | no | `orgName` (req), `unitName?` (allows `''`), `adminName` (req), `adminPhone` (req), `adminEmail` (email, req), `numEmployees?` (int) | Stores a `FreeTrialPending` row with a 6-digit code (**30 min** expiry), emails `auth/organization-verification.pug`. Real HTTP codes: 400 if org/user exists, **429** if a live pending code already exists. A. |
| POST | `/free-trial/verify` | no | `adminEmail` (email, req), `verificationCode` (req) | Creates `Organisation` (`approved: true`), a `Booking` (`status:'DONE'`) against the `FREE` subscription, an `OrganisationSubscription` valid **14 days** with `isSubscriptionActive: true`, and an `ORG-ADMIN` user with a generated password, then emails credentials (`auth/organization-setup.pug`) and notifies `digi5sapp@gmail.com`. A, `message: 'Organization created. Check your email for credentials.'` — **the password is only delivered by email, not in the response.** |

---

### `paidSubscription.js` (Razorpay)

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/paid-subscription/pricing` | no | `orgName`, `unitName`, `adminName`, `adminPhone`, `adminEmail` (email), `employeeCount` (int ≥1) — all required | Picks the cheapest plan with `membersLimit >= employeeCount` and `pricePerYear > 0`. A, `data: { subscription: { id, name, description, membersLimit, adminUserLimit, pricePerYear, onboardingPrice }, employeeCount, totalAmount, breakdown: { annualPrice, onboardingFee, total } }`. 400 if the email/phone already exists. |
| POST | `/paid-subscription/register` | no | identical payload | Identical response (this endpoint is a duplicate of `/pricing`; the doc calls it "step 1"). |
| POST | `/paid-subscription/payment/initiate` | no | same 6 fields **+ `subscriptionId` (guid, req)** | Rate-limited (5 attempts / 15 min per `email_phone`). Creates a `Booking` (`status:'PENDING'`, `registrationData` JSON, no `orgId` yet) and a **real Razorpay order** (`amount` in paise, `currency:'INR'`, `receipt: bookingId`). A, `data: { bookingId, subscription {…}, totalAmount, razorpayOrderId, razorpayOrderData, razorpayKeyId }`. |
| **PUT** | `/paid-subscription/payment/complete` | no | `bookingId` (req), `razorpayPaymentId` (req), `razorpayOrderId` (req), `razorpaySignature` (req), `amount` (positive number, req), `tax` (number ≥0, req) | Verifies `HMAC-SHA256(orderId\|paymentId, RAZORPAY_KEY_SECRET)`, validates the amount matches the plan, then creates `Organisation` (`approved: false`), `Users` (role `ORG-ADMIN`, `approved: false`, generated password), `OrganisationSubscription` (1 year, `isSubscriptionActive: false`), updates the booking to `DONE` with `transcationDetails`, and emails `digi5sapp@gmail.com`. A, `data: { orgId, adminUserId, subscriptionId, invoice, paymentId }` (`invoice` is currently the literal string `"base64_invoice_placeholder"` — `createInvoice` is a stub in this file). **Credentials are NOT emailed here — only after admin approval.** |
| POST | `/paid-subscription/webhook` | no | Raw Razorpay webhook body; header `x-razorpay-signature` | Handles `payment.captured` → booking `DONE`, `payment.failed` → booking `FAILED`. Returns `{ received: true }` or `{ error }` with a real 400/500. |
| GET | `/paid-subscription/payment/status/{bookingId}` | no | `bookingId` string | A, `data: { bookingId, status, createdAt, modifiedAt }`. |

Razorpay env keys: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET` (webhook verification actually uses `RAZORPAY_KEY_SECRET`, not the webhook secret — a real bug).

---

### `checkout.js` (older booking/renewal flow for **existing** orgs)

| Method | Path | Auth | Payload | Returns |
|---|---|---|---|---|
| POST | `/customer/booking/checkout/initiate` | no | `orgId` (guid, req), `subscriptionId` (guid, req) | Creates a `Booking` with a `short-uuid` `bookingId` and `status:'PENDING'`. A, `data`: inserted booking rows. |
| PUT | `/customer/booking/checkout` | no | `bookingId` (req), `razorpayPaymentId` (req), `orgId` (guid, req), `amount` (num, req), `tax` (num, req) | Builds `transcationDetails` (`totalPaidPrice = amount + tax*0.18`), generates a real PDF invoice (base64 stored in `transcationDetails.invoicePDF`), sets booking `DONE`, notifies `digi5sapp@gmail.com`. **No signature verification.** A, `data`: updated booking. Does **not** create/extend the org subscription. |
| PUT | `/customer/booking/checkout-renew` | no | same payload | Same as above **plus**: marks all previous `DONE` bookings for the org `EXPIRE`, deactivates the current org subscription, creates a new `OrganisationSubscription` for **+1 year** with `isSubscriptionActive: true`, and calls `subscriptionExpiryService.handleSubscriptionRenewal`. A, `data`: updated booking. |

---

### `booking.js`

| Method | Path | Auth | Payload | Returns |
|---|---|---|---|---|
| POST | `/booking/initiate` | no | `rideDetails` (nested array of ride objects), `addressId` (req) | **Dead legacy ambulance code** — inserts columns (`userId`, `rideDetails`, `addressId`) that don't exist on `Booking`; always errors. |

---

### `subscription.js` (plan catalogue)

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/subscriptions` | no | `membersLimit?` (int), `onboardingPrice` (num, req), `pricePerYear` (num, req) | Forces `SubscriptionName:"diGi5S subscription"`. B 201. |
| GET | `/subscriptions` | no | — | B, `data`: plans with non-null `onboardingPrice`, ordered by `onboardingPrice`, with `pricePerYear`/`onboardingPrice` coerced to numbers. Fields: `id, SubscriptionName, description, adminUserLimit, membersLimit, pricePerYear, onboardingPrice, approved, createdAt, …`. |
| GET | `/subscriptions/{id}` | no | guid | B, one plan. |
| PUT | `/subscriptions/{id}` | no | `membersLimit?`, `onboardingPice?` (typo — will fail at DB level), `pricePerYear?`, `modifiedBy?` | B. |
| DELETE | `/subscriptions/{id}` | no | guid | B. |

---

### `organisationSubscription.js`

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/organisation-subscriptions` | no | `orgId` (guid), `subscriptionId` (guid), `startDate` (ISO), `endDate` (ISO, > startDate), `isSubscriptionActive` (bool) — all required | B 201. |
| GET | `/organisation-subscriptions` | no | — | B, `data`: `[{ id, orgId, subscriptionId, startDate, endDate, isSubscriptionActive, orgName, orgEmail, SubscriptionName, pricePerYear, isFree, daysLeft }]`. |
| GET | `/organisation-subscriptions/{id}` | no | guid | B, one raw row. |
| GET | `/organisation-subscriptions/org/{id}` | no | guid = orgId | **The endpoint the app should call to know plan status.** Joins `Subscription` + `Booking` (only `status = 'DONE'`). B, `data`: `[{ organisationSubscriptionId, orgId, startDate, endDate, isSubscriptionActive, subscriptionId, adminUserLimit, membersLimit, pricePerYear, bookingId, transcationDetails }]`. |
| PUT | `/organisation-subscriptions/{id}` | no | any of the create fields + `modifiedBy?` | B. |
| DELETE | `/organisation-subscriptions/{id}` | no | guid | B. |

---

### `subscriptionExpiry.js` (ops/cron control — not for the mobile app)

| Method | Path | Auth | Returns |
|---|---|---|---|
| POST | `/subscription-expiry/trigger-notifications` | no | A, `data`: result of the notification pass. |
| POST | `/subscription-expiry/trigger-deactivation` | no | A, `data: { deactivatedCount }`. |
| GET | `/subscription-expiry/status` | no | A, `data: { scheduler: { initialized, tasks }, statistics }`. |
| POST | `/subscription-expiry/initialize` | no | A, `data: { initialized }`. |
| POST | `/subscription-expiry/stop` | no | A, `data: { initialized }`. |
| GET | `/subscription-expiry/subscriptions` | no | A, `data: { subscriptions: [{ …sub, daysLeft, isExpired, needsReminder }], total, expiringSoon, expired }`. |
| GET | `/subscription-expiry/renewal-tracking` | no | A, `data`: tracking map. |
| POST | `/subscription-expiry/reset-renewal-tracking` | no | A, `data: null`. |

Reminder intervals: **30, 15, 7, 3, 1 days** before expiry; cron at 09:00 (notifications), 10:00 (deactivation), 11:00 (stats).

---

### `invoices.js` — **all four routes inherit the default `jwt` strategy (no `auth` key)**

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/invoices` | **jwt** | `organisationSubscriptionId` (guid), `issueDate` (ISO), `amount` (num), `status` (string), `createdBy?` | B 201. |
| GET | `/invoices` | **jwt** | — | B, all `Invoices`. |
| GET | `/invoices/{id}` | **jwt** | guid | B, one. |
| PUT | `/invoices/{id}` | **jwt** | any of the above optional + `modifiedBy?` | B. |
| DELETE | `/invoices/{id}` | **jwt** | guid | B. |

---

### `enquiries.js` — **also inherits `jwt` (no `auth` key)** — note the public website contact form would need a token, which is almost certainly unintended.

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/enquiries` | **jwt** | `name` (req), `email` (email, req), `phoneNumber` (req), `createdBy?` | B 201. |
| GET | `/enquiries` | **jwt** | — | B, all. |
| GET | `/enquiries/{id}` | **jwt** | guid | B, one. |
| PUT | `/enquiries/{id}` | **jwt** | `name?`, `email?`, `phoneNumber?`, `modifiedBy?` | B. |
| DELETE | `/enquiries/{id}` | **jwt** | guid | B. |

---

### `roles.js`

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| POST | `/roles` | no | `roleName` (req) | B 201. |
| GET | `/roles` | no | — | B, `data`: `[{ id, roleName, approved, createdAt, modifiedAt, createdBy, modifiedBy }]`. Needed to obtain `roleId` for `/users/organisation-members`. |
| GET | `/roles/{id}` | no | guid | B, one. |
| PUT | `/roles/{id}` | no | `roleName` (req), `modifiedBy?` | B. |
| DELETE | `/roles/{id}` | no | guid | B. |

---

### `userPermissions.js` — **non-functional**: it queries a `UserPermissions` table that has no migration, and the module schema is leftover ambulance/hospital/driver domain.

| Method | Path | Auth | Payload / params | Returns |
|---|---|---|---|---|
| GET | `/userPermissions` | no | — | A, `data`: all `UserPermissions` rows. |
| GET | `/userPermissions/{scope}` | no | `scope` string | `{ statusCode, status, error, data }`. |
| POST | `/userPermissions/add` | no | `userScope` (req), `hospitalModule/ambulanceModule/driverModule: { create, edit, view, delete }` | **Handler is nested inside `config` (a structural bug) → Hapi will reject / 500.** |
| PATCH | `/userPermissions/edit` | no | same, all booleans required | `{ statusCode, status, error, message, data }`. |

---

### `developer.js`

| Method | Path | Auth | Payload | Returns |
|---|---|---|---|---|
| POST | `/developer/test-email` | no | `email` (req), `intent` ∈ `signup\|login\|task` (req) | Sends a sample `tasks/new-task.pug` email. B 201, `data`: nodemailer info. |

---

### `customer.js`, `hospitalDashboard.js`, `signup.js`

No routes registered. `signup.js` exports `{ Signup, signupHospital, signupCustomer, SignupOtp, signupOrgMembers }` (note: `src/api/routes/signup.js` is an unused duplicate of `src/core/auth/signup.js`; only the `core/auth` copy is required by the route files).

---

### Routes defined inline in `index.js`

| Method | Path | Auth | Returns |
|---|---|---|---|
| GET | `/ping` | no | `{ message: 'pong' }` — health check. |
| GET | `/routes` | no | `{ message, total, routes: [{ method, path, description }] }` — live route table dump. |
| GET | `/reset-password.html` | no | Static `public/reset-password.html` (the reset-link landing page). |
| GET | `/index.html` | no | Static `public/index.html`. |
| GET | `/documentation`, `/swagger.json` | no | hapi-swagger UI + spec. |


---

## 3. Auth flows in detail

### 3.1 App / web user login — `POST /users/login` (the only real login)

Request:
```json
{ "email": "admin@acme.com", "password": "Abc123!x", "rememberMe": true }
```

Success (HTTP 200):
```json
{
  "statusCode": 200,
  "status": true,
  "error": "",
  "message": "user Login Successfully",
  "data": {
    "id": "uuid",
    "roleId": "uuid|null",
    "orgId": "uuid|null",
    "zoneId": "uuid|null",
    "email": "admin@acme.com",
    "phoneNumber": "9876543210",
    "photo": "https://digi5s-app-uploads.s3.ap-south-1.amazonaws.com/Profile-photo/....jpg|null",
    "fullName": "Acme Admin",
    "role": "ORGANISATION-ADMIN",
    "scope": ["ORGANISATION-ADMIN"],
    "designation": "Admin",
    "authToken": "<JWT>",
    "firebaseToken": null,
    "signupType": "LOCAL",
    "approved": true,
    "disabled": false,
    "fcmToken": null,
    "passwordResetToken": null,
    "passwordResetExpires": null,
    "notifications": 0
  }
}
```

Important details:
* The email is lower-cased before lookup; lookup itself is case-insensitive.
* **The JWT is returned inside `data.authToken`** (the freshly generated token — `login()` returns `updatedUser[0]` from `updateUserToken(...).returning('*')`). It is *also* set as a cookie-ish state via `.state('access_token', authToken)`, but since no `server.state('access_token', …)` is registered, Hapi throws on unknown state in strict mode — in practice the app must read `data.authToken`.
* Deleted before responding: `password`, `passwordResetKey`, `createdAt`, `modifiedAt`, `modifiedBy`. **`authToken` is deliberately kept.**
* Failure modes (all HTTP 200 with body `statusCode`):
  * `404` / `"User not found"` — email not registered.
  * `405` / `"Your account is not active."` — `disabled = true`.
  * `405` / `"Your account verification is pending."` — `approved = false`.
  * `401` / `"Invalid email or password"` — bcrypt mismatch (thrown from `authenticateUser`).
* `POST /admin/login` is a **separate, weaker** website-admin path: it returns the full `Users` row array including the bcrypt hash and does not mint a token.

### 3.2 Signup

There is **no self-serve app signup**. Accounts are created by one of four server-side paths:

1. **Free trial (website)** — `POST /free-trial/start` → email code → `POST /free-trial/verify`. Creates org + `ORG-ADMIN` user, 14-day FREE subscription. Password emailed.
2. **Paid subscription (website/app)** — `POST /paid-subscription/pricing|register` → `POST /paid-subscription/payment/initiate` → Razorpay checkout → `PUT /paid-subscription/payment/complete`. Creates org + `ORG-ADMIN` user **unapproved**; credentials emailed only after `POST /admin/paid-subscriptions/{orgId}/approve`.
3. **Super-admin creates an org** — `POST /organisations` (returns the generated admin password in the response body).
4. **Org admin creates members** — `POST /users/organisation-admin` and `POST /users/organisation-members` (password chosen by the caller and emailed to the member).

`POST /admin/signup` and `POST /users/add` also exist for the back-office.

### 3.3 OTP

Two independent OTP mechanisms, both writing to the `UserValidation` table:

* **Phone OTP** (`otp` / `otpExpTime`, 6 digits, **10 min**): issued by `POST /customer/Signup` and `POST /customer/login`. **There is no verify endpoint** — `PATCH /customer/otp/verify` is entirely commented out, and the SMS gateway (textlocal) call is commented out too. This flow is dead; do not build the app on it.
* **Password-reset OTP** (same `otp` column, 10 min): `POST /auth/password-reset/otp` → `POST /auth/password-reset`. This one is live and email-delivered.
* **Email verification code** (`emailVerificationCode` / `emailVerificationExpTime`, 6 digits, **30 min**): `POST /email-verification/send|verify|resend`.
* **Free-trial verification code** (`FreeTrialPending.verificationCode`, 6 digits, **30 min**).

### 3.4 Forgot / reset password

Two parallel flows:

| Flow | Endpoints | Delivery | Token TTL |
|---|---|---|---|
| OTP-based (app-friendly) | `POST /auth/password-reset/otp` → `POST /auth/password-reset` (`email`, `password`, `otp`) | 6-digit code by email | 10 min |
| Link-based (web) | `POST /auth/forgot-password` → user clicks `https://api.seichoconsulting.com/reset-password.html?token=…` → page calls `POST /auth/reset-password` (`token`, `password` min 6) | 32-byte hex link | 1 hour |

Admin-initiated reset: `POST /users/{id}/reset-password` generates and emails a new password and returns the plaintext in `data.newPassword`.

### 3.5 Logout

* `POST /auth/logout` — **requires the JWT**, nulls `Users.authToken`. The JWT stays cryptographically valid until `exp` (no blacklist), so the client must also delete its stored token.
* `POST /admin/logout` — public no-op for the web console.

### 3.6 Token refresh

**None.** There is no refresh endpoint, no refresh token, and no re-issue path. With `rememberMe` always true on `/users/login`, the token TTL is effectively unbounded — the app should simply store `data.authToken` and re-login on 401.

### 3.7 App users vs website users

| Flow | Consumer |
|---|---|
| `/users/login`, `/auth/logout`, `/auth/password-reset*`, `/tasks/*`, `/redtags/*`, `/audit-sheets/*`, `/dashboard/organisation`, `/flash-news`, `/news`, `/manual`, `/training-material`, `/best-practices`, `/zone-scores/org`, `/audit-scores/*` | **Mobile app** |
| `/organisations/*`, `/users/add`, `/usersBy/{scope}`, `/admin/*`, `/subscriptions` CRUD, `/roles`, `/invoices`, `/enquiries`, `/subscription-expiry/*`, `/dashboard/super-admin`, `/developer/test-email` | **Website / admin console** |
| `/free-trial/*`, `/paid-subscription/*`, `/email-verification/*`, `/customer/booking/checkout*` | **Public marketing site + app onboarding** |
| `/customer/Signup`, `/customer/login`, `/booking/initiate`, `/api/audit/*`, `/userPermissions/*`, `/dashboard/status/` | **Legacy / dead** (do not port) |

---

## 4. Role model

### Seeded roles — `src/core/seeddata/Roles.js` (fixed UUIDs, `Roles` table)

| roleName | id |
|---|---|
| `SUPER-ADMIN` | `523e4567-e89b-12d3-a456-426614174200` |
| `ORGANISATION-ADMIN` | `623e4567-e89b-12d3-a456-426614174201` |
| `ZONE-MEMBER` | `723e4567-e89b-12d3-a456-426614174202` |
| `ZONE-LEADER` | `823e4567-e89b-12d3-a456-426614174203` |
| `VIEWER` | `823e4567-e89b-12d3-a456-426614174204` |

Seeded super-admin user: `digi5sapp@gmail.com` / `9099948547`, id `123e4567-e89b-12d3-a456-426614174000`, `role: "SUPER-ADMIN"`, `scope: ["SUPER-ADMIN"]`.

### The `ORG-ADMIN` vs `ORGANISATION-ADMIN` split (important)

Users created by **free trial** and **paid subscription** get `role: 'ORG-ADMIN'` and `scope: ['ORG-ADMIN']`, which is **not** in the `Roles` seed table. Users created by `POST /organisations` or `/users/organisation-admin` get `ORGANISATION-ADMIN`. Handler-side permission checks therefore accept all three spellings:

```js
user.role === 'SUPER-ADMIN' || user.role === 'ORGANISATION-ADMIN' || user.role === 'ORG-ADMIN'
```
(`redTagList.js:isOrgAdmin`, `auditSheets.js:isAdmin`). Also note `organisationSubscriptionStore.getAdminAndZoneMemberCounts` only counts `role = 'ORG-ADMIN'` as admins, so `ORGANISATION-ADMIN` users are invisible to the seat-limit check. The Flutter app must treat `ORG-ADMIN` and `ORGANISATION-ADMIN` as the same role.

### How permissions are actually enforced

There is **no middleware-level RBAC**. Three mechanisms exist:

1. **Hapi scope on routes** — used exactly once, on `GET /dashboard/status/` with `scope: ['ADMIN']` (a role that doesn't exist).
2. **In-handler role lookups** — the pattern used by the live features. The caller passes a user id in the payload/query and the handler loads that user and checks `role`:
   * `redTagList.js` — `isOrgAdmin(adminUserId, orgId)` gates `POST /redtags/approve/{id}` and `GET /redtags/pending/{orgId}?adminUserId=…`.
   * `auditSheets.js` — `isAdmin(userId)` gates create/update of audit sheets; `isZoneLeader(userId, zoneId)` (requires `role === 'ZONE-LEADER'` **and** `Users.zoneId === zoneId`) gates submit, listing by zone, and submission delete.
   * `organisationUsers.js` — `isSubscriptionAllowed` enforces seat limits, not roles.
   This is trivially spoofable (any client can send any `adminUserId`), so treat it as a UX affordance, not a security boundary.
3. **`userPermissions` routes/store** — a per-scope permission matrix (`UserPermissions` table with `userScope`, `hospitalModule`, `ambulanceModule`, `driverModule` JSON columns). **There is no migration creating this table**, the modules are leftovers from the ambulance project, and `POST /userPermissions/add` has its handler nested inside `config` so it cannot work. **This system is not in use** — ignore it when rebuilding the app.

Practical role → capability map (derived from handlers):

| Role | Can |
|---|---|
| `SUPER-ADMIN` | Everything, cross-org (org CRUD, approvals, subscriptions, red-tag approval anywhere) |
| `ORGANISATION-ADMIN` / `ORG-ADMIN` | Create members/zones, create & edit audit sheets, approve/reject red tags for own org, view org dashboard |
| `ZONE-LEADER` | Create/assign tasks, approve/reject tasks (`/tasks/approve`), submit audits for own zone, delete own-zone submissions |
| `ZONE-MEMBER` | View assigned tasks, mark complete + request approval, raise red tags |
| `VIEWER` | Read-only (not enforced anywhere server-side — must be enforced in the app) |

---

## 5. Subscription & payment flows

### Plan catalogue (`Subscription` table)

Seeded by `20241201_insert_subscription_pricing.js` — 14 tiers, from `Digi5s Basic - 30 Members` (adminUserLimit 3, membersLimit 30, ₹2 000/yr, ₹10 000 onboarding) up to `Digi5s Unlimited` (adminUserLimit 50, membersLimit 9999, ₹15 000/yr, ₹75 000 onboarding), plus intermediate Standard/Professional/Business/Enterprise/Corporate/Premium/Elite/Ultimate/Platinum/Diamond/Titanium/Master tiers. A separate **`FREE`** plan row is expected to exist (looked up by name in `freeTrial.js`; `/free-trial/verify` returns a 500 "FREE subscription not found" if it is missing).

`totalAmount = pricePerYear + onboardingPrice`. GST is handled inconsistently — `checkout.js` computes `totalPaidPrice = amount + tax * 0.18` (i.e. 18 % of the tax, not of the amount).

### A. Free trial (14 days)

```
POST /free-trial/start   { orgName, unitName, adminName, adminPhone, adminEmail, numEmployees }
     → 200 "Verification code sent to your email."   (429 if a code is already live)
POST /free-trial/verify  { adminEmail, verificationCode }
     → creates Organisation(approved:true) + Booking(status:DONE, FREE plan)
       + OrganisationSubscription(+14 days, isSubscriptionActive:true)
       + Users(role:'ORG-ADMIN', approved:true, generated password emailed)
     → 200 "Organization created. Check your email for credentials."
POST /users/login        { email: adminEmail, password: <from email> }
```

### B. Paid subscription with Razorpay (new organisation)

```
1. POST /paid-subscription/pricing        { orgName, unitName, adminName, adminPhone, adminEmail, employeeCount }
      ← { subscription: { id, name, membersLimit, adminUserLimit, pricePerYear, onboardingPrice },
          totalAmount, breakdown }
2. POST /paid-subscription/payment/initiate  { …same 6 fields…, subscriptionId }
      ← { bookingId, totalAmount, razorpayOrderId, razorpayKeyId, razorpayOrderData }
3. (client) open Razorpay checkout with razorpayKeyId + razorpayOrderId, amount in paise, INR
      ← razorpay_payment_id, razorpay_order_id, razorpay_signature
4. PUT  /paid-subscription/payment/complete  { bookingId, razorpayPaymentId, razorpayOrderId,
                                               razorpaySignature, amount, tax }
      ← { orgId, adminUserId, subscriptionId, invoice, paymentId }
      (server verifies HMAC, creates Org approved:false, Users approved:false,
       OrgSubscription +1yr isSubscriptionActive:false, Booking → DONE,
       emails digi5sapp@gmail.com)
5. (poll) GET /paid-subscription/payment/status/{bookingId}  ← { bookingId, status, createdAt, modifiedAt }
6. (super admin, out of band) POST /admin/paid-subscriptions/{orgId}/approve
      → org.approved = true, user.approved = true, NEW password generated + emailed
7. POST /users/login   with the emailed credentials
```
Razorpay also POSTs `/paid-subscription/webhook` (`payment.captured` → `DONE`, `payment.failed` → `FAILED`).

Rejection path: `POST /admin/paid-subscriptions/{bookingId}/reject { reason, notes? }`.

### C. Renewal for an **existing** organisation (`checkout.js`)

```
1. GET  /subscriptions                                    ← plan list with prices
2. POST /customer/booking/checkout/initiate  { orgId, subscriptionId }   ← booking (status PENDING)
3. (client) Razorpay checkout                              (order created client-side; no server order here)
4. PUT  /customer/booking/checkout-renew  { bookingId, razorpayPaymentId, orgId, amount, tax }
      → expires old bookings, deactivates old subscription,
        creates OrganisationSubscription +1 year active, generates PDF invoice (base64),
        triggers renewal confirmation email
5. GET  /organisation-subscriptions/org/{orgId}            ← confirm endDate / isSubscriptionActive
```
`PUT /customer/booking/checkout` is the same thing **without** creating a subscription — first-purchase variant only. Neither verifies the Razorpay signature.

### D. Reading subscription state from the app

`GET /organisation-subscriptions/org/{orgId}` → `[{ organisationSubscriptionId, orgId, startDate, endDate, isSubscriptionActive, subscriptionId, adminUserLimit, membersLimit, pricePerYear, bookingId, transcationDetails }]`. Empty array = no completed booking → the app should show "no active subscription".

`GET /organisation-subscriptions` (all orgs) additionally returns computed `isFree` and `daysLeft`.

### E. Expiry & pause

* Cron (`schedulerService`): 09:00 reminders at 30/15/7/3/1 days, 10:00 deactivation of expired subs, 11:00 stats. Manual triggers under `/subscription-expiry/*`.
* Seat limits are enforced at member creation (`isSubscriptionAllowed`): subscription must exist, be `isSubscriptionActive`, not past `endDate`, and adding a user must not exceed `adminUserLimit` / `membersLimit`. FREE plans skip the limit check entirely.
* Org pause (`PUT /organisations/{id}/pause` / `/unpause`) suspends the subscription and, on unpause, extends `endDate` by the pause duration.

### F. Invoices

* `Invoices` table CRUD lives at `/invoices` (**JWT required**).
* In practice invoices are generated inline: `checkout.js` builds a real PDF via `src/core/utils/invoiceTemplate.createInvoice` and stores base64 into `Booking.transcationDetails.invoicePDF`; `paidSubscription.js` has a **stub** that returns `"base64_invoice_placeholder"`.
* Dashboard PDF downloads (`/dashboard/red-tag-list/download`, `/dashboard/task-list/download`) also return base64 PDFs in `data`.

---

## 6. Core domain entities (from migrations)

All tables use `uuid` PKs (`uuid_generate_v4()`) plus `createdAt/modifiedAt/createdBy/modifiedBy` unless noted. Table names are **quoted PascalCase** in Postgres.

### `Users`
`id`, `roleId`→Roles, `orgId`→Organisation, `zoneId`→Zone, `email` (unique), `phoneNumber` (unique), `photo`, `fullName`, `password` (bcrypt), `role` (string), `scope` (json array), `designation`, `authToken` (text), `firebaseToken` (text), `signupType` (notNull), `approved` (bool, def false), `disabled` (bool, def false), `fcmToken` (text), `passwordResetToken`, `passwordResetExpires` (added 2024-12-02).

### `UserValidation`
`id`, `userId`→Users (unique, notNull), `isCurrentSession`, `isPasswordSet`, `emailValidationKey`, `isPhoneValid`, `isEmailValid`, `isAcceptTerms`, `isAcceptPrivacy`, `isDocSubmitted`, `otp`, `otpExpTime`, `emailVerificationCode`, `emailVerificationExpTime` (added 2024-03-28).

### `Roles`
`id`, `roleName` (unique, notNull), `approved` (def true).

### `Organisation`
`id`, `name` (notNull), `addressLine1`, `addressLine2` (text), `contactNo`, `email` (unique), `gstNo`, `pancardNo`, `approved` (def **true**), `isPaused` (def false), `pausedAt`, `pauseExpiresAt` (added 2024-12-01; `pauseReason`/`pauseNotes`/`pausedBy` were added then dropped 2024-12-02).

### `Zone`
`id`, `zoneName` (notNull), `orgId`→Organisation, `approved` (def true).

### `Tasks`
`id`, `taskName` (notNull), `description` (text), `taskPhotos` (json — array of `{path}`), `zoneMemberId`→Users, `orgId`→Organisation, `zoneId`→Zone, `targetDate` (date), `status` (def `'PENDING'`), `activity` (json — array of `{ status, actionOn, description, actionBy, path, remarks? }`), `approved` (def true).

### `RedTagList`
`id`, `orgId`→Organisation, `zoneId`→Zone, `description` (text), `path` (S3 URL), `redTagBy`→Users, `status` (def `'PENDING'`), `activity` (json), `approved` (def true). (`remarks` existed but was dropped 2024-12-17.)

### `Subscription`
`id`, `SubscriptionName` (notNull), `description` (text), `adminUserLimit` (int), `membersLimit` (int), `pricePerYear` (decimal 14,2), `onboardingPrice` (decimal 14,2), `approved` (def true).

### `OrganisationSubscription`
`id`, `orgId`→Organisation, `subscriptionId`→Subscription, `startDate` (date), `endDate` (date), `isSubscriptionActive` (bool, def false).

### `Booking`
`id`, `orgId`→Organisation (**made nullable** 2024-12-01), `bookingId` (short-uuid string, notNull), `subscriptionId`→Subscription (notNull), `productDetails` (json), `transcationDetails` (json — note the misspelling; holds `razorpayPaymentId, razorpayOrderId, amount, tax, totalPaidPrice, billingAddress, paymentStatus, paymentTimestamp, invoicePDF`), `status` (text: `PENDING|DONE|FAILED|REJECTED|EXPIRE`), `payoutStatus` (text), `registrationData` (jsonb — `{ orgName, unitName, adminName, adminPhone, adminEmail, employeeCount }`, added 2024-12-01).

### `Invoices`
`id`, `organisationSubscriptionId`→OrganisationSubscription, `issueDate` (date), `amount` (decimal 14,2), `status`.

### `Tickets` (no routes exist; `ticketsStore.js` is orphaned)
`id`, `userId`→Users (notNull), `orgId`→Organisation, `ticketId` (notNull), `email`, `fullName`, `ticketType`, `description` (text), `status` (def `'PENDING'`), `activity` (json), `approved`.

### `Enquiry`
`id`, `name` (notNull), `email` (notNull), `phoneNumber` (notNull).

### `Manual`
`id`, `orgId`→Organisation, `name` (notNull), `path` (**made nullable** 2024-03-27), `zoneId`→Zone (added 2024-03-27, unused by the routes), `approved` (def true).

### `TrainingMaterial`
`id`, `orgId`→Organisation, `materialType` (notNull), `name` (notNull, added 2024-03-27), `path` (**nullable** since 2024-03-27), `zoneId`→Zone (added 2024-03-27, unused), `approved` (def true).

### `News`
`id`, `orgId`→Organisation (notNull), `title` (notNull), `path` (notNull), `description` (text).

### `FlashNews` (created 2024-12-03, restructured 2024-12-17)
`id`, `orgId`→Organisation (notNull), `content` (text, notNull), `expiryDate` (timestamp, **notNull**). The original `title`, `priority`, `path`, `isActive` columns were **dropped**.

### `BestPractices`
`id`, `orgId`→Organisation, `title` (notNull), `zone` (**string** notNull — a free-text zone label, not a FK), `description` (text), `path` (S3 URL), `approved` (def true).

### `ZoneScore`
`id`, `orgId`→Organisation (notNull), `zoneId`→Zone (notNull), `zoneScore` (int, notNull), `monthAndYear` (string, notNull — `"YYYY-MM"`).

### `AuditSheets`
`id`, `orgId`→Organisation (notNull), `month` (string), `name` (notNull), `questions` (json — `[{ questionId, question }]`), `maxScore` (int, notNull, def 100), `totalQuestions` (int, notNull), `approved` (def true). **`zoneId` was dropped** (2024-03-24) — an audit sheet is now org-wide and its zone is derived from submissions.

### `AuditSheetSubmissions`
`id`, `auditSheetId`→AuditSheets (notNull), `submittedBy`→Users (notNull), `grades` (json — `{questionId: score|"NA"}`), `remarks` (json — `{questionId: text}`), `photos` (json — `{questionId: [{url, description}]}`), `totalScore` (int, notNull def 0), `percentage` (decimal 5,2 def 0), `naQuestions` (int def 0), `applicableQuestions` (int def 0), `auditScorePercentage` (decimal 5,2 def 0), `auditDate` (timestamp), `auditZone`→Zone (notNull), `userZone`→Zone (notNull). (`zone` was replaced by `auditZone`/`userZone` on 2024-03-26.)

### `FreeTrialPending` (created 2024-04-01)
`id`, `orgName` (notNull), `unitName`, `adminName` (notNull), `adminPhone` (notNull), `adminEmail` (notNull), `numEmployees` (int), `verificationCode` (notNull), `codeExpiry` (bigint unix seconds, notNull), `createdAt`.

### `GeneralParams`
`id`, `key` (unique, notNull), `value` (notNull), `description`, `category` (notNull). Seeded with `SESSION_EXPIRY_TIME = 3000000000`.

### Legacy integer-PK audit tables (2024-03-21) — used only by `/api/audit/*`
* `audit_questions`: `id` (serial), `question_text`, `max_score`, `category`, `is_active`, timestamps.
* `audit_sessions`: `id`, `zone_leader_id` (int), `location`, `audit_date`, `total_score`, `status` (`in_progress|completed`), `remarks`.
* `audit_responses`: `id`, `audit_session_id`, `question_id`, `score`, `remarks`.
* `audit_attachments`: `id`, `audit_session_id`, `response_id`, `file_url`, `file_type`.

### `UserPermissions`
Referenced by `userPermissionsStore.js` but **has no migration** — the table does not exist.

### Feature → entity map

| Feature | Tables | Key routes |
|---|---|---|
| Organisation | `Organisation` | `/organisations*` |
| Organisation users | `Users`, `UserValidation`, `Roles` | `/users/organisation-admin`, `/users/organisation-members`, `/users/org/{id}`, `/users/login` |
| Zones | `Zone` | `/zones*` |
| Zone score | `ZoneScore` | `/zone-scores*` |
| Tasks | `Tasks` | `/tasks*` |
| Red tag list | `RedTagList` | `/redtags*` |
| Audit sheets / audit / audit score view | `AuditSheets`, `AuditSheetSubmissions` (+ legacy `audit_*`) | `/audit-sheets*`, `/audit-scores*`, `/api/audit/*` |
| Manuals | `Manual` | `/manual*` |
| Training material | `TrainingMaterial` | `/training-material*` |
| Best practices | `BestPractices` | `/best-practices*` |
| News | `News` | `/news*` |
| Flash news | `FlashNews` | `/flash-news*` |
| Dashboard | reads RedTagList/Tasks/ZoneScore | `/dashboard/organisation`, `/dashboard/super-admin` |
| Admin dashboard | `Booking`, `Organisation`, `Subscription`, `Users` | `/admin/*` |
| Hospital dashboard | — | none (file exports `[]`) |
| Enquiries | `Enquiry` | `/enquiries*` |
| Customer | — | none (file is fully commented out) |
| Developer | — | `/developer/test-email` |
| Invoices | `Invoices` | `/invoices*` |
| Subscriptions | `Subscription`, `OrganisationSubscription`, `Booking`, `FreeTrialPending` | `/subscriptions*`, `/organisation-subscriptions*`, `/free-trial/*`, `/paid-subscription/*`, `/customer/booking/checkout*` |

---

## 7. File upload conventions

### Transport

Multipart routes declare:
```js
payload: { maxBytes: 20 * 1000 * 1000, output: 'stream', parse: true, multipart: true }
```
i.e. **20 MB (20 000 000 bytes)** per request, streamed. Hapi's default `maxBytes` (1 MB) applies to every other route.

### Storage — `src/core/s3Bucket/uploadFiletoS3.js`

AWS SDK v3 `PutObjectCommand`. **No ACL is set** (bucket uses "bucket owner enforced"); public read must come from a bucket policy.

* Bucket: `process.env.AWS_S3_BUCKET` = **`digi5s-app-uploads`**
* Region: `process.env.AWS_REGION` = **`ap-south-1`**
* Key: `` `${folder}/${name}` ``
* Returned URL shape (non-`us-east-1` branch):
  ```
  https://digi5s-app-uploads.s3.ap-south-1.amazonaws.com/<Folder>/<filename>
  ```
  (for `us-east-1` it would be `https://<bucket>.s3.amazonaws.com/<key>`)

Filenames are built as `<Prefix>_<name>_<YYYY><M><D>_<H>_<m>_<s>.<ext>` — note that several call sites do `uploadFileAndGetURL(folder, FileName + fileExtension, …)` where `FileName` already ends in `.`, and `tasks.js` appends the extension **twice** (`Task_x_...jpg` + `jpg` → `...jpgjpg`). Expect messy extensions in existing data.

### Route-by-route

| Route | Field name(s) | Allowed types | S3 folder | Notes |
|---|---|---|---|---|
| `POST /users/organisation-members` | `file` | png, jpg, jpeg | `Profile-photo` | Stored on `Users.photo`. |
| `POST /tasks` | `file` | png, jpg, jpeg, pdf | `Tasks` | Stored as `Tasks.taskPhotos` = JSON `[{path}]`. |
| `PUT /tasks/{id}` | `file` | png, jpg, jpeg, pdf | `Tasks` | Replaces `taskPhotos`. |
| `PUT /tasks/status/completed/{id}` | `file` | PNG/png, jpg, jpeg, pdf | `Manual` (mis-set) | URL goes into the activity entry's `path`. |
| `POST /tasks/request-approval/{id}` | **`photos`** (repeatable — single file or array) | png, jpg, jpeg | `TaskApprovals` | Activity `path` = JSON string of `[{path}]`. |
| `POST /redtags` | `file` | png, jpg, jpeg, pdf | `Red-tag-list` | `RedTagList.path`. File optional. |
| `POST /manual` | `file` | png, jpg, jpeg, pdf | `Manual` | `Manual.path`. |
| `POST /training-material`, `PUT /training-material/{id}` | `file` | png, jpg, jpeg, pdf | **`News`** | `TrainingMaterial.path`. |
| `POST /news` | `file` | png, jpg, jpeg, pdf, mp4 | `News` | `News.path`; effectively required. |
| `POST /best-practices`, `PUT /best-practices/{id}` | `file` | png, jpg, jpeg, pdf, mp4 | `BestPractices` | `BestPractices.path`. |
| `POST /audit-sheets/{sheetId}/submit` | `responses[].photos[].file` — **base64 data URI in a JSON body**, not multipart | `data:image/<ext>;base64,…` | `AuditPhotos` | Stored as `{ questionId: [{ url, description }] }`. Invalid/failed uploads are silently skipped. |

Invalid mime type → body `statusCode: 415` with `error: 'Invalid mime type'` / `'Invalid file type'`. Upload failure → body `statusCode: 500`.

Legacy: `src/core/utils/fileupload.js` writes to a local `./upload/` directory and is served by `GET /upload/assets/{path*}` — no longer used by any active route.

---

## 8. Push notifications (FCM)

**Effectively not wired up.**

* `Users` has both `fcmToken` (text) and `firebaseToken` (text) columns.
* **Device-token registration endpoint**: `PATCH /users/fcmToken` — `auth: false`, payload `{ userId: string (required), fcmToken: string (required) }`. It writes `Users.fcmToken` and returns envelope A with the updated user row. There is no equivalent for `firebaseToken`.
* `POST /customer/Signup` also accepts an `fcmToken` (typed `Joi.number()`, which is wrong for FCM tokens) and passes it to `SignupOtp`.
* `src/core/fcmNotification/notification.js` exports `sendFcmNotification(customData, fcmToken, title, body)` using `firebase-admin` `sendMulticast` with a service-account JSON at `src/core/fcmNotification/jeevan-driver-app.json` (a leftover from the "Jeevan" ambulance project; the file is not in the repo). **Nothing imports this module** — no route sends a push.
* `singleNotification.js` and `customerNotification.js` are entirely commented out.

All user-facing notification today is **email** (nodemailer + pug templates under `src/core/email-templates/`): welcome org / org member, task assigned & approval request/response, forgot password OTP + reset link + success, email verification, organization verification & setup, free-trial completed, paid-subscription receipt / admin notification / credentials, payment notification to admin, subscription expiry reminder & expired.

If the rebuilt Flutter app needs push, the backend work required is: call `PATCH /users/fcmToken` after login, and add server-side `sendFcmNotification` calls (plus a valid Firebase service account) at the task-assign / task-approval / red-tag-approval / flash-news points.

---

## 9. Notes from the documentation files

### `FLUTTER_APP_DOCUMENTATION.md`
Aspirational spec, written before/independently of the backend — it does **not** match the current API. Worth knowing:
* Proposed feature modules: **Auth** (login, org registration, user registration, password reset, email verification), **Dashboard** (org overview, subscription status, quick actions, notifications, analytics), **Organization** (profile, members, zones, subscription, settings), **Tasks** (list, create, assign, status updates, comments, attachments), **Profile** (info, photo, role, activity history, settings).
* Named screens: Splash (logo, version check), Login (email/password, "social login options", **organization selection**), Dashboard (custom bottom navigation, quick-action cards, recent activities, statistics), Task Management (**Kanban board / list / calendar views**, filters), Profile (user info, org details, subscription status, settings).
* Assumes `Authorization: Bearer $token`, Material 3, Bloc/Riverpod, dio, offline caching + sync, FCM push for task assignments/due-date reminders, multi-language + RTL.
* Its "Backend Modifications Required" list is a candid gap list: **pagination, real-time updates, file upload endpoints, better errors, push-notification registration, analytics, bulk operations, search, rate limiting, device tracking** — most of which are still missing (only `/admin/paid-subscriptions/pending` paginates; only paid-subscription initiate is rate-limited).
* Notably absent from this doc but central to the real product: **red tags, audit sheets, zone scores, flash news, best practices, manuals, training material**. Do not use this doc as the screen list.

### `PROJECT_DOCUMENTATION.md`
Accurate high-level model: multi-tenant, Organisation is the top entity, each org has one subscription, users belong to orgs with roles `ORG-ADMIN | ZONE-MEMBER | ZONE-LEADER | VIEWER`, tasks and zones are org-scoped, all operations validated against subscription limits. Claims a "token expiration and refresh mechanism" — **there is no refresh**. Documents an endpoint `GET /customer/booking/checkout/{bookingId}` that **does not exist**.

### `PAID_SUBSCRIPTION_IMPLEMENTATION.md`
Describes the 4-step flow above and states admin endpoints "Require JWT" — in the code they are all `auth: false` with a `// Temporarily disable auth for testing` comment. Also documents `GET /admin/paid-subscriptions/{bookingId}` and `POST /admin/paid-subscriptions/{bookingId}/approve`; the code actually has `POST /admin/paid-subscriptions/{orgId}/approve` (keyed by **orgId**, not bookingId) and no per-booking GET.

### `SUBSCRIPTION_EXPIRY_IMPLEMENTATION.md`
Confirms reminder intervals 30/15/7/3/1 days, cron at 09:00/10:00/11:00, expiry-day email with a payment link, auto-deactivation, and duplicate-reminder suppression. Implies the app should surface a renewal CTA driven by `daysLeft` from `/organisation-subscriptions`.

### `LOGOUT_IMPLEMENTATION.md`
Confirms `/auth/logout` requires `Authorization: Bearer <JWT>` and only nulls the DB `authToken`; recommends the client clear local storage. Confirms the credentials shape `{ userId, orgId, scope }`.

### `EMAIL_PASSWORD_RESET_IMPLEMENTATION.md`
Confirms the two parallel reset flows and the exact request/response bodies; reset link TTL 1 hour; the landing page is the API-hosted `reset-password.html`.

### `ORGANISATION_PAUSE_IMPLEMENTATION.md`
Pause suspends the org and its subscription; unpause extends `endDate` by the pause duration ("fair billing"). A background service auto-unpauses at `pauseExpiresAt`. **The app should handle a paused org**: the subscription reads `isSubscriptionActive: false` while paused, so any "subscription inactive" screen must not be mistaken for expiry.

### `RED_TAG_APPROVAL_SYSTEM.md`
Confirms the status flow `PENDING → APPROVED | REJECTED`, that org admins are `SUPER-ADMIN | ORGANISATION-ADMIN | ORG-ADMIN`, scoped to their own org (super admins are cross-org), and the exact `GET /redtags/pending/{orgId}?adminUserId=…` response shape (`id, orgId, zoneId, description, path, status, activity, approved, createdAt, createdBy, email, zoneName`).

### `AUDIT_SCORE_VIEW_FIX.md`
States the intended UX is a **two-step flow**: (1) pick a zone via `GET /audit-scores/zones`, (2) show last-6-months scores via `GET /audit-scores/zone/{zoneId}/last-6-months`. The doc says `orgId` was removed from the query string — **the code still requires `?orgId=<guid>`**. Build against the code.

### Other docs
`ZONE_REMOVAL_API_DOCUMENTATION.md` (zone deletion FK guardrails, mirrored by the 409 response on `DELETE /zones/{id}`), `WEBHOOK_SETUP.md`, `TESTING_GUIDE.md` (confirms the production host `https://api.seichoconsulting.com` and references a `POST /users/signup` endpoint that does not exist), plus a large set of AWS/Lightsail/DB-migration runbooks that are irrelevant to the API contract.

---

## 10. Gotchas the Flutter rebuild must plan for

1. **HTTP status is almost always 200.** Parse `body.statusCode` and `body.status`, not the transport code — except in `freeTrial`, `paidSubscription`, `adminDashboard`, `subscriptionExpiry`, which do use real codes.
2. **Two response envelopes** (`{statusCode,status,error,message,data}` vs `{statusCode,message,data}`) — write a tolerant decoder.
3. **The token comes back as `data.authToken` from `/users/login`**, not from a `token` field or a header.
4. **`ORG-ADMIN` ≡ `ORGANISATION-ADMIN`** — normalise client-side.
5. **Role/permission checks are payload-driven** (`userId`, `adminUserId`), so the app must send the current user's id explicitly on: `POST /audit-sheets`, `PUT /audit-sheets/{id}`, `POST /audit-sheets/{sheetId}/submit` (`submittedBy` + `userZone`), `GET /audit-sheets?userId=`, `GET /audit-sheets/{sheetId}/submissions?userId=`, `DELETE /audit-sheets/{sheetId}/submissions/{submissionId}?userId=`, `POST /redtags/approve/{id}` (`adminUserId`), `GET /redtags/pending/{orgId}?adminUserId=`, `POST /tasks` (`createdBy`), `POST /redtags` (`createdBy`).
6. **`GET /users/organisation-members/{id}` takes a USER id and returns ONE user.** For the member list use `GET /users/org/{orgId}` or `GET /organisations/members/{orgId}`.
7. **`PUT /tasks/{id}` wipes the activity history** and resets status to PENDING.
8. **`PUT /tasks/status/completed/{id}` sets `PENDING_APPROVAL`, not `COMPLETED`.**
9. **`POST /news` fails silently (500) without a file.**
10. **No pagination anywhere** except `/admin/paid-subscriptions/pending`. `GET /tasks`, `GET /redtags`, `GET /news`, `GET /audit-scores/zones` return the whole table across all orgs.
11. **No refresh token**; token TTL is effectively unbounded because `rememberMe` is hardcoded true.
12. **CORS is `*` and nearly every endpoint is unauthenticated** — any org's data is readable by id. Treat all client-side gating as cosmetic and flag this for the backend team.
