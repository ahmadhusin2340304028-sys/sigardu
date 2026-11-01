@extends('layouts.app')
@section('title', 'Input Realisasi')
@section('back', url('/kegiatan/' . $id))
@section('content')
  <div class="pad" id="root" data-id="{{ $id }}"></div>
@endsection

@push('scripts')
<script>
App.ready(async me => {
  const { $, esc, num } = App, ID = $('#root').dataset.id, root = $('#root');
  let K = null, R = null, sel = null, file = null, busy = false;
  const byBulan = b => (R && R.per_bulan || []).find(x => +x.bulan === b);
  const hasData = d => !!d && (d.fisik != null || d.anggaran != null || (d.keterangan || '').trim() !== '' || !!d.bukti);

  async function load(keepForm) {
    if (!keepForm) root.innerHTML = App.spinner();
    const [a, b] = await Promise.all([App.api('/kegiatan/' + ID), App.api(`/kegiatan/${ID}/realisasi`)]);
    if (!a.ok || !b.ok) { root.innerHTML = App.state('wifi_off', 'Gagal memuat data realisasi', '<button class="btn btn-primary mt16" id="retry">Coba Lagi</button>'); $('#retry').onclick = () => load(); return; }
    K = a.data.data; R = b.data.data;
    keepForm ? (renderGrid(), renderSummary(), renderForm()) : shell();
  }

  function shell() {
    const sat = esc(K.satuan);
    root.innerHTML = `
      <div class="banner banner-blue" style="display:block;padding:14px;border-radius:12px"><div style="font-size:13px;font-weight:600;color:var(--on-pl)">${esc(K.sub_kegiatan)}</div>
        <div class="mt4" style="font-size:11px;color:var(--on-pl2)">${esc(K.bidang)} · ${esc(K.tahun)}</div>
        <div style="font-size:11px;color:var(--on-pl2)">pagu : ${App.rpc(num(K.pagu_anggaran))} · target : ${esc(K.target)} ${sat}</div></div>
      <div class="card pad14 mt16" id="sum"></div>
      <div class="step mt16"><i>1</i>Pilih Bulan Realisasi</div><div class="mgrid mt10" id="grid"></div>
      <div id="form" class="mt20"></div>`;
    renderSummary(); renderGrid(); renderForm();
  }
  function renderSummary() {
    $('#sum').innerHTML = `<div class="flex gap6" style="font-size:12px;font-weight:600;color:var(--t1)"><span class="ms" style="color:var(--accent);font-size:16px">analytics</span>Sisa Realisasi</div>
      <div class="sumrow mt10"><div><b style="color:var(--primary-mid)">${App.rp(num(K.sisa_anggaran))}</b><small>Sisa Anggaran</small></div>
      <div><b style="color:${App.progressColor(num(K.sisa_target))}">${num(K.sisa_target).toFixed(2)} ${esc(K.satuan)}</b><small>Sisa Target</small></div></div>`;
  }
  function renderGrid() {
    $('#grid').innerHTML = App.MONTHS_SHORT.map((m, i) => { const has = hasData(byBulan(i + 1)), on = sel === i + 1;
      return `<button class="mcell${on ? ' sel' : has ? ' has' : ''}" data-b="${i + 1}">${m === 'Agu' ? 'Ags' : m}${has ? '<span class="ms">check_circle</span>' : ''}</button>`; }).join('');
  }
  $('#root').addEventListener('click', e => { const b = e.target.closest('[data-b]'); if (b) { sel = +b.dataset.b; file = null; renderGrid(); renderForm(true); } });

  function buktiCard(b) {
    const pdf = /\.pdf$/i.test(b.file_path || ''), name = esc(b.file_name || (b.file_path || '').split('/').pop());
    return `<div class="bukti-card"><div class="h"><span class="ms" style="font-size:14px">attach_file</span>Bukti Pendukung Tersimpan</div>
      <div class="b"><div class="fic" style="background:${pdf ? 'var(--danger-light)' : 'var(--primary-light)'};color:${pdf ? 'var(--danger)' : 'var(--accent)'}"><span class="ms">${pdf ? 'picture_as_pdf' : 'image'}</span></div>
        <div class="grow"><div class="ell" style="font-size:13px;font-weight:500;color:var(--t1)">${name}</div><div class="muted" style="font-size:11px">${pdf ? 'Dokumen PDF' : 'Gambar'}</div></div>
        <a class="btn btn-outline btn-sm" href="${esc(b.file_url)}" target="_blank" rel="noopener"><span class="ms" style="font-size:14px">open_in_new</span>Buka</a></div>
      <div class="u"><span class="ms" style="font-size:13px;color:var(--th)">link</span><span class="grow ell" style="text-decoration:underline">${esc(b.file_url)}</span>
        <button type="button" data-copy="${esc(b.file_url)}" aria-label="Salin URL"><span class="ms" style="font-size:13px;color:var(--th)">content_copy</span></button></div></div>`;
  }

  function renderForm(fill) {
    const box = $('#form'); if (!sel) { box.innerHTML = ''; return; }
    const d = byBulan(sel), has = hasData(d), can = !!K.can_manage, ro = can ? '' : ' readonly';
    const fisik = d && d.fisik != null ? (num(d.fisik) % 1 === 0 ? num(d.fisik).toFixed(0) : num(d.fisik).toFixed(2)) : '';
    const ang = d && d.anggaran != null ? num(d.anggaran).toFixed(0) : '';
    box.innerHTML = `<div class="step"><i>2</i>Isi Data Realisasi — ${App.MONTHS[sel - 1]}</div>
      ${has ? `<div class="banner banner-warn mt12" style="align-items:center;font-size:12px"><span class="ms">edit</span><span>Data bulan ${App.MONTHS[sel - 1]} sudah ada — form terisi otomatis. Ubah data dan Simpan untuk mengedit.</span></div>` : ''}
      ${can ? '' : '<div class="banner banner-gray mt8" style="align-items:center"><span class="ms o">lock</span><span>Kegiatan ini bukan bidang Anda. Data bisa dilihat, tetapi tidak bisa disimpan.</span></div>'}
      <form id="rf" class="mt12" novalidate>
        <div class="field"><label class="label" style="margin-bottom:2px">Realisasi Fisik (${esc(K.satuan)})</label><div class="hint" style="margin-bottom:6px">Persentase fisik yang sudah tercapai</div>
          <div class="iw"><input class="input ps" id="f-fisik" inputmode="decimal" placeholder="Contoh: 75" value="${fisik}"${ro}><span class="sfx">%</span></div><div class="errmsg" id="e-fisik" hidden></div></div>
        <div class="field"><label class="label" style="margin-bottom:2px">Realisasi Anggaran (Rp)</label><div class="hint" style="margin-bottom:6px">Nominal anggaran yang sudah terpakai bulan ini</div>
          <div class="iw"><span class="pfx">Rp</span><input class="input pp" id="f-ang" inputmode="numeric" placeholder="Contoh: 5000000" value="${ang}"${ro}></div><div class="errmsg" id="e-ang" hidden></div></div>
        <div class="field"><label class="label" style="margin-bottom:2px">Keterangan</label><div class="hint" style="margin-bottom:6px">Opsional — catatan kendala atau progres</div>
          <textarea class="input" id="f-ket" rows="3" maxlength="500" placeholder="Contoh: Pengadaan material sudah selesai..."${ro}>${esc(d && d.keterangan || '')}</textarea></div>
        <div class="field"><label class="label" style="margin-bottom:2px">File Bukti</label>
          <div class="hint" style="margin-bottom:6px">${d && d.bukti ? 'Pilih file baru jika ingin mengganti bukti lama' : 'Opsional, PDF/JPG/PNG maksimal 5 MB'}</div>
          <div class="pickcard"><div class="pickic ${file ? 'sel' : d && d.bukti ? 'ex' : ''}"><span class="ms">${file ? 'upload_file' : d && d.bukti ? 'verified' : 'note_add'}</span></div>
            <div class="grow"><div class="ell" style="font-size:13px;font-weight:600;color:var(--t1)">${file ? esc(file.name) : d && d.bukti ? 'Bukti lama tersedia' : 'Belum ada file bukti'}</div>
              <div class="muted" style="font-size:11px">${file ? (file.size / 1024 / 1024 >= 1 ? (file.size / 1024 / 1024).toFixed(1) + ' MB' : Math.max(1, Math.round(file.size / 1024)) + ' KB') + ' - akan diunggah saat disimpan' : d && d.bukti ? 'Kosongkan jika tidak ingin mengganti file.' : 'Lampirkan file pendukung realisasi.'}</div></div>
            ${file ? '<button type="button" class="icon-btn" id="f-clear" aria-label="Batal pilih file"><span class="ms">close</span></button>'
                   : `<button type="button" class="btn btn-outline btn-sm" id="f-pick"${can ? '' : ' disabled'}><span class="ms" style="font-size:14px">attach_file</span>Pilih</button>`}</div>
          <input type="file" id="f-file" accept=".pdf,.jpg,.jpeg,.png" hidden></div>
        ${d && d.bukti ? buktiCard(d.bukti) : ''}
        <button class="btn btn-primary btn-block btn-lg" id="f-save" type="submit"${can ? '' : ' disabled'}>${can ? (file ? 'Simpan & Unggah Bukti' : has ? 'Perbarui Realisasi' : 'Simpan Realisasi') : 'Hanya Lihat Data'}</button>
      </form>`;
    const pick = $('#f-pick'), inp = $('#f-file');
    if (pick) pick.onclick = () => inp.click();
    const clr = $('#f-clear'); if (clr) clr.onclick = () => { file = null; keep(); };
    inp.onchange = () => { const f = inp.files[0]; if (!f) return; if (f.size > 5 * 1024 * 1024) return App.err('Ukuran file maksimal 5 MB.'); file = f; keep(); };
    $('#f-ang').addEventListener('input', e => { e.target.value = e.target.value.replace(/\D/g, ''); });
    $('#f-fisik').addEventListener('input', e => { e.target.value = e.target.value.replace(/[^\d,.]/g, ''); });
    $('#rf').addEventListener('submit', submit);
    box.querySelectorAll('[data-copy]').forEach(b => b.onclick = async () => { try { await navigator.clipboard.writeText(b.dataset.copy); App.info('URL disalin ke clipboard'); } catch (e) { App.err('Gagal menyalin URL'); } });
  }
  // Render ulang form tapi pertahankan isian yang sedang diketik (saat pilih/hapus file).
  function keep() { const v = ['#f-fisik', '#f-ang', '#f-ket'].map(s => $(s).value); renderForm(); ['#f-fisik', '#f-ang', '#f-ket'].forEach((s, i) => { $(s).value = v[i]; }); }

  async function submit(e) {
    e.preventDefault(); if (busy || !K.can_manage) return;
    const fs = $('#f-fisik').value.trim(), as = $('#f-ang').value.trim(), fv = parseFloat(fs.replace(',', '.'));
    const ef = !fs ? 'Realisasi fisik wajib diisi' : isNaN(fv) ? 'Angka tidak valid' : (fv < 0 || fv > 100) ? 'Nilai 0 – 100' : '';
    const ea = as ? '' : 'Realisasi anggaran wajib diisi';
    [['fisik', ef], ['ang', ea]].forEach(([k, m]) => { const el = $('#e-' + k); el.textContent = m; el.hidden = !m; $('#f-' + k).classList.toggle('err', !!m); });
    if (ef || ea) return;
    busy = true; const btn = $('#f-save'); btn.disabled = true; btn.innerHTML = '<div class="spin sm w"></div>Menyimpan...';
    const ket = $('#f-ket').value.trim();
    const r = await App.api('/realisasi', { method: 'POST', json: { kegiatan_id: +ID, bulan: sel, realisasi_fisik: fv, realisasi_anggaran: parseFloat(as) || 0, ...(ket ? { keterangan: ket } : {}) } });
    let ok = r.ok, msg = r.ok ? (r.data && r.data.message) : App.errMsg(r.data, 'Server menolak data. Periksa input.');
    if (ok && file) {
      const fd = new FormData(); fd.append('kegiatan_id', ID); fd.append('bulan', sel); fd.append('file', file, file.name);
      const u = await App.api('/upload-bukti', { method: 'POST', form: fd });
      ok = u.ok && u.data && u.data.success; msg = ok ? (u.data.message || msg) : 'Gagal mengunggah bukti. Periksa format dan ukuran file.';
    }
    busy = false;
    if (ok) { file = null; App.ok(msg || 'Realisasi berhasil disimpan.'); await load(true); } else { App.err(msg); btn.disabled = false; btn.textContent = 'Simpan Realisasi'; }
  }
  load();
});
</script>
@endpush
