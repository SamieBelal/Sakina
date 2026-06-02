import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

import { handleRevenueCatWebhook } from "./handler.ts";
import { mixpanelTrack, subscriptionEventName } from "../_shared/mixpanel.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

// Reuses the OneSignal env + request shape established by notify-referral-confirmed
// (modern v2: include_aliases.external_id + target_channel, `Authorization: Key`).
const oneSignalAppId = Deno.env.get("ONESIGNAL_APP_ID") ?? "";
const oneSignalRestApiKey = Deno.env.get("ONESIGNAL_API_KEY") ?? "";

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

      // The RPC returns { written, cancellation_started }.
      return {
        written: data?.written === true,
        cancellationStarted: data?.cancellation_started === true,
      };
    },
    trackSubscriptionEvent: async (payload) => {
      // Subscription-lifecycle churn analytics. Best-effort; mixpanelTrack
      // no-ops without MIXPANEL_TOKEN and never throws.
      const event = subscriptionEventName(payload.last_event_type);
      if (event == null) return;
      await mixpanelTrack(event, payload.user_id, {
        product_id: payload.product_id,
        store: payload.store,
        period_type: payload.period_type,
        is_trial: payload.period_type === "trial",
        environment: payload.environment,
      });
    },
    sendCancellationSurveyPush: async (payload) => {
      // TODO(launch): REMOVE this sandbox gate once the app build containing the
      // cancellation survey + sakina://cancellation-feedback deep link is LIVE on
      // the App Store. Until then, production users have no survey UI, so a push
      // would dead-end at the home screen — so we only fire for SANDBOX (test
      // devices) during pre-launch verification. Removing the gate is a
      // server-only edge-function redeploy; no App Store update needed.
      if (payload.environment !== "SANDBOX") return;

      // Best-effort. The handler isolates failures, but bail early if OneSignal
      // is unconfigured so we don't make a doomed request.
      if (!oneSignalAppId || !oneSignalRestApiKey) return;

      const response = await fetch("https://api.onesignal.com/notifications", {
        method: "POST",
        headers: {
          Authorization: `Key ${oneSignalRestApiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          app_id: oneSignalAppId,
          include_aliases: { external_id: [payload.user_id] },
          target_channel: "push",
          headings: { en: "Before you go" },
          contents: {
            en: "We'd love to know why — it takes 10 seconds. 🌙",
          },
          data: { type: "cancellation_feedback" },
        }),
      });

      if (!response.ok) {
        // Surface for logs; the handler swallows the throw so billing sync is
        // unaffected.
        throw new Error(
          `OneSignal cancellation push non-2xx: ${response.status}`,
        );
      }
    },
    clawbackConsumable: async (payload) => {
      // The RPC is idempotent on transaction_id, so retries from RC are
      // safe. Errors propagate to the caller, which converts them into a
      // 500 so RC will retry.
      const { error } = await supabase.rpc("clawback_consumable_grant", {
        p_user_id: payload.user_id,
        p_sku: payload.sku,
        p_kind: payload.kind,
        p_amount: payload.amount,
        p_transaction_id: payload.transaction_id,
        p_event_timestamp: payload.event_timestamp,
      });

      if (error != null) {
        throw error;
      }
    },
  })
);
