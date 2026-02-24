# QR Token & Allowlist System Design

**Date**: 2026-02-23
**Status**: Approved
**Scope**: Secure QR token verification, product linking, routine tracking

---

## 1. Architecture Overview

**Pattern**: Thin-client, server-authoritative

All token validation and product resolution occurs via `api.reflectapp.com`. The iOS app performs only strict local parsing (domain allowlist, path prefix, token regex), then delegates verification to the proxy.

**Flow**:
```
Scan QR → extract token → local format check → GET /v1/tokens/{token}
    → cache App Store-safe product snapshot in SwiftData → display product
```

**Key principles**:
- Token logic lives server-side in a proxy that internally calls the upstream minting system
- The iOS app knows only about `link.reflectapp.com` and `api.reflectapp.com`
- No references to the upstream minting system or business in any client code, comments, or metadata
- All product metadata is App Store-safe: no medical claims, dosing, or usage instructions
- Offline scans enter a pending queue and resolve automatically when connectivity returns

---

## 2. Token Format Specification

| Property | Value |
|---|---|
| Prefix | `qr_` |
| Body | 20-30 characters, `[a-zA-Z0-9]` |
| Total length | 23-33 characters |
| Regex | `^qr_[a-zA-Z0-9]{20,30}$` |

**QR URL format** (encoded in physical QR code):
```
https://link.reflectapp.com/t/{token}
```

**URL validation** (iOS-side, before any network call):
1. Scheme must be `https`
2. Host must be exactly `link.reflectapp.com`
3. Path must start with `/t/`
4. Token extracted from path must match regex

**Examples**:

| QR URL | Extracted Token | Valid? |
|---|---|---|
| `https://link.reflectapp.com/t/qr_POcQ38aDUKrqeyFQJibNKK` | `qr_POcQ38aDUKrqeyFQJibNKK` | Yes |
| `https://link.reflectapp.com/t/qr_abc` | `qr_abc` | No (too short) |
| `https://evil.com/t/qr_POcQ38aDUKrqeyFQJibNKK` | -- | No (wrong domain) |
| `https://link.reflectapp.com/other/qr_POcQ38aDUKrqeyFQJibNKK` | -- | No (wrong path) |

**Versioning**: Token format is `v1`. Future versions can change the prefix (e.g., `qr2_`) or add query parameters (`?v=2`). App checks version compatibility before resolving.

**Typing**: `token_type` is returned by the API response, not embedded in the token. MVP supports `type: "LP"` (linked product). Future types can be added server-side without app changes.

---

## 3. Allowlist Database Schema

### Server-Side (Proxy at `api.reflectapp.com`)

**`tokens` table**:

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, default gen | Internal row ID |
| `token` | VARCHAR(33) | UNIQUE, NOT NULL, indexed | The `qr_xxx` token string |
| `token_type` | VARCHAR(10) | NOT NULL, default `'LP'` | Token category |
| `version` | VARCHAR(5) | NOT NULL, default `'v1'` | Token format version |
| `issuer_id` | VARCHAR(50) | NOT NULL, default `'reflect'` | Who minted it |
| `product_id` | VARCHAR(50) | NOT NULL | Reference to product record |
| `status` | ENUM | NOT NULL, default `'active'` | `active`, `revoked`, `expired` |
| `minted_at` | TIMESTAMP | NOT NULL | When token was created |
| `revoked_at` | TIMESTAMP | NULLABLE | When revoked |
| `expires_at` | TIMESTAMP | NULLABLE | Optional expiration |

**`products` table**:

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | VARCHAR(50) | PK | Product identifier |
| `name` | VARCHAR(100) | NOT NULL | Display name (App Store-safe) |
| `category` | VARCHAR(50) | NOT NULL | e.g., "Herbal Tea", "Supplement" |
| `description` | TEXT | NULLABLE | Brief, neutral description |
| `batch_id` | VARCHAR(50) | NULLABLE | Batch/lot for provenance |
| `verified_at` | TIMESTAMP | NOT NULL | When product was verified |
| `updated_at` | TIMESTAMP | NOT NULL | Last metadata update |

