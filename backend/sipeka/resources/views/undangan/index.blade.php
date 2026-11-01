@extends('layouts.app')
@section('title', 'Undangan')
@section('actions')
  <span class="ab-pill" id="ab-pending" hidden></span>
  <button class="icon-btn" data-refresh title="Muat ulang"><span class="ms">refresh</span></button>
@endsection
@section('content')
  <div class="bar-surface"><div class="fchips" id="chips"></div></div>
  <div class="pad"><div id="list" class="list"></div><div id="more" class="center-pad" hidden style="padding:16px"><div class="spin sm"></div></div><div id="sentinel" style="height:1px"></div></div>
@endsection

@push('scripts')
<script src="{{ asset('js/sigardu-undangan.js') }}?v=1"></script>
<script>
App.ready(async me => {
  const { $ } = App, U = Undangan, list = $('#list');
  const st = { items: [], page: 0, last: 1, busy: false, filter: null, error: null, updating: false };
  const FILTERS = [[null, 'Semua', ''], ['pending', 'Pending', 'var(--warning)'], ['hadir', 'Hadir', 'var(--success)'], ['tidak', 'Tidak Hadir', 'var(--danger)']];

  const chips = () => { $('#chips').innerHTML = FILTERS.map(f => `<button class="fchip${st.filter === f[0] ? ' on' : ''}" style="${f[2] ? `--ac:${f[2]}` : ''}" data-f="${f[0] || ''}">${f[1]}</button>`).join(''); };
  function render() {
    if (st.error) { list.innerHTML = App.state('wifi_off', st.error, '<button class="btn btn-primary mt16" id="retry"><span class="ms">refresh</span>Coba Lagi</button>'); $('#retry').onclick = () => fetchPage(true); return; }
    const rows = st.filter ? st.items.filter(u => u.status === st.filter) : st.items;
    if (!rows.length && !st.busy) {
      const msg = { hadir: 'Belum ada undangan yang dikonfirmasi hadir', tidak: 'Belum ada undangan yang tidak hadir', pending: 'Tidak ada undangan yang pending' }[st.filter] || 'Belum ada undangan';
      list.innerHTML = App.state('mail', msg); return;
    }
    list.innerHTML = rows.map(u => U.card(u).replace(/(data-act="(?:hadir|tidak)")/g, st.updating ? '$1 disabled' : '$1')).join('');
  }

  async function fetchPage(reset) {
    if (st.busy) return; st.busy = true; st.error = null;
    if (reset) { st.page = 0; st.last = 1; list.innerHTML = App.spinner(); } else $('#more').hidden = false;
    const r = await App.api('/undangan', { params: { page: reset ? 1 : st.page + 1, per_page: 20 } });
    st.busy = false; $('#more').hidden = true;
    if (r.ok && r.data && r.data.success) {
      const p = r.data.data, rows = (p.data || []).map(U.parse);
      if (reset) { st.items = rows; App.setPending(parseInt(r.data.total_pending || 0, 10)); }
      else { const ids = new Set(st.items.map(i => i.id)); st.items.push(...rows.filter(i => !ids.has(i.id))); }
      st.page = p.current_page; st.last = p.last_page;
    } else if (reset) st.error = r.networkError ? 'Terjadi kesalahan koneksi' : 'Gagal memuat data undangan';
    render(); io.recheck();
  }
  const io = App.infinite($('#sentinel'), () => { if (st.page && st.page < st.last) fetchPage(false); });
  App.onRefresh = () => fetchPage(true);

  $('#chips').addEventListener('click', e => { const b = e.target.closest('[data-f]'); if (!b) return; st.filter = b.dataset.f || null; chips(); render(); io.recheck(); });
  list.addEventListener('click', async e => {
    const b = e.target.closest('[data-act]'); if (!b || st.updating) return;
    const u = st.items.find(i => i.id === +b.dataset.id); if (!u) return;
    const res = b.dataset.act === 'hadir' ? await U.hadir(u) : await U.tidak(u);
    if (res) { const i = st.items.findIndex(x => x.id === u.id); st.items[i] = res; App.setPending(Math.max(0, App.pending() - 1)); render(); }
  });
  chips(); fetchPage(true);
});
</script>
@endpush
