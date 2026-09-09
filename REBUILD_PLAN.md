# Digi5S Flutter App — Rebuild Plan

Written 2026-09-09. The published app (`com.digi5s.app`, App Store v2.0.0 Oct 2025, Play Store updated Mar 2026)
was built from source that was lost with the old Mac. GitHub holds a June 2025 development snapshot
(branch `UI`, commit 7ceb614). This plan rebuilds the app from that snapshot against the current backend
(`https://api.seichoconsulting.com`, contract in `docs/API_CONTRACT.md`).

Work happens on branch `rebuild`.

---

## 1. Where the June code stands

**Already implemented and reusable (keep, then wire properly):**
tasks (create / approve / my tasks), red tags (list / create / status), audit sheets (create / edit / perform / statistics),
manuals, news, training material (manage screen), best practices, zones, zone members, role dashboards, Riverpod + go_router.

**Present but running on dummy data or in-memory only:**
flash news, active organisations, add organisation, org info, steering committee, 5S training material (member view),
red tag list view, viewer dashboard.

**Missing entirely (exists in backend, needed by the live app):**
logout, forgot/reset password, home dashboard counts, subscription status and renewal, org-admin member management
(list / deactivate / reset password), red tag approval by admins, task status flow (work-in-progress / completed with proof),
audit score view (last 6 months), zone scores, super-admin org approvals and paid-subscription approvals,
free-trial signup, paid signup with Razorpay, organisation pause handling, profile screen.

**Must be fixed before any store build:**
- API base URL hardcoded to `http://localhost:8081` in 22 places.
- Bearer token attached on almost no request.
- `com.example.seicho_app` / `com.example.seichoApp` ids, debug signing in release, no INTERNET permission in the main
  Android manifest, no camera/photo usage strings on iOS.
- Passwords printed to the console on login and member creation.

---

## 2. Backend facts that shape the design

- One login: `POST /users/login`. The JWT is in `data.authToken`. No refresh endpoint; tokens effectively never expire.
- HTTP status is almost always 200. The real code is `body.statusCode`; two envelope shapes exist.
- Roles: `SUPER-ADMIN`, `ORGANISATION-ADMIN` (≡ `ORG-ADMIN`, both exist in data), `ZONE-LEADER`, `ZONE-MEMBER`, `VIEWER`.
- Authorisation is payload-driven: the app must send `userId` / `adminUserId` / `createdBy` / `submittedBy` explicitly.
- Uploads: multipart field `file` (20 MB), except task approval (`photos`) and audit submit (base64 in JSON).
- Nearly every endpoint is unauthenticated server-side. Client role gating is UX only. Flagged for backend work.
- Push notifications are not wired on the backend. Email is the only notification channel today.

---

## 3. Phases

### Phase 0 — Foundations (no new screens)
1. `lib/core/config/app_config.dart`: base URL from `--dart-define=API_BASE_URL`, default production.
2. `lib/core/api/api_client.dart`: single HTTP client. Attaches `Authorization: Bearer`, decodes both envelopes,
   throws `ApiException` on `body.statusCode >= 400`, multipart helper, 401 → clears session.
3. `lib/core/auth/session.dart`: `UserSession` model + `SessionStore` (secure storage) + Riverpod `sessionProvider`.
   Normalises `ORG-ADMIN` to `ORGANISATION-ADMIN`. Exposes `isAdmin`, `isZoneLeader`, `isZoneMember`, `isViewer`.
4. Replace every hardcoded base URL and raw `http` call in services with `ApiClient`.
5. Router: redirect guard (no session → `/login`, session → role home), remove `ModuleSelectionScreen` from the
   default path, fix the four broken route pushes, delete the dead commented-out files.
6. Logout: `POST /auth/logout`, clear storage, go to `/login`. Menu entry on every dashboard.
7. Platform: ids `com.digi5s.app`, app name `diGi5S`, INTERNET permission, iOS usage descriptions, version bump,
   release signing config that reads from `key.properties`.
