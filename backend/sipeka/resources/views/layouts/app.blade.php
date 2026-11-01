<!DOCTYPE html>
<html lang="id">
<head>
@include('partials.head', ['title' => trim($__env->yieldContent('title')), 'admin' => $__env->hasSection('admin')])
</head>
<body>
@php $back = trim($__env->yieldContent('back')); @endphp
<header class="appbar">
  @if ($back)
    <a class="icon-btn" href="{{ $back }}" aria-label="Kembali"><span class="ms">arrow_back</span></a>
  @else
    <button class="icon-btn" data-menu aria-label="Menu"><span class="ms">menu</span></button>
  @endif
  <h1>@yield('title')</h1>
  @yield('actions')
</header>
@unless ($back)
  @include('partials.drawer')
@endunless
<main class="page">@yield('content')</main>
@yield('fab')
<div id="toasts"></div>
<script src="{{ asset('js/sigardu.js') }}?v=1"></script>
@stack('scripts')
</body>
</html>
