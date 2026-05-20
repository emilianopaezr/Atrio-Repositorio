#!/usr/bin/env python3
"""Apply a SQL file to the self-hosted Supabase /pg/query endpoint.

Usage:
    python apply_sql.py <path-to-sql-file> [--key <service-key>]
"""

import argparse
import json
import os
import sys
import urllib.request


URL_BASE = "https://atrioappcloude-atrioappcloude.2rfeor.easypanel.host"


def run_sql(sql: str, key: str, label: str) -> bool:
    body = json.dumps({"query": sql}).encode("utf-8")
    req = urllib.request.Request(
        f"{URL_BASE}/pg/query",
        data=body,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "apikey": key,
            "Authorization": f"Bearer {key}",
        },
    )
    print(f"\n==> {label}")
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            text = resp.read().decode("utf-8")
            print(f"OK ({resp.status})")
            if text and text != "[]":
                print(text[:2000])
            return True
    except urllib.error.HTTPError as e:
        body_resp = e.read().decode("utf-8", errors="replace")
        print(f"FAIL ({e.code}): {body_resp[:1000]}")
        return False
    except Exception as e:
        print(f"FAIL: {e}")
        return False


def main():
    p = argparse.ArgumentParser()
    p.add_argument("sql_file")
    p.add_argument("--key", default=os.environ.get("SUPABASE_SERVICE_KEY"))
    p.add_argument("--admin-email", default=None)
    args = p.parse_args()

    if not args.key:
        print("ERROR: provide --key or set SUPABASE_SERVICE_KEY env var", file=sys.stderr)
        sys.exit(2)

    with open(args.sql_file, "r", encoding="utf-8") as f:
        sql = f.read()

    if not run_sql(sql, args.key, f"Applying {args.sql_file}"):
        sys.exit(1)

    if args.admin_email:
        admin_sql = f"""
UPDATE profiles SET is_admin = TRUE
WHERE id = (SELECT id FROM auth.users WHERE email = '{args.admin_email}');
SELECT id, display_name, is_admin FROM profiles
WHERE id = (SELECT id FROM auth.users WHERE email = '{args.admin_email}');
"""
        run_sql(admin_sql, args.key, f"Marking {args.admin_email} as admin")

    run_sql("NOTIFY pgrst, 'reload schema';", args.key, "Reload PostgREST schema cache")

    health = """
SELECT
  (SELECT EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'kyc')) AS bucket_exists,
  (SELECT COUNT(*)::int FROM profiles WHERE is_admin = TRUE)      AS admin_count,
  (SELECT COUNT(*)::int FROM pg_proc
     WHERE proname IN ('kyc_submit','kyc_approve','kyc_reject','kyc_list_pending')) AS rpc_count;
"""
    run_sql(health, args.key, "Health check")


if __name__ == "__main__":
    main()
