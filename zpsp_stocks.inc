<!DOCTYPE html>
<html lang="{{ lang or 'bg' }}" data-theme="{{ session.get('theme', 'dark') if session else 'dark' }}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
{% if page == 'detail' and server is defined %}
<title>{{ server.name }} — quboardix.eu</title>
<meta name="description" content="{{ server.description[:160] }}">
<meta property="og:title" content="{{ server.name }} — quboardix.eu">
<meta property="og:description" content="{{ server.description[:160] }}">
{% elif page == 'blog_post' and post is defined %}
<title>{{ post.title }} — quboardix.eu Blog</title>
<meta name="description" content="{{ post.summary or post.body[:160] }}">
{% else %}
<title>quboardix.eu — Discord Server Directory</title>
<meta name="description" content="Намери перфектния Discord сървър. Хиляди активни общности.">
{% endif %}
<style>
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

/* ── THEME VARIABLES ── */
[data-theme="dark"] {
  --bg: #06070e; --s1: #090a18; --s2: #0c0e1e; --s3: #101326; --card: #08091a;
  --b0: rgba(255,255,255,0.025); --b1: rgba(255,255,255,0.06);
  --b2: rgba(255,255,255,0.10); --b3: rgba(255,255,255,0.16);
  --a: #4a7bff; --a2: #7b6dff; --ag: rgba(74,123,255,0.1); --ag2: rgba(74,123,255,0.18);
  --amber: #e8933a; --amber2: rgba(232,147,58,0.12); --amber3: rgba(232,147,58,0.22);
  --green: #22c578; --gt: rgba(34,197,120,0.1);
  --red: #e05050; --rt: rgba(224,80,80,0.1);
  --t0: #dde1ff; --t1: #565c7a; --t2: #2e3350;
  --sidebar: 210px; --shadow: 0 4px 24px rgba(0,0,0,0.4);
}
[data-theme="light"] {
  --bg: #f4f5fb; --s1: #ffffff; --s2: #f8f9ff; --s3: #edf0ff; --card: #ffffff;
  --b0: rgba(0,0,0,0.03); --b1: rgba(0,0,0,0.07);
  --b2: rgba(0,0,0,0.11); --b3: rgba(0,0,0,0.17);
  --a: #3a6bef; --a2: #6b5def; --ag: rgba(58,107,239,0.08); --ag2: rgba(58,107,239,0.14);
  --amber: #c87820; --amber2: rgba(200,120,32,0.1); --amber3: rgba(200,120,32,0.2);
  --green: #18a860; --gt: rgba(24,168,96,0.1);
  --red: #d04040; --rt: rgba(208,64,64,0.1);
  --t0: #111830; --t1: #5a6284; --t2: #a0a8c4;
  --sidebar: 210px; --shadow: 0 4px 24px rgba(0,0,0,0.1);
}
body { font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', sans-serif; background: var(--bg); color: var(--t0); min-height: 100vh; -webkit-font-smoothing: antialiased; transition: background .3s, color .3s; }
a { color: inherit; text-decoration: none; }

/* ── LAYOUT ── */
.layout { display: flex; min-height: 100vh; }

/* ── SIDEBAR ── */
.sidebar {
  width: var(--sidebar); background: var(--s1); border-right: 1px solid var(--b1);
  display: flex; flex-direction: column; flex-shrink: 0; position: sticky; top: 0; height: 100vh; overflow-y: auto; z-index: 100;
}
.sb-logo { padding: 18px 14px 14px; border-bottom: 1px solid var(--b1); display: flex; align-items: center; gap: 9px; }
.sb-logo-svg { width: 28px; height: 28px; flex-shrink: 0; }
.sb-logo-name { font-size: 14px; font-weight: 700; color: var(--t0); letter-spacing: -.3px; }
.sb-logo-name em { color: var(--a); font-style: normal; font-weight: 300; }
.sb-v4 { font-size: 9px; padding: 1px 5px; border-radius: 4px; background: var(--ag2); color: #7aaaff; margin-left: 2px; font-weight: 700; }
.sb-sec { padding: 14px 10px 4px; }
.sb-sec-lbl { font-size: 9px; color: var(--t2); letter-spacing: 1.1px; text-transform: uppercase; padding: 0 8px; margin-bottom: 3px; }
.sb-item {
  display: flex; align-items: center; gap: 9px; padding: 7px 10px; border-radius: 7px;
  cursor: pointer; transition: all .15s; font-size: 12px; color: var(--t1);
  border: none; background: transparent; width: 100%; font-family: inherit; text-align: left; margin-bottom: 1px;
}
.sb-item:hover { background: var(--b0); color: var(--t0); }
.sb-item.active { background: var(--ag); color: #7aaaff; border: 1px solid rgba(74,123,255,0.18); }
.sb-item svg { width: 14px; height: 14px; flex-shrink: 0; opacity: .65; }
.sb-item.active svg { opacity: 1; }
.sb-notif-badge { margin-left: auto; min-width: 18px; height: 18px; border-radius: 9px; background: var(--a); color: #fff; font-size: 9px; font-weight: 700; display: flex; align-items: center; justify-content: center; padding: 0 4px; }
.sb-amber-badge { margin-left: auto; font-size: 9px; padding: 1px 6px; border-radius: 10px; background: var(--amber2); color: var(--amber); border: 1px solid var(--amber3); font-weight: 600; }
.sb-admin-badge { margin-left: auto; font-size: 9px; padding: 1px 6px; border-radius: 10px; background: var(--rt); color: var(--red); font-weight: 600; }
.sb-user { margin-top: auto; padding: 10px; border-top: 1px solid var(--b1); }
.sb-user-card { display: flex; align-items: center; gap: 8px; padding: 8px 10px; border-radius: 8px; background: var(--b0); border: 1px solid var(--b1); }
.sb-ava { width: 30px; height: 30px; border-radius: 50%; overflow: hidden; flex-shrink: 0; }
.sb-ava img { width: 100%; height: 100%; object-fit: cover; }
.sb-ava-init { width: 30px; height: 30px; border-radius: 50%; background: var(--ag2); display: flex; align-items: center; justify-content: center; font-size: 11px; font-weight: 700; color: var(--a); flex-shrink: 0; }
.sb-uname { font-size: 11px; font-weight: 600; color: var(--t0); line-height: 1.2; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 90px; }
.sb-uloc { font-size: 10px; color: var(--t1); margin-top: 1px; }
.sb-logout-btn { margin-left: auto; width: 24px; height: 24px; border-radius: 6px; flex-shrink: 0; background: rgba(224,80,80,0.08); border: 1px solid rgba(224,80,80,0.15); display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all .15s; }
.sb-logout-btn:hover { background: rgba(224,80,80,0.15); }
.sb-logout-btn svg { width: 12px; height: 12px; stroke: var(--red); fill: none; stroke-width: 1.8; stroke-linecap: round; stroke-linejoin: round; }

/* ── MOBILE NAV ── */
.mobile-nav {
  display: none; position: fixed; bottom: 0; left: 0; right: 0; z-index: 200;
  background: var(--s1); border-top: 1px solid var(--b1);
  padding: 8px 0 env(safe-area-inset-bottom, 8px);
}
.mobile-nav-inner { display: flex; justify-content: space-around; }
.mn-item { display: flex; flex-direction: column; align-items: center; gap: 3px; padding: 4px 12px; color: var(--t2); font-size: 10px; cursor: pointer; position: relative; }
.mn-item.active { color: var(--a); }
.mn-item svg { width: 20px; height: 20px; }
.mn-badge { position: absolute; top: 0; right: 6px; width: 16px; height: 16px; border-radius: 8px; background: var(--a); color: #fff; font-size: 8px; font-weight: 700; display: flex; align-items: center; justify-content: center; }

/* ── MOBILE HEADER ── */
.mobile-header { display: none; background: var(--s1); border-bottom: 1px solid var(--b1); padding: 12px 16px; align-items: center; gap: 10px; position: sticky; top: 0; z-index: 100; }
.mh-logo { font-size: 15px; font-weight: 700; color: var(--t0); }
.mh-logo em { color: var(--a); font-style: normal; font-weight: 300; }
.mh-search { flex: 1; }
.mh-search .search-box { width: 100%; }

/* ── MAIN ── */
.main { flex: 1; display: flex; flex-direction: column; min-width: 0; }

/* ── TOPBAR ── */
.topbar {
  height: 52px; background: rgba(6,7,14,0.97); border-bottom: 1px solid var(--b1);
  display: flex; align-items: center; padding: 0 22px; gap: 10px; position: sticky; top: 0; z-index: 50;
}
[data-theme="light"] .topbar { background: rgba(255,255,255,0.97); }
.topbar-title { font-size: 13px; font-weight: 500; color: var(--t0); flex: 1; letter-spacing: -.1px; }
.search-wrap { position: relative; }
.search-box { display: flex; align-items: center; gap: 7px; background: var(--s2); border: 1px solid var(--b1); border-radius: 8px; padding: 6px 12px; width: 220px; transition: border-color .15s; }
.search-box:focus-within { border-color: rgba(74,123,255,0.4); }
.search-box svg { width: 12px; height: 12px; color: var(--t2); flex-shrink: 0; }
.search-box input { background: transparent; border: none; outline: none; font-size: 12px; color: var(--t0); font-family: inherit; width: 100%; }
.search-box input::placeholder { color: var(--t2); }
.autocomplete-drop { position: absolute; top: calc(100% + 6px); left: 0; right: 0; background: var(--s2); border: 1px solid var(--b2); border-radius: 8px; overflow: hidden; z-index: 200; display: none; box-shadow: var(--shadow); }
.ac-item { display: flex; align-items: center; gap: 10px; padding: 8px 12px; cursor: pointer; transition: background .12s; font-size: 12px; }
.ac-item:hover { background: var(--b0); }
.ac-emoji { width: 28px; height: 28px; border-radius: 6px; background: var(--s3); display: flex; align-items: center; justify-content: center; font-size: 14px; flex-shrink: 0; overflow: hidden; }
.ac-emoji img { width: 100%; height: 100%; object-fit: cover; }
.ac-name { color: var(--t0); font-weight: 500; }
.ac-meta { color: var(--t2); font-size: 10px; margin-top: 1px; }

/* Lang */
.lang-sw { display: flex; background: var(--b0); border: 1px solid var(--b1); border-radius: 6px; overflow: hidden; flex-shrink: 0; }
.lang-btn { font-size: 11px; padding: 5px 10px; color: var(--t1); background: transparent; border: none; cursor: pointer; font-family: inherit; transition: all .15s; }
.lang-btn:hover { color: var(--t0); }
.lang-btn.on { background: var(--s3); color: var(--t0); }
.lang-div { width: 1px; background: var(--b1); }

/* Theme toggle */
.theme-btn { width: 30px; height: 30px; border-radius: 7px; border: 1px solid var(--b2); background: var(--b0); cursor: pointer; display: flex; align-items: center; justify-content: center; color: var(--t1); transition: all .15s; flex-shrink: 0; }
.theme-btn:hover { color: var(--t0); border-color: var(--b3); }
.theme-btn svg { width: 14px; height: 14px; }

/* ── CONTENT ── */
.content { padding: 20px 22px 80px; flex: 1; }
.flash-area { padding: 10px 22px 0; }
.flash { padding: 10px 16px; border-radius: 8px; font-size: 12px; margin-bottom: 6px; border: 1px solid; display: flex; align-items: center; gap: 8px; }
.flash.success { background: rgba(15,45,28,0.7); color: #4ecf7e; border-color: rgba(34,197,120,.2); }
.flash.danger  { background: rgba(60,15,15,0.7); color: #f07070; border-color: rgba(224,80,80,.2); }
.flash.warning { background: rgba(50,35,10,0.7); color: #d4a840; border-color: rgba(200,150,30,.2); }
.flash.info    { background: rgba(10,25,65,0.7); color: #7aaaff; border-color: rgba(74,123,255,.2); }
[data-theme="light"] .flash.success { background: rgba(220,255,235,0.9); }
[data-theme="light"] .flash.danger  { background: rgba(255,220,220,0.9); }
[data-theme="light"] .flash.info    { background: rgba(220,230,255,0.9); }

/* ── WELCOME CARD ── */
.welcome-card { background: var(--s1); border: 1px solid var(--b1); border-radius: 12px; padding: 18px 22px; margin-bottom: 16px; display: flex; align-items: center; justify-content: space-between; gap: 12px; }
.wc-left h2 { font-size: 17px; font-weight: 600; letter-spacing: -.3px; color: var(--t0); margin-bottom: 2px; }
.wc-left h2 em { font-style: normal; color: var(--amber); }
.wc-left p { font-size: 11px; color: var(--t1); }
.owner-pill { display: flex; align-items: center; gap: 6px; padding: 6px 14px; border-radius: 6px; background: var(--amber2); border: 1px solid var(--amber3); font-size: 11px; font-weight: 700; color: var(--amber); letter-spacing: .5px; white-space: nowrap; }
.vip-pill { display: flex; align-items: center; gap: 6px; padding: 6px 14px; border-radius: 6px; background: var(--ag); border: 1px solid rgba(74,123,255,.25); font-size: 11px; font-weight: 700; color: #7aaaff; letter-spacing: .5px; }

/* ── STAT GRID ── */
.stat-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin-bottom: 16px; }
.stat-card { background: var(--card); border: 1px solid var(--b1); border-radius: 11px; padding: 14px 16px; display: flex; flex-direction: column; gap: 10px; transition: border-color .2s; }
.stat-card:hover { border-color: var(--b2); }
.sc-icon { width: 36px; height: 36px; border-radius: 9px; display: flex; align-items: center; justify-content: center; }
.sc-icon svg { width: 16px; height: 16px; }
.ic-blue   { background: rgba(74,123,255,0.12); color: #7aaaff; }
.ic-purple { background: rgba(123,109,255,0.12); color: #a89cff; }
.ic-amber  { background: var(--amber2); color: var(--amber); }
.ic-green  { background: var(--gt); color: var(--green); }
.ic-red    { background: var(--rt); color: var(--red); }
.sc-val { font-size: 24px; font-weight: 500; color: var(--t0); letter-spacing: -.5px; line-height: 1; }
.sc-lbl { font-size: 10px; color: var(--t2); letter-spacing: .6px; text-transform: uppercase; margin-top: 2px; }
.sc-change { font-size: 10px; margin-top: 3px; }

/* ── SECTION ROW ── */
.sec-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
.sec-title { font-size: 10px; color: var(--t2); letter-spacing: .9px; text-transform: uppercase; display: flex; align-items: center; gap: 7px; }
.sec-dot { width: 5px; height: 5px; border-radius: 50%; flex-shrink: 0; }
.sec-link { font-size: 11px; color: var(--a); cursor: pointer; opacity: .7; transition: opacity .15s; }
.sec-link:hover { opacity: 1; }

/* ── FILTERS ── */
.filters { display: flex; gap: 5px; flex-wrap: wrap; margin-bottom: 14px; }
.chip { font-size: 11px; padding: 5px 13px; border-radius: 6px; border: 1px solid var(--b1); cursor: pointer; color: var(--t2); background: transparent; font-family: inherit; transition: all .15s; letter-spacing: .1px; }
.chip:hover { border-color: var(--b2); color: var(--t1); }
.chip.on { background: var(--ag2); border-color: rgba(74,123,255,.32); color: #7aaaff; }

/* ── SORT TABS ── */
.sort-row { display: flex; gap: 4px; margin-bottom: 14px; }
.sort-tab { font-size: 11px; padding: 4px 12px; border-radius: 6px; border: 1px solid var(--b1); cursor: pointer; color: var(--t2); background: transparent; font-family: inherit; transition: all .12s; }
.sort-tab:hover { border-color: var(--b2); color: var(--t1); }
.sort-tab.on { background: var(--ag); border-color: rgba(74,123,255,.3); color: #7aaaff; }

/* ── FEATURED BANNER ── */
.featured-banner {
  background: linear-gradient(135deg, rgba(74,123,255,0.12), rgba(123,109,255,0.12));
  border: 1px solid rgba(74,123,255,0.3); border-radius: 14px; padding: 20px;
  margin-bottom: 16px; display: flex; gap: 16px; align-items: center; position: relative; overflow: hidden;
}
.featured-banner::before { content: ''; position: absolute; top: -30px; right: -30px; width: 120px; height: 120px; border-radius: 50%; background: rgba(74,123,255,0.08); }
.fb-badge { font-size: 9px; padding: 2px 8px; border-radius: 20px; background: rgba(74,123,255,.2); color: #7aaaff; font-weight: 700; letter-spacing: .8px; text-transform: uppercase; margin-bottom: 6px; display: inline-block; }
.fb-name { font-size: 16px; font-weight: 700; color: var(--t0); margin-bottom: 4px; }
.fb-desc { font-size: 12px; color: var(--t1); }

/* ── SERVER CARD ── */
.scard { background: var(--card); border: 1px solid var(--b1); border-radius: 11px; padding: 15px 16px; margin-bottom: 8px; display: flex; gap: 13px; align-items: flex-start; transition: border-color .2s, background .15s; }
.scard:hover { background: var(--s2); border-color: var(--b2); }
.scard.pinned { border-left: 2px solid rgba(74,123,255,.45); }
.scard.featured-card { border-color: rgba(232,147,58,.35); background: rgba(232,147,58,.02); }
.sv-ava { width: 44px; height: 44px; border-radius: 10px; background: var(--s3); border: 1px solid var(--b1); display: flex; align-items: center; justify-content: center; font-size: 20px; flex-shrink: 0; overflow: hidden; }
.sv-ava img { width: 100%; height: 100%; object-fit: cover; }
.sv-body { flex: 1; min-width: 0; }
.sv-name-row { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; flex-wrap: wrap; }
.sv-name { font-size: 13px; font-weight: 600; color: var(--t0); letter-spacing: -.1px; }
.sv-desc { font-size: 11px; color: var(--t2); line-height: 1.5; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.sv-tags { display: flex; gap: 4px; margin-top: 6px; flex-wrap: wrap; }
.sv-tag { font-size: 10px; padding: 2px 8px; border-radius: 5px; background: var(--b0); color: var(--t2); border: 1px solid var(--b1); }
.sv-meta { display: flex; gap: 12px; margin-top: 7px; }
.sv-mi { font-size: 11px; color: var(--t2); display: flex; align-items: center; gap: 4px; }
.live-dot { width: 5px; height: 5px; border-radius: 50%; background: var(--green); flex-shrink: 0; animation: pulse 2s infinite; }
@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }
.sv-right { display: flex; flex-direction: column; gap: 5px; align-items: flex-end; flex-shrink: 0; padding-top: 1px; }

/* ── GIVEAWAY CARD ── */
.giveaway-card { background: linear-gradient(135deg, rgba(34,197,120,0.06), rgba(74,123,255,0.06)); border: 1px solid rgba(34,197,120,0.2); border-radius: 10px; padding: 14px 16px; margin-bottom: 8px; }
.giveaway-header { display: flex; align-items: center; gap: 8px; margin-bottom: 6px; }
.giveaway-badge { font-size: 9px; padding: 2px 8px; border-radius: 20px; background: rgba(34,197,120,.15); color: var(--green); font-weight: 700; letter-spacing: .5px; }
.giveaway-title { font-size: 13px; font-weight: 600; color: var(--t0); }
.giveaway-prize { font-size: 12px; color: var(--green); margin-bottom: 4px; }
.giveaway-meta { font-size: 11px; color: var(--t2); }

/* ── BADGES ── */
.bdg { font-size: 10px; padding: 2px 8px; border-radius: 5px; font-weight: 600; letter-spacing: .3px; }
.bdg-vip      { background: rgba(123,109,255,.1); color: #a89cff; border: 1px solid rgba(123,109,255,.2); }
.bdg-new      { background: rgba(34,197,120,.08); color: #3ecf7e; border: 1px solid rgba(34,197,120,.15); }
.bdg-hot      { background: var(--amber2); color: var(--amber); border: 1px solid var(--amber3); }
.bdg-ver      { background: rgba(74,123,255,.1); color: #7aaaff; border: 1px solid rgba(74,123,255,.18); }
.bdg-pro      { background: linear-gradient(90deg, rgba(74,123,255,.15), rgba(123,109,255,.15)); color: #b0a8ff; border: 1px solid rgba(123,109,255,.2); }
.bdg-featured { background: var(--amber2); color: var(--amber); border: 1px solid var(--amber3); }
.bdg-pending  { background: rgba(200,150,30,.1); color: #d4a840; border: 1px solid rgba(200,150,30,.2); }

/* ── BUTTONS ── */
.btn { display: inline-flex; align-items: center; justify-content: center; gap: 6px; border: none; cursor: pointer; font-family: inherit; font-weight: 500; transition: all .15s; letter-spacing: .2px; border-radius: 8px; white-space: nowrap; }
.btn svg { width: 12px; height: 12px; fill: currentColor; flex-shrink: 0; }
.btn-xs  { font-size: 10px; padding: 0 10px; height: 26px; border-radius: 6px; }
.btn-sm  { font-size: 11px; padding: 0 14px; height: 30px; }
.btn-md  { font-size: 12px; padding: 0 18px; height: 36px; }
.btn-lg  { font-size: 13px; padding: 0 24px; height: 42px; }
.btn-primary   { background: var(--a); color: #fff; }
.btn-primary:hover { background: #5d8eff; }
.btn-secondary { background: transparent; color: var(--t1); border: 1px solid var(--b2); }
.btn-secondary:hover { color: var(--t0); border-color: var(--b3); background: var(--b0); }
.btn-amber { background: var(--amber2); color: var(--amber); border: 1px solid var(--amber3); }
.btn-amber:hover { background: rgba(232,147,58,.2); }
.btn-danger { background: var(--rt); color: var(--red); border: 1px solid rgba(224,80,80,.18); }
.btn-danger:hover { background: rgba(224,80,80,.16); }
.btn-ghost { background: var(--b0); color: var(--t1); border: 1px solid var(--b1); }
.btn-ghost:hover { color: var(--t0); border-color: var(--b2); background: var(--b1); }
.btn-done { background: rgba(15,45,25,.8); color: var(--green); border: 1px solid rgba(34,197,120,.2); cursor: default; }
.btn-green { background: var(--gt); color: var(--green); border: 1px solid rgba(34,197,120,.2); }
.btn-green:hover { background: rgba(34,197,120,.15); }

/* ── FORMS ── */
.form-card { background: var(--card); border: 1px solid var(--b1); border-radius: 12px; padding: 22px; }
.form-title { font-size: 15px; font-weight: 600; letter-spacing: -.2px; margin-bottom: 20px; }
.form-group { margin-bottom: 14px; }
.form-label { font-size: 11px; color: var(--t1); margin-bottom: 5px; display: block; letter-spacing: .3px; }
.form-input { width: 100%; padding: 9px 13px; border-radius: 8px; border: 1px solid var(--b2); background: var(--s2); color: var(--t0); font-size: 13px; font-family: inherit; transition: border-color .15s; }
.form-input:focus { outline: none; border-color: rgba(74,123,255,.5); }
.form-textarea { width: 100%; padding: 9px 13px; border-radius: 8px; border: 1px solid var(--b2); background: var(--s2); color: var(--t0); font-size: 13px; font-family: inherit; resize: vertical; min-height: 90px; transition: border-color .15s; }
.form-textarea:focus { outline: none; border-color: rgba(74,123,255,.5); }
.form-select { width: 100%; padding: 9px 13px; border-radius: 8px; border: 1px solid var(--b2); background: var(--s2); color: var(--t0); font-size: 13px; font-family: inherit; }
.form-row2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.form-hint { font-size: 10px; color: var(--t2); margin-top: 4px; }
.type-toggle { display: flex; gap: 6px; }
.type-opt { flex: 1; padding: 9px; border-radius: 8px; border: 1px solid var(--b2); cursor: pointer; text-align: center; font-size: 12px; color: var(--t1); background: var(--s2); transition: all .15s; }
.type-opt.on { border-color: rgba(74,123,255,.4); background: var(--ag); color: #7aaaff; font-weight: 600; }
.upload-area { border: 2px dashed var(--b2); border-radius: 10px; padding: 20px; text-align: center; cursor: pointer; transition: border-color .2s; }
.upload-area:hover { border-color: var(--a); }
.upload-area input { display: none; }

/* ── AUTH ── */
.auth-outer { display: flex; justify-content: center; padding: 30px 20px; }
.auth-card { background: var(--card); border: 1px solid var(--b1); border-radius: 14px; padding: 30px; width: 100%; max-width: 380px; }
.auth-logo { display: flex; align-items: center; justify-content: center; gap: 9px; margin-bottom: 22px; }
.auth-logo-name { font-size: 16px; font-weight: 700; letter-spacing: -.3px; }
.auth-logo-name em { color: var(--a); font-style: normal; font-weight: 300; }
.auth-title { font-size: 16px; font-weight: 600; text-align: center; margin-bottom: 4px; }
.auth-sub { font-size: 12px; color: var(--t1); text-align: center; margin-bottom: 20px; }
.btn-discord { width: 100%; height: 40px; border-radius: 8px; background: #5865F2; color: #fff; border: none; cursor: pointer; font-size: 13px; font-weight: 600; display: flex; align-items: center; justify-content: center; gap: 8px; margin-bottom: 14px; transition: background .15s; font-family: inherit; }
.btn-discord:hover { background: #6a77f5; }
.divider { display: flex; align-items: center; gap: 10px; margin-bottom: 14px; }
.divider-line { flex: 1; height: 1px; background: var(--b1); }
.divider-text { font-size: 11px; color: var(--t2); }
.auth-footer { text-align: center; font-size: 12px; color: var(--t1); margin-top: 16px; }
.auth-footer a { color: #7aaaff; }

/* ── VIP PLANS ── */
.plan-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }
.plan-card { background: var(--card); border: 1px solid var(--b1); border-radius: 12px; padding: 22px; transition: border-color .2s; }
.plan-card.featured { border-color: rgba(74,123,255,.4); }
.plan-name { font-size: 13px; font-weight: 700; color: var(--t0); margin-bottom: 4px; }
.plan-price { font-size: 30px; font-weight: 500; color: var(--t0); letter-spacing: -.7px; margin: 10px 0 4px; }
.plan-price span { font-size: 12px; font-weight: 400; color: var(--t1); }
.plan-feats { margin: 14px 0; display: flex; flex-direction: column; gap: 8px; }
.pf { font-size: 12px; color: var(--t2); display: flex; align-items: center; gap: 8px; }
.pf.on { color: var(--t0); }
.pf-on-dot  { width: 6px; height: 6px; border-radius: 50%; background: var(--green); flex-shrink: 0; }
.pf-off-dot { width: 6px; height: 6px; border-radius: 50%; background: var(--t2); flex-shrink: 0; opacity: .35; }
.popular-bdg { font-size: 10px; padding: 3px 10px; border-radius: 20px; background: var(--ag2); color: #7aaaff; border: 1px solid rgba(74,123,255,.25); display: inline-block; margin-bottom: 9px; letter-spacing: .4px; font-weight: 600; }

/* ── DASHBOARD CHART ── */
.chart-card { background: var(--card); border: 1px solid var(--b1); border-radius: 11px; padding: 16px 18px; margin-bottom: 12px; }
.chart-title { font-size: 12px; font-weight: 500; margin-bottom: 14px; }
.bars { display: flex; align-items: flex-end; gap: 6px; height: 80px; }
.bar-col { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 5px; height: 100%; justify-content: flex-end; }
.bar { width: 100%; border-radius: 4px 4px 0 0; background: rgba(74,123,255,.2); min-height: 4px; transition: background .2s; }
.bar.today { background: var(--a); }
.bar-lbl { font-size: 9px; color: var(--t2); }

/* ── PROFILE ── */
.profile-header { background: var(--s1); border: 1px solid var(--b1); border-radius: 12px; padding: 22px; margin-bottom: 14px; display: flex; gap: 16px; align-items: flex-start; }
.profile-ava { width: 60px; height: 60px; border-radius: 50%; overflow: hidden; border: 2px solid var(--b2); }
.profile-ava img { width: 100%; height: 100%; object-fit: cover; }
.profile-ava-init { width: 60px; height: 60px; border-radius: 50%; background: var(--ag2); display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: 700; color: var(--a); border: 2px solid rgba(74,123,255,.25); }
.profile-name { font-size: 18px; font-weight: 700; letter-spacing: -.3px; margin-bottom: 4px; }
.profile-meta { font-size: 12px; color: var(--t1); display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.profile-bio { font-size: 12px; color: var(--t1); margin-top: 8px; line-height: 1.6; }
.profile-actions { margin-top: 14px; display: flex; gap: 8px; flex-wrap: wrap; }

/* ── NOTIFICATIONS ── */
.notif-item { background: var(--card); border: 1px solid var(--b1); border-radius: 10px; padding: 13px 16px; margin-bottom: 7px; display: flex; gap: 12px; }
.notif-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; margin-top: 4px; }
.notif-dot.success { background: var(--green); }
.notif-dot.info    { background: var(--a); }
.notif-dot.warning { background: var(--amber); }
.notif-dot.danger  { background: var(--red); }
.notif-title { font-size: 12px; font-weight: 600; color: var(--t0); margin-bottom: 2px; }
.notif-body  { font-size: 11px; color: var(--t2); }
.notif-time  { font-size: 10px; color: var(--t2); margin-top: 4px; }

/* ── DETAIL ── */
.detail-banner { width: 100%; height: 150px; border-radius: 12px 12px 0 0; object-fit: cover; margin-bottom: -20px; }
.detail-header { background: var(--s1); border: 1px solid var(--b1); border-radius: 12px; padding: 22px; margin-bottom: 14px; display: flex; gap: 18px; }
.detail-ava { width: 68px; height: 68px; border-radius: 14px; background: var(--s3); border: 1px solid var(--b1); display: flex; align-items: center; justify-content: center; font-size: 32px; flex-shrink: 0; overflow: hidden; }
.detail-ava img { width: 100%; height: 100%; object-fit: cover; }
.detail-name { font-size: 20px; font-weight: 700; letter-spacing: -.3px; margin-bottom: 6px; display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.detail-meta { font-size: 12px; color: var(--t1); margin-bottom: 10px; }
.detail-desc { font-size: 13px; color: var(--t1); line-height: 1.65; }
.detail-actions { display: flex; gap: 8px; margin-top: 16px; flex-wrap: wrap; }
.review-card { background: var(--card); border: 1px solid var(--b1); border-radius: 9px; padding: 12px 14px; margin-bottom: 8px; }
.review-top { display: flex; align-items: center; gap: 8px; margin-bottom: 4px; }
.review-author { font-size: 12px; font-weight: 600; color: var(--t0); }
.review-stars  { font-size: 11px; color: #f5a623; }
.review-date   { font-size: 10px; color: var(--t2); margin-left: auto; }
.review-comment { font-size: 12px; color: var(--t1); line-height: 1.5; }
.widget-embed-box { background: var(--s2); border: 1px solid var(--b1); border-radius: 8px; padding: 10px 13px; font-size: 11px; font-family: monospace; color: var(--t1); word-break: break-all; cursor: pointer; }
.widget-embed-box:hover { border-color: var(--a); color: var(--t0); }

/* ── BLOG ── */
.blog-card { background: var(--card); border: 1px solid var(--b1); border-radius: 11px; padding: 18px; margin-bottom: 10px; cursor: pointer; transition: border-color .2s; }
.blog-card:hover { border-color: var(--b2); }
.blog-title { font-size: 15px; font-weight: 600; color: var(--t0); margin-bottom: 6px; }
.blog-summary { font-size: 12px; color: var(--t1); line-height: 1.6; margin-bottom: 10px; }
.blog-meta { font-size: 10px; color: var(--t2); display: flex; gap: 10px; align-items: center; }
.blog-body { font-size: 13px; color: var(--t1); line-height: 1.8; white-space: pre-wrap; }

/* ── REFERRAL ── */
.ref-card { background: linear-gradient(135deg, rgba(74,123,255,0.08), rgba(123,109,255,0.08)); border: 1px solid rgba(74,123,255,0.2); border-radius: 12px; padding: 22px; margin-bottom: 16px; }
.ref-code { font-size: 22px; font-weight: 700; color: var(--a); letter-spacing: 3px; font-family: monospace; }
.ref-link { font-size: 12px; color: var(--t1); background: var(--s2); border: 1px solid var(--b1); border-radius: 7px; padding: 8px 12px; word-break: break-all; margin-top: 8px; }

/* ── 2FA ── */
.totp-qr { text-align: center; padding: 20px; }
.totp-qr img { width: 180px; height: 180px; border-radius: 10px; border: 2px solid var(--b2); }
.totp-secret { font-family: monospace; font-size: 13px; letter-spacing: 2px; background: var(--s2); border: 1px solid var(--b1); border-radius: 7px; padding: 8px 12px; text-align: center; margin-top: 10px; color: var(--t0); }

/* ── TOP 3 PODIUM ── */
.top3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin-bottom: 16px; }
.top-card { background: var(--card); border: 1px solid var(--b1); border-radius: 11px; padding: 16px; transition: border-color .2s; }
.top-card.gold-card { border-color: rgba(232,147,58,0.3); background: rgba(232,147,58,0.03); }
.top-rank { font-size: 20px; font-weight: 700; line-height: 1; margin-bottom: 10px; }
.rank-1 { color: var(--amber); } .rank-2 { color: #9ba3c0; } .rank-3 { color: #a07860; }
.top-ava { width: 38px; height: 38px; border-radius: 9px; background: var(--s3); display: flex; align-items: center; justify-content: center; font-size: 18px; margin-bottom: 9px; overflow: hidden; }
.top-ava img { width: 100%; height: 100%; object-fit: cover; }
.top-name { font-size: 12px; font-weight: 600; color: var(--t0); margin-bottom: 3px; }
.top-cat  { font-size: 10px; color: var(--t2); margin-bottom: 5px; }
.top-bump { font-size: 10px; color: var(--green); display: flex; align-items: center; gap: 3px; }

/* ── ADMIN PANEL ── */
.admin-sidebar { display: flex; gap: 4px; background: var(--s1); border: 1px solid var(--b1); border-radius: 10px; padding: 8px; margin-bottom: 16px; flex-wrap: wrap; }
.admin-tab { font-size: 11px; padding: 6px 14px; border-radius: 6px; border: none; cursor: pointer; color: var(--t1); background: transparent; font-family: inherit; transition: all .12s; display: flex; align-items: center; gap: 6px; }
.admin-tab:hover { background: var(--b0); color: var(--t0); }
.admin-tab.active { background: var(--ag); color: #7aaaff; }
.admin-tab .badge { min-width: 18px; height: 18px; border-radius: 9px; background: var(--red); color: #fff; font-size: 9px; font-weight: 700; display: inline-flex; align-items: center; justify-content: center; padding: 0 4px; }
.admin-table { width: 100%; border-collapse: collapse; font-size: 12px; }
.admin-table th { text-align: left; padding: 8px 12px; font-size: 10px; color: var(--t2); letter-spacing: .8px; text-transform: uppercase; border-bottom: 1px solid var(--b1); background: var(--s1); }
.admin-table td { padding: 10px 12px; border-bottom: 1px solid var(--b1); color: var(--t1); vertical-align: middle; }
.admin-table tr:last-child td { border-bottom: none; }
.admin-table tr:hover td { background: var(--b0); }
.admin-table-wrap { background: var(--card); border: 1px solid var(--b1); border-radius: 10px; overflow: auto; margin-bottom: 14px; }
.admin-stat-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin-bottom: 16px; }
.mini-chart { display: flex; align-items: flex-end; gap: 3px; height: 40px; margin-top: 10px; }
.mini-bar { flex: 1; border-radius: 2px 2px 0 0; background: rgba(74,123,255,.25); min-height: 2px; }
.mini-bar.today { background: var(--a); }

/* ── TABLE ACTIONS ── */
.action-group { display: flex; gap: 4px; align-items: center; flex-wrap: wrap; }

/* ── MODALS ── */
.modal-backdrop { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.6); z-index: 500; align-items: center; justify-content: center; padding: 20px; }
.modal-backdrop.open { display: flex; }
.modal { background: var(--s1); border: 1px solid var(--b2); border-radius: 14px; padding: 24px; width: 100%; max-width: 400px; max-height: 90vh; overflow-y: auto; }
.modal-title { font-size: 14px; font-weight: 600; margin-bottom: 16px; }
.modal-close { float: right; background: none; border: none; color: var(--t1); cursor: pointer; font-size: 18px; line-height: 1; }
.modal-close:hover { color: var(--t0); }

/* ── EMPTY ── */
.empty { text-align: center; padding: 50px 20px; color: var(--t1); }
.empty-icon { font-size: 38px; margin-bottom: 12px; opacity: .4; }

/* ── GEO TOAST ── */
.geo-toast { background: var(--s2); border: 1px solid var(--b2); border-radius: 10px; padding: 11px 16px; margin-bottom: 14px; display: flex; align-items: center; gap: 12px; font-size: 12px; animation: slideDown .3s ease; }
@keyframes slideDown { from { opacity:0; transform: translateY(-6px); } to { opacity:1; transform: translateY(0); } }
.geo-close { margin-left: auto; color: var(--t2); cursor: pointer; font-size: 16px; line-height: 1; padding: 0 4px; }

/* ── FOOTER ── */
.footer { border-top: 1px solid var(--b1); padding: 14px 22px; display: flex; align-items: center; justify-content: space-between; flex-shrink: 0; flex-wrap: wrap; gap: 8px; }
.f-logo { display: flex; align-items: center; gap: 8px; }
.f-logo-name { font-size: 12px; font-weight: 700; letter-spacing: -.2px; }
.f-logo-name em { color: var(--a); font-style: normal; font-weight: 300; }
.f-copy  { font-size: 11px; color: var(--t2); }
.f-brand { font-size: 11px; color: var(--t2); }
.f-brand b { color: var(--t1); font-weight: 700; }

/* ══════════════════════════════════════
   MOBILE RESPONSIVE — FULL
══════════════════════════════════════ */
@media (max-width: 768px) {
  .sidebar { display: none !important; }
  .topbar  { display: none !important; }
  .mobile-header { display: flex; }
  .mobile-nav { display: block; }
  .layout { flex-direction: column; }
  .content { padding: 14px 14px 90px; }
  .flash-area { padding: 8px 14px 0; }
  .stat-grid { grid-template-columns: 1fr 1fr; }
  .plan-grid { grid-template-columns: 1fr; }
  .top3 { grid-template-columns: 1fr; }
  .form-row2 { grid-template-columns: 1fr; }
  .welcome-card { flex-direction: column; align-items: flex-start; }
  .auth-outer { padding: 14px; }
  .auth-card { padding: 20px 16px; }
  .detail-header { flex-direction: column; }
  .detail-name { font-size: 16px; }
  .admin-stat-grid { grid-template-columns: 1fr 1fr; }
  .scard { flex-wrap: wrap; }
  .sv-right { flex-direction: row; flex-wrap: wrap; justify-content: flex-start; width: 100%; padding-top: 8px; }
  .profile-header { flex-direction: column; }
  .featured-banner { flex-direction: column; }
  .admin-table-wrap { overflow-x: auto; }
  .sc-val { font-size: 18px; }
  .sort-row { overflow-x: auto; padding-bottom: 4px; }
  .filters { overflow-x: auto; flex-wrap: nowrap; padding-bottom: 4px; }
}
@media (max-width: 420px) {
  .stat-grid { grid-template-columns: 1fr; }
  .btn-md { height: 38px; font-size: 13px; }
}
</style>
</head>
<body>

{# ── REPORT MODAL ── #}
<div class="modal-backdrop" id="report-modal">
  <div class="modal">
    <button class="modal-close" onclick="closeReport()">×</button>
    <div class="modal-title">Репортирай сървър</div>
    <input type="hidden" id="report-sid">
    <div class="form-group">
      <label class="form-label">Причина</label>
      <select class="form-select" id="report-reason">
        <option value="spam">Спам / Реклама</option>
        <option value="inappropriate">Неподходящо съдържание</option>
        <option value="scam">Измама / Scam</option>
        <option value="inactive">Неактивен сървър</option>
        <option value="other">Друго</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Детайли (по желание)</label>
      <textarea class="form-textarea" id="report-details" style="min-height:70px" placeholder="Опиши проблема..."></textarea>
    </div>
    <div style="display:flex;gap:8px">
      <button class="btn btn-md btn-danger" style="flex:1" onclick="submitReport()">Изпрати репорт</button>
      <button class="btn btn-md btn-secondary" onclick="closeReport()">Отказ</button>
    </div>
  </div>
</div>

{# ── BAN MODAL ── #}
<div class="modal-backdrop" id="ban-modal">
  <div class="modal">
    <button class="modal-close" onclick="closeBan()">×</button>
    <div class="modal-title">🔨 Бан на потребител</div>
    <form id="ban-form" method="POST">
      <div class="form-group">
        <label class="form-label">Причина за бан</label>
        <input name="reason" class="form-input" placeholder="Нарушение на правилата..." required>
      </div>
      <button type="submit" class="btn btn-md btn-danger" style="width:100%;justify-content:center">Бан</button>
    </form>
  </div>
</div>

{# ── REJECT MODAL ── #}
<div class="modal-backdrop" id="reject-modal">
  <div class="modal">
    <button class="modal-close" onclick="closeReject()">×</button>
    <div class="modal-title">❌ Отхвърли сървър</div>
    <form id="reject-form" method="POST">
      <div class="form-group">
        <label class="form-label">Причина</label>
        <input name="reason" class="form-input" value="Не отговаря на изискванията." required>
      </div>
      <button type="submit" class="btn btn-md btn-danger" style="width:100%;justify-content:center">Отхвърли и изтрий</button>
    </form>
  </div>
</div>

{# ── GIVEAWAY MODAL ── #}
<div class="modal-backdrop" id="giveaway-modal">
  <div class="modal">
    <button class="modal-close" onclick="closeModal('giveaway-modal')">×</button>
    <div class="modal-title">🎁 Създай Giveaway</div>
    <form id="giveaway-form" method="POST">
      <div class="form-group"><label class="form-label">Заглавие</label><input name="title" class="form-input" placeholder="Giveaway заглавие..." required></div>
      <div class="form-group"><label class="form-label">Награда 🏆</label><input name="prize" class="form-input" placeholder="Discord Nitro, VIP роля..." required></div>
      <div class="form-group"><label class="form-label">Описание</label><textarea name="description" class="form-textarea" style="min-height:60px" placeholder="По желание..."></textarea></div>
      <div class="form-group"><label class="form-label">Продължителност (дни)</label><input name="days" type="number" class="form-input" value="7" min="1" max="30"></div>
      <button type="submit" class="btn btn-md btn-green" style="width:100%;justify-content:center">🎁 Стартирай Giveaway</button>
    </form>
  </div>
</div>

{% set cur = current_user() %}

{# ── MOBILE HEADER ── #}
<div class="mobile-header">
  <span class="mh-logo">qboard<em>ix</em> <span class="sb-v4">V4</span></span>
  <div class="mh-search">
    <div class="search-box">
      <svg viewBox="0 0 14 14" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="6" cy="6" r="4"/><path d="M9.5 9.5l2.5 2.5"/></svg>
      <input id="search-input-m" placeholder="{{ _('Търси...','Search...','Suchen...') }}" autocomplete="off" onkeyup="doSearch(this.value)">
    </div>
  </div>
  <button class="theme-btn" onclick="toggleTheme()" title="Toggle theme">
    <svg id="theme-icon" viewBox="0 0 16 16" fill="currentColor"><path d="M8 12a4 4 0 1 1 0-8 4 4 0 0 1 0 8zm0-1.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5zM8 0h1v2H7V0h1zm0 14h1v2H7v-2h1zM2.05 2.05l1.06 1.06L1.7 4.52.64 3.46l1.41-1.41zM13.94 13.94l-1.06-1.06 1.41-1.41 1.06 1.06-1.41 1.41zM0 7v1h2V7H0zm14 0v1h2V7h-2zM2.05 13.94l1.41-1.41 1.06 1.06-1.41 1.41-1.06-1.06zM13.94 2.05l-1.41 1.41-1.06-1.06L12.88.99l1.06 1.06z"/></svg>
  </button>
</div>

<div class="layout">

{# ── SIDEBAR ── #}
<aside class="sidebar">
  <div class="sb-logo">
    <svg class="sb-logo-svg" viewBox="0 0 28 28" fill="none"><rect width="28" height="28" rx="7" fill="#08091a"/><rect x="4" y="4" width="8" height="8" rx="2.2" fill="#4a7bff"/><rect x="16" y="4" width="8" height="8" rx="2.2" fill="#4a7bff" opacity=".35"/><rect x="4" y="16" width="8" height="8" rx="2.2" fill="#7b6dff" opacity=".5"/><rect x="16" y="16" width="8" height="8" rx="2.2" fill="#4a7bff" opacity=".82"/></svg>
    <span class="sb-logo-name">qboard<em>ix</em> <span class="sb-v4">V4</span></span>
  </div>

  <div class="sb-sec">
    <div class="sb-sec-lbl">{{ _('Главно','Main','Haupt') }}</div>
    <a href="/"><button class="sb-item {% if page=='home' %}active{% endif %}">
      <svg viewBox="0 0 16 16" fill="currentColor"><path d="M8 1.5L1.5 7.5V14h4v-4h5v4h4V7.5L8 1.5z"/></svg>
      {{ _('Начало','Home','Startseite') }}
    </button></a>
    <a href="/top"><button class="sb-item {% if page=='top' %}active{% endif %}">
      <svg viewBox="0 0 16 16" fill="currentColor"><path d="M8 1l1.8 5H15l-4.3 3.1 1.6 5L8 11.3 3.7 14.1l1.6-5L1 5.9h5.2L8 1z"/></svg>
      {{ _('Топ класация','Top Chart','Rangliste') }}
      <span class="sb-amber-badge">TOP</span>
    </button></a>
    <a href="/blog"><button class="sb-item {% if page in ('blog_list','blog_post') %}active{% endif %}">
      <svg viewBox="0 0 16 16" fill="currentColor"><rect x="2" y="1" width="12" height="14" rx="2" opacity=".3"/><rect x="4" y="4" width="8" height="1.5" rx=".75"/><rect x="4" y="7" width="6" height="1.5" rx=".75"/><rect x="4" y="10" width="7" height="1.5" rx=".75"/></svg>
      {{ _('Блог','Blog','Blog') }}
    </button></a>
  </div>

  <div class="sb-sec">
    <div class="sb-sec-lbl">{{ _('Акаунт','Account','Konto') }}</div>
    {% if cur %}
    <a href="/profile/{{ cur.id }}"><button class="sb-item {% if page=='profile' %}active{% endif %}">
      <svg viewBox="0 0 16 16" fill="currentColor"><circle cx="8" cy="5" r="3"/><path d="M2 14c0-3.3 2.7-5.5 6-5.5s6 2.2 6 5.5H2z"/></svg>
      {{ _('Профил','Profile','Profil') }}
    </button></a>
    <a href="/dashboard"><button class="sb-item {% if page=='dashboard' %}active{% endif %}">
      <svg viewBox="0 0 16 16" fill="currentColor"><rect x="1" y="9" width="4" height="6" rx="1"/><rect x="6" y="6" width="4" height="9" rx="1"/><rect x="11" y="2" width="4" height="13" rx="1"/></svg>
      {{ _('Дашборд','Dashboard','Dashboard') }}
    </button></a>
    <a href="/notifications"><button class="sb-item {% if page=='notifications' %}active{% endif %}">
      <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M8 2a5 5 0 0 1 5 5v3l1.5 2H1.5L3 10V7a5 5 0 0 1 5-5z"/><path d="M6.5 13.5a1.5 1.5 0 0 0 3 0"/></svg>
      {{ _('Известия','Notifications','Benachrichtigungen') }}
      <span class="sb-notif-badge" id="notif-count" style="display:none">0</span>
    </button></a>
    <a href="/referral"><button class="sb-item {% if page=='referral' %}active{% endif %}">
      <svg viewBox="0 0 16 16" fill="currentColor"><circle cx="5" cy="5" r="2.5"/><circle cx="11" cy="5" r="2.5"/><path d="M1 14c0-2.5 1.8-4 4-4s4 1.5 4 4H1z"/><path d="M11 9c1.5 0 3 1 3 3.5h-2.5"/></svg>
      {{ _('Реферали','Referrals','Referrals') }}
    </button></a>
    {% endif %}
    <a href="/add"><button class="sb-item {% if page=='add' %}active{% endif %}">
      <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M8 3v10M3 8h10"/></svg>
      {{ _('Добави сървър','Add Server','Server hinzufügen') }}
    </button></a>
  </div>

  <div class="sb-sec">
    <div class="sb-sec-lbl">{{ _('Система','System','System') }}</div>
    <a href="/vip"><button class="sb-item {% if page=='vip' %}active{% endif %}">
      <svg viewBox="0 0 16 16" fill="currentColor"><path d="M8 1l1.5 4.5H14L10.2 8l1.4 4.5L8 10.2 4.4 12.5 5.8 8 2 5.5h4.5L8 1z"/></svg>
      VIP {{ _('планове','Plans','Pläne') }}
    </button></a>
    {% if cur and cur.is_admin %}
    <a href="/admin"><button class="sb-item {% if page and page.startswith('admin') %}active{% endif %}">
      <svg viewBox="0 0 16 16" fill="currentColor"><path d="M8 1a4 4 0 0 1 4 4 4 4 0 0 1-1.2 2.87L14 12l-1 1-3.13-3.13A4 4 0 0 1 8 11 4 4 0 0 1 4 7a4 4 0 0 1 4-4zm0 1.5A2.5 2.5 0 0 0 5.5 5 2.5 2.5 0 0 0 8 7.5 2.5 2.5 0 0 0 10.5 5 2.5 2.5 0 0 0 8 2.5z"/></svg>
      Admin
      <span class="sb-admin-badge">ADM</span>
    </button></a>
    {% endif %}
  </div>

  {% if cur %}
  <div class="sb-user">
    <div class="sb-user-card">
      {% if cur.avatar_url %}
        <div class="sb-ava"><img src="{{ cur.avatar_url }}" alt="{{ cur.username }}"></div>
      {% else %}
        <div class="sb-ava-init">{{ cur.username[:2].upper() }}</div>
      {% endif %}
      <div style="min-width:0">
        <div class="sb-uname">{{ cur.username }}</div>
        <div class="sb-uloc">{{ cur.flag }} {{ cur.city or cur.country or '—' }}</div>
      </div>
      <a href="/logout"><div class="sb-logout-btn">
        <svg viewBox="0 0 12 12"><path d="M8 2h2a1 1 0 011 1v6a1 1 0 01-1 1H8"/><path d="M5 8.5l3-2.5-3-2.5"/><line x1="8" y1="6" x2="1" y2="6"/></svg>
      </div></a>
    </div>
  </div>
  {% else %}
  <div class="sb-user">
    <a href="/login/discord"><button class="btn btn-md btn-primary" style="width:100%;justify-content:center">
      <svg viewBox="0 0 127.14 96.36" fill="currentColor" style="width:13px;height:13px"><path d="M107.7,8.07A105.15,105.15,0,0,0,81.47,0a72.06,72.06,0,0,0-3.36,6.83A97.68,97.68,0,0,0,49,6.83,72.37,72.37,0,0,0,45.64,0,105.89,105.89,0,0,0,19.39,8.09C2.79,32.65-1.71,56.6.54,80.21h0A105.73,105.73,0,0,0,32.71,96.36,77.7,77.7,0,0,0,39.6,85.25a68.42,68.42,0,0,1-10.85-5.18c.91-.66,1.8-1.34,2.66-2a75.57,75.57,0,0,0,64.32,0c.87.71,1.76,1.39,2.66,2a68.68,68.68,0,0,1-10.87,5.19,77,77,0,0,0,6.89,11.1A105.25,105.25,0,0,0,126.6,80.22h0C129.24,52.84,122.09,29.11,107.7,8.07Z"/></svg>
      Discord
    </button></a>
  </div>
  {% endif %}
</aside>

{# ── MAIN ── #}
<div class="main">
  <div class="topbar">
    <span class="topbar-title">
      {% if page == 'home' %}{{ _('Начало','Home','Startseite') }}
      {% elif page == 'top' %}{{ _('Топ класация','Top Chart','Rangliste') }}
      {% elif page == 'detail' %}{{ server.name if server is defined else 'Сървър' }}
      {% elif page == 'add' %}{{ _('Добави сървър','Add Server','Server hinzufügen') }}
      {% elif page == 'edit_server' %}{{ _('Редактирай','Edit Server','Server bearbeiten') }}
      {% elif page == 'vip' %}VIP Plans
      {% elif page == 'dashboard' %}Dashboard
      {% elif page in ('profile','profile_edit') %}{{ _('Профил','Profile','Profil') }}
      {% elif page == 'notifications' %}{{ _('Известия','Notifications','Nachrichten') }}
      {% elif page == 'login' %}{{ _('Вход','Login','Anmelden') }}
      {% elif page == 'register' %}{{ _('Регистрация','Register','Registrieren') }}
      {% elif page == 'referral' %}{{ _('Реферали','Referrals','Referrals') }}
      {% elif page in ('blog_list','blog_post') %}Blog
      {% elif page and page.startswith('admin') %}Admin Panel
      {% elif page == 'totp_setup' %}2FA Setup
      {% elif page == 'totp_verify' %}2FA Verify
      {% else %}quboardix.eu{% endif %}
    </span>

    <div class="search-wrap">
      <div class="search-box">
        <svg viewBox="0 0 14 14" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="6" cy="6" r="4"/><path d="M9.5 9.5l2.5 2.5"/></svg>
        <input id="search-input" placeholder="{{ _('Търси сървър...','Search...','Suchen...') }}" autocomplete="off" onkeyup="doSearch(this.value)">
      </div>
      <div class="autocomplete-drop" id="ac-drop"></div>
    </div>

    <div class="lang-sw">
      <a href="/lang/bg"><button class="lang-btn {% if lang=='bg' %}on{% endif %}">🇧🇬 BG</button></a>
      <div class="lang-div"></div>
      <a href="/lang/en"><button class="lang-btn {% if lang=='en' %}on{% endif %}">🇬🇧 EN</button></a>
      <div class="lang-div"></div>
      <a href="/lang/de"><button class="lang-btn {% if lang=='de' %}on{% endif %}">🇩🇪 DE</button></a>
    </div>

    <button class="theme-btn" onclick="toggleTheme()" title="Toggle theme">
      <svg id="theme-icon-desk" viewBox="0 0 16 16" fill="currentColor"><path d="M8 12a4 4 0 1 1 0-8 4 4 0 0 1 0 8zm0-1.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z"/></svg>
    </button>
  </div>

  {# Flash #}
  {% with messages = get_flashed_messages(with_categories=true) %}
  {% if messages %}
  <div class="flash-area">
    {% for cat, msg in messages %}
    <div class="flash {{ cat }}">
      <div style="width:18px;height:18px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:9px;font-weight:700;flex-shrink:0;background:{% if cat=='success' %}rgba(34,197,120,.2){% elif cat=='danger' %}rgba(224,80,80,.2){% elif cat=='warning' %}rgba(200,150,30,.2){% else %}rgba(74,123,255,.2){% endif %}">
        {% if cat=='success' %}✓{% elif cat=='danger' %}✕{% elif cat=='warning' %}!{% else %}i{% endif %}
      </div>
      {{ msg }}
    </div>
    {% endfor %}
  </div>
  {% endif %}
  {% endwith %}

  <div class="content">

{# ════ HOME ════ #}
{% if page == 'home' %}

  {% if cur and cur.city %}
  <div id="geo-toast" class="geo-toast" style="display:none">
    <span style="font-size:22px">{{ cur.flag }}</span>
    <div>
      <div style="font-weight:600;color:var(--t0);margin-bottom:1px">{{ _('Добре дошъл от ' + cur.city + '!','Welcome from ' + cur.city + '!','Willkommen aus ' + cur.city + '!') }}</div>
      <div style="font-size:11px;color:var(--t1)">{{ cur.flag }} {{ cur.city }}, {{ cur.country }}</div>
    </div>
    <span class="geo-close" onclick="document.getElementById('geo-toast').style.display='none'">×</span>
  </div>
  {% endif %}

  <div class="welcome-card">
    <div class="wc-left">
      {% if cur %}
        <h2>{{ _('Добре дошъл,','Welcome back,','Willkommen,') }} <em>{{ cur.username }}</em></h2>
        <p>{{ _('Ето какво се случва днес в quboardix.eu','Here is what is happening today','Hier ist was heute passiert') }}</p>
      {% else %}
        <h2>{{ _('Намери перфектния','Find the perfect','Finde den perfekten') }} <em>Discord {{ _('сървър','Server','Server') }}</em></h2>
        <p>{{ _('Хиляди активни общности на едно място','Thousands of active communities in one place','Tausende aktiver Communities') }}</p>
      {% endif %}
    </div>
    {% if cur and cur.vip_active %}
      <div class="vip-pill">⭐ {{ cur.vip_plan | upper }}</div>
    {% elif not cur %}
      <a href="/login/discord"><button class="btn btn-lg btn-primary">
        <svg viewBox="0 0 127.14 96.36" fill="currentColor" style="width:14px;height:14px"><path d="M107.7,8.07A105.15,105.15,0,0,0,81.47,0a72.06,72.06,0,0,0-3.36,6.83A97.68,97.68,0,0,0,49,6.83,72.37,72.37,0,0,0,45.64,0,105.89,105.89,0,0,0,19.39,8.09C2.79,32.65-1.71,56.6.54,80.21h0A105.73,105.73,0,0,0,32.71,96.36,77.7,77.7,0,0,0,39.6,85.25a68.42,68.42,0,0,1-10.85-5.18c.91-.66,1.8-1.34,2.66-2a75.57,75.57,0,0,0,64.32,0c.87.71,1.76,1.39,2.66,2a68.68,68.68,0,0,1-10.87,5.19,77,77,0,0,0,6.89,11.1A105.25,105.25,0,0,0,126.6,80.22h0C129.24,52.84,122.09,29.11,107.7,8.07Z"/></svg>
        {{ _('Влез с Discord','Login with Discord','Mit Discord') }}
      </button></a>
    {% endif %}
  </div>

  <div class="stat-grid">
    <div class="stat-card"><div class="sc-icon ic-blue"><svg viewBox="0 0 16 16" fill="currentColor"><rect x="1" y="2" width="14" height="3.5" rx="1"/><rect x="1" y="7.5" width="14" height="3.5" rx="1"/></svg></div><div><div class="sc-val">{{ "{:,}".format(total_servers) }}</div><div class="sc-lbl">{{ _('Сървъри','Servers','Server') }}</div></div></div>
    <div class="stat-card"><div class="sc-icon ic-purple"><svg viewBox="0 0 16 16" fill="currentColor"><circle cx="5.5" cy="5" r="2.5"/><circle cx="11" cy="5" r="2"/><path d="M0 14c0-3 2.5-5 5.5-5s5.5 2 5.5 5H0z"/><path d="M11 9c2.2 0 4 1.6 4 4h-3.5"/></svg></div><div><div class="sc-val">{{ "{:,}".format(total_members) }}</div><div class="sc-lbl">{{ _('Членове','Members','Mitglieder') }}</div></div></div>
    <div class="stat-card"><div class="sc-icon ic-amber"><svg viewBox="0 0 16 16" fill="currentColor"><path d="M8 1l1.5 4.5H14L10.2 8l1.4 4.5L8 10.2 4.4 12.5 5.8 8 2 5.5h4.5L8 1z"/></svg></div><div><div class="sc-val">{{ "{:,}".format(total_bumps) }}</div><div class="sc-lbl">{{ _('Бъмпове','Bumps','Bumps') }}</div></div></div>
    <div class="stat-card"><div class="sc-icon ic-green"><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M2 11l4-4 3 3 5-6"/></svg></div><div><div class="sc-val">{{ servers | selectattr('vip') | list | length }}</div><div class="sc-lbl">VIP</div></div></div>
  </div>

  {% if active_giveaways %}
  <div class="sec-row"><span class="sec-title"><span class="sec-dot" style="background:var(--green)"></span>🎁 {{ _('Активни Giveaway','Active Giveaways','Aktive Giveaways') }}</span></div>
  {% for g in active_giveaways %}
  <div class="giveaway-card">
    <div class="giveaway-header"><span class="giveaway-badge">GIVEAWAY</span><span style="font-size:11px;color:var(--t2)">{{ g.server.name }}</span></div>
    <div class="giveaway-title">{{ g.title }}</div>
    <div class="giveaway-prize">🏆 {{ g.prize }}</div>
    <div class="giveaway-meta">{{ g.entries | length }} {{ _('участника','participants','Teilnehmer') }} · {{ _('Завършва','Ends','Endet') }} {{ g.ends_at.strftime('%d.%m.%Y') }}</div>
    {% if cur %}<button class="btn btn-xs btn-green" style="margin-top:8px" onclick="enterGiveaway({{ g.id }}, this)">{{ _('Участвай','Enter','Teilnehmen') }}</button>{% endif %}
  </div>
  {% endfor %}
  {% endif %}

  {% if recent_posts %}
  <div class="sec-row"><span class="sec-title"><span class="sec-dot" style="background:var(--a)"></span>{{ _('Последни новини','Latest News','Neueste Nachrichten') }}</span><a href="/blog"><span class="sec-link">{{ _('Виж всички →','See all →','Alle →') }}</span></a></div>
  <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:8px;margin-bottom:16px">
    {% for post in recent_posts %}
    <a href="/blog/{{ post.slug }}">
      <div class="blog-card" style="padding:14px">
        <div class="blog-title" style="font-size:13px">{{ post.title }}</div>
        <div class="blog-meta" style="margin-top:4px"><span>{{ post.author.username }}</span><span>{{ post.created_at.strftime('%d.%m.%Y') }}</span></div>
      </div>
    </a>
    {% endfor %}
  </div>
  {% endif %}

  <form method="GET" action="/">
    <input type="hidden" name="lang" value="{{ lang }}">
    <div class="sec-row" style="margin-bottom:8px"><span class="sec-title"><span class="sec-dot" style="background:var(--a)"></span>{{ _('Категории','Categories','Kategorien') }}</span></div>
    <div class="filters">
      {% for key, bg, en, de in categories %}
        {% set label = bg if lang=='bg' else en if lang=='en' else de %}
        <button type="submit" name="cat" value="{{ key }}" class="chip {% if active_cat==key %}on{% endif %}">{{ label }}</button>
      {% endfor %}
    </div>
  </form>

  <div class="sort-row">
    {% set sorts = [('bump','↑ Bump'),('members','👥 Members'),('rating','★ Rating'),('new','🆕 New')] %}
    {% for sv, sl in sorts %}
      <a href="/?cat={{ active_cat }}&sort={{ sv }}&lang={{ lang }}{% if query %}&q={{ query }}{% endif %}"><button class="sort-tab {% if sort==sv %}on{% endif %}">{{ sl }}</button></a>
    {% endfor %}
  </div>

  <div class="sec-row">
    <span class="sec-title"><span class="sec-dot" style="background:var(--a)"></span>{{ _('Сървъри','Servers','Server') }} · {{ servers|length }}</span>
    <a href="/top"><span class="sec-link">{{ _('Топ →','Top →','Rangliste →') }}</span></a>
  </div>

  {% if servers %}
    {% for s in servers %}
    <div class="scard {% if s.vip %}pinned{% endif %} {% if s.featured %}featured-card{% endif %}">
      {% if s.featured %}<div style="position:absolute;top:10px;right:10px"><span class="bdg bdg-featured">⭐ FEATURED</span></div>{% endif %}
      <a href="/server/{{ s.id }}" style="display:flex;gap:13px;flex:1;min-width:0;align-items:flex-start">
        <div class="sv-ava">{% if s.icon_url %}<img src="{{ s.icon_url }}" alt="{{ s.name }}">{% else %}{{ s.emoji }}{% endif %}</div>
        <div class="sv-body">
          <div class="sv-name-row">
            <span class="sv-name">{{ s.name }}</span>
            {% if s.featured %}<span class="bdg bdg-featured">★</span>{% elif s.vip %}<span class="bdg bdg-vip">VIP</span>{% endif %}
            {% if s.verified %}<span class="bdg bdg-ver">✓</span>{% endif %}
            {% if s.is_new %}<span class="bdg bdg-new">{{ _('НОВО','NEW','NEU') }}</span>{% endif %}
          </div>
          <div class="sv-desc">{{ s.description }}</div>
          {% if s.tag_list %}<div class="sv-tags">{% for t in s.tag_list[:4] %}<span class="sv-tag">{{ t }}</span>{% endfor %}</div>{% endif %}
          <div class="sv-meta">
            <span class="sv-mi"><span class="live-dot"></span>{{ "{:,}".format(s.member_count or 0) }}</span>
            <span class="sv-mi">↑ {{ "{:,}".format(s.bump_count or 0) }}</span>
            <span class="sv-mi">★ {{ s.avg_rating }}</span>
            <span class="sv-mi">{{ s.category }}</span>
          </div>
        </div>
      </a>
      <div class="sv-right">
        <button class="btn btn-sm btn-primary" onclick="doBump({{ s.id }}, this)">↑ {{ _('Бъмп','Bump','Bump') }}</button>
        <a href="{{ s.invite_url }}" target="_blank"><button class="btn btn-sm btn-secondary">{{ _('Влез','Join','Beitreten') }} →</button></a>
        <button class="btn btn-xs btn-ghost" onclick="openReport({{ s.id }})">⚑</button>
      </div>
    </div>
    {% endfor %}
  {% else %}
    <div class="empty"><div class="empty-icon">🔍</div><div>{{ _('Няма намерени сървъри.','No servers found.','Keine Server gefunden.') }} <a href="/add" style="color:#7aaaff">{{ _('Добави!','Add one!','Hinzufügen!') }}</a></div></div>
  {% endif %}

{# ════ TOP CHART ════ #}
{% elif page == 'top' %}
  <div class="welcome-card">
    <div class="wc-left"><h2>{{ _('Топ','Top','Top') }} <em>{{ _('класация','Chart','Rangliste') }}</em></h2><p>{{ _('Най-бъмпваните сървъри тази седмица','Most bumped servers this week','Meistgebumpte Server') }}</p></div>
    <div class="owner-pill"><svg viewBox="0 0 12 12" fill="currentColor" style="width:12px;height:12px"><path d="M6 1l1.2 3.5H11L8.2 6.8l1.2 3.7L6 8.5l-3.4 2 1.2-3.7L1 4.5h3.8z"/></svg> WEEKLY TOP 10</div>
  </div>
  {% if top_servers %}
    {% if top_servers|length >= 3 %}
    <div class="top3">
      {% for s in top_servers[:3] %}
      <div class="top-card {% if loop.index==1 %}gold-card{% endif %}">
        <div class="top-rank rank-{{ loop.index }}">#{{ loop.index }}</div>
        <div class="top-ava">{% if s.icon_url %}<img src="{{ s.icon_url }}" alt="{{ s.name }}">{% else %}<span style="font-size:28px">{{ s.emoji }}</span>{% endif %}</div>
        <div class="top-name">{{ s.name }}</div>
        <div class="top-cat">{{ s.category }}</div>
        <div class="top-bump">↑ {{ "{:,}".format(s.weekly_bumps or s.bump_count or 0) }}</div>
        <div style="margin-top:10px;display:flex;gap:6px">
          <button class="btn btn-xs btn-primary" onclick="doBump({{ s.id }}, this)">↑</button>
          <a href="{{ s.invite_url }}" target="_blank"><button class="btn btn-xs btn-secondary">{{ _('Влез','Join','Join') }}</button></a>
        </div>
      </div>
      {% endfor %}
    </div>
    {% endif %}
    <div class="sec-row"><span class="sec-title"><span class="sec-dot" style="background:var(--amber)"></span>{{ _('Пълна класация','Full Ranking','Vollständiges Ranking') }}</span></div>
    {% for s in top_servers[3:] %}
    <div class="scard">
      <div style="width:30px;font-size:15px;font-weight:700;color:var(--t2);flex-shrink:0;display:flex;align-items:center;justify-content:center">#{{ loop.index + 3 }}</div>
      <div class="sv-ava">{% if s.icon_url %}<img src="{{ s.icon_url }}" alt="{{ s.name }}">{% else %}{{ s.emoji }}{% endif %}</div>
      <div class="sv-body"><div class="sv-name-row"><span class="sv-name">{{ s.name }}</span>{% if s.vip %}<span class="bdg bdg-vip">VIP</span>{% endif %}</div><div class="sv-meta"><span class="sv-mi"><span class="live-dot"></span>{{ "{:,}".format(s.member_count or 0) }}</span><span class="sv-mi">↑ {{ "{:,}".format(s.weekly_bumps or s.bump_count or 0) }}</span><span class="sv-mi">★ {{ s.avg_rating }}</span></div></div>
      <div class="sv-right"><button class="btn btn-sm btn-primary" onclick="doBump({{ s.id }}, this)">↑</button><a href="{{ s.invite_url }}" target="_blank"><button class="btn btn-sm btn-secondary">{{ _('Влез','Join','Join') }}</button></a></div>
    </div>
    {% endfor %}
  {% else %}
    <div class="empty"><div class="empty-icon">📊</div><div>{{ _('Все още няма данни.','No data yet.','Noch keine Daten.') }}</div></div>
  {% endif %}

{# ════ DETAIL ════ #}
{% elif page == 'detail' %}
  {% if server.banner_url %}
  <img src="{{ server.banner_url }}" class="detail-banner" alt="{{ server.name }} banner">
  {% endif %}
  <div class="detail-header">
    <div class="detail-ava">{% if server.icon_url %}<img src="{{ server.icon_url }}" alt="{{ server.name }}">{% else %}{{ server.emoji }}{% endif %}</div>
    <div style="flex:1;min-width:0">
      <div class="detail-name">
        {{ server.name }}
        {% if server.featured %}<span class="bdg bdg-featured">⭐ FEATURED</span>{% endif %}
        {% if server.vip %}<span class="bdg bdg-vip">VIP</span>{% endif %}
        {% if server.verified %}<span class="bdg bdg-ver">✓ {{ _('Верифициран','Verified','Verifiziert') }}</span>{% endif %}
      </div>
      <div class="detail-meta">📂 {{ server.category }} &nbsp;·&nbsp; 👥 {{ "{:,}".format(server.member_count or 0) }} {% if server.online_count %}<span style="color:var(--green)">({{ server.online_count }} online)</span>{% endif %} &nbsp;·&nbsp; ↑ {{ "{:,}".format(server.bump_count or 0) }} &nbsp;·&nbsp; ★ {{ server.avg_rating }} ({{ server.reviews|length }})</div>
      <div class="detail-desc">{{ server.description }}</div>
      {% if server.long_desc %}<div style="font-size:12px;color:var(--t1);margin-top:8px;line-height:1.7">{{ server.long_desc }}</div>{% endif %}
      {% if server.tag_list %}<div class="sv-tags" style="margin-top:10px">{% for t in server.tag_list %}<span class="sv-tag">{{ t }}</span>{% endfor %}</div>{% endif %}
      <div class="detail-actions">
        <a href="{{ server.invite_url }}" target="_blank"><button class="btn btn-md btn-primary">{{ _('Присъедини се','Join Server','Beitreten') }} 🎮</button></a>
        <button class="btn btn-md btn-secondary" onclick="doBump({{ server.id }}, this)">↑ {{ _('Бъмп','Bump','Bump') }}</button>
        {% if server.website %}<a href="{{ server.website }}" target="_blank"><button class="btn btn-md btn-ghost">{{ _('Уебсайт','Website','Website') }} ↗</button></a>{% endif %}
        {% if cur and (cur.id == server.owner_id or cur.is_admin) %}
          <a href="/server/{{ server.id }}/edit"><button class="btn btn-md btn-amber">✏️ {{ _('Редактирай','Edit','Bearbeiten') }}</button></a>
          {% if cur.vip_active and cur.id == server.owner_id %}
            <button class="btn btn-md btn-green" onclick="openGiveaway({{ server.id }})">🎁 Giveaway</button>
            <button class="btn btn-md btn-ghost" onclick="syncMembers({{ server.id }}, this)">🔄 Sync</button>
          {% endif %}
        {% endif %}
        <button class="btn btn-md btn-danger" onclick="openReport({{ server.id }})">⚑ {{ _('Репорт','Report','Melden') }}</button>
        <a href="/"><button class="btn btn-md btn-ghost">← {{ _('Назад','Back','Zurück') }}</button></a>
      </div>
    </div>
  </div>

  {% if giveaways %}
  <div class="sec-row"><span class="sec-title"><span class="sec-dot" style="background:var(--green)"></span>🎁 Giveaways</span></div>
  {% for g in giveaways %}
  <div class="giveaway-card">
    <div class="giveaway-header"><span class="giveaway-badge">АКТИВЕН</span><span style="color:var(--t2);font-size:11px">{{ g.entries|length }} участника</span></div>
    <div class="giveaway-title">{{ g.title }}</div>
    <div class="giveaway-prize">🏆 {{ g.prize }}</div>
    <div class="giveaway-meta" style="margin-bottom:8px">{{ _('Завършва','Ends','Endet') }}: {{ g.ends_at.strftime('%d.%m.%Y %H:%M') }}</div>
    {% if cur %}
      {% if g.id in user_entry_ids %}
        <span class="btn btn-xs btn-done">✓ {{ _('Участваш','Entered','Teilgenommen') }}</span>
      {% else %}
        <button class="btn btn-xs btn-green" onclick="enterGiveaway({{ g.id }}, this)">{{ _('Участвай','Enter','Teilnehmen') }}</button>
      {% endif %}
    {% endif %}
    {% if cur and (cur.id == server.owner_id or cur.is_admin) %}
    <form method="POST" action="/giveaway/draw/{{ g.id }}" style="display:inline;margin-left:6px">
      <button type="submit" class="btn btn-xs btn-amber" onclick="return confirm('Теглене на победител?')">🎲 {{ _('Тегли','Draw','Ziehen') }}</button>
    </form>
    {% endif %}
  </div>
  {% endfor %}
  {% endif %}

  <div class="sec-row"><span class="sec-title"><span class="sec-dot" style="background:var(--amber)"></span>{{ _('Отзиви','Reviews','Bewertungen') }}</span></div>
  {% if cur %}
  <div class="form-card" style="margin-bottom:14px;padding:16px">
    <form method="POST" action="/review/{{ server.id }}">
      <div class="form-row2">
        <div class="form-group"><label class="form-label">{{ _('Оценка','Rating','Bewertung') }}</label>
          <select name="rating" class="form-select"><option value="5">★★★★★</option><option value="4">★★★★☆</option><option value="3">★★★☆☆</option><option value="2">★★☆☆☆</option><option value="1">★☆☆☆☆</option></select></div>
        <div class="form-group"><label class="form-label">{{ _('Коментар','Comment','Kommentar') }}</label><input name="comment" class="form-input" placeholder="{{ _('По желание...','Optional...','Optional...') }}"></div>
      </div>
      <button type="submit" class="btn btn-sm btn-primary">{{ _('Изпрати','Submit','Senden') }}</button>
    </form>
  </div>
  {% endif %}
  {% for r in reviews %}
  <div class="review-card">
    <div class="review-top"><span class="review-author">{{ r.author.username }}</span>{% if r.author.flag %}<span>{{ r.author.flag }}</span>{% endif %}<span class="review-stars">{{ '★' * r.rating }}{{ '☆' * (5 - r.rating) }}</span><span class="review-date">{{ r.created_at.strftime('%d.%m.%Y') }}</span></div>
    {% if r.comment %}<div class="review-comment">{{ r.comment }}</div>{% endif %}
  </div>
  {% else %}<div style="color:var(--t1);font-size:12px;padding:16px 0">{{ _('Все още няма отзиви.','No reviews yet.','Noch keine Bewertungen.') }}</div>{% endfor %}

  <div class="sec-row" style="margin-top:20px"><span class="sec-title"><span class="sec-dot" style="background:var(--t2)"></span>{{ _('Embed Widget','Embed Widget','Embed Widget') }}</span></div>
  <div class="widget-embed-box" onclick="copyWidget(this)" title="Кликни за копиране">
    &lt;iframe src="https://quboardix.eu/widget/{{ server.id }}" width="300" height="150" frameborder="0" style="border-radius:12px"&gt;&lt;/iframe&gt;
  </div>
  <div style="font-size:10px;color:var(--t2);margin-top:4px">{{ _('Кликни за копиране — постави в твоя сайт','Click to copy — paste on your site','Klicken zum Kopieren') }}</div>

{# ════ ADD SERVER ════ #}
{% elif page == 'add' %}
  {% if not cur %}
    <div class="empty"><div class="empty-icon">🔒</div><div style="margin-bottom:16px">{{ _('Трябва да влезеш в акаунта си.','You need to log in.','Du musst dich anmelden.') }}</div><a href="/login"><button class="btn btn-lg btn-primary">{{ _('Влез','Sign in','Anmelden') }}</button></a></div>
  {% else %}
  <div class="form-card">
    <div class="form-title">{{ _('Добави Discord сървър','Add Discord Server','Discord Server hinzufügen') }}</div>
    <p style="font-size:12px;color:var(--amber);margin-bottom:16px;padding:8px 12px;background:var(--amber2);border-radius:7px;border:1px solid var(--amber3)">⏳ {{ _('Сървърите изискват одобрение от администратор (до 24ч)','Servers require admin approval (up to 24h)','Server benötigen Admin-Genehmigung (bis zu 24h)') }}</p>
    <form method="POST" action="/add" enctype="multipart/form-data">
      <div class="form-row2">
        <div class="form-group"><label class="form-label">{{ _('Emoji / Икона','Emoji','Emoji') }}</label><input name="emoji" class="form-input" value="🎮" maxlength="2"></div>
        <div class="form-group"><label class="form-label">{{ _('Категория','Category','Kategorie') }}</label>
          <select name="category" class="form-select">{% for key,bg,en,de in categories %}{% if key!='all' %}<option value="{{ key }}">{{ bg if lang=='bg' else en if lang=='en' else de }}</option>{% endif %}{% endfor %}</select></div>
      </div>
      <div class="form-group"><label class="form-label">{{ _('Икона (снимка, по желание)','Icon image (optional)','Icon-Bild (optional)') }}</label>
        <div class="upload-area" onclick="this.querySelector('input').click()">
          <input type="file" name="icon" accept="image/*" onchange="previewImg(this,'icon-prev')">
          <img id="icon-prev" style="max-height:60px;border-radius:8px;display:none;margin:0 auto">
          <div id="icon-placeholder" style="color:var(--t2);font-size:12px">📷 {{ _('Избери икона','Choose icon','Icon wählen') }}</div>
        </div>
      </div>
      <div class="form-group"><label class="form-label">{{ _('Банер (по желание, 16:5)','Banner (optional, 16:5)','Banner (optional, 16:5)') }}</label>
        <div class="upload-area" onclick="this.querySelector('input').click()">
          <input type="file" name="banner" accept="image/*" onchange="previewImg(this,'banner-prev')">
          <img id="banner-prev" style="max-height:80px;width:100%;object-fit:cover;border-radius:8px;display:none">
          <div id="banner-placeholder" style="color:var(--t2);font-size:12px">🖼️ {{ _('Избери банер','Choose banner','Banner wählen') }}</div>
        </div>
      </div>
      <div class="form-group"><label class="form-label">{{ _('Име на сървъра','Server name','Servername') }}</label><input name="name" class="form-input" required></div>
      <div class="form-group"><label class="form-label">{{ _('Кратко описание','Short description','Kurzbeschreibung') }}</label><textarea name="description" class="form-textarea" style="min-height:70px" required></textarea></div>
      <div class="form-group"><label class="form-label">{{ _('Подробно описание (по желание)','Long description (optional)','Lange Beschreibung (optional)') }}</label><textarea name="long_desc" class="form-textarea"></textarea></div>
      <div class="form-row2">
        <div class="form-group"><label class="form-label">Discord Invite Link</label><input name="invite_url" class="form-input" placeholder="https://discord.gg/..." required></div>
        <div class="form-group"><label class="form-label">{{ _('Уебсайт (по желание)','Website (optional)','Website (optional)') }}</label><input name="website" class="form-input" placeholder="https://..."></div>
      </div>
      <div class="form-row2">
        <div class="form-group"><label class="form-label">{{ _('Тагове (с запетая)','Tags (comma)','Tags (Komma)') }}</label><input name="tags" class="form-input" placeholder="fps, pvp, chill"></div>
        <div class="form-group"><label class="form-label">Discord Guild ID <span style="color:var(--t2);font-weight:normal">(за автоматичен member count)</span></label><input name="discord_guild_id" class="form-input" placeholder="123456789012345678"></div>
      </div>
      <div class="form-group"><label class="form-label">{{ _('Тип сървър','Server type','Servertyp') }}</label>
        <div class="type-toggle">
          <label class="type-opt on" onclick="selType(this)">🌍 {{ _('Публичен','Public','Öffentlich') }}<input type="radio" name="server_type" value="public" checked style="display:none"></label>
          <label class="type-opt" onclick="selType(this)">🔒 {{ _('Частен','Private','Privat') }}<input type="radio" name="server_type" value="private" style="display:none"></label>
        </div>
      </div>
      <button type="submit" class="btn btn-lg btn-primary" style="width:100%;justify-content:center;margin-top:4px">{{ _('Добави за одобрение','Submit for approval','Zur Genehmigung einreichen') }} 🚀</button>
    </form>
  </div>
  {% endif %}

{# ════ EDIT SERVER ════ #}
{% elif page == 'edit_server' %}
  <div class="form-card">
    <div class="form-title">✏️ {{ _('Редактирай сървъра','Edit Server','Server bearbeiten') }}: {{ server.name }}</div>
    <form method="POST" action="/server/{{ server.id }}/edit" enctype="multipart/form-data">
      <div class="form-row2">
        <div class="form-group"><label class="form-label">Emoji</label><input name="emoji" class="form-input" value="{{ server.emoji }}" maxlength="2"></div>
        <div class="form-group"><label class="form-label">{{ _('Категория','Category','Kategorie') }}</label>
          <select name="category" class="form-select">{% for key,bg,en,de in categories %}{% if key!='all' %}<option value="{{ key }}" {% if server.category==key %}selected{% endif %}>{{ bg if lang=='bg' else en if lang=='en' else de }}</option>{% endif %}{% endfor %}</select></div>
      </div>
      <div class="form-group"><label class="form-label">{{ _('Нова икона (по желание)','New icon (optional)','Neues Icon (optional)') }}</label><input type="file" name="icon" class="form-input" accept="image/*"></div>
      <div class="form-group"><label class="form-label">{{ _('Нов банер (по желание)','New banner (optional)','Neues Banner (optional)') }}</label><input type="file" name="banner" class="form-input" accept="image/*"></div>
      <div class="form-group"><label class="form-label">{{ _('Описание','Description','Beschreibung') }}</label><textarea name="description" class="form-textarea" required>{{ server.description }}</textarea></div>
      <div class="form-group"><label class="form-label">{{ _('Подробно описание','Long description','Lange Beschreibung') }}</label><textarea name="long_desc" class="form-textarea">{{ server.long_desc }}</textarea></div>
      <div class="form-row2">
        <div class="form-group"><label class="form-label">{{ _('Уебсайт','Website','Website') }}</label><input name="website" class="form-input" value="{{ server.website or '' }}" placeholder="https://..."></div>
        <div class="form-group"><label class="form-label">Discord Guild ID</label><input name="discord_guild_id" class="form-input" value="{{ server.discord_guild_id or '' }}" placeholder="123456789..."></div>
      </div>
      <div class="form-group"><label class="form-label">{{ _('Тагове','Tags','Tags') }}</label><input name="tags" class="form-input" value="{{ server.tags or '' }}"></div>
      <div style="display:flex;gap:8px;margin-top:4px">
        <button type="submit" class="btn btn-lg btn-primary" style="flex:1;justify-content:center">💾 {{ _('Запази','Save','Speichern') }}</button>
        <a href="/server/{{ server.id }}"><button type="button" class="btn btn-lg btn-secondary">{{ _('Отказ','Cancel','Abbrechen') }}</button></a>
      </div>
    </form>
  </div>

{# ════ VIP ════ #}
{% elif page == 'vip' %}
  <div class="welcome-card"><div class="wc-left"><h2>⭐ VIP <em>{{ _('реклама','Advertising','Werbung') }}</em></h2><p>{{ _('Повече видимост, повече членове','More visibility, more members','Mehr Sichtbarkeit, mehr Mitglieder') }}</p></div><div class="owner-pill">PRO PLANS</div></div>
  <div class="plan-grid">
    <div class="plan-card">
      <div class="plan-name">{{ _('Безплатен','Free','Kostenlos') }}</div>
      <div class="plan-price">0 €<span>/{{ _('мес','mo','Mo') }}</span></div>
      <div class="plan-feats"><div class="pf on"><span class="pf-on-dot"></span>{{ _('Листинг','Listing','Listing') }}</div><div class="pf on"><span class="pf-on-dot"></span>{{ _('Бъмп на 2ч','Bump every 2h','Bump alle 2h') }}</div><div class="pf"><span class="pf-off-dot"></span>{{ _('Горна позиция','Top position','Spitzenposition') }}</div></div>
      <button class="btn btn-md btn-ghost" style="width:100%;justify-content:center;margin-top:8px">{{ _('Текущ','Current','Aktuell') }}</button>
    </div>
    <div class="plan-card featured">
      <div class="popular-bdg">{{ _('НАЙ-ПОПУЛЯРЕН','MOST POPULAR','AM BELIEBTESTEN') }}</div>
      <div class="plan-name">VIP</div>
      <div class="plan-price">9.99 €<span>/{{ _('мес','mo','Mo') }}</span></div>
      <div class="plan-feats"><div class="pf on"><span class="pf-on-dot"></span>{{ _('Горна позиция','Top position','Spitzenposition') }}</div><div class="pf on"><span class="pf-on-dot"></span>{{ _('Банер & Икона','Banner & Icon','Banner & Icon') }}</div><div class="pf on"><span class="pf-on-dot"></span>{{ _('Бъмп на 1ч','Bump every 1h','Bump alle 1h') }}</div><div class="pf on"><span class="pf-on-dot"></span>🎁 Giveaway</div></div>
      <a href="/pay/vip"><button class="btn btn-md btn-primary" style="width:100%;justify-content:center;margin-top:8px">PayPal →</button></a>
    </div>
    <div class="plan-card">
      <div class="plan-name">Pro</div>
      <div class="plan-price">24.99 €<span>/{{ _('мес','mo','Mo') }}</span></div>
      <div class="plan-feats"><div class="pf on"><span class="pf-on-dot"></span>{{ _('Всичко от VIP','Everything in VIP','Alles aus VIP') }}</div><div class="pf on"><span class="pf-on-dot"></span>{{ _('Пинната позиция #1','Pinned #1','Gepinnt #1') }}</div><div class="pf on"><span class="pf-on-dot"></span>{{ _('Бъмп на 30мин','Bump every 30min','Bump alle 30min') }}</div><div class="pf on"><span class="pf-on-dot"></span>⭐ Featured Slot</div></div>
      <a href="/pay/pro"><button class="btn btn-md btn-secondary" style="width:100%;justify-content:center;margin-top:8px">PayPal →</button></a>
    </div>
  </div>

{# ════ DASHBOARD ════ #}
{% elif page == 'dashboard' %}
  <div class="welcome-card">
    <div class="wc-left"><h2>{{ _('Моят','My','Mein') }} <em>{{ _('дашборд','Dashboard','Dashboard') }}</em></h2><p>{{ _('Статистики за твоите сървъри','Statistics for your servers','Statistiken für deine Server') }}</p></div>
    {% if cur.vip_active %}<div class="vip-pill">⭐ {{ cur.vip_plan | upper }}</div>{% else %}<a href="/vip"><button class="btn btn-md btn-amber">⭐ {{ _('Вземи VIP','Get VIP','VIP holen') }}</button></a>{% endif %}
  </div>
  <div class="stat-grid" style="grid-template-columns:repeat(3,1fr)">
    <div class="stat-card"><div class="sc-icon ic-purple"><svg viewBox="0 0 16 16" fill="currentColor"><circle cx="8" cy="5" r="3"/><path d="M2 14c0-3.3 2.7-5 6-5s6 1.7 6 5H2z"/></svg></div><div><div class="sc-val">{{ "{:,}".format(total_members) }}</div><div class="sc-lbl">{{ _('Членове','Members','Mitglieder') }}</div></div></div>
    <div class="stat-card"><div class="sc-icon ic-amber"><svg viewBox="0 0 16 16" fill="currentColor"><path d="M8 1l1.5 4.5H14L10.2 8l1.4 4.5L8 10.2 4.4 12.5 5.8 8 2 5.5h4.5z"/></svg></div><div><div class="sc-val">{{ "{:,}".format(total_bumps) }}</div><div class="sc-lbl">{{ _('Бъмпове','Bumps','Bumps') }}</div></div></div>
    <div class="stat-card"><div class="sc-icon ic-green"><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M2 11l4-4 3 3 5-6"/></svg></div><div><div class="sc-val">{{ "{:,}".format(total_clicks) }}</div><div class="sc-lbl">{{ _('Кликове','Clicks','Klicks') }}</div></div></div>
  </div>
  <div class="chart-card">
    <div class="chart-title">{{ _('Кликове — последните 7 дни','Clicks — last 7 days','Klicks — letzte 7 Tage') }}</div>
    <div class="bars">
      {% set mc = days | map(attribute='count') | max | default(1) %}
      {% for d in days %}
        {% set pct = ((d.count / mc) * 100) | int if mc > 0 else 4 %}
        <div class="bar-col"><div class="bar {% if loop.last %}today{% endif %}" style="height:{{ [pct,4]|max }}%"></div><div class="bar-lbl">{{ d.label }}</div></div>
      {% endfor %}
    </div>
  </div>
  <div class="sec-row"><span class="sec-title"><span class="sec-dot" style="background:var(--a)"></span>{{ _('Мои сървъри','My Servers','Meine Server') }}</span><a href="/add"><span class="sec-link">+ {{ _('Добави','Add','Hinzufügen') }}</span></a></div>
  {% for s in servers %}
  <div class="scard">
    <div class="sv-ava">{% if s.icon_url %}<img src="{{ s.icon_url }}" alt="{{ s.name }}">{% else %}{{ s.emoji }}{% endif %}</div>
    <div class="sv-body">
      <div class="sv-name-row">
        <span class="sv-name">{{ s.name }}</span>
        {% if s.vip %}<span class="bdg bdg-vip">VIP</span>{% endif %}
        {% if not s.approved %}<span class="bdg bdg-pending">⏳ {{ _('Чакащ','Pending','Ausstehend') }}</span>{% endif %}
      </div>
      <div class="sv-desc">{{ s.description }}</div>
      <div class="sv-meta"><span class="sv-mi">👥 {{ "{:,}".format(s.member_count or 0) }}</span><span class="sv-mi">↑ {{ s.bump_count or 0 }}</span><span class="sv-mi">👁 {{ s.click_count or 0 }}</span></div>
    </div>
    <div class="sv-right">
      <a href="/server/{{ s.id }}/edit"><button class="btn btn-xs btn-secondary">✏️</button></a>
      <a href="/server/{{ s.id }}"><button class="btn btn-sm btn-ghost">{{ _('Преглед','View','Ansehen') }}</button></a>
    </div>
  </div>
  {% else %}<div class="empty"><div class="empty-icon">📭</div><div><a href="/add" style="color:#7aaaff">{{ _('Добави първия си сървър!','Add your first server!','Füge deinen ersten Server hinzu!') }}</a></div></div>{% endfor %}

{# ════ PROFILE ════ #}
{% elif page == 'profile' %}
  <div class="profile-header">
    <div>{% if profile_user.avatar_url %}<div class="profile-ava"><img src="{{ profile_user.avatar_url }}" alt="{{ profile_user.username }}"></div>{% else %}<div class="profile-ava-init">{{ profile_user.username[:2].upper() }}</div>{% endif %}</div>
    <div style="flex:1;min-width:0">
      <div class="profile-name">{{ profile_user.username }}{% if profile_user.vip_active %} <span class="bdg bdg-vip">{{ profile_user.vip_plan | upper }}</span>{% endif %}{% if profile_user.is_admin %} <span class="bdg bdg-featured">ADMIN</span>{% endif %}</div>
      <div class="profile-meta"><span>{{ profile_user.flag }} {{ profile_user.location_str }}</span><span>·</span><span>{{ _('Член от','Since','Seit') }} {{ profile_user.created_at.strftime('%b %Y') }}</span>{% if profile_user.discord_id %}<span>·</span><span style="color:#5865F2">Discord</span>{% endif %}</div>
      {% if profile_user.bio %}<div class="profile-bio">{{ profile_user.bio }}</div>{% endif %}
      <div class="profile-actions">
        {% if cur and cur.id == profile_user.id %}
          <a href="/profile/edit"><button class="btn btn-sm btn-secondary">{{ _('Редактирай','Edit','Bearbeiten') }}</button></a>
          <a href="/referral"><button class="btn btn-sm btn-ghost">🎁 Реферали</button></a>
          <a href="/2fa/setup"><button class="btn btn-sm btn-ghost">🔒 2FA</button></a>
        {% endif %}
      </div>
    </div>
  </div>
  <div class="stat-grid" style="grid-template-columns:repeat(3,1fr)">
    <div class="stat-card"><div class="sc-icon ic-blue"><svg viewBox="0 0 16 16" fill="currentColor"><rect x="1" y="2" width="14" height="3.5" rx="1"/><rect x="1" y="7.5" width="14" height="3.5" rx="1"/></svg></div><div><div class="sc-val">{{ servers|length }}</div><div class="sc-lbl">{{ _('Сървъри','Servers','Server') }}</div></div></div>
    <div class="stat-card"><div class="sc-icon ic-amber"><svg viewBox="0 0 16 16" fill="currentColor"><path d="M8 1l1.5 4.5H14L10.2 8l1.4 4.5L8 10.2 4.4 12.5 5.8 8 2 5.5h4.5z"/></svg></div><div><div class="sc-val">{{ servers | sum(attribute='bump_count') }}</div><div class="sc-lbl">Bumps</div></div></div>
    <div class="stat-card"><div class="sc-icon ic-green"><svg viewBox="0 0 16 16" fill="currentColor"><circle cx="8" cy="8" r="6"/></svg></div><div><div class="sc-val">{{ ((now() - profile_user.created_at).days) }}</div><div class="sc-lbl">{{ _('Дни','Days','Tage') }}</div></div></div>
  </div>
  <div class="sec-row"><span class="sec-title"><span class="sec-dot" style="background:var(--a)"></span>{{ _('Сървъри','Servers','Server') }}</span></div>
  {% for s in servers %}<div class="scard"><div class="sv-ava">{% if s.icon_url %}<img src="{{ s.icon_url }}" alt="{{ s.name }}">{% else %}{{ s.emoji }}{% endif %}</div><div class="sv-body"><div class="sv-name-row"><span class="sv-name">{{ s.name }}</span>{% if s.vip %}<span class="bdg bdg-vip">VIP</span>{% endif %}</div><div class="sv-desc">{{ s.description }}</div><div class="sv-meta"><span class="sv-mi"><span class="live-dot"></span>{{ s.member_count or 0 }}</span><span class="sv-mi">↑ {{ s.bump_count or 0 }}</span></div></div><div class="sv-right"><a href="/server/{{ s.id }}"><button class="btn btn-sm btn-secondary">{{ _('Виж','View','Ansehen') }}</button></a></div></div>{% else %}<div class="empty"><div class="empty-icon">📭</div></div>{% endfor %}

{# ════ PROFILE EDIT ════ #}
{% elif page == 'profile_edit' %}
  <div class="form-card">
    <div class="form-title">{{ _('Редактирай профила','Edit Profile','Profil bearbeiten') }}</div>
    <form method="POST" action="/profile/edit">
      <div class="form-group"><label class="form-label">{{ _('Биография','Bio','Bio') }}</label><textarea name="bio" class="form-textarea" style="min-height:80px">{{ cur.bio or '' }}</textarea></div>
      <div class="form-group" style="display:flex;align-items:center;gap:10px">
        <input type="checkbox" name="email_notify" id="email_notify" {% if cur.email_notify %}checked{% endif %} style="width:16px;height:16px">
        <label for="email_notify" class="form-label" style="margin:0">{{ _('Email известия','Email notifications','E-Mail-Benachrichtigungen') }}</label>
      </div>
      <div class="form-group"><label class="form-label">{{ _('Тема','Theme','Thema') }}</label>
        <div class="type-toggle">
          <label class="type-opt {% if cur.theme == 'dark' %}on{% endif %}" onclick="selType(this)">🌙 Dark<input type="radio" name="theme" value="dark" {% if cur.theme == 'dark' %}checked{% endif %} style="display:none"></label>
          <label class="type-opt {% if cur.theme == 'light' %}on{% endif %}" onclick="selType(this)">☀️ Light<input type="radio" name="theme" value="light" {% if cur.theme == 'light' %}checked{% endif %} style="display:none"></label>
        </div>
      </div>
      <div style="display:flex;gap:8px;margin-top:4px">
        <button type="submit" class="btn btn-lg btn-primary" style="flex:1;justify-content:center">{{ _('Запази','Save','Speichern') }}</button>
      </div>
    </form>
    <div style="margin-top:20px;padding-top:16px;border-top:1px solid var(--b1)">
      <div class="form-label" style="margin-bottom:10px">🔒 2FA {{ _('Двустепенна верификация','Two-Factor Authentication','Zwei-Faktor-Authentifizierung') }}</div>
      {% if cur.totp_enabled %}
        <p style="font-size:12px;color:var(--green);margin-bottom:10px">✓ 2FA е активно</p>
        <form method="POST" action="/2fa/disable" style="display:flex;gap:8px">
          <input name="code" class="form-input" placeholder="6-цифрен код" maxlength="6" style="flex:1">
          <button type="submit" class="btn btn-md btn-danger">{{ _('Деактивирай','Disable','Deaktivieren') }}</button>
        </form>
      {% else %}
        <a href="/2fa/setup"><button class="btn btn-md btn-secondary">{{ _('Настрой 2FA','Setup 2FA','2FA einrichten') }}</button></a>
      {% endif %}
    </div>
  </div>

{# ════ 2FA SETUP ════ #}
{% elif page == 'totp_setup' %}
  <div class="auth-outer">
    <div class="auth-card">
      <div class="auth-title">🔒 {{ _('Настрой 2FA','Setup 2FA','2FA einrichten') }}</div>
      <div class="auth-sub">{{ _('Сканирай QR кода с Google/Authy Authenticator','Scan QR with Google/Authy Authenticator','QR mit Authenticator scannen') }}</div>
      <div class="totp-qr"><img src="data:image/png;base64,{{ qr_b64 }}" alt="QR Code"></div>
      <div class="totp-secret">{{ totp_secret }}</div>
      <p style="font-size:11px;color:var(--t2);text-align:center;margin:10px 0">{{ _('Или въведи кода ръчно','Or enter manually','Oder manuell eingeben') }}</p>
      <form method="POST" action="/2fa/setup">
        <div class="form-group"><label class="form-label">{{ _('Въведи 6-цифрен код','Enter 6-digit code','6-stelligen Code eingeben') }}</label><input name="code" class="form-input" maxlength="6" placeholder="123456" required autocomplete="off"></div>
        <button type="submit" class="btn btn-lg btn-primary" style="width:100%;justify-content:center">{{ _('Активирай','Activate','Aktivieren') }}</button>
      </form>
    </div>
  </div>

{# ════ 2FA VERIFY ════ #}
{% elif page == 'totp_verify' %}
  <div class="auth-outer">
    <div class="auth-card">
      <div class="auth-title">🔐 {{ _('Двустепенна верификация','Two-Factor Auth','Zwei-Faktor-Auth') }}</div>
      <div class="auth-sub">{{ _('Въведи кода от Authenticator приложението','Enter code from Authenticator app','Code aus der Authenticator-App eingeben') }}</div>
      <form method="POST" action="/2fa/verify">
        <div class="form-group"><label class="form-label">{{ _('Код','Code','Code') }}</label><input name="code" class="form-input" maxlength="6" placeholder="123456" required autocomplete="off" autofocus style="font-size:22px;letter-spacing:6px;text-align:center"></div>
        <button type="submit" class="btn btn-lg btn-primary" style="width:100%;justify-content:center">{{ _('Потвърди','Verify','Bestätigen') }}</button>
      </form>
    </div>
  </div>

{# ════ REFERRAL ════ #}
{% elif page == 'referral' %}
  <div class="welcome-card"><div class="wc-left"><h2>🎁 {{ _('Реферална','Referral','Referral') }} <em>{{ _('програма','Program','Programm') }}</em></h2><p>{{ _('Покани приятел и получи 7 VIP дни!','Invite a friend and get 7 VIP days!','Lade einen Freund ein und erhalte 7 VIP-Tage!') }}</p></div></div>
  <div class="ref-card">
    <div style="font-size:11px;color:var(--t1);margin-bottom:6px">{{ _('Твоят реферален код','Your referral code','Dein Referral-Code') }}</div>
    <div class="ref-code">{{ cur.referral_code }}</div>
    <div class="ref-link">https://quboardix.eu/ref/{{ cur.referral_code }}</div>
    <button class="btn btn-sm btn-primary" style="margin-top:10px" onclick="copyRef()">{{ _('Копирай линка','Copy link','Link kopieren') }}</button>
    <p style="font-size:11px;color:var(--t1);margin-top:12px">{{ _('За всеки поканен приятел: +7 VIP дни за теб, -25% за новия потребител','Per invited friend: +7 VIP days for you','Pro eingeladenen Freund: +7 VIP-Tage für dich') }}</p>
  </div>
  <div class="sec-row"><span class="sec-title"><span class="sec-dot" style="background:var(--green)"></span>{{ _('Покани от теб','Your referrals','Deine Referrals') }} ({{ referrals|length }})</span></div>
  {% for u in referrals %}
  <div class="scard"><div class="sv-ava-init" style="width:44px;height:44px;border-radius:10px;background:var(--ag2);display:flex;align-items:center;justify-content:center;font-weight:700;color:var(--a)">{{ u.username[:2].upper() }}</div><div class="sv-body"><div class="sv-name-row"><span class="sv-name">{{ u.username }}</span>{% if u.vip_active %}<span class="bdg bdg-vip">VIP</span>{% endif %}</div><div class="sv-meta"><span class="sv-mi">{{ u.flag }} {{ u.country }}</span><span class="sv-mi">{{ u.created_at.strftime('%d.%m.%Y') }}</span></div></div></div>
  {% else %}<div class="empty"><div class="empty-icon">👥</div><div>{{ _('Все още няма реферали.','No referrals yet.','Noch keine Referrals.') }}</div></div>{% endfor %}

{# ════ BLOG LIST ════ #}
{% elif page == 'blog_list' %}
  <div class="welcome-card"><div class="wc-left"><h2>📰 <em>Blog</em></h2><p>{{ _('Новини и обяви от quboardix.eu','News and announcements from quboardix.eu','Neuigkeiten von quboardix.eu') }}</p></div></div>
  {% for post in posts %}
  <a href="/blog/{{ post.slug }}">
    <div class="blog-card">
      <div class="blog-title">{{ post.title }}</div>
      {% if post.summary %}<div class="blog-summary">{{ post.summary }}</div>{% endif %}
      <div class="blog-meta"><span>✍️ {{ post.author.username }}</span><span>📅 {{ post.created_at.strftime('%d.%m.%Y') }}</span></div>
    </div>
  </a>
  {% else %}<div class="empty"><div class="empty-icon">📭</div><div>{{ _('Няма публикации.','No posts yet.','Noch keine Beiträge.') }}</div></div>{% endfor %}

{# ════ BLOG POST ════ #}
{% elif page == 'blog_post' %}
  <div style="margin-bottom:10px"><a href="/blog"><button class="btn btn-sm btn-ghost">← {{ _('Назад','Back','Zurück') }}</button></a></div>
  <div class="form-card">
    <h1 style="font-size:20px;font-weight:700;letter-spacing:-.4px;margin-bottom:8px">{{ post.title }}</h1>
    <div style="font-size:12px;color:var(--t2);margin-bottom:20px;display:flex;gap:12px"><span>✍️ {{ post.author.username }}</span><span>📅 {{ post.created_at.strftime('%d.%m.%Y') }}</span></div>
    <div class="blog-body">{{ post.body }}</div>
  </div>

{# ════ NOTIFICATIONS ════ #}
{% elif page == 'notifications' %}
  <div class="welcome-card"><div class="wc-left"><h2>{{ _('Известия','Notifications','Benachrichtigungen') }}</h2><p>{{ notifications|length }} {{ _('известия','notifications','Benachrichtigungen') }}</p></div></div>
  {% for n in notifications %}
  <div class="notif-item"><span class="notif-dot {{ n.type }}"></span><div><div class="notif-title">{{ n.title }}</div>{% if n.body %}<div class="notif-body">{{ n.body }}</div>{% endif %}<div class="notif-time">{{ n.created_at.strftime('%d.%m.%Y %H:%M') }}</div></div></div>
  {% else %}<div class="empty"><div class="empty-icon">🔔</div><div>{{ _('Няма известия.','No notifications.','Keine Benachrichtigungen.') }}</div></div>{% endfor %}

{# ════ LOGIN ════ #}
{% elif page == 'login' %}
  <div class="auth-outer">
    <div class="auth-card">
      <div class="auth-logo"><svg width="26" height="26" viewBox="0 0 28 28" fill="none"><rect width="28" height="28" rx="7" fill="#08091a"/><rect x="4" y="4" width="8" height="8" rx="2.2" fill="#4a7bff"/><rect x="16" y="4" width="8" height="8" rx="2.2" fill="#4a7bff" opacity=".35"/><rect x="4" y="16" width="8" height="8" rx="2.2" fill="#7b6dff" opacity=".5"/><rect x="16" y="16" width="8" height="8" rx="2.2" fill="#4a7bff" opacity=".82"/></svg><span class="auth-logo-name">qboard<em>ix</em></span></div>
      <div class="auth-title">{{ _('Добре дошъл 👋','Welcome back 👋','Willkommen 👋') }}</div>
      <div class="auth-sub">{{ _('Влез в акаунта си','Sign in to your account','Melde dich an')
