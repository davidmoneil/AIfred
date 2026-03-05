#!/usr/bin/env python3
"""jobsdb.py - SQLite helper for AIfred Jobs shell scripts.

Provides a CLI for executing SQL against jobs.db with JSON output.
Used by msgbus.sh, dispatcher.sh, dashboard.sh, etc. as a replacement
for the sqlite3 CLI (which requires apt install).

Usage:
    jobsdb.py exec "SQL" [param1 param2 ...]   # Execute SQL, return JSON lines
    jobsdb.py exec-scalar "SQL" [params...]     # Return single value
    jobsdb.py exec-raw "SQL" [params...]        # Tab-separated output
    jobsdb.py init                               # Create tables if not exist
    jobsdb.py pragma "PRAGMA command"           # Run a PRAGMA
"""

import json
import os
import sqlite3
import sys

JOBS_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(JOBS_DIR, "state", "jobs.db")


def get_db():
    """Open database with WAL mode."""
    db = sqlite3.connect(DB_PATH)
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("PRAGMA busy_timeout=5000")
    db.row_factory = sqlite3.Row
    return db


def init_db(db):
    """Create tables and indexes if they don't exist."""
    db.executescript("""
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_type TEXT NOT NULL,
            source TEXT NOT NULL,
            actor TEXT NOT NULL DEFAULT 'executor',
            severity TEXT NOT NULL DEFAULT 'info',
            parent_id INTEGER,
            thread_id INTEGER,
            status TEXT NOT NULL DEFAULT 'pending',
            data TEXT NOT NULL DEFAULT '{}',
            created_at TEXT NOT NULL,
            deliver_after TEXT NOT NULL,
            expires_at TEXT
        );

        CREATE TABLE IF NOT EXISTS job_state (
            job TEXT PRIMARY KEY,
            last_run INTEGER NOT NULL DEFAULT 0,
            fail_count INTEGER NOT NULL DEFAULT 0,
            last_failure INTEGER
        );

        CREATE INDEX IF NOT EXISTS idx_events_status_deliver
            ON events (status, deliver_after);
        CREATE INDEX IF NOT EXISTS idx_events_type_status
            ON events (event_type, status);
        CREATE INDEX IF NOT EXISTS idx_events_created
            ON events (created_at DESC);
        CREATE INDEX IF NOT EXISTS idx_events_thread
            ON events (thread_id);
    """)


def _clean_params(params):
    """Convert empty strings to None for proper SQL NULL handling."""
    return [None if p == "" else p for p in params]


def _expand_json_fields(row_dict):
    """Parse known JSON text fields back into objects for output."""
    for key in ("data",):
        if key in row_dict and isinstance(row_dict[key], str):
            try:
                row_dict[key] = json.loads(row_dict[key])
            except (json.JSONDecodeError, TypeError):
                pass
    return row_dict


def cmd_exec(db, sql, params):
    """Execute SQL, output each row as a JSON line."""
    cursor = db.execute(sql, _clean_params(params))
    if cursor.description is None:
        db.commit()
        if cursor.lastrowid:
            print(cursor.lastrowid)
        return
    for row in cursor:
        print(json.dumps(_expand_json_fields(dict(row)), ensure_ascii=False))


def cmd_insert(db, sql, params):
    """Execute INSERT, return lastrowid."""
    cursor = db.execute(sql, _clean_params(params))
    db.commit()
    print(cursor.lastrowid)


def cmd_exec_scalar(db, sql, params):
    """Execute SQL, return single value."""
    cursor = db.execute(sql, _clean_params(params))
    row = cursor.fetchone()
    if row is not None:
        print(row[0] if row[0] is not None else "")
    else:
        print("")


def cmd_exec_raw(db, sql, params):
    """Execute SQL, return tab-separated output."""
    cursor = db.execute(sql, _clean_params(params))
    if cursor.description is None:
        db.commit()
        return
    for row in cursor:
        print("\t".join(str(v) if v is not None else "" for v in row))


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    db = get_db()

    if cmd == "init":
        init_db(db)
        print("OK")
    elif cmd == "exec":
        sql = sys.argv[2] if len(sys.argv) > 2 else ""
        params = sys.argv[3:]
        init_db(db)
        cmd_exec(db, sql, params)
    elif cmd == "insert":
        sql = sys.argv[2] if len(sys.argv) > 2 else ""
        params = sys.argv[3:]
        init_db(db)
        cmd_insert(db, sql, params)
    elif cmd == "exec-scalar":
        sql = sys.argv[2] if len(sys.argv) > 2 else ""
        params = sys.argv[3:]
        init_db(db)
        cmd_exec_scalar(db, sql, params)
    elif cmd == "exec-raw":
        sql = sys.argv[2] if len(sys.argv) > 2 else ""
        params = sys.argv[3:]
        init_db(db)
        cmd_exec_raw(db, sql, params)
    elif cmd == "pragma":
        result = db.execute(sys.argv[2]).fetchone()
        if result:
            print(result[0])
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)

    db.close()


if __name__ == "__main__":
    main()
