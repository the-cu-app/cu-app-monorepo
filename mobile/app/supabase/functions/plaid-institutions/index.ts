import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { Configuration, PlaidApi, PlaidEnvironments, CountryCode } from "npm:plaid";

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

const CACHE_TTL = 24 * 60 * 60 * 1000; // 24 hours for institutions

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const url = new URL(req.url);
    const pathname = url.pathname;

    if (pathname.includes("/search")) {
      // Institution search
      const query = url.searchParams.get("query");
      const products = url.searchParams.get("products")?.split(",") || ["transactions"];
      const countryCodes = url.searchParams.get("country_codes")?.split(",") || ["US"];
      
      if (!query) {
        return new Response(
          JSON.stringify({ error: "Query parameter required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const cacheKey = `plaid:institutions:search:${query}:${products.join(":")}`;
      const cached = await kv.get([cacheKey]);
      
      if (cached.value) {
        return new Response(JSON.stringify(cached.value), {
          status: 200,
          headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "true" },
        });
      }

      const response = await plaid.institutionsSearch({
        query,
        products: products as any[],
        country_codes: countryCodes as CountryCode[],
      });

      const responseData = {
        institutions: response.data.institutions.map(inst => ({
          institution_id: inst.institution_id,
          name: inst.name,
          products: inst.products,
          country_codes: inst.country_codes,
          url: inst.url,
          primary_color: inst.primary_color,
          logo: inst.logo,
          routing_numbers: inst.routing_numbers,
          dtc_numbers: inst.dtc_numbers,
          oauth: inst.oauth,
        })),
        total: response.data.institutions.length,
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

    if (pathname.includes("/get-by-id")) {
      // Get institution by ID
      const institutionId = url.searchParams.get("institution_id");
      const countryCodes = url.searchParams.get("country_codes")?.split(",") || ["US"];
      
      if (!institutionId) {
        return new Response(
          JSON.stringify({ error: "institution_id parameter required" }),
          { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
        );
      }

      const cacheKey = `plaid:institution:${institutionId}`;
      const cached = await kv.get([cacheKey]);
      
      if (cached.value) {
        return new Response(JSON.stringify(cached.value), {
          status: 200,
          headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "true" },
        });
      }

      const response = await plaid.institutionsGetById({
        institution_id: institutionId,
        country_codes: countryCodes as CountryCode[],
        options: {
          include_optional_metadata: true,
          include_auth_metadata: true,
          include_payment_initiation_metadata: true,
        },
      });

      const institution = response.data.institution;
      const responseData = {
        institution: {
          institution_id: institution.institution_id,
          name: institution.name,
          products: institution.products,
          country_codes: institution.country_codes,
          url: institution.url,
          primary_color: institution.primary_color,
          logo: institution.logo,
          routing_numbers: institution.routing_numbers,
          dtc_numbers: institution.dtc_numbers,
          oauth: institution.oauth,
          status: institution.status,
          auth_metadata: institution.auth_metadata,
          payment_initiation_metadata: institution.payment_initiation_metadata,
        },
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

    // Default: Get all institutions (with pagination)
    const count = Math.min(parseInt(url.searchParams.get("count") || "100"), 500);
    const offset = parseInt(url.searchParams.get("offset") || "0");
    const countryCodes = url.searchParams.get("country_codes")?.split(",") || ["US"];
    
    const cacheKey = `plaid:institutions:all:${offset}:${count}`;
    const cached = await kv.get([cacheKey]);
    
    if (cached.value) {
      return new Response(JSON.stringify(cached.value), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "true" },
      });
    }

    const response = await plaid.institutionsGet({
      count,
      offset,
      country_codes: countryCodes as CountryCode[],
      options: {
        include_optional_metadata: true,
      },
    });

    const responseData = {
      institutions: response.data.institutions.map(inst => ({
        institution_id: inst.institution_id,
        name: inst.name,
        products: inst.products,
        country_codes: inst.country_codes,
        url: inst.url,
        primary_color: inst.primary_color,
        logo: inst.logo,
        routing_numbers: inst.routing_numbers,
        oauth: inst.oauth,
      })),
      total: response.data.total,
      count,
      offset,
      lastUpdated: new Date().toISOString(),
      source: "plaid_real_api",
      cachedAt: Date.now(),
    };

    await kv.set([cacheKey], responseData, { expireIn: CACHE_TTL });

    return new Response(JSON.stringify(responseData), {
      status: 200,
      headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "false" },
    });

  } catch (error) {
    console.error("Plaid Institutions API Error:", error);
    return new Response(
      JSON.stringify({ 
        error: "Failed to fetch institutions", 
        details: String(error) 
      }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } }
    );
  }
});