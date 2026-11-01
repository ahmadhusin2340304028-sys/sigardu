<!DOCTYPE html>
<html lang="id">
<head>@include('partials.head', ['title' => 'Masuk'])</head>
<body>
<div class="auth-wrap">
  <div class="logo-c"><img src="{{ asset('images/logo_sipeka.png') }}" alt="SIGARDU"></div>
  <div class="auth-app">SIGARDU</div>
  <div class="auth-sub">Sistem Informasi Pelaporan&#10;Kinerja dan Anggaran Kegiatan</div>

  <form class="auth-card" id="f" novalidate>
    <h2>Masuk ke akun Anda</h2>
    <p class="muted mt4" style="font-size:12px">Gunakan NIP/email dan kata sandi Anda</p>

    <div class="field mt20" style="margin-bottom:16px">
      <label class="label" for="u">Username / NIP / Email</label>
      <div class="iw"><span class="ms o lead">person</span>
        <input class="input pl" id="u" autocomplete="username" placeholder="Masukkan username atau email"></div>
      <div class="errmsg" id="u-e" hidden></div>
    </div>
    <div class="field" style="margin-bottom:26px">
      <label class="label" for="p">Kata Sandi</label>
      <div class="iw"><span class="ms o lead">lock</span>
        <input class="input pl" style="padding-right:44px" id="p" type="password" autocomplete="current-password" placeholder="••••••••">
        <button class="icon-btn trail" type="button" id="eye" aria-label="Tampilkan kata sandi"><span class="ms o">visibility_off</span></button></div>
      <div class="errmsg" id="p-e" hidden></div>
    </div>
    <button class="btn btn-primary btn-block" style="height:50px;font-size:15px" id="go" type="submit">Masuk</button>
  </form>

  <p class="muted mt20" style="font-size:12px">Lupa kata sandi? Hubungi Administrator IT.</p>
  <p class="mt20" style="font-size:12px;color:var(--tm);opacity:.7">SIGARDU v1.0.0</p>
  <a href="#" id="about" class="mt4" style="display:inline-block;font-size:12px;color:#3B82F6;text-decoration:underline">Tentang Aplikasi</a>
</div>
<script src="{{ asset('js/sigardu.js') }}?v=1"></script>
<script>
  const { $ } = App;
  (async () => { if (App.token()) { const r = await App.api('/user'); if (r.ok) App.go('/dashboard'); } })();

  $('#eye').onclick = () => {
    const p = $('#p'), show = p.type === 'password';
    p.type = show ? 'text' : 'password';
    $('#eye .ms').textContent = show ? 'visibility' : 'visibility_off';
  };
  $('#about').onclick = e => {
    e.preventDefault();
    const o = App.modal(`<div class="dialog"><div class="dlg-title">Tentang SIGARDU</div>
      <div class="dlg-body">SIGARDU adalah Sistem Informasi Gerakan Agenda, Rekap Data dan Undangan.<br><br>Dikembangkan untuk mendukung efisiensi pelaporan.</div>
      <div class="dlg-actions"><button class="btn btn-text" id="x">Tutup</button></div></div>`);
    $('#x', o).onclick = () => App.close(o);
  };
  const setErr = (id, msg) => { const e = $('#' + id + '-e'); e.textContent = msg || ''; e.hidden = !msg; $('#' + id).classList.toggle('err', !!msg); };

  $('#f').addEventListener('submit', async e => {
    e.preventDefault();
    const u = $('#u').value.trim(), p = $('#p').value;
    setErr('u', u ? '' : 'Username tidak boleh kosong');
    setErr('p', !p ? 'Kata sandi tidak boleh kosong' : p.length < 6 ? 'Minimal 6 karakter' : '');
    if (!u || p.length < 6) return;
    const b = $('#go'); b.disabled = true; b.innerHTML = '<div class="spin sm w"></div>';
    const r = await App.api('/login', { method: 'POST', json: { username: u, password: p } });
    if (r.ok && r.data && r.data.token) { localStorage.setItem('token', r.data.token); App.go('/dashboard'); return; }
    App.err(r.networkError ? 'Terjadi kesalahan koneksi' : 'Username atau password salah');
    b.disabled = false; b.textContent = 'Masuk';
  });
</script>
</body>
</html>
