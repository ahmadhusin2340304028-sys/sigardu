<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{ $title ?? 'SIGARDU' }} — SIGARDU</title>
<link rel="icon" href="{{ asset('images/logo_sipeka.png') }}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;600;700;800&display=swap">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@24,400,0..1,0&display=block">
<link rel="stylesheet" href="{{ asset('css/sigardu.css') }}?v=1">
<script>
  try { if (localStorage.getItem('theme_mode') === 'dark') document.documentElement.dataset.theme = 'dark'; } catch (e) {}
  window.SIGARDU = { base: @json(rtrim(url('/'), '/')), api: @json(rtrim(url('/api'), '/')), admin: @json((bool) ($admin ?? false)) };
</script>
