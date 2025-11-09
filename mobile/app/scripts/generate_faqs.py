#!/usr/bin/env python3
"""
Comprehensive FAQ Generator for CU Banking Platform
Generates FAQs for all audiences: Members, Staff, Developers, Designers, Security/Compliance

Usage:
  # Generate member FAQs for a specific CU
  python generate_faqs.py member --cu-id navyfederal

  # Generate developer FAQs (platform-wide)
  python generate_faqs.py developer

  # Generate all audiences for a CU
  python generate_faqs.py all --cu-id becu

  # Generate specific categories only
  python generate_faqs.py member --cu-id golden1 --categories login transfers deposits
"""

import requests
import json
import os
import sys
from typing import List, Optional
import argparse

# Supabase configuration
SUPABASE_URL = os.getenv('SUPABASE_URL', 'https://your-project.supabase.co')
SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY', '')
EDGE_FUNCTION_URL = f"{SUPABASE_URL}/functions/v1/generate-faqs"

# Audience types and their descriptions
AUDIENCES = {
    'member': {
        'description': 'Member-facing FAQs for mobile app users',
        'requires_cu': True,
        'categories': ['login', 'accounts', 'transfers', 'bill_pay', 'deposits', 'cards', 'security', 'settings', 'troubleshooting']
    },
    'staff': {
        'description': 'Staff training FAQs for CU employees',
        'requires_cu': True,
        'categories': ['account_help', 'technical', 'compliance', 'verification', 'escalation', 'products', 'system_limits']
    },
    'developer': {
        'description': 'Developer documentation FAQs',
        'requires_cu': False,
        'categories': ['api', 'deployment', 'customization', 'database', 'authentication', 'performance', 'troubleshooting']
    },
    'design': {
        'description': 'Design system FAQs for UI/UX designers',
        'requires_cu': False,
        'categories': ['tokens', 'components', 'figma', 'branding', 'accessibility', 'responsive', 'composition']
    },
    'security': {
        'description': 'Security & compliance FAQs',
        'requires_cu': False,
        'categories': ['encryption', 'audit', 'compliance', 'access_control', 'incident_response', 'penetration_testing', 'vulnerability']
    }
}


def generate_faqs(
    audience: str,
    cu_id: Optional[str] = None,
    categories: Optional[List[str]] = None,
    count: int = 10
) -> dict:
    """
    Generate FAQs for a specific audience

    Args:
        audience: Type of audience (member, staff, developer, design, security)
        cu_id: Credit union ID (required for member/staff)
        categories: List of categories to generate (defaults to all)
        count: Number of FAQs per category

    Returns:
        Dictionary with generation results
    """

    if audience not in AUDIENCES:
        raise ValueError(f"Invalid audience. Must be one of: {', '.join(AUDIENCES.keys())}")

    audience_config = AUDIENCES[audience]

    # Validate CU ID requirement
    if audience_config['requires_cu'] and not cu_id:
        raise ValueError(f"{audience} FAQs require a CU ID")

    payload = {
        "audience": audience,
        "count": count
    }

    if cu_id:
        payload["cuId"] = cu_id

    if categories:
        payload["categories"] = categories

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}"
    }

    print(f"\n🚀 Generating {audience.upper()} FAQs...")
    if cu_id:
        print(f"📍 CU ID: {cu_id}")
    if categories:
        print(f"📂 Categories: {', '.join(categories)}")
    else:
        print(f"📂 Categories: All ({len(audience_config['categories'])} categories)")
    print(f"🔢 Count per category: {count}")

    try:
        response = requests.post(
            EDGE_FUNCTION_URL,
            json=payload,
            headers=headers,
            timeout=600  # 10 minute timeout
        )

        response.raise_for_status()
        result = response.json()

        if result.get('success'):
            print(f"\n✅ Success! Generated {result['faqsGenerated']} FAQs across {result['categoriesGenerated']} categories")
            if 'cuName' in result:
                print(f"🏦 Credit Union: {result['cuName']}")
            return result
        else:
            print(f"\n❌ Error: {result.get('error')}")
            return result

    except requests.exceptions.RequestException as e:
        print(f"\n❌ Request failed: {str(e)}")
        return {"success": False, "error": str(e)}


def generate_all_audiences(cu_id: str, count: int = 10):
    """Generate FAQs for all relevant audiences for a specific CU"""

    print(f"\n{'=' * 80}")
    print(f"Generating FAQs for ALL audiences - CU: {cu_id}")
    print(f"{'=' * 80}")

    results = {}

    # Member FAQs
    print(f"\n\n{'=' * 80}")
    print("1/3: MEMBER FAQs")
    print(f"{'=' * 80}")
    results['member'] = generate_faqs('member', cu_id=cu_id, count=count)

    # Staff FAQs
    print(f"\n\n{'=' * 80}")
    print("2/3: STAFF FAQs")
    print(f"{'=' * 80}")
    results['staff'] = generate_faqs('staff', cu_id=cu_id, count=count)

    # Platform-wide FAQs (only if not already generated)
    print(f"\n\n{'=' * 80}")
    print("3/3: PLATFORM-WIDE FAQs (Developer, Design, Security)")
    print(f"{'=' * 80}")
    print("⚠️  Platform FAQs are CU-agnostic. Generate separately if needed:")
    print("    python generate_faqs.py developer")
    print("    python generate_faqs.py design")
    print("    python generate_faqs.py security")

    # Summary
    print(f"\n\n{'=' * 80}")
    print("SUMMARY")
    print(f"{'=' * 80}")

    total_faqs = 0
    for audience, result in results.items():
        if result.get('success'):
            faq_count = result.get('faqsGenerated', 0)
            total_faqs += faq_count
            print(f"✅ {audience.upper()}: {faq_count} FAQs generated")
        else:
            print(f"❌ {audience.upper()}: Failed - {result.get('error')}")

    print(f"\n📊 TOTAL: {total_faqs} FAQs generated for {cu_id}")

    return results


def batch_generate_all_cus(cu_ids: List[str], count: int = 10):
    """Batch generate FAQs for multiple CUs"""

    print(f"\n{'=' * 80}")
    print(f"BATCH GENERATION: {len(cu_ids)} Credit Unions")
    print(f"{'=' * 80}")

    all_results = {}

    for i, cu_id in enumerate(cu_ids, 1):
        print(f"\n\n{'#' * 80}")
        print(f"CU {i}/{len(cu_ids)}: {cu_id}")
        print(f"{'#' * 80}")

        all_results[cu_id] = generate_all_audiences(cu_id, count)

        # Rate limiting between CUs
        if i < len(cu_ids):
            print(f"\n⏳ Waiting 5 seconds before next CU...")
            import time
            time.sleep(5)

    # Final summary
    print(f"\n\n{'=' * 80}")
    print("BATCH GENERATION COMPLETE")
    print(f"{'=' * 80}")

    for cu_id, results in all_results.items():
        total = sum(
            r.get('faqsGenerated', 0)
            for r in results.values()
            if r.get('success')
        )
        print(f"{cu_id}: {total} FAQs")

    return all_results


def main():
    parser = argparse.ArgumentParser(
        description='Generate comprehensive FAQs for CU banking platform',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate member FAQs for Navy Federal
  python generate_faqs.py member --cu-id navyfederal

  # Generate developer FAQs (all categories)
  python generate_faqs.py developer

  # Generate all FAQs for BECU
  python generate_faqs.py all --cu-id becu

  # Generate specific categories only
  python generate_faqs.py member --cu-id golden1 --categories login transfers

  # Batch generate for multiple CUs
  python generate_faqs.py batch --cu-ids navyfederal becu golden1 penfed

Audiences:
  member     - Member-facing FAQs for mobile app users
  staff      - Staff training FAQs for CU employees
  developer  - Developer documentation FAQs
  design     - Design system FAQs for UI/UX designers
  security   - Security & compliance FAQs
  all        - Generate member + staff FAQs (requires --cu-id)
  batch      - Generate for multiple CUs (requires --cu-ids)
        """
    )

    parser.add_argument(
        'audience',
        choices=['member', 'staff', 'developer', 'design', 'security', 'all', 'batch'],
        help='Type of FAQs to generate'
    )

    parser.add_argument(
        '--cu-id',
        help='Credit union ID (required for member/staff/all)'
    )

    parser.add_argument(
        '--cu-ids',
        nargs='+',
        help='Multiple CU IDs for batch generation'
    )

    parser.add_argument(
        '--categories',
        nargs='+',
        help='Specific categories to generate (defaults to all)'
    )

    parser.add_argument(
        '--count',
        type=int,
        default=10,
        help='Number of FAQs per category (default: 10)'
    )

    args = parser.parse_args()

    # Handle batch generation
    if args.audience == 'batch':
        if not args.cu_ids:
            print("❌ Error: --cu-ids required for batch generation")
            sys.exit(1)

        batch_generate_all_cus(args.cu_ids, args.count)
        sys.exit(0)

    # Handle all audiences
    if args.audience == 'all':
        if not args.cu_id:
            print("❌ Error: --cu-id required for 'all' audience")
            sys.exit(1)

        generate_all_audiences(args.cu_id, args.count)
        sys.exit(0)

    # Handle single audience
    result = generate_faqs(
        audience=args.audience,
        cu_id=args.cu_id,
        categories=args.categories,
        count=args.count
    )

    sys.exit(0 if result.get('success') else 1)


if __name__ == '__main__':
    main()
