#!/usr/bin/env python3
"""
DEPRECATED: Legacy Suncoast Browser Automation Script

This script has been REPLACED by:
- supabase/functions/generate-feature-content/index.ts (Edge Function)
- scripts/generate_feature_content.py (Python CLI)

Problems with this approach:
❌ Hardcoded "Suncoast" references
❌ Browser automation (brittle, requires Edge running)
❌ No caching (regenerates every time)
❌ Manual copy-paste required
❌ Breaks with browser UI changes
❌ Not scalable for 200+ CUs

DO NOT USE THIS FILE - Use the new Edge Function approach instead.
See: scripts/README.md for migration guide
"""

import time
import pyperclip
import os

# DEPRECATED: Hardcoded Suncoast features
features_deprecated = [
    "Splash Screen", "Join Now Screen", "Identity Verification Screen",
    "Multi-factor Authentication Screen", "QR Code Screen", "Login Screen",
    "Forgot Password Screen", "Dashboard Screen", "Settings Screen",
    "Log Out Screen", "Account Access", "Login", "My Information Setting",
    "Share Overview", "Consumer Loan Overview", "Credit Card Overview",
    "Mortgage Overview", "Transaction History", "Accessibility", "Navigation",
    "Move Money Within Suncoast",  # ❌ Hardcoded CU name
    "Feedback", "eStatements", "Digital Debit Card Management", "eNotices",
    "Login with Username", "Identify a User in Core",
    "Move Money Out of Suncoast",  # ❌ Hardcoded CU name
    "Bill Pay", "Bill Pay Process Tracking",
    "Connect with Suncoast",  # ❌ Hardcoded CU name
    "Suncoast Locations",  # ❌ Hardcoded CU name
    "Offers", "Open & Apply", "User Access Roles and Permissions",
    "Manage Shares", "Manage Consumer Loans", "Login Setting",
    "Email Management", "Email the CU about a Transaction from Transaction History",
    "Manage Joint Owners on Shares", "Manage Beneficiaries on Shares",
    "App Settings", "Digital Credit Card Management", "MX Insights",
    "Meridian Link Deep Linking", "Loan Payment Enhancements",
    "Alerts & Notifications", "New MFA (Vendor Integration)",
    "Disclosures & Documentation", "Tax Documents",
    "Upload/Submit/View Documents", "Check Orders", "SPF Enhancements",
    "Stop Payments", "Deposit a Check (RDC)", "Dispute a Transaction",
    "Score Card Rewards", "Track my Card Order", "In-App Communication",
    "Digital Profile", "Report a Bug", "Quick Tips and How-To's", "Chatbots"
]

# DEPRECATED: Hardcoded template with Suncoast references
template_deprecated = """
Please provide information about the [Feature] as it were a new version of the
sunmobile Suncoast credit union app in a table format/.csv and dont address each
question Just give me the contents i'd need for all questions in one table and
prepared for a Figma Plugin called Google Sheets Sync to use for conent on designs.
"""

def deprecated_browser_automation():
    """
    DEPRECATED: Do not use this function

    This approach is:
    - Brittle (breaks with browser updates)
    - Slow (30 second waits)
    - Unreliable (depends on clipboard, UI timing)
    - Not scalable (can't batch process 200+ CUs)

    Use the new Edge Function approach instead:
        python scripts/generate_feature_content.py navyfederal --output content.csv
    """

    print("=" * 80)
    print("⚠️  WARNING: This script is DEPRECATED")
    print("=" * 80)
    print("\nThis legacy browser automation script has been replaced.")
    print("\nNew approach:")
    print("  1. Uses Supabase Edge Functions (no browser required)")
    print("  2. Works with ANY credit union (variable CU branding)")
    print("  3. Includes caching (avoid regeneration)")
    print("  4. Direct CSV export")
    print("\nTo migrate:")
    print("  python scripts/generate_feature_content.py YOUR_CU_ID --output content.csv")
    print("\nSee: scripts/README.md for full documentation")
    print("=" * 80)

    response = input("\nDo you still want to run the deprecated script? (yes/no): ")

    if response.lower() != 'yes':
        print("✅ Good choice! Use the new Edge Function approach instead.")
        return

    print("\n⚠️  Running deprecated script...")

    for feature in features_deprecated:
        question = template_deprecated.replace("[Feature]", feature)
        pyperclip.copy(question)
        time.sleep(2)

        # Activate Microsoft Edge
        os.system('osascript -e \'tell application "Microsoft Edge" to activate\'')

        # Open a new tab
        os.system('osascript -e \'tell application "System Events" to tell process "Microsoft Edge" to keystroke "t" using command down\'')

        # Type the chat URL and hit enter
        time.sleep(2)
        os.system('osascript -e \'tell application "System Events" to keystroke "https://chat.openai.com/?model=text-davinci-002-render-sha"\'')
        os.system('osascript -e \'tell application "System Events" to key code 36\'')

        # Wait for the chat to load
        time.sleep(5)

        # Paste the question into the chat and hit enter
        os.system('osascript -e \'tell application "System Events" to keystroke "v" using command down\'')
        time.sleep(2)
        os.system('osascript -e \'tell application "System Events" to key code 36\'')

        # Wait for 5 seconds before proceeding to the next feature
        time.sleep(5)


if __name__ == '__main__':
    deprecated_browser_automation()
