@extends('layouts.app')
@section('title', 'Kelola Kegiatan')
@section('admin', '1')
@section('actions')
  <button class="icon-btn" id="add" title="Tambah Kegiatan"><span class="ms">add</span></button>
@endsection
@section('content')
  <div class="bar-surface" style="border-bottom:.5px solid var(--border)">
    <div class="searchwrap"><span class="ms lead">search</span><input class="input" id="q" placeholder="Cari kegiatan, bidang, program..." autocomplete="off">
      <button class="icon-btn trail" id="q-clear" hidden aria-label="Hapus"><span class="ms">clear</span></button></div>
  </div>
  <div style="background:var(--surface-gray);padding:8px 16px;border-bottom:.5px solid var(--border);font-size:12px;color:var(--tm)" id="stats">0 kegiatan</div>
  <div class="pad"><div id="list" class="list" style="gap:8px"></div><div id="more" class="center-pad" hidden style="padding:16px"><div class="spin sm"></div></div><div id="sentinel" style="height:1px"></div></div>
@endsection
@section('fab')
  <button class="fab" id="fab"><span class="ms">add</span>Tambah</button>
@endsection

@push('scripts')
<script>
App.ready(async me => {
  const { $, esc, num } = App, list = $('#list');
  const st = { items: [], page: 0, last: 1, total: 0, busy: false, search: '' };

  const card = k => { const c = App.bidangColor(k.bidang);
    return `<div class="card admin-card"><div class="ah" style="background:color-mix(in srgb,${c} 6%,transparent);border-bottom:.5px solid color-mix(in srgb,${c} 15%,transparent)">
      <span class="dot" style="background:${c}"></span><span class="grow" style="font-size:11px;font-weight:600;color:${c}">${esc(k.bidang)}</span><span class="muted" style="font-size:11px">${esc(k.tahun)}</span></div>
      <div class="tb"><div style="font-size:13px;font-weight:600;color:var(--t1);line-height:1.35">${esc(k.sub_kegiatan)}</div><div class="muted ell" style="font-size:11px;margin-top:4px">${esc(k.program)}</div>
        <div class="flex gap6 mt8"><span class="ichip"><span class="ms">flag</span>Target: ${num(k.target).toFixed(0)} ${esc(k.satuan)}</span><span class="ichip"><span class="ms">account_balance_wallet</span>${App.rpc(num(k.pagu_anggaran))}</span></div></div>
      <div class="ac"><button class="btn btn-text btn-sm" data-edit="${k.id}"><span class="ms" style="font-size:15px">edit</span>Edit</button><button class="btn btn-text btn-sm" style="color:var(--danger)" data-del="${k.id}"><span class="ms o" style="font-size:15px">delete</span>Hapus</button></div></div>`; };

  function render() {
    $('#stats').innerHTML = `${st.total} kegiatan${st.search ? ` · <span style="color:var(--accent)">hasil pencarian "${esc(st.search)}"</span>` : ''}`;
    if (!st.items.length && !st.busy) {
      list.innerHTML = App.state(st.search ? 'search_off' : 'folder_open', st.search ? `Tidak ada hasil untuk "${st.search}"` : 'Belum ada data kegiatan', st.search ? '<button class="btn btn-text mt10" id="clr">Hapus pencarian</button>' : '');
      const c = $('#clr'); if (c) c.onclick = clear; return;
    }
    list.innerHTML = st.items.map(card).join('');
  }
  async function fetchPage(reset) {
    if (st.busy) return; st.busy = true;
    if (reset) { st.page = 0; st.last = 1; list.innerHTML = App.spinner(); } else $('#more').hidden = false;
    const r = await App.api('/kegiatan', { params: { page: reset ? 1 : st.page + 1, per_page: 20, search: st.search } });
    st.busy = false; $('#more').hidden = true;
    if (r.ok && r.data && r.data.data) {
      const p = r.data.data, rows = p.data || [];
      if (reset) st.items = rows; else { const ids = new Set(st.items.map(i => i.id)); st.items.push(...rows.filter(i => !ids.has(i.id))); }
      st.page = p.current_page; st.last = p.last_page; st.total = p.total;
    } else if (reset) { st.items = []; App.err('Gagal memuat data kegiatan'); }
    render(); io.recheck();
  }
  const io = App.infinite($('#sentinel'), () => { if (st.page && st.page < st.last) fetchPage(false); });
  const reload = () => fetchPage(true);
  const clear = () => { $('#q').value = ''; $('#q-clear').hidden = true; if (st.search) { st.search = ''; reload(); } };
  const deb = App.debounce(v => { if (v.trim() !== st.search) { st.search = v.trim(); reload(); } }, 400);
  $('#q').addEventListener('input', e => { $('#q-clear').hidden = !e.target.value; deb(e.target.value); });
  $('#q-clear').onclick = clear;
  $('#add').onclick = $('#fab').onclick = () => dialog();
  list.addEventListener('click', e => {
    const ed = e.target.closest('[data-edit]'), dl = e.target.closest('[data-del]');
    if (ed) dialog(st.items.find(k => k.id === +ed.dataset.edit)); if (dl) hapus(st.items.find(k => k.id === +dl.dataset.del));
  });

  async function hapus(k) {
    const ok = await App.confirm({ icon: 'warning', title: 'Konfirmasi Hapus', ok: 'Hapus',
      body: `<div style="font-size:14px">Hapus kegiatan berikut?</div><div class="graybox mt8">${esc(k.sub_kegiatan)}</div><div class="mt8" style="font-size:12px;color:var(--danger)">Data realisasi fisik, anggaran, keterangan, dan bukti akan ikut terhapus.</div>` });
    if (!ok) return;
    const r = await App.api('/kegiatan/' + k.id, { method: 'DELETE' });
    if (r.ok) { App.ok('Kegiatan berhasil dihapus.'); reload(); } else App.err(App.errMsg(r.data, 'Gagal menghapus'));
  }

  async function dialog(k) {
    const edit = !!k, f = (id, label, val, o = {}) => `<div class="field"><label class="label">${label}</label>${o.rows ? `<textarea class="input" id="${id}" rows="${o.rows}" placeholder="${o.ph || label}">${esc(val)}</textarea>`
      : `<div class="iw">${o.pfx ? '<span class="pfx">Rp</span>' : ''}<input class="input${o.pfx ? ' pp' : ''}" id="${id}" inputmode="${o.mode || 'text'}" placeholder="${o.ph || label}" value="${esc(val)}"></div>`}<div class="errmsg" id="${id}-e" hidden></div></div>`;
    const o = App.modal(`<div class="dialog lg"><div class="dlg-head"><span class="ib"><span class="ms">task_alt</span></span><h3>${edit ? 'Edit Kegiatan' : 'Tambah Kegiatan'}</h3><button class="icon-btn" id="d-x" aria-label="Tutup"><span class="ms">close</span></button></div>
      <div class="dlg-scroll">${f('sasaran', 'Sasaran Strategis', edit ? k.sasaran_strategis : '', { rows: 3 })}${f('indikator', 'Indikator Kinerja', edit ? k.indikator_kinerja : '', { rows: 2 })}
      ${f('program', 'Program', edit ? k.program : '', { rows: 2 })}${f('kegiatan', 'Kegiatan', edit ? k.kegiatan : '', { rows: 2 })}${f('sub', 'Sub Kegiatan', edit ? k.sub_kegiatan : '', { rows: 2 })}
      <div class="row2" style="gap:8px"><div class="grow">${f('satuan', 'Satuan', edit ? k.satuan : '', { ph: '%, Orang, Lembaga' })}</div><div class="grow">${f('target', 'Target', edit ? String(num(k.target)) : '', { mode: 'decimal' })}</div><div class="grow">${f('tahun', 'Tahun', edit ? k.tahun : new Date().getFullYear(), { mode: 'numeric' })}</div></div>
      ${f('pagu', 'Pagu Anggaran (Rp)', edit ? String(num(k.pagu_anggaran)) : '', { pfx: 1, mode: 'numeric', ph: 'Contoh: 150000000' })}
      <div class="field"><label class="label">Urusan / Bidang</label><select class="input" id="bidang"><option value="">Memuat bidang...</option></select><div class="errmsg" id="bidang-e" hidden>Pilih urusan</div>
        <div class="hint mt6" id="bidang-h" style="color:var(--warning)" hidden>Belum ada data bidang. Tambahkan lewat menu "Kelola Bidang" terlebih dahulu.</div></div></div>
      <div class="dlg-foot"><button class="btn btn-outline" id="d-no">Batal</button><button class="btn btn-primary" id="d-ok" style="padding:10px 16px;font-size:14px"><span class="ms">save</span>Simpan</button></div></div>`);
    const q = s => $(s, o);
    q('#d-x').onclick = q('#d-no').onclick = () => App.close(o);
    ['target', 'pagu', 'tahun'].forEach(id => q('#' + id).addEventListener('input', e => { e.target.value = e.target.value.replace(id === 'target' ? /[^\d.]/g : /\D/g, ''); }));
    App.api('/bidang').then(r => {
      const names = r.ok && r.data && r.data.data ? r.data.data.map(b => b.nama) : [], sel = q('#bidang');
      sel.innerHTML = `<option value="">${names.length ? '-- Pilih Urusan --' : 'Memuat bidang...'}</option>` + names.map(n => `<option${edit && k.bidang === n ? ' selected' : ''}>${esc(n)}</option>`).join('');
      q('#bidang-h').hidden = names.length > 0;
    });
    q('#d-ok').onclick = async () => {
      const labels = { sasaran: 'Sasaran Strategis', indikator: 'Indikator Kinerja', program: 'Program', kegiatan: 'Kegiatan', sub: 'Sub Kegiatan', satuan: 'Satuan', target: 'Target', pagu: 'Pagu Anggaran (Rp)', tahun: 'Tahun' };
      let bad = false;
      Object.entries(labels).forEach(([id, l]) => {
        const v = q('#' + id).value.trim(); let m = v ? '' : (id === 'tahun' ? 'Wajib' : `${l} wajib diisi`);
        if (id === 'tahun' && v && (+v < 2020 || +v > 2099)) m = 'Thn tidak valid';
        const e = q('#' + id + '-e'); e.textContent = m; e.hidden = !m; q('#' + id).classList.toggle('err', !!m); if (m) bad = true;
      });
      const bid = q('#bidang').value; q('#bidang-e').hidden = !!bid; if (!bid) bad = true;
      if (bad) return;
      const body = { sasaran_strategis: q('#sasaran').value.trim(), indikator_kinerja: q('#indikator').value.trim(), program: q('#program').value.trim(), kegiatan: q('#kegiatan').value.trim(),
        sub_kegiatan: q('#sub').value.trim(), satuan: q('#satuan').value.trim(), target: parseFloat(q('#target').value) || 0, tahun: parseInt(q('#tahun').value, 10), pagu_anggaran: parseFloat(q('#pagu').value) || 0, bidang: bid };
      const btn = q('#d-ok'); btn.disabled = true; btn.innerHTML = '<div class="spin sm w"></div>Menyimpan...';
      const r = await App.api(edit ? '/kegiatan/' + k.id : '/kegiatan', { method: edit ? 'PUT' : 'POST', json: body });
      if (r.ok) { App.close(o); App.ok(edit ? 'Kegiatan berhasil diperbarui.' : 'Kegiatan berhasil ditambahkan.'); reload(); }
      else { App.err(App.errMsg(r.data, 'Gagal menyimpan')); btn.disabled = false; btn.innerHTML = '<span class="ms">save</span>Simpan'; }
    };
  }
  App.onRefresh = reload; reload();
});
</script>
@endpush
