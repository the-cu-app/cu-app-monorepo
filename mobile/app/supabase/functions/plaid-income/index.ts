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

const CACHE_TTL = 60 * 60 * 1000; // 1 hour for income data

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const url = new URL(req.url);
    const pathname = url.pathname;
    const body = await req.json().catch(() => ({}));
    const accessToken = body.access_token;

    if (!accessToken) {
      return new Response(
        JSON.stringify({ error: "access_token is required" }),
        { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
      );
    }

    if (pathname.includes("/get")) {
      // Get income verification data
      const cacheKey = `plaid:income:${accessToken}`;
      const cached = await kv.get([cacheKey]);
      
      if (cached.value) {
        return new Response(JSON.stringify(cached.value), {
          status: 200,
          headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "true" },
        });
      }

      const response = await plaid.incomeGet({
        access_token: accessToken,
        options: {
          account_ids: body.account_ids,
        },
      });

      const responseData = {
        income: {
          income_streams: response.data.income.income_streams?.map(stream => ({
            account_id: stream.account_id,
            stream_id: stream.stream_id,
            category: stream.category,
            description: stream.description,
            merchant_name: stream.merchant_name,
            confidence: stream.confidence,
            days_since_last_transaction: stream.days_since_last_transaction,
            first_transaction_date: stream.first_transaction_date,
            frequency: stream.frequency,
            historical_average_monthly_gross_income: stream.historical_average_monthly_gross_income,
            historical_average_monthly_income: stream.historical_average_monthly_income,
            last_transaction_date: stream.last_transaction_date,
            max_number_of_overlapping_income_streams: stream.max_number_of_overlapping_income_streams,
            number_of_transactions_last_12_months: stream.number_of_transactions_last_12_months,
            transaction_ids: stream.transaction_ids,
          })),
          last_year_income: response.data.income.last_year_income,
          last_year_income_before_tax: response.data.income.last_year_income_before_tax,
          projected_yearly_income: response.data.income.projected_yearly_income,
          projected_yearly_income_before_tax: response.data.income.projected_yearly_income_before_tax,
          max_number_of_overlapping_income_streams: response.data.income.max_number_of_overlapping_income_streams,
          number_of_income_streams: response.data.income.number_of_income_streams,
        },
        accounts: response.data.accounts?.map(account => ({
          account_id: account.account_id,
          name: account.name,
          official_name: account.official_name,
          type: account.type,
          subtype: account.subtype,
          mask: account.mask,
          balances: account.balances,
        })),
        item: response.data.item,
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

    if (pathname.includes("/employment/get")) {
      // Get employment verification data
      const cacheKey = `plaid:employment:${accessToken}`;
      const cached = await kv.get([cacheKey]);
      
      if (cached.value) {
        return new Response(JSON.stringify(cached.value), {
          status: 200,
          headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "true" },
        });
      }

      const response = await plaid.employmentGet({
        access_token: accessToken,
        options: {
          account_ids: body.account_ids,
        },
      });

      const responseData = {
        employments: response.data.employments?.map(employment => ({
          account_id: employment.account_id,
          employee: employment.employee ? {
            employee_id: employment.employee.employee_id,
            marital_status: employment.employee.marital_status,
            taxpayer_id: employment.employee.taxpayer_id,
          } : null,
          employer: employment.employer ? {
            address: employment.employer.address ? {
              city: employment.employer.address.city,
              country: employment.employer.address.country,
              postal_code: employment.employer.address.postal_code,
              region: employment.employer.address.region,
              street: employment.employer.address.street,
            } : null,
            employer_id: employment.employer.employer_id,
            name: employment.employer.name,
          } : null,
          employment_details: employment.employment_details?.map(detail => ({
            annual_salary: detail.annual_salary,
            hire_date: detail.hire_date,
            position_title: detail.position_title,
            status: detail.status,
            end_date: detail.end_date,
          })),
        })),
        accounts: response.data.accounts?.map(account => ({
          account_id: account.account_id,
          name: account.name,
          official_name: account.official_name,
          type: account.type,
          subtype: account.subtype,
        })),
        item: response.data.item,
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

    if (pathname.includes("/precheck")) {
      // Income verification precheck
      const response = await plaid.incomeVerificationPrecheckGet({
        access_token: accessToken,
      });

      return new Response(JSON.stringify({
        precheck: {
          confidence: response.data.precheck.confidence,
          supported_account_types: response.data.precheck.supported_account_types,
        },
        lastUpdated: new Date().toISOString(),
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
          "POST /plaid-income/get",
          "POST /plaid-income/employment/get",
          "POST /plaid-income/precheck",
        ],
        description: "Income and employment verification endpoints for Plaid API",
      }),
      { status: 404, headers: { ...cors, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Plaid Income API Error:", error);
    return new Response(
      JSON.stringify({ 
        error: "Failed to fetch income data", 
        details: String(error) 
      }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } }
    );
  }
});