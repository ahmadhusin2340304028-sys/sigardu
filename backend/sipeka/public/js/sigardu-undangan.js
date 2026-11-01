/* SIGARDU — helper Undangan (dipakai Dashboard & halaman Undangan). */
(function () {
  'use strict';
  const { esc, $ } = App;
  const U = (window.Undangan = {});

  U.status = m => { const v = String(m || '').trim().toLowerCase(); return !v || v === 'pending' ? 'pending' : v === 'tidak hadir' ? 'tidak' : 'hadir'; };
  U.parse = r => {
    const d = App.parseDate(r.tanggal), w = String(r.waktu || '').slice(0, 5), [hh, mm] = w.split(':').map(Number);
    return {
      id: r.id, judul: r.judul_kegiatan || '', tanggal: d, dt: new Date(d.getFullYear(), d.getMonth(), d.getDate(), hh || 0, mm || 0),
      waktu: w, tempat: r.tempat || '', pihakMengundang: r.pihak_mengundang || '',
      pihak: String(r.bidang_terkait || '').split(',').map(s => s.trim()).filter(Boolean),
      status: U.status(r.menghadiri), menghadiri: r.menghadiri || '', delegasi: r.delegasi || '',
      buktiUrl: r.bukti_url || '', canRespond: r.can_respond !== false
    };
  };
  U.past = u => u.dt < new Date(Date.now() - 3600000);
  U.meta = (ic, t, hl) => `<div class="meta${hl ? ' hl' : ''}"><span class="ms">${ic}</span><span>${esc(t)}</span></div>`;
  U.pihak = l => l.length ? `<div class="mt8"><div class="meta"><span class="ms">groups</span><span>Pihak yang diundang:</span></div><div class="chips mt5">${l.map(p => `<span class="pchip">${esc(p)}</span>`).join('')}</div></div>` : '';
  U.badge = s => {
    const m = { hadir: ['b-hadir', 'check_circle', 'Hadir'], tidak: ['b-tidak', 'cancel', 'Tidak Hadir'], pending: ['b-pending', 'schedule', 'Pending'] }[s];
    return `<span class="badge ${m[0]}"><span class="ms">${m[1]}</span>${m[2]}</span>`;
  };
  U.infoHadir = u => `<div class="hadirbox">
    ${u.menghadiri ? `<div class="r"><span class="ms">person</span><span>Dihadiri oleh: <b>${esc(u.menghadiri)}</b></span></div>` : ''}
    ${u.delegasi ? `<div class="r"><span class="ms">swap_horiz</span><span>Delegasi: <b>${esc(u.delegasi)}</b></span></div>` : ''}
    ${u.buktiUrl ? `<a href="${esc(u.buktiUrl)}" target="_blank" rel="noopener"><span class="ms">attach_file</span>lihat bukti</a>` : ''}</div>`;
  U.actions = (u, busy) => {
    if (u.status === 'hadir') return '<div class="statusline" style="color:var(--success)"><span class="ms">check_circle</span>Kehadiran telah dikonfirmasi</div>';
    if (u.status === 'tidak') return '<div class="statusline" style="color:var(--danger)"><span class="ms">cancel</span>Tidak dapat hadir</div>';
    if (!u.canRespond) return '<div class="statusline muted"><span class="ms">visibility</span>Hanya lihat undangan bidang lain</div>';
    return `<div class="row2"><button class="btn btn-o-success grow" data-act="hadir" data-id="${u.id}"${busy ? ' disabled' : ''}><span class="ms">check</span>Hadir</button>
      <button class="btn btn-o-danger grow" data-act="tidak" data-id="${u.id}"${busy ? ' disabled' : ''}><span class="ms">close</span>Tidak Hadir</button></div>`;
  };
  U.card = u => `<div class="card ucard"><div class="accent-top" style="background:var(--${{ hadir: 'success', tidak: 'danger', pending: 'warning' }[u.status]})"></div>
    <div class="uc-head"><div class="uc-title">${esc(u.judul)}</div>${U.badge(u.status)}</div>
    <div class="uc-body">${U.meta('calendar_today', `${App.date(u.tanggal)} · ${u.waktu} WIB`, U.past(u) && u.status === 'pending')}${U.meta('location_on', u.tempat)}${U.meta('business', u.pihakMengundang)}
    ${U.pihak(u.pihak)}<hr class="hr" style="margin:8px 0">${u.status === 'hadir' ? U.infoHadir(u) : ''}</div>
    <div class="uc-act">${U.actions(u)}</div></div>`;

  // ── Dialog konfirmasi hadir → resolve(UndanganBaru | null)
  U.hadir = u => new Promise(resolve => {
    const who = App.me.bidang || App.me.username || '-';
    let file = null;
    const o = App.modal(`<div class="dialog"><div class="dlg-scroll">
      <div class="flex gap10"><span class="ib ok"><span class="ms">check_circle</span></span><h3 style="font-size:16px;font-weight:600;color:var(--t1)">Konfirmasi Kehadiran</h3></div>
      <div class="graybox mt14">${esc(u.judul)}</div>
      <div class="infobox mt14"><span class="ms">person</span><div><small>Dihadiri oleh</small><b>${esc(who)}</b></div></div>
      <label class="chk mt12"><input type="checkbox" id="h-del"><span>Hadir sebagai delegasi</span></label>
      <div id="h-delw" hidden class="mt10"><div class="hint-m">Keterangan delegasi</div><textarea class="input mt6" id="h-delt" rows="3" placeholder="Contoh: perwakilan/delegasi kepala dinas"></textarea></div>
      <div class="hint-m mt14">Bukti kehadiran (opsional)</div>
      <div class="filebox mt6" id="h-file"><span class="ms">attach_file</span><span class="grow ell" id="h-name">Pilih file bukti...</span><span class="ms" id="h-clr" hidden>close</span></div>
      <input type="file" id="h-in" accept=".pdf,.jpg,.jpeg,.png" hidden>
      <div class="row2 mt20"><button class="btn btn-outline grow" id="h-no">Batal</button><button class="btn btn-success grow" id="h-ok"><span class="ms">check</span>Konfirmasi</button></div></div></div>`);
    const q = s => $(s, o), box = q('#h-file'), inp = q('#h-in');
    q('#h-del').onchange = e => { q('#h-delw').hidden = !e.target.checked; };
    const sync = () => { box.classList.toggle('has', !!file); q('#h-name').textContent = file ? file.name : 'Pilih file bukti...'; q('#h-clr').hidden = !file; box.firstChild.textContent = file ? 'check_circle' : 'attach_file'; };
    box.onclick = e => { if (e.target.id === 'h-clr') { file = null; inp.value = ''; sync(); } else inp.click(); };
    inp.onchange = () => { const f = inp.files[0]; if (!f) return; if (f.size > 5 * 1024 * 1024) { App.err('File maksimal 5 MB'); inp.value = ''; return; } file = f; sync(); };
    q('#h-no').onclick = () => { App.close(o); resolve(null); };
    q('#h-ok').onclick = async () => {
      const btn = q('#h-ok'); btn.disabled = true; btn.innerHTML = '<div class="spin sm w"></div>';
      const fd = new FormData(), del = q('#h-del').checked ? q('#h-delt').value.trim() : '';
      if (del) fd.append('delegasi', del); if (file) fd.append('bukti', file, file.name);
      const r = await App.api(`/undangan/${u.id}/kehadiran`, { method: 'POST', form: fd });
      if (r.ok && r.data && r.data.success) { App.close(o); App.ok(r.data.message || 'Kehadiran berhasil dikonfirmasi.'); resolve(U.parse(r.data.data)); }
      else { App.err(App.errMsg(r.data, 'Gagal mengonfirmasi kehadiran.')); btn.disabled = false; btn.innerHTML = '<span class="ms">check</span>Konfirmasi'; }
    };
  });

  // ── Dialog tidak hadir → resolve(UndanganBaru | null)
  U.tidak = async u => {
    const ok = await App.confirm({
      icon: 'cancel', title: 'Tidak Dapat Hadir', ok: 'Konfirmasi', okCls: 'btn-danger',
      body: `<div style="font-size:13px;font-weight:500;color:var(--t1)">"${esc(u.judul)}"</div><div class="muted mt10" style="font-size:12px">Konfirmasi bahwa Anda tidak dapat hadir dalam undangan ini.</div>`
    });
    if (!ok) return null;
    const r = await App.api(`/undangan/${u.id}/tidak-hadir`, { method: 'POST' });
    if (r.ok && r.data && r.data.success) { App.info(r.data.message || 'Undangan ditandai tidak hadir.'); return U.parse(r.data.data); }
    App.err(App.errMsg(r.data, 'Gagal memperbarui status.')); return null;
  };
})();
