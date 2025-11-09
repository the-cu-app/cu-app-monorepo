// Edge Function: Generate Comprehensive FAQs for All Audiences
// Generates member, staff, developer, design, and security/compliance FAQs

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')

interface FAQRequest {
  audience: 'member' | 'staff' | 'developer' | 'design' | 'security'
  cuId?: string  // Required for member/staff, optional for others
  categories?: string[]
  count?: number  // Number of FAQs to generate per category
}

const AUDIENCE_PROMPTS = {
  member: {
    systemPrompt: (cuName: string) => `You are a helpful banking assistant creating member-facing FAQs for ${cuName}. Generate clear, concise, user-friendly answers that members can easily understand. Use ${cuName} branding consistently.`,
    categories: {
      login: 'Generate FAQs about logging in, password resets, 2FA, biometric authentication, and security',
      accounts: 'Generate FAQs about viewing accounts, understanding balances, account types, and statements',
      transfers: 'Generate FAQs about transferring money between accounts, external transfers, limits, and timing',
      bill_pay: 'Generate FAQs about setting up bill pay, scheduling payments, managing payees',
      deposits: 'Generate FAQs about mobile check deposits, deposit limits, hold times, and requirements',
      cards: 'Generate FAQs about debit/credit cards, card controls, lost/stolen cards, and PIN management',
      security: 'Generate FAQs about account security, fraud protection, alerts, and safe banking practices',
      settings: 'Generate FAQs about app settings, notifications, preferences, and profile management',
      troubleshooting: 'Generate FAQs about common errors, app crashes, login issues, and technical problems'
    }
  },

  staff: {
    systemPrompt: (cuName: string) => `You are creating training materials for ${cuName} staff members. Generate practical, actionable FAQs that help staff assist members effectively. Include escalation procedures where appropriate.`,
    categories: {
      account_help: 'Generate FAQs about helping members with account issues, balance inquiries, and statements',
      technical: 'Generate FAQs about troubleshooting app issues, device compatibility, and technical errors',
      compliance: 'Generate FAQs about regulatory compliance, privacy laws, and CU policies',
      verification: 'Generate FAQs about verifying member identity, authentication procedures, and security protocols',
      escalation: 'Generate FAQs about when to escalate issues, who to contact, and escalation procedures',
      products: 'Generate FAQs about CU products, features, rates, and account types',
      system_limits: 'Generate FAQs about transaction limits, restrictions, and system capabilities'
    }
  },

  developer: {
    systemPrompt: () => 'You are creating developer documentation for the CU white-label banking platform. Generate technical, code-focused FAQs with examples. Assume intermediate to advanced development knowledge.',
    categories: {
      api: 'Generate FAQs about API endpoints, authentication, request/response formats, and rate limits',
      deployment: 'Generate FAQs about deploying Edge Functions, building apps, and CI/CD pipelines',
      customization: 'Generate FAQs about customizing CU branding, features, and behavior',
      database: 'Generate FAQs about database schema, RLS policies, migrations, and queries',
      authentication: 'Generate FAQs about JWT tokens, session management, OAuth flows, and security',
      performance: 'Generate FAQs about optimization, caching, indexing, and performance monitoring',
      troubleshooting: 'Generate FAQs about debugging, error handling, logging, and common issues'
    }
  },

  design: {
    systemPrompt: () => 'You are creating design system documentation for UI/UX designers. Generate FAQs about design tokens, components, Figma integration, and branding guidelines.',
    categories: {
      tokens: 'Generate FAQs about primitive, semantic, and composition tokens',
      components: 'Generate FAQs about UI component library, usage patterns, and customization',
      figma: 'Generate FAQs about Figma plugins, Google Sheets Sync, and design file organization',
      branding: 'Generate FAQs about CU branding, logo usage, color systems, and typography',
      accessibility: 'Generate FAQs about WCAG compliance, color contrast, and a11y best practices',
      responsive: 'Generate FAQs about responsive design, breakpoints, and adaptive layouts',
      composition: 'Generate FAQs about layout composition tokens and spacing systems'
    }
  },

  security: {
    systemPrompt: () => 'You are creating security and compliance documentation for security teams, auditors, and compliance officers. Generate detailed, technically accurate FAQs with references to regulations and best practices.',
    categories: {
      encryption: 'Generate FAQs about data encryption, key management, TLS/SSL, and cryptographic standards',
      audit: 'Generate FAQs about audit logging, trails, compliance reporting, and evidence collection',
      compliance: 'Generate FAQs about GDPR, CCPA, PCI-DSS, SOC2, and regulatory requirements',
      access_control: 'Generate FAQs about RLS policies, permissions, roles, and access management',
      incident_response: 'Generate FAQs about security incidents, breach protocols, and response procedures',
      penetration_testing: 'Generate FAQs about pen testing procedures, vulnerability scanning, and remediation',
      vulnerability: 'Generate FAQs about CVE management, patching, and vulnerability disclosure'
    }
  }
}

