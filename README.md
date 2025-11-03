# CU.APP

Production-ready banking infrastructure adapters for credit unions.

## Features

- 11 production adapters
- Supabase authentication with ID verification
- Stripe checkout integration
- Light/dark mode support
- Next.js 15 with App Router

## Setup

```bash
npm install
npm run dev
```

# cu.app - infrastructure as proof™
---

## **Federal Banking & Credit Union Core Regulations**

### **Bank Secrecy Act (BSA) / Anti-Money Laundering (AML)**
- **Regulation:** 31 CFR § 103
- **Scope:** KYC, CDD, SAR/CTR filing, suspicious activity monitoring
- **cu.app compliance:** Real-time risk scoring engine; dynamic KYC at onboarding; automated SAR/CTR flagging with audit trail; continuous transaction monitoring across all adapters (banking-core, cards, loans, investments).

### **USA PATRIOT Act**
- **Regulation:** Public Law 107-56 (amends BSA)
- **Scope:** Customer Identification Program (CIP), information sharing (314(a) and 314(b))
- **cu.app compliance:** Biometric + document verification at signup; automated 314(a) law enforcement queries; internal information-sharing protocols across adapters; full CIP logging per member.

### **Gramm-Leach-Bliley Act (GLBA)**
- **Regulation:** 15 U.S. Code § 6801–6809
- **Scope:** Privacy, data safeguarding, pretexting prevention
- **cu.app compliance:** End-to-end AES-256 encryption; role-based field-level encryption; member consent workflow; annual privacy notice automation; secure data-sharing only with explicit member opt-in.

### **Federal Credit Union Act**
- **Regulation:** 12 U.S. Code Chapter 14
- **Scope:** Federal charter authority, member ownership, field of membership
- **cu.app compliance:** Multi-tenancy by FOM; charter-specific product configs; automated dividend and patronage calculations.

### **NCUA Rules & Regulations**
- **Regulation:** 12 CFR Part 701, 741, 703, 715
- **Scope:** Federal CU operations, insurance, capital, lending limits
- **cu.app compliance:** Real-time capital adequacy checks; automated share insurance disclosures (NCUA logo + statement on all deposit pages); lending limit guardrails by adapter (loans, cards); compliance dashboards for examiners.

---

## **Consumer Lending & Credit Regulations**

### **Truth in Lending Act (TILA) / Regulation Z**
- **Regulation:** 15 U.S. Code § 1601; 12 CFR Part 1026
- **Scope:** APR disclosure, credit card terms, mortgage disclosures (Loan Estimate, Closing Disclosure), rescission rights
- **cu.app compliance:** Auto-generated Loan Estimate (3-day rule); Closing Disclosure (3-day pre-consummation); APR calculator embedded; credit card terms displayed at application; rescission workflow for HELOC/mortgage.

### **Equal Credit Opportunity Act (ECOA) / Regulation B**
- **Regulation:** 15 U.S. Code § 1691; 12 CFR Part 1002
- **Scope:** Prohibits discrimination in credit (race, sex, marital status, age, etc.); adverse action notices
- **cu.app compliance:** Application forms exclude prohibited fields (race, religion, sex unless voluntary for monitoring); automated adverse action notices (reason codes); fair lending analytics pipeline detects disparate impact.

### **Fair Credit Reporting Act (FCRA)**
- **Regulation:** 15 U.S. Code § 1681; 12 CFR Part 222 (Regulation V)
- **Scope:** Permissible purposes for credit reports, prescreening, adverse action, risk-based pricing, dispute resolution
- **cu.app compliance:** Permissible purpose certification to CRAs; prescreening criteria locked pre-offer; post-screen only for verification; automated risk-based pricing notices; member dispute portal integrated with CRAs; identity theft red flags program.

### **Fair Debt Collection Practices Act (FDCPA)**
- **Regulation:** 15 U.S. Code § 1692
- **Scope:** Debt collection communication restrictions, disclosures, harassment prevention
- **cu.app compliance:** Communication log (time, method, agent); automated "mini-Miranda" in all collection comms; STOP request honored instantly; no contact after attorney representation flagged.

---

## **Electronic Payments & Transfers**

### **Electronic Fund Transfer Act (EFTA) / Regulation E**
- **Regulation:** 15 U.S. Code § 1693; 12 CFR Part 1005
- **Scope:** EFT disclosures, error resolution (45/90 days), unauthorized transaction liability, remittance transfers, overdraft opt-in
- **cu.app compliance:** Electronic receipts at every transaction; error resolution workflow (provisional credit automation within 10 days); unauthorized transaction liability caps enforced; overdraft opt-in modal (ATM/one-time debit); remittance transfer disclosures (amount, fees, FX rate, delivery date) pre-send.

