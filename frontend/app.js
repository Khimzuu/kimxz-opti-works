'use strict';
const modes=[
{id:'quick',icon:'ϟ',name:'QUICK BOOST',description:'Safe cleanup, DNS refresh, startup workload assessment.',tags:['STARTUP','CLEANUP','DIAGNOSTICS']},
{id:'balanced',icon:'▥',name:'BALANCED OPTIMIZE',description:'Recommended: quick tasks plus reversible visuals and storage assessment.',tags:['VISUALS','STORAGE','CLEANUP','BASELINE']},
{id:'gaming',icon:'⌘',name:'GAMING FOCUS',description:'Game Mode preference, low-overhead visuals and background workload report.',tags:['GAMING','VISUALS','STARTUP','POWER']},
{id:'deep',icon:'⚙',name:'DEEP PERFORMANCE TUNE',description:'Broader supported tasks including Windows-managed drive optimization.',tags:['STORAGE','VISUALS','GAMING','DRIVE OPTIMIZE']}
];
const groups=[
{id:'cleanup',name:'SYSTEM CLEANUP',desc:'Remove older temporary files, refresh DNS, collect disk-space report.',tags:['TEMP','DNS','REPORT']},
{id:'visuals',name:'PERFORMANCE & VISUALS',desc:'Save originals and select lower-overhead Windows visual preferences.',tags:['REVERSIBLE','UI']},
{id:'storage',name:'STORAGE OPTIMIZATION',desc:'Examine volumes and request supported media-aware Windows drive optimization.',tags:['ADMIN','DRIVE']},
{id:'gaming-group',name:'GAMING OPTIMIZATION',desc:'Enable Game Mode and collect startup/power workload information.',tags:['GAME MODE','STARTUP']},
{id:'power',name:'POWER & STARTUP',desc:'Read power plan and startup items; never disable services blindly.',tags:['REPORT','NO FORCE']},
{id:'diagnostics',name:'DIAGNOSTICS & RECOVERY',desc:'Collect OS, CPU, memory, drives, and power-plan details.',tags:['INVENTORY','HEALTH']}
];
let busy=false;let lastSignature='';
const $=s=>document.querySelector(s);
function safe(s){return String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}
$('#modeCards').innerHTML=modes.map(m=>`<article class="modeCard"><div class="modeIcon">${m.icon}</div><div><h2>${safe(m.name)}</h2><p>${safe(m.description)}</p><div class="tags">${m.tags.map(t=>`<span>${safe(t)}</span>`).join('')}</div></div><button class="primary" data-run="${m.id}">RUN PRESET &nbsp; →</button></article>`).join('');
$('#manualCards').innerHTML=groups.map(g=>`<article class="manualCard"><h2>${safe(g.name)}</h2><p>${safe(g.desc)}</p><div class="tags">${g.tags.map(t=>`<span>${safe(t)}</span>`).join('')}</div><button class="primary" data-run="${g.id}">RUN GROUP →</button></article>`).join('');
function navigate(page){document.querySelectorAll('.page').forEach(e=>e.classList.toggle('active',e.id===page));document.querySelectorAll('nav button').forEach(e=>e.classList.toggle('selected',e.dataset.nav===page));$('#breadcrumb').textContent=page.toUpperCase();}
function send(m){if(!window.chrome?.webview){displayError('Open this application through Launch-kim.xz.bat on Windows.');return;}window.chrome.webview.postMessage(m);}
function displayError(msg){$('#runInfo').textContent=msg;$('#runState').textContent='ERROR';$('#light').className='dot error';}
function setBusy(b){busy=b;document.querySelectorAll('[data-run]').forEach(x=>x.disabled=b);$('#light').className='dot'+(b?' busy':'');$('#runState').textContent=b?'RUNNING':'READY';}
document.body.addEventListener('click',e=>{let target=e.target.closest('button');if(!target)return;if(target.dataset.nav)navigate(target.dataset.nav);if(target.dataset.run&&!busy){$('#logLines').innerHTML='';lastSignature='';send({type:'run',id:target.dataset.run});}if(target.id==='openLogs')send({type:'openLogs'});if(target.id==='startup')send({type:'openStartup'});});
if(window.chrome?.webview){window.chrome.webview.addEventListener('message',event=>{let m=event.data;if(m.type==='started'){setBusy(true);$('#runInfo').textContent='Executing '+m.id+' — results are being logged.';}
if(m.type==='error')displayError(m.message);
if(m.type==='events'){
 const events=m.events||[];
 const sig=JSON.stringify(events);
 if(sig===lastSignature)return;lastSignature=sig;
 $('#logLines').innerHTML=events.map(x=>`<div class="logLine ${safe(x.status)}">${safe(x.at||'')} · ${safe(x.operation)} · ${safe(x.status)} — ${safe(x.detail)}</div>`).join('');
 const last=events.at(-1);if(last){$('#runInfo').textContent=`${last.operation}: ${last.status}`;}
 const inv=events.find(e=>e.operation==='inventory'&&e.status==='success');if(inv){try{$('#systemReport').textContent=JSON.stringify(JSON.parse(inv.detail),null,2);}catch{$('#systemReport').textContent=inv.detail;}}
 if(events.some(x=>x.status==='failure'))$('#light').className='dot error';
 }
 if(m.type==='ended'){setBusy(false);if(m.exitCode!==0)displayError('Task finished with one or more failures. See Execution Logs.');else{$('#runState').textContent='COMPLETE';$('#runInfo').textContent='Task completed; see logs for individual operations.';}}
 });}
