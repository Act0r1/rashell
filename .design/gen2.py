import base64, pathlib

def b64(p):
    return "data:image/jpeg;base64," + base64.b64encode(pathlib.Path(p).read_bytes()).decode()

BIG = {p.stem: b64(p) for p in pathlib.Path(".design/big").glob("*.jpg")}

W = [
    dict(key="bisbiswas-a-summer-evening", name="bisbiswas-a-summer-evening.png",
         dim="3840×2160", size="1.8 MB", pal=["#28050D","#5C1121","#AC3238","#BB9F60","#94B68F"], accent="#AC3238"),
    dict(key="amber", name="amber.jpg",
         dim="2560×1440", size="3.0 MB", pal=["#1F1D19","#5A4530","#986A34","#BE9653","#C3B39A"], accent="#BE9653"),
    dict(key="Flux.1_Dev_00007_", name="Flux.1_Dev_00007_.png",
         dim="2560×1440", size="3.0 MB", pal=["#0F1225","#2E2F4A","#563352","#563E61","#AB698F"], accent="#AB698F"),
    dict(key="goku-perfected-5120x2880-25454", name="goku-perfected-5120x2880-25454.jpg",
         dim="5120×2880", size="6.3 MB", pal=["#080A0D","#374956","#3E505E","#5C7488","#95A6B4"], accent="#5C7488"),
]
import json
DATA = json.dumps([{**w, "img": BIG[w["key"]]} for w in W])