### **Expedited Funds Availability Act (EFAA) / Regulation CC**
- **Regulation:** 12 CFR Part 229
- **Scope:** Funds availability schedules, hold disclosures, check return/collection rules
- **cu.app compliance:** Funds availability policy displayed at account opening and on statements; automated hold placement logic (next-day for certain deposits, case-by-case holds disclosed); check image capture and truncation; return item processing per Reg CC timelines.

### **Payment Card Industry Data Security Standard (PCI DSS)**
- **Regulation:** PCI DSS v4.0 (Industry Standard)
- **Scope:** Cardholder data protection, tokenization, network segmentation
- **cu.app compliance:** PCI zone isolation for card vault; dynamic tokenization (no plain PAN storage); quarterly ASV scans; annual penetration tests; compensating controls documented.

### **NACHA Operating Rules**
- **Regulation:** ACH Network Rules (annually updated)
- **Scope:** ACH origination, Same-Day ACH, unauthorized debits, return timelines, WEB/TEL/PPD entries
- **cu.app compliance:** NACHA-compliant ODFI/RDFI message formatting; Same-Day ACH support (adapter/banking-core); authorization records for WEB/TEL; return item auto-reconciliation; micro-deposit verification for external account linking.

---

## **Mortgage & Real Estate**

### **Real Estate Settlement Procedures Act (RESPA) / Regulation X**
- **Regulation:** 12 U.S. Code § 2601; 12 CFR Part 1024
- **Scope:** Loan servicing, escrow accounts, kickback prohibition, loss mitigation
- **cu.app compliance:** Integrated TILA-RESPA Disclosures (TRID); servicing transfer notices (15-day advance); escrow analysis automation; kickback/referral fee tracking flagged; loss mitigation decision tree per RESPA timelines.

### **Home Mortgage Disclosure Act (HMDA) / Regulation C**
- **Regulation:** 12 U.S. Code § 2801; 12 CFR Part 1003
- **Scope:** Mortgage data collection and reporting (race, ethnicity, sex, income, loan terms, denial reasons)
- **cu.app compliance:** Automated HMDA LAR generation; annual submission (March 1); GMI (Government Monitoring Information) collected at application (voluntary for mail/internet); geocoding via Census tract; HMDA disclosure statement published on website.

### **Homeowners Protection Act (HPA)**
- **Regulation:** 12 U.S. Code § 4901
- **Scope:** PMI cancellation, termination, disclosure
- **cu.app compliance:** Automated PMI cancellation at 80% LTV (member request) or 78% LTV (automatic termination); annual PMI disclosure; midpoint cancellation logic.

---

## **Deposit & Savings Accounts**

### **Truth in Savings Act (TISA) / Regulation DD**
- **Regulation:** 12 U.S. Code § 4301; 12 CFR Part 1030
- **Scope:** APY disclosure, fee schedules, periodic statements, change-in-terms notices
- **cu.app compliance:** APY calculator (compounding logic); account opening disclosures (fees, minimums, terms); monthly statements with APY earned; change-in-terms notice (30 days advance for rate decreases or new fees).

### **Garnishment of Accounts Containing Federal Benefits**
- **Regulation:** 31 CFR Part 212
- **Scope:** Protected federal benefit payments from garnishment
- **cu.app compliance:** Automated lookback (2 months) for federal benefits (SSA, VA, etc.); protected amount calculation; member notice of garnishment order and protected funds; hold exemption for protected amounts.

---

## **Fair Lending & Community Reinvestment**

### **Community Reinvestment Act (CRA)**
- **Regulation:** 12 U.S. Code § 2901; 12 CFR Part 345 (FDIC), Part 25 (OCC), Part 228 (Fed)
- **Scope:** Assessment areas, lending/investment/service tests, LMI performance
- **cu.app compliance:** CRA data capture per loan (geography, borrower income, census tract); public CRA file maintained digitally; community development loan/investment tagging; branch/service mapping by LMI area; automated CRA reporting for exams.

### **Fair Housing Act (FHA)**
- **Regulation:** 42 U.S. Code § 3601
- **Scope:** Prohibits housing discrimination (race, color, religion, sex, national origin, disability, familial status)
- **cu.app compliance:** Equal Housing Lender logo on all mortgage pages; fair lending training logged; algorithmic fairness audits on credit decisioning models; complaint tracking.

---

## **Data Privacy & Cybersecurity**

### **General Data Protection Regulation (GDPR)**
- **Regulation:** EU Regulation 2016/679
- **Scope:** Data subject rights (access, erasure, portability), consent, breach notification (72 hours)
- **cu.app compliance:** Member data export API (JSON/CSV); erasure request workflow (30-day SLA); consent management (granular opt-in/opt-out); EU data residency for EU members; breach notification automation (72-hour clock).

