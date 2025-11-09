# Comprehensive FAQ System - Complete Guide

## 🎯 Overview

The **Comprehensive FAQ System** generates AI-powered, audience-specific knowledge bases for every stakeholder in the white-label CU banking platform:

- 👥 **Member FAQs** - End users of the mobile banking app
- 🏦 **Staff Training FAQs** - CU employees helping members
- 💻 **Developer FAQs** - Platform developers and integrators
- 🎨 **Design FAQs** - UI/UX designers creating CU-branded experiences
- 🔒 **Security/Compliance FAQs** - Security teams and auditors

---

## ✨ Key Features

✅ **Multi-Audience Support** - 5 different audience types with custom content
✅ **CU-Specific Branding** - Member/staff FAQs tailored to each credit union
✅ **AI-Generated Content** - GPT-4 Turbo generates comprehensive, professional FAQs
✅ **Full-Text Search** - PostgreSQL FTS with GIN indexes for fast searches
✅ **Category Organization** - 9 categories per audience type
✅ **Batch Processing** - Generate FAQs for 200+ CUs automatically
✅ **RLS Security** - Row-level security ensures proper access control

---

## 📊 Database Schema

### 5 FAQ Tables

```sql
member_faqs               -- CU-specific member FAQs
staff_training_faqs       -- CU-specific staff training
developer_faqs            -- Platform-wide developer docs
design_faqs               -- Platform-wide design system docs
security_compliance_faqs  -- Platform-wide security/compliance
```

### Common Fields

All tables include:
- `id` - UUID primary key
- `category` - FAQ category (enum)
- `question` - The FAQ question
- `answer` - Detailed answer
- `tags` - Array of searchable tags
- `display_order` - Sort order
- `created_at` / `updated_at` - Timestamps

### Audience-Specific Fields

**Member FAQs:**
- `cu_id` - Credit union identifier
- `search_keywords` - Additional search terms
- `is_featured` - Featured on dashboard
- `view_count` - Analytics
- `helpful_count` - User feedback

**Staff Training FAQs:**
- `cu_id` - Credit union identifier
- `role` - Staff role (teller, manager, etc.)
- `escalation_procedure` - When/how to escalate
- `related_policies` - Links to policy documents
- `is_mandatory_training` - Required training flag

**Developer FAQs:**
- `difficulty_level` - beginner/intermediate/advanced
- `code_example` - Code snippets
- `programming_language` - Language for code examples
- `related_docs` - Links to documentation
- `is_deprecated` - Deprecated flag

**Design FAQs:**
- `tool` - Design tool (Figma, Sketch, etc.)
- `visual_example_url` - Screenshots/mockups
- `figma_file_url` - Link to Figma file

**Security/Compliance FAQs:**
- `regulation` - GDPR, CCPA, PCI-DSS, etc.
- `severity_level` - low/medium/high/critical
- `policy_reference` - Official policy link
- `audit_trail_location` - Where to find audit logs
- `compliance_framework` - Array of frameworks (SOC2, ISO27001, etc.)

---

## 🚀 Quick Start

### 1. Deploy Edge Function

```bash
cd cu_core_banking_app

# Set OpenAI API key
supabase secrets set OPENAI_API_KEY=sk-...

# Deploy function
supabase functions deploy generate-faqs
```

### 2. Run Database Migration

```bash
# Create all 5 FAQ tables
supabase db push
```

### 3. Generate FAQs

```bash
# Generate member FAQs for Navy Federal
python scripts/generate_faqs.py member --cu-id navyfederal

# Generate all FAQs for BECU
python scripts/generate_faqs.py all --cu-id becu

# Generate developer FAQs (platform-wide)
python scripts/generate_faqs.py developer
```

---

## 📖 Usage Examples

### Generate Member FAQs

```bash
# All categories
python scripts/generate_faqs.py member --cu-id navyfederal

# Specific categories only
python scripts/generate_faqs.py member \
  --cu-id navyfederal \
  --categories login transfers deposits \
  --count 15
```

**Output:**
```
🚀 Generating MEMBER FAQs...
📍 CU ID: navyfederal
📂 Categories: login, transfers, deposits
🔢 Count per category: 15

✅ Success! Generated 45 FAQs across 3 categories
🏦 Credit Union: Navy Federal Credit Union
```

### Generate Staff Training FAQs

```bash
python scripts/generate_faqs.py staff \
  --cu-id becu \
  --categories account_help technical escalation
```

### Generate Developer FAQs

```bash
# Platform-wide (no CU ID needed)
python scripts/generate_faqs.py developer \
  --categories api database authentication
```

### Generate All Audiences for a CU

```bash
python scripts/generate_faqs.py all --cu-id golden1
```

Generates:
- ✅ Member FAQs (9 categories)
- ✅ Staff Training FAQs (7 categories)

