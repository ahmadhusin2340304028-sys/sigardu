@extends('layouts.app')
@section('title', 'Kegiatan')
@section('actions')
  <button class="icon-btn" data-refresh title="Muat ulang"><span class="ms">refresh</span></button>
@endsection
@section('content')
  <div class="bar-surface">
    <div class="searchwrap">
      <span class="ms lead">search</span>
      <input class="input" id="q" placeholder="Cari kegiatan, bidang, pelaksana..." autocomplete="off">
      <button class="icon-btn trail" id="q-clear" hidden aria-label="Hapus"><span class="ms">clear</span></button>
    </div>
    <div class="fchips mt10" id="chips"></div>
  </div>
  <div class="pad"><div id="list" class="list"></div><div id="more" class="center-pad" hidden style="padding:16px"><div class="spin sm"></div></div><div id="sentinel" style="height:1px"></div></div>
@endsection
@section('fab')
  <button class="fab" id="fab-export"><span class="ms">download</span>Export</button>
@endsection

@push('scripts')
<script>
App.ready(async me => {
  const { $, esc, num } = App;
  const st = { items: [], page: 0, last: 1, busy: false, search: '', bidang: null, options: [], error: null };
  const list = $('#list');

  const card = k => {
    const tgt = num(k.target), f = num(k.total_realisasi_fisik), pg = num(k.pagu_anggaran), a = num(k.total_realisasi_anggaran), sisa = num(k.sisa_anggaran);
    const pf = tgt > 0 ? f / tgt * 100 : 0, pa = pg > 0 ? a / pg * 100 : 0;
    const acc = App.progressColor(num(k.persen_target));
    return `<a class="card kcard" href="${App.url('/kegiatan/' + k.id)}"><i class="kc-accent" style="background:${acc}"></i>
      <div class="kc-title"><span>${esc(k.sub_kegiatan)}</span><span class="ms">chevron_right</span></div>
      <div class="chips"><span class="tag ${App.bidangClass(k.bidang)}">${esc(k.bidang)}</span><span class="tag tag-gray">${esc(k.tahun)}</span></div>
      <div class="mt10">${App.mini({ label: 'Fisik', pct: pf, color: acc, right: Math.min(100, pf).toFixed(1) + '%' })}${App.mini({ label: 'Anggaran', pct: pa, color: 'var(--primary-mid)', right: Math.min(100, pa).toFixed(1) + '%' })}</div>
      <div class="kc-foot"><span>${sisa > 0 ? 'Sisa: ' + App.rpc(sisa) : 'Anggaran sudah terpakai'}</span><b>${App.rpc(pg)}</b></div></a>`;
  };

  function renderChips() {
    $('#chips').innerHTML = ['Semua', ...st.options].map(o =>
      `<button class="fchip${(o === 'Semua' ? st.bidang === null : st.bidang === o) ? ' on' : ''}" data-b="${esc(o)}">${esc(o)}</button>`).join('');
  }
  function renderList() {
    if (st.error) { list.innerHTML = App.state('wifi_off', st.error, '<button class="btn btn-primary mt16" id="retry"><span class="ms">refresh</span>Coba Lagi</button>'); $('#retry').onclick = () => fetchPage(true); return; }
    if (!st.items.length && !st.busy) {
      const f = st.search || st.bidang;
      list.innerHTML = App.state(f ? 'search_off' : 'folder_open', f ? 'Tidak ada kegiatan yang cocok' : 'Belum ada data kegiatan', f ? '<button class="btn btn-text mt10" id="clr">Hapus filter</button>' : '');
      const c = $('#clr'); if (c) c.onclick = clearAll; return;
    }
    list.innerHTML = st.items.map(card).join(''); App.animate(list);
  }

  async function fetchPage(reset) {
    if (st.busy) return; st.busy = true; st.error = null;
    if (reset) { st.page = 0; st.last = 1; list.innerHTML = App.spinner(); } else $('#more').hidden = false;
    const r = await App.api('/kegiatan', { params: { page: reset ? 1 : st.page + 1, per_page: 20, search: st.search.trim(), bidang: st.bidang } });
    st.busy = false; $('#more').hidden = true;
    if (r.ok && r.data && r.data.data) {
      const p = r.data.data, rows = p.data || [];
      if (reset) st.items = rows; else { const ids = new Set(st.items.map(i => i.id)); st.items.push(...rows.filter(i => !ids.has(i.id))); }
      st.page = p.current_page; st.last = p.last_page;
      const opts = r.data.filters && r.data.filters.bidang; if (Array.isArray(opts)) { st.options = opts; renderChips(); }
    } else if (reset) st.error = r.networkError ? 'Terjadi kesalahan koneksi' : 'Gagal memuat data kegiatan';
    renderList(); io.recheck();
  }
  const io = App.infinite($('#sentinel'), () => { if (st.page && st.page < st.last) fetchPage(false); });
  App.onRefresh = () => fetchPage(true);

  const reload = () => fetchPage(true);
  const clearAll = () => { $('#q').value = ''; st.search = ''; st.bidang = null; $('#q-clear').hidden = true; renderChips(); reload(); };
  const deb = App.debounce(() => reload(), 500);
  $('#q').addEventListener('input', e => { st.search = e.target.value; $('#q-clear').hidden = !st.search; deb(); });
  $('#q-clear').onclick = clearAll;
  $('#chips').addEventListener('click', e => {
    const b = e.target.closest('[data-b]'); if (!b) return;
    const v = b.dataset.b === 'Semua' ? null : b.dataset.b; if (v === st.bidang) return;
    st.bidang = v; renderChips(); reload();
  });
  renderChips(); reload();

  // ── Export laporan (bottom sheet) ───────────────────────────────────────
  $('#fab-export').onclick = async () => {
    const now = new Date().getFullYear(), years = [0, 1, 2, 3, 4].map(i => now - i);
    const mins = [['Semua', ''], ['≥ 30%', 30], ['≥ 50%', 50], ['≥ 90%', 90], ['100%', 100]];
    const s = { bidang: 'Semua', tahun: now, min: 0, busy: null };
    const o = App.modal(`<div class="sheet-body surf"><div class="sheet-head"><div class="grab"></div>
      <div class="row" style="padding-bottom:14px"><span class="ib"><span class="ms">filter_alt</span></span><h3 class="grow" style="font-size:16px;font-weight:600;color:var(--t1)">Filter Laporan Kegiatan</h3>
      <button class="icon-btn" id="x-close" aria-label="Tutup"><span class="ms">close</span></button></div></div>
      <div class="sheet-scroll" style="padding:16px 20px 20px">
        <label class="label">Seksi / Urusan</label><select class="input" id="x-bid"><option>Semua</option></select>
        <label class="label mt18">Tahun</label><select class="input" id="x-thn">${years.map(y => `<option>${y}</option>`).join('')}</select>
        <label class="label mt18">Realisasi Kinerja Minimal</label><select class="input" id="x-min">${mins.map(m => `<option value="${m[1]}">${m[0]}</option>`).join('')}</select>
        <div class="banner banner-blue mt20" style="display:block;padding:14px"><div class="flex gap6" style="font-weight:600;font-size:12px"><span class="ms">info</span>Kriteria Laporan</div>
          <div class="mt8" id="x-prev" style="font-size:12px;line-height:1.7"></div></div>
        <button class="btn btn-success btn-block btn-lg mt20" id="x-xls"><span class="ms">table_chart</span>Export Excel</button>
        <button class="btn btn-outline btn-block btn-lg mt12" id="x-pdf" style="border-color:var(--danger);color:var(--danger);font-size:15px"><span class="ms">picture_as_pdf</span>Export PDF</button>
        <p class="center-t hint mt8">File akan diunduh ke perangkat Anda</p></div></div>`, 'sheet');
    const q = x => $(x, o);
    const prev = () => { const m = mins.find(m => String(m[1]) === String(s.min || '')) || mins[0];
      q('#x-prev').innerHTML = `<div>Bidang : <b>${esc(s.bidang)}</b></div><div>Tahun : <b>${s.tahun}</b></div><div>Min. Kinerja : <b>${m[0]}</b></div>`; };
    const btns = () => { q('#x-xls').disabled = q('#x-pdf').disabled = !!s.busy;
      q('#x-xls').innerHTML = s.busy === 'excel' ? '<div class="spin sm w"></div>Mengekspor...' : '<span class="ms">table_chart</span>Export Excel';
      q('#x-pdf').innerHTML = s.busy === 'pdf' ? '<div class="spin sm"></div>Mengekspor...' : '<span class="ms">picture_as_pdf</span>Export PDF'; };
    q('#x-close').onclick = () => App.close(o);
    q('#x-bid').onchange = e => { s.bidang = e.target.value; prev(); };
    q('#x-thn').onchange = e => { s.tahun = +e.target.value; prev(); };
    q('#x-min').onchange = e => { s.min = e.target.value; prev(); };
    prev();
    App.api('/bidang').then(r => { if (r.ok && r.data && r.data.data) q('#x-bid').innerHTML = ['Semua', ...r.data.data.map(b => b.nama)].map(n => `<option>${esc(n)}</option>`).join(''); });
    const run = async kind => {
      if (s.busy) return; s.busy = kind; btns();
      const params = { tahun: s.tahun }; if (s.bidang !== 'Semua') params.bidang = s.bidang; if (s.min) params.min_fisik = s.min;
      const r = await App.api('/export/' + kind, { params, blob: true });
      s.busy = null; btns();
      if (r.ok) { App.saveBlob(r.blob, `laporan_kegiatan_${s.tahun}.${kind === 'excel' ? 'xlsx' : 'pdf'}`); App.close(o); App.ok('File laporan berhasil diunduh'); }
      else App.err(`Gagal export ${kind === 'excel' ? 'Excel' : 'PDF'}: ${r.networkError ? 'koneksi gagal' : 'Server error ' + r.status}`);
    };
    q('#x-xls').onclick = () => run('excel'); q('#x-pdf').onclick = () => run('pdf');
  };
});
</script>
@endpush
