# Real-World Gym App Upgrade Todo

Status key:
- `[ ]` pending
- `[~]` in progress
- `[x]` completed

## Phase 0: Foundation
- `[x]` Audit current app flows for packages, members, payments, attendance, and settings
- `[x]` Define production-grade domain model for packages, memberships, subscriptions, payments, and lifecycle actions
- `[ ]` Add migration notes for current data compatibility
- `[x]` Confirm manual payment collection scope for now
  - No payment gateway integration in this phase
  - Staff creates billing records and marks them as received manually

## Phase 1: Package Foundation
- `[~]` Upgrade package schema from basic tier data to production-ready package data
- `[x]` Add package fields: `description`, `billingCycle`, `joiningFee`, `status`, `isArchived`
- `[x]` Replace destructive package deletion with archive behavior
- `[ ]` Prevent archiving packages that would break active member assignments without clear handling
- `[x]` Upgrade package CRUD validation on backend
- `[x]` Upgrade Flutter package repository/model for richer package data
- `[x]` Rebuild package management UI for better CRUD flow
- `[x]` Show active vs archived packages in admin UI

## Phase 2: Member Subscription Model
- `[~]` Introduce a subscription/membership record instead of relying only on `member.tier`
- `[~]` Store current package snapshot, billing amount, start date, and next billing date
- `[ ]` Add package change workflow with `immediate` and `next_cycle` effective modes
- `[ ]` Add member lifecycle states: `active`, `overdue`, `frozen`, `cancelled`, `expired`
- `[ ]` Preserve package history when members change plans

## Phase 3: Billing and Payment Operations
- `[~]` Refactor payments into billing records with package/price snapshots
- `[~]` Add billing period start/end dates
- `[~]` Add payment methods, receipt/reference number, notes, discounts, and balance
- `[ ]` Support statuses such as `pending`, `partial`, `paid`, `overdue`, `cancelled`
- `[ ]` Update payments page to behave like an invoice/payment operations screen
- `[ ]` Auto-sync member billing state from billing records instead of stale manual flags

## Phase 4: Attendance and Access Rules
- `[ ]` Link attendance behavior to member/subscription state
- `[ ]` Define access rules for overdue, frozen, and expired memberships
- `[ ]` Surface alerts for members needing staff attention

## Phase 5: Reporting and Admin Operations
- `[ ]` Dashboard metrics for revenue, overdue members, expiring memberships, and package mix
- `[ ]` Reports for due today, overdue invoices, and package performance
- `[ ]` Add operational actions for freeze, cancel, rejoin, and manual adjustments

## Phase 6: Validation
- `[ ]` Run backend smoke validation for package/member/payment flows
- `[ ]` Run Flutter analysis and focused manual UI checks
- `[ ]` Update this checklist as each implementation slice lands