### Batch Generate for Multiple CUs

```bash
python scripts/generate_faqs.py batch \
  --cu-ids navyfederal becu golden1 penfed alliant \
  --count 10
```

---

## 🔍 Searching FAQs

### Full-Text Search

```sql
-- Search member FAQs
SELECT * FROM search_member_faqs(
  'navyfederal',
  'password reset',
  NULL  -- category filter (optional)
);

-- Direct full-text search
SELECT * FROM member_faqs
WHERE cu_id = 'navyfederal'
  AND to_tsvector('english', question || ' ' || answer) @@ plainto_tsquery('english', 'mobile deposit');
```

### Tag-Based Search

```sql
-- Find FAQs by tag
SELECT * FROM member_faqs
WHERE 'security' = ANY(tags)
ORDER BY helpful_count DESC;
```

### Featured FAQs

```sql
-- Get top 5 featured FAQs
SELECT * FROM get_featured_faqs('navyfederal', 5);
```

---

## 🎨 Category Reference

### Member FAQ Categories (9 total)

| Category | Description | Example Questions |
|----------|-------------|-------------------|
| `login` | Authentication | "How do I reset my password?" |
| `accounts` | Account management | "How do I view my account balances?" |
| `transfers` | Money movement | "How long do transfers take?" |
| `bill_pay` | Bill payments | "How do I set up bill pay?" |
| `deposits` | Mobile deposits | "What's the check deposit limit?" |
| `cards` | Card management | "How do I freeze my debit card?" |
| `security` | Security features | "How does 2FA work?" |
| `settings` | App preferences | "How do I change my notification settings?" |
| `troubleshooting` | Common issues | "Why can't I log in?" |

### Staff Training Categories (7 total)

| Category | Description |
|----------|-------------|
| `account_help` | Helping members with accounts |
| `technical` | Troubleshooting app issues |
| `compliance` | Regulatory compliance |
| `verification` | Identity verification |
| `escalation` | When to escalate |
| `products` | Product knowledge |
| `system_limits` | Transaction limits |

### Developer Categories (7 total)

| Category | Description |
|----------|-------------|
| `api` | API endpoints, auth |
| `deployment` | Edge Functions, CI/CD |
| `customization` | CU-specific customizations |
| `database` | Schema, RLS, migrations |
| `authentication` | JWT, OAuth, sessions |
| `performance` | Optimization, caching |
| `troubleshooting` | Debugging, errors |

### Design Categories (7 total)

| Category | Description |
|----------|-------------|
| `tokens` | Design token system |
| `components` | UI component library |
| `figma` | Figma integration |
| `branding` | CU branding guidelines |
| `accessibility` | WCAG compliance |
| `responsive` | Responsive design |
| `composition` | Layout composition |

### Security/Compliance Categories (7 total)

| Category | Description |
|----------|-------------|
| `encryption` | Data encryption standards |
| `audit` | Audit logging, trails |
| `compliance` | GDPR, CCPA, PCI-DSS |
| `access_control` | RLS, permissions, roles |
| `incident_response` | Security incidents |
| `penetration_testing` | Pen testing procedures |
| `vulnerability` | CVE management |

---

## 🔐 Access Control (RLS Policies)

```sql
-- Members can only read their CU's FAQs
CREATE POLICY "Members can read their CU's FAQs"
ON member_faqs FOR SELECT TO authenticated
USING (cu_id = (SELECT cu_id FROM user_profiles WHERE id = auth.uid()));

-- Staff can only read their CU's training materials
CREATE POLICY "Staff can read their CU's training FAQs"
ON staff_training_faqs FOR SELECT TO authenticated
USING (
  cu_id = (SELECT cu_id FROM user_profiles WHERE id = auth.uid())
  AND role IN ('staff', 'admin', 'manager')
);

-- All developers can read platform FAQs
CREATE POLICY "Developers can read all developer FAQs"
ON developer_faqs FOR SELECT TO authenticated
USING (true);

-- Security teams can read compliance FAQs
CREATE POLICY "Security teams can read compliance FAQs"
ON security_compliance_faqs FOR SELECT TO authenticated
USING (role IN ('admin', 'security', 'compliance'));
```

---

## 💰 Cost Estimation

### AI Generation Costs

| Audience | FAQs per CU | Categories | Cost per CU | 200 CUs Total |
|----------|-------------|------------|-------------|---------------|
| Member | 90 (10/cat × 9) | 9 | ~$3.00 | $600 |
| Staff | 70 (10/cat × 7) | 7 | ~$1.50 | $300 |
| Developer | 70 | 7 | $1.50 (one-time) | $1.50 |
| Design | 70 | 7 | $1.50 (one-time) | $1.50 |
| Security | 70 | 7 | $1.50 (one-time) | $1.50 |

