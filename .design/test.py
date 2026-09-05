import json, subprocess, pathlib, tempfile, sys

# Тесты: каждый — JS, возвращающий {ok:bool, msg:str}
TESTS = {
"1. wheel: узлы созданы и стоят по hue": """
 const n=[...document.querySelectorAll('.wnode')];
 if(n.length!==4) return {ok:0,msg:'узлов '+n.length};
 const amber=n[1].style.left, goku=n[3].style.left;
 return {ok: amber!==goku && amber!=='', msg:'amber@'+amber+' goku@'+goku};
""",
"2. wheel: hover на узел меняет центр": """
 const before=document.querySelector('#w-nm').textContent;
 document.querySelectorAll('.wnode')[3].dispatchEvent(new MouseEvent('mouseover',{bubbles:1}));
 const after=document.querySelector('#w-nm').textContent;
 return {ok: before!==after, msg:before+' -> '+after};
""",
"3. wheel: кнопка → листает по кругу": """
 const b=document.querySelector('[data-k=w-next]');
 const before=document.querySelector('#w-deg').textContent;
 b.click();
 const after=document.querySelector('#w-deg').textContent;
 return {ok: before!==after, msg:before+' -> '+after};
""",
"4. wheel: активный узел ровно один": """
 const on=document.querySelectorAll('.wnode.on').length;
 return {ok:on===1, msg:'активных '+on};
""",
"5. split: обе половины имеют картинки": """
 const a=document.querySelector('#sp-old').style.backgroundImage;
 const b=document.querySelector('#sp-new').style.backgroundImage;
 return {ok: a.length>50 && b.length>50 && a!==b, msg:'old='+a.length+' new='+b.length+' разные='+(a!==b)};
""",
"6. split: клик по чипу меняет кандидата": """
 const before=document.querySelector('#sp-new').style.backgroundImage;
 document.querySelectorAll('.sp-chip')[2].click();
 const after=document.querySelector('#sp-new').style.backgroundImage;
 const tag=document.querySelector('#sp-tag-r').textContent;
 return {ok: before!==after, msg:'tag='+tag+' сменилось='+(before!==after)};
""",
"7. split: кнопка → двигает шторку": """
 const w=document.querySelector('#sp-wrap');
 const before=w.style.getPropertyValue('--split');
 document.querySelector('[data-k=s-r]').click();
 const after=w.style.getPropertyValue('--split');
 const line=document.querySelector('#sp-line').style.left;
 return {ok: before!==after && line===after, msg:before+' -> '+after+' линия='+line};
""",
"8. split: clip-path реально применён": """
 const el=document.querySelector('#sp-new');
 const cp=getComputedStyle(el).clipPath;
 return {ok: cp && cp!=='none', msg:'clip-path='+cp};
""",
"9. dial: риски на разной высоте по яркости": """
 const t=[...document.querySelectorAll('.dl-tick')];
 if(t.length!==4) return {ok:0,msg:'рисок '+t.length};
 const tops=t.map(x=>parseFloat(x.style.top));
 const sorted=[...tops].sort((a,b)=>a-b);
 return {ok: new Set(tops).size===4, msg:'высоты '+tops.map(x=>x.toFixed(0)).join(',')};
""",
"10. dial: hover на риску меняет имя": """
 const before=document.querySelector('#dl-n').textContent;
 document.querySelectorAll('.dl-tick')[3].dispatchEvent(new MouseEvent('mouseover',{bubbles:1}));
 const after=document.querySelector('#dl-n').textContent;
 return {ok: before!==after, msg:before+' -> '+after};
""",
"11. dial: обе кнопки двигают выбор, край зациклен": """
 const pos=()=>document.querySelector('#dl-pos').textContent;
 const seen=new Set();
 for(let i=0;i<6;i++){ document.querySelector('[data-k=d-dn]').click(); seen.add(pos()); }
 const down=seen.size;
 const before=pos(); document.querySelector('[data-k=d-up]').click();
 return {ok: down===4 && pos()!==before, msg:'вниз посетил '+down+'/4, вверх: '+before+' -> '+pos()};
""",
"12. dial: активная риска ровно одна": """
 const on=document.querySelectorAll('.dl-tick.on').length;
 return {ok:on===1, msg:'активных '+on};
""",
"13. акцент --live перекрашивается": """
 const get=()=>getComputedStyle(document.documentElement).getPropertyValue('--live').trim();
 const a=get();
 document.querySelectorAll('.wnode')[1].dispatchEvent(new MouseEvent('mouseover',{bubbles:1}));
 const b=get();
 return {ok: a!==b && b!=='', msg:a+' -> '+b};
""",
"14. все картинки встроены (нет битых src)": """
 const imgs=[...document.querySelectorAll('img')];
 const bad=imgs.filter(i=>!i.src.startsWith('data:'));
 const bgs=[...document.querySelectorAll('[style*=background-image]')]
   .filter(e=>!e.style.backgroundImage.includes('data:'));
 return {ok: bad.length===0 && bgs.length===0, msg:'img='+imgs.length+' битых='+bad.length+' bg-битых='+bgs.length};
""",
"16. wheel: узлы круглые, не сплющены": """
 const bad=[...document.querySelectorAll('.wnode')].filter(n=>{
   const r=n.getBoundingClientRect();
   return Math.abs(r.width-r.height) > 2;
 });
 const r0=document.querySelector('.wnode').getBoundingClientRect();
 return {ok:bad.length===0, msg:'сплющенных '+bad.length+', размер '+r0.width.toFixed(0)+'x'+r0.height.toFixed(0)};
""",
"17. wheel: ни один узел не вылез за кадр": """
 const st=document.querySelector('.w-stage').getBoundingClientRect();
 const out=[...document.querySelectorAll('.wnode')].filter(n=>{
   const r=n.getBoundingClientRect();
   return r.top<st.top-1||r.bottom>st.bottom+1||r.left<st.left-1||r.right>st.right+1;
 });
 return {ok:out.length===0, msg:'вылезло '+out.length+' из 4'};
""",
"18. wheel: активный узел тоже в кадре": """
 document.querySelectorAll('.wnode')[0].dispatchEvent(new MouseEvent('mouseover',{bubbles:1}));
 const st=document.querySelector('.w-stage').getBoundingClientRect();
 const n=document.querySelector('.wnode.on').getBoundingClientRect();
 const ok=n.top>=st.top-1&&n.bottom<=st.bottom+1;
 return {ok, msg:'узел '+n.top.toFixed(0)+'-'+n.bottom.toFixed(0)+' кадр '+st.top.toFixed(0)+'-'+st.bottom.toFixed(0)};
""",
"19. все три макета одинаковой высоты (не разъезжаются)": """
 const h=[...document.querySelectorAll('.stage')].map(s=>Math.round(s.getBoundingClientRect().height));
 return {ok:new Set(h).size===1, msg:'высоты '+h.join(',')};
""",
"20. текст нигде не наезжает на край кадра": """
 const bad=[];
 document.querySelectorAll('.stage').forEach(st=>{
   const r=st.getBoundingClientRect();
   st.querySelectorAll('.w-hub b,.dl-name,.sp-chip span').forEach(e=>{
     const t=e.getBoundingClientRect();
     if(t.left<r.left-1||t.right>r.right+1) bad.push(e.className||e.tagName);
   });
 });
 return {ok:bad.length===0, msg:bad.length?bad.join(','):'всё внутри'};
""",
"21. dial: метки процентов не налезают на точки": """
 const lbls=[...document.querySelectorAll('.dl-lumlbl')];
 const dots=[...document.querySelectorAll('.dl-tick .dot')];
 let hit=0;
 lbls.forEach(l=>{const a=l.getBoundingClientRect();
   dots.forEach(d=>{const b=d.getBoundingClientRect();
     if(a.right>b.left&&a.left<b.right&&a.bottom>b.top&&a.top<b.bottom) hit++;});});
 return {ok:hit===0, msg:'пересечений '+hit+' (меток '+lbls.length+')'};
""",
"22. dial: шкала внутри кадра": """
 const st=document.querySelectorAll('.stage')[2].getBoundingClientRect();
 const tr=document.querySelector('.dl-track').getBoundingClientRect();
 const ok=tr.right<=st.right+1&&tr.left>=st.left-1&&tr.top>=st.top-1&&tr.bottom<=st.bottom+1;
 return {ok, msg:'трек '+tr.left.toFixed(0)+'-'+tr.right.toFixed(0)+' кадр '+st.left.toFixed(0)+'-'+st.right.toFixed(0)};
""",
"15. нет горизонтального переполнения": """
 const o=document.documentElement.scrollWidth-document.documentElement.clientWidth;
 return {ok:o<=1, msg:'overflow='+o+'px'};
""",
}

