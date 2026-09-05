import base64, pathlib, json

def b64(p): return "data:image/jpeg;base64," + base64.b64encode(pathlib.Path(p).read_bytes()).decode()
BIG = {p.stem: b64(p) for p in pathlib.Path(".design/big").glob("*.jpg")}

W = [
 dict(key="bisbiswas-a-summer-evening", name="bisbiswas-a-summer-evening.png", short="summer-evening",
      dim="3840×2160", size="1.8 MB", hue=254, sat=62, lum=30,
      pal=["#28050D","#5C1121","#AC3238","#BB9F60","#94B68F"], accent="#AC3238"),
 dict(key="amber", name="amber.jpg", short="amber",
      dim="2560×1440", size="3.0 MB", hue=44, sat=19, lum=19,
      pal=["#1F1D19","#5A4530","#986A34","#BE9653","#C3B39A"], accent="#BE9653"),
 dict(key="Flux.1_Dev_00007_", name="Flux.1_Dev_00007_.png", short="Flux.1_Dev",
      dim="2560×1440", size="3.0 MB", hue=252, sat=49, lum=18,
      pal=["#0F1225","#2E2F4A","#563352","#563E61","#AB698F"], accent="#AB698F"),
 dict(key="goku-perfected-5120x2880-25454", name="goku-perfected-5120x2880-25454.jpg", short="goku-perfected",
      dim="5120×2880", size="6.3 MB", hue=218, sat=18, lum=6,
      pal=["#080A0D","#374956","#3E505E","#5C7488","#95A6B4"], accent="#5C7488"),
]
DATA = json.dumps([{**w, "img": BIG[w["key"]]} for w in W], ensure_ascii=False)

PAGE = r"""<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>rashell · Wallpaper — три идеи</title>
<style>
:root{
  --bg:#08070a;--surface:#0f0d12;--raised:#1c171e;--accent:#c43b52;
  --text:#e6ded0;--muted:#b3aa9b;--dis:#7f776b;--on-accent:#fff5e9;
  --border:#393238;--border-i:#766d70;
  --mono:"FiraCode Nerd Font","Fira Code",ui-monospace,"JetBrains Mono",Menlo,monospace;
  --live:#c43b52;
}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:var(--mono);font-size:14px;
  line-height:1.6;padding:40px 26px 110px;-webkit-font-smoothing:antialiased}
.wrap{max-width:1100px;margin:0 auto}
h1{font-size:24px;font-weight:700;margin-bottom:8px}
h1 .d{color:var(--muted);font-weight:400}
.lede{color:var(--muted);max-width:800px;font-size:13.5px}
.lede b{color:var(--text)}
.note{border-left:3px solid var(--accent);background:var(--surface);padding:13px 18px;
  border-radius:0 8px 8px 0;margin:20px 0 40px;max-width:880px;color:var(--muted);font-size:13px}
.note b{color:var(--accent)}

.opt{margin-bottom:62px}
.oh{display:flex;align-items:baseline;gap:13px;margin-bottom:6px;flex-wrap:wrap}
.on{width:30px;height:30px;flex:0 0 30px;border-radius:8px;background:var(--accent);
  color:var(--on-accent);display:grid;place-items:center;font-weight:700;font-size:13px}
.oh h2{font-size:18px;font-weight:700}
.oh .sub{color:var(--dis);font-size:12px}
.od{color:var(--muted);max-width:830px;margin:0 0 16px 43px;font-size:13px}
.od code{color:var(--accent)}
.od b{color:var(--text)}
.why{margin:8px 0 0 43px;padding:9px 14px;border-left:2px solid var(--border-i);
  font-size:12px;color:var(--dis);max-width:830px}
.why b{color:var(--muted)}

.stage{border:1px solid var(--border);border-radius:10px;overflow:hidden;background:#000;
  position:relative;aspect-ratio:16/9}
.shot{position:absolute;inset:0;background-size:cover;background-position:center}

/* ═════ 1 · COLOR WHEEL ═════ */
.w-bg{position:absolute;inset:0;background-size:cover;background-position:center;
  filter:blur(38px) saturate(1.3) brightness(.42);transform:scale(1.15);transition:.5s}
.w-stage{position:absolute;inset:0;display:grid;place-items:center}
.wheel{position:relative;height:86%;aspect-ratio:1}
.wheel svg{position:absolute;inset:0;width:100%;height:100%;overflow:visible}
.wnode{position:absolute;width:15.5%;height:15.5%;border-radius:50%;overflow:hidden;
  transform:translate(-50%,-50%);cursor:pointer;border:2px solid rgba(255,255,255,.14);
  transition:width .3s,height .3s,border-color .3s,box-shadow .3s}
.wnode img{width:100%;height:100%;object-fit:cover;filter:saturate(.55) brightness(.6);transition:.3s}
.wnode.on{width:25%;height:25%;border-color:var(--live);box-shadow:0 0 40px -4px var(--live),0 14px 40px rgba(0,0,0,.7);z-index:5}
.wnode.on img{filter:none}
.wnode:hover{border-color:rgba(255,255,255,.5)}
.w-hub{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);text-align:center;
  z-index:6;pointer-events:none;width:30%}
.w-hub b{display:block;font-size:14px;color:#fff;font-weight:600;overflow:hidden;
  text-overflow:ellipsis;white-space:nowrap}
.w-hub i{font-style:normal;font-size:10.5px;color:rgba(255,255,255,.5);display:block;margin-top:2px}
.w-hub .deg{font-size:24px;font-weight:700;color:var(--live);line-height:1.1}
.w-lbl{position:absolute;font-size:9.5px;color:rgba(255,255,255,.4);letter-spacing:1px;
  text-transform:uppercase;pointer-events:none}
.w-foot{position:absolute;bottom:0;left:0;right:0;padding:12px 22px;z-index:7;
  background:linear-gradient(transparent,rgba(8,7,10,.9));display:flex;gap:16px;
  align-items:center;font-size:10.5px;color:rgba(255,255,255,.55)}
.k{border:1px solid rgba(255,255,255,.28);border-radius:4px;padding:1px 7px;
  font-size:10px;color:rgba(255,255,255,.8);margin-right:4px}

/* ═════ 2 · SPLIT ═════ */
.sp-wrap{position:absolute;inset:0;overflow:hidden}
.sp-half{position:absolute;inset:0;background-size:cover;background-position:center}
.sp-new{clip-path:inset(0 0 0 var(--split))}
.sp-line{position:absolute;top:0;bottom:0;left:var(--split);width:2px;
  background:var(--live);box-shadow:0 0 22px var(--live);z-index:4;cursor:ew-resize}
.sp-grip{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);
  width:34px;height:34px;border-radius:50%;background:var(--live);color:#fff;
  display:grid;place-items:center;font-size:13px;box-shadow:0 4px 16px rgba(0,0,0,.6)}
.sp-tag{position:absolute;top:16px;padding:5px 12px;border-radius:20px;font-size:10.5px;
  font-weight:700;letter-spacing:.8px;backdrop-filter:blur(10px);z-index:5}
.sp-tag.l{left:16px;background:rgba(8,7,10,.72);color:rgba(255,255,255,.62);
  border:1px solid rgba(255,255,255,.18)}
.sp-tag.r{right:16px;background:var(--live);color:#fff}
.sp-barov{position:absolute;left:14px;right:14px;top:52px;height:26px;z-index:6;
  background:rgba(15,13,18,.8);border:1px solid rgba(255,255,255,.14);border-radius:6px;
  display:flex;align-items:center;gap:12px;padding:0 11px;font-size:10px;
  color:rgba(255,255,255,.7);backdrop-filter:blur(10px)}
.sp-barov .ac{color:var(--live);font-weight:700}
.sp-dock{position:absolute;bottom:0;left:0;right:0;z-index:7;padding:11px 16px;
  background:linear-gradient(transparent,rgba(8,7,10,.93) 45%);
  display:flex;align-items:center;gap:9px}
.sp-chip{flex:1;height:34px;border-radius:6px;border:1px solid rgba(255,255,255,.16);
  background:rgba(15,13,18,.7);display:flex;align-items:center;gap:9px;padding:0 11px;
  cursor:pointer;transition:.16s;overflow:hidden;backdrop-filter:blur(8px)}
.sp-chip:hover{border-color:rgba(255,255,255,.45)}
.sp-chip.on{border-color:var(--live);background:rgba(196,59,82,.18)}
.sp-chip .sw{width:16px;height:16px;border-radius:4px;flex:0 0 16px}
.sp-chip span{font-size:10.5px;color:rgba(255,255,255,.82);overflow:hidden;
  text-overflow:ellipsis;white-space:nowrap}
.sp-chip kbd{margin-left:auto;font-size:9px;color:rgba(255,255,255,.4);
  border:1px solid rgba(255,255,255,.2);border-radius:3px;padding:0 5px}

/* ═════ 3 · DIAL ═════ */
.dl-bg{position:absolute;inset:0;background-size:cover;background-position:center;transition:.45s}
.dl-veil{position:absolute;inset:0;background:linear-gradient(90deg,rgba(8,7,10,.92) 0%,
  rgba(8,7,10,.55) 36%,rgba(8,7,10,.22) 58%,rgba(8,7,10,.82) 88%)}
.dl-col{position:absolute;left:0;top:0;bottom:0;width:44%;padding:26px 24px;
  display:flex;flex-direction:column;justify-content:center;gap:16px;z-index:4}
.dl-kicker{font-size:10px;letter-spacing:1.6px;color:var(--live);font-weight:700}
.dl-name{font-size:23px;font-weight:600;color:#fff;line-height:1.2;word-break:break-all}
.dl-meta{font-size:11px;color:rgba(255,255,255,.5)}
.dl-pal{display:flex;gap:4px;margin-top:2px}
.dl-pal i{width:26px;height:26px;border-radius:5px;border:1px solid rgba(255,255,255,.15)}
.dl-track{position:absolute;right:4%;top:9%;bottom:9%;width:96px;z-index:5}
.dl-rail{position:absolute;right:5px;top:0;bottom:0;width:2px;
  background:rgba(255,255,255,.22);border-radius:2px}
.dl-tick{position:absolute;right:0;width:100%;height:40px;transform:translateY(-50%);
  cursor:pointer;display:flex;align-items:center;justify-content:flex-end;gap:7px;
  padding-right:1px;transition:.2s}
.dl-tick .bar{height:2px;background:rgba(255,255,255,.5);border-radius:2px;width:14px;transition:.2s;box-shadow:0 0 6px rgba(0,0,0,.8)}
.dl-tick .dot{width:11px;height:11px;border-radius:50%;border:2px solid rgba(255,255,255,.6);
  background:rgba(8,7,10,.85);transition:.2s;flex:0 0 11px;box-shadow:0 0 8px rgba(0,0,0,.8)}
.dl-tick:hover .bar{width:24px;background:rgba(255,255,255,.7)}
.dl-tick.on .bar{width:32px;height:3px;background:var(--live);box-shadow:0 0 12px var(--live)}
.dl-tick.on .dot{border-color:var(--live);background:var(--live);
  box-shadow:0 0 16px var(--live);transform:scale(1.35)}
.dl-lum{position:absolute;right:12px;top:0;bottom:0;width:3px;border-radius:3px;
  background:linear-gradient(180deg,#f0f0f0,#7a7a7a,#2a2a2a,#000);opacity:.75}
.dl-lumlbl{position:absolute;left:0;font-size:9px;color:rgba(255,255,255,.5);
  letter-spacing:.4px;transform:translateY(-50%);text-align:left;width:34px;
  text-shadow:0 1px 4px rgba(0,0,0,.9);pointer-events:none}
.dl-foot{position:absolute;bottom:0;left:0;right:0;padding:11px 22px;z-index:6;
  background:linear-gradient(transparent,rgba(8,7,10,.9));font-size:10.5px;
  color:rgba(255,255,255,.5);display:flex;gap:16px;align-items:center}

.ctl{display:flex;gap:7px;align-items:center;padding:13px 2px 0;flex-wrap:wrap}
.ctl .lbl{font-size:10px;letter-spacing:1px;color:var(--dis);text-transform:uppercase}
.kb{border:1px solid var(--border-i);background:var(--surface);color:var(--text);
  border-radius:6px;padding:5px 12px;font-family:var(--mono);font-size:12px;cursor:pointer;transition:.14s}
.kb:hover{background:var(--raised);border-color:var(--accent);color:var(--accent)}
.hint{font-size:11px;color:var(--dis);margin-left:auto}

table{width:100%;border-collapse:collapse;font-size:12.5px;border:1px solid var(--border);
  border-radius:8px;overflow:hidden;margin-top:12px}
th,td{padding:10px 13px;text-align:left;border-bottom:1px solid var(--border)}
th{background:var(--raised);font-size:10px;letter-spacing:1px;text-transform:uppercase;color:var(--accent)}
td:first-child{color:var(--muted);white-space:nowrap}
tr:last-child td{border-bottom:0}
.y{color:var(--accent)}.n{color:var(--dis)}
h2.big{font-size:19px;margin:50px 0 8px}
.rec{border:1px solid var(--accent);border-radius:9px;padding:20px 24px;
  background:linear-gradient(135deg,rgba(196,59,82,.1),transparent);margin-top:32px}
.rec h3{font-size:16px;color:var(--accent);margin-bottom:9px}
.rec p{color:var(--muted);font-size:13px}
.rec p+p{margin-top:9px}
.rec code{color:var(--text);background:var(--raised);padding:1px 6px;border-radius:4px;font-size:12px}
.rec b{color:var(--text)}
.rec ol{margin:13px 0 0 20px;color:var(--muted);font-size:13px}
.rec li{margin-bottom:4px}
</style>
</head>
<body>
<div class="wrap">

<h1>Wallpaper picker <span class="d">— три идеи, построенные на свойствах картинки</span></h1>
<p class="lede">Прошлые попытки были карусель, лаунчер и vimium-хинты — заимствования из чужих
интерфейсов. Здесь другое: каждый вариант <b>использует то, чего нет у файлов и приложений</b> —
у обоев есть цвет, яркость и то, что они фон для интерфейса. Всё работает и мышью, и клавишами.</p>

<div class="note">
<b>Общий принцип.</b> Обои выбирают не по имени файла, а по тому, как они будут выглядеть за
баром и окнами. Значит интерфейс должен показывать не список, а <b>результат</b>: цвет, контраст,
как ляжет панель. Три варианта — три способа это показать.
</div>

<!-- ═══ 1 ═══ -->
<section class="opt">
  <div class="oh"><div class="on">1</div><h2>Colour wheel</h2>
    <span class="sub">обои расставлены по цветовому кругу</span></div>
  <p class="od">Файлы разложены не списком, а <b>по кругу — каждый там, где его доминирующий
  оттенок</b>. Твой amber стоит на 44° (тёплое золото), goku на 218° (холодная синь), summer-evening
  и Flux рядом на 252–254° (пурпур). Навигация становится осмысленной: не «следующий файл», а
  «поверни в сторону тёплого». Выбранный узел разрастается, центр показывает угол и палитру,
  фон размывается в текущие обои.</p>
  <p class="why"><b>Почему это ново:</b> ни лаунчер, ни файловый менеджер так не умеют — у
  приложений нет цвета. Расположение здесь несёт информацию, а не просто раскладывает элементы.
  Для 4 файлов круг читается сразу; для 40 — превращается в плотное кольцо, где видно, каких
  оттенков в коллекции не хватает.</p>
  <p class="od" style="margin-top:10px"><b>Мышь:</b> наведение на узел — превью, клик — применить,
  колесо — вращение по кругу. <b>Клавиши:</b> <code>←</code><code>→</code> по кругу,
  <code>enter</code>.</p>
  <div class="stage">
    <div class="w-bg" id="w-bg"></div>
    <div class="w-stage"><div class="wheel" id="wheel">
      <svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="31" fill="none"
        stroke="rgba(255,255,255,.12)" stroke-width=".4" stroke-dasharray="1.6 1.6"/></svg>
      <div class="w-hub"><div class="deg" id="w-deg"></div><b id="w-nm"></b><i id="w-mt"></i></div>
    </div></div>
    <div class="w-foot"><span><span class="k">←</span><span class="k">→</span>по кругу</span>
      <span><span class="k">enter</span>применить</span>
      <span style="margin-left:auto;color:var(--live);font-weight:700" id="w-live"></span></div>
  </div>
  <div class="ctl"><span class="lbl">клавиши</span>
    <button class="kb" data-k="w-prev">←</button><button class="kb" data-k="w-next">→</button>
    <span class="hint">мышью: наведи на узел круга или крути колесо над макетом</span></div>
</section>

<!-- ═══ 2 ═══ -->
<section class="opt">
  <div class="oh"><div class="on">2</div><h2>Split preview</h2>
    <span class="sub">шторка: слева текущие, справа кандидат</span></div>
  <p class="od">Экран разрезан вертикальной шторкой: <b>слева то, что стоит сейчас, справа
  кандидат</b> — обои сравниваются в реальном размере, а не по миниатюрам. Поверх обеих половин
  лежит настоящий макет твоего бара, так что сразу видно, читается ли текст панели на этом фоне.
  Шторка таскается мышью или стрелками; внизу — узкий док имён.</p>
  <p class="why"><b>Почему это ново:</b> единственный вариант, который отвечает на реальный
  вопрос — «лучше ли новые обои текущих?». Сетка и карусель показывают картинку в вакууме,
  а решение всегда сравнительное. Плюс проверка контраста бара — то, из-за чего обои чаще всего
  и меняют обратно.</p>
  <p class="od" style="margin-top:10px"><b>Мышь:</b> таскай шторку, клик по чипу внизу меняет
  кандидата, двойной клик — применить. <b>Клавиши:</b> <code>←</code><code>→</code> шторка,
  <code>↑</code><code>↓</code> кандидат, <code>enter</code>.</p>
  <div class="stage">
    <div class="sp-wrap" id="sp-wrap" style="--split:52%">
      <div class="sp-half" id="sp-old"></div>
      <div class="sp-half sp-new" id="sp-new"></div>
      <div class="sp-tag l">ТЕКУЩИЕ</div>
      <div class="sp-tag r" id="sp-tag-r">КАНДИДАТ</div>
      <div class="sp-barov"><span>󰍹 1 2 3</span><span style="margin-left:auto"></span>
        <span>󰃭 09:21</span><span class="ac">󰸉</span><span>󰂯</span><span>󰕾</span></div>
      <div class="sp-line" id="sp-line"><div class="sp-grip">⇔</div></div>
      <div class="sp-dock" id="sp-dock"></div>
    </div>
  </div>
  <div class="ctl"><span class="lbl">клавиши</span>
    <button class="kb" data-k="s-l">←</button><button class="kb" data-k="s-r">→</button>
    <button class="kb" data-k="s-next">↓ кандидат</button>
    <span class="hint">мышью: тащи шторку за круглую ручку, кликай чипы внизу</span></div>
</section>

<!-- ═══ 3 ═══ -->
<section class="opt">
  <div class="oh"><div class="on">3</div><h2>Luminance dial</h2>
    <span class="sub">вертикальная шкала «светлее ↔ темнее»</span></div>
  <p class="od">Справа — шкала яркости, файлы висят на ней <b>на своей реальной высоте</b>:
  summer-evening наверху (30% яркости), goku в самом низу (6%, почти чёрные). Слева — крупное имя,
  палитра и метаданные на фоне самих обоев. Выбор — это движение по шкале «хочу потемнее»,
  а не перебор файлов.</p>
  <p class="why"><b>Почему это ново:</b> яркость обоев — то, ради чего их реально переключают
  (днём светлее, ночью темнее), но ни один picker её не показывает. Здесь она — сама ось
  навигации. Порядок на шкале стабилен: файл всегда на одном месте, и через неделю рука помнит,
  что тёмное — внизу.</p>
  <p class="od" style="margin-top:10px"><b>Мышь:</b> наведение на риску — превью, клик — применить,
  колесо — вверх-вниз. <b>Клавиши:</b> <code>↑</code><code>↓</code>, <code>enter</code>.</p>
  <div class="stage">
    <div class="dl-bg" id="dl-bg"></div>
    <div class="dl-veil"></div>
    <div class="dl-col">
      <div class="dl-kicker" id="dl-k"></div>
      <div class="dl-name" id="dl-n"></div>
      <div class="dl-meta" id="dl-m"></div>
      <div class="dl-pal" id="dl-p"></div>
    </div>
    <div class="dl-track" id="dl-t"><div class="dl-rail"></div><div class="dl-lum"></div></div>
    <div class="dl-foot"><span><span class="k">↑</span><span class="k">↓</span>по яркости</span>
      <span><span class="k">enter</span>применить</span>
      <span style="margin-left:auto" id="dl-pos"></span></div>
  </div>
  <div class="ctl"><span class="lbl">клавиши</span>
    <button class="kb" data-k="d-up">↑ светлее</button><button class="kb" data-k="d-dn">↓ темнее</button>
    <span class="hint">мышью: наведи на риску справа или крути колесо над макетом</span></div>
</section>

<h2 class="big">Сравнение</h2>
<table>
  <tr><th></th><th>1 · Wheel</th><th>2 · Split</th><th>3 · Dial</th></tr>
  <tr><td>На чём построен</td><td>оттенок (hue)</td><td>сравнение с текущим</td><td>яркость (lum)</td></tr>
  <tr><td>Отвечает на вопрос</td><td class="y">какого цвета?</td><td class="y">лучше ли текущих?</td><td class="y">светлее/темнее?</td></tr>
  <tr><td>Видно бар на фоне</td><td class="n">нет</td><td class="y">да, главное</td><td class="n">частично</td></tr>
  <tr><td>Позиция файла стабильна</td><td class="y">да</td><td class="n">список</td><td class="y">да</td></tr>
  <tr><td>При 40 файлах</td><td class="y">плотное кольцо</td><td class="n">док длинный</td><td class="y">шкала гуще</td></tr>
  <tr><td>Нужна палитра из magick</td><td class="n">да, обязательно</td><td class="y">нет</td><td class="n">да, но дёшево</td></tr>
  <tr><td>Сложность QML</td><td class="n">высокая, Canvas</td><td class="y">низкая, clip</td><td class="y">средняя</td></tr>
</table>

<div class="rec">
  <h3>Рекомендация: Split preview</h3>
  <p>Он единственный отвечает на вопрос, который ты реально задаёшь при смене обоев —
  <b>лучше ли новые текущих</b>, — и единственный показывает бар на фоне кандидата.
  Прошлые варианты (и сетка, и карусель) показывали картинку в вакууме, хотя решение всегда
  сравнительное.</p>
  <p>Технически он же самый дешёвый: два <code>Image</code> и <code>clip</code> по X — никакого
  <code>Canvas</code>, никакого <code>magick</code>, палитра не нужна вообще. Работает на первом
  запуске, без кэша и фоновых процессов.</p>
  <p><b>Wheel</b> — самый красивый и самый рискованный: требует извлечения палитры (~1.4 с/файл,
  замерил на goku), а при 4 файлах круг полупустой — идея раскрывается на 20+. <b>Dial</b>
  хорош как второй режим внутри Split: та же шкала, переключение по <code>Tab</code>.</p>
  <ol>
    <li><b>modules/wallpaper/WallpaperState.qml</b> — скан каталога, список, индекс кандидата</li>
    <li><b>modules/wallpaper/WallpaperPicker.qml</b> — <code>PanelWindow</code> +
      <code>WlrLayer.Overlay</code> + <code>keyboardFocus: Exclusive</code>, как <code>Launcher.qml:60</code>;
      шторка — <code>Item</code> с <code>clip: true</code> и анимируемой шириной</li>
    <li>Макет бара поверх — переиспользовать реальный <code>bar/Bar.qml</code> в режиме превью</li>
    <li>IPC <code>wallpaperToggle()</code> в <code>shell.qml</code> + бинд в Hyprland</li>
  </ol>
  <p style="margin-top:11px;font-size:12px">Не меняется: <code>overlays/Wallpaper.qml</code>,
  <code>ConfigStore.setWallpaper()</code>, <code>validate()</code> — уже готовы.</p>
</div>

</div>
<script>
const W = __DATA__;
const $ = s => document.querySelector(s);
const setLive = c => document.documentElement.style.setProperty('--live', c);

/* ─── 1 · wheel ─── */
let wi = 0;
const wheel = $('#wheel');
W.forEach((w,i)=>{
  const a = (w.hue - 90) * Math.PI/180;
  const n = document.createElement('div');
  n.className = 'wnode'; n.dataset.i = i;
  n.style.left = (50 + 31*Math.cos(a)) + '%';
  n.style.top  = (50 + 31*Math.sin(a)) + '%';
  n.innerHTML = `<img src="${w.img}" alt="">`;
  wheel.appendChild(n);
});
[[0,'0° красный'],[90,'90° зелёный'],[180,'180° голубой'],[270,'270° пурпур']].forEach(([d,t])=>{
  const a=(d-90)*Math.PI/180, l=document.createElement('div');
  l.className='w-lbl'; l.textContent=t;
  l.style.left=(50+44*Math.cos(a))+'%'; l.style.top=(50+44*Math.sin(a))+'%';
  l.style.transform='translate(-50%,-50%)';
  wheel.appendChild(l);
});
function drawWheel(){
  const w = W[wi];
  wheel.querySelectorAll('.wnode').forEach((n,i)=>n.classList.toggle('on', i===wi));
  $('#w-bg').style.backgroundImage = `url('${w.img}')`;
  $('#w-deg').textContent = w.hue + '°';
  $('#w-nm').textContent = w.short;
  $('#w-mt').textContent = w.dim + ' · насыщ. ' + w.sat + '%';
  $('#w-live').textContent = wi===0 ? '● ТЕКУЩИЕ' : '○ ПРЕВЬЮ';
  setLive(w.accent);
}
const byHue = [...W.keys()].sort((a,b)=>W[a].hue-W[b].hue);
function stepWheel(d){ const p=byHue.indexOf(wi); wi=byHue[(p+d+byHue.length)%byHue.length]; drawWheel(); }
wheel.addEventListener('mouseover',e=>{
  const n=e.target.closest('.wnode'); if(!n)return;
  const i=+n.dataset.i; if(i!==wi){ wi=i; drawWheel(); }
});
$('#w-bg').parentElement.addEventListener('wheel',e=>{e.preventDefault();stepWheel(e.deltaY>0?1:-1);},{passive:false});

/* ─── 2 · split ─── */
let si = 1, split = 52;
function drawSplit(){
  const cur = W[0], cand = W[si];
  $('#sp-old').style.backgroundImage = `url('${cur.img}')`;
  $('#sp-new').style.backgroundImage = `url('${cand.img}')`;
  $('#sp-wrap').style.setProperty('--split', split + '%');
  $('#sp-line').style.left = split + '%';
  $('#sp-tag-r').textContent = cand.short.toUpperCase();
  $('#sp-dock').innerHTML = W.map((w,i)=>
    `<div class="sp-chip${i===si?' on':''}" data-i="${i}">
       <span class="sw" style="background:${w.accent}"></span>
       <span>${w.short}</span><kbd>${i+1}</kbd></div>`).join('');
  setLive(cand.accent);
}
$('#sp-dock').addEventListener('click',e=>{
  const c=e.target.closest('.sp-chip'); if(!c)return;
  si=+c.dataset.i; drawSplit();
});
(function(){
  const wrap=$('#sp-wrap'); let drag=false;
  const move=e=>{
    if(!drag)return;
    const r=wrap.getBoundingClientRect();
    split=Math.max(4,Math.min(96,(e.clientX-r.left)/r.width*100));
    drawSplit();
  };
  $('#sp-line').addEventListener('mousedown',e=>{drag=true;e.preventDefault();});
  window.addEventListener('mousemove',move);
  window.addEventListener('mouseup',()=>drag=false);
  wrap.addEventListener('click',e=>{
    if(e.target.closest('.sp-dock')||e.target.closest('.sp-line'))return;
    const r=wrap.getBoundingClientRect();
    split=Math.max(4,Math.min(96,(e.clientX-r.left)/r.width*100)); drawSplit();
  });
})();

/* ─── 3 · dial ─── */
let di = 0;
const byLum = [...W.keys()].sort((a,b)=>W[b].lum-W[a].lum);
const track = $('#dl-t');
const LMAX = 36;
byLum.forEach(i=>{
  const w = W[i];
  const t = document.createElement('div');
  t.className='dl-tick'; t.dataset.i=i;
  t.style.top = (6 + (1 - w.lum/LMAX) * 84) + '%';
  t.innerHTML = `<span class="bar"></span><span class="dot"></span>`;
  track.appendChild(t);
  const l=document.createElement('div');
  l.className='dl-lumlbl'; l.textContent=w.lum+'%';
  l.style.top=t.style.top; track.appendChild(l);
});
function drawDial(){
  const w = W[di];
  $('#dl-bg').style.backgroundImage = `url('${w.img}')`;
  track.querySelectorAll('.dl-tick').forEach(t=>t.classList.toggle('on', +t.dataset.i===di));
  $('#dl-k').textContent = w.lum>=25?'СВЕТЛЫЕ':w.lum>=15?'СРЕДНИЕ':'ТЁМНЫЕ';
  $('#dl-n').textContent = w.short;
  $('#dl-m').textContent = w.dim+' · '+w.size+' · яркость '+w.lum+'%';
  $('#dl-p').innerHTML = w.pal.map(c=>`<i style="background:${c}"></i>`).join('');
  $('#dl-pos').textContent = (byLum.indexOf(di)+1)+' / '+W.length+' по яркости';
  setLive(w.accent);
}
track.addEventListener('mouseover',e=>{
  const t=e.target.closest('.dl-tick'); if(!t)return;
  const i=+t.dataset.i; if(i!==di){ di=i; drawDial(); }
});
function stepDial(d){ const p=byLum.indexOf(di); di=byLum[(p+d+byLum.length)%byLum.length]; drawDial(); }
$('#dl-bg').parentElement.addEventListener('wheel',e=>{e.preventDefault();stepDial(e.deltaY>0?1:-1);},{passive:false});

/* ─── кнопки ─── */
document.querySelectorAll('.kb').forEach(b=>b.addEventListener('click',()=>{
  const k=b.dataset.k;
  if(k==='w-prev')stepWheel(-1); else if(k==='w-next')stepWheel(1);
  else if(k==='s-l'){split=Math.max(4,split-8);drawSplit();}
  else if(k==='s-r'){split=Math.min(96,split+8);drawSplit();}
  else if(k==='s-next'){si=(si+1)%W.length; if(si===0)si=1; drawSplit();}
  else if(k==='d-up')stepDial(-1); else if(k==='d-dn')stepDial(1);
}));

drawWheel(); drawSplit(); drawDial();
window.__ready = true;
</script>
</body>
</html>
""".replace("__DATA__", DATA)

pathlib.Path("index.html").write_text(PAGE, encoding="utf-8")
print("written", len(PAGE))
