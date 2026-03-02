## Why

In the SRTM (Security Requirements Traceability Matrix) view, users care most about in-scope controls, but they are currently displayed last in both the tab order and percentage summary. This buries the most important information and requires unnecessary navigation to reach it.

## What Changes

- Reorder percentage display boxes at the top of the SRTM page: In scope, Out of scope, Not allocated (currently: Not allocated, Out of scope, In scope)
- Reorder tabs in the SRTM view: In scope, Out of scope, Not allocated (currently: Not allocated, Out of scope, In scope)
- Adjust layout structure to maintain visual hierarchy with In scope and Out of scope sharing 8 columns (left), and Not allocated taking 4 columns (right)
- Update CSS classes for proper border rendering in the new layout order

## Capabilities

### New Capabilities
- `srtm-tab-ordering`: Define the display order for SRTM tabs and percentage summaries, prioritizing in-scope controls

### Modified Capabilities
<!-- No existing specs are being modified - this is a presentation-layer change only -->

## Impact

**Affected Files:**
- `lib/valentine_web/live/workspace_live/srtm/index.html.heex` - Template file containing the percentage display boxes and tab component configuration

**User Experience:**
- Improved usability by surfacing the most relevant information (in-scope controls) first
- More consistent visual flow from most important to least important information
- Reduced cognitive load by eliminating the need to scroll past less relevant data

**Technical Impact:**
- Low risk: Pure presentational change with no business logic modifications
- No database changes required
- No API or backend changes required
- Layout remains responsive across mobile and desktop viewports
