@extends('layouts.app')
@section('title', 'Kelola Bidang')
@section('admin', '1')
@section('actions')
  <button class="icon-btn" id="add" title="Tambah Bidang"><span class="ms">add</span></button>
@endsection
@section('content')
  <div class="pad" id="root"></div>
@endsection
@section('fab')
  <button class="fab" id="fab"><span class="ms">add</span>Tambah</button>
@endsection

@push('scripts')
<script>
App.ready(async me => {
  const { $, esc } = App, root = $('#root');
  let items = [];

  async function load() {
    if (!items.length) root.innerHTML = App.spinner();
    const r = await App.api('/bidang');
    if (r.ok && r.data && r.data.success) items = r.data.data;
    render();
  }
  App.onRefresh = load;

  function render() {
    if (!items.length) { root.innerHTML = App.state('apartment', 'Belum ada data bidang', '<button class="btn btn-primary mt16" id="add2" style="padding:10px 16px;font-size:14px"><span class="ms">add</span>Tambah Bidang</button>'); $('#add2').onclick = () => dialog(); return; }
    root.innerHTML = `<div class="banner banner-blue mb12"><span class="ms o">info</span><span>Daftar bidang ini dipakai sebagai pilihan dropdown di fitur Kelola Kegiatan, Kelola Undangan, filter Kegiatan, dan Export Laporan. Setiap bidang bisa punya satu akun login staff utama.</span></div>
      <div class="list" style="gap:8px">${items.map(b => { const acc = b.user && b.user.username;
        return `<div class="card flex gap12" style="padding:10px 6px 10px 14px"><div class="b-icon"><span class="ms">apartment</span></div>
          <div class="grow"><div style="font-size:13px;font-weight:600;color:var(--t1)">${esc(b.nama)}</div>
            ${b.keterangan ? `<div class="muted" style="font-size:11px;margin-top:2px">${esc(b.keterangan)}</div>` : ''}
            <div class="flex gap6 mt4" style="font-size:11px;color:${acc ? 'var(--success)' : 'var(--th)'};font-weight:${acc ? 500 : 400}"><span class="ms" style="font-size:12px">${acc ? 'verified_user' : 'person_off'}</span><span class="ell">${acc ? 'Akun: ' + esc(b.user.username) : 'Belum ada akun staff'}</span></div></div>
          <button class="icon-btn" data-edit="${b.id}" title="Edit" style="width:36px;height:36px;color:var(--accent)"><span class="ms">edit</span></button>
          <button class="icon-btn" data-del="${b.id}" title="Hapus" style="width:36px;height:36px;color:var(--danger)"><span class="ms o">delete</span></button></div>`; }).join('')}</div>`;
  }
  root.addEventListener('click', e => {
    const ed = e.target.closest('[data-edit]'), dl = e.target.closest('[data-del]');
    if (ed) dialog(items.find(b => b.id === +ed.dataset.edit)); if (dl) hapus(items.find(b => b.id === +dl.dataset.del));
  });
  $('#add').onclick = $('#fab').onclick = () => dialog();

  // ── Tambah / edit ───────────────────────────────────────────────────────
  function dialog(b) {
    const edit = !!b, hasAcc = !!(b && b.user && b.user.username);
    const o = App.modal(`<div class="dialog lg"><div class="dlg-head"><span class="ib"><span class="ms">apartment</span></span><h3>${edit ? 'Edit Bidang' : 'Tambah Bidang'}</h3><button class="icon-btn" id="d-x" aria-label="Tutup"><span class="ms">close</span></button></div>
      <div class="dlg-scroll"><div class="field"><label class="label">Nama Bidang</label><input class="input" id="d-nama" placeholder="Contoh: Rehabilitasi Sosial" value="${esc(b ? b.nama : '')}"><div class="errmsg" id="d-nama-e" hidden>Nama bidang wajib diisi</div></div>
      <div class="field"><label class="label">Keterangan (opsional)</label><textarea class="input" id="d-ket" rows="2" placeholder="Deskripsi singkat bidang ini">${esc(b ? b.keterangan || '' : '')}</textarea></div>
      <hr style="margin:20px 0 16px">
      <div class="flex gap6" style="font-size:13px;font-weight:600;color:var(--t2)"><span class="ms" style="font-size:15px">badge</span>Akun Staff Bidang</div>
      <div class="hint mt4" style="line-height:1.4">${hasAcc ? 'Bidang ini sudah punya akun staff. Ubah username/kata sandi di bawah kalau perlu.' : 'Opsional — isi untuk langsung membuat akun login staff utama bidang ini.'}</div>
      <div class="field mt10"><label class="label">Username</label><input class="input" id="d-user" placeholder="Contoh: staff_perencanaan" autocomplete="off" value="${esc(hasAcc ? b.user.username : '')}"></div>
      <div class="field"><label class="label">Kata Sandi</label><div class="iw"><input class="input" id="d-pass" type="password" autocomplete="new-password" style="padding-right:44px" placeholder="${hasAcc ? 'Kosongkan jika tidak ingin mengubah' : 'Minimal 6 karakter'}"><button type="button" class="icon-btn trail" id="d-eye"><span class="ms o" style="font-size:18px">visibility_off</span></button></div></div>
      <div class="banner banner-warn mt16"><span class="ms o">info</span><span>Mengubah nama bidang otomatis memperbarui kegiatan &amp; undangan yang memakai bidang ini. Beberapa bidang bawaan tidak dapat diganti namanya karena masih terhubung ke akun jabatan struktural lama.</span></div></div>
      <div class="dlg-foot"><button class="btn btn-outline" id="d-no">Batal</button><button class="btn btn-primary" id="d-ok" style="padding:10px 16px;font-size:14px"><span class="ms">save</span>Simpan</button></div></div>`);
    const q = s => $(s, o);
    q('#d-x').onclick = q('#d-no').onclick = () => App.close(o);
    q('#d-eye').onclick = () => { const p = q('#d-pass'), s = p.type === 'password'; p.type = s ? 'text' : 'password'; q('#d-eye .ms').textContent = s ? 'visibility' : 'visibility_off'; };
    q('#d-ok').onclick = async () => {
      const nama = q('#d-nama').value.trim(), ket = q('#d-ket').value.trim(), username = q('#d-user').value.trim(), password = q('#d-pass').value;
      q('#d-nama-e').hidden = !!nama; q('#d-nama').classList.toggle('err', !nama); if (!nama) return;
      if (username || password) {
        if (!username) return App.err('Username wajib diisi jika ingin mengatur akun staff.');
        if (!hasAcc && !password) return App.err('Kata sandi wajib diisi untuk akun staff baru.');
        if (password && password.length < 6) return App.err('Kata sandi minimal 6 karakter.');
      }
      const body = edit ? { nama, keterangan: ket } : { nama, ...(ket ? { keterangan: ket } : {}) };
      if (username) body.username = username; if (password) body.password = password;
      const btn = q('#d-ok'); btn.disabled = true; btn.innerHTML = '<div class="spin sm w"></div>Menyimpan...';
      const r = await App.api(edit ? '/bidang/' + b.id : '/bidang', { method: edit ? 'PUT' : 'POST', json: body });
      if (r.ok) { App.close(o); App.ok((r.data && r.data.message) || 'Berhasil disimpan'); load(); }
      else { App.err(App.errMsg(r.data, 'Gagal menyimpan')); btn.disabled = false; btn.innerHTML = '<span class="ms">save</span>Simpan'; }
    };
  }

  // ── Hapus: 2 tahap konfirmasi ───────────────────────────────────────────
  async function hapus(b) {
    const li = t => `<div style="display:flex;gap:6px;margin-top:2px"><span>•</span><span>${t}</span></div>`;
    const lanjut = await App.confirm({ icon: 'warning', title: 'Hapus Bidang?', ok: 'Lanjutkan',
      body: `<div class="graybox" style="font-weight:600">${esc(b.nama)}</div>
        <div class="banner-danger mt12" style="padding:10px;font-size:12px;line-height:1.4;font-weight:600">Tindakan ini TIDAK BISA DIBATALKAN. Menghapus bidang ini akan ikut menghapus secara permanen:<div class="mt8" style="font-weight:400">
        ${li('Seluruh data Kegiatan pada bidang ini — target, realisasi, bukti pendukung')}${li('Seluruh data Undangan yang menyertakan bidang ini')}${li('Akun login staff utama bidang ini (jika ada)')}</div></div>` });
    if (!lanjut) return;
    const o = App.modal(`<div class="dialog"><div class="dlg-title"><span class="ms" style="color:var(--danger);font-size:22px">delete_forever</span>Konfirmasi Akhir</div>
      <div class="dlg-body" style="font-size:13px;line-height:1.5">Ketik <b style="color:var(--t1)">${esc(b.nama)}</b> untuk memastikan Anda benar-benar ingin menghapusnya.
        <input class="input mt12" id="c-in" placeholder="${esc(b.nama)}" autocomplete="off"></div>
      <div class="dlg-actions"><button class="btn btn-text" id="c-no">Batal</button><button class="btn btn-danger" id="c-ok" disabled>Hapus Permanen</button></div></div>`);
    $('#c-in', o).focus();
    $('#c-in', o).oninput = e => { $('#c-ok', o).disabled = e.target.value.trim() !== b.nama; };
    $('#c-no', o).onclick = () => App.close(o);
    $('#c-ok', o).onclick = async () => {
      $('#c-ok', o).disabled = true;
      const r = await App.api('/bidang/' + b.id, { method: 'DELETE' }); App.close(o);
      if (r.ok) { App.ok((r.data && r.data.message) || 'Bidang berhasil dihapus'); load(); } else App.err(App.errMsg(r.data, 'Gagal menghapus bidang'));
    };
  }
  load();
});
</script>
@endpush
