import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

import { handleRevenueCatWebhook } from "./handler.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

serve((request) =>
  handleRevenueCatWebhook(request, {
    webhookSecret: Deno.env.get("REVENUECAT_WEBHOOK_SECRET") ?? "",
    upsertSubscription: async (payload) => {
      const { data, error } = await supabase.rpc(
        "upsert_user_subscription_if_newer",
        { payload },
      );

      if (error != null) {
        throw error;
      }

      return data === true;
    },
  })
);
