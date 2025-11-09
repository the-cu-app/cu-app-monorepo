// Stripe Webhook Handler
// Processes Stripe events and syncs with CU subscriptions

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14.14.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, stripe-signature',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify Stripe signature
    const signature = req.headers.get('stripe-signature')
    if (!signature) {
      throw new Error('Missing Stripe signature')
    }

    const body = await req.text()
    const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')

    let event: Stripe.Event

    try {
      event = stripe.webhooks.constructEvent(body, signature, webhookSecret!)
    } catch (err) {
      console.error('Webhook signature verification failed:', err.message)
      return new Response(
        JSON.stringify({ error: 'Webhook signature verification failed' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Process event
    console.log(`Processing Stripe event: ${event.type} (${event.id})`)

    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        await handleSubscriptionUpdate(supabaseClient, event)
        break

      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(supabaseClient, event)
        break

      case 'invoice.paid':
        await handleInvoicePaid(supabaseClient, event)
        break

      case 'invoice.payment_failed':
        await handleInvoicePaymentFailed(supabaseClient, event)
        break

      case 'customer.created':
      case 'customer.updated':
        await handleCustomerUpdate(supabaseClient, event)
        break

      case 'payment_method.attached':
        await handlePaymentMethodAttached(supabaseClient, event)
        break

      default:
        console.log(`Unhandled event type: ${event.type}`)
    }

    // Log webhook event
    await supabaseClient.rpc('process_stripe_webhook', {
      p_stripe_event_id: event.id,
      p_event_type: event.type,
      p_event_data: event as any,
    })

    return new Response(JSON.stringify({ received: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('Error processing webhook:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})

// Handle subscription created/updated
async function handleSubscriptionUpdate(
  supabaseClient: any,
  event: Stripe.Event
) {
  const subscription = event.data.object as Stripe.Subscription

  // Update Stripe subscription record
  const { error } = await supabaseClient
    .from('stripe_subscriptions')
    .upsert({
      stripe_subscription_id: subscription.id,
      status: subscription.status,
      current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
      current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
      cancel_at_period_end: subscription.cancel_at_period_end,
      latest_invoice_id: subscription.latest_invoice as string,
      stripe_metadata: subscription.metadata,
      updated_at: new Date().toISOString(),
    }, {
      onConflict: 'stripe_subscription_id',
    })

  if (error) {
    console.error('Error updating subscription:', error)
    throw error
  }

  console.log(`Subscription updated: ${subscription.id} (status: ${subscription.status})`)
}

// Handle subscription deleted (cancelled)
async function handleSubscriptionDeleted(
  supabaseClient: any,
  event: Stripe.Event
) {
  const subscription = event.data.object as Stripe.Subscription

  // Update status to cancelled
  const { error } = await supabaseClient
    .from('stripe_subscriptions')
    .update({
      status: 'canceled',
      canceled_at: new Date().toISOString(),
      ended_at: new Date().toISOString(),
    })
    .eq('stripe_subscription_id', subscription.id)

  if (error) {
    console.error('Error deleting subscription:', error)
    throw error
  }

  // Also update internal subscription
  await supabaseClient.rpc('sync_stripe_subscription', {
    p_stripe_subscription_id: subscription.id,
    p_status: 'canceled',
    p_current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
    p_current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
    p_cancel_at_period_end: false,
  })

  console.log(`Subscription cancelled: ${subscription.id}`)
}

// Handle invoice paid
async function handleInvoicePaid(
  supabaseClient: any,
  event: Stripe.Event
) {
  const invoice = event.data.object as Stripe.Invoice

  // Record invoice
  const { error } = await supabaseClient
    .from('stripe_invoices')
    .upsert({
      stripe_invoice_id: invoice.id,
      stripe_customer_id: invoice.customer as string,
      invoice_number: invoice.number,
      amount_due: invoice.amount_due / 100, // Convert cents to dollars
      amount_paid: invoice.amount_paid / 100,
      amount_remaining: invoice.amount_remaining / 100,
      currency: invoice.currency,
      status: invoice.status,
      paid: invoice.paid,
      invoice_date: new Date(invoice.created * 1000).toISOString(),
      due_date: invoice.due_date ? new Date(invoice.due_date * 1000).toISOString() : null,
      paid_at: invoice.status_transitions?.paid_at
        ? new Date(invoice.status_transitions.paid_at * 1000).toISOString()
        : null,
      invoice_pdf_url: invoice.invoice_pdf,
      hosted_invoice_url: invoice.hosted_invoice_url,
      line_items: invoice.lines.data,
      stripe_metadata: invoice.metadata,
    }, {
      onConflict: 'stripe_invoice_id',
    })

  if (error) {
    console.error('Error recording invoice:', error)
    throw error
  }

  console.log(`Invoice paid: ${invoice.id} (${invoice.amount_paid / 100} ${invoice.currency})`)
}

// Handle invoice payment failed
async function handleInvoicePaymentFailed(
  supabaseClient: any,
  event: Stripe.Event
) {
  const invoice = event.data.object as Stripe.Invoice

  // Update invoice status
  await supabaseClient
    .from('stripe_invoices')
    .update({
      status: 'open',
      paid: false,
    })
    .eq('stripe_invoice_id', invoice.id)

  // Mark customer as delinquent
  await supabaseClient
    .from('stripe_customers')
    .update({
      delinquent: true,
    })
    .eq('stripe_customer_id', invoice.customer as string)

  console.log(`Invoice payment failed: ${invoice.id}`)
}

// Handle customer update
async function handleCustomerUpdate(
  supabaseClient: any,
  event: Stripe.Event
) {
  const customer = event.data.object as Stripe.Customer

  await supabaseClient
    .from('stripe_customers')
    .update({
      email: customer.email,
      name: customer.name,
      description: customer.description,
      default_payment_method_id: customer.invoice_settings?.default_payment_method as string,
      delinquent: customer.delinquent,
      stripe_metadata: customer.metadata,
      updated_at: new Date().toISOString(),
    })
    .eq('stripe_customer_id', customer.id)

  console.log(`Customer updated: ${customer.id}`)
}

// Handle payment method attached
async function handlePaymentMethodAttached(
  supabaseClient: any,
  event: Stripe.Event
) {
  const paymentMethod = event.data.object as Stripe.PaymentMethod

  // Get customer info to find CU
  const customer = await stripe.customers.retrieve(paymentMethod.customer as string)

  const { data: stripeCustomer } = await supabaseClient
    .from('stripe_customers')
    .select('cu_id')
    .eq('stripe_customer_id', paymentMethod.customer as string)
    .single()

  if (!stripeCustomer) {
    console.log('Customer not found in database')
    return
  }

  // Record payment method
  await supabaseClient
    .from('stripe_payment_methods')
    .insert({
      cu_id: stripeCustomer.cu_id,
      stripe_payment_method_id: paymentMethod.id,
      type: paymentMethod.type,
      brand: paymentMethod.card?.brand,
      last_4: paymentMethod.card?.last4 || paymentMethod.us_bank_account?.last4,
      exp_month: paymentMethod.card?.exp_month,
      exp_year: paymentMethod.card?.exp_year,
      bank_name: paymentMethod.us_bank_account?.bank_name,
      account_holder_name: paymentMethod.billing_details?.name,
      is_default: true, // Assume new PM is default
    })

  console.log(`Payment method attached: ${paymentMethod.id}`)
}
