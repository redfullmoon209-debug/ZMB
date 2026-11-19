-- PostgreSQL draft for the future authenticated ZMB server. Not used by the
-- offline Godot build. Apply only on a dedicated server database.
-- Clients must never receive database credentials or write these tables.
CREATE TABLE zmb_account (
    account_id uuid PRIMARY KEY,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE zmb_session (
    session_id uuid PRIMARY KEY,
    account_id uuid NOT NULL REFERENCES zmb_account(account_id),
    started_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    last_heartbeat_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    ended_at timestamptz,
    verified_online_seconds bigint NOT NULL DEFAULT 0 CHECK (verified_online_seconds >= 0),
    CHECK (last_heartbeat_at >= started_at),
    CHECK (ended_at IS NULL OR ended_at >= last_heartbeat_at)
);
-- Prevent concurrent sessions from multiplying recorded time.
CREATE UNIQUE INDEX zmb_one_open_session ON zmb_session(account_id) WHERE ended_at IS NULL;

CREATE TABLE zmb_session_heartbeat (
    session_id uuid NOT NULL REFERENCES zmb_session(session_id),
    sequence_no bigint NOT NULL CHECK (sequence_no >= 0),
    received_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    credited_seconds integer NOT NULL CHECK (credited_seconds BETWEEN 0 AND 30),
    PRIMARY KEY (session_id, sequence_no)
);

CREATE TABLE zmb_progression_event (
    event_id uuid PRIMARY KEY,
    session_id uuid NOT NULL REFERENCES zmb_session(session_id),
    character_id uuid NOT NULL,
    recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    event_kind text NOT NULL CHECK (event_kind IN ('combat','quest','reward','gm','adjustment')),
    level_before integer NOT NULL CHECK (level_before >= 1),
    level_after integer NOT NULL CHECK (level_after >= 1),
    exp_delta bigint NOT NULL,
    source_reference text NOT NULL,
    UNIQUE (session_id, source_reference)
);
CREATE INDEX zmb_progression_session_time ON zmb_progression_event(session_id, recorded_at);

CREATE VIEW zmb_account_playtime AS
SELECT a.account_id, a.created_at,
       COALESCE(SUM(s.verified_online_seconds), 0)::bigint AS verified_online_seconds,
       MIN(s.started_at) AS first_login_at,
       MAX(s.last_heartbeat_at) AS last_seen_at
FROM zmb_account a LEFT JOIN zmb_session s ON s.account_id = a.account_id
GROUP BY a.account_id, a.created_at;

-- A signal for GM review, not a ban. Impossible timestamps should never be
-- produced by the production server; investigate before taking action.
CREATE VIEW zmb_account_time_anomalies AS
SELECT p.*, EXTRACT(EPOCH FROM (clock_timestamp() - p.created_at)) AS account_age_seconds
FROM zmb_account_playtime p
WHERE p.verified_online_seconds > EXTRACT(EPOCH FROM (clock_timestamp() - p.created_at))
   OR p.first_login_at < p.created_at;

CREATE FUNCTION zmb_protect_account_creation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.created_at IS DISTINCT FROM OLD.created_at THEN
        RAISE EXCEPTION 'account creation timestamp is immutable';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER zmb_account_creation_immutable BEFORE UPDATE ON zmb_account
FOR EACH ROW EXECUTE FUNCTION zmb_protect_account_creation();

-- Only the server transaction layer may grant runtime access. Registration
-- creates the UTC timestamp; heartbeat updates credit bounded elapsed time
-- once per authenticated session. A late heartbeat closes the old session
-- instead of crediting disconnected time. Progression and GM actions must
-- create a deduplicated event in the same transaction as the gameplay change.
-- Keep audit rows append-only to game roles; protect account creation fields.