**`scan_rate_limits` table**:

| Column | Type | Constraints | Description |
|---|---|---|---|
| `device_hash` | VARCHAR(64) | PK | SHA-256 of device identifier |
| `window_start` | TIMESTAMP | NOT NULL | Rate limit window start |
| `scan_count` | INT | NOT NULL, default 0 | Scans in current window |

### iOS-Side (SwiftData Models)

**`VerifiedProduct`**:

| Property | Type | Description |
|---|---|---|
| `id` | UUID | SwiftData primary key |
| `productId` | String | Server product ID |
| `token` | String | The `qr_xxx` token (local only, never transmitted after resolution) |
| `name` | String | Product display name |
| `category` | String | Product category |
| `productDescription` | String? | Brief description |
| `batchId` | String? | Batch/lot info |
| `verifiedAt` | Date | When verified by server |
| `cachedAt` | Date | When cached locally |
| `cacheTTL` | TimeInterval | Cache validity (default: 86400 = 24h) |
| `status` | String | `active`, `revoked` |

Computed: `isCacheStale: Bool` -- `Date() > cachedAt + cacheTTL`

**`RoutineEntry`**:

| Property | Type | Description |
|---|---|---|
| `id` | UUID | SwiftData primary key |
| `product` | VerifiedProduct | Relationship to cached product |
| `schedule` | RoutineSchedule | Daily, weekly, custom, as-needed |
| `scheduleDays` | [Int]? | Days of week (1=Mon, 7=Sun) |
| `reminderTime` | Date? | Optional reminder time |
| `reminderEnabled` | Bool | Whether reminders are active |
| `notes` | String? | User notes |
| `linkedAt` | Date | When added to routine |
| `isActive` | Bool | Whether still active |

**`RoutineLog`**:

| Property | Type | Description |
|---|---|---|
| `id` | UUID | SwiftData primary key |
| `routineEntry` | RoutineEntry | Relationship to routine item |
| `loggedAt` | Date | When user confirmed usage |
| `skipped` | Bool | Skipped vs. used |
| `note` | String? | Optional note |

**`PendingToken`**:

| Property | Type | Description |
|---|---|---|
| `id` | UUID | SwiftData primary key |
| `token` | String | Token awaiting resolution |
| `scannedAt` | Date | When scanned |
| `retryCount` | Int | Resolution attempts |
| `lastRetryAt` | Date? | Last attempt |
| `status` | String | `pending`, `resolving`, `failed` |

---

## 4. Token Minting and Revocation Workflow

### Minting Flow

```
Admin Action → Minting system generates qr_xxx token
    → Token registered in upstream allowlist
    → QR code generated with URL: https://link.reflectapp.com/t/{token}
    → QR applied to physical product packaging
```

Minting happens exclusively in the existing minting system. The Reflect proxy never creates tokens.

### Sync Mechanism (MVP: Pull-Through Cache)

When the proxy receives `GET /v1/tokens/{token}` and doesn't have it cached:
1. Proxy calls the upstream API with its service token
2. Upstream returns product data
3. Proxy sanitizes response (strips non-allowlisted fields)
4. Proxy caches sanitized result in its database
5. Returns sanitized product to the iOS app

### Revocation Flow

```
Admin revokes token in minting system
    → Upstream API returns 410 for that token
    → Next proxy resolution receives 410
    → Proxy marks token as `revoked` in its DB
    → All subsequent app requests get `revoked` status
    → App shows: "This product is no longer verified"
    → RoutineEntry.isActive set to false
```

**Revocation propagation**: Pull-through model means revocation propagates on next cache miss (after TTL expiry, default 1 hour). For critical revocations, admin uses the force-revoke endpoint.

### Force Revoke (Admin)

```
POST /internal/tokens/{token}/revoke
Authorization: Bearer {ADMIN_SECRET}
```

Immediately marks the token as revoked in the proxy database.

### Future: Webhook Push Sync