serve(async (req) => {
  try {
    const { audience, cuId, categories, count = 10 }: FAQRequest = await req.json()

    // Validate request
    if (!audience || !AUDIENCE_PROMPTS[audience]) {
      throw new Error(`Invalid audience. Must be one of: ${Object.keys(AUDIENCE_PROMPTS).join(', ')}`)
    }

    // Member and staff FAQs require cuId
    if ((audience === 'member' || audience === 'staff') && !cuId) {
      throw new Error(`CU ID is required for ${audience} FAQs`)
    }

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Get CU configuration if needed
    let cuName = 'Your Credit Union'
    if (cuId) {
      const { data: cuConfig } = await supabaseClient
        .from('cu_configurations')
        .select('name')
        .eq('cu_id', cuId)
        .single()

      cuName = cuConfig?.name || cuName
    }

    // Get categories to generate
    const audienceConfig = AUDIENCE_PROMPTS[audience]
    const categoriesToGenerate = categories || Object.keys(audienceConfig.categories)

    const allFAQs = []

    // Generate FAQs for each category
    for (const category of categoriesToGenerate) {
      const categoryPrompt = audienceConfig.categories[category]
      if (!categoryPrompt) {
        console.warn(`Unknown category: ${category}`)
        continue
      }

      const systemPrompt = typeof audienceConfig.systemPrompt === 'function'
        ? audienceConfig.systemPrompt(cuName)
        : audienceConfig.systemPrompt

      const userPrompt = `${categoryPrompt}

Generate ${count} frequently asked questions about this topic.

Return a JSON array of FAQs with this exact structure:
[
  {
    "question": "The question text",
    "answer": "The detailed answer",
    "tags": ["tag1", "tag2", "tag3"]
  }
]

Requirements:
- Questions should be natural, conversational queries users would actually ask
- Answers should be clear, concise, and actionable (2-3 sentences max)
- Include 3-5 relevant tags per FAQ
${audience === 'member' ? `- Use "${cuName}" in answers where appropriate` : ''}
${audience === 'developer' ? '- Include code examples in answers where helpful' : ''}
${audience === 'staff' ? '- Include escalation procedures where appropriate' : ''}

Return ONLY the JSON array, no additional text.`

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
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userPrompt }
          ],
          temperature: 0.7,
          max_tokens: 3000,
          response_format: { type: 'json_object' }
        })
      })

      const openaiData = await openaiResponse.json()
      const content = openaiData.choices[0]?.message?.content

      if (!content) {
        console.error(`No content generated for category: ${category}`)
        continue
      }

      // Parse AI response
      let faqs
      try {
        const parsed = JSON.parse(content)
        // Handle both array and object with array property
        faqs = Array.isArray(parsed) ? parsed : (parsed.faqs || parsed.items || [])
      } catch (parseError) {
        console.error(`Failed to parse AI response for ${category}:`, parseError)
        continue
      }

      // Insert FAQs into appropriate table
      const tableName = {
        member: 'member_faqs',
        staff: 'staff_training_faqs',
        developer: 'developer_faqs',
        design: 'design_faqs',
        security: 'security_compliance_faqs'
      }[audience]

      for (const faq of faqs) {
        const record: any = {
          category,
          question: faq.question,
          answer: faq.answer,
          tags: faq.tags || []
        }

        // Add audience-specific fields
        if (audience === 'member' || audience === 'staff') {
          record.cu_id = cuId
        }

        if (audience === 'staff') {
          record.escalation_procedure = faq.escalation_procedure || null
          record.related_policies = faq.related_policies || []
        }

        if (audience === 'developer') {
          record.code_example = faq.code_example || null
          record.difficulty_level = faq.difficulty_level || 'intermediate'
        }

        if (audience === 'design') {
          record.tool = faq.tool || 'general'
          record.visual_example_url = faq.visual_example_url || null
          record.figma_file_url = faq.figma_file_url || null
        }

        if (audience === 'security') {
          record.regulation = faq.regulation || null
          record.severity_level = faq.severity_level || 'medium'
          record.policy_reference = faq.policy_reference || null
        }

        const { error: insertError } = await supabaseClient
          .from(tableName)
          .insert(record)

        if (insertError) {
          console.error(`Failed to insert FAQ:`, insertError)
        } else {
          allFAQs.push(record)
        }
      }

      // Rate limiting between categories
      await new Promise(resolve => setTimeout(resolve, 2000))
    }

    return new Response(
      JSON.stringify({
        success: true,
        audience,
        cuId: cuId || 'platform-wide',
        cuName,
        categoriesGenerated: categoriesToGenerate.length,
        faqsGenerated: allFAQs.length,
        faqs: allFAQs
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
