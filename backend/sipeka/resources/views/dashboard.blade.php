@extends('layouts.app')
@section('title', 'Dashboard')
@section('actions')
  <button class="icon-btn" data-refresh title="Muat ulang"><span class="ms">refresh</span></button>
  <div class="avatar-sm" id="ab-avatar">U</div>
@endsection
@section('content')
  <div class="pad" id="root"></div>
@endsection

@push('scripts')
<script src="{{ asset('js/sigardu-undangan.js') }}?v=1"></script>
<script>
App.ready(async me => {
  const { $, esc, num } = App, U = Undangan;
  const root = $('#root'), year = new Date().getFullYear();
  $('#ab-avatar').textContent = me.initials;
  let nearest = null;

  const stat = o => `<div class="scard" style="--ac:${o.ac || 'var(--accent)'};${o.bg ? `--sbg:${o.bg};` : ''}">
    <span class="ic"><span class="ms">${o.icon}</span></span>
    <div class="v" style="font-size:${o.size}px">${esc(o.value)}</div><div class="l">${esc(o.label)}</div><div class="s">${esc(o.sub)}</div></div>`;

  async function load() {
    root.innerHTML = App.spinner();
    const r = await App.api('/dashboard/summary');
    const d = r.ok && r.data && r.data.success ? r.data.data : null;
    if (!d) {
      root.innerHTML = App.state('cloud_off', 'Gagal memuat data dashboard', '<button class="btn btn-primary mt16" id="retry">Coba Lagi</button>');
      $('#retry').onclick = load; return;
    }
    render(d); loadPending();
  }
  App.onRefresh = load;

  function render(d) {
    const pagu = num(d.total_pagu_anggaran), real = num(d.total_realisasi_anggaran), tgt = num(d.total_target), rf = num(d.total_realisasi_fisik), avg = num(d.rata_realisasi_fisik);
    const pct = pagu > 0 ? real / pagu * 100 : 0, tfis = tgt > 0 ? rf / tgt * 100 : 0;
    const first = (me.username || 'User').split(' ')[0], bp = d.bidang_progress || [];
    root.innerHTML = `
      <div class="banner banner-blue greet"><span class="ms">waving_hand</span><div>Haloo <b>${esc(first)}</b> — Selamat datang di SIGARDU</div></div>
      <div class="sec-title mt18">Ringkasan Kinerja ${year}</div>
      <div class="grid2 mt10">
        ${stat({ label: 'Total Kegiatan', value: String(d.total_kegiatan), size: 22, sub: 'Tahun ' + year, icon: 'task_alt' })}
        ${stat({ label: 'Realisasi Fisik', value: avg.toFixed(1), size: 22, sub: 'Rata-rata', icon: 'trending_up', ac: App.progressColor(avg), bg: `color-mix(in srgb,${App.progressColor(avg)} 8%,var(--surface))` })}
      </div>
      <div class="grid2 mt10">
        ${stat({ label: 'Total Anggaran', value: App.rp(pagu), size: 18, sub: 'kegiatan', icon: 'payments', ac: 'var(--success)', bg: 'var(--success-light)' })}
        ${stat({ label: 'Target Fisik', value: tfis.toFixed(1) + '%', size: 22, sub: 'Terealisasi', icon: 'analytics', ac: 'var(--warning)', bg: 'var(--warning-light)' })}
      </div>
      <div class="card-blue mt10">
        <div class="flex gap6" style="font-size:11px;font-weight:500;color:var(--on-pl2)"><span class="ms" style="color:var(--accent);font-size:16px">account_balance_wallet</span>Total Anggaran Terrealisasi</div>
        <div class="mt8" style="font-size:22px;font-weight:700;color:var(--on-pl)">${App.rpc(real)}</div>
        <div style="font-size:11px;color:var(--on-pl2)">dari ${App.rp(pagu)}</div>
        <div class="track tall mt10"><i data-w="${Math.min(100, pct)}" style="background:var(--btn)"></i></div>
        <div class="mt4" style="font-size:11px;font-weight:500;color:var(--accent)">${pct.toFixed(1)}% terrealisasi</div>
      </div>
      <div id="pending-slot" class="mt10"></div>
      <div class="flex between mt20"><div class="sec-title">Progres per Bidang</div><a class="link-sm" href="{{ url('/kegiatan') }}">Lihat semua</a></div>
      ${bp.length ? `<div class="card mt10" style="padding:14px 16px 4px">${bp.map(b => App.bar({ label: b.nama, value: num(b.total_realisasi_fisik), target: num(b.total_target) })).join('')}</div>` : ''}
      <div class="sec-title mt20">Aksi Cepat</div>
      <div class="grid2 mt10">
        <a class="card qa" href="{{ url('/kegiatan') }}"><span class="ms o">add_circle</span>Input Realisasi</a>
        <a class="card qa" href="{{ url('/undangan') }}"><span class="qb"><span class="ms o">mail</span><span class="qbadge" data-pending hidden>0</span></span>Undangan</a>
      </div>`;
    App.setPending(App.pending()); App.animate(root);
  }

  // ── Undangan pending terdekat ───────────────────────────────────────────
  async function loadPending() {
    const slot = $('#pending-slot'); if (!slot) return;
    slot.innerHTML = '<div class="card flex gap10 pad14" style="font-size:12px;color:var(--tm)"><div class="spin sm"></div>Memuat undangan pending...</div>';
    const r = await App.api('/undangan', { params: { page: 1, per_page: 1, status: 'pending', sort: 'nearest' } });
    if (r.ok && r.data) {
      const rows = (r.data.data && r.data.data.data) || [];
      nearest = rows.length ? U.parse(rows[0]) : null;
      App.setPending(parseInt(r.data.total_pending || 0, 10));
    } else nearest = null;
    slot.innerHTML = nearest ? pendingCard(nearest) : '';
  }

  function pendingCard(u) {
    return `<div class="card ucard"><div class="accent-top" style="background:var(--warning)"></div>
      <div class="flex gap6" style="padding:12px 14px 0"><span class="ms" style="color:var(--warning);font-size:16px">mark_email_unread</span>
        <div class="grow" style="font-size:12px;font-weight:600;color:var(--t1)">Undangan Pending Terdekat</div><a class="link-sm" href="{{ url('/undangan') }}">Lihat semua</a></div>
      <div class="uc-head" style="padding-top:10px"><div class="uc-title">${esc(u.judul)}</div>${U.badge('pending')}</div>
      <div class="uc-body">${U.meta('calendar_today', `${App.date(u.tanggal)} · ${u.waktu} WIB`, U.past(u))}${U.meta('location_on', u.tempat)}${U.meta('business', u.pihakMengundang)}${U.pihak(u.pihak)}<hr class="hr" style="margin:8px 0 0"></div>
      <div class="uc-act" style="padding-top:10px">${U.actions(u)}</div></div>`;
  }

  $('#root').addEventListener('click', async e => {
    const b = e.target.closest('[data-act]'); if (!b || !nearest) return;
    const res = b.dataset.act === 'hadir' ? await U.hadir(nearest) : await U.tidak(nearest);
    if (res) loadPending();
  });

  load();
});
</script>
@endpush
