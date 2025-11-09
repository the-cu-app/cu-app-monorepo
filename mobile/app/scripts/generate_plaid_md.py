#!/usr/bin/env python3
import os
import sys
import re
from collections import defaultdict

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '.tools')))
try:
    import yaml  # type: ignore
except Exception as e:
    print("PyYAML not available. Please run: python3 -m pip install pyyaml --target ./.tools", file=sys.stderr)
    raise


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
REPO_DIR = os.path.join(ROOT, 'vendor', 'plaid-openapi')
DOCS_DIR = os.path.join(ROOT, 'docs')


def find_spec_file() -> str:
    # Prefer the canonical Plaid spec file name if present
    candidates = [
        os.path.join(REPO_DIR, '2020-09-14.yml'),
        os.path.join(REPO_DIR, 'openapi.yaml'),
        os.path.join(REPO_DIR, 'openapi.yml'),
    ]
    for c in candidates:
        if os.path.exists(c):
            return c
    # Fallback: search any .yml/.yaml at repo root containing 'openapi:' and 'paths:'
    for name in os.listdir(REPO_DIR):
        if not name.lower().endswith(('.yml', '.yaml')):
            continue
        p = os.path.join(REPO_DIR, name)
        try:
            with open(p, 'r', encoding='utf-8') as f:
                head = f.read(2000)
            if 'openapi:' in head and 'paths:' in head:
                return p
        except Exception:
            pass
    raise FileNotFoundError('Could not locate Plaid OpenAPI spec in vendor/plaid-openapi')


def method_order_key(m: str) -> int:
    order = ['post', 'get', 'put', 'patch', 'delete', 'options', 'head']
    try:
        return order.index(m.lower())
    except ValueError:
        return 999


def slugify(text: str) -> str:
    text = re.sub(r'[^a-zA-Z0-9\s/\-]+', '', text)
    text = text.replace('/', ' ').replace('-', ' ')
    text = re.sub(r'\s+', ' ', text)
    return text.strip().lower().replace(' ', '-')


def generate_all_endpoints_md(spec: dict) -> str:
    title = '# Plaid API — Complete Endpoint Index\n'
    version = spec.get('info', {}).get('version', 'unknown')
    intro = (
        f"\nGenerated from plaid-openapi (version: {version}).\n\n"
        "- Base URLs: https://sandbox.plaid.com, https://development.plaid.com, https://production.plaid.com\n"
        "- All endpoints require server-side secret. Do not call from client apps.\n"
        "- Grouped by tag; each bullet shows method, path, and summary.\n\n"
    )

    paths = spec.get('paths', {})
    tag_map = defaultdict(list)  # tag -> list of (tag, method, path, summary, opId, deprecated)

    for path, methods in paths.items():
        if not isinstance(methods, dict):
            continue
        for method, op in methods.items():
            if method.startswith('x-'):
                continue
            if not isinstance(op, dict):
                continue
            if method.lower() not in ['get', 'post', 'put', 'patch', 'delete', 'options', 'head']:
                continue
            tags = op.get('tags') or ['Untagged']
            summary = op.get('summary') or op.get('operationId') or ''
            op_id = op.get('operationId', '')
            deprecated = bool(op.get('deprecated'))
            entry = (method.upper(), path, summary, op_id, deprecated)
            for t in tags:
                tag_map[t].append(entry)

    # Sort tags alphabetically, with some curated ordering for common products first
    preferred = [
        'Link', 'Items', 'Accounts', 'Auth', 'Transactions', 'Balances', 'Identity', 'Institutions',
        'Statements', 'Liabilities', 'Investments', 'Holdings', 'Assets', 'Income', 'Employment',
        'Credit', 'Transfer', 'Signal', 'Categories', 'Webhooks', 'Payment Initiation', 'Processor', 'Sandbox'
    ]
    tag_names = sorted(tag_map.keys())
    ordered_tags = [t for t in preferred if t in tag_map]
    ordered_tags += [t for t in tag_names if t not in ordered_tags]

    lines = [title, intro]
    # Build a small table of contents
    lines.append('## Tags\n')
    for t in ordered_tags:
        lines.append(f"- [{t}](#{slugify(t)})")
    lines.append('')

    for tag in ordered_tags:
        lines.append(f"## {tag}\n")
        entries = tag_map[tag]
        # Sort entries by path then method order
        entries.sort(key=lambda e: (e[1], method_order_key(e[0])))
        for method, path, summary, op_id, deprecated in entries:
            dep = ' — DEPRECATED' if deprecated else ''
            op = f" (opId: `{op_id}`)" if op_id else ''
            lines.append(f"- {method} `{path}`: {summary}{op}{dep}")
        lines.append('')

    return "\n".join(lines).rstrip() + "\n"