8. Remove password logging and unused dependencies.

### Phase 1 — Auth completeness
- Forgot password: `POST /auth/password-reset/otp` → OTP + new password screen → `POST /auth/password-reset`.
- Login error handling from `body.statusCode` (404 / 405 pending / 405 disabled / 401).
- Register device token after login via `PATCH /users/fcmToken` (no-op until Firebase is added).

### Phase 2 — Home dashboards on real data
- Org / zone dashboards read `POST /dashboard/organisation` for red-tag and task counts.
- Flash news ticker from `GET /flash-news/org/{orgId}` filtered by `expiryDate`; CRUD for admins.
- Subscription banner from `GET /organisation-subscriptions/org/{orgId}`: days left, expired, paused.
- Viewer dashboard: read-only versions of news, manuals, training, best practices, red tags.

### Phase 3 — Wire the existing feature screens correctly
- Org-scoped lists everywhere: `/news/org`, `/manual/org`, `/best-practices/org`, `/training-material/org`,
  `/tasks/org`, `/redtags/org`. Never the global lists.
- Red tags: detail by `GET /redtags/{id}`; admin pending list `GET /redtags/pending/{orgId}?adminUserId=`;
  approve / reject via `POST /redtags/approve/{id}`.
- Tasks: status updates `PUT /tasks/status/{id}`, completion with proof `PUT /tasks/status/completed/{id}`,
  request approval with photos, approve / reject. Correct `createdBy` and real `orgId` on create.
- Audits: `userId` on list and submissions, `submittedBy` + `userZone` on submit, statistics route fix.
- Training material member view and 5S training screen from the API.
- Zone scores: `POST /zone-scores/org` chart; admin entry via `POST /zone-scores`.
- Audit score view: zone picker → `GET /audit-scores/zone/{zoneId}/last-6-months?orgId=`.

### Phase 4 — Org admin management
- Members: list `GET /users/org/{orgId}`, create (existing form + roles), deactivate
  `PUT /users/organisation-members/inactive/{id}`, reset password `POST /users/{id}/reset-password`.
- Organisation profile: `GET/PUT /organisations/{id}`.
- Remove steering committee (no backend) or keep as local-only with a clear label.

### Phase 5 — Super admin
- Organisations list with subscription status, create (`POST /organisations` shows generated credentials),
  approve / unapprove, pause / unpause.
- Pending paid subscriptions: list, approve, reject.
- Counts from `POST /dashboard/super-admin`.

### Phase 6 — Onboarding and payments
- Free trial: `POST /free-trial/start` → code → `POST /free-trial/verify` → login.
- Paid signup: pricing → initiate → Razorpay checkout (`razorpay_flutter`) → complete → "awaiting approval".
- Renewal for an existing org: plans → initiate → Razorpay → `checkout-renew`.
- Note: Apple may require these purchases to happen outside the iOS app (guideline 3.1.1). Decide before submitting.

### Phase 7 — Release
- Profile screen (photo, role, org, subscription, logout).
- App icon and splash, store screenshots.
- Android: new upload key if the old one is gone (see risk below). iOS: regenerate certificates and profiles.
- Smoke test every role against production with test accounts.

---

## 4. Risks to resolve early

1. **Android signing key.** The upload keystore lived on the lost Mac. If the app is enrolled in Play App Signing,
   request an upload-key reset in Play Console. If it is not enrolled, the existing listing cannot be updated and a
   new package would be needed. Check this first in Play Console → Setup → App signing.
2. **Backend security.** Nearly every route is public and role checks trust client-supplied ids. The rebuilt app
   sends the Bearer token on every call so the backend can start enforcing it without another app release.
3. **`ORG-ADMIN` vs `ORGANISATION-ADMIN`** must be treated as one role everywhere in the app.
4. **No pagination** on the backend. Lists are org-scoped and small today; revisit if an org grows.

---

## 5. Order of work in this session

Phase 0 in full, then Phase 1, then Phase 2 and 3 feature by feature, committing after each working step.
