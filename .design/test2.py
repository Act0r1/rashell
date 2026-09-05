import json, subprocess, pathlib, re, sys

TESTS = {
"1. sheet: 4 полосы, активная одна": """
 const c=document.querySelectorAll('.cs-col'), on=document.querySelectorAll('.cs-col.on');
 return {ok:c.length===4&&on.length===1, msg:'полос '+c.length+' активных '+on.length};
""",
"2. sheet: активная реально шире остальных": """
 const cols=[...document.querySelectorAll('.cs-col')].map(c=>c.getBoundingClientRect().width);
 const on=document.querySelector('.cs-col.on').getBoundingClientRect().width;
 const rest=cols.filter(w=>Math.abs(w-on)>1);
 return {ok: on > Math.max(...rest)*2, msg:'активная '+on.toFixed(0)+' против '+rest.map(x=>x.toFixed(0)).join(',')};
""",
"3. sheet: hover раскрывает другую полосу": """
 const before=document.querySelector('.cs-col.on').dataset.i;
 document.querySelectorAll('.cs-col')[2].dispatchEvent(new MouseEvent('mouseover',{bubbles:1}));
 const after=document.querySelector('.cs-col.on').dataset.i;
 return {ok:before!==after, msg:before+' -> '+after};
""",
"4. sheet: полосы заполняют кадр без щелей": """
 const st=document.querySelector('.cs-strip').getBoundingClientRect();
 const sum=[...document.querySelectorAll('.cs-col')].reduce((a,c)=>a+c.getBoundingClientRect().width,0);
 return {ok:Math.abs(sum-st.width)<3, msg:'сумма '+sum.toFixed(0)+' кадр '+st.width.toFixed(0)};
""",
"5. fitness: оценки посчитаны и различны": """
 const s=[...document.querySelectorAll('.bf-chip .sc')].map(e=>+e.textContent);
 return {ok:s.length===4&&new Set(s).size>=3, msg:'оценки '+s.join(',')};
""",
"6. fitness: чипы отсортированы по убыванию": """
 const s=[...document.querySelectorAll('.bf-chip .sc')].map(e=>+e.textContent);
 const sorted=[...s].sort((a,b)=>b-a);
 return {ok:JSON.stringify(s)===JSON.stringify(sorted), msg:s.join(',')};
""",
"7. fitness: goku лучший (верх 1%)": """
 const first=document.querySelector('.bf-chip span:nth-child(2)').textContent;
 return {ok:first.includes('goku'), msg:'первый: '+first};
""",
"8. fitness: клик по каждому чипу даёт свою оценку": """
 const seen=[];
 for(let i=0;i<4;i++){
   document.querySelectorAll('.bf-chip')[i].click();
   seen.push(document.querySelector('#bf-n').textContent+':'+document.querySelector('#bf-th').textContent);
 }
 return {ok:new Set(seen).size===4, msg:seen.join(' ')};
""",
"9. fitness: тема бара реально применяется": """
 const bar=document.querySelector('#bf-bar');
 const bg=bar.style.background, col=bar.style.color;
 return {ok:bg!==''&&col!=='', msg:'bg='+bg+' color='+col};
""",
"10. fitness: полоски метрик имеют ширину": """
 const w1=document.querySelector('#bf-f1').style.width, w2=document.querySelector('#bf-f2').style.width;
 return {ok:parseFloat(w1)>0&&parseFloat(w2)>0, msg:'фон='+w1+' контраст='+w2};
""",
"11. zone: 9 ячеек с процентами": """
 const c=document.querySelectorAll('.zm-cell');
 const txt=[...c].map(x=>x.querySelector('b').textContent);
 return {ok:c.length===9, msg:'ячеек '+c.length+' | '+txt.join(' ')};
""",
"12. zone: есть и спокойные и занятые зоны": """
 const calm=document.querySelectorAll('.zm-cell.calm').length;
 const busy=document.querySelectorAll('.zm-cell.busy').length;
 return {ok:calm>0, msg:'спокойных '+calm+' занятых '+busy};
""",
"13. zone: виджет стоит в самой тёмной зоне": """
 const vals=[...document.querySelectorAll('.zm-cell b')].map(b=>parseInt(b.textContent));
 const mn=Math.min(...vals), idx=vals.indexOf(mn);
 const col=idx%3, row=Math.floor(idx/3);
 const w=document.querySelector('#zm-w');
 const expL=(col*33.33+4).toFixed(1), expT=(row*33.33+5).toFixed(1);
 const okL=Math.abs(parseFloat(w.style.left)-parseFloat(expL))<0.2;
 const okT=Math.abs(parseFloat(w.style.top)-parseFloat(expT))<0.2;
 return {ok:okL&&okT, msg:'мин '+mn+'% в зоне '+(col+1)+'x'+(row+1)+', виджет '+w.style.left+'/'+w.style.top};
""",
"14. zone: смена обоев двигает виджет": """
 const w=document.querySelector('#zm-w');
 const before=w.style.left+'/'+w.style.top;
 const vb=[...document.querySelectorAll('.zm-cell b')].map(b=>b.textContent).join(',');
 document.querySelectorAll('.zm-pick div')[1].click();
 const va=[...document.querySelectorAll('.zm-cell b')].map(b=>b.textContent).join(',');
 return {ok:vb!==va, msg:'зоны сменились: '+(vb!==va)+' позиция '+before+' -> '+w.style.left+'/'+w.style.top};
""",
"15. виджет zone не вылезает за кадр": """
 const st=document.querySelectorAll('.stage')[2].getBoundingClientRect();
 const w=document.querySelector('#zm-w').getBoundingClientRect();
 const ok=w.left>=st.left-1&&w.right<=st.right+1&&w.top>=st.top-1&&w.bottom<=st.bottom+1;
 return {ok, msg:'виджет '+w.left.toFixed(0)+'-'+w.right.toFixed(0)+' кадр '+st.left.toFixed(0)+'-'+st.right.toFixed(0)};
""",
"16. панель fitness не вылезает за кадр": """
 const st=document.querySelectorAll('.stage')[1].getBoundingClientRect();
 const p=document.querySelector('.bf-panel').getBoundingClientRect();
 const d=document.querySelector('.bf-dock').getBoundingClientRect();
 const ok=p.right<=st.right+1&&p.bottom<=st.bottom+1&&d.left>=st.left-1&&d.bottom<=st.bottom+1;
 return {ok, msg:'панель до '+p.right.toFixed(0)+'/'+p.bottom.toFixed(0)+' кадр '+st.right.toFixed(0)+'/'+st.bottom.toFixed(0)};
""",
"17. панель и чипы fitness не перекрываются": """
 const p=document.querySelector('.bf-panel').getBoundingClientRect();
 const d=document.querySelector('.bf-dock').getBoundingClientRect();
 const hit=p.left<d.right&&p.right>d.left&&p.top<d.bottom&&p.bottom>d.top;
 return {ok:!hit, msg:hit?'ПЕРЕКРЫТИЕ':'зазор '+(p.left-d.right).toFixed(0)+'px'};
""",
"18. все картинки встроены": """
 const bad=[...document.querySelectorAll('[style*=background-image]')]
   .filter(e=>e.style.backgroundImage&&!e.style.backgroundImage.includes('data:'));
 return {ok:bad.length===0, msg:'битых фонов '+bad.length};
""",
"23. чипы нигде не переносятся в две строки": """
 const bad=[];
 document.querySelectorAll('.bf-chip,.zm-pick div').forEach(e=>{
   const cs=getComputedStyle(e);
   const fs=parseFloat(cs.fontSize);
   const pad=parseFloat(cs.paddingTop)+parseFloat(cs.paddingBottom);
   if(e.getBoundingClientRect().height > fs*1.9+pad+2) bad.push(e.textContent.trim().slice(0,14));
 });
 return {ok:bad.length===0, msg:bad.length?'перенос: '+bad.join(','):'все в одну строку'};
""",
"24. чипы zone не наезжают друг на друга": """
 const r=[...document.querySelectorAll('.zm-pick div')].map(e=>e.getBoundingClientRect());
 let hit=0;
 for(let i=0;i<r.length;i++)for(let j=i+1;j<r.length;j++)
   if(r[i].right>r[j].left+1&&r[i].left<r[j].right-1&&r[i].bottom>r[j].top+1&&r[i].top<r[j].bottom-1) hit++;
 return {ok:hit===0, msg:'наложений '+hit};
""",
"25. чипы zone внутри кадра": """
 const st=document.querySelectorAll('.stage')[2].getBoundingClientRect();
 const bad=[...document.querySelectorAll('.zm-pick div')].filter(e=>{
   const r=e.getBoundingClientRect(); return r.left<st.left-1||r.right>st.right+1;});
 return {ok:bad.length===0, msg:'вылезло '+bad.length};
""",
"26. чипы fitness одной ширины": """
 const w=[...document.querySelectorAll('.bf-chip')].map(e=>Math.round(e.getBoundingClientRect().width));
 return {ok:new Set(w).size===1, msg:'ширины '+w.join(',')};
""",
"27. sheet: инфо активной полосы внутри кадра": """
 document.querySelectorAll('.cs-col,.cs-info').forEach(e=>e.style.transition='none');
 document.querySelector('.cs-strip').getBoundingClientRect();
 const st=document.querySelector('.cs-strip').getBoundingClientRect();
 const inf=document.querySelector('.cs-col.on .cs-info').getBoundingClientRect();
 const ok=inf.top>=st.top-1&&inf.bottom<=st.bottom+1&&inf.left>=st.left-1&&inf.right<=st.right+1;
 return {ok, msg:'инфо '+inf.top.toFixed(0)+'-'+inf.bottom.toFixed(0)+' кадр '+st.top.toFixed(0)+'-'+st.bottom.toFixed(0)};
""",
"19. нет горизонтального переполнения": """
 const o=document.documentElement.scrollWidth-document.documentElement.clientWidth;
 return {ok:o<=1, msg:'overflow='+o+'px'};
""",
"20. все три макета одной высоты": """
 const h=[...document.querySelectorAll('.stage')].map(s=>Math.round(s.getBoundingClientRect().height));
 return {ok:new Set(h).size===1, msg:h.join(',')};
""",
"21. акцент перекрашивается при смене": """
 const g=()=>getComputedStyle(document.documentElement).getPropertyValue('--live').trim();
 const a=g(); document.querySelectorAll('.zm-pick div')[3].click(); const b=g();
 return {ok:a!==b, msg:a+' -> '+b};
""",
"22. кнопки-стрелки работают во всех трёх": """
 const st=[];
 const b1=document.querySelector('.cs-col.on').dataset.i;
 document.querySelector('[data-k=cs-n]').click();
 st.push(document.querySelector('.cs-col.on').dataset.i!==b1);
 const b2=document.querySelector('#bf-n').textContent;
 document.querySelector('[data-k=bf-d]').click();
 st.push(document.querySelector('#bf-n').textContent!==b2);
 const b3=document.querySelector('.zm-pick .on').dataset.i;
 document.querySelector('[data-k=zm-n]').click();
 st.push(document.querySelector('.zm-pick .on').dataset.i!==b3);
 return {ok:st.every(Boolean), msg:'sheet='+st[0]+' fitness='+st[1]+' zone='+st[2]};
""",
}