js_tests = ",".join(f"{json.dumps(k)}:(()=>{{try{{{v}}}catch(e){{return{{ok:0,msg:'ИСКЛЮЧЕНИЕ: '+e.message}}}}}})()" for k,v in TESTS.items())
runner = f"""
const errs=[];
window.addEventListener('error',e=>errs.push(e.message));
const R={{{js_tests}}};
R['0. JS-ошибок нет']={{ok:errs.length===0,msg:errs.join('|')||'чисто'}};
R['0. скрипт доработал до конца']={{ok:window.__ready===true,msg:String(window.__ready)}};
document.title='RESULT'+JSON.stringify(R);
"""
html = pathlib.Path("index.html").read_text()
html = html.replace("</body>", f"<script>{runner}</script></body>")
tmp = pathlib.Path(".design/_test.html"); tmp.write_text(html)

out = subprocess.run(["timeout","90","chromium","--headless","--disable-gpu","--no-sandbox",
    "--virtual-time-budget=6000","--dump-dom",str(tmp)],capture_output=True,text=True).stdout
import re
m = re.search(r"<title>RESULT(.*?)</title>", out, re.S)
if not m:
    print("НЕ УДАЛОСЬ ПОЛУЧИТЬ РЕЗУЛЬТАТ"); sys.exit(1)
res = json.loads(m.group(1).replace("&amp;","&").replace("&lt;","<").replace("&gt;",">").replace("&quot;",'"'))
fail=0
for k in sorted(res):
    r=res[k]
    ok=bool(r["ok"])
    if not ok: fail+=1
    print(("  OK  " if ok else "ПРОВАЛ")+" │ "+k+" │ "+str(r["msg"])[:70])
print("\n"+("ВСЕ %d ТЕСТОВ ПРОШЛИ"%len(res) if not fail else "ПРОВАЛОВ: %d из %d"%(fail,len(res))))
sys.exit(1 if fail else 0)
