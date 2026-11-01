@php
  $p = '/' . trim(request()->path(), '/');
  $act = fn ($path) => $p === $path ? 'active' : '';
@endphp
<div class="scrim" id="scrim"></div>
<aside class="drawer" id="drawer">
  <div class="dw-head">
    <div class="dw-logo">
      <div class="dw-logobox"><img src="{{ asset('images/logo_sipeka.png') }}" alt=""></div>
      <div><div class="dw-app">SIGARDU</div><div class="dw-sub">Kinerja &amp; Anggaran</div></div>
    </div>
    <div class="dw-user">
      <div class="dw-av" id="dw-av">U<span class="sh" id="dw-sh" hidden><span class="ms">shield</span></span></div>
      <div class="min0"><div class="dw-name ell" id="dw-name">Pengguna</div><div class="dw-role ell" id="dw-role">-</div></div>
    </div>
  </div>
  <nav class="dw-nav">
    <a class="dw-item {{ $act('/dashboard') }}" href="{{ url('/dashboard') }}"><span class="ms">dashboard</span><span>Dashboard</span></a>
    <a class="dw-item {{ $act('/kegiatan') }}" href="{{ url('/kegiatan') }}"><span class="ms">task_alt</span><span>Kegiatan</span></a>
    <a class="dw-item {{ $act('/undangan') }}" href="{{ url('/undangan') }}"><span class="ms o">mail</span><span>Undangan</span><span class="dw-badge" data-pending hidden>0</span></a>
    <div id="dw-admin" hidden>
      <div class="dw-adminlabel"><span class="admin-tag"><span class="ms">shield</span>ADMIN</span><i></i></div>
      <a class="dw-item warn {{ $act('/admin/bidang') }}" href="{{ url('/admin/bidang') }}"><span class="ms">apartment</span><span>Kelola Bidang</span></a>
      <a class="dw-item warn {{ $act('/admin/kegiatan') }}" href="{{ url('/admin/kegiatan') }}"><span class="ms">manage_search</span><span>Kelola Kegiatan</span></a>
      <a class="dw-item warn {{ $act('/admin/undangan') }}" href="{{ url('/admin/undangan') }}"><span class="ms">mark_email_unread</span><span>Kelola Undangan</span></a>
      <a class="dw-item warn {{ $act('/admin/data') }}" href="{{ url('/admin/data') }}"><span class="ms">storage</span><span>Kelola Data</span></a>
    </div>
  </nav>
  <div class="dw-bottom">
    <label class="theme-tile">
      <span class="ms" id="th-ic">light_mode</span>
      <span class="grow"><b id="th-t">Mode Terang</b><small id="th-s">Tema terang aktif</small></span>
      <span class="switch"><input type="checkbox" id="theme-sw"><i></i></span>
    </label>
    <hr>
    <a class="dw-item {{ $act('/tentang') }}" href="{{ url('/tentang') }}"><span class="ms o">info</span><span>Tentang Aplikasi</span></a>
    <button class="dw-item danger" id="logout-btn" type="button"><span class="ms">logout</span><span>Keluar</span></button>
  </div>
</aside>
