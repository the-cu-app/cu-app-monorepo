import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { Configuration, PlaidApi, PlaidEnvironments } from "npm:plaid";

const kv = await Deno.openKv();

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const PLAID_CLIENT_ID = "68b4224630c9690024a8ce7f";
const PLAID_SECRET = "1c77d0ac62503fa2862a5faab8e080";

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

const CACHE_TTL = 30 * 60 * 1000; // 30 minutes for assets data

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const url = new URL(req.url);
    const pathname = url.pathname;
    const body = await req.json().catch(() => ({}));
    
    if (pathname.includes("/report/create")) {
      // Create asset report
      const accessTokens = body.access_tokens;
      const daysRequested = body.days_requested || 730; // Default 2 years
      const webhook = body.webhook;
      const user = body.user;

      if (!accessTokens || !Array.isArray(accessTokens) || accessTokens.length === 0) {
        return new Response(
          JSON.stringify({ error: "access_tokens array is required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const response = await plaid.assetReportCreate({
        access_tokens: accessTokens,
        days_requested: daysRequested,
        webhook: webhook,
        user: user ? {
          client_user_id: user.client_user_id,
          first_name: user.first_name,
          middle_name: user.middle_name,
          last_name: user.last_name,
          ssn: user.ssn,
          phone_number: user.phone_number,
          email: user.email,
        } : undefined,
        options: {
          include_insights: body.include_insights || false,
          webhook: webhook,
        },
      });

      return new Response(JSON.stringify({
        asset_report_token: response.data.asset_report_token,
        asset_report_id: response.data.asset_report_id,
        request_id: response.data.request_id,
        created_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    if (pathname.includes("/report/get")) {
      // Get asset report
      const assetReportToken = body.asset_report_token;
      const includeInsights = body.include_insights || false;

      if (!assetReportToken) {
        return new Response(
          JSON.stringify({ error: "asset_report_token is required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const cacheKey = `plaid:assets:report:${assetReportToken}`;
      const cached = await kv.get([cacheKey]);
      
      if (cached.value) {
        return new Response(JSON.stringify(cached.value), {
          status: 200,
          headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "true" },
        });
      }

      const response = await plaid.assetReportGet({
        asset_report_token: assetReportToken,
        include_insights: includeInsights,
      });

      const report = response.data.report;
      const responseData = {
        report: {
          asset_report_id: report.asset_report_id,
          client_report_id: report.client_report_id,
          date_generated: report.date_generated,
          days_requested: report.days_requested,
          user: report.user,
          items: report.items?.map(item => ({
            item_id: item.item_id,
            institution_name: item.institution_name,
            institution_id: item.institution_id,
            date_last_updated: item.date_last_updated,
            accounts: item.accounts?.map(account => ({
              account_id: account.account_id,
              name: account.name,
              official_name: account.official_name,
              type: account.type,
              subtype: account.subtype,
              mask: account.mask,
              balances: account.balances,
              days_available: account.days_available,
              transactions: account.transactions?.map(tx => ({
                transaction_id: tx.transaction_id,
                amount: tx.amount,
                date: tx.date,
                name: tx.name,
                merchant_name: tx.merchant_name,
                original_description: tx.original_description,
                category: tx.category,
                category_id: tx.category_id,
                check_number: tx.check_number,
                date_transacted: tx.date_transacted,
                location: tx.location,
                payment_channel: tx.payment_channel,
                account_owner: tx.account_owner,
                transaction_type: tx.transaction_type,
                pending: tx.pending,
                pending_transaction_id: tx.pending_transaction_id,
                account_id: tx.account_id,
                iso_currency_code: tx.iso_currency_code,
                unofficial_currency_code: tx.unofficial_currency_code,
              })),
              owners: account.owners,
              historical_balances: account.historical_balances?.map(balance => ({
                date: balance.date,
                current: balance.current,
                iso_currency_code: balance.iso_currency_code,
                unofficial_currency_code: balance.unofficial_currency_code,
              })),
            })),
          })),
          insights: includeInsights ? report.insights : undefined,
        },
        warnings: response.data.warnings,
        lastUpdated: new Date().toISOString(),
        source: "plaid_real_api",
        cachedAt: Date.now(),
      };

      await kv.set([cacheKey], responseData, { expireIn: CACHE_TTL });

      return new Response(JSON.stringify(responseData), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "false" },
      });
    }

    if (pathname.includes("/report/pdf/get")) {
      // Get asset report PDF
      const assetReportToken = body.asset_report_token;

      if (!assetReportToken) {
        return new Response(
          JSON.stringify({ error: "asset_report_token is required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const response = await plaid.assetReportPdfGet({
        asset_report_token: assetReportToken,
      });

      // Return the PDF as base64 encoded string
      const uint8Array = new Uint8Array(response.data);
      const base64String = btoa(String.fromCharCode.apply(null, Array.from(uint8Array)));

      return new Response(JSON.stringify({
        pdf_data: base64String,
        content_type: "application/pdf",
        generated_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    if (pathname.includes("/report/remove")) {
      // Remove asset report
      const assetReportToken = body.asset_report_token;

      if (!assetReportToken) {
        return new Response(
          JSON.stringify({ error: "asset_report_token is required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const response = await plaid.assetReportRemove({
        asset_report_token: assetReportToken,
      });

      return new Response(JSON.stringify({
        removed: response.data.removed,
        request_id: response.data.request_id,
        removed_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    if (pathname.includes("/report/refresh")) {
      // Refresh asset report
      const assetReportToken = body.asset_report_token;
      const daysRequested = body.days_requested;

      if (!assetReportToken) {
        return new Response(
          JSON.stringify({ error: "asset_report_token is required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const response = await plaid.assetReportRefresh({
        asset_report_token: assetReportToken,
        days_requested: daysRequested,
        options: {
          include_insights: body.include_insights || false,
          webhook: body.webhook,
        },
      });

      return new Response(JSON.stringify({
        asset_report_token: response.data.asset_report_token,
        asset_report_id: response.data.asset_report_id,
        request_id: response.data.request_id,
        refreshed_at: new Date().toISOString(),
        source: "plaid_real_api",
      }), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    // Default: Return available endpoints
    return new Response(
      JSON.stringify({
        error: "Endpoint not found",
        available_endpoints: [
          "POST /plaid-assets/report/create",
          "POST /plaid-assets/report/get",
          "POST /plaid-assets/report/pdf/get",
          "POST /plaid-assets/report/remove",
          "POST /plaid-assets/report/refresh",
        ],
        description: "Asset report generation and management endpoints for Plaid API",
      }),
      { status: 404, headers: { ...cors, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Plaid Assets API Error:", error);
    return new Response(
      JSON.stringify({ 
        error: "Failed to process asset report request", 
        details: String(error) 
      }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } }
    );
  }
});