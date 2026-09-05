import base64, pathlib, json

def b64(p): return "data:image/jpeg;base64," + base64.b64encode(pathlib.Path(p).read_bytes()).decode()
BIG = {p.stem: b64(p) for p in pathlib.Path(".design/big").glob("*.jpg")}
M = json.loads(pathlib.Path(".design/metrics.json").read_text())

W = [
 dict(key="bisbiswas-a-summer-evening", short="summer-evening", name="bisbiswas-a-summer-evening.png",
      dim="3840×2160", size="1.8 MB", hue=254, sat=62, lum=30,
      pal=["#28050D","#5C1121","#AC3238","#BB9F60","#94B68F"], accent="#AC3238", theme="nevermore"),
 dict(key="amber", short="amber", name="amber.jpg",
      dim="2560×1440", size="3.0 MB", hue=44, sat=19, lum=19,
      pal=["#1F1D19","#5A4530","#986A34","#BE9653","#C3B39A"], accent="#BE9653", theme="ember"),
 dict(key="Flux.1_Dev_00007_", short="Flux.1_Dev", name="Flux.1_Dev_00007_.png",
      dim="2560×1440", size="3.0 MB", hue=252, sat=49, lum=18,
      pal=["#0F1225","#2E2F4A","#563352","#563E61","#AB698F"], accent="#AB698F", theme="raven"),
 dict(key="goku-perfected-5120x2880-25454", short="goku-perfected", name="goku-perfected-5120x2880-25454.jpg",
      dim="5120×2880", size="6.3 MB", hue=218, sat=18, lum=6,
      pal=["#080A0D","#374956","#3E505E","#5C7488","#95A6B4"], accent="#5C7488", theme="talon"),
]
for w in W:
    w.update(M[w["key"]]); w["img"] = BIG[w["key"]]
    # оценка пригодности под бар: чем темнее верх и ниже контраст — тем лучше читается панель
    w["barScore"] = max(0, min(100, round(100 - w["top"]*3.2 - w["contrast"]*1.1)))
DATA = json.dumps(W, ensure_ascii=False)

THEMES = json.dumps({
 "nevermore":{"bg":"#08070a","surface":"#0f0d12","accent":"#c43b52","text":"#e6ded0","border":"#393238"},
 "ember":{"bg":"#0e0e13","surface":"#17171f","accent":"#ffbd5a","text":"#f2ecdf","border":"#32303a"},
 "raven":{"bg":"#0d0e16","surface":"#171824","accent":"#a79aff","text":"#ebe9ff","border":"#303247"},
 "talon":{"bg":"#0b0c0e","surface":"#101113","accent":"#f2f0ea","text":"#f2f0ea","border":"#38393b"},
}, ensure_ascii=False)