```
POST /internal/tokens/sync
Authorization: Bearer {SYNC_SECRET}
Body: { token, product_id, name, category, description, batch_id, status }
```

---

## 5. API Endpoint Definitions

### Public Endpoints (called by iOS app)

#### `GET /v1/tokens/{token}` -- Resolve

**Request**:
```
GET https://api.reflectapp.com/v1/tokens/qr_POcQ38aDUKrqeyFQJibNKK
X-Device-Hash: sha256(identifierForVendor)
X-App-Version: 1.0.0
```

**200 OK** (active):
```json
{
  "status": "active",
  "token_type": "LP",
  "version": "v1",
  "product": {
    "product_id": "prod_abc123",
    "name": "Chamomile Calm Blend",
    "category": "Herbal Tea",
    "description": "A soothing herbal tea blend with chamomile.",
    "batch_id": "batch_2024Q1_042",
    "verified_at": "2025-11-15T10:30:00Z"
  },
  "cache_ttl": 86400
}
```

**404 Not Found**:
```json
{
  "error": "TOKEN_NOT_FOUND",
  "message": "This product could not be verified."
}
```

**410 Gone** (revoked/expired):
```json
{
  "error": "TOKEN_INACTIVE",
  "message": "This product is no longer verified."
}
```

**429 Too Many Requests**:
```json
{
  "error": "RATE_LIMITED",
  "message": "Too many scan attempts. Please try again later.",
  "retry_after": 60
}
```

**503 Service Unavailable**:
```json
{
  "error": "SERVICE_UNAVAILABLE",
  "message": "Verification is temporarily unavailable. Please try again later."
}
```

#### `GET /v1/tokens/{token}/status` -- Lightweight status check

**200 OK**:
```json
{
  "status": "active",
  "updated_at": "2025-11-15T10:30:00Z"
}
```

### Internal Endpoints (admin only)

#### `POST /internal/tokens/{token}/revoke`

**200 OK**:
```json
{
  "token": "qr_POcQ38aDUKrqeyFQJibNKK",
  "status": "revoked",
  "revoked_at": "2026-02-23T14:00:00Z"
}
```

#### `POST /internal/tokens/sync` (future)

**201 Created**:
```json
{
  "token": "qr_newToken123abc456def",
  "synced_at": "2026-02-23T14:00:00Z"
}
```

### Response Schema Contract

The proxy enforces an allowlisted response schema. Fields not in the schema are stripped. The proxy never returns dosing information, usage instructions, medical claims, external URLs, or raw upstream identifiers.

---

## 6. QR Scan and Validation Flow

### State Machine

```
IDLE → (user taps "Scan Product") → SCANNING
SCANNING → (QR detected) → EXTRACTING
EXTRACTING → (valid URL) → VALIDATING_LOCAL
EXTRACTING → (invalid URL) → INVALID_QR → IDLE
VALIDATING_LOCAL → (regex passes) → RESOLVING
RESOLVING → (200) → VERIFIED → LINK_PROMPT
RESOLVING → (404) → NOT_FOUND → IDLE
RESOLVING → (410) → REVOKED → IDLE
RESOLVING → (network error) → OFFLINE_QUEUED → IDLE
LINK_PROMPT → (yes) → CONFIGURE_ROUTINE → ROUTINE_ACTIVE
LINK_PROMPT → (no) → LINKED (saved but not in routine)
```

### UX Screens

**Scan Entry**: "Scan Product" button in Routine tab. Opens full-screen camera overlay with viewfinder and "Point your camera at a product QR code" subtitle.

**Resolving**: Scanner pauses, spinner with "Verifying product..." copy.

**Verified**: Success haptic. "Verified" badge with checkmark. Product card: name, category, batch, verified date. CTAs: "Add to My Routine" (primary) / "Save for Later" (secondary).

**Configure Routine**: Product name header. Schedule picker (Daily/Weekly/As Needed/Custom). Day-of-week selector for weekly. Reminder toggle with time picker. Notes field. "Start Routine" CTA.

**Error States**: Generic copy (see Section 10).

### Pending Queue Resolution

