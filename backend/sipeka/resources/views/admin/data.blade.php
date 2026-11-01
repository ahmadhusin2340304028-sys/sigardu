@extends('layouts.app')
@section('title', 'Kelola Data')
@section('admin', '1')
@section('content')
<style>
  .linbar{height:4px;border-radius:2px;overflow:hidden;background:color-mix(in srgb,var(--btn) 25%,transparent)}
  .linbar i{display:block;height:100%;width:40%;background:var(--btn);animation:lb 1.2s infinite ease-in-out}
  @keyframes lb{0%{margin-left:-40%}100%{margin-left:100%}}
  .dm-card{padding:16px}.dm-card .t{display:flex;gap:10px;align-items:center;font-size:16px;font-weight:700;color:var(--t1)}
  .dm-card .t .ms{font-size:24px;color:var(--accent)}.dm-card.danger .t .ms{color:var(--danger)}
  .dm-card .s{font-size:12px;color:var(--tm);margin:8px 0 14px}
</style>
<div class="pad">
  <div class="linbar" id="busy" hidden style="margin-bottom:14px"><i></i></div>
  <div class="list" id="sections" style="gap:14px">

    <div class="card dm-card">
      <div class="t"><span class="ms o">backup</span><span>Backup database</span></div>
      <div class="s">Unduh salinan lengkap database dalam format .sql.</div>
      <button class="btn btn-primary" id="btn-backup" style="padding:10px 16px"><span class="ms">download</span>Buat backup SQL</button>
    </div>

    <div class="card dm-card">
      <div class="t"><span class="ms">upload_file</span><span>Impor kegiatan</span></div>
      <div class="s">Gunakan file .xlsx dengan kolom sesuai template kegiatan.</div>
      <button class="btn btn-primary" id="btn-import" style="padding:10px 16px"><span class="ms o">file_upload</span>Pilih file Excel</button>
      <input type="file" id="file-import" accept=".xlsx" hidden>
    </div>

    <div class="card dm-card danger">
      <div class="t"><span class="ms">event_busy</span><span>Hapus kegiatan berdasarkan tahun</span></div>
      <div class="s">Data realisasi, keterangan, dan bukti ikut dihapus. Master bidang tetap dipertahankan.</div>
      <label class="label" for="tahun">Tahun kegiatan</label>
      <input class="input" id="tahun" inputmode="numeric" value="{{ date('Y') }}">
      <button class="btn btn-outline btn-block mt10" id="btn-kegiatan" style="padding:10px 16px;font-size:14px"><span class="ms o">delete</span>Tinjau dan hapus</button>
    </div>

    <div class="card dm-card danger">
      <div class="t"><span class="ms">auto_delete</span><span>Hapus undangan lama</span></div>
      <div class="s">Undangan dan file buktinya yang melewati masa simpan akan dihapus.</div>
      <label class="label" for="retensi">Masa simpan (tahun)</label>
      <input class="input" id="retensi" inputmode="numeric" value="3">
      <button class="btn btn-outline btn-block mt10" id="btn-undangan" style="padding:10px 16px;font-size:14px"><span class="ms o">delete_sweep</span>Tinjau dan hapus</button>
    </div>

  </div>
</div>
@endsection

