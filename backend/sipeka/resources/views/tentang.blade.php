@extends('layouts.app')
@section('title', 'Tentang Aplikasi')
@section('content')
@php
  $devs = [
    ['Ahmad Husin', 'Software Engginer', '#2563EB', 'ahmadhusin.2340304028@gmail.com', '0852-5687-5779', 'ahmadhusin.jpeg'],
    ['Rangga Saputra', 'Frontend Developer', '#16A34A', 'ranggasaputra270504@gmail.com', '081254834538', 'rangga.png'],
    ['Adi Saputra', 'UI/UX Designer', '#F97316', 'adisaaputraa19@gmail.com', '0853-4610-1011', 'putra.png'],
  ];
@endphp
<div class="pad">
  <div class="t-hero">
    <div class="av"><img src="{{ asset('images/logo_sipeka.png') }}" alt="SIGARDU"></div>
    <div style="font-size:26px;font-weight:700;letter-spacing:1.2px">SIGARDU</div>
    <div style="opacity:.75;font-size:15px">Versi 1.0.0</div>
  </div>

  <div class="t-h">Deskripsi</div>
  <div class="card pad" style="border-radius:16px;font-size:15px;line-height:1.6;text-align:justify">
    SIGARDU (Sistem Informasi Gerakan Agenda, Rekap Data dan Undangan) merupakan aplikasi yang dirancang untuk membantu proses monitoring, pencatatan, serta pelaporan kegiatan secara efektif dan terintegrasi.
  </div>

  <div class="t-h">Pengembang</div>
  @foreach ($devs as $d)
    <div class="card t-dev">
      <img src="{{ asset('images/' . $d[5]) }}" alt="{{ $d[0] }}" onerror="this.style.visibility='hidden'">
      <div class="min0">
        <b>{{ $d[0] }}</b>
        <div style="color:{{ $d[2] }};font-weight:500;margin-top:4px">{{ $d[1] }}</div>
        <div style="margin-top:8px;overflow-wrap:anywhere">{{ $d[3] }}</div>
        <div>{{ $d[4] }}</div>
      </div>
    </div>
  @endforeach

  <div class="t-h">Kontak</div>
  <div class="grid2" style="gap:12px">
    <a class="t-contact" href="mailto:it@domain.go.id"><span class="ms" style="color:#EF4444">email</span>Email</a>
    <a class="t-contact" href="https://www.facebook.com/DinsosPM" target="_blank" rel="noopener">
      <svg viewBox="0 0 24 24" fill="#1E40AF"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>Facebook</a>
    <a class="t-contact" href="https://www.instagram.com/dinsospm" target="_blank" rel="noopener"><span class="ms" style="color:#EC4899">photo_camera</span>Instagram</a>
    <a class="t-contact" href="https://dinsos.tarakankota.go.id/" target="_blank" rel="noopener"><span class="ms" style="color:#22C55E">language</span>Website</a>
  </div>

  <p class="center-t mt20" style="margin-top:40px;color:var(--tm);font-size:13px">© 2026 SIGARDU Team</p>
</div>
@endsection

@push('scripts')
<script>App.ready(async () => {});</script>
@endpush
