## 1. Template Restructuring

- [x] 1.1 Update main container left column class from `col-10` to `col-8` in show.html.heex (line 16)
- [x] 1.2 Move NIST Controls section (lines 115-149) out of left column and prepare for right sidebar placement
- [x] 1.3 Move Tags section (lines 151-185) out of left column and prepare for right sidebar placement
- [x] 1.4 Ensure left column closing tag (`</div>`) is positioned after Description box (after line 113)

## 2. Right Sidebar Creation

- [x] 2.1 Add new right column div with class `float-left col-3 pl-4` after left column closing tag
- [x] 2.2 Add NIST Controls section to right sidebar with `.action_list_section_divider` header
- [x] 2.3 Add Tags section to right sidebar with `.action_list_section_divider` header
- [x] 2.4 Close right column div at end of sidebar content

## 3. Section Divider Formatting

- [x] 3.1 Wrap NIST Controls heading with `.action_list_section_divider` component (reference threat page lines 301-303)
- [x] 3.2 Add octicon icon to NIST Controls divider title (use appropriate icon like "shield-16" or "list-ordered-16")
- [x] 3.3 Wrap Tags heading with `.action_list_section_divider` component
- [x] 3.4 Add octicon icon to Tags divider title (use "tag-16" icon)

## 4. Styling Adjustments

- [x] 4.1 Remove `.box` wrapper around NIST Controls section (right sidebar doesn't use box styling per threat page pattern)
- [x] 4.2 Remove `.box` wrapper around Tags section
- [x] 4.3 Adjust spacing classes on NIST Controls form to work in sidebar context (may need to update `col-3` input width)
- [x] 4.4 Adjust spacing classes on Tags form to work in sidebar context

## 5. Verification

- [x] 5.1 Test evidence create page loads without errors
- [x] 5.2 Test evidence edit page loads without errors
- [x] 5.3 Verify NIST Controls add/remove functionality still works
- [x] 5.4 Verify Tags add/remove functionality still works
- [x] 5.5 Verify form validation and error display still works correctly
- [x] 5.6 Verify layout is responsive and works at different viewport widths
