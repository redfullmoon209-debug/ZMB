# Account time and progression audit (production contract)

The Godot Web demo has no authentication or dedicated server. `account_audit.sql` is a PostgreSQL schema draft for the future backend, not a deployed service. The browser's local playtime is display-only and is not trusted for fraud investigations.

## Server rules

1. Registration creates a server-generated account UUID and UTC creation timestamp. Never accept the date from a client or permit ordinary game roles to change it.
2. Authenticated entry opens one session per account. The server issues the session ID and records start time. On reconnect, close an expired session first.
3. The authenticated game connection sends a heartbeat every 15 seconds. Under a row lock, reject duplicate/out-of-order sequence numbers, calculate elapsed time from the server clock, and credit at most 30 seconds per accepted heartbeat. Close sessions idle longer than 30 seconds without crediting their disconnected gap. Store the heartbeat and update the session total atomically; retrying the same event must not add time twice.
4. On logout or disconnect, close the session with the last verified timestamp. The authoritative online duration is the sum of verified session seconds. Never accept a total, a character level, or EXP gain supplied by the client.
5. Every server-validated EXP/level transaction records its session, character, reason, UTC timestamp, before/after level, and EXP delta. Deduplicate using the server-generated source ID. Record legitimate GM adjustments and event bonuses in the same ledger.
6. The character UI receives account creation, first/last login, and verified total seconds from an authenticated read-only endpoint. GM review compares recorded age, online hours, EXP per hour, level progression, and legitimate rewards. Flag impossible or unusual rates for review; short playtime alone never proves cheating. Thresholds must be calibrated after the actual leveling curve and events are implemented.

No credentials or GM permissions are embedded in the Web client. Deploy the schema and authenticated server separately before public online play.
