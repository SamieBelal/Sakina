import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

type EligibleUser = {
  user_id: string;
  timezone: string;
  display_name: string | null;
  current_streak: number;
  last_active: string | null;
};

type NotificationType = {
  key: string;
  prefColumn: string;
  sentColumn: string;
  targetHour: number;
  requiresStreak: boolean;
  inactiveDays?: number;
  dayOfWeek?: number;
  title: (row: EligibleUser) => string;
  message: (row: EligibleUser) => string;
  dataType: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const NOTIFICATION_TYPES: NotificationType[] = [
  {
    key: "daily",
    prefColumn: "notify_daily",
    sentColumn: "last_daily_sent_at",
    targetHour: 9,
    requiresStreak: false,
    title: (row) =>
      row.display_name ? `Assalamu Alaikum, ${row.display_name}` : "Sakina",
    message: () => "Take a moment with Sakina today.",
    dataType: "daily_reminder",
  },
  {
    key: "streak",
    prefColumn: "notify_streak",
    sentColumn: "last_streak_sent_at",
    targetHour: 20,
    requiresStreak: true,
    title: () => "Protect your streak",
    message: (row) =>
      row.current_streak > 0
        ? `Keep your ${row.current_streak}-day streak alive today.`
        : "Check in with Sakina today.",
    dataType: "streak_risk",
  },
  {
    key: "reengagement",
    prefColumn: "notify_reengagement",
    sentColumn: "last_reengagement_sent_at",
    targetHour: 11,
    inactiveDays: 3,
    requiresStreak: false,
    title: (row) =>
      row.display_name ? `We miss you, ${row.display_name}` : "We miss you",
    message: () => "Take a moment with Sakina today.",
    dataType: "reengagement",
  },
  {
    key: "weekly_reflection",
    prefColumn: "notify_weekly",
    sentColumn: "last_weekly_sent_at",
    targetHour: 18,
    dayOfWeek: 5,
    inactiveDays: -1, // skip activity filter; weekly fires regardless of check-in status
    requiresStreak: false,
    title: () => "Your week with Sakina",
    message: () => "Take a moment to reflect on your week.",
    dataType: "weekly_reflection",
  },
];

function jsonResponse(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

async function sendOneSignalNotification(params: {
  appId: string;
  restApiKey: string;
  userId: string;
  title: string;
  message: string;
  dataType: string;
}): Promise<boolean> {
  const response = await fetch("https://api.onesignal.com/notifications", {
    method: "POST",
    headers: {
      Authorization: `Key ${params.restApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      app_id: params.appId,
      include_aliases: {
        external_id: [params.userId],
      },
      target_channel: "push",
      headings: { en: params.title },
      contents: { en: params.message },
      data: { type: params.dataType },
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error("onesignal send failed", {
      userId: params.userId,
      status: response.status,
      errorText,
    });
    return false;
  }

  return true;
}

async function markSent(
  supabase: any,
  userIds: string[],
  sentColumn: string,
) {
  if (userIds.length === 0) return;

  const { error } = await supabase
    .from("user_notification_preferences")
    .update({ [sentColumn]: new Date().toISOString() })
    .in("user_id", userIds);

  if (error) {
    throw error;
  }
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const oneSignalAppId = Deno.env.get("ONESIGNAL_APP_ID");
  const oneSignalRestApiKey = Deno.env.get("ONESIGNAL_API_KEY");

  if (
    !supabaseUrl || !serviceRoleKey || !oneSignalAppId || !oneSignalRestApiKey
  ) {
    return jsonResponse(500, {
      error:
        "Missing SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, ONESIGNAL_APP_ID, or ONESIGNAL_API_KEY",
    });
  }

  const authHeader = request.headers.get("Authorization");
  if (
    authHeader !== null && authHeader !== `Bearer ${serviceRoleKey}`
  ) {
    return jsonResponse(401, { error: "Unauthorized" });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const summary: Record<string, unknown> = {};

  try {
    for (const notificationType of NOTIFICATION_TYPES) {
      const { data, error } = await supabase.rpc(
        "get_eligible_notification_users",
        {
          p_pref_column: notificationType.prefColumn,
          p_sent_column: notificationType.sentColumn,
          p_target_hour: notificationType.targetHour,
          p_requires_streak: notificationType.requiresStreak,
          p_inactive_days: notificationType.inactiveDays ?? 0,
          p_day_of_week: notificationType.dayOfWeek ?? null,
        },
      );

      if (error) {
        throw error;
      }

      const users = (data ?? []) as EligibleUser[];

      if (users.length === 0) {
        summary[notificationType.key] = {
          eligible: 0,
          sent: 0,
          marked: 0,
        };
        continue;
      }

      let sent = 0;
      let marked = 0;

      if (notificationType.key === "reengagement") {
        for (const user of users) {
          const ok = await sendOneSignalNotification({
            appId: oneSignalAppId,
            restApiKey: oneSignalRestApiKey,
            userId: user.user_id,
            title: notificationType.title(user),
            message: notificationType.message(user),
            dataType: notificationType.dataType,
          });

          if (!ok) continue;

          sent += 1;
          await markSent(supabase, [user.user_id], notificationType.sentColumn);
          marked += 1;
        }
      } else {
        await markSent(
          supabase,
          users.map((user) => user.user_id),
          notificationType.sentColumn,
        );
        marked = users.length;

        for (const user of users) {
          const ok = await sendOneSignalNotification({
            appId: oneSignalAppId,
            restApiKey: oneSignalRestApiKey,
            userId: user.user_id,
            title: notificationType.title(user),
            message: notificationType.message(user),
            dataType: notificationType.dataType,
          });

          if (ok) {
            sent += 1;
          }
        }
      }

      summary[notificationType.key] = {
        eligible: users.length,
        sent,
        marked,
      };
    }

    return jsonResponse(200, {
      ok: true,
      summary,
    });
  } catch (error) {
    console.error("send-scheduled-notifications failed", error);
    return jsonResponse(500, {
      ok: false,
      error: error instanceof Error ? error.message : String(error),
      summary,
    });
  }
});
