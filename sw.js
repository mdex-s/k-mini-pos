const CACHE="kooo-cloud-v3-shell";
const SDK="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2";
const FILES=["./","./index.html","./css/style.css","./js/config.js","./js/app.js","./manifest.webmanifest","./assets/icon.svg",SDK];
self.addEventListener("install",e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(FILES))));
self.addEventListener("activate",e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k))))));
self.addEventListener("fetch",e=>{if(e.request.method!=="GET")return;const u=new URL(e.request.url);if(u.origin===location.origin||e.request.url===SDK){e.respondWith(caches.match(e.request).then(x=>x||fetch(e.request).then(r=>{let copy=r.clone();caches.open(CACHE).then(c=>c.put(e.request,copy));return r}).catch(()=>caches.match("./index.html"))))}});