// Edge Function: Generate Feature Content for CU Apps
// Generates Figma-ready content tables for any credit union's banking features

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')

// Generic banking features (no CU-specific references)
const CORE_BANKING_FEATURES = [
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
  "Share Overview",
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
  "Identify a User in Core",
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

const CONTENT_TEMPLATE = `Please provide information about the [Feature] as it would appear in the [CU_NAME] mobile banking app. Format the response as a CSV table ready for Figma's Google Sheets Sync plugin.

Use these column headings: Slot 1, Slot 2, Slot 3, Slot 4, Slot 5, Slot 6, Slot 7, Slot 8, Slot 9, Slot 10, Slot 11, Slot 12, Slot 13, Slot 14, Slot 15, Slot 16, Slot 17, Slot 18, Slot 19, Slot 20, Slot 21, Slot 22, Slot 23, Slot 24, Slot 25, Slot 26, Slot 27, Slot 28, Slot 29

Provide content for these questions in order:
1. Purpose of [Feature]
2. Information displayed
3. Member actions available
4. Fields displayed
5. Possible scenarios
6. Number of screens
7. Access & restrictions
8. Access restriction scenarios
9. Required input data
10. Data validations/errors
11. Available data filters
12. Graphical representations
13. Customization options
14. Notification types
15. Third-party integrations
16. Data refresh method
17. Security/privacy considerations
18. Links/CTAs
19. Information architecture position
20. Related screens/features
21. Main purpose in app context
22. Pathways to this screen
23. Screens this leads to
24. Navigation label terminology
25. Navigation hierarchy position
26. Main content & functionality
27. Target user persona
28. Expected user flow
29. Desktop optimization ideas

Format as a single CSV row with 29 columns.`

serve(async (req) => {
  try {
    const { cuId, features, batchMode = false } = await req.json()

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get CU configuration
    const { data: cuConfig, error: cuError } = await supabaseClient
      .from('cu_configurations')
      .select('name, short_name')
      .eq('cu_id', cuId)
      .single()

    if (cuError) throw new Error(`CU not found: ${cuError.message}`)

    const cuName = cuConfig.name
    const featureList = features || CORE_BANKING_FEATURES

    // Generate content for each feature
    const results = []

    for (const feature of featureList) {
      const prompt = CONTENT_TEMPLATE
        .replace(/\[Feature\]/g, feature)
        .replace(/\[CU_NAME\]/g, cuName)

      // Call OpenAI API
      const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${OPENAI_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-4-turbo-preview',
          messages: [
            {
              role: 'system',
              content: `You are a banking UX content specialist creating CSV content for ${cuName}'s mobile banking app. Generate concise, professional content suitable for Figma design mockups.`
            },
            {
              role: 'user',
              content: prompt
            }
          ],
          temperature: 0.7,
          max_tokens: 2000
        })
      })

      const openaiData = await openaiResponse.json()
      const generatedContent = openaiData.choices[0]?.message?.content || ''

      results.push({
        feature,
        content: generatedContent,
        timestamp: new Date().toISOString()
      })

      // Store in database for caching
      await supabaseClient
        .from('feature_content_cache')
        .upsert({
          cu_id: cuId,
          feature_name: feature,
          content: generatedContent,
          updated_at: new Date().toISOString()
        })

      // Rate limiting: wait 2 seconds between requests
      if (batchMode) {
        await new Promise(resolve => setTimeout(resolve, 2000))
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        cuId,
        cuName,
        featuresGenerated: results.length,
        results
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