@push('scripts')
<script>
App.ready(async me => {
  const { $, esc } = App;
  const setBusy = v => { $('#busy').hidden = !v; $('#sections').style.pointerEvents = v ? 'none' : ''; $('#sections').style.opacity = v ? '.85' : ''; };

  // Pesan error: baris impor "Baris N: ..." seperti di Flutter.
  const msg = d => {
    if (!d || typeof d !== 'object') return null;
    const e = d.errors;
    if (Array.isArray(e) && e.length) { const f = e[0]; if (f && Array.isArray(f.messages)) return `Baris ${f.row}: ${f.messages.join(', ')}`; }
    else if (e && typeof e === 'object') { const f = Object.values(e)[0]; return Array.isArray(f) ? f[0] : String(f); }
    return d.message || null;
  };
  // Panggil API; sukses → body JSON, gagal → toast error + null.
  async function call(path, opt, fallback) {
    setBusy(true);
    try {
      const r = await App.api(path, opt);
      if (r.ok && r.data && r.data.success) return r.data;
      App.err(msg(r.data) || fallback); return null;
    } finally { setBusy(false); }
  }
  const ask = (title, message, action, danger = false) => new Promise(res => {
    const o = App.modal(`<div class="dialog"><div class="dlg-title" style="font-size:20px">${esc(title)}</div>
      <div class="dlg-body" style="font-size:14px;line-height:1.5">${esc(message)}</div>
      <div class="dlg-actions"><button class="btn btn-text" data-r="0">Batal</button>
      <button class="btn ${danger ? 'btn-danger' : 'btn-primary'}" style="padding:10px 24px;font-size:14px" data-r="1">${esc(action)}</button></div></div>`);
    o.addEventListener('click', e => { const b = e.target.closest('[data-r]'); if (b) { App.close(o); res(b.dataset.r === '1'); } });
  });

  // ── Backup ──────────────────────────────────────────────────────────────
  $('#btn-backup').onclick = async () => {
    setBusy(true);
    const r = await App.api('/admin/data/backup', { blob: true });
    setBusy(false);
    if (!r.ok) return App.err(r.status === 422 ? 'Backup SQL saat ini hanya tersedia untuk database MySQL.' : 'Backup gagal dibuat.');
    App.saveBlob(r.blob, `sipeka-backup-${new Date().toISOString().replace(/:/g, '-')}.sql`);
    App.ok('Backup SQL berhasil disimpan.');
  };

  // ── Impor kegiatan (.xlsx) ──────────────────────────────────────────────
  const inp = $('#file-import');
  $('#btn-import').onclick = () => inp.click();
  inp.onchange = async () => {
    const f = inp.files[0]; inp.value = ''; if (!f) return;
    if (!/\.xlsx$/i.test(f.name)) return App.err('File harus berformat .xlsx.');
    if (f.size > 10 * 1024 * 1024) return App.err('Ukuran file maksimal 10 MB.');
    const ok = await ask('Impor kegiatan', `Semua baris pada ${f.name} akan diperiksa terlebih dahulu. Data hanya disimpan bila seluruh baris valid.`, 'Impor');
    if (!ok) return;
    const fd = new FormData(); fd.append('file', f, f.name);
    const res = await call('/admin/data/kegiatan-import', { method: 'POST', form: fd }, 'Impor gagal dilakukan.');
    if (res) App.ok(`${(res.data && res.data.imported) || 0} kegiatan berhasil diimpor.`);
  };

  // ── Hapus kegiatan per tahun ────────────────────────────────────────────
  $('#btn-kegiatan').onclick = async () => {
    const tahun = parseInt($('#tahun').value, 10);
    if (isNaN(tahun) || tahun < 2020 || tahun > 2099) return App.err('Masukkan tahun yang valid.');
    const pv = await call('/admin/data/kegiatan-cleanup-preview', { params: { tahun } }, 'Permintaan gagal dilakukan.');
    if (!pv) return;
    const d = pv.data;
    const go = await ask(`Hapus kegiatan tahun ${tahun}?`,
      `${d.kegiatan} kegiatan akan dihapus bersama ${d.realisasi_fisik} realisasi fisik, ${d.realisasi_anggaran} realisasi anggaran, ${d.keterangan_kegiatan} keterangan, dan ${d.bukti_kegiatan} bukti. Bidang dan akun pengguna tetap aman.`,
      'Hapus permanen', true);
    if (!go) return;
    const res = await call('/admin/data/kegiatan-by-year', { method: 'DELETE', params: { tahun } }, 'Permintaan gagal dilakukan.');
    if (res) App.ok(res.message || 'Berhasil diproses.');
  };

  // ── Hapus undangan lama ─────────────────────────────────────────────────
  $('#btn-undangan').onclick = async () => {
    const years = parseInt($('#retensi').value, 10);
    if (isNaN(years) || years < 1 || years > 50) return App.err('Masa simpan harus antara 1 sampai 50 tahun.');
    const pv = await call('/admin/data/undangan-cleanup-preview', { params: { years } }, 'Permintaan gagal dilakukan.');
    if (!pv) return;
    const d = pv.data;
    const go = await ask('Hapus undangan lama?',
      `${d.undangan} undangan sebelum ${d.cutoff} akan dihapus, termasuk ${d.bukti} file bukti. Masa simpan dapat diubah pada kolom di bawah.`,
      'Hapus permanen', true);
    if (!go) return;
    const res = await call('/admin/data/old-undangan', { method: 'DELETE', params: { years } }, 'Permintaan gagal dilakukan.');
    if (res) App.ok(res.message || 'Berhasil diproses.');
  };
});
</script>
@endpush
