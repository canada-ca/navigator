// EnhancedSelect hook: provides a lightweight select2-like widget without external deps
// Features: search filtering, keyboard navigation, click outside close, LiveView friendly

function normalize(str) {
  return (str || "").toLowerCase();
}

const EnhancedSelect = {
  mounted() {
    this.inputEl = this.el.querySelector('[data-role="input"]');
    this.valueEl = this.el.querySelector('[data-role="value"]');
    this.listEl = this.el.querySelector('[data-role="list"]');
    this.emptyEl = this.el.querySelector('[data-role="empty"]');
    this.items = Array.from(this.listEl.querySelectorAll('.enh-select-item'));
    this.minChars = parseInt(this.el.dataset.minChars || '0', 10);
    this.activeIndex = this.items.findIndex(i => i.dataset.value === this.valueEl.value);

    this.boundDocClick = (e) => {
      if (!this.el.contains(e.target)) this.close();
    };

    this.inputEl.addEventListener('focus', () => this.open());
    this.inputEl.addEventListener('input', () => this.filter());
    this.inputEl.addEventListener('keydown', (e) => this.onKey(e));

    this.items.forEach((item, idx) => {
      item.addEventListener('click', () => this.select(idx));
      item.addEventListener('mousemove', () => (this.activeIndex = idx));
    });
  },
  destroyed() { document.removeEventListener('click', this.boundDocClick); },
  isOpen() { return !this.listEl.hasAttribute('hidden'); },
  open() {
    if (this.isOpen()) return;
    this.listEl.removeAttribute('hidden');
    this.inputEl.setAttribute('aria-expanded', 'true');
    document.addEventListener('click', this.boundDocClick);
    this.ensureVisible();
  },
  close() {
    if (!this.isOpen()) return;
    this.listEl.setAttribute('hidden', 'true');
    this.inputEl.setAttribute('aria-expanded', 'false');
    document.removeEventListener('click', this.boundDocClick);
  },
  filter() {
    const term = normalize(this.inputEl.value);
    let visibleCount = 0;
    this.items.forEach((item, idx) => {
      const label = normalize(item.dataset.label);
      const show = term.length < this.minChars || term === '' || label.includes(term);
      item.style.display = show ? '' : 'none';
      if (show) visibleCount++;
    });
    this.emptyEl.hidden = visibleCount !== 0;
    // Reset active index to first visible
    if (visibleCount > 0) {
      this.activeIndex = this.items.findIndex(i => i.style.display !== 'none');
    }
    // Auto-populate when a single option remains
    if (visibleCount === 1) {
      const onlyItem = this.items.find(i => i.style.display !== 'none');
      if (onlyItem) {
        // If nothing selected yet or selected differs, set both display and value
        const currentVal = this.valueEl.value;
        if (currentVal !== onlyItem.dataset.value) {
          this.inputEl.value = onlyItem.dataset.label;
          this.valueEl.value = onlyItem.dataset.value;
          // Keep internal active index aligned
          this.activeIndex = this.items.indexOf(onlyItem);
          this.highlight();
        }
      }
    }
  },
  onKey(e) {
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        if (!this.isOpen()) this.open();
        this.move(1);
        break;
      case 'ArrowUp':
        e.preventDefault();
        if (!this.isOpen()) this.open();
        this.move(-1);
        break;
      case 'Enter':
        if (this.isOpen() && this.activeIndex >= 0) {
          e.preventDefault();
          this.select(this.activeIndex);
        }
        break;
      case 'Escape':
        this.close();
        break;
    }
  },
  move(delta) {
    if (!this.items.length) return;
    let idx = this.activeIndex;
    const visible = this.items.filter(i => i.style.display !== 'none');
    if (!visible.length) return;
    const currentVisibleIndex = visible.indexOf(this.items[idx]);
    let nextVisibleIndex = (currentVisibleIndex + delta + visible.length) % visible.length;
    const nextEl = visible[nextVisibleIndex];
    this.activeIndex = this.items.indexOf(nextEl);
    this.highlight();
    this.ensureVisible();
  },
  highlight() {
    this.items.forEach(i => i.classList.remove('is-active'));
    if (this.activeIndex >= 0) this.items[this.activeIndex].classList.add('is-active');
  },
  ensureVisible() {
    if (this.activeIndex < 0) return;
    const el = this.items[this.activeIndex];
    if (el && el.style.display !== 'none') {
      const listRect = this.listEl.getBoundingClientRect();
      const elRect = el.getBoundingClientRect();
      if (elRect.top < listRect.top) this.listEl.scrollTop -= (listRect.top - elRect.top);
      else if (elRect.bottom > listRect.bottom) this.listEl.scrollTop += (elRect.bottom - listRect.bottom);
    }
  },
  select(idx) {
    const item = this.items[idx];
    if (!item) return;
    this.items.forEach(i => i.classList.remove('is-selected'));
    item.classList.add('is-selected');
    this.valueEl.value = item.dataset.value;
    this.inputEl.value = item.dataset.label;
    if (this.pushEventToggle) {
      this.pushEvent('enhanced_select_changed', { id: this.el.id, value: item.dataset.value });
    }
    this.close();
  }
};

export default EnhancedSelect;
