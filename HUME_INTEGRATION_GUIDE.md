# HUME EVI Integration Guide for OneScope
## Connect SHEESH-pay-ai IVR System to CU-OS

**Date:** 2025-11-08

---

## What We Built

**OneScope Component:** `/Users/kylekusche/Downloads/cu-app/components/apps/onescope.tsx`

Features:
- ✅ Role-based permission system (Admin, Manager, Teller, Member Advocate)
- ✅ Live IVR session monitoring
- ✅ Real-time transcript display
- ✅ Transaction approval workflow
- ✅ Member context cards with session-based access
- ✅ Permission-gated UI (shows/hides based on role)

**Currently:** Uses mock data to demonstrate workflow

**Next:** Connect to real HUME EVI backend

---

## HUME Backend Location

**Source:** `/Users/kylekusche/Desktop/SHEESH-pay-ai/`

**Key Files:**
- `server.js` - Express server with IVR endpoints
- `services/hume-service.js` - HUME EVI WebSocket connection
- `services/transaction-service.js` - Banking operations
- `routes/ivr.js` - Twilio webhook handlers
- `routes/api.js` - Banking API endpoints

**Database:** SQLite (`sheesh.db`)

Tables:
- `members` - Member accounts
- `accounts` - Bank accounts (checking, savings)
- `transactions` - All transactions with double-entry bookkeeping
- `transfer_pairs` - Links paired transactions
- `ivr_sessions` - Call session tracking

---

## Architecture

```
Member calls CU → Twilio → OneScope Backend
                                ↓
                        /ivr/incoming (webhook)
                                ↓
                        Create IVR session
                                ↓
                        Connect to HUME EVI
                                ↓
                        HUME greets member
                                ↓
┌───────────────────────────────┴───────────────────────────────┐
│                                                                 │
│  Member speaks                    Employee (in OneScope UI)    │
│      ↓                                    ↓                     │
│  HUME understands              Sees real-time notification     │
│      ↓                                    ↓                     │
│  HUME calls tool              Views member context card        │
│  (check_balance)                          ↓                     │
│      ↓                          Approves/denies transaction    │
│  Return balance                           ↓                     │
│      ↓                          Response sent to HUME          │
│  HUME speaks result                       ↓                     │
│                               Transaction processed             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step 1: Copy SHEESH Backend to CU-OS

**Option A: Integrate into Next.js API Routes**

```bash
# Create API routes in CU-OS
mkdir -p /Users/kylekusche/Downloads/cu-app/app/api/ivr
mkdir -p /Users/kylekusche/Downloads/cu-app/app/api/banking

# Copy service layer
cp -r /Users/kylekusche/Desktop/SHEESH-pay-ai/services \
      /Users/kylekusche/Downloads/cu-app/lib/

# Adapt for Next.js App Router
```

**File: `app/api/ivr/incoming/route.ts`**
```typescript
import { NextRequest, NextResponse } from 'next/server'
import twilio from 'twilio'

export async function POST(request: NextRequest) {
  const formData = await request.formData()
  const from = formData.get('From') as string
  const callSid = formData.get('CallSid') as string

  // Create IVR session in Supabase
  const { data: session } = await supabase
    .from('ivr_sessions')
    .insert({
      call_sid: callSid,
      phone_number: from,
      status: 'active',
      started_at: new Date()
    })
    .select()
    .single()

  // Broadcast to OneScope (for employee monitoring)
  await supabase.channel('ivr-sessions').send({
    type: 'broadcast',
    event: 'new_session',
    payload: session
  })

  // Connect to HUME EVI
  const twiml = new twilio.twiml.VoiceResponse()

  twiml.say({
    voice: 'Polly.Joanna'
  }, 'Connecting you to our voice assistant...')

  twiml.connect().stream({
    url: `wss://${process.env.DOMAIN}/api/ivr/media-stream`,
    parameters: {
      sessionId: session.id,
      from: from
    }
  })

  return new NextResponse(twiml.toString(), {
    headers: { 'Content-Type': 'text/xml' }
  })
}
```

**File: `app/api/ivr/media-stream/route.ts`**
```typescript
import { Server } from 'ws'
import { HumeClient } from 'hume'

