@extends('layouts.app')
@section('title', 'Detail Kegiatan')
@section('back', url('/kegiatan'))
@section('content')
  <div class="pad" id="root" data-id="{{ $id }}">{{-- diisi JS --}}</div>
@endsection

@push('scripts')
<script>
App.ready(async me => {
  const { $, esc, num } = App, ID = $('#root').dataset.id, root = $('#root');
  const f2 = v => num(v).toFixed(2);

  async function load() {
    root.innerHTML = App.spinner();
    const r = await App.api('/kegiatan/' + ID);
    if (!r.ok || !r.data || !r.data.data) { root.innerHTML = App.state('search_off', 'Data tidak tersedia.'); return; }
    render(r.data.data);
  }

  function render(k) {
    const target = num(k.target), pagu = num(k.pagu_anggaran), tf = num(k.total_realisasi_fisik), ta = num(k.total_realisasi_anggaran);
    const fis = k.realisasi_fisik || [], ang = k.realisasi_anggaran || [];
    const bulanan = fis.map(x => ({ bulan: +x.bulan, fisik: num(x.nilai), anggaran: num((ang.find(a => +a.bulan === +x.bulan) || {}).nilai) })).sort((a, b) => a.bulan - b.bulan);
    const sat = esc(k.satuan);
    const rows = [
      ['Sasaran Strategis', esc(k.sasaran_strategis)], ['Indikator', esc(k.indikator_kinerja)], ['Program', esc(k.program)], ['Kegiatan', esc(k.kegiatan)], ['Sub Kegiatan', esc(k.sub_kegiatan)],
      ['Target Fisik', `${f2(target)} ${sat}`], ['Realisasi Fisik', `${f2(tf)} ${sat}`], ['Sisa Target', `${f2(num(k.sisa_target))} ${sat}`],
      ['Pagu Anggaran', App.rp(pagu)], ['Realisasi Anggaran', App.rp(ta)], ['Sisa Anggaran', App.rp(num(k.sisa_anggaran))], ['Pelaksana', esc(k.bidang)], ['Tahun Anggaran', esc(k.tahun)]
    ];
    const maxV = bulanan.reduce((m, b) => Math.max(m, b.fisik), 1);
    root.innerHTML = `
      <div class="card pad"><div style="font-size:16px;font-weight:600;color:var(--t1);line-height:1.3">${esc(k.sub_kegiatan)}</div>
        <div class="chips mt10" style="gap:5px 7px"><span class="chip-h ${App.bidangClass(k.bidang)}">${esc(k.bidang)}</span><span class="chip-h tag-gray">${esc(k.tahun)}</span></div></div>
      <div class="card itable mt12"><div class="chead">Informasi Kegiatan</div>${rows.map(r => `<div class="r"><div class="k">${r[0]}</div><div class="v">${r[1]}</div></div>`).join('')}</div>
      <div class="card cardx mt12"><div class="ct">Capaian Realisasi</div>
        ${App.bar({ label: 'Realisasi Fisik', value: tf, target })}${App.bar({ label: 'Realisasi Anggaran', value: ta, target: pagu, color: 'var(--primary-mid)' })}</div>
      ${bulanan.length ? `<div class="card cardx mt12"><div class="ct">Realisasi Fisik per Bulan (${sat})</div><div class="bchart">${bulanan.map(b =>
        `<div class="bc"><span class="bv">${b.fisik.toFixed(0)}</span><div class="bb" data-h="${(55 * Math.min(1, Math.max(0.05, b.fisik / maxV))).toFixed(1)}"></div><span class="bm">${b.bulan >= 1 && b.bulan <= 12 ? App.MONTHS_SHORT[b.bulan - 1] : '?'}</span></div>`).join('')}</div></div>` : ''}
      <button class="btn btn-outline btn-block mt12" id="tw" style="height:50px;font-size:14px"><span class="ms">bar_chart</span>Lihat Detail Triwulan</button>
      <a class="btn btn-primary btn-block mt10" style="height:50px;font-size:15px" href="${App.url('/kegiatan/' + ID + '/realisasi')}"><span class="ms">add</span>Input Realisasi</a>`;
    App.animate(root);
    $('#tw').onclick = () => triwulan(k, bulanan, { target, pagu, tf, ta });
  }

  // ── Sheet detail triwulan ───────────────────────────────────────────────
  function triwulan(k, bulanan, t) {
    const sat = esc(k.satuan), ranges = ['Jan – Mar', 'Apr – Jun', 'Jul – Sep', 'Okt – Des'];
    const pctF = t.target > 0 ? Math.min(100, t.tf / t.target * 100) : 0, pctA = t.pagu > 0 ? Math.min(100, t.ta / t.pagu * 100) : 0;
    const cards = [0, 1, 2, 3].map(i => {
      const s = i * 3 + 1, ms = [s, s + 1, s + 2].map(b => ({ b, d: bulanan.find(x => x.bulan === b) }));
      const fq = ms.reduce((a, m) => a + (m.d ? m.d.fisik : 0), 0), aq = ms.reduce((a, m) => a + (m.d ? m.d.anggaran : 0), 0);
      const pf = t.target > 0 ? Math.min(100, fq / t.target * 100) : 0, pa = t.pagu > 0 ? Math.min(100, aq / t.pagu * 100) : 0;
      return `<div class="card tw"><div class="tw-h"><div class="flex gap10"><div class="tw-q">Q${i + 1}</div>
        <div class="grow"><div style="font-size:13px;font-weight:600;color:var(--t1)">Triwulan ${i + 1}</div><div class="muted" style="font-size:11px">${ranges[i]}</div></div>
        <span class="ms muted tw-ar">keyboard_arrow_down</span></div>
        <div class="mt10">${App.mini({ label: 'Fisik', pct: pf, color: 'var(--accent)', right: `${fq.toFixed(1)} | ${pf.toFixed(1)}%` })}${App.mini({ label: 'Anggaran', pct: pa, color: 'var(--primary-mid)', right: `${App.rpc(aq)} | ${pa.toFixed(1)}%` })}</div></div>
        <div class="tw-b" hidden>${ms.map(m => { const has = m.d && (m.d.fisik > 0 || m.d.anggaran > 0);
          return `<div class="tw-m${has ? ' has' : ''}"><div class="n">${App.MONTHS[m.b - 1]}</div>
            <div class="grow"><small>Fisik</small><b class="${m.d && m.d.fisik > 0 ? 'd' : ''}">${m.d ? m.d.fisik.toFixed(1) + ' ' + sat : '-'}</b></div>
            <div class="grow right"><small>Anggaran</small><b class="${m.d && m.d.anggaran > 0 ? 'd' : ''}">${m.d && m.d.anggaran > 0 ? App.rpc(m.d.anggaran) : '-'}</b></div></div>`; }).join('')}</div></div>`;
    }).join('');
    const o = App.modal(`<div class="sheet-body"><div class="sheet-head"><div class="grab" style="margin-bottom:10px"></div>
      <div class="row"><span class="ms" style="color:var(--accent);font-size:20px">bar_chart</span><h3 class="grow" style="font-size:15px;font-weight:600;color:var(--t1)">Detail Realisasi per Triwulan</h3>
      <button class="icon-btn" id="tw-x" aria-label="Tutup"><span class="ms">close</span></button></div>
      <div class="muted" style="font-size:11px;padding:0 20px 14px">${esc(k.bidang)}  ·  Target: ${t.target.toFixed(0)} ${sat}  ·  Pagu: ${App.rpc(t.pagu)}</div></div>
      <div class="sheet-scroll"><div class="card cardx"><div class="ct" style="margin-bottom:3px">Akumulasi Realisasi</div><div class="hint" style="margin-bottom:12px">Total seluruh realisasi yang telah dicatat.</div>
        ${App.mini({ label: 'Fisik', pct: pctF, color: 'var(--accent)', right: `${t.tf.toFixed(1)} | ${pctF.toFixed(1)}%` })}<div style="height:3px"></div>${App.mini({ label: 'Anggaran', pct: pctA, color: 'var(--primary-mid)', right: `${App.rpc(t.ta)} | ${pctA.toFixed(1)}%` })}</div>
        <div class="sec-title mt20 mb12" style="color:var(--t1);font-size:13px;margin-bottom:10px">Realisasi per Triwulan</div><div class="list" style="gap:12px">${cards}</div></div></div>`, 'sheet');
    $('#tw-x', o).onclick = () => App.close(o);
    o.querySelectorAll('.tw-h').forEach(h => h.addEventListener('click', () => {
      const b = h.nextElementSibling; b.hidden = !b.hidden; h.querySelector('.tw-ar').textContent = b.hidden ? 'keyboard_arrow_down' : 'keyboard_arrow_up';
    }));
    App.animate(o);
  }
  load();
});
</script>
@endpush
