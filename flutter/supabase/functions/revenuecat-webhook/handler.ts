const PREMIUM_ENTITLEMENT = "premium";
const ANONYMOUS_PREFIX = "$RCAnonymousID:";
const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const ACTIVE_LIFECYCLE_EVENT_TYPES = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "PRODUCT_CHANGE",
  "UNCANCELLATION",
]);

export const HANDLED_EVENT_TYPES = new Set([
  ...ACTIVE_LIFECYCLE_EVENT_TYPES,
  "CANCELLATION",
  "BILLING_ISSUE",
  "EXPIRATION",
]);

export interface RevenueCatEvent {
  type?: string | null;
  app_user_id?: string | null;
  original_app_user_id?: string | null;
  aliases?: string[] | null;
  entitlement_ids?: string[] | null;
  product_id?: string | null;
  new_product_id?: string | null;
  store?: string | null;
  environment?: string | null;
  expiration_at_ms?: number | null;
  event_timestamp_ms?: number | null;
}

export interface UserSubscriptionUpsert {
  user_id: string;
  entitlement: string;
  product_id: string;
  store: string | null;
  environment: string | null;
  revenuecat_app_user_id: string | null;
  revenuecat_original_app_user_id: string | null;
  aliases: string[];
  expires_at: string | null;
  canceled_at?: string | null;
  billing_issue_detected_at?: string | null;
  last_event_type: string;
  last_event_at: string | null;
  updated_at: string;
}

interface HandleWebhookOptions {
  webhookSecret: string;
  // Returns true if the upsert wrote/updated a row, false if the incoming
  // event was older than the stored last_event_at and therefore ignored.
  upsertSubscription: (payload: UserSubscriptionUpsert) => Promise<boolean>;
}

function jsonResponse(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
    },
  });
}

export function isAnonymousRevenueCatUserId(
  value: string | null | undefined,
): boolean {
  return Boolean(value && value.startsWith(ANONYMOUS_PREFIX));
}

export function isUuid(value: string | null | undefined): value is string {
  return Boolean(value && UUID_REGEX.test(value));
}

function nonEmptyString(value: string | null | undefined): string | null {
  if (value == null) return null;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

export function resolveStableUserId(event: RevenueCatEvent): string | null {
  const aliases = Array.isArray(event.aliases)
    ? event.aliases.filter((alias) => nonEmptyString(alias) != null)
    : [];

  const appUserId = nonEmptyString(event.app_user_id);
  if (appUserId != null && !isAnonymousRevenueCatUserId(appUserId)) {
    return appUserId;
  }

  const originalAppUserId = nonEmptyString(event.original_app_user_id);
  if (
    originalAppUserId != null &&
    !isAnonymousRevenueCatUserId(originalAppUserId)
  ) {
    return originalAppUserId;
  }

  return aliases.find((alias) => !isAnonymousRevenueCatUserId(alias)) ?? null;
}

function msToIsoString(value: number | null | undefined): string | null {
  if (typeof value !== "number" || Number.isNaN(value)) return null;
  return new Date(value).toISOString();
}

function hasPremiumEntitlement(event: RevenueCatEvent): boolean {
  return Array.isArray(event.entitlement_ids) &&
    event.entitlement_ids.includes(PREMIUM_ENTITLEMENT);
}

export function buildUserSubscriptionUpsert(
  event: RevenueCatEvent,
): UserSubscriptionUpsert | null {
  const eventType = nonEmptyString(event.type);
  if (eventType == null || !HANDLED_EVENT_TYPES.has(eventType)) {
    return null;
  }

  if (!hasPremiumEntitlement(event)) {
    return null;
  }

  const userId = resolveStableUserId(event);
  if (
    userId == null || isAnonymousRevenueCatUserId(userId) || !isUuid(userId)
  ) {
    return null;
  }

  const productId = nonEmptyString(
    eventType === "PRODUCT_CHANGE"
      ? event.new_product_id ?? event.product_id
      : event.product_id,
  );
  if (productId == null) {
    return null;
  }

  const lastEventAt = msToIsoString(event.event_timestamp_ms);
  const expiresAt = msToIsoString(event.expiration_at_ms);
  const aliases = Array.isArray(event.aliases) ? event.aliases : [];
  const payload: UserSubscriptionUpsert = {
    user_id: userId,
    entitlement: PREMIUM_ENTITLEMENT,
    product_id: productId,
    store: nonEmptyString(event.store),
    environment: nonEmptyString(event.environment),
    revenuecat_app_user_id: nonEmptyString(event.app_user_id),
    revenuecat_original_app_user_id: nonEmptyString(event.original_app_user_id),
    aliases,
    expires_at: expiresAt,
    last_event_type: eventType,
    last_event_at: lastEventAt,
    updated_at: new Date().toISOString(),
  };

  if (ACTIVE_LIFECYCLE_EVENT_TYPES.has(eventType)) {
    payload.canceled_at = null;
    payload.billing_issue_detected_at = null;
  } else if (eventType === "CANCELLATION") {
    payload.canceled_at = lastEventAt;
  } else if (eventType === "BILLING_ISSUE") {
    payload.billing_issue_detected_at = lastEventAt;
  }

  return payload;
}

export function hasActivePremiumAccess(
  subscription: Pick<UserSubscriptionUpsert, "expires_at">,
  now: Date = new Date(),
): boolean {
  if (subscription.expires_at == null) return true;
  return new Date(subscription.expires_at).getTime() > now.getTime();
}

export async function handleRevenueCatWebhook(
  request: Request,
  options: HandleWebhookOptions,
): Promise<Response> {
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  if (!options.webhookSecret) {
    return jsonResponse(500, { error: "Webhook secret not configured" });
  }

  const authorization = request.headers.get("Authorization");
  if (authorization !== `Bearer ${options.webhookSecret}`) {
    return jsonResponse(401, { error: "Unauthorized" });
  }

  let body: { event?: RevenueCatEvent } | null = null;
  try {
    body = await request.json();
  } catch {
    return jsonResponse(400, { error: "Invalid JSON body" });
  }

  const event = body?.event;
  if (event == null || typeof event !== "object") {
    return jsonResponse(400, { error: "Missing event payload" });
  }

  const payload = buildUserSubscriptionUpsert(event);
  if (payload == null) {
    return jsonResponse(200, { status: "skipped" });
  }

  let written: boolean;
  try {
    written = await options.upsertSubscription(payload);
  } catch (error) {
    console.error("revenuecat-webhook upsert failed", error);
    return jsonResponse(500, { error: "Failed to persist subscription event" });
  }

  if (!written) {
    return jsonResponse(200, { status: "skipped", reason: "stale_event" });
  }

  return jsonResponse(200, { status: "ok" });
}
