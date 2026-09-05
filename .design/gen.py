import base64, pathlib, html

thumbs = {}
for p in sorted(pathlib.Path(".design/thumbs").glob("*.jpg")):
    thumbs[p.stem] = "data:image/jpeg;base64," + base64.b64encode(p.read_bytes()).decode()

WALLS = [
    ("bisbiswas-a-summer-evening", "bisbiswas-a-summer-evening.png", "1.8 MB · 2560×1440", True),
    ("amber", "amber.jpg", "3.0 MB · 3840×2160", False),
    ("Flux.1_Dev_00007_", "Flux.1_Dev_00007_.png", "3.0 MB · 1024×1024", False),
    ("goku-perfected-5120x2880-25454", "goku-perfected-5120x2880-25454.jpg", "6.3 MB · 5120×2880", False),
]

def tiles(prefix, cls=""):
    out = []
    for key, name, meta, active in WALLS:
        sel = " is-active" if active else ""
        out.append(f'''
        <button class="tile{sel} {cls}" data-name="{html.escape(name)}">
          <img src="{thumbs[key]}" alt="">
          <span class="tile-check">✓</span>
          <span class="tile-meta"><b>{html.escape(name)}</b><i>{meta}</i></span>
        </button>''')
    return "".join(out)

PAGE = f"""<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>rashell · Wallpaper Picker — три варианта дизайна</title>
<style>
:root {{
  --bg:#08070a; --surface:#0f0d12; --raised:#1c171e;
  --accent:#c43b52; --accent-muted:#b56371;
  --text:#e6ded0; --muted:#b3aa9b; --disabled:#7f776b;
  --on-accent:#fff5e9; --border:#393238; --border-i:#766d70;
  --danger:#ed536b;
  --radius:8px; --mono:"FiraCode Nerd Font","Fira Code",ui-monospace,"JetBrains Mono",Menlo,monospace;
}}
*{{box-sizing:border-box;margin:0;padding:0}}
body{{background:var(--bg);color:var(--text);font-family:var(--mono);font-size:14px;line-height:1.6;
  padding:48px 32px 96px;-webkit-font-smoothing:antialiased}}
.wrap{{max-width:1180px;margin:0 auto}}

h1{{font-size:26px;font-weight:700;letter-spacing:.5px;margin-bottom:8px}}
h1 .dim{{color:var(--muted);font-weight:400}}
.lede{{color:var(--muted);max-width:760px;margin-bottom:14px}}
.lede code{{color:var(--accent-muted)}}

.callout{{border-left:3px solid var(--accent);background:var(--surface);padding:14px 18px;
  border-radius:0 var(--radius) var(--radius) 0;margin:24px 0 40px;max-width:860px}}
.callout b{{color:var(--accent)}}
.callout p+p{{margin-top:8px}}

.sec-label{{font-size:11px;font-weight:700;letter-spacing:1.4px;color:var(--accent);
  text-transform:uppercase;margin-bottom:10px}}

.opt{{margin-bottom:56px;border:1px solid var(--border);border-radius:var(--radius);
  background:var(--surface);overflow:hidden}}
.opt-head{{padding:20px 24px;border-bottom:1px solid var(--border);display:flex;
  align-items:flex-start;gap:16px;flex-wrap:wrap}}
.opt-num{{width:34px;height:34px;flex:0 0 34px;border-radius:var(--radius);background:var(--accent);
  color:var(--on-accent);display:grid;place-items:center;font-weight:700;font-size:15px}}
.opt-title{{flex:1;min-width:260px}}
.opt-title h2{{font-size:17px;font-weight:700;letter-spacing:.3px}}
.opt-title p{{color:var(--muted);font-size:13px;margin-top:3px}}
.tags{{display:flex;gap:6px;flex-wrap:wrap}}
.tag{{font-size:10.5px;letter-spacing:.6px;padding:3px 9px;border-radius:20px;
  border:1px solid var(--border-i);color:var(--muted);text-transform:uppercase;white-space:nowrap}}
.tag.good{{border-color:var(--accent);color:var(--accent)}}
.tag.warn{{border-color:var(--disabled);color:var(--disabled)}}

.stage{{padding:32px 24px;background:
  linear-gradient(160deg,rgba(196,59,82,.07),transparent 60%),
  repeating-linear-gradient(45deg,#0a090c 0 12px,#0c0b0f 12px 24px);
  display:flex;justify-content:center}}

/* ── общие элементы шелла ───────────────── */
.bar{{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);
  height:34px;display:flex;align-items:center;gap:14px;padding:0 12px;font-size:12px;color:var(--muted)}}
.bar .act{{color:var(--accent)}}
.panel{{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);padding:16px}}
.p-head{{display:flex;align-items:center;gap:8px;padding-bottom:12px;
  border-bottom:1px solid var(--border);margin-bottom:14px}}
.p-mark{{width:3px;height:18px;background:var(--accent);border-radius:1px}}
.p-title{{font-size:15px;font-weight:700;letter-spacing:1px}}
.p-x{{margin-left:auto;width:30px;height:30px;border:1px solid var(--border-i);border-radius:var(--radius);
  display:grid;place-items:center;color:var(--muted);font-size:15px}}

.btn{{height:30px;padding:0 14px;border:1px solid var(--border-i);border-radius:var(--radius);
  background:transparent;color:var(--text);font-family:var(--mono);font-size:13px;
  display:inline-flex;align-items:center;gap:7px;cursor:pointer;transition:.14s}}
.btn:hover{{background:var(--raised)}}
.btn.pri{{background:var(--accent);border-color:var(--accent);color:var(--on-accent);font-weight:700}}
.btn.sel{{border-color:var(--accent);color:var(--accent);font-weight:700}}
.btn.gho{{color:var(--muted)}}

.field{{height:30px;flex:1;background:var(--raised);border:1px solid var(--border-i);
  border-radius:var(--radius);display:flex;align-items:center;padding:0 10px;
  color:var(--muted);font-size:11.5px;overflow:hidden;white-space:nowrap}}

/* ── плитки обоев ───────────────────────── */
.grid{{display:grid;gap:10px}}
.tile{{position:relative;border:1px solid var(--border);border-radius:var(--radius);
  overflow:hidden;background:var(--raised);cursor:pointer;padding:0;
  aspect-ratio:16/9;transition:.16s;display:block;width:100%}}
.tile img{{width:100%;height:100%;object-fit:cover;display:block;transition:.16s}}
.tile:hover{{border-color:var(--border-i);transform:translateY(-2px)}}
.tile:hover img{{transform:scale(1.04)}}
.tile.is-active{{border-color:var(--accent);border-width:2px}}
.tile-check{{position:absolute;top:6px;right:6px;width:20px;height:20px;border-radius:50%;
  background:var(--accent);color:var(--on-accent);display:none;place-items:center;font-size:11px;font-weight:700}}
.tile.is-active .tile-check{{display:grid}}
.tile-meta{{position:absolute;left:0;right:0;bottom:0;padding:14px 8px 6px;text-align:left;
  background:linear-gradient(transparent,rgba(8,7,10,.94));display:flex;flex-direction:column}}
.tile-meta b{{font-size:10.5px;font-weight:600;color:var(--text);overflow:hidden;
  text-overflow:ellipsis;white-space:nowrap}}
.tile-meta i{{font-size:9.5px;font-style:normal;color:var(--disabled)}}

/* ── вариант A ──────────────────────────── */
.mock-a{{width:460px}}
.mock-a .grid{{grid-template-columns:repeat(2,1fr)}}
.scrollbox{{max-height:230px;overflow-y:auto;padding-right:4px;margin:0 -2px;padding-left:2px}}
.scrollbox::-webkit-scrollbar{{width:5px}}
.scrollbox::-webkit-scrollbar-thumb{{background:var(--border-i);border-radius:3px}}
.rowline{{display:flex;gap:8px;align-items:center;margin-top:14px}}
.hint{{font-size:11px;color:var(--disabled);margin-top:10px}}

/* ── вариант B ──────────────────────────── */
.mock-b{{width:100%;max-width:820px}}
.screen{{background:#000;border:1px solid var(--border);border-radius:10px;overflow:hidden;
  position:relative;aspect-ratio:16/10}}
.screen-bg{{position:absolute;inset:0;background-size:cover;background-position:center;filter:brightness(.5)}}
.screen-dim{{position:absolute;inset:0;background:rgba(8,7,10,.55);backdrop-filter:blur(2px)}}
.b-card{{position:absolute;inset:7% 5%;background:rgba(15,13,18,.93);border:1px solid var(--border);
  border-radius:10px;padding:18px;display:flex;flex-direction:column;gap:14px}}
.b-top{{display:flex;align-items:center;gap:12px}}
.b-top h3{{font-size:17px;font-weight:600}}
.search{{flex:1;height:32px;background:var(--raised);border:1px solid var(--border-i);
  border-radius:var(--radius);display:flex;align-items:center;gap:8px;padding:0 12px;
  color:var(--disabled);font-size:12.5px}}
.search .cur{{width:1.5px;height:14px;background:var(--accent);animation:bl 1.1s steps(2) infinite}}
@keyframes bl{{50%{{opacity:0}}}}
.mock-b .grid{{grid-template-columns:repeat(4,1fr);flex:1;align-content:start}}
.mock-b .tile.is-active{{outline:2px solid var(--accent);outline-offset:2px}}
.b-foot{{display:flex;align-items:center;gap:14px;font-size:11px;color:var(--disabled);
  border-top:1px solid var(--border);padding-top:12px}}
.kbd{{border:1px solid var(--border-i);border-radius:4px;padding:1px 6px;font-size:10px;color:var(--muted)}}

/* ── вариант C ──────────────────────────── */
.mock-c{{width:100%;max-width:760px;display:flex;flex-direction:column;gap:12px}}
.c-live{{position:relative;border:1px solid var(--border);border-radius:10px;overflow:hidden;
  aspect-ratio:21/9;background-size:cover;background-position:center}}
.c-live .barov{{position:absolute;left:10px;right:10px;top:10px;height:28px;
  background:rgba(15,13,18,.82);border:1px solid var(--border);border-radius:6px;
  display:flex;align-items:center;gap:12px;padding:0 10px;font-size:10.5px;color:var(--muted);
  backdrop-filter:blur(8px)}}
.c-badge{{position:absolute;bottom:10px;left:10px;background:rgba(8,7,10,.85);border:1px solid var(--accent);
  color:var(--accent);border-radius:20px;padding:4px 12px;font-size:10.5px;font-weight:700;letter-spacing:.6px}}
.filmstrip{{display:flex;gap:8px;overflow-x:auto;padding:4px 2px 8px}}
.filmstrip::-webkit-scrollbar{{height:5px}}
.filmstrip::-webkit-scrollbar-thumb{{background:var(--border-i);border-radius:3px}}
.filmstrip .tile{{flex:0 0 148px}}
.c-bar{{display:flex;gap:8px;align-items:center}}

/* ── таблица сравнения ──────────────────── */
table{{width:100%;border-collapse:collapse;font-size:12.5px;
  border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}}
th,td{{padding:11px 14px;text-align:left;border-bottom:1px solid var(--border);vertical-align:top}}
th{{background:var(--raised);font-size:10.5px;letter-spacing:1px;text-transform:uppercase;color:var(--accent)}}
td:first-child{{color:var(--muted);white-space:nowrap}}
tr:last-child td{{border-bottom:0}}
.yes{{color:var(--accent)}} .no{{color:var(--disabled)}}

.rec{{border:1px solid var(--accent);border-radius:var(--radius);padding:20px 24px;
  background:linear-gradient(135deg,rgba(196,59,82,.1),transparent);margin-top:36px}}
.rec h3{{font-size:15px;margin-bottom:10px;color:var(--accent);letter-spacing:.5px}}
.rec ol{{margin:12px 0 0 20px;color:var(--muted)}}
.rec li{{margin-bottom:5px}}
.rec b{{color:var(--text)}}
.files{{margin-top:14px;font-size:11.5px;color:var(--disabled);line-height:1.9}}
.files code{{color:var(--accent-muted);background:var(--raised);padding:1px 6px;border-radius:4px}}
h2.big{{font-size:18px;margin:44px 0 16px;letter-spacing:.4px}}
</style>
</head>
<body>
<div class="wrap">

  <h1>Wallpaper Picker <span class="dim">— три варианта для rashell</span></h1>
  <p class="lede">Палитра <code>nevermore</code>, шрифт FiraCode Nerd Font, отступы и радиусы взяты из
  <code>core/Theme.qml</code>. Превью — твои реальные файлы из <code>~/Pictures/Wallpapers</code>.</p>

  <div class="callout">
    <p><b>Сначала важное:</b> picker в rashell уже есть — <code>modules/system/ControlPanel.qml:41</code>
    открывает нативный <code>FileDialog</code>, а <code>ConfigStore.setWallpaper()</code> уже пишет
    путь в конфиг, и <code>overlays/Wallpaper.qml</code> реагирует на него автоматически.</p>
    <p>То есть строить механизм смены обоев не нужно — он рабочий. Проблема в <b>UI</b>: нативный
    диалог выпадает из эстетики шелла, не показывает превью сеткой и заставляет каждый раз
    ходить по файловой системе. Все три варианта ниже — про замену этого диалога.</p>
  </div>

  <!-- ВАРИАНТ A -->
  <section class="opt">
    <div class="opt-head">
      <div class="opt-num">A</div>
      <div class="opt-title">
        <h2>Popup-панель у кнопки в баре</h2>
        <p>Тот же слот, что у Bluetooth, Weather и Calendar: <code>PanelCoordinator.toggleRegistered()</code>
        + <code>PopupWindow</code>, привязанный к иконке.</p>
      </div>
      <div class="tags">
        <span class="tag good">минимум кода</span>
        <span class="tag good">паттерн уже есть</span>
        <span class="tag warn">мелкие превью</span>
      </div>
    </div>
    <div class="stage">
      <div class="mock-a">
        <div class="bar" style="margin-bottom:8px">
          <span>󰍹 1 2 3</span><span style="margin-left:auto"></span>
          <span>󰃭 09:21</span><span class="act">󰸉</span><span>󰂯</span><span>󰕾</span>
        </div>
        <div class="panel">
          <div class="p-head"><div class="p-mark"></div><div class="p-title">WALLPAPER</div><div class="p-x">×</div></div>
          <div class="scrollbox"><div class="grid">{tiles("a")}</div></div>
          <div class="rowline">
            <div class="field">~/Pictures/Wallpapers</div>
            <button class="btn">Папка…</button>
          </div>
          <p class="hint">Клик по плитке применяет обои сразу — без кнопки «Применить».</p>
        </div>
      </div>
    </div>
  </section>

  <!-- ВАРИАНТ B -->
  <section class="opt">
    <div class="opt-head">
      <div class="opt-num">B</div>
      <div class="opt-title">
        <h2>Полноэкранный оверлей с поиском</h2>
        <p>Слот Launcher: <code>PanelWindow</code> + <code>WlrLayer.Overlay</code> +
        <code>keyboardFocus: Exclusive</code>. Вызов по IPC-биндингу из Hyprland.</p>
      </div>
      <div class="tags">
        <span class="tag good">крупные превью</span>
        <span class="tag good">клавиатура</span>
        <span class="tag warn">больше кода</span>
      </div>
    </div>
    <div class="stage">
      <div class="mock-b">
        <div class="screen">
          <div class="screen-bg" style="background-image:url('{thumbs["bisbiswas-a-summer-evening"]}')"></div>
          <div class="screen-dim"></div>
          <div class="b-card">
            <div class="b-top">
              <h3>Wallpaper</h3>
              <div class="search">󰍉 <span>sum</span><span class="cur"></span></div>
              <span style="font-size:11px;color:var(--disabled)">4 файла</span>
            </div>
            <div class="grid">{tiles("b")}</div>
            <div class="b-foot">
              <span><span class="kbd">↑↓←→</span> навигация</span>
              <span><span class="kbd">Enter</span> применить</span>
              <span><span class="kbd">Esc</span> закрыть</span>
              <span style="margin-left:auto">живое превью на фоне</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- ВАРИАНТ C -->
  <section class="opt">
    <div class="opt-head">
      <div class="opt-num">C</div>
      <div class="opt-title">
        <h2>Лента с живым превью</h2>
        <p>Широкая панель: сверху — как обои выглядят под реальным баром, снизу —
        горизонтальная лента-филмстрип. Наведение меняет превью, клик фиксирует.</p>
      </div>
      <div class="tags">
        <span class="tag good">видно результат</span>
        <span class="tag warn">широкая панель</span>
        <span class="tag warn">риск моргания</span>
      </div>
    </div>
    <div class="stage">
      <div class="mock-c">
        <div class="c-live" style="background-image:url('{thumbs["amber"]}')">
          <div class="barov">
            <span>󰍹 1 2 3</span><span style="margin-left:auto"></span>
            <span>󰃭 09:21</span><span style="color:var(--accent)">󰸉</span><span>󰕾</span>
          </div>
          <div class="c-badge">ПРЕВЬЮ · amber.jpg</div>
        </div>
        <div class="filmstrip">{tiles("c")}</div>
        <div class="c-bar">
          <div class="field">~/Pictures/Wallpapers/amber.jpg</div>
          <button class="btn gho">Папка…</button>
          <button class="btn pri">Применить</button>
        </div>
      </div>
    </div>
  </section>

  <h2 class="big">Сравнение</h2>
  <table>
    <tr><th>Критерий</th><th>A · Popup</th><th>B · Оверлей</th><th>C · Лента</th></tr>
    <tr><td>Размер превью</td><td class="no">~200×112</td><td class="yes">~380×214</td><td class="yes">крупное + лента</td></tr>
    <tr><td>Новых файлов QML</td><td class="yes">2</td><td class="no">2 + IPC + бинд</td><td class="no">2, много логики</td></tr>
    <tr><td>Поиск по имени</td><td class="no">тесно</td><td class="yes">есть</td><td class="no">нет места</td></tr>
    <tr><td>Клавиатура</td><td class="no">только Esc</td><td class="yes">полная</td><td class="no">только Esc</td></tr>
    <tr><td>Виден результат до применения</td><td class="no">нет</td><td class="yes">фон оверлея</td><td class="yes">главная идея</td></tr>
    <tr><td>Вписан в паттерны rashell</td><td class="yes">точь-в-точь</td><td class="yes">как Launcher</td><td class="no">новый паттерн</td></tr>
    <tr><td>Много обоев (50+)</td><td class="no">скролл мелких</td><td class="yes">поиск спасает</td><td class="no">лента длинная</td></tr>
  </table>

  <div class="rec">
    <h3>Рекомендация: A сейчас, B потом</h3>
    <p style="color:var(--muted)">У тебя <b>4 файла обоев</b>. Поиск и клавиатурная навигация из
    варианта B решают проблему, которой пока нет — это преждевременная сложность. Вариант A
    переиспользует существующий паттерн панелей целиком: новых концепций ноль, кода минимум,
    нативный <code>FileDialog</code> остаётся под кнопкой «Папка…» как запасной путь к файлам вне
    каталога. Когда обоев станет несколько десятков — та же <code>WallpaperState</code>
    переносится в оверлей B без переписывания.</p>
    <p style="color:var(--muted);margin-top:10px">Вариант C выглядит эффектнее всех, но живое
    превью на весь экран означает перерисовку фонового <code>Image</code> на каждый hover —
    на файлах по 6 МБ (goku, 5120×2880) это заметные подтормаживания. Идею стоит взять частично:
    показывать в A имя и разрешение выбранного файла.</p>
    <ol>
      <li><b>modules/wallpaper/WallpaperState.qml</b> — <code>Process</code> со сканом каталога, список файлов, <code>setWallpaper()</code></li>
      <li><b>modules/wallpaper/WallpaperPanel.qml</b> — <code>PanelFrame</code> + <code>GridView</code> плиток</li>
      <li><b>modules/wallpaper/qmldir</b> — регистрация модуля</li>
      <li>Кнопка «Wallpaper» в <code>ControlPanel.qml:301</code> открывает панель вместо <code>FileDialog</code></li>
    </ol>
    <div class="files">
      Не потребуется трогать: <code>overlays/Wallpaper.qml</code> (уже реагирует на конфиг),
      <code>ConfigStore.setWallpaper()</code> (уже есть), <code>validate()</code> (новых полей в
      конфиге нет — каталог обоев берётся из пути текущих обоев).
    </div>
  </div>

</div>
<script>
document.querySelectorAll('.stage').forEach(stage => {{
  stage.addEventListener('click', e => {{
    const tile = e.target.closest('.tile');
    if (!tile) return;
    const scope = tile.closest('.mock-a, .mock-b, .mock-c');
    scope.querySelectorAll('.tile').forEach(t => t.classList.remove('is-active'));
    tile.classList.add('is-active');
    const live = scope.querySelector('.c-live');
    if (live) {{
      live.style.backgroundImage = `url('${{tile.querySelector('img').src}}')`;
      live.querySelector('.c-badge').textContent = 'ПРЕВЬЮ · ' + tile.dataset.name;
      scope.querySelector('.field').textContent = '~/Pictures/Wallpapers/' + tile.dataset.name;
    }}
  }});
}});
</script>
</body>
</html>
"""

pathlib.Path("index.html").write_text(PAGE, encoding="utf-8")
print("written", len(PAGE), "bytes")