**Total First Generation:** ~$906
**Per CU (Member + Staff):** ~$4.50
**Regeneration:** Free (cached)

---

## 📊 Analytics & Metrics

### Track FAQ Engagement

```sql
-- Increment view count
SELECT increment_faq_view('faq-uuid');

-- Mark FAQ as helpful
SELECT mark_faq_helpful('faq-uuid');

-- Get most viewed FAQs
SELECT question, view_count, helpful_count
FROM member_faqs
WHERE cu_id = 'navyfederal'
ORDER BY view_count DESC
LIMIT 10;

-- Calculate helpfulness ratio
SELECT
  question,
  helpful_count,
  view_count,
  CASE
    WHEN view_count > 0 THEN (helpful_count::FLOAT / view_count * 100)
    ELSE 0
  END AS helpfulness_percentage
FROM member_faqs
WHERE view_count > 100
ORDER BY helpfulness_percentage DESC;
```

---

## 🎯 Integration Examples

### Flutter In-App FAQ Widget

```dart
// Display member FAQs in app
class FAQWidget extends StatelessWidget {
  final String cuId;
  final String? category;

  Future<List<FAQ>> _loadFAQs() async {
    final response = await supabase
      .from('member_faqs')
      .select()
      .eq('cu_id', cuId)
      .eq('category', category ?? 'general')
      .order('helpful_count', ascending: false)
      .limit(10);

    return response.map((json) => FAQ.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FAQ>>(
      future: _loadFAQs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final faq = snapshot.data![index];
            return ExpansionTile(
              title: Text(faq.question),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(faq.answer),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
```

### Next.js Staff Portal

```typescript
// pages/staff/faqs.tsx
import { createServerSupabaseClient } from '@supabase/auth-helpers-nextjs'

export async function getServerSideProps(context) {
  const supabase = createServerSupabaseClient(context)

  const { data: faqs } = await supabase
    .from('staff_training_faqs')
    .select('*')
    .eq('cu_id', context.req.cookies.cu_id)
    .order('is_mandatory_training', { ascending: false })

  return { props: { faqs } }
}

export default function StaffFAQs({ faqs }) {
  return (
    <div>
      <h1>Staff Training FAQs</h1>
      {faqs.map(faq => (
        <div key={faq.id} className="faq-card">
          <h3>{faq.question}</h3>
          <p>{faq.answer}</p>
          {faq.escalation_procedure && (
            <div className="escalation">
              <strong>Escalation:</strong> {faq.escalation_procedure}
            </div>
          )}
        </div>
      ))}
    </div>
  )
}
```

---

## 🔄 Update & Maintenance

### Regenerate Specific Category

```bash
# Regenerate only login FAQs for Navy Federal
python scripts/generate_faqs.py member \
  --cu-id navyfederal \
  --categories login
```

### Delete and Regenerate

```sql
-- Delete old FAQs before regeneration
DELETE FROM member_faqs
WHERE cu_id = 'navyfederal' AND category = 'login';
```

### Update Single FAQ

```sql
UPDATE member_faqs
SET
  answer = 'Updated answer text...',
  tags = ARRAY['updated', 'password', 'reset'],
  updated_at = NOW()
WHERE id = 'faq-uuid';
```

---

## 🚀 Deployment Checklist

- [ ] Deploy `generate-faqs` Edge Function
- [ ] Run database migration (create 5 tables)
- [ ] Set OpenAI API key in Supabase secrets
- [ ] Generate platform-wide FAQs (developer, design, security)
- [ ] Generate member FAQs for pilot CUs (5-10 CUs)
- [ ] Generate staff training FAQs for pilot CUs
- [ ] Test full-text search functionality
- [ ] Integrate FAQ widgets into mobile app
- [ ] Build staff training portal
- [ ] Set up analytics tracking
- [ ] Batch generate for all 200+ CUs

---

## 📚 Related Documentation

- [Comprehensive FAQ System Plan](../COMPREHENSIVE_FAQ_SYSTEM_PLAN.md)
- [Feature Content Generator](./README.md)
- [Deployment Checklist](../DEPLOYMENT_CHECKLIST.md)
- [Database Migrations](../supabase/migrations/)

---

## 🎉 Success Metrics

**Target Outcomes:**
- 📉 50% reduction in support tickets (member FAQs)
- ⚡ 30% faster issue resolution (staff training)
- 🚀 70% faster developer onboarding
- 🎨 90% design system compliance
- ✅ 95% security audit passing rate

**Monitor:**
- FAQ view counts
- Helpful ratings
- Search query patterns
- Support ticket deflection rate
- Staff training completion rates

---

**Ready to deploy comprehensive FAQs for 200+ credit unions! 🚀**