export async function GET(request: NextRequest) {
  // Upgrade to WebSocket
  const upgrade = request.headers.get('upgrade')
  if (upgrade !== 'websocket') {
    return new NextResponse('Expected WebSocket', { status: 426 })
  }

  // Handle WebSocket connection
  const wss = new Server({ noServer: true })

  wss.on('connection', async (twilioWs, req) => {
    const params = new URLSearchParams(req.url?.split('?')[1])
    const sessionId = params.get('sessionId')

    // Connect to HUME
    const hume = new HumeClient({
      apiKey: process.env.HUME_API_KEY
    })

    const socket = await hume.empathicVoice.chat.connect({
      configId: process.env.HUME_CONFIG_ID,
    })

    // Tools HUME can call
    socket.on('tool_call', async (toolCall) => {
      if (toolCall.name === 'check_balance') {
        const { account_type } = toolCall.parameters

        // Get member from session
        const { data: session } = await supabase
          .from('ivr_sessions')
          .select('*, member_id')
          .eq('id', sessionId)
          .single()

        // Query Supabase for balance
        const { data: account } = await supabase
          .from('accounts')
          .select('balance, available_balance')
          .eq('member_id', session.member_id)
          .eq('type', account_type)
          .single()

        // Return to HUME
        socket.sendToolResult({
          tool_call_id: toolCall.id,
          content: JSON.stringify(account)
        })
      }

      if (toolCall.name === 'transfer_funds') {
        const { from_account, to_account, amount } = toolCall.parameters

        // Get session
        const { data: session } = await supabase
          .from('ivr_sessions')
          .select('*')
          .eq('id', sessionId)
          .single()

        // Create approval request
        const { data: approval } = await supabase
          .from('approval_requests')
          .insert({
            session_id: sessionId,
            member_id: session.member_id,
            type: 'transfer',
            amount,
            from_account,
            to_account,
            status: 'pending'
          })
          .select()
          .single()

        // Notify available tellers via real-time
        await supabase.channel('teller-queue').send({
          type: 'broadcast',
          event: 'approval_needed',
          payload: approval
        })

        // Wait for teller approval (with timeout)
        const result = await waitForApproval(approval.id, 60000)

        if (result.approved) {
          // Process transfer
          const transaction = await processTransfer({
            member_id: session.member_id,
            from_account,
            to_account,
            amount,
            approved_by: result.employee_id
          })

          socket.sendToolResult({
            tool_call_id: toolCall.id,
            content: JSON.stringify({
              success: true,
              transaction_id: transaction.id,
              message: `Transfer complete. $${amount} moved from ${from_account} to ${to_account}.`
            })
          })
        } else {
          socket.sendToolResult({
            tool_call_id: toolCall.id,
            content: JSON.stringify({
              success: false,
              error: 'Transfer denied by teller',
              reason: result.denial_reason
            })
          })
        }
      }
    })

    // Relay audio between Twilio and HUME
    twilioWs.on('message', (message) => {
      const msg = JSON.parse(message.toString())

      if (msg.event === 'media') {
        // Forward audio to HUME
        socket.sendAudio(Buffer.from(msg.media.payload, 'base64'))
      }
    })

    socket.on('audio_output', (audio) => {
      // Forward HUME's audio to Twilio
      twilioWs.send(JSON.stringify({
        event: 'media',
        media: {
          payload: audio.toString('base64')
        }
      }))
    })

    // Update transcript in real-time
    socket.on('message', async (message) => {
      if (message.type === 'user_message' || message.type === 'assistant_message') {
        // Store transcript in Supabase
        await supabase
          .from('ivr_transcripts')
          .insert({
            session_id: sessionId,
            speaker: message.type === 'user_message' ? 'Member' : 'HUME',
            text: message.content,
            timestamp: new Date()
          })

        // Broadcast to OneScope UI
        await supabase.channel(`session-${sessionId}`).send({
          type: 'broadcast',
          event: 'transcript_update',
          payload: {
            speaker: message.type === 'user_message' ? 'Member' : 'HUME',
            text: message.content,
            time: new Date().toLocaleTimeString()
          }
        })
      }
    })
  })
}
```

---

## Step 2: Update OneScope to Use Real-Time Data

**File: `components/apps/onescope.tsx`**

Replace mock data with Supabase real-time subscriptions:

```typescript
"use client"

import { useState, useEffect } from "react"
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'

