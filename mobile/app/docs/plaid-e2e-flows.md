# Plaid E2E Flows — Practical Guide

This guide outlines common end-to-end flows and minimal calls, including webhooks and cursors.

Note: All API calls must be server-side with your Plaid secret.

## Link + Item Creation

- POST `/link/token/create` — Create a one-time link token
- Launch Link in your client using the link token
- Client returns `public_token` → exchange server-side
- POST `/item/public_token/exchange` — Receive `access_token`
- Store `item_id`/`access_token` securely
- Register your webhook URL in the link token or developer dashboard

## Account Profile

- POST `/accounts/get` — Account metadata
- POST `/accounts/balance/get` — Realtime balances
- POST `/identity/get` — Identity data (if product enabled)

## Transactions (cursor-based)

- POST `/transactions/sync` — Use stored `cursor` for incremental sync
- Handle `TRANSACTIONS: INITIAL_UPDATE`, `HISTORICAL_UPDATE`, `DEFAULT_UPDATE` webhooks
- Persist added/modified/removed transactions and update the `cursor`

## Statements (PDF bank statements)

- POST `/statements/list` — List available statements
- POST `/statements/download` — Download a specific statement (PDF)

## US ACH Payments

- POST `/auth/get` — Account/routing details
- POST `/transfer/recipient/create` (if used) + `/transfer/create`
- Handle `TRANSFER` webhooks for lifecycle events

## Income / Employment / Assets

- Income: `/income/verification/*`
- Employment: `/employment/*`
- Assets: `/asset_report/*` + `/asset_report/pdf/get`

## Error Handling & Re-Link

- Detect `ITEM_LOGIN_REQUIRED` and prompt re-link with `/link/token/create` + `access_token`
- Rotate `access_token` if needed with `/item/access_token/invalidate`

## Sandbox Simulation

- Use `/sandbox/*` endpoints to set item state, fire webhooks, or create test items
