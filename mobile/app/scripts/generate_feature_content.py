#!/usr/bin/env python3
"""
CU Feature Content Generator (Refactored)
Generates Figma-ready content for any credit union's banking features
Uses Supabase Edge Function instead of browser automation
"""

import requests
import json
import os
import sys
from typing import List, Dict, Optional

# Supabase configuration
SUPABASE_URL = os.getenv('SUPABASE_URL', 'https://your-project.supabase.co')
SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY', '')
EDGE_FUNCTION_URL = f"{SUPABASE_URL}/functions/v1/generate-feature-content"

# Generic banking features (no CU-specific references)
CORE_BANKING_FEATURES = [
    "Splash Screen",
    "Join Now Screen",
    "Identity Verification Screen",
    "Multi-factor Authentication Screen",
    "QR Code Screen",
    "Login Screen",
    "Forgot Password Screen",
    "Dashboard Screen",
    "Settings Screen",
    "Log Out Screen",
    "Account Access",
    "My Information Setting",
    "Checking Account Overview",
    "Savings Account Overview",
    "Consumer Loan Overview",
    "Credit Card Overview",
    "Mortgage Overview",
    "Transaction History",
    "Accessibility",
    "Navigation",
    "Internal Transfers",
    "Feedback",
    "eStatements",
    "Digital Debit Card Management",
    "eNotices",
    "Login with Username",
    "External Transfers",
    "Bill Pay",
    "Bill Pay Process Tracking",
    "Contact CU",
    "Branch & ATM Locations",
    "Offers",
    "Open & Apply",
    "User Access Roles and Permissions",
    "Manage Accounts",
    "Manage Consumer Loans",
    "Login Setting",
    "Email Management",
    "Email CU about Transaction",
    "Manage Joint Owners",
    "Manage Beneficiaries",
    "App Settings",
    "Digital Credit Card Management",
    "Financial Insights",
    "Loan Application Deep Linking",
    "Loan Payment Enhancements",
    "Alerts & Notifications",
    "Multi-Factor Authentication",
    "Disclosures & Documentation",
    "Tax Documents",
    "Upload/Submit/View Documents",
    "Check Orders",
    "Secure Payment Features",
    "Stop Payments",
    "Mobile Check Deposit",
    "Dispute a Transaction",
    "Rewards Program",
    "Track Card Order",
    "In-App Communication",
    "Digital Profile",
    "Report a Bug",
    "Quick Tips and How-To's",
    "AI Chatbot"
]


def generate_feature_content(
    cu_id: str,
    features: Optional[List[str]] = None,
    batch_mode: bool = True,
    output_file: Optional[str] = None
) -> Dict:
    """
    Generate Figma-ready content for banking features via Supabase Edge Function

    Args:
        cu_id: Credit union identifier (e.g., 'navyfederal', 'becu', 'golden1')
        features: List of features to generate content for (defaults to all core features)
        batch_mode: Whether to process all features in batch (with rate limiting)
        output_file: Optional CSV file path to save results

    Returns:
        Dictionary with generation results
    """

    payload = {
        "cuId": cu_id,
        "features": features or CORE_BANKING_FEATURES,
        "batchMode": batch_mode
    }

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}"
    }

    print(f"🚀 Generating content for {len(payload['features'])} features...")
    print(f"📍 CU ID: {cu_id}")
    print(f"⏱️  Batch mode: {batch_mode}")

    try:
        response = requests.post(
            EDGE_FUNCTION_URL,
            json=payload,
            headers=headers,
            timeout=600  # 10 minute timeout for batch processing
        )

        response.raise_for_status()
        result = response.json()

        if result.get('success'):
            print(f"\n✅ Success! Generated content for {result['featuresGenerated']} features")
            print(f"🏦 Credit Union: {result['cuName']}")

            # Save to CSV if output file specified
            if output_file:
                save_to_csv(result['results'], output_file)
                print(f"💾 Saved to: {output_file}")

            return result
        else:
            print(f"\n❌ Error: {result.get('error')}")
            return result

    except requests.exceptions.RequestException as e:
        print(f"\n❌ Request failed: {str(e)}")
        return {"success": False, "error": str(e)}


def save_to_csv(results: List[Dict], output_file: str):
    """Save generated content to CSV file for Figma import"""
    import csv

    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)

        # Write header
        writer.writerow(['Feature'] + [f'Slot {i}' for i in range(1, 30)])

        # Write content rows
        for result in results:
            # Parse CSV content from AI response
            content_row = result['content'].split(',')
            writer.writerow([result['feature']] + content_row)

    print(f"✅ CSV file created: {output_file}")


def main():
    """CLI interface for feature content generation"""
    import argparse

    parser = argparse.ArgumentParser(
        description='Generate Figma-ready content for CU banking features'
    )
    parser.add_argument(
        'cu_id',
        help='Credit union ID (e.g., navyfederal, becu, golden1)'
    )
    parser.add_argument(
        '--features',
        nargs='+',
        help='Specific features to generate (defaults to all core features)'
    )
    parser.add_argument(
        '--output',
        '-o',
        help='Output CSV file path'
    )
    parser.add_argument(
        '--no-batch',
        action='store_true',
        help='Disable batch mode (process features individually)'
    )

    args = parser.parse_args()

    result = generate_feature_content(
        cu_id=args.cu_id,
        features=args.features,
        batch_mode=not args.no_batch,
        output_file=args.output
    )

    sys.exit(0 if result.get('success') else 1)


if __name__ == '__main__':
    main()
