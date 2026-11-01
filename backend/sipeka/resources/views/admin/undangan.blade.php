@extends('layouts.app')
@section('title', 'Kelola Undangan')
@section('admin', '1')
@section('actions')
  <button class="icon-btn" id="add" title="Tambah Undangan"><span class="ms">add</span></button>
@endsection
@section('content')
  <div class="pad" id="root"></div>
@endsection
@section('fab')
  <button class="fab" id="fab"><span class="ms">add</span>Tambah</button>
@endsection

@push('scripts')
<script src="{{ asset('js/sigardu-undangan.js') }}?v=1"></script>
<script>
App.ready(async me => {
  const { $, esc } = App, root = $('#root');
  // Jabatan struktural terikat ke role akun login (User::BIDANG_ROLE_MAP), bukan master "bidang".
  const JABATAN = ['Kepala Dinas', 'Sekretaris', 'Kepala Bidang Sosial', 'Kepala Bidang Pemberdayaan Masyarakat', 'Kepala Sub Bagian Perencanaan', 'Kepala Sub Bagian Kepegawaian'];
  let items = [], bidang = [];

  async function load() {
    if (!items.length) root.innerHTML = App.spinner();
    const r = await App.api('/undangan', { params: { per_page: 50 } });
    if (r.ok && r.data && r.data.data) items = r.data.data.data || [];
    else App.err('Gagal memuat undangan');
    render();
  }
  App.onRefresh = load;
  const loadBidang = async () => { const r = await App.api('/bidang'); if (r.ok && r.data && r.data.data) bidang = r.data.data.map(b => b.nama); };
  loadBidang();

  const kehColor = s => { const l = s.toLowerCase(); return l === 'tidak hadir' ? 'var(--danger)' : l === 'pending' ? 'var(--warning)' : 'var(--success)'; };
  function render() {
    if (!items.length) { root.innerHTML = App.state('mail', 'Belum ada data undangan', '<button class="btn btn-primary mt16" id="add2" style="padding:10px 16px;font-size:14px"><span class="ms">add</span>Tambah Undangan</button>'); $('#add2').onclick = () => dialog(); return; }
    root.innerHTML = `<div class="list" style="gap:8px">${items.map(u => {
      const d = App.parseDate(u.tanggal), pihak = String(u.bidang_terkait || '').split(',').map(s => s.trim()).filter(Boolean), keh = u.menghadiri || 'Pending';
      return `<div class="card" style="overflow:hidden"><div style="padding:11px 14px 10px;background:var(--surface-gray);border-bottom:.5px solid var(--border);font-size:13px;font-weight:600;color:var(--t1)">${esc(u.judul_kegiatan)}</div>
        <div style="padding:10px 14px 4px">${Undangan.meta('calendar_today', `${App.date(d)} · ${String(u.waktu || '').slice(0, 5) || '-'} WIB`)}${Undangan.meta('location_on', u.tempat || '-')}${Undangan.meta('business', u.pihak_mengundang || '-')}
          ${Undangan.pihak(pihak)}<hr class="hr" style="margin:12px 0 8px"><div class="flex gap6" style="font-size:12px"><span class="ms muted" style="font-size:13px">how_to_reg</span><span class="muted">Kehadiran:</span><b style="color:${kehColor(keh)}">${esc(keh)}</b></div></div>
        <div class="ac" style="display:flex;justify-content:flex-end;gap:4px;padding:4px 10px 10px"><button class="btn btn-text btn-sm" data-edit="${u.id}"><span class="ms" style="font-size:15px">edit</span>Edit</button>
          <button class="btn btn-text btn-sm" style="color:var(--danger)" data-del="${u.id}"><span class="ms o" style="font-size:15px">delete</span>Hapus</button></div></div>`; }).join('')}</div>`;
  }
  root.addEventListener('click', e => {
    const ed = e.target.closest('[data-edit]'), dl = e.target.closest('[data-del]');
    if (ed) dialog(items.find(u => u.id === +ed.dataset.edit)); if (dl) hapus(items.find(u => u.id === +dl.dataset.del));
  });
  $('#add').onclick = $('#fab').onclick = () => dialog();

  async function hapus(u) {
    const ok = await App.confirm({ icon: 'warning', title: 'Konfirmasi Hapus', ok: 'Hapus', body: `<div style="font-size:14px">Hapus undangan berikut?</div><div class="graybox mt8">${esc(u.judul_kegiatan)}</div>` });
    if (!ok) return;
    const r = await App.api('/undangan/' + u.id, { method: 'DELETE' });
    if (r.ok) { App.ok('Undangan berhasil dihapus'); load(); } else App.err(App.errMsg(r.data, 'Gagal menghapus'));
  }

  async function dialog(u) {
    if (!bidang.length) await loadBidang();
    const edit = !!u, options = [...JABATAN, ...bidang];
    const sel = new Set(u ? String(u.bidang_terkait || '').split(',').map(s => s.trim()).filter(Boolean) : []);
    const tgl = u ? String(u.tanggal).slice(0, 10) : '', wkt = u ? String(u.waktu || '').slice(0, 5) : '';
    const o = App.modal(`<div class="dialog lg"><div class="dlg-head"><span class="ib"><span class="ms">mail</span></span><h3>${edit ? 'Edit Undangan' : 'Tambah Surat Undangan'}</h3><button class="icon-btn" id="d-x" aria-label="Tutup"><span class="ms">close</span></button></div>
      <div class="dlg-scroll"><div class="field"><label class="label">Judul / Nama Kegiatan</label><textarea class="input" id="judul" rows="3" placeholder="Nama / judul kegiatan undangan">${esc(u ? u.judul_kegiatan : '')}</textarea><div class="errmsg" id="judul-e" hidden>Wajib diisi</div></div>
      <div class="row2" style="gap:10px"><div class="field grow"><label class="label">Tanggal</label><input class="input" type="date" id="tgl" value="${tgl}"></div><div class="field grow"><label class="label">Waktu</label><input class="input" type="time" id="wkt" value="${wkt}"></div></div>
      <div class="field"><label class="label">Tempat</label><input class="input" id="tempat" placeholder="Ruang / lokasi kegiatan" value="${esc(u ? u.tempat : '')}"><div class="errmsg" id="tempat-e" hidden>Wajib diisi</div></div>
      <div class="field"><label class="label">Pihak yang Mengundang</label><input class="input" id="meng" placeholder="Instansi / pihak pengundang" value="${esc(u ? u.pihak_mengundang : '')}"><div class="errmsg" id="meng-e" hidden>Wajib diisi</div></div>
      <label class="label" style="margin-bottom:4px">Pihak yang Diundang</label><div class="hint">Pilih satu atau lebih pihak yang akan menerima undangan</div>
      <div class="chips mt8" id="sel"></div>
      <div class="pihak-list" id="opts">${options.map((p, i) => `<label><input type="checkbox" data-i="${i}"><span>${esc(p)}</span></label>`).join('')}</div>
      <div class="banner banner-warn mt10"><span class="ms o">info</span><span>Konfirmasi kehadiran (hadir/tidak hadir), bukti, dan delegasi diisi oleh masing-masing pihak yang diundang.</span></div></div>
      <div class="dlg-foot"><button class="btn btn-outline" id="d-no">Batal</button><button class="btn btn-primary" id="d-ok" style="padding:10px 16px;font-size:14px"><span class="ms">save</span>${edit ? 'Simpan Perubahan' : 'Simpan'}</button></div></div>`);
    const q = s => $(s, o);
    const sync = () => {
      q('#sel').innerHTML = [...sel].map(p => `<span class="rchip">${esc(p)}<span class="ms" data-rm="${esc(p)}">close</span></span>`).join('');
      o.querySelectorAll('#opts input').forEach(c => { c.checked = sel.has(options[+c.dataset.i]); });
    };
    q('#opts').addEventListener('change', e => { const p = options[+e.target.dataset.i]; e.target.checked ? sel.add(p) : sel.delete(p); sync(); });
    q('#sel').addEventListener('click', e => { const r = e.target.closest('[data-rm]'); if (r) { sel.delete(r.dataset.rm); sync(); } });
    sync();
    q('#d-x').onclick = q('#d-no').onclick = () => App.close(o);
    q('#d-ok').onclick = async () => {
      let bad = false;
      [['judul'], ['tempat'], ['meng']].forEach(([id]) => { const m = !q('#' + id).value.trim(); q('#' + id + '-e').hidden = !m; q('#' + id).classList.toggle('err', m); if (m) bad = true; });
      if (bad) return;
      if (!q('#tgl').value) return App.err('Pilih tanggal kegiatan.');
      if (!q('#wkt').value) return App.err('Pilih waktu kegiatan.');
      if (!sel.size) return App.err('Pilih minimal satu pihak yang diundang.');
      const body = { judul_kegiatan: q('#judul').value.trim(), tanggal: q('#tgl').value, waktu: q('#wkt').value, tempat: q('#tempat').value.trim(), pihak_mengundang: q('#meng').value.trim(), bidang_terkait: [...sel] };
      const btn = q('#d-ok'); btn.disabled = true; btn.innerHTML = '<div class="spin sm w"></div>Menyimpan...';
      const r = await App.api(edit ? '/undangan/' + u.id : '/undangan', { method: edit ? 'PUT' : 'POST', json: body });
      if (r.ok) { App.close(o); App.ok(edit ? 'Undangan berhasil diperbarui.' : 'Undangan berhasil ditambahkan.'); load(); }
      else { App.err(App.errMsg(r.data, 'Gagal menyimpan undangan.')); btn.disabled = false; btn.innerHTML = `<span class="ms">save</span>${edit ? 'Simpan Perubahan' : 'Simpan'}`; }
    };
  }
  load();
});
</script>
@endpush