def generate_e2e_flows_md() -> str:
    lines = []
    lines.append('# Plaid E2E Flows — Practical Guide\n')
    lines.append('This guide outlines common end-to-end flows and minimal calls, including webhooks and cursors.\n')
    lines.append('Note: All API calls must be server-side with your Plaid secret.\n')

    flows = [
        (
            'Link + Item Creation',
            [
                'POST `/link/token/create` — Create a one-time link token',
                'Launch Link in your client using the link token',
                'Client returns `public_token` → exchange server-side',
                'POST `/item/public_token/exchange` — Receive `access_token`',
                'Store `item_id`/`access_token` securely',
                'Register your webhook URL in the link token or developer dashboard',
            ],
        ),
        (
            'Account Profile',
            [
                'POST `/accounts/get` — Account metadata',
                'POST `/accounts/balance/get` — Realtime balances',
                'POST `/identity/get` — Identity data (if product enabled)',
            ],
        ),
        (
            'Transactions (cursor-based)',
            [
                'POST `/transactions/sync` — Use stored `cursor` for incremental sync',
                'Handle `TRANSACTIONS: INITIAL_UPDATE`, `HISTORICAL_UPDATE`, `DEFAULT_UPDATE` webhooks',
                'Persist added/modified/removed transactions and update the `cursor`',
            ],
        ),
        (
            'Statements (PDF bank statements)',
            [
                'POST `/statements/list` — List available statements',
                'POST `/statements/download` — Download a specific statement (PDF)',
            ],
        ),
        (
            'US ACH Payments',
            [
                'POST `/auth/get` — Account/routing details',
                'POST `/transfer/recipient/create` (if used) + `/transfer/create`',
                'Handle `TRANSFER` webhooks for lifecycle events',
            ],
        ),
        (
            'Income / Employment / Assets',
            [
                'Income: `/income/verification/*`',
                'Employment: `/employment/*`',
                'Assets: `/asset_report/*` + `/asset_report/pdf/get`',
            ],
        ),
        (
            'Error Handling & Re-Link',
            [
                'Detect `ITEM_LOGIN_REQUIRED` and prompt re-link with `/link/token/create` + `access_token`',
                'Rotate `access_token` if needed with `/item/access_token/invalidate`',
            ],
        ),
        (
            'Sandbox Simulation',
            [
                'Use `/sandbox/*` endpoints to set item state, fire webhooks, or create test items',
            ],
        ),
    ]
    for header, steps in flows:
        lines.append(f"## {header}\n")
        for s in steps:
            lines.append(f"- {s}")
        lines.append('')
    return "\n".join(lines).rstrip() + "\n"


def main():
    os.makedirs(DOCS_DIR, exist_ok=True)
    spec_path = find_spec_file()
    with open(spec_path, 'r', encoding='utf-8') as f:
        spec = yaml.safe_load(f)

    all_md = generate_all_endpoints_md(spec)
    with open(os.path.join(DOCS_DIR, 'plaid-openapi-all.md'), 'w', encoding='utf-8') as f:
        f.write(all_md)

    flows_md = generate_e2e_flows_md()
    with open(os.path.join(DOCS_DIR, 'plaid-e2e-flows.md'), 'w', encoding='utf-8') as f:
        f.write(flows_md)

    print('Generated:')
    print(' - docs/plaid-openapi-all.md')
    print(' - docs/plaid-e2e-flows.md')


if __name__ == '__main__':
    main()

