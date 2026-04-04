[2026-04-04 00:42] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "API mismatch",
    "EXPECTATION": "Use existing repository methods or implement missing ones so the code compiles.",
    "NEW INSTRUCTION": "WHEN compiler error shows missing member THEN align calls to existing repository API"
}

[2026-04-04 00:58] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Package ID input",
    "EXPECTATION": "Users should not manually enter package IDs; the system should auto-generate IDs and restrict enum fields to valid options.",
    "NEW INSTRUCTION": "WHEN user form includes package id THEN remove field and auto-generate on backend"
}

[2026-04-04 01:05] - Updated by Junie
{
    "TYPE": "positive",
    "CATEGORY": "UI top bar",
    "EXPECTATION": "The CustomTopBar update works correctly and meets the user's needs.",
    "NEW INSTRUCTION": "WHEN adding or updating any page or dialog header THEN use the CustomTopBar component"
}

[2026-04-04 01:06] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Enum validation error",
    "EXPECTATION": "Use a Tier reference (ObjectId) instead of an enum for package/tier fields so values like IDs do not trigger enum validation errors.",
    "NEW INSTRUCTION": "WHEN modeling member package or saving selection THEN use ObjectId ref 'Tier' not enum"
}

[2026-04-04 01:15] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Enum removal ripple",
    "EXPECTATION": "Attendance repository should not use the MemberTier enum; it must use dynamic Tier refs/labels consistent with the new model.",
    "NEW INSTRUCTION": "WHEN compile error mentions 'MemberTier not found' THEN replace with Tier ObjectId and dynamic label"
}

[2026-04-04 01:20] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Attendance target collection",
    "EXPECTATION": "Adding attendance should create records in the Attendance collection and show on the Attendance screen, not in Members.",
    "NEW INSTRUCTION": "WHEN saving attendance on backend THEN persist to Attendance model and not Member"
}

[2026-04-04 01:24] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "UI data labels",
    "EXPECTATION": "Show package name (not MongoDB ObjectId) in Members table, and combine Attendance status and action into a single button that reflects and toggles the current state.",
    "NEW INSTRUCTION": "WHEN rendering member package or attendance status THEN show human-readable label and use single status toggle button"
}

[2026-04-04 01:26] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Payments UX and validation",
    "EXPECTATION": "Replace long dropdowns with a searchable list (show ~5 results) and include a required plan/package field so payments save successfully.",
    "NEW INSTRUCTION": "WHEN payment save errors 'plan required' THEN add plan selector and send Tier ObjectId"
}

[2026-04-04 01:27] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Top bar not replaced",
    "EXPECTATION": "All screens and dialogs should use the CustomTopBar instead of the default app bar.",
    "NEW INSTRUCTION": "WHEN a page or dialog still shows the default AppBar THEN replace it with CustomTopBar"
}

[2026-04-04 01:32] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Window chrome clarification",
    "EXPECTATION": "By 'top bar', the user means the desktop window title bar with close/minimize buttons, and they want a custom one instead of the default.",
    "NEW INSTRUCTION": "WHEN building desktop window top bar THEN implement custom draggable title bar with close/minimize buttons"
}

[2026-04-04 01:33] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Window chrome meaning",
    "EXPECTATION": "By top bar, the user means the desktop window title bar with close/minimize buttons, and they want a custom one instead of the default.",
    "NEW INSTRUCTION": "WHEN user mentions 'top bar' on desktop THEN implement custom draggable title bar with close/minimize"
}

[2026-04-04 01:37] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Missing dependency",
    "EXPECTATION": "If using window_manager APIs, the dependency must be added and configured so the app compiles.",
    "NEW INSTRUCTION": "WHEN using window_manager in code THEN add pubspec dependency and desktop platform setup"
}

[2026-04-04 01:44] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Window manager plugin",
    "EXPECTATION": "window_manager must be properly registered on desktop so ensureInitialized works without MissingPluginException.",
    "NEW INSTRUCTION": "WHEN error MissingPluginException ensureInitialized window_manager THEN complete desktop setup, flutter clean, and rerun app (not hot restart)"
}

[2026-04-04 01:50] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Payment type mismatch",
    "EXPECTATION": "Fix the payment page crash by ensuring fields that require String IDs (e.g., memberId, plan) are not sent as Map objects.",
    "NEW INSTRUCTION": "WHEN runtime says \"Map<String, dynamic> is not a subtype of String\" on Payments THEN send Tier ObjectId and memberId as strings, not full objects"
}

[2026-04-04 01:53] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Data binding mismatch",
    "EXPECTATION": "Members table should show existing backend members, and Attendance table should not display entries if there are no attendance records.",
    "NEW INSTRUCTION": "WHEN backend has members but Members UI empty THEN verify members API route and list mapping"
}

[2026-04-04 01:59] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Top bar styling",
    "EXPECTATION": "Use the text design style from the 'stitch_owner_login' project for the top bar labels and keep the existing bottom border.",
    "NEW INSTRUCTION": "WHEN updating desktop top bar text THEN match stitch_owner_login typography and keep bottom border"
}

[2026-04-04 02:02] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Top bar typography",
    "EXPECTATION": "Restore the previous design style: a large title where the first word is white and the second word (if present) is gray and italic; remove the 'Kinetic' label from page tops and keep a full-width bottom border.",
    "NEW INSTRUCTION": "WHEN rendering top bar title THEN use large title; first word white; second word gray italic; add bottom border"
}

[2026-04-04 02:03] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Top bar typography",
    "EXPECTATION": "Restore the previous header style: large title with first word white, second word gray italic; remove the 'Kinetic' label; keep a full-width bottom border.",
    "NEW INSTRUCTION": "WHEN rendering a page or dialog header THEN Use large title; first white, second gray italic; remove 'Kinetic'; add bottom border"
}

[2026-04-04 02:04] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Top bar typography",
    "EXPECTATION": "Restore previous header style: large title, first word white, second word gray italic, remove 'Kinetic', and keep a full-width bottom border.",
    "NEW INSTRUCTION": "WHEN rendering a page or dialog header THEN use large title; first white; second gray italic; remove 'Kinetic'; add bottom border"
}

[2026-04-04 02:05] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Realtime refresh",
    "EXPECTATION": "Screens should update immediately after data changes, without leaving and returning to the page.",
    "NEW INSTRUCTION": "WHEN backend data changes on current screen THEN refresh list/state immediately without navigation"
}

[2026-04-04 02:11] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Dashboard labels",
    "EXPECTATION": "Display package names (not MongoDB ObjectIds) for tiers on the Dashboard table and pie chart.",
    "NEW INSTRUCTION": "WHEN rendering dashboard tier data THEN show package name label instead of ObjectId"
}

[2026-04-04 02:14] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Login top bar",
    "EXPECTATION": "The login page must have the custom draggable window title bar with window buttons, without logo or extra actions.",
    "NEW INSTRUCTION": "WHEN rendering the desktop login screen THEN add custom draggable title bar with window buttons only"
}

[2026-04-04 02:30] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Dialog top bar",
    "EXPECTATION": "Pop-up dialogs should not include the CustomTopBar; remove the header from dialogs.",
    "NEW INSTRUCTION": "WHEN rendering a modal dialog or popup THEN omit CustomTopBar and any header bar"
}

[2026-04-04 02:41] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Overdue metrics",
    "EXPECTATION": "Overdue counts should reflect unpaid payments past their dueDate across Payments and Dashboard, not always 0.",
    "NEW INSTRUCTION": "WHEN computing overdue counts THEN count payments with dueDate < now and status != 'paid'"
}

[2026-04-04 02:50] - Updated by Junie
{
    "TYPE": "correction",
    "CATEGORY": "Overdue metrics zero",
    "EXPECTATION": "Overdue counts should increase for unpaid payments past their dueDate, not always show 0.",
    "NEW INSTRUCTION": "WHEN creating or editing a payment THEN require dueDate and forbid empty or zero values"
}