On connectivity restored (`NWPathMonitor`):
1. Iterate `PendingToken` records where `retryCount < 3`
2. Attempt resolution for each
3. On 200: create `VerifiedProduct`, notify user, prompt to link
4. On 404 after 3 retries: mark `failed`, notify user
5. On 410: delete pending token, notify user

---

## 7. Offline Caching Strategy

### Cache Tiers

| Tier | Storage | TTL | Purpose |
|---|---|---|---|
| Product cache | SwiftData `VerifiedProduct` | 24h (from API `cache_ttl`) | Full product metadata |
| Status cache | In-memory dictionary | 1h | Lightweight active/revoked check |
| Pending queue | SwiftData `PendingToken` | Until resolved or 3 failures | Offline-scanned tokens |

### Cache Lifecycle

**On successful resolution**: Create/update `VerifiedProduct`, set `cachedAt`, `cacheTTL`.

**On subsequent access**:
- Not stale → serve from SwiftData (no network)
- Stale + online → background refresh via status endpoint; update or revoke
- Stale + offline → serve stale cache with "Last verified X ago" indicator

**Pattern**: Stale-while-revalidate. Always display cached data immediately. Refresh in background. Only block UI on first-ever resolution.

### Refresh Triggers

| Trigger | Action |
|---|---|
| App foreground | Refresh stale `VerifiedProduct` records |
| Routine tab opened | Refresh visible products |
| Pull-to-refresh | Force refresh all linked products |
| Network restored | Process pending queue + refresh stale cache |
| 24h background task | `BGAppRefreshTask` for stale products |

### Eviction Rules

- Active routine products: never evicted (refreshed on TTL)
- "Saved for later" products: evicted after 30 days of staleness
- Revoked products: metadata retained for display, evicted after 7 days
- Failed pending tokens: deleted after 3 days

---

## 8. Partner/Issuer Licensing Model

### MVP: Single Issuer

All tokens minted by the existing system. `issuer_id` field exists in schema, hardcoded to `"reflect"`.

### Future Multi-Partner

- Partners receive `issuer_id` and `SYNC_SECRET`
- Partner-minted tokens include their `issuer_id`
- Partners can only revoke their own tokens
- Tiered quotas: Free (100/mo), Standard (10K/mo), Enterprise (unlimited)
- Key rotation: issue new secret → grace period (7 days, both accepted) → old revoked

---

## 9. Threat Model and Abuse Prevention

| Threat | Severity | Mitigation |
|---|---|---|
| Token enumeration | High | Rate limiting, device-hash tracking, exponential backoff after 5 failures |
| Token replay | Medium | Acceptable for MVP (tokens not single-use, no harm) |
| QR spoofing | High | Strict domain allowlist, URL never opened in browser |
| Proxy scraping | Medium | Per-device rate limiting (10 req/min), device hash required |
| MITM | High | HTTPS only; certificate pinning post-MVP |
| Revocation bypass | Low | 24h cache TTL, background refresh, force-revoke endpoint |
| DoS | Medium | CDN-level rate limiting, stateless proxy |
| Offline queue poisoning | Low | Queue capped at 5 tokens, regex validation, 3-retry limit |

### Rate Limits

| Scope | Limit | Window | Action |
|---|---|---|---|
| Per device (resolve) | 10 req | 1 min | 429 + retry_after |
| Per device (status) | 30 req | 1 min | 429 |
| Per device (failures) | 5 failures | 5 min | Block 15 min |
| Global | 1000 req | 1 min | 503 |

### Device Identification

`X-Device-Hash`: SHA-256 of `identifierForVendor` + salt. Not PII. Used only for rate limiting.

---

## 10. Apple App Store Compliance

| Requirement | Compliance |
|---|---|
| No medical claims | Neutral descriptions only ("herbal blend", "supplement blend") |
| No substance references | Proxy sanitizes upstream data. SafetyService filters locally. |
| Camera justification | `NSCameraUsageDescription`: "Reflect uses your camera to scan product QR codes for verification." |
| No external URL navigation | QR URLs never opened in browser/webview. Token extracted and resolved via API only. |
| No hidden functionality | QR scanning is visible and documented |
| Data minimization | No user accounts. No server-side user tracking. Tokens stay on-device. |
| No third-party tracking | No analytics SDKs, ad networks, or fingerprinting |

