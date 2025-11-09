import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Configuration, PlaidApi, PlaidEnvironments } from "npm:plaid";

// Deno KV for caching
const kv = await Deno.openKv();

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Configuration - using your existing Plaid keys
const PLAID_CLIENT_ID = "68b4224630c9690024a8ce7f";
const PLAID_SECRET = "1c77d0ac62503fa2862a5faab8e080";

// Initialize Plaid client
const plaid = new PlaidApi(
  new Configuration({
    basePath: PlaidEnvironments.sandbox,
    baseOptions: {
      headers: {
        "PLAID-CLIENT-ID": PLAID_CLIENT_ID,
        "PLAID-SECRET": PLAID_SECRET,
      },
    },
  })
);

// Cache configuration
const CACHE_TTL = 3 * 60 * 1000; // 3 minutes for transactions
const CACHE_PREFIX = "plaid:transactions:";

interface TransactionRequest {
  accessToken?: string;
  accountId?: string;
  startDate?: string;
  endDate?: string;
  count?: number;
  offset?: number;
  category?: string;
  merchantName?: string;
  minAmount?: number;
  maxAmount?: number;
}

// Helper function to get cache key
function getCacheKey(params: TransactionRequest): string {
  const key = `${CACHE_PREFIX}${params.accessToken}:${params.accountId || 'all'}:${params.startDate}:${params.endDate}:${params.offset}:${params.count}`;
  return key;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const body: TransactionRequest = await req.json();
    
    // Default values
    const accessToken = body.accessToken || "access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24";
    const count = Math.min(body.count || 50, 100); // Max 100 per page
    const offset = body.offset || 0;
    const startDate = body.startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const endDate = body.endDate || new Date().toISOString().split('T')[0];

    // Check cache first
    const cacheKey = getCacheKey({ ...body, accessToken, count, offset, startDate, endDate });
    const cached = await kv.get([cacheKey]);
    
    if (cached.value) {
      // Apply filters on cached data if needed
      let filteredData = cached.value as any;
      
      if (body.category || body.merchantName || body.minAmount !== undefined || body.maxAmount !== undefined) {
        filteredData = {
          ...filteredData,
          transactions: filteredData.transactions.filter((tx: any) => {
            if (body.category && !tx.category?.includes(body.category)) return false;
            if (body.merchantName && !tx.merchant_name?.toLowerCase().includes(body.merchantName.toLowerCase())) return false;
            if (body.minAmount !== undefined && tx.amount < body.minAmount) return false;
            if (body.maxAmount !== undefined && tx.amount > body.maxAmount) return false;
            return true;
          }),
          filtered: true,
        };
        filteredData.total_transactions = filteredData.transactions.length;
      }
      
      return new Response(JSON.stringify(filteredData), {
        status: 200,
        headers: { 
          ...cors, 
          "Content-Type": "application/json",
          "X-Cache-Hit": "true",
          "X-Cache-Age": String(Date.now() - (cached.value as any).cachedAt)
        },
      });
    }

    // Cache miss - fetch from Plaid with pagination
    const options: any = {
      count,
      offset,
    };

    if (body.accountId) {
      options.account_ids = [body.accountId];
    }

    const response = await plaid.transactionsGet({
      access_token: accessToken,
      start_date: startDate,
      end_date: endDate,
      options,
    });

    // Transform transactions for better performance
    const transactions = response.data.transactions.map((transaction) => ({
      transaction_id: transaction.transaction_id,
      account_id: transaction.account_id,
      amount: transaction.amount,
      date: transaction.date,
      name: transaction.name,
      merchant_name: transaction.merchant_name,
      category: transaction.category,
      pending: transaction.pending,
      logo_url: transaction.logo_url,
      payment_channel: transaction.payment_channel,
    }));

    const responseData = {
      transactions,
      accounts: response.data.accounts.map(account => ({
        account_id: account.account_id,
        name: account.name,
        mask: account.mask,
        type: account.type,
        subtype: account.subtype,
      })),
      total_transactions: response.data.total_transactions,
      has_more: response.data.total_transactions > offset + count,
      page_info: {
        count,
        offset,
        total: response.data.total_transactions,
        pages: Math.ceil(response.data.total_transactions / count),
        current_page: Math.floor(offset / count) + 1,
      },
      lastUpdated: new Date().toISOString(),
      source: "plaid_paginated",
      cachedAt: Date.now(),
    };

    // Store in cache with TTL
    await kv.set([cacheKey], responseData, { expireIn: CACHE_TTL });

    return new Response(JSON.stringify(responseData), {
      status: 200,
      headers: { 
        ...cors, 
        "Content-Type": "application/json",
        "X-Cache-Hit": "false",
        "X-Total-Count": String(response.data.total_transactions),
      },
    });

  } catch (error) {
    console.error("Plaid API Error:", error);
    
    // Return error response
    return new Response(
      JSON.stringify({ 
        error: "Failed to fetch transactions", 
        details: String(error),
      }),
      {
        status: 500,
        headers: { ...cors, "Content-Type": "application/json" },
      }
    );
  }
});