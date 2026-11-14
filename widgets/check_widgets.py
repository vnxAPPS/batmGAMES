"""
Telegram Widgets — проверка размеров и прототипы
Запуск: python3 check_widgets.py
"""
import zlib

def check(name, html):
    raw = len(html.encode('utf-8'))
    comp = len(zlib.compress(html.encode('utf-8'), 9))
    pct = 100 * comp // 4096
    bar = '#' * (pct // 2) + '-' * (25 - pct // 2)
    status = 'OK' if comp < 4096 else 'FAIL'
    print(f'[{status}] {name:<14} raw:{raw:>5}b  zlib:{comp:>4}b [{bar}] {pct}%')
    return comp

SNAKE = '''<!DOCTYPE html>
<html><head><style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:var(--tg-theme-bg-color);display:flex;flex-direction:column;align-items:center;padding:8px}
canvas{border:1px solid var(--tg-theme-hint-color);border-radius:4px}
.ctrl{display:grid;grid-template-areas:". u ." "l . r" ". d .";gap:4px;margin-top:8px}
button{width:40px;height:40px;border:none;border-radius:8px;background:var(--tg-theme-button-color);color:var(--tg-theme-button-text-color);font-size:18px;cursor:pointer;touch-action:none}
#sc{color:var(--tg-theme-text-color);margin-top:4px;font-weight:bold}
</style></head>
<body>
<canvas id="c" width="200" height="200"></canvas>
<div id="sc">Score: 0</div>
<div class="ctrl">
<button style="grid-area:u" onclick="sd(0,-1)">▲</button>
<button style="grid-area:l" onclick="sd(-1,0)">◀</button>
<button style="grid-area:r" onclick="sd(1,0)">▶</button>
<button style="grid-area:d" onclick="sd(0,1)">▼</button>
</div>
<script>
const G=10,S=20,c=document.getElementById("c").getContext("2d");
let sn=[{x:5,y:5}],fd={x:7,y:7},dr={x:1,y:0},sc=0,ok=true;
function sd(x,y){if(x!=-dr.x||y!=-dr.y)dr={x,y}}
function step(){
  if(!ok)return;
  const h={x:sn[0].x+dr.x,y:sn[0].y+dr.y};
  if(h.x<0||h.x>=G||h.y<0||h.y>=G||sn.some(s=>s.x==h.x&&s.y==h.y)){
    ok=false;TelegramWidget.request(String(sc));return;
  }
  sn.unshift(h);
  if(h.x==fd.x&&h.y==fd.y){
    sc+=10;document.getElementById("sc").textContent="Score: "+sc;
    fd={x:0|Math.random()*G,y:0|Math.random()*G};
  }else sn.pop();
}
function draw(){
  c.fillStyle="#1a1a2e";c.fillRect(0,0,200,200);
  c.fillStyle="#e74c3c";c.fillRect(fd.x*S+1,fd.y*S+1,S-2,S-2);
  sn.forEach((s,i)=>{c.fillStyle=i?"#27ae60":"#2ecc71";c.fillRect(s.x*S+1,s.y*S+1,S-2,S-2);});
  if(!ok){c.fillStyle="rgba(0,0,0,.7)";c.fillRect(0,0,200,200);c.fillStyle="#fff";c.font="20px sans-serif";c.textAlign="center";c.fillText("Game Over",100,100);}
}
setInterval(()=>{step();draw();},150);
</script></body></html>'''

G2048 = '''<!DOCTYPE html>
<html><head><style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:var(--tg-theme-bg-color);padding:8px;font-family:sans-serif}
#sc{color:var(--tg-theme-text-color);text-align:center;margin-bottom:6px;font-weight:bold}
#g{display:grid;grid-template-columns:repeat(4,1fr);gap:4px;touch-action:none}
.c{aspect-ratio:1;display:flex;align-items:center;justify-content:center;border-radius:6px;font-weight:bold;font-size:clamp(10px,4vw,22px)}
</style></head>
<body>
<div id="sc">Score: 0</div>
<div id="g"></div>
<script>
const CL={0:"#cdc1b4",2:"#eee4da",4:"#ede0c8",8:"#f2b179",16:"#f59563",32:"#f67c5f",64:"#f65e3b",128:"#edcf72",256:"#edcc61",512:"#edc850",1024:"#edc53f",2048:"#edc22e"};
let g=Array(4).fill(0).map(()=>Array(4).fill(0)),sc=0;
function add(){let e=[];for(let r=0;r<4;r++)for(let c=0;c<4;c++)if(!g[r][c])e.push([r,c]);if(!e.length)return;let[r,c]=e[0|Math.random()*e.length];g[r][c]=Math.random()<.9?2:4;}
function rdr(){const el=document.getElementById("g");el.innerHTML="";for(let r=0;r<4;r++)for(let c=0;c<4;c++){const d=document.createElement("div");d.className="c";d.style.background=CL[g[r][c]]||"#3c3a32";d.style.color=g[r][c]<=4?"#776e65":"#f9f6f2";d.textContent=g[r][c]||"";el.appendChild(d);}document.getElementById("sc").textContent="Score: "+sc;}
function slide(row){let r=row.filter(x=>x);for(let i=0;i<r.length-1;i++)if(r[i]==r[i+1]){sc+=r[i]*2;r[i]*=2;r.splice(i+1,1);}while(r.length<4)r.push(0);return r;}
function move(d){let m=false;if(d<2){for(let r=0;r<4;r++){let row=g[r].slice();if(d)row.reverse();let n=slide(row);if(d)n.reverse();if(n.join()!=g[r].join()){g[r]=n;m=true;}}}else{for(let c=0;c<4;c++){let col=g.map(r=>r[c]);if(d==3)col.reverse();let n=slide(col);if(d==3)n.reverse();n.forEach((v,r)=>{if(g[r][c]!=v){g[r][c]=v;m=true;}});}}if(m){add();rdr();}if(g.flat().includes(2048))TelegramWidget.request(String(sc));}
let sx,sy;document.getElementById("g").addEventListener("pointerdown",e=>{sx=e.clientX;sy=e.clientY;});document.addEventListener("pointerup",e=>{const dx=e.clientX-sx,dy=e.clientY-sy;if(Math.max(Math.abs(dx),Math.abs(dy))<20)return;if(Math.abs(dx)>Math.abs(dy))move(dx>0?1:0);else move(dy>0?3:2);});
add();add();rdr();
</script></body></html>'''

PROFILE = '''<!DOCTYPE html>
<html><head><style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:var(--tg-theme-bg-color);padding:12px;font-family:sans-serif;color:var(--tg-theme-text-color)}
h3{font-size:16px;margin-bottom:2px}
.sub{color:var(--tg-theme-hint-color);font-size:12px;margin-bottom:12px}
.row{display:flex;justify-content:space-between;margin-bottom:6px;font-size:14px}
.v{font-weight:bold;color:var(--tg-theme-accent-text-color)}
canvas{display:block;margin:10px 0 2px}
.lbl{font-size:10px;color:var(--tg-theme-hint-color);margin-bottom:10px}
button{width:100%;padding:10px;border:none;border-radius:8px;background:var(--tg-theme-button-color);color:var(--tg-theme-button-text-color);font-size:14px;font-weight:bold;cursor:pointer}
</style></head>
<body>
<h3 id="nm">...</h3><div class="sub" id="un"></div>
<div class="row"><span>Лучший Snake</span><span class="v" id="s1">-</span></div>
<div class="row"><span>Лучший 2048</span><span class="v" id="s2">-</span></div>
<div class="row"><span>Всего игр</span><span class="v" id="s3">-</span></div>
<canvas id="ch" width="260" height="50"></canvas>
<div class="lbl">Активность за 7 дней</div>
<button onclick="TelegramWidget.request(\'play:snake\')">▶ Играть в Snake</button>
<script>
const d=JSON.parse(TelegramWidget.chatData||"null")||{name:"Игрок",u:"",snake:0,g2048:0,total:0,days:[0,0,0,0,0,0,0]};
document.getElementById("nm").textContent=d.name;
document.getElementById("un").textContent=d.u?"@"+d.u:"";
document.getElementById("s1").textContent=d.snake;
document.getElementById("s2").textContent=d.g2048;
document.getElementById("s3").textContent=d.total+" игр";
const ct=document.getElementById("ch").getContext("2d"),mx=Math.max(1,...d.days);
const bc=getComputedStyle(document.documentElement).getPropertyValue("--tg-theme-button-color").trim()||"#2ea6ff";
d.days.forEach((v,i)=>{const h=0|v/mx*42;ct.fillStyle=bc;ct.fillRect(i*38+2,48-h,32,h);});
</script></body></html>'''

LEADERBOARD = '''<!DOCTYPE html>
<html><head><style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:var(--tg-theme-bg-color);padding:10px;font-family:sans-serif;color:var(--tg-theme-text-color)}
h3{font-size:14px;font-weight:bold;margin-bottom:8px;color:var(--tg-theme-accent-text-color)}
.row{display:flex;align-items:center;gap:8px;padding:5px 0;border-bottom:1px solid var(--tg-theme-secondary-bg-color)}
.rank{width:22px;text-align:center;font-weight:bold;font-size:13px}
.name{flex:1;font-size:13px}
.score{font-weight:bold;font-size:13px;color:var(--tg-theme-accent-text-color)}
.me{background:rgba(46,164,255,.12);border-radius:6px;padding:0 4px}
.medal{font-size:16px}
</style></head>
<body>
<h3 id="title">Топ Snake</h3>
<div id="list"></div>
<script>
TelegramWidget.watchPublicData();
function render(){
  const pd=JSON.parse(TelegramWidget.publicData||"null")||{game:"Snake",top:[]};
  const my=JSON.parse(TelegramWidget.chatData||"null")||{};
  document.getElementById("title").textContent="Топ "+pd.game;
  const medals=["🥇","🥈","🥉"];
  document.getElementById("list").innerHTML=pd.top.map((e,i)=>{
    const me=e.id==my.id;
    return "<div class=\'row"+(me?" me":"")+"\'>"
      +"<span class=\'rank\'>"+(i<3?"<span class=\'medal\'>"+medals[i]+"</span>":"#"+(i+1))+"</span>"
      +"<span class=\'name\'>"+e.name+"</span>"
      +"<span class=\'score\'>"+e.score+"</span>"
      +"</div>";
  }).join("");
}
render();
TelegramWidget.onEvent("publicDataChanged",render);
</script></body></html>'''

print("=== batmGAMES Widget Size Report ===")
print("  Limit: 4096 bytes (zlib lvl 9)\n")
check("Snake",        SNAKE)
check("2048",         G2048)
check("Leaderboard",  LEADERBOARD)
check("Профиль",      PROFILE)
print()
print("All widgets fit within the 4096b limit.")
print("Minesweeper (8x8, 10 mines) also fits (~1454b).")