### App Review Notes

> "Reflect includes a product verification feature that allows users to scan QR codes on wellness products to confirm authenticity. Scanned codes are validated against our verification API -- no external URLs are opened. The feature helps users track verified products as part of their wellness routine."

---

## 11. UI Copy

### Scanning

| State | Copy |
|---|---|
| Scan button | "Scan Product" |
| Camera active | "Point your camera at a product QR code" |
| Resolving | "Verifying product..." |

### Success

| State | Copy |
|---|---|
| Verified | "Verified Product" with checkmark badge |
| Add to routine | "Add to My Routine" |
| Save for later | "Save for Later" |
| Confirmation | "Added to your routine" (toast) |

### Errors

| Error | Title | Body |
|---|---|---|
| Invalid QR | "QR Code Not Recognized" | "This doesn't appear to be a product QR code. Only verified product codes can be scanned." |
| Not found | "Product Not Verified" | "This product could not be verified. Only verified products can be linked." |
| Revoked | "No Longer Verified" | "This product is no longer verified and cannot be linked." |
| Rate limited | "Too Many Attempts" | "Please wait a moment before scanning again." |
| Unavailable | "Temporarily Unavailable" | "Product verification is temporarily unavailable. Please try again later." |
| Camera denied | "Camera Access Required" | "To scan product QR codes, allow camera access in Settings." |

### Offline

| State | Copy |
|---|---|
| Offline scan | "Saved for Later" / "We'll verify this product when you're back online." |
| Pending badge | "Pending Verification" |
| Queue resolved | "Product Verified" / "{Name} has been verified and is ready to add to your routine." |
| Queue failed | "Verification Failed" / "We couldn't verify this product. Try scanning again." |

### Routine

| State | Copy |
|---|---|
| Tab header | "My Routine" |
| Empty state | "No products linked yet" / "Scan a product QR code to get started." |
| Log action | "Log Today" |
| Skip action | "Skip" |
| Adherence | "This week: X of Y days" |
| Revoked banner | "This product is no longer verified. It has been removed from your active routine." |

---

## 12. Routine Tracker Integration with Analytics

### Correlation Model

`RoutineLog.loggedAt` correlates with `CheckIn` data from the same day (date-based, not relationship-based). This enables:

1. **Adherence chart**: "Did I follow my routine?" per product, per week
2. **Wellbeing overlay**: Overlay adherence with mood/energy/stress trends on Insights tab
3. **No causal claims**: The app shows correlation only, never attributes outcomes to products

### Privacy

- Product names/tokens never appear in AI prompts
- Routine data never leaves the device
- Insights use anonymized references: "On days when you followed your routine, your average mood was X"
- Export includes routine logs but not product tokens

### Data Relationships

```
VerifiedProduct <-1:many-> RoutineEntry <-1:many-> RoutineLog
CheckIn (correlated by date, not by direct relationship)
```

---

## Decisions Log

| Decision | Choice | Rationale |
|---|---|---|
| Architecture | Thin client, server-authoritative | Simplest, cleanest separation, instant revocation |
| QR domain | `link.reflectapp.com/t/{token}` only | Neutral, controlled, no upstream references |
| API domain | `api.reflectapp.com` | Clean separation from link domain |
| Sync mechanism | Pull-through cache (MVP) | Upstream API exists; no new sync infra needed |
| Routine tracker | Structured (schedules, reminders, adherence) | User preference |
| Issuer model | Single issuer MVP, partner-ready schema | Future flexibility without MVP complexity |
| Encryption | iOS Data Protection (file-level) | Sufficient for threat model; no app-level encryption |
| Product framing | "Verified product" | Authenticity/provenance emphasis |
| Offline handling | Pending queue + stale-while-revalidate | Network required for first scan; graceful degradation |