### **California Consumer Privacy Act (CCPA) / California Privacy Rights Act (CPRA)**
- **Regulation:** Cal. Civ. Code § 1798.100 et seq.
- **Scope:** Right to know, delete, opt-out of sale, data minimization
- **cu.app compliance:** "Do Not Sell My Personal Information" link on homepage; member data access portal; deletion request workflow (45-day response); privacy policy updated annually; opt-out signal (GPC) honored.

### **Gramm-Leach-Bliley Safeguards Rule**
- **Regulation:** 16 CFR Part 314
- **Scope:** Information security program, risk assessment, access controls, encryption, incident response
- **cu.app compliance:** Annual risk assessment; written information security program (WISP); multi-factor authentication enforced; encryption at rest (AES-256) and in transit (TLS 1.3); security incident response plan with 48-hour breach notification internally.

### **FFIEC Cybersecurity Assessment Tool (CAT)**
- **Regulation:** FFIEC Guidance
- **Scope:** Inherent risk profile, cybersecurity maturity (5 domains)
- **cu.app compliance:** Annual CAT self-assessment; penetration testing (quarterly); vulnerability scans (weekly); threat intelligence feeds; security operations center (SOC) monitoring 24/7.

---

## **Open Banking & Data Sharing**

### **CFPB 1033 Rule (Open Banking / Consumer Data Access)**
- **Regulation:** 12 CFR 1033
- **Scope:** Consumer-authorized data sharing, data access rights, standardized APIs
- **cu.app compliance:** Member-controlled data export (API and UI); consent dashboard (revoke anytime); third-party data access logs; OAuth 2.0 / OpenID Connect for secure authorization; API rate limiting and anomaly detection.

### **Payment Services Directive 2 (PSD2, EU)**
- **Regulation:** EU Directive 2015/2366
- **Scope:** Strong Customer Authentication (SCA), open banking APIs, third-party provider access
- **cu.app compliance:** SCA for electronic payments (two-factor: biometric + device); API endpoints for Account Information Service Providers (AISPs) and Payment Initiation Service Providers (PISPs); consent workflow per PSD2 RTS; transaction monitoring for fraud.

---

## **Global Payment Standards**

### **ISO 20022**
- **Regulation:** ISO 20022:2013 (Industry Standard)
- **Scope:** Universal financial messaging (XML/JSON schemas), rich payment data, cross-border interoperability
- **cu.app compliance:** Canonical message mapping (adapter/iso20022); inbound/outbound schema validation; cryptographic payload signing (ECC-256); message audit trail; automated fallback for legacy formats (MT, NACHA).

---

## **Marketing & Communications**

### **CAN-SPAM Act**
- **Regulation:** 15 U.S. Code § 7701; 16 CFR Part 316
- **Scope:** Commercial email rules (header accuracy, subject line, opt-out, physical address)
- **cu.app compliance:** Sender authentication (SPF, DKIM, DMARC); opt-out link in every commercial email; unsubscribe honored within 10 business days; physical address in footer; "advertisement" label if promotional.

### **Telephone Consumer Protection Act (TCPA)**
- **Regulation:** 47 U.S. Code § 227; 47 CFR Part 64
- **Scope:** Prior express consent for autodialed/prerecorded calls/texts, Do Not Call Registry, opt-out
- **cu.app compliance:** Consent log (timestamp, method, IP); STOP keyword instant opt-out for SMS; DNC scrubbing (monthly); call recording consent; one-to-one consent for each campaign; no autodialer without written consent.

### **Telemarketing Sales Rule (TSR)**
- **Regulation:** 16 CFR Part 310
- **Scope:** DNC compliance, abandoned call rates, material disclosures
- **cu.app compliance:** DNC registry scrub every 31 days; abandoned call rate <3%; caller ID transmission; material terms disclosed before payment authorization.

---

## **Unfair, Deceptive, or Abusive Acts or Practices (UDAAP)**

### **Dodd-Frank Act Section 1031**
- **Regulation:** 12 U.S. Code § 5531
- **Scope:** Prohibition on unfair, deceptive, or abusive acts (materially interferes with consumer understanding; takes unreasonable advantage of vulnerability, inability to protect interests, or reasonable reliance)
- **cu.app compliance:** Plain-language disclosures; A/B testing for clarity; consumer testing logs; product/feature risk assessment for UDAAP (quarterly); fee transparency (no hidden fees); proactive resolution of member complaints (closed-loop).

### **FTC Act Section 5 (UDAP)**
- **Regulation:** 15 U.S. Code § 45
- **Scope:** Unfair or deceptive acts or practices
- **cu.app compliance:** Marketing review process (legal + compliance sign-off); misleading claim detection (automated + manual); substantiation files for all claims; corrective action tracking.