PAGE = r"""<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>rashell · Wallpaper — вторая серия</title>
<style>
:root{--bg:#08070a;--surface:#0f0d12;--raised:#1c171e;--accent:#c43b52;
 --text:#e6ded0;--muted:#b3aa9b;--dis:#7f776b;--on-accent:#fff5e9;
 --border:#393238;--border-i:#766d70;
 --mono:"FiraCode Nerd Font","Fira Code",ui-monospace,"JetBrains Mono",Menlo,monospace;--live:#c43b52}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:var(--mono);font-size:14px;
 line-height:1.6;padding:40px 26px 110px;-webkit-font-smoothing:antialiased}
.wrap{max-width:1100px;margin:0 auto}
h1{font-size:24px;font-weight:700;margin-bottom:8px}
h1 .d{color:var(--muted);font-weight:400}
.lede{color:var(--muted);max-width:820px;font-size:13.5px}
.lede b{color:var(--text)}
.note{border-left:3px solid var(--accent);background:var(--surface);padding:13px 18px;
 border-radius:0 8px 8px 0;margin:20px 0 18px;max-width:880px;color:var(--muted);font-size:13px}
.note b{color:var(--accent)}
.mtab{width:100%;max-width:880px;border-collapse:collapse;font-size:12px;margin:0 0 40px;
 border:1px solid var(--border);border-radius:8px;overflow:hidden}
.mtab th,.mtab td{padding:7px 12px;text-align:left;border-bottom:1px solid var(--border)}
.mtab th{background:var(--raised);font-size:10px;letter-spacing:1px;text-transform:uppercase;color:var(--accent)}
.mtab tr:last-child td{border-bottom:0}
.mtab td:first-child{color:var(--muted)}
.mtab .num{color:var(--text);text-align:right;font-variant-numeric:tabular-nums}

.opt{margin-bottom:62px}
.oh{display:flex;align-items:baseline;gap:13px;margin-bottom:6px;flex-wrap:wrap}
.onum{width:30px;height:30px;flex:0 0 30px;border-radius:8px;background:var(--accent);
 color:var(--on-accent);display:grid;place-items:center;font-weight:700;font-size:13px}
.oh h2{font-size:18px;font-weight:700}
.oh .sub{color:var(--dis);font-size:12px}
.od{color:var(--muted);max-width:830px;margin:0 0 16px 43px;font-size:13px}
.od code{color:var(--accent)} .od b{color:var(--text)}
.why{margin:8px 0 14px 43px;padding:9px 14px;border-left:2px solid var(--border-i);
 font-size:12px;color:var(--dis);max-width:830px}
.why b{color:var(--muted)}
.stage{border:1px solid var(--border);border-radius:10px;overflow:hidden;background:#000;
 position:relative;aspect-ratio:16/9}

/* ═════ 4 · CONTACT SHEET ═════ */
.cs-bg{position:absolute;inset:0;background-size:cover;background-position:center;
 filter:brightness(.28) saturate(.7);transition:.4s}
.cs-strip{position:absolute;inset:0;display:flex;gap:0}
.cs-col{position:relative;flex:1;overflow:hidden;cursor:pointer;
 border-right:1px solid rgba(255,255,255,.08);transition:flex .42s cubic-bezier(.3,.9,.3,1)}
.cs-col:last-child{border-right:0}
.cs-col.on{flex:5.2}
.cs-img{position:absolute;inset:0;background-size:cover;background-position:center;
 filter:saturate(.35) brightness(.5);transition:.42s}
.cs-col.on .cs-img{filter:none}
.cs-vert{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%) rotate(-90deg);
 white-space:nowrap;font-size:11px;letter-spacing:2px;color:rgba(255,255,255,.72);
 text-transform:uppercase;transition:.3s;text-shadow:0 1px 6px rgba(0,0,0,.9)}
.cs-col.on .cs-vert{opacity:0}
.cs-info{position:absolute;left:0;right:0;bottom:0;padding:30px 20px 16px;opacity:0;
 transition:.3s .12s;background:linear-gradient(transparent,rgba(8,7,10,.93));
 pointer-events:none;visibility:hidden;white-space:nowrap;overflow:hidden}
.cs-col.on .cs-info{visibility:visible}
.cs-col.on .cs-info{opacity:1}
.cs-info b{display:block;font-size:14px;color:#fff;font-weight:600}
.cs-info i{font-style:normal;font-size:10.5px;color:rgba(255,255,255,.55)}
.cs-pal{display:flex;gap:3px;margin-top:7px}
.cs-pal em{width:20px;height:8px;border-radius:2px}
.cs-num{position:absolute;top:12px;left:0;right:0;text-align:center;font-size:10px;
 color:rgba(255,255,255,.5);font-weight:700;text-shadow:0 1px 5px rgba(0,0,0,.9)}
.cs-col.on .cs-num{color:var(--live)}

/* ═════ 5 · BAR FITNESS ═════ */
.bf-img{position:absolute;inset:0;background-size:cover;background-position:center;transition:.4s}
.bf-bar{position:absolute;left:0;right:0;top:0;height:38px;display:flex;align-items:center;
 gap:14px;padding:0 14px;font-size:11px;z-index:5;transition:.35s}
.bf-bar .ac{font-weight:700}
.bf-scan{position:absolute;left:0;right:0;top:0;height:38px;z-index:4;
 border-bottom:1px dashed rgba(255,255,255,.45);
 background:repeating-linear-gradient(90deg,rgba(255,255,255,.05) 0 6px,transparent 6px 12px)}
.bf-cap{position:absolute;top:44px;left:14px;font-size:9.5px;letter-spacing:1px;
 color:rgba(255,255,255,.5);z-index:5}
.bf-panel{position:absolute;right:16px;bottom:16px;width:38%;z-index:6;
 background:rgba(8,7,10,.82);border:1px solid rgba(255,255,255,.14);border-radius:9px;
 padding:14px 16px;backdrop-filter:blur(14px)}
.bf-score{display:flex;align-items:baseline;gap:8px;margin-bottom:3px}
.bf-score b{font-size:30px;font-weight:700;line-height:1;color:var(--live)}
.bf-score span{font-size:10px;letter-spacing:1.2px;color:rgba(255,255,255,.5)}
.bf-verdict{font-size:11.5px;color:#fff;margin-bottom:10px}
.bf-row{display:flex;align-items:center;gap:8px;font-size:10px;
 color:rgba(255,255,255,.6);margin-bottom:5px}
.bf-row .lb{width:82px;flex:0 0 82px;white-space:nowrap}
.bf-track{flex:1;height:5px;background:rgba(255,255,255,.2);border-radius:3px;overflow:hidden;
 box-shadow:inset 0 0 0 1px rgba(255,255,255,.08)}
.bf-fill{height:100%;border-radius:3px;transition:.4s;box-shadow:0 0 8px currentColor}
.bf-row .vl{width:30px;text-align:right;color:rgba(255,255,255,.85);
 font-variant-numeric:tabular-nums}
.bf-dock{position:absolute;left:16px;bottom:16px;z-index:6;display:flex;flex-direction:column;gap:5px;width:172px}
.bf-chip{display:flex;align-items:center;gap:8px;padding:7px 11px;border-radius:6px;
 background:rgba(8,7,10,.78);border:1px solid rgba(255,255,255,.13);cursor:pointer;
 font-size:10.5px;color:rgba(255,255,255,.72);transition:.16s;backdrop-filter:blur(8px);
 white-space:nowrap;overflow:hidden}
.bf-chip .nm{flex:1;overflow:hidden;text-overflow:ellipsis;min-width:0}
.bf-chip:hover{border-color:rgba(255,255,255,.45);color:#fff}
.bf-chip.on{border-color:var(--live);color:#fff;background:rgba(196,59,82,.2)}
.bf-chip .dt{width:7px;height:7px;border-radius:50%;flex:0 0 7px}
.bf-chip .sc{margin-left:auto;font-variant-numeric:tabular-nums;font-weight:700}

/* ═════ 6 · ZONE MAP ═════ */
.zm-img{position:absolute;inset:0;background-size:cover;background-position:center;transition:.4s}
.zm-grid{position:absolute;inset:0;display:grid;grid-template-columns:repeat(3,1fr);
 grid-template-rows:repeat(3,1fr);z-index:3;pointer-events:none}
.zm-cell{border:1px solid rgba(255,255,255,.1);display:flex;align-items:flex-start;
 justify-content:flex-start;padding:6px;position:relative}
.zm-cell b{font-size:9.5px;font-weight:700;color:rgba(255,255,255,.9);
 background:rgba(8,7,10,.7);border-radius:3px;padding:1px 5px;
 font-variant-numeric:tabular-nums}
.zm-cell.calm{background:rgba(115,223,161,.24);border-color:rgba(115,223,161,.75);
 box-shadow:inset 0 0 0 1px rgba(115,223,161,.3)}
.zm-cell.busy{background:rgba(196,59,82,.2);border-color:rgba(196,59,82,.6)}
.zm-widget{position:absolute;z-index:5;border-radius:8px;padding:10px 13px;
 background:rgba(8,7,10,.8);border:1.5px solid var(--live);backdrop-filter:blur(12px);
 transition:.45s cubic-bezier(.3,.9,.3,1);box-shadow:0 8px 30px rgba(0,0,0,.6)}
.zm-widget .t{font-size:9px;letter-spacing:1.2px;color:var(--live);font-weight:700}
.zm-widget .v{font-size:19px;color:#fff;font-weight:600;line-height:1.2}
.zm-widget .s{font-size:9.5px;color:rgba(255,255,255,.55)}
.zm-legend{position:absolute;left:0;right:0;bottom:0;padding:10px 16px;z-index:6;
 background:linear-gradient(transparent,rgba(8,7,10,.92) 50%);display:flex;gap:14px;
 align-items:center;font-size:10px;color:rgba(255,255,255,.6)}
.zm-legend .sw{width:10px;height:10px;border-radius:2px;display:inline-block;
 vertical-align:-1px;margin-right:5px}
.zm-pick{position:absolute;top:12px;right:14px;z-index:6;display:flex;gap:5px;
 flex-wrap:nowrap;max-width:calc(100% - 28px)}
.zm-pick div{padding:5px 10px;border-radius:5px;font-size:10px;cursor:pointer;
 background:rgba(8,7,10,.82);border:1px solid rgba(255,255,255,.14);
 color:rgba(255,255,255,.7);transition:.15s;backdrop-filter:blur(8px);white-space:nowrap}
.zm-pick div:hover{border-color:rgba(255,255,255,.45);color:#fff}
.zm-pick div.on{border-color:var(--live);color:#fff;background:rgba(196,59,82,.22)}

.ctl{display:flex;gap:7px;align-items:center;padding:13px 2px 0;flex-wrap:wrap}
.ctl .lbl{font-size:10px;letter-spacing:1px;color:var(--dis);text-transform:uppercase}
.kb{border:1px solid var(--border-i);background:var(--surface);color:var(--text);
 border-radius:6px;padding:5px 12px;font-family:var(--mono);font-size:12px;cursor:pointer;transition:.14s}
.kb:hover{background:var(--raised);border-color:var(--accent);color:var(--accent)}
.hint{font-size:11px;color:var(--dis);margin-left:auto}

table.cmp{width:100%;border-collapse:collapse;font-size:12.5px;border:1px solid var(--border);
 border-radius:8px;overflow:hidden;margin-top:12px}
.cmp th,.cmp td{padding:10px 13px;text-align:left;border-bottom:1px solid var(--border)}
.cmp th{background:var(--raised);font-size:10px;letter-spacing:1px;text-transform:uppercase;color:var(--accent)}
.cmp td:first-child{color:var(--muted);white-space:nowrap}
.cmp tr:last-child td{border-bottom:0}
.y{color:var(--accent)}.n{color:var(--dis)}
h2.big{font-size:19px;margin:50px 0 8px}
.rec{border:1px solid var(--accent);border-radius:9px;padding:20px 24px;
 background:linear-gradient(135deg,rgba(196,59,82,.1),transparent);margin-top:32px}
.rec h3{font-size:16px;color:var(--accent);margin-bottom:9px}
.rec p{color:var(--muted);font-size:13px}.rec p+p{margin-top:9px}
.rec code{color:var(--text);background:var(--raised);padding:1px 6px;border-radius:4px;font-size:12px}
.rec b{color:var(--text)}
.src{border:1px solid var(--border);border-radius:9px;padding:20px 24px;margin-top:26px;background:var(--surface)}
.src h3{font-size:16px;margin-bottom:12px}
.src h4{font-size:12px;color:var(--accent);letter-spacing:1px;text-transform:uppercase;
 margin:16px 0 7px}
.src ul{margin-left:18px;color:var(--muted);font-size:13px}
.src li{margin-bottom:6px}
.src b{color:var(--text)}
.src code{color:var(--accent);background:var(--raised);padding:1px 6px;border-radius:4px;font-size:12px}
</style>
</head>
<body>
<div class="wrap">

<h1>Wallpaper picker <span class="d">— вторая серия, ещё три идеи</span></h1>
<p class="lede">Первая серия строилась на цвете и яркости. Здесь три новые метрики, снятые
с твоих же файлов: <b>яркость полосы под баром</b>, <b>контраст</b> и <b>карта занятости кадра
по зонам</b>. Каждая даёт свой интерфейс. Всё кликается мышью и клавишами.</p>

<div class="note"><b>Откуда цифры.</b> Снял <code>magick</code> с четырёх твоих обоев:
яркость верхних 8% кадра (там, где бар), стандартное отклонение по серому (контраст) и
яркость по сетке 3×3. Это не выдумка для картинки — на этих числах построены варианты ниже.</div>

<table class="mtab">
<tr><th>файл</th><th>верх под баром</th><th>контраст</th><th>самая тёмная зона</th><th>самая светлая</th></tr>
<tr><td>goku-perfected</td><td class="num">1%</td><td class="num">9</td><td class="num">1%</td><td class="num">23%</td></tr>
<tr><td>amber</td><td class="num">10%</td><td class="num">17</td><td class="num">7%</td><td class="num">36%</td></tr>
<tr><td>Flux.1_Dev</td><td class="num">15%</td><td class="num">14</td><td class="num">8%</td><td class="num">36%</td></tr>
<tr><td>summer-evening</td><td class="num">16%</td><td class="num">25</td><td class="num">2%</td><td class="num">64%</td></tr>
</table>

<!-- ═══ 4 ═══ -->
<section class="opt">
  <div class="oh"><div class="onum">4</div><h2>Contact sheet</h2>
    <span class="sub">гармошка вертикальных полос</span></div>
  <p class="od">Кадр разрезан на вертикальные полосы — по одной на файл, все видны одновременно.
  Активная <b>раскрывается в широкое окно</b>, остальные сжимаются в корешки с именем вдоль
  полосы, как книги на полке. Ни одна не исчезает: коллекция видна целиком всегда, но экран
  отдан текущему выбору.</p>
  <p class="why"><b>Почему это работает:</b> решает конфликт «видеть всё» против «видеть крупно» —
  не компромиссом (сетка средних миниатюр), а перераспределением места. На 4 файлах активная
  полоса занимает две трети экрана; на 20 корешки становятся тоньше, но выбранная сохраняет
  ширину.</p>
  <p class="od" style="margin-top:10px"><b>Мышь:</b> наведение раскрывает полосу, клик применяет.
  <b>Клавиши:</b> <code>←</code><code>→</code>, <code>enter</code>.</p>
  <div class="stage">
    <div class="cs-bg" id="cs-bg"></div>
    <div class="cs-strip" id="cs-strip"></div>
  </div>
  <div class="ctl"><span class="lbl">клавиши</span>
    <button class="kb" data-k="cs-p">←</button><button class="kb" data-k="cs-n">→</button>
    <span class="hint">мышью: наведи на любую полосу — она раскроется</span></div>
</section>

<!-- ═══ 5 ═══ -->
<section class="opt">
  <div class="oh"><div class="onum">5</div><h2>Bar fitness</h2>
    <span class="sub">оценка: утонет ли панель на этих обоях</span></div>
  <p class="od">Picker, который <b>считает, а не только показывает</b>. Для каждых обоев измеряется
  яркость полосы ровно там, где стоит бар, и контраст кадра — из них складывается оценка
  читаемости панели. goku даёт 1% яркости под баром и получает высший балл, summer-evening с 16%
  и контрастом 25 — самый низкий. Сверху лежит настоящий бар, снизу — разбор по метрикам.</p>
  <p class="why"><b>Почему это ново:</b> ни один известный picker не отвечает на вопрос, из-за
  которого обои чаще всего и меняют обратно — «а панель-то читается?». Здесь этот вопрос
  главный, а картинка вторична. Тема шелла тоже подставляется под каждые обои.</p>
  <p class="od" style="margin-top:10px"><b>Мышь:</b> клик по чипу слева, hover — превью.
  <b>Клавиши:</b> <code>↑</code><code>↓</code>, <code>enter</code>.</p>
  <div class="stage">
    <div class="bf-img" id="bf-img"></div>
    <div class="bf-scan"></div>
    <div class="bf-bar" id="bf-bar"><span>󰍹 1 2 3</span><span style="margin-left:auto"></span>
      <span>󰃭 09:21</span><span class="ac">󰸉</span><span>󰂯</span><span>󰕾</span></div>
    <div class="bf-cap">↑ ЗАМЕР ЯРКОСТИ В ПОЛОСЕ БАРА</div>
    <div class="bf-dock" id="bf-dock"></div>
    <div class="bf-panel">
      <div class="bf-score"><b id="bf-n"></b><span>/100 ЧИТАЕМОСТЬ ПАНЕЛИ</span></div>
      <div class="bf-verdict" id="bf-v"></div>
      <div class="bf-row"><span class="lb">фон под баром</span>
        <span class="bf-track"><span class="bf-fill" id="bf-f1"></span></span><span class="vl" id="bf-v1"></span></div>
      <div class="bf-row"><span class="lb">контраст</span>
        <span class="bf-track"><span class="bf-fill" id="bf-f2"></span></span><span class="vl" id="bf-v2"></span></div>
      <div class="bf-row"><span class="lb">тема</span>
        <span style="color:#fff" id="bf-th"></span></div>
    </div>
  </div>
  <div class="ctl"><span class="lbl">клавиши</span>
    <button class="kb" data-k="bf-u">↑</button><button class="kb" data-k="bf-d">↓</button>
    <span class="hint">мышью: кликай чипы слева — бар и оценка меняются</span></div>
</section>

<!-- ═══ 6 ═══ -->
<section class="opt">
  <div class="oh"><div class="onum">6</div><h2>Zone map</h2>
    <span class="sub">куда на этих обоях встанут виджеты</span></div>
  <p class="od">Кадр размечен сеткой 3×3 с реальной яркостью каждой зоны. <b>Зелёные —
  спокойные</b>, туда можно ставить часы и виджеты; <b>красные — занятые</b>, там текст утонет.
  Плавающая карточка часов сама перелетает в самую тёмную зону текущих обоев: у goku это левый
  верх (1%), у summer-evening — тоже левый верх (2%), но правый горит на 64% и помечен красным.</p>
  <p class="why"><b>Почему это ново:</b> обои — это фон под контентом, а не картина в раме.
  Единственный вариант, который показывает <b>композиционную совместимость</b> с интерфейсом,
  а не эстетику. Полезен ровно тогда, когда на рабочем столе живут виджеты.</p>
  <p class="od" style="margin-top:10px"><b>Мышь:</b> клик по названию сверху справа.
  <b>Клавиши:</b> <code>←</code><code>→</code>, <code>enter</code>.</p>
  <div class="stage">
    <div class="zm-img" id="zm-img"></div>
    <div class="zm-grid" id="zm-grid"></div>
    <div class="zm-widget" id="zm-w"><div class="t">СПОКОЙНАЯ ЗОНА</div>
      <div class="v">09:21</div><div class="s" id="zm-s"></div></div>
    <div class="zm-pick" id="zm-pick"></div>
    <div class="zm-legend"><span><span class="sw" style="background:rgba(115,223,161,.5)"></span>спокойно, можно ставить виджеты</span>
      <span><span class="sw" style="background:rgba(196,59,82,.45)"></span>занято, текст утонет</span>
      <span style="margin-left:auto;color:var(--live);font-weight:700" id="zm-b"></span></div>
  </div>
  <div class="ctl"><span class="lbl">клавиши</span>
    <button class="kb" data-k="zm-p">←</button><button class="kb" data-k="zm-n">→</button>
    <span class="hint">мышью: выбери обои справа сверху — карточка перелетит в тёмную зону</span></div>
</section>

<h2 class="big">Сравнение всех шести</h2>
<table class="cmp">
  <tr><th></th><th>на чём построен</th><th>отвечает на вопрос</th><th>цена реализации</th></tr>
  <tr><td>1 · Wheel</td><td>оттенок</td><td>какого цвета коллекция?</td><td class="n">Canvas + magick</td></tr>
  <tr><td>2 · Split</td><td>сравнение</td><td class="y">лучше ли текущих?</td><td class="y">два Image + clip</td></tr>
  <tr><td>3 · Dial</td><td>яркость</td><td>светлее или темнее?</td><td>шкала + magick</td></tr>
  <tr><td>4 · Contact sheet</td><td>ничего, чистый UI</td><td>как выглядит каждый?</td><td class="y">анимация flex</td></tr>
  <tr><td>5 · Bar fitness</td><td>яркость полосы + контраст</td><td class="y">панель не утонет?</td><td>2 замера magick</td></tr>
  <tr><td>6 · Zone map</td><td>сетка 3×3</td><td class="y">куда встанут виджеты?</td><td>9 замеров magick</td></tr>
</table>

<div class="rec">
  <h3>Рекомендация после шести вариантов: Split + Bar fitness одним экраном</h3>
  <p>Они закрывают один и тот же вопрос с двух сторон и не конфликтуют. <b>Split</b> даёт
  визуальный ответ («вот так будет против того, что сейчас»), <b>Bar fitness</b> — числовой
  («панель читается на 78 из 100»). Шторка занимает кадр, панель с оценкой ложится в угол —
  это один экран, а не два режима.</p>
  <p>Из остальных <b>Contact sheet</b> — лучший чистый UI без единого внешнего замера, самый
  дешёвый в реализации после Split: одна анимация <code>flex</code>, никакого
  <code>magick</code>. Хороший запасной вариант, если не захочешь тянуть ImageMagick в шелл.</p>
  <p><b>Zone map</b> имеет смысл только если ты заведёшь виджеты на рабочем столе — сейчас у тебя
  их нет, метрика будет считаться впустую.</p>
  <p style="font-size:12px;color:var(--dis);margin-top:11px">Замеры для Bar fitness дешевле, чем
  для палитры: <code>magick -resize 200x -crop 100%x8% -format "%[fx:mean]"</code> — это одно число
  с уменьшенной копии, а не квантование в 5 цветов. Считается один раз при скане каталога и
  кэшируется рядом со списком файлов.</p>
</div>

<div class="src">
  <h3>Где брать обои</h3>

  <h4>Под твой вкус — тёмное, кинематографичное</h4>
  <ul>
    <li><b>wallhaven.cc</b> — главный источник для тюнинга Linux. Ключевое: поиск по цвету
      (кликаешь плашку — выдаёт обои этого оттенка) и фильтр по точному разрешению.
      Для твоей коллекции: <code>wallhaven.cc/search?q=dark&colors=0d0e16&atleast=2560x1440</code>.
      Есть API — обои можно тянуть скриптом прямо в <code>~/Pictures/Wallpapers</code>.</li>
    <li><b>r/wallpapers</b> и <b>r/WidescreenWallpaper</b> — живая лента, сортировка по top за год
      отсеивает случайное.</li>
    <li><b>Unsplash</b> — фотография, всё бесплатно и без атрибуции. Ищи <code>dark moody</code>,
      <code>night landscape</code>, <code>minimal dark</code>.</li>
  </ul>

  <h4>Художественное и иллюстрации</h4>
  <ul>
    <li><b>ArtStation</b> — концепт-арт индустрии. Твой bisbiswas-a-summer-evening — типичный
      представитель. Скачивание в полном разрешении не всегда доступно, но авторов легко найти.</li>
    <li><b>Cosmos.so</b> — визуальный дискавери, хорошо ловит эстетику «по вайбу».</li>
    <li><b>Danbooru / safebooru</b>, если нужен аниме-слой вроде твоего goku — там есть фильтр
      по разрешению и тег <code>wallpaper</code>.</li>
  </ul>

  <h4>Генерация под конкретную палитру</h4>
  <ul>
    <li>Твой <code>Flux.1_Dev_00007_.png</code> — уже генерация. Flux и SDXL хорошо слушаются
      промпта с точным цветом: «dark moody landscape, muted crimson and warm gold palette,
      cinematic, low contrast, 16:9». Раз у тебя тема <code>nevermore</code> с акцентом
      <code>#c43b52</code> — можно генерировать обои прямо под неё, а не подбирать тему под обои.</li>
  </ul>

  <h4>Практическое</h4>
  <ul>
    <li>Бери <b>не меньше нативного разрешения монитора</b>, иначе <code>PreserveAspectCrop</code>
      в <code>overlays/Wallpaper.qml</code> растянет и будет мыло.</li>
    <li>Для шелла лучше работают обои с <b>тёмным верхом</b> — бар читается без подложки.
      Это ровно то, что считает вариант 5: у твоего goku верх 1%, и он тут вне конкуренции.</li>
    <li>Низкий контраст (goku — 9) не спорит с интерфейсом; высокий (summer-evening — 25)
      красив, но перетягивает внимание на себя.</li>
  </ul>
</div>

</div>
<script>
const W = __DATA__, TH = __THEMES__;
const $ = s=>document.querySelector(s);
const setLive = c=>document.documentElement.style.setProperty('--live',c);

/* ─── 4 · contact sheet ─── */
let ci=0;
$('#cs-strip').innerHTML = W.map((w,i)=>`
 <div class="cs-col${i===ci?' on':''}" data-i="${i}">
   <div class="cs-img" style="background-image:url('${w.img}')"></div>
   <div class="cs-num">${String(i+1).padStart(2,'0')}</div>
   <div class="cs-vert">${w.short}</div>
   <div class="cs-info"><b>${w.short}</b><i>${w.dim} · ${w.size}</i>
     <div class="cs-pal">${w.pal.map(c=>`<em style="background:${c}"></em>`).join('')}</div></div>
 </div>`).join('');
function drawCS(){
  [...$('#cs-strip').children].forEach((c,i)=>c.classList.toggle('on',i===ci));
  $('#cs-bg').style.backgroundImage=`url('${W[ci].img}')`;
  setLive(W[ci].accent);
}
$('#cs-strip').addEventListener('mouseover',e=>{
  const c=e.target.closest('.cs-col'); if(!c)return;
  const i=+c.dataset.i; if(i!==ci){ci=i;drawCS();}
});

/* ─── 5 · bar fitness ─── */
let bi=0;
const byScore=[...W.keys()].sort((a,b)=>W[b].barScore-W[a].barScore);
function drawBF(){
  const w=W[bi], t=TH[w.theme];
  $('#bf-img').style.backgroundImage=`url('${w.img}')`;
  const bar=$('#bf-bar');
  bar.style.background=t.surface+'d9';
  bar.style.color=t.text;
  bar.style.borderBottom='1px solid '+t.border;
  bar.querySelector('.ac').style.color=t.accent;
  $('#bf-n').textContent=w.barScore;
  $('#bf-v').textContent = w.barScore>=70?'Панель читается уверенно'
    : w.barScore>=50?'Приемлемо, местами сливается':'Панели нужна подложка';
  const f1=Math.min(100,w.top*4), f2=Math.min(100,w.contrast*3);
  $('#bf-f1').style.width=f1+'%'; $('#bf-f1').style.background=w.top<=8?'#73dfa1':w.top<=14?'#ffbd5a':'#ed536b';
  $('#bf-f2').style.width=f2+'%'; $('#bf-f2').style.background=w.contrast<=12?'#73dfa1':w.contrast<=20?'#ffbd5a':'#ed536b';
  $('#bf-v1').textContent=w.top+'%'; $('#bf-v2').textContent=w.contrast;
  $('#bf-th').textContent=w.theme;
  $('#bf-dock').innerHTML=byScore.map(i=>{
    const x=W[i];
    return `<div class="bf-chip${i===bi?' on':''}" data-i="${i}">
      <span class="dt" style="background:${x.barScore>=70?'#73dfa1':x.barScore>=50?'#ffbd5a':'#ed536b'}"></span>
      <span class="nm">${x.short}</span><span class="sc">${x.barScore}</span></div>`;}).join('');
  setLive(t.accent);
}
$('#bf-dock').addEventListener('click',e=>{
  const c=e.target.closest('.bf-chip'); if(!c)return;
  bi=+c.dataset.i; drawBF();
});
$('#bf-dock').addEventListener('mouseover',e=>{
  const c=e.target.closest('.bf-chip'); if(!c)return;
  const i=+c.dataset.i; if(i!==bi){bi=i;drawBF();}
});

/* ─── 6 · zone map ─── */
let zi=0;
function drawZM(){
  const w=W[zi], z=w.zones;
  $('#zm-img').style.backgroundImage=`url('${w.img}')`;
  const mn=Math.min(...z), mx=Math.max(...z);
  $('#zm-grid').innerHTML=z.map(v=>{
    const cls = v<=mn+4?'calm' : v>=Math.max(30,mx-8)?'busy':'';
    return `<div class="zm-cell ${cls}"><b>${v}%</b></div>`;}).join('');
  const idx=z.indexOf(mn), col=idx%3, row=Math.floor(idx/3);
  const wd=$('#zm-w');
  wd.style.left=(col*33.33+4)+'%';
  wd.style.top=(row*33.33+5)+'%';
  $('#zm-s').textContent='зона '+(col+1)+'×'+(row+1)+' · яркость '+mn+'%';
  $('#zm-b').textContent='самая светлая зона: '+mx+'%';
  $('#zm-pick').innerHTML=W.map((x,i)=>
    `<div class="${i===zi?'on':''}" data-i="${i}">${x.short}</div>`).join('');
  setLive(w.accent);
}
$('#zm-pick').addEventListener('click',e=>{
  const d=e.target.closest('[data-i]'); if(!d)return;
  zi=+d.dataset.i; drawZM();
});

/* ─── кнопки ─── */
document.querySelectorAll('.kb').forEach(b=>b.addEventListener('click',()=>{
  const k=b.dataset.k;
  if(k==='cs-p'){ci=(ci-1+W.length)%W.length;drawCS();}
  else if(k==='cs-n'){ci=(ci+1)%W.length;drawCS();}
  else if(k==='bf-u'){const p=byScore.indexOf(bi);bi=byScore[(p-1+byScore.length)%byScore.length];drawBF();}
  else if(k==='bf-d'){const p=byScore.indexOf(bi);bi=byScore[(p+1)%byScore.length];drawBF();}
  else if(k==='zm-p'){zi=(zi-1+W.length)%W.length;drawZM();}
  else if(k==='zm-n'){zi=(zi+1)%W.length;drawZM();}
}));

drawCS(); drawBF(); drawZM();
window.__ready=true;
</script>
</body>
</html>
""".replace("__DATA__", DATA).replace("__THEMES__", THEMES)

pathlib.Path("index2.html").write_text(PAGE, encoding="utf-8")
print("written", len(PAGE))