PAGE = """<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>rashell · Wallpaper — клавиатурный picker</title>
<style>
:root{
  --bg:#08070a; --surface:#0f0d12; --raised:#1c171e;
  --accent:#c43b52; --text:#e6ded0; --muted:#b3aa9b; --dis:#7f776b;
  --on-accent:#fff5e9; --border:#393238; --border-i:#766d70;
  --mono:"FiraCode Nerd Font","Fira Code",ui-monospace,"JetBrains Mono",Menlo,monospace;
  --live:#c43b52;
}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:var(--mono);font-size:14px;
  line-height:1.6;padding:44px 28px 110px;-webkit-font-smoothing:antialiased}
.wrap{max-width:1120px;margin:0 auto}
h1{font-size:25px;font-weight:700;letter-spacing:.4px;margin-bottom:8px}
h1 .d{color:var(--muted);font-weight:400}
.lede{color:var(--muted);max-width:780px}
.lede code{color:var(--accent)}
.note{border-left:3px solid var(--accent);background:var(--surface);padding:13px 18px;
  border-radius:0 8px 8px 0;margin:22px 0 44px;max-width:880px;color:var(--muted)}
.note b{color:var(--accent)}

.opt{margin-bottom:60px}
.oh{display:flex;align-items:baseline;gap:14px;margin-bottom:6px;flex-wrap:wrap}
.on{width:32px;height:32px;flex:0 0 32px;border-radius:8px;background:var(--accent);
  color:var(--on-accent);display:grid;place-items:center;font-weight:700;font-size:14px}
.oh h2{font-size:18px;font-weight:700;letter-spacing:.3px}
.oh .sub{color:var(--dis);font-size:12px}
.od{color:var(--muted);max-width:820px;margin:0 0 18px 46px;font-size:13px}
.od code{color:var(--accent)}

.stage{border:1px solid var(--border);border-radius:10px;overflow:hidden;background:#000}
.frame{position:relative;aspect-ratio:16/9;overflow:hidden;background:#000}
.frame .shot{position:absolute;inset:0;background-size:cover;background-position:center;
  transition:opacity .28s}

/* ══ 1 · CINEMA ══ */
.cin-veil{position:absolute;inset:0;
  background:linear-gradient(180deg,rgba(8,7,10,.72) 0%,rgba(8,7,10,.12) 32%,rgba(8,7,10,.16) 55%,rgba(8,7,10,.9) 100%)}
.cin-top{position:absolute;top:0;left:0;right:0;padding:22px 30px;display:flex;
  align-items:center;gap:16px}
.cin-idx{font-size:34px;font-weight:700;color:#fff;letter-spacing:-1px;line-height:1}
.cin-idx small{font-size:15px;color:rgba(255,255,255,.42);font-weight:400}
.cin-nm{flex:1;min-width:0}
.cin-nm b{display:block;font-size:15px;color:#fff;font-weight:600;overflow:hidden;
  text-overflow:ellipsis;white-space:nowrap}
.cin-nm i{font-style:normal;font-size:11.5px;color:rgba(255,255,255,.5)}
.cin-bot{position:absolute;bottom:0;left:0;right:0;padding:26px 30px 22px}
.ruler{display:flex;gap:5px;margin-bottom:16px}
.rk{flex:1;height:3px;background:rgba(255,255,255,.2);border-radius:2px;transition:.22s}
.rk.on{background:var(--live);height:5px;margin-top:-1px;box-shadow:0 0 14px var(--live)}
.cin-keys{display:flex;gap:20px;font-size:11px;color:rgba(255,255,255,.55);align-items:center}
.k{border:1px solid rgba(255,255,255,.28);border-radius:4px;padding:1px 7px;
  font-size:10.5px;color:rgba(255,255,255,.82);margin-right:5px}
.cin-live{margin-left:auto;color:var(--live);font-weight:700;letter-spacing:.8px;font-size:10.5px}
.pal{display:flex;gap:0;border-radius:3px;overflow:hidden;width:96px;height:14px;
  border:1px solid rgba(255,255,255,.18)}
.pal span{flex:1}
.cin-zone{position:absolute;top:0;bottom:0;width:26%;z-index:4;cursor:pointer;
  display:grid;place-items:center;opacity:0;transition:.18s}
.cz-l{left:0;background:linear-gradient(90deg,rgba(8,7,10,.6),transparent)}
.cz-r{right:0;background:linear-gradient(270deg,rgba(8,7,10,.6),transparent)}
.cin-zone:hover{opacity:1}
.cin-zone span{font-size:44px;color:#fff;text-shadow:0 2px 14px rgba(0,0,0,.8);font-weight:300}
.rk{cursor:pointer}
.rk:hover{background:rgba(255,255,255,.55)}
.ty-row{cursor:pointer}
.ty-row:hover{background:rgba(255,255,255,.07);color:#fff}
.hq{cursor:pointer}

/* ══ 2 · TYPEAHEAD ══ */
.ty-blur{position:absolute;inset:0;backdrop-filter:blur(26px) saturate(1.15);
  background:rgba(8,7,10,.6)}
.ty-mini{position:absolute;left:50%;top:9%;transform:translateX(-50%);width:38%;
  aspect-ratio:16/9;border-radius:8px;background-size:cover;background-position:center;
  border:2px solid var(--live);box-shadow:0 22px 60px rgba(0,0,0,.75),0 0 0 1px rgba(255,255,255,.07)}
.ty-in{position:absolute;left:50%;top:calc(9% + 24.5%);transform:translateX(-50%);
  width:62%;margin-top:20px;text-align:center}
.ty-q{font-size:30px;font-weight:300;color:#fff;letter-spacing:-.5px}
.ty-q .typed{border-bottom:2px solid var(--live);padding-bottom:2px}
.ty-q .ghost{color:rgba(255,255,255,.3)}
.cur{display:inline-block;width:2px;height:26px;background:var(--live);
  vertical-align:-4px;animation:bl 1.05s steps(2) infinite;margin-left:1px}
@keyframes bl{50%{opacity:0}}
.ty-cnt{margin-top:12px;font-size:11.5px;color:rgba(255,255,255,.45)}
.ty-list{position:absolute;left:50%;transform:translateX(-50%);bottom:52px;width:62%;
  display:flex;flex-direction:column;gap:2px}
.ty-row{display:flex;align-items:center;gap:11px;padding:7px 13px;border-radius:6px;
  font-size:12.5px;color:rgba(255,255,255,.5);transition:.15s}
.ty-row.on{background:rgba(255,255,255,.1);color:#fff}
.ty-row .sw{width:3px;height:16px;border-radius:2px;background:transparent}
.ty-row.on .sw{background:var(--live)}
.ty-row .mt{margin-left:auto;font-size:10.5px;color:rgba(255,255,255,.32)}
.ty-row em{font-style:normal;color:var(--live);font-weight:700}
.ty-foot{position:absolute;bottom:20px;left:0;right:0;text-align:center;
  font-size:10.5px;color:rgba(255,255,255,.35)}

/* ══ 3 · HINTS ══ */
.hi-veil{position:absolute;inset:0;background:rgba(8,7,10,.35)}
.hi-grid{position:absolute;inset:0;display:grid;grid-template-columns:1fr 1fr;
  grid-template-rows:1fr 1fr}
.hq{position:relative;border:1px solid rgba(255,255,255,.09);background-size:cover;
  background-position:center;overflow:hidden;transition:.2s}
.hq::after{content:"";position:absolute;inset:0;background:rgba(8,7,10,.5);transition:.2s}
.hq.on::after{background:rgba(8,7,10,.05)}
.hq.on{border-color:var(--live);z-index:2;box-shadow:inset 0 0 0 2px var(--live)}
.hkey{position:absolute;top:14px;left:14px;width:36px;height:36px;border-radius:7px;
  background:rgba(8,7,10,.78);border:1.5px solid rgba(255,255,255,.5);color:#fff;
  display:grid;place-items:center;font-size:17px;font-weight:700;z-index:3;
  backdrop-filter:blur(6px);transition:.2s}
.hq.on .hkey{background:var(--live);border-color:var(--live);
  box-shadow:0 0 22px var(--live);transform:scale(1.12)}
.hnm{position:absolute;left:14px;right:14px;bottom:12px;z-index:3;font-size:11px;
  color:rgba(255,255,255,.92);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;
  text-shadow:0 1px 6px rgba(0,0,0,.9)}
.hnm i{font-style:normal;display:block;font-size:9.5px;color:rgba(255,255,255,.5)}
.hi-foot{position:absolute;bottom:0;left:0;right:0;padding:11px 20px;z-index:5;
  background:linear-gradient(transparent,rgba(8,7,10,.94) 55%);
  display:flex;gap:18px;align-items:center;font-size:10.5px;color:rgba(255,255,255,.5)}

.ctl{display:flex;gap:8px;align-items:center;padding:14px 4px 0;flex-wrap:wrap}
.ctl .lbl{font-size:10.5px;letter-spacing:1px;color:var(--dis);text-transform:uppercase;margin-right:2px}
.kb{border:1px solid var(--border-i);background:var(--surface);color:var(--text);
  border-radius:6px;padding:6px 13px;font-family:var(--mono);font-size:12px;cursor:pointer;
  transition:.14s}
.kb:hover{background:var(--raised);border-color:var(--accent);color:var(--accent)}
.kb:active{transform:translateY(1px)}
.hint{font-size:11px;color:var(--dis);margin-left:auto}

table{width:100%;border-collapse:collapse;font-size:12.5px;border:1px solid var(--border);
  border-radius:8px;overflow:hidden;margin-top:14px}
th,td{padding:11px 14px;text-align:left;border-bottom:1px solid var(--border)}
th{background:var(--raised);font-size:10.5px;letter-spacing:1px;text-transform:uppercase;color:var(--accent)}
td:first-child{color:var(--muted);white-space:nowrap}
tr:last-child td{border-bottom:0}
.y{color:var(--accent)} .n{color:var(--dis)}
h2.big{font-size:19px;margin:52px 0 10px;letter-spacing:.3px}
.rec{border:1px solid var(--accent);border-radius:9px;padding:22px 26px;
  background:linear-gradient(135deg,rgba(196,59,82,.1),transparent);margin-top:34px}
.rec h3{font-size:16px;color:var(--accent);margin-bottom:10px}
.rec p{color:var(--muted);font-size:13px}
.rec p+p{margin-top:9px}
.rec code{color:var(--text);background:var(--raised);padding:1px 6px;border-radius:4px;font-size:12px}
.rec ol{margin:14px 0 0 20px;color:var(--muted);font-size:13px}
.rec li{margin-bottom:5px}
.rec b{color:var(--text)}
</style>
</head>
<body>
<div class="wrap">

<h1>Wallpaper picker <span class="d">— три клавиатурных подхода</span></h1>
<p class="lede">Ни одной сетки миниатюр. Обои показываются <b>крупно</b>, интерфейс
перекрашивается в их доминирующий цвет. Каждый вариант работает <b>и клавишами, и мышью</b> —
наводи, кликай, крути колесо прямо в макетах, кнопки внизу дублируют клавиши.</p>

<div class="note">
<b>Что не так было с плитками.</b> Сетка миниатюр тратит экран на двадцать марок по 200 пикселей,
хотя решение принимается по одному кадру. Обои — это большая картинка, и смотреть на неё надо
большой. Все три варианта ниже отдают превью максимум площади, а список сжимают до тонкой
полоски, буквы или вообще убирают.
</div>

<div class="note" style="border-color:var(--dis)">
<b style="color:var(--muted)">Мышь и клавиатура равноправны.</b> Ниже у каждого варианта явно
расписано, что делает мышь: hover меняет превью, клик применяет, колесо листает. Клавиатура
работает параллельно, ни один путь не является обязательным.
</div>

<!-- ═══ 1 ═══ -->
<section class="opt" data-mock="cinema">
  <div class="oh"><div class="on">1</div><h2>Cinema</h2>
    <span class="sub">один кадр во весь экран · стрелки, колесо или клик по краю</span></div>
  <p class="od">Обои занимают весь экран целиком — ты видишь их ровно такими, какими они станут.
  Сверху номер и имя, снизу «линейка» из штрихов по числу файлов — позиция читается без миниатюр.
  Акцент интерфейса перекрашивается в доминирующий цвет кадра.<br>
  <b style="color:var(--text)">Мышь:</b> колесо листает, клик по левой/правой трети экрана —
  назад/вперёд, клик по штриху линейки — прыжок к файлу, двойной клик — применить.
  <b style="color:var(--text)">Клавиши:</b> <code>←</code> <code>→</code>, <code>1</code>–<code>9</code>
  прыжок, <code>enter</code>.</p>
  <div class="stage">
    <div class="frame">
      <div class="shot" id="cin-shot"></div>
      <div class="cin-veil"></div>
      <div class="cin-top">
        <div class="cin-idx" id="cin-i">1<small>/4</small></div>
        <div class="cin-nm"><b id="cin-n"></b><i id="cin-m"></i></div>
        <div class="pal" id="cin-p"></div>
      </div>
      <div class="cin-zone cz-l" id="cz-l"><span>‹</span></div>
      <div class="cin-zone cz-r" id="cz-r"><span>›</span></div>
      <div class="cin-bot">
        <div class="ruler" id="cin-r"></div>
        <div class="cin-keys">
          <span><span class="k">←</span><span class="k">→</span>листать</span>
          <span><span class="k">enter</span>применить</span>
          <span><span class="k">esc</span>отмена</span>
          <span class="cin-live" id="cin-live">● ТЕКУЩИЕ</span>
        </div>
      </div>
    </div>
  </div>
  <div class="ctl"><span class="lbl">клавиши</span>
    <button class="kb" data-k="prev">←</button>
    <button class="kb" data-k="next">→</button>
    <button class="kb" data-k="enter">enter</button>
    <span class="hint">мышью: колесо, клик по краям кадра, клик по штрихам линейки</span></div>
</section>

<!-- ═══ 2 ═══ -->
<section class="opt" data-mock="type">
  <div class="oh"><div class="on">2</div><h2>Typeahead</h2>
    <span class="sub">печатаешь имя · или просто водишь по списку мышью</span></div>
  <p class="od">Логика лаунчера, применённая к обоям: печатаешь — список сужается, превью наверху
  меняется мгновенно, совпавшие буквы подсвечены. Фон размыт текущими обоями.
  Масштабируется на сотни файлов: три буквы почти всегда дают один результат.<br>
  <b style="color:var(--text)">Мышь:</b> наведение на строку меняет превью, клик применяет —
  печатать не обязательно, при четырёх файлах список и так виден целиком.
  <b style="color:var(--text)">Клавиши:</b> буквы фильтруют, <code>↑↓</code>, <code>enter</code>.</p>
  <div class="stage">
    <div class="frame">
      <div class="shot" id="ty-bg"></div>
      <div class="ty-blur"></div>
      <div class="ty-mini" id="ty-mini"></div>
      <div class="ty-in">
        <div class="ty-q"><span class="typed" id="ty-t"></span><span class="ghost" id="ty-g"></span><span class="cur"></span></div>
        <div class="ty-cnt" id="ty-c"></div>
      </div>
      <div class="ty-list" id="ty-l"></div>
      <div class="ty-foot"><span class="k">↑↓</span>выбрать <span class="k">enter</span>применить <span class="k">esc</span>закрыть</div>
    </div>
  </div>
  <div class="ctl"><span class="lbl">печать</span>
    <button class="kb" data-k="t-g">g</button>
    <button class="kb" data-k="t-o">o</button>
    <button class="kb" data-k="t-a">a</button>
    <button class="kb" data-k="t-m">m</button>
    <button class="kb" data-k="t-back">⌫</button>
    <button class="kb" data-k="t-down">↓</button>
    <span class="hint">мышью: наведи на строку в списке — превью меняется, клик применяет</span></div>
</section>

<!-- ═══ 3 ═══ -->
<section class="opt" data-mock="hints">
  <div class="oh"><div class="on">3</div><h2>Hint keys</h2>
    <span class="sub">одна клавиша — один выбор · или просто клик по области</span></div>
  <p class="od">Экран делится на крупные области — по одной на файл, каждая помечена буквой.
  Область под курсором (или под буквой) светлеет до полной яркости, остальные приглушены.
  Формально это тоже сетка — но из четырёх кадров по четверти экрана, а не из двадцати марок:
  каждый показан достаточно крупно, чтобы решать по нему.<br>
  <b style="color:var(--text)">Мышь:</b> hover подсвечивает и показывает имя, клик применяет.
  <b style="color:var(--text)">Клавиши:</b> <code>a</code> <code>s</code> <code>d</code> <code>f</code>
  применяют мгновенно, без Enter.</p>
  <div class="stage">
    <div class="frame">
      <div class="hi-grid" id="hi-g"></div>
      <div class="hi-foot"><span>жми букву — применяется сразу</span>
        <span><span class="k">tab</span>следующая страница</span>
        <span><span class="k">esc</span>закрыть</span>
        <span style="margin-left:auto;color:var(--live);font-weight:700" id="hi-cur"></span></div>
    </div>
  </div>
  <div class="ctl"><span class="lbl">клавиши</span>
    <button class="kb" data-k="h-a">a</button>
    <button class="kb" data-k="h-s">s</button>
    <button class="kb" data-k="h-d">d</button>
    <button class="kb" data-k="h-f">f</button>
    <span class="hint">мышью: наведи на любую четверть — она разгорается, клик применяет</span></div>
</section>

<h2 class="big">Сравнение</h2>
<table>
  <tr><th></th><th>1 · Cinema</th><th>2 · Typeahead</th><th>3 · Hint keys</th></tr>
  <tr><td>Нажатий до цели</td><td class="n">до N−1 стрелок</td><td class="y">2–4 буквы</td><td class="y">1 клавиша</td></tr>
  <tr><td>Размер превью</td><td class="y">весь экран</td><td class="n">~38% ширины</td><td class="y">четверть экрана</td></tr>
  <tr><td>При 4 файлах</td><td class="y">идеально</td><td class="n">печать избыточна</td><td class="y">идеально</td></tr>
  <tr><td>При 100 файлах</td><td class="n">невозможно</td><td class="y">лучший</td><td class="n">много страниц</td></tr>
  <tr><td>Надо помнить имена</td><td class="y">нет</td><td class="n">да</td><td class="y">нет</td></tr>
  <tr><td>Видно до применения</td><td class="y">целиком</td><td class="n">мелко</td><td class="y">крупно</td></tr>
  <tr><td>Работа мышью</td><td class="y">колесо, края, линейка</td><td class="y">hover + клик</td><td class="y">hover + клик</td></tr>
  <tr><td>Сложность QML</td><td class="y">низкая</td><td class="n">средняя</td><td class="y">низкая</td></tr>
</table>

<div class="rec">
  <h3>Рекомендация: Cinema, с hint-клавишами поверх</h3>
  <p>У тебя <b>4 файла обоев</b>. Cinema даёт максимум того, что вообще возможно —
  обои на весь экран в реальном размере, ноль концепций для запоминания. Клавишами это
  <code>←</code>/<code>→</code>, мышью — колесо или клик по краю кадра; двух движений хватает,
  чтобы обойти всю коллекцию любым способом.</p>
  <p>Hint-клавиши не конкурируют с Cinema, а <b>дополняют</b> её: те же <code>1</code>–<code>4</code>
  (или <code>a s d f</code>) работают прямо в Cinema как прыжок к N-му файлу — один хлопок вместо
  трёх стрелок. Мышиный эквивалент того же прыжка — клик по штриху линейки. Это ~10 строк QML
  поверх готового <code>Keys.onPressed</code>, отдельный режим не нужен.</p>
  <p>Typeahead держи в уме на потом: когда обоев станет 50+, поле поиска добавляется в тот же
  оверлей по нажатию <code>/</code>, а <code>WallpaperState</code> не переписывается.</p>
  <p style="color:var(--dis);font-size:12px">Про перекраску акцента: палитра извлекается
  <code>magick -colors 5</code> за ~1.4 с на файл (замерил на goku 5120×2880) — значит только фоновым
  <code>Process</code> с кэшем в <code>~/.cache/rashell/</code> при первом скане, не на лету при листании.
  Если это лишнее — Cinema работает и без перекраски, палитра просто не показывается.</p>
  <ol>
    <li><b>modules/wallpaper/WallpaperState.qml</b> — скан каталога, список, индекс, кэш палитр</li>
    <li><b>modules/wallpaper/WallpaperPicker.qml</b> — <code>PanelWindow</code> + <code>WlrLayer.Overlay</code> +
      <code>keyboardFocus: Exclusive</code>, как <code>Launcher.qml:60-70</code></li>
    <li><b>modules/wallpaper/qmldir</b> + инстанс в <code>shell.qml</code></li>
    <li>IPC-функция <code>wallpaperToggle()</code> в <code>shell.qml</code> + бинд в Hyprland</li>
  </ol>
  <p style="margin-top:12px;font-size:12px">Не меняется: <code>overlays/Wallpaper.qml</code>,
  <code>ConfigStore.setWallpaper()</code>, <code>validate()</code> — всё уже готово и рабочее.</p>
</div>

</div>
<script>
const W = __DATA__;
const $ = s => document.querySelector(s);
const setLive = c => document.documentElement.style.setProperty('--live', c);

/* ── 1 · cinema ── */
let ci = 0;
function cinema(){
  const w = W[ci];
  $('#cin-shot').style.backgroundImage = `url('${w.img}')`;
  $('#cin-i').innerHTML = (ci+1)+'<small>/'+W.length+'</small>';
  $('#cin-n').textContent = w.name;
  $('#cin-m').textContent = w.dim+' · '+w.size;
  $('#cin-p').innerHTML = w.pal.map(c=>`<span style="background:${c}"></span>`).join('');
  $('#cin-r').innerHTML = W.map((_,i)=>`<div class="rk${i===ci?' on':''}"></div>`).join('');
  $('#cin-live').textContent = ci===0 ? '● ТЕКУЩИЕ' : '○ ПРЕВЬЮ';
  setLive(w.accent);
  [...$('#cin-r').children].forEach((el,i)=>
    el.addEventListener('click',()=>{ ci=i; cinema(); }));
}

/* ── 2 · typeahead ── */
let q = '', ti = 0;
function matches(){ return W.filter(w=>w.name.toLowerCase().includes(q.toLowerCase())); }
function type(){
  const m = matches();
  if (ti >= m.length) ti = 0;
  const w = m[ti] || W[0];
  $('#ty-bg').style.backgroundImage = `url('${w.img}')`;
  $('#ty-mini').style.backgroundImage = `url('${w.img}')`;
  $('#ty-t').textContent = q;
  $('#ty-g').textContent = q === '' ? 'начни печатать имя…' : '';
  $('#ty-c').textContent = m.length + (m.length===1?' совпадение':' совпадений');
  $('#ty-l').innerHTML = m.slice(0,4).map((x,i)=>{
    const p = x.name.toLowerCase().indexOf(q.toLowerCase());
    const nm = (q && p>=0)
      ? x.name.slice(0,p)+'<em>'+x.name.slice(p,p+q.length)+'</em>'+x.name.slice(p+q.length)
      : x.name;
    return `<div class="ty-row${i===ti?' on':''}"><span class="sw"></span><span>${nm}</span><span class="mt">${x.dim}</span></div>`;
  }).join('');
  if (m.length) setLive(w.accent);
}

/* ── 3 · hints ── */
const KEYS = ['a','s','d','f'];
let hi = 0;
function hints(){
  $('#hi-g').innerHTML = W.map((w,i)=>
    `<div class="hq${i===hi?' on':''}" style="background-image:url('${w.img}')">
       <div class="hkey">${KEYS[i]}</div>
       <div class="hnm">${w.name}<i>${w.dim} · ${w.size}</i></div>
     </div>`).join('');
  $('#hi-cur').textContent = '→ '+W[hi].name;
  setLive(W[hi].accent);
}

/* мышь: cinema */
$('#cz-l').addEventListener('click',()=>{ ci=(ci-1+W.length)%W.length; cinema(); });
$('#cz-r').addEventListener('click',()=>{ ci=(ci+1)%W.length; cinema(); });
$('#cin-shot').parentElement.addEventListener('wheel',e=>{
  e.preventDefault();
  ci = (ci + (e.deltaY>0?1:-1) + W.length) % W.length;
  cinema();
},{passive:false});

/* мышь: typeahead + hints — делегирование, узлы перерисовываются */
$('#ty-l').addEventListener('mouseover',e=>{
  const r=e.target.closest('.ty-row'); if(!r)return;
  const i=[...$('#ty-l').children].indexOf(r);
  if(i>=0&&i!==ti){ ti=i; type(); }
});
$('#hi-g').addEventListener('mouseover',e=>{
  const q=e.target.closest('.hq'); if(!q)return;
  const i=[...$('#hi-g').children].indexOf(q);
  if(i>=0&&i!==hi){ hi=i; hints(); }
});

document.querySelectorAll('.kb').forEach(b=>b.addEventListener('click',()=>{
  const k = b.dataset.k;
  if (k==='prev'){ ci=(ci-1+W.length)%W.length; cinema(); }
  else if (k==='next'){ ci=(ci+1)%W.length; cinema(); }
  else if (k==='enter'){ const l=$('#cin-live'); l.textContent='✓ ПРИМЕНЕНО'; setTimeout(cinema,900); }
  else if (k==='t-back'){ q=q.slice(0,-1); ti=0; type(); }
  else if (k==='t-down'){ ti=(ti+1)%Math.max(1,matches().length); type(); }
  else if (k.startsWith('t-')){ q+=k.slice(2); ti=0; type(); }
  else if (k.startsWith('h-')){ hi=KEYS.indexOf(k.slice(2)); hints(); }
}));

cinema(); type(); hints();
</script>
</body>
</html>
""".replace("__DATA__", DATA)

pathlib.Path("index.html").write_text(PAGE, encoding="utf-8")
print("written", len(PAGE))
