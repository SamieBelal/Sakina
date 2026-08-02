# Lane Agent Operating Protocol (2026-06-01 full regression)

Shared rules for every parallel lane agent. Read this first, then your lane section in
`docs/qa/plans/2026-06-01-full-regression-sim-test-plan.md`.

## Your environment
- **App bundle id:** `com.sakina.app.sakina`
- **Your simulator:** use the UDID given in your brief. **Pass `udid=<your UDID>` on EVERY `ios-simulator` MCP call.** Never touch another lane's sim.
- App is already installed + the welcome screen may be open. Relaunch fresh with `launch_app(udid, bundle_id, terminate_running=true)` when you need a clean start.
- **Backend is PRODUCTION.** Only ever create/seed/read YOUR OWN test accounts. Never UPDATE/DELETE rows you didn't create. RLS protects other users — rely on it. Clean up your test accounts at the end with the in-app delete-account flow if feasible.

## Loading MCP tools
Before first use, load schemas with ToolSearch, e.g.:
`ToolSearch("select:mcp__ios-simulator__launch_app,mcp__ios-simulator__ui_describe_all,mcp__ios-simulator__ui_tap,mcp__ios-simulator__ui_type,mcp__ios-simulator__ui_swipe,mcp__ios-simulator__screenshot,mcp__supabase__execute_sql,mcp__mixpanel__Run-Query")`
Call Mixpanel `Get-Business-Context` once before other Mixpanel calls.

## Driving the UI
1. `ui_describe_all(udid)` → returns on-screen elements with frames. Compute tap point = frame center.
2. `ui_tap(udid, x, y)` to tap; `ui_type(udid, text)` to type into the focused field; `ui_swipe` to scroll.
3. After any meaningful action: `screenshot(udid, output_path=".../screens/<lane>-<step>.png")`, then in Bash `sips -Z 1600 <path>` (REQUIRED — native @3x trips the image cap), then `Read` the png to visually verify.
4. If you can't find a target after 2 `ui_describe_all` attempts: screenshot, record what you see, mark the step BLOCKED, and move on. Do not loop forever.

## Account creation (autoconfirm is ON — no email step)
- From welcome: "Get Started" → walk onboarding → at the email/password screen use a unique plain email like `sakinaqa.<lane>.<n>@gmail.com` (no `+`; client validation is strict) and password `SakinaQA!2026`.
- Record the resulting `auth.uid()` — find it with: `select id,email,created_at from auth.users order by created_at desc limit 5;` (match your email).

## Verifying each layer
- **UI:** screenshot + describe; assert the expected widget/state is present and Arabic/English don't bleed (RTL).
- **DB:** `execute_sql` SELECTs scoped to your user_id. Quote the rows in your report.
- **Analytics:** after firing events, wait ~90s, then Mixpanel `Run-Query` for your event names filtered to a property you can identify (e.g. recent timestamp). Note ingestion lag; if an event isn't visible yet, say "not yet visible" rather than "missing".

## Output (do this as you go, not just at the end)
- **Run log:** `docs/qa/runs/2026-06-01-full-regression/lane-<X>.md` — table of test case → PASS/FAIL/BLOCKED, with the DB rows / analytics results / screenshot paths as evidence.
- **Bugs:** one file per real bug at `docs/qa/findings/2026-06-01-<short-slug>.md` (severity, repro steps, expected vs actual, evidence). Cross-link from your run log.
- Keep going through ALL your lane's cases even if some fail. Your final message back should be a concise summary: counts of PASS/FAIL/BLOCKED + the headline bugs.