export function OneScope() {
  const [role, setRole] = useState<EmployeeRole>("teller")
  const [sessions, setSessions] = useState<IVRSession[]>([])
  const supabase = createClientComponentClient()

  useEffect(() => {
    // Load active sessions
    const loadSessions = async () => {
      const { data } = await supabase
        .from('ivr_sessions')
        .select(`
          *,
          member:members(*),
          approval_requests(*)
        `)
        .eq('status', 'active')
        .order('started_at', { ascending: false })

      setSessions(data || [])
    }

    loadSessions()

    // Subscribe to real-time updates
    const channel = supabase
      .channel('ivr-sessions')
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'ivr_sessions'
      }, (payload) => {
        if (payload.eventType === 'INSERT') {
          setSessions(prev => [payload.new, ...prev])
        } else if (payload.eventType === 'UPDATE') {
          setSessions(prev =>
            prev.map(s => s.id === payload.new.id ? payload.new : s)
          )
        } else if (payload.eventType === 'DELETE') {
          setSessions(prev => prev.filter(s => s.id !== payload.old.id))
        }
      })
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [])

  // Rest of component...
}
```

---

## Step 3: Implement Approval Workflow

**File: `components/apps/onescope/approval-buttons.tsx`**

```typescript
"use client"

import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'

interface ApprovalButtonsProps {
  approvalId: string
  sessionId: string
  employeeId: string
}

export function ApprovalButtons({ approvalId, sessionId, employeeId }: ApprovalButtonsProps) {
  const supabase = createClientComponentClient()

  const handleApprove = async () => {
    // Update approval request
    const { data } = await supabase
      .from('approval_requests')
      .update({
        status: 'approved',
        approved_by: employeeId,
        approved_at: new Date()
      })
      .eq('id', approvalId)
      .select()
      .single()

    // Process the transfer
    await fetch('/api/banking/transfer', {
      method: 'POST',
      body: JSON.stringify({
        approval_id: approvalId,
        employee_id: employeeId
      })
    })

    // HUME will receive this via real-time subscription and respond to member
  }

  const handleDeny = async () => {
    const reason = prompt('Reason for denial:')

    await supabase
      .from('approval_requests')
      .update({
        status: 'denied',
        denied_by: employeeId,
        denial_reason: reason,
        denied_at: new Date()
      })
      .eq('id', approvalId)
  }

  return (
    <div className="flex gap-3">
      <button
        onClick={handleApprove}
        className="flex-1 px-6 py-3 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-semibold"
      >
        ✓ Approve Transaction
      </button>
      <button
        onClick={handleDeny}
        className="flex-1 px-6 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-semibold"
      >
        ✗ Deny Transaction
      </button>
    </div>
  )
}
```

---

## Step 4: Supabase Database Schema

**Create these tables:**

```sql
-- IVR Sessions
CREATE TABLE ivr_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  call_sid TEXT UNIQUE NOT NULL,
  member_id UUID REFERENCES members(id),
  phone_number TEXT,
  status TEXT DEFAULT 'active', -- active, completed, failed
  assigned_employee_id UUID REFERENCES employees(id),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  duration INTEGER, -- seconds
  tenant_id UUID REFERENCES tenants(id)
);

-- Approval Requests
CREATE TABLE approval_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID REFERENCES ivr_sessions(id),
  member_id UUID REFERENCES members(id),
  type TEXT, -- transfer, withdrawal, etc.
  amount DECIMAL(10,2),
  from_account TEXT,
  to_account TEXT,
  status TEXT DEFAULT 'pending', -- pending, approved, denied
  approved_by UUID REFERENCES employees(id),
  denied_by UUID REFERENCES employees(id),
  denial_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  approved_at TIMESTAMPTZ,
  denied_at TIMESTAMPTZ
);

-- IVR Transcripts
CREATE TABLE ivr_transcripts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID REFERENCES ivr_sessions(id),
  speaker TEXT, -- Member, HUME, Employee
  text TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Actions (Audit)
CREATE TABLE ivr_employee_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID REFERENCES employees(id),
  member_id UUID REFERENCES members(id),
  session_id UUID REFERENCES ivr_sessions(id),
  action TEXT, -- viewed_balance, approved_transfer, denied_transfer
  amount DECIMAL(10,2),
  ip_address TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS Policies:**

```sql
-- Tellers can only access sessions assigned to them
CREATE POLICY "tellers_assigned_sessions" ON ivr_sessions
FOR SELECT
USING (
  auth.role() = 'teller' AND
  assigned_employee_id = auth.uid() AND
  status = 'active'
);

-- Managers can see all department sessions
CREATE POLICY "managers_department_sessions" ON ivr_sessions
FOR SELECT
USING (
  auth.role() = 'manager' AND
  EXISTS (
    SELECT 1 FROM employees
    WHERE id = assigned_employee_id
    AND department_id = (SELECT department_id FROM employees WHERE id = auth.uid())
  )
);

-- Admins see everything
CREATE POLICY "admins_all_sessions" ON ivr_sessions
FOR SELECT
USING (auth.role() = 'admin');
```