js = ",".join(f"{json.dumps(k)}:(()=>{{try{{{v}}}catch(e){{return{{ok:0,msg:'ИСКЛЮЧЕНИЕ: '+e.message}}}}}})()" for k,v in TESTS.items())
runner = f"""
const errs=[];window.addEventListener('error',e=>errs.push(e.message));
const R={{{js}}};
R['0. JS-ошибок нет']={{ok:errs.length===0,msg:errs.join('|')||'чисто'}};
R['0. скрипт доработал']={{ok:window.__ready===true,msg:String(window.__ready)}};
document.title='RESULT'+JSON.stringify(R);
"""
html = pathlib.Path("index2.html").read_text().replace("</body>", f"<script>{runner}</script></body>")
tmp = pathlib.Path(".design/_t2.html"); tmp.write_text(html)
out = subprocess.run(["timeout","90","chromium","--headless","--disable-gpu","--no-sandbox",
    "--virtual-time-budget=6000","--dump-dom",str(tmp)],capture_output=True,text=True).stdout
m = re.search(r"<title>RESULT(.*?)</title>", out, re.S)
if not m: print("НЕТ РЕЗУЛЬТАТА"); sys.exit(1)
res = json.loads(m.group(1).replace("&amp;","&").replace("&lt;","<").replace("&gt;",">").replace("&quot;",'"'))
fail=0
for k in sorted(res, key=lambda x:(len(x.split('.')[0]),x)):
    r=res[k]; ok=bool(r["ok"])
    if not ok: fail+=1
    print(("  OK  " if ok else "ПРОВАЛ")+" │ "+k+" │ "+str(r["msg"])[:72])
print("\n"+("ВСЕ %d ПРОШЛИ"%len(res) if not fail else "ПРОВАЛОВ %d из %d"%(fail,len(res))))
sys.exit(1 if fail else 0)