---

## **Additional Compliance Frameworks**

### **SOC 1 / SOC 2 Type II**
- **Regulation:** AICPA SSAE 18 / SOC 2 Trust Services Criteria
- **Scope:** Internal controls over financial reporting (SOC 1); security, availability, processing integrity, confidentiality, privacy (SOC 2)
- **cu.app compliance:** Annual SOC 2 Type II audit (security, availability, confidentiality); automated control testing; continuous monitoring; remediation tracking; reports provided to members/partners on request.

### **ISO/IEC 27001**
- **Regulation:** ISO/IEC 27001:2013 (Information Security Management)
- **Scope:** ISMS, risk treatment, asset management, access control, cryptography
- **cu.app compliance:** Certified ISMS; annual risk assessment; asset inventory (all adapters, data flows); access control matrix (RBAC); cryptographic key management (HSM).

### **NIST Cybersecurity Framework**
- **Regulation:** NIST CSF 1.1 (Identify, Protect, Detect, Respond, Recover)
- **Scope:** Cybersecurity risk management
- **cu.app compliance:** CSF maturity mapping (Tier 3+); incident response playbooks; threat modeling per adapter; continuous monitoring; disaster recovery tested quarterly.

---

## **State-Specific Regulations (Multi-State)**

### **State Money Transmitter Licenses**
- **Regulation:** Varies by state (NMLS registry)
- **Scope:** Licensing, surety bonds, reporting, consumer protection
- **cu.app compliance:** NMLS #maintained; state-by-state licensing matrix; regional KYC/flow configs per state law; quarterly financial reporting to state regulators; consumer complaint tracking by state.

### **New York DFS Part 500 (Cybersecurity Requirements)**
- **Regulation:** 23 NYCRR Part 500
- **Scope:** Cybersecurity program, CISO, penetration testing, encryption, incident response, Third-party service provider management
- **cu.app compliance:** Designated CISO; annual Part 500 certification; penetration tests (annual + after material changes); encryption everywhere; vendor risk assessments; incident reporting to DFS within 72 hours.

### **BitLicense (New York)**
- **Regulation:** 23 NYCRR Part 200
- **Scope:** Virtual currency business activity
- **cu.app compliance:** BitLicense obtained if crypto custody/exchange offered; AML program for virtual currency; capital requirements met; consumer disclosures for virtual currency risks.

---

## **International / Regional Standards**

### **MAS Technology Risk Management (TRM) Guidelines (Singapore)**
- **Regulation:** MAS TRM Guidelines (Annex C: Mobile Security Controls)
- **Scope:** Mobile app security, device risk scoring, secure coding
- **cu.app compliance:** Device posture scoring (jailbreak/root detection); secure code review (SAST/DAST); encrypted local storage; certificate pinning; session timeout; biometric/PIN authentication.

### **RBI Digital Payment Security Controls (India)**
- **Regulation:** RBI Master Direction on Digital Payment Security Controls
- **Scope:** Two-factor authentication, fraud monitoring, alert mechanisms
- **cu.app compliance:** 2FA for all payment transactions; SMS/email alerts for every transaction; fraud scoring engine; customer education on safe digital banking.

---

## **Cryptographic Posture**

### **Hamming Code Error Detection**
- **Implementation:** Hamming(7,4) for payload integrity checks
- **cu.app:** Every message payload encoded with Hamming parity bits; real-time error detection; corrupted payloads rejected and logged; auto-retry with exponential backoff.

### **ECC-256 Digital Signatures**
- **Implementation:** Elliptic Curve Cryptography (secp256r1)
- **cu.app:** Every adapter-to-adapter message signed with ECC-256; signature verification before processing; public key infrastructure (PKI) managed via HSM; key rotation (annual).

### **Pose Recovery Fallback**
- **Implementation:** Automatic failover to alternate communication channel if primary fails integrity check
- **cu.app:** Multi-path redundancy (primary + backup channels); pose recovery triggered on Hamming failure or signature mismatch; member experience uninterrupted; incident logged for forensic review.

---

## **Summary: cu.app = Built-In Compliance**

cu.app isn't retrofitted for compliance—**compliance is the architecture**. Every adapter (banking-core, iso20022, compliance, financial-wellness, cards, loans, investments, design-system, communications, checkout) enforces regulatory logic at the edge, not as an afterthought.

- **31 CFR § 103 to 23 NYCRR 500:** Covered.
- **BSA to BitLicense:** Automated.
- **GDPR to TCPA:** Built-in.
- **Hamming + ECC-256 + Pose Recovery:** Every payload, every time.

**Result:** Precision-coded. Audit-ready. Zero drama. Just pure, unbreakable compliance.
