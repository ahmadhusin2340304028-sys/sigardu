<!DOCTYPE html>
<html lang="id">
<head>@include('partials.head', ['title' => 'SIGARDU'])</head>
<body>
<div class="splash">
  <div class="logo-c"><img src="{{ asset('images/logo_sipeka.png') }}" alt="SIGARDU"></div>
  <h1>SIGARDU</h1>
  <p>Kinerja &amp; Anggaran Kegiatan</p>
  <div class="spin w" style="margin-top:48px;opacity:.8"></div>
</div>
<script src="{{ asset('js/sigardu.js') }}?v=1"></script>
<script>
  setTimeout(async () => {
    if (!App.token()) return App.go('/login');
    const r = await App.api('/user');
    if (r.ok) App.go('/dashboard'); else { App.clearAuth(); App.go('/login'); }
  }, 1500);
</script>
</body>
</html>