---

## Step 5: HUME Configuration

**Get HUME API Key:** https://platform.hume.ai/

**Create HUME EVI Config:**

```json
{
  "name": "CU Banking Assistant",
  "voice": {
    "provider": "HUME_AI",
    "name": "ITO"
  },
  "language_model": {
    "model_provider": "ANTHROPIC",
    "model_resource": "claude-3-5-sonnet-20241022",
    "temperature": 0.7
  },
  "system_prompt": "You are a helpful banking assistant for a credit union. You help members check balances, transfer funds, and answer account questions. Always be polite, empathetic, and secure. For transactions over $500, you must request teller approval. Never share sensitive information unless the member has been properly authenticated.",
  "tools": [
    {
      "name": "check_balance",
      "description": "Check the balance of a member's account",
      "parameters": {
        "type": "object",
        "properties": {
          "account_type": {
            "type": "string",
            "enum": ["checking", "savings", "money_market"],
            "description": "The type of account to check"
          }
        },
        "required": ["account_type"]
      }
    },
    {
      "name": "get_recent_transactions",
      "description": "Get the last 5 transactions for an account",
      "parameters": {
        "type": "object",
        "properties": {
          "account_type": {
            "type": "string",
            "enum": ["checking", "savings"],
            "description": "The account to get transactions for"
          }
        },
        "required": ["account_type"]
      }
    },
    {
      "name": "transfer_funds",
      "description": "Transfer money between member accounts. REQUIRES TELLER APPROVAL for amounts over $500.",
      "parameters": {
        "type": "object",
        "properties": {
          "from_account": {
            "type": "string",
            "enum": ["checking", "savings"],
            "description": "Account to transfer from"
          },
          "to_account": {
            "type": "string",
            "enum": ["checking", "savings"],
            "description": "Account to transfer to"
          },
          "amount": {
            "type": "number",
            "description": "Amount to transfer in dollars"
          }
        },
        "required": ["from_account", "to_account", "amount"]
      }
    }
  ]
}
```

---

## Step 6: Test the Integration

**1. Start CU-OS:**
```bash
cd /Users/kylekusche/Downloads/cu-app
npm run dev
```

**2. Start HUME-enabled backend:**
```bash
cd /Users/kylekusche/Downloads/cu-app
node server.js  # or integrate into Next.js
```

**3. Configure Twilio webhook:**
- Webhook URL: `https://your-domain.com/api/ivr/incoming`
- Method: POST

**4. Test call flow:**
1. Call your Twilio number
2. HUME greets you
3. Say "What's my checking balance?"
4. HUME calls `check_balance` tool
5. Backend queries Supabase
6. HUME responds with balance
7. Say "Transfer $500 to savings"
8. HUME requests teller approval
9. OneScope UI shows notification
10. Teller approves in UI
11. Backend processes transfer
12. HUME confirms to member

**5. Watch in OneScope:**
- Open CU-OS (localhost:3000)
- Click OneScope icon
- See live IVR session appear
- Click session to view transcript
- Approve transaction
- See member context card
- Switch roles to test permissions

---

## Environment Variables

**`.env.local`:**
```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-key

# HUME
HUME_API_KEY=your-hume-api-key
HUME_CONFIG_ID=your-config-id

# Twilio
TWILIO_ACCOUNT_SID=your-account-sid
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_PHONE_NUMBER=+18137365086

# App
DOMAIN=your-domain.com
```

---

## Security Checklist

- [ ] Employee authentication required for all IVR endpoints
- [ ] RLS policies enforced on Supabase tables
- [ ] Session-based member data access (auto-expires)
- [ ] Audit logging for all employee actions
- [ ] Rate limiting on IVR endpoints
- [ ] IP whitelisting for Twilio/HUME
- [ ] Encrypted WebSocket connections (WSS)
- [ ] PCI DSS compliance for payment data
- [ ] 7-year retention for call recordings
- [ ] HTTPS only (no HTTP)

---

## Next Steps

1. **Copy backend code from SHEESH-pay-ai**
2. **Create Supabase tables + RLS policies**
3. **Set up HUME EVI account**
4. **Configure Twilio webhooks**
5. **Test with demo member account**
6. **Add real-time subscriptions to OneScope UI**
7. **Implement approval workflow**
8. **Add compliance monitoring**
9. **Set up call recording storage**
10. **Load test with 100+ concurrent calls**

---

**Ready to integrate!** The OneScope UI is fully built and waiting for real data from HUME EVI + Supabase.
