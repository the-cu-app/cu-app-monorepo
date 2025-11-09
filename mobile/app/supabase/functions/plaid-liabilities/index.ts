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

const CACHE_TTL = 30 * 60 * 1000; // 30 minutes for liabilities data

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const accessToken = body.access_token;

    if (!accessToken) {
      return new Response(
        JSON.stringify({ error: "access_token is required" }),
        { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
      );
    }

    const cacheKey = `plaid:liabilities:${accessToken}`;
    const cached = await kv.get([cacheKey]);
    
    if (cached.value) {
      return new Response(JSON.stringify(cached.value), {
        status: 200,
        headers: { ...cors, "Content-Type": "application/json", "X-Cache-Hit": "true" },
      });
    }

    const response = await plaid.liabilitiesGet({
      access_token: accessToken,
      options: {
        account_ids: body.account_ids,
      },
    });

    const responseData = {
      accounts: response.data.accounts.map(account => ({
        account_id: account.account_id,
        name: account.name,
        official_name: account.official_name,
        type: account.type,
        subtype: account.subtype,
        mask: account.mask,
        balances: account.balances,
      })),
      liabilities: {
        credit: response.data.liabilities.credit?.map(credit => ({
          account_id: credit.account_id,
          aprs: credit.aprs?.map(apr => ({
            apr_percentage: apr.apr_percentage,
            apr_type: apr.apr_type,
            balance_subject_to_apr: apr.balance_subject_to_apr,
            interest_charge_amount: apr.interest_charge_amount,
          })),
          is_overdue: credit.is_overdue,
          last_payment_amount: credit.last_payment_amount,
          last_payment_date: credit.last_payment_date,
          last_statement_issue_date: credit.last_statement_issue_date,
          last_statement_balance: credit.last_statement_balance,
          minimum_payment_amount: credit.minimum_payment_amount,
          next_payment_due_date: credit.next_payment_due_date,
        })),
        mortgage: response.data.liabilities.mortgage?.map(mortgage => ({
          account_id: mortgage.account_id,
          account_number: mortgage.account_number,
          current_late_fee: mortgage.current_late_fee,
          escrow_balance: mortgage.escrow_balance,
          has_pmi: mortgage.has_pmi,
          has_prepayment_penalty: mortgage.has_prepayment_penalty,
          interest_rate: {
            percentage: mortgage.interest_rate.percentage,
            type: mortgage.interest_rate.type,
          },
          last_payment_amount: mortgage.last_payment_amount,
          last_payment_date: mortgage.last_payment_date,
          loan_type_description: mortgage.loan_type_description,
          loan_term: mortgage.loan_term,
          maturity_date: mortgage.maturity_date,
          next_monthly_payment: mortgage.next_monthly_payment,
          next_payment_due_date: mortgage.next_payment_due_date,
          origination_date: mortgage.origination_date,
          origination_principal_amount: mortgage.origination_principal_amount,
          past_due_amount: mortgage.past_due_amount,
          property_address: mortgage.property_address ? {
            city: mortgage.property_address.city,
            country: mortgage.property_address.country,
            postal_code: mortgage.property_address.postal_code,
            region: mortgage.property_address.region,
            street: mortgage.property_address.street,
          } : null,
          servicer_address: mortgage.servicer_address ? {
            city: mortgage.servicer_address.city,
            country: mortgage.servicer_address.country,
            postal_code: mortgage.servicer_address.postal_code,
            region: mortgage.servicer_address.region,
            street: mortgage.servicer_address.street,
          } : null,
          ytd_interest_paid: mortgage.ytd_interest_paid,
          ytd_principal_paid: mortgage.ytd_principal_paid,
        })),
        student: response.data.liabilities.student?.map(student => ({
          account_id: student.account_id,
          account_number: student.account_number,
          disbursement_dates: student.disbursement_dates,
          expected_payoff_date: student.expected_payoff_date,
          guarantor: student.guarantor,
          interest_rate_percentage: student.interest_rate_percentage,
          is_overdue: student.is_overdue,
          last_payment_amount: student.last_payment_amount,
          last_payment_date: student.last_payment_date,
          last_statement_issue_date: student.last_statement_issue_date,
          loan_name: student.loan_name,
          loan_status: {
            type: student.loan_status.type,
            end_date: student.loan_status.end_date,
          },
          minimum_payment_amount: student.minimum_payment_amount,
          next_payment_due_date: student.next_payment_due_date,
          origination_date: student.origination_date,
          origination_principal_amount: student.origination_principal_amount,
          outstanding_interest_amount: student.outstanding_interest_amount,
          payment_reference_number: student.payment_reference_number,
          pslf_status: student.pslf_status,
          repayment_plan: student.repayment_plan ? {
            type: student.repayment_plan.type,
            description: student.repayment_plan.description,
          } : null,
          sequence_number: student.sequence_number,
          servicer_address: student.servicer_address ? {
            city: student.servicer_address.city,
            country: student.servicer_address.country,
            postal_code: student.servicer_address.postal_code,
            region: student.servicer_address.region,
            street: student.servicer_address.street,
          } : null,
          ytd_interest_paid: student.ytd_interest_paid,
          ytd_principal_paid: student.ytd_principal_paid,
        })),
      },
      item: response.data.item,
      total_debt: calculateTotalDebt(response.data.accounts),
      credit_utilization: calculateCreditUtilization(response.data.liabilities.credit, response.data.accounts),
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
    console.error("Plaid Liabilities API Error:", error);
    return new Response(
      JSON.stringify({ 
        error: "Failed to fetch liabilities data", 
        details: String(error) 
      }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } }
    );
  }
});

// Helper functions
function calculateTotalDebt(accounts: any[]): number {
  return accounts
    .filter(account => account.type === 'credit' || account.type === 'loan')
    .reduce((sum, account) => sum + (account.balances.current || 0), 0);
}

function calculateCreditUtilization(creditAccounts: any[] | undefined, allAccounts: any[]): number {
  if (!creditAccounts || creditAccounts.length === 0) return 0;
  
  const creditData = allAccounts.filter(account => account.type === 'credit');
  const totalUsed = creditData.reduce((sum, account) => sum + (account.balances.current || 0), 0);
  const totalAvailable = creditData.reduce((sum, account) => sum + (account.balances.limit || 0), 0);
  
  return totalAvailable > 0 ? (totalUsed / totalAvailable) * 100 : 0;
}