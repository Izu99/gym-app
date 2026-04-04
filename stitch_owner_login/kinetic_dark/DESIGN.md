# Design System Specification: High-Performance Athleticism

## 1. Overview & Creative North Star: "Kinetic Precision"
This design system is built to mirror the intensity of a high-end, late-night strength facility. The Creative North Star is **Kinetic Precision**. We are moving away from the "friendly SaaS" look toward a sophisticated, editorial aesthetic that feels engineered rather than drawn.

To break the "template" feel, we lean into **Intentional Asymmetry**. Large-scale typography (Display-LG) should bleed off edges or overlap container boundaries, creating a sense of movement. We avoid rigid, centered layouts in favor of dynamic, left-aligned compositions that guide the eye through high-contrast "action zones." This is not just a management tool; it is a digital adrenaline shot.

---

## 2. Colors & The Surface Manifesto
The palette is rooted in a "Pure Dark" philosophy. We use high-contrast accents to pull the user’s focus toward critical performance metrics and calls to action.

### The Palette
- **Primary (Electric Lime):** `#f4ffc9` (Main Action) and `#cefc22` (Container). This is the "pulse" of the app. Use it sparingly for maximum impact.
- **Secondary (Punchy Orange):** `#ff7441`. Reserved for secondary actions and high-energy status indicators (e.g., "Live Class").
- **Surface Hierarchy:** 
    - Base: `surface` (`#0e0e0e`)
    - Sections: `surface_container_low` (`#131313`)
    - Interaction Cards: `surface_container` (`#1a1a1a`)
    - Floating Modals: `surface_container_highest` (`#262626`)

### The "No-Line" Rule
**Prohibit 1px solid borders for sectioning.** To separate a workout schedule from a profile summary, do not draw a line. Instead, shift the background from `surface` to `surface_container_low`. Boundaries must be felt through tonal depth, not seen through strokes.

### The Glass & Gradient Rule
For hero elements (e.g., "Personal Best" cards), use a 15% opacity `primary` tint with a `backdrop-blur` of 20px. This "Glassmorphism" ensures the app feels premium and layered. Apply a subtle linear gradient from `primary` (`#f4ffc9`) to `primary_container` (`#cefc22`) on primary buttons to provide a metallic, high-performance "sheen."

---

## 3. Typography: The Athletic Editorial
Our typography is a blend of technical precision and bold, aggressive scales.

- **The Display Tier (Lexend):** Used for big numbers—reps, sets, and countdowns. `display-lg` (3.5rem) should be used for motivational headers or "PR" (Personal Record) numbers.
- **The Headline Tier (Lexend):** `headline-lg` (2rem) is the workhorse for page titles. It should always be bold and uppercase to maintain an authoritative, athletic tone.
- **The Label Tier (Space Grotesk):** This is our "technical" font. Used for data points, timestamps, and status tags (`label-md`). Its monospaced feel suggests a stopwatch or a digital readout.
- **The Body Tier (Manrope):** Used for instructional text and descriptions. Its clean, geometric sans-serif nature ensures readability against deep black backgrounds without causing eye strain.

---

## 4. Elevation & Depth: Tonal Layering
Traditional drop shadows are forbidden unless specified. We achieve "lift" through the **Layering Principle**.

- **Surface Stacking:** A user’s "Upcoming Class" card (`surface_container`) sits on the dashboard background (`surface`). The contrast between `#1a1a1a` and `#0e0e0e` provides all the separation needed.
- **The Ghost Border:** For accessibility in input fields or card groupings, use the `outline_variant` (`#484847`) at **20% opacity**. This creates a "whisper" of a boundary that defines the shape without cluttering the UI.
- **Ambient Glow:** Instead of a black shadow, floating "Action" buttons (FABs) should use a diffused glow of the `primary` color (`#cefc22`) at 10% opacity with a 30px blur. This makes the button feel like it’s emitting light, consistent with the "Electric Lime" theme.

---

## 5. Components

### Buttons
- **Primary:** Background `primary_container` (`#cefc22`), Text `on_primary_container` (`#4b5e00`). Sharp corners (Radius `sm`: `0.125rem`) to maintain a "tough" aesthetic.
- **Secondary:** Background `transparent`, Ghost Border (20% opacity `outline`), Text `primary`.
- **Tertiary:** Text only, uppercase `label-md` with `0.1rem` letter spacing.

### Cards & Progress
- **The "No-Divider" List:** Gym member lists or class schedules must not use lines. Use `spacing-4` (`0.9rem`) of vertical gap and alternating background tones (`surface_container_low` vs `surface_container`) to distinguish items.
- **Attendance Indicators:** Use `primary` for "Checked In" and `error` (`#ff7351`) for "Missed." These should be small, high-saturation pips or Space Grotesk labels.
- **Status Chips:** Use `secondary_container` for payment alerts. The contrast between the Orange and the Lime creates a clear hierarchy of "Urgency" vs "Action."

### Inputs
- **Field Styling:** Use `surface_container_highest` for the input background. No bottom line. Label in `label-sm` positioned above the field, never inside as a placeholder.

---

## 6. Do’s and Don’ts

### Do
- **Do** use `display-lg` for single, impactful numbers (e.g., "120kg").
- **Do** use `primary_dim` for hover states to create a "pressed" feeling.
- **Do** embrace negative space. Large gaps (`spacing-16`) between sections create an "Elite" gallery feel.
- **Do** use `tertiary` (`#ffe56b`) for "Premium" or "VIP" features to signify a higher tier of service.

### Don't
- **Don't** use pure white (`#ffffff`) for body text; use `on_surface_variant` (`#adaaaa`) to reduce glare on dark backgrounds.
- **Don't** use Rounded-Full (pills) for buttons. Keep them at `sm` or `none` to maintain the aggressive, athletic vibe.
- **Don't** use standard 1px dividers. If you feel the need to separate, use a `1px` height `surface_variant` block that only spans 40% of the container width (Asymmetric Detail).
- **Don't** use soft, "bubbly" animations. Use "Back-Out" or "Expo-Out" easing functions for transitions to mimic fast, explosive movement.