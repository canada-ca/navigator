## 1. Reorder Percentage Display Boxes

- [x] 1.1 Locate the percentage display section in `lib/valentine_web/live/workspace_live/srtm/index.html.heex` (lines 63-126)
- [x] 1.2 Move the parent container div for Not allocated from col-md-4 to col-md-4 (keep size, change position to right)
- [x] 1.3 Move the parent container div for Out of scope + In scope from col-md-8 to col-md-8 (keep size, change position to left)
- [x] 1.4 Reorder the In scope box to be first within the col-md-8 container (move from lines 106-123 to first position)
- [x] 1.5 Update In scope box CSS classes: change `border rounded-right-2` to `border border-right-0 rounded-left-2`
- [x] 1.6 Reorder the Out of scope box to be second within the col-md-8 container (move from lines 88-105 to second position)
- [x] 1.7 Update Out of scope box CSS classes: change `border border-right-0 rounded-left-2` to `border rounded-right-2`
- [x] 1.8 Keep Not allocated box CSS classes unchanged: `border rounded-2`

## 2. Reorder Tab Navigation

- [x] 2.1 Locate the TabNavComponent tabs array in `lib/valentine_web/live/workspace_live/srtm/index.html.heex` (lines 131-135)
- [x] 2.2 Reorder the tabs array to: In scope (first), Out of scope (second), Not allocated (third)

## 3. Visual QA Testing

- [ ] 3.1 Start the Phoenix server and navigate to an SRTM view page
- [ ] 3.2 Verify percentage boxes appear in correct order on desktop: In scope (left-1st), Out of scope (left-2nd), Not allocated (right)
- [ ] 3.3 Verify In scope and Out of scope boxes appear as unified visual block with proper borders
- [ ] 3.4 Verify Not allocated box has all borders and rounded corners
- [ ] 3.5 Resize browser to mobile viewport (<768px) and verify boxes stack vertically in correct order
- [ ] 3.6 Verify tabs appear in correct order: In scope, Out of scope, Not allocated

## 4. Functional Testing

- [ ] 4.1 Click each tab and verify the correct control list displays
- [ ] 4.2 In the In scope tab, verify evidence filtering works (All, Needs evidence, Evidence attached)
- [ ] 4.3 Verify evidence counts display correctly for each filter option
- [ ] 4.4 Expand control details using "More information" and verify all metadata displays correctly
- [ ] 4.5 Verify evidence badges display correctly next to control IDs in the In scope tab
- [ ] 4.6 Test "Export to Excel" functionality and verify export includes all controls correctly

## 5. Cross-browser Testing

- [ ] 5.1 Test layout in Chrome/Edge (desktop and mobile viewports)
- [ ] 5.2 Test layout in Firefox (desktop and mobile viewports)
- [ ] 5.3 Test layout in Safari (desktop and mobile viewports)
