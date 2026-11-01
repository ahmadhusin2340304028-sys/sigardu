/* SIGARDU — core: API client (Bearer token seperti Flutter), auth, drawer, dialog, helper format. */
(function () {
  'use strict';
  const cfg = window.SIGARDU || {};
  const App = (window.App = {});
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
  const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  Object.assign(App, { $, $$, esc });

  App.MONTHS = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
  App.MONTHS_SHORT = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  App.num = v => { const n = parseFloat(v); return isNaN(n) ? 0 : n; };
  App.url = p => cfg.base + p;
  App.go = p => { location.href = cfg.base + p; };

  // ── Format (AppUtils) ────────────────────────────────────────────────────
  App.rp = n => 'Rp ' + Math.round(n).toLocaleString('id-ID');
  App.rpc = n => n >= 1e9 ? `Rp ${(n / 1e9).toFixed(1)} M` : n >= 1e6 ? `Rp ${(n / 1e6).toFixed(0)} Jt` : n >= 1e3 ? `Rp ${(n / 1e3).toFixed(0)} Rb` : `Rp ${n.toFixed(0)}`;
  App.date = d => `${String(d.getDate()).padStart(2, '0')} ${App.MONTHS_SHORT[d.getMonth()]} ${d.getFullYear()}`;
  // Ambil YYYY-MM-DD apa adanya supaya tidak bergeser zona waktu.
  App.parseDate = s => { const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(s)); return m ? new Date(+m[1], +m[2] - 1, +m[3]) : new Date(); };
  App.progressColor = p => p >= 80 ? 'var(--success)' : p >= 50 ? 'var(--primary-mid)' : 'var(--warning)';
  App.initials = n => {
    const p = String(n || '').trim().split(/[_\s]+/).filter(Boolean);
    if (p.length <= 1) return String(p[0] || 'U').slice(0, 2).toUpperCase();
    return (p[0][0] + p[1][0]).toUpperCase();
  };
  const BD = {
    'Perencanaan dan Keuangan': ['bd-pk', '#1A56DB'], 'Umum dan Kepegawaian': ['bd-uk', '#16A34A'],
    'Rehabilitasi Sosial': ['bd-rs', '#7C3AED'], 'Perlindungan dan Jaminan Sosial': ['bd-pj', '#D97706'],
    'Pemberdayaan Sosial': ['bd-ps', '#0891B2'], 'Pemberdayaan Masyarakat': ['bd-pm', '#65A30D']
  };
  App.bidangClass = n => (BD[n] || ['bd-def'])[0];
  App.bidangColor = n => (BD[n] || [0, '#64748B'])[1];

  // ── Komponen kecil ───────────────────────────────────────────────────────
  App.spinner = () => '<div class="center-pad"><div class="spin"></div></div>';
  App.state = (icon, text, extra = '') => `<div class="state"><span class="ms">${icon}</span><p>${esc(text)}</p>${extra}</div>`;
  App.bar = ({ label, value, target, color }) => {
    const p = (target > 0 ? Math.min(1, Math.max(0, value / target)) : 0) * 100, c = color || App.progressColor(p);
    return `<div class="pbar"><div class="pbar-top"><span>${esc(label)}</span><b style="color:${c}">${p.toFixed(1)}%</b></div><div class="track"><i data-w="${p}" style="background:${c}"></i></div></div>`;
  };
  App.mini = ({ label, pct, color, right }) =>
    `<div class="mini"><span class="mini-l">${label}</span><div class="track thin"><i data-w="${Math.min(100, Math.max(0, pct))}" style="background:${color}"></i></div><span class="mini-r" style="color:${color}">${right}</span></div>`;
  App.animate = (root = document) => requestAnimationFrame(() => requestAnimationFrame(() => {
    $$('[data-w]', root).forEach(i => { i.style.width = i.dataset.w + '%'; });
    $$('[data-h]', root).forEach(i => { i.style.height = i.dataset.h + 'px'; });
  }));

  // ── Toast (snackbar) ─────────────────────────────────────────────────────
  App.toast = (msg, type = 'info') => {
    let box = $('#toasts'); if (!box) { box = document.createElement('div'); box.id = 'toasts'; document.body.appendChild(box); }
    const ic = { success: 'check_circle', error: 'error', info: 'info' }[type];
    const el = document.createElement('div'); el.className = 't-' + type + ' toast';
    el.innerHTML = `<span class="ms">${ic}</span><span>${esc(msg)}</span>`;
    box.replaceChildren(el); setTimeout(() => el.remove(), 3000);
  };
  App.ok = m => App.toast(m, 'success'); App.err = m => App.toast(m, 'error'); App.info = m => App.toast(m, 'info');

  // ── Modal / dialog ───────────────────────────────────────────────────────
  App.modal = (html, cls = '') => {
    const o = document.createElement('div'); o.className = 'overlay ' + cls; o.innerHTML = html;
    document.body.appendChild(o); document.body.classList.add('noscroll');
    if (cls.includes('sheet')) o.addEventListener('mousedown', e => { if (e.target === o) App.close(o); });
    return o;
  };
  App.close = o => { o.remove(); if (!$('.overlay')) document.body.classList.remove('noscroll'); };
  App.confirm = ({ icon, color = 'danger', title, body = '', ok = 'Ya', okCls = 'btn-danger', cancel = 'Batal' }) => new Promise(res => {
    const o = App.modal(`<div class="dialog"><div class="dlg-title"><span class="ms" style="color:var(--${color});font-size:22px">${icon}</span>${title}</div><div class="dlg-body">${body}</div>
      <div class="dlg-actions"><button class="btn btn-text" data-r="0">${cancel}</button><button class="btn ${okCls}" data-r="1">${ok}</button></div></div>`);
    o.addEventListener('click', e => { const b = e.target.closest('[data-r]'); if (b) { App.close(o); res(b.dataset.r === '1'); } });
  });

  // ── Util ─────────────────────────────────────────────────────────────────
  App.debounce = (fn, ms) => { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; };
  App.infinite = (el, cb) => {
    const io = new IntersectionObserver(es => { if (es[0].isIntersecting) cb(); }, { rootMargin: '240px' });
    io.observe(el);
    return { recheck() { io.unobserve(el); io.observe(el); } };
  };
  App.saveBlob = (blob, name) => {
    const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = name;
    document.body.appendChild(a); a.click(); setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 1000);
  };
  App.pending = () => parseInt(sessionStorage.getItem('pending') || '0', 10) || 0;
  App.setPending = n => {
    sessionStorage.setItem('pending', n);
    $$('[data-pending]').forEach(el => { el.textContent = n; el.hidden = n <= 0; });
    const pill = $('#ab-pending'); if (pill) { pill.textContent = n + ' pending'; pill.hidden = n <= 0; }
  };
  App.errMsg = (d, fb = 'Terjadi kesalahan') => {
    if (!d) return fb;
    if (d.errors) { const f = Object.values(d.errors)[0]; return Array.isArray(f) ? f[0] : String(f); }
    return d.message || fb;
  };

  // ── Auth + API ───────────────────────────────────────────────────────────
  App.token = () => localStorage.getItem('token') || '';
  App.clearAuth = () => { localStorage.removeItem('token'); localStorage.removeItem('user'); sessionStorage.removeItem('pending'); };
  App.api = async (path, { method = 'GET', params, json, form, blob } = {}) => {
    let url = cfg.api + path;
    if (params) {
      const q = new URLSearchParams();
      Object.entries(params).forEach(([k, v]) => { if (v !== undefined && v !== null && v !== '') q.append(k, v); });
      const s = q.toString(); if (s) url += '?' + s;
    }
    const headers = { Accept: 'application/json' }, t = App.token();
    if (t) headers.Authorization = 'Bearer ' + t;
    const opt = { method, headers };
    if (json !== undefined) { headers['Content-Type'] = 'application/json'; opt.body = JSON.stringify(json); }
    if (form) opt.body = form;
    let res;
    try { res = await fetch(url, opt); } catch (e) { return { ok: false, status: 0, data: null, networkError: true }; }
    if (res.status === 401 && path !== '/login') { App.clearAuth(); App.go('/login'); return { ok: false, status: 401, data: null }; }
    if (blob && res.ok) return { ok: true, status: res.status, blob: await res.blob() };
    let data = null; try { data = await res.json(); } catch (e) { /* bukan JSON */ }
    return { ok: res.ok, status: res.status, data };
  };

  // ── Shell: drawer, tema, logout ──────────────────────────────────────────
  App.setTheme = d => { document.documentElement.dataset.theme = d ? 'dark' : 'light'; localStorage.setItem('theme_mode', d ? 'dark' : 'light'); };
  function wireShell(me) {
    const dw = $('#drawer'), sc = $('#scrim');
    if (dw) {
      $('#dw-av').firstChild.textContent = me.initials;
      $('#dw-name').textContent = me.username; $('#dw-role').textContent = me.label;
      $('#dw-av').classList.toggle('adm', me.isAdmin); $('#dw-sh').hidden = !me.isAdmin; $('#dw-admin').hidden = !me.isAdmin;
      const open = v => { dw.classList.toggle('open', v); sc.classList.toggle('open', v); };
      $$('[data-menu]').forEach(b => b.addEventListener('click', () => open(true)));
      sc.addEventListener('click', () => open(false));
      const sw = $('#theme-sw'), sync = () => {
        const d = App.isDark(); sw.checked = d;
        $('#th-ic').textContent = d ? 'dark_mode' : 'light_mode'; $('#th-t').textContent = d ? 'Mode Gelap' : 'Mode Terang'; $('#th-s').textContent = d ? 'Tema gelap aktif' : 'Tema terang aktif';
      };
      sw.addEventListener('change', () => { App.setTheme(sw.checked); sync(); }); sync();
      $('#logout-btn').addEventListener('click', async () => {
        open(false);
        const ok = await App.confirm({ icon: 'logout', title: 'Konfirmasi Keluar', body: 'Apakah Anda yakin ingin keluar dari aplikasi SIGARDU?', ok: 'Keluar' });
        if (!ok) return;
        await App.api('/logout', { method: 'POST' }); App.clearAuth(); App.go('/login');
      });
      App.setPending(App.pending());
    }
    $$('[data-refresh]').forEach(b => b.addEventListener('click', () => App.onRefresh && App.onRefresh()));
  }
  App.isDark = () => document.documentElement.dataset.theme === 'dark';

  // Panggil di setiap halaman terproteksi (setara checkLogin + _AdminGuard).
  App.ready = async fn => {
    if (!App.token()) return App.go('/login');
    const r = await App.api('/user');
    let u = r.ok && r.data ? (r.data.data || r.data) : null;
    if (!u) { try { u = JSON.parse(localStorage.getItem('user') || 'null'); } catch (e) { /* abaikan */ } }
    if (!u) { App.clearAuth(); return App.go('/login'); }
    if (r.ok) localStorage.setItem('user', JSON.stringify(u));
    const bid = u.bidang && u.bidang !== '-' ? u.bidang : '';
    const me = App.me = { ...u, bidang: bid, label: bid || u.role, initials: App.initials(u.username), isAdmin: u.role === 'Admin' };
    wireShell(me);
    if (cfg.admin && !me.isAdmin) { sessionStorage.setItem('flash', 'Akses ditolak. Hanya Admin yang bisa mengakses halaman ini.'); return App.go('/dashboard'); }
    const fl = sessionStorage.getItem('flash'); if (fl) { sessionStorage.removeItem('flash'); App.err(fl); }
    await fn(me);
  };
})();
