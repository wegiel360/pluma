'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "0bc3a1a6a225b5830e146869419b4226",
"assets/AssetManifest.bin.json": "537db526deb43196c2c97829d0132cef",
"assets/FontManifest.json": "0a6aab104d6bf7a8203f73f0624520a8",
"assets/NOTICES": "8f314facbe870b7726e2a09ad1a60b38",
"assets/assets/bliss-1024p.jpg": "1ad16cf1fe30bdd24fad9b975a4c6510",
"assets/assets/default-pfp.png": "e49a254eff49ecbbf2744aac41d6f380",
"assets/assets/fonts/NotoColorEmoji.ttf": "46d5c51b979f91964c084f9ddd0af9fa",
"assets/assets/fonts/Ubuntu-Bold.ttf": "896a60219f6157eab096825a0c9348a8",
"assets/assets/fonts/Ubuntu-BoldItalic.ttf": "4b926632fb7674f562c821d7d881f11a",
"assets/assets/fonts/Ubuntu-Italic.ttf": "54ed64df032e0c0d1dd36c2839890d69",
"assets/assets/fonts/Ubuntu-Light.ttf": "c9d68f61bf89fde6a24da697bc45d6f9",
"assets/assets/fonts/Ubuntu-LightItalic.ttf": "267b80deff5315fc57e39bc7d26e9fcf",
"assets/assets/fonts/Ubuntu-Medium.ttf": "d3c3b35e6d478ed149f02fad880dd359",
"assets/assets/fonts/Ubuntu-MediumItalic.ttf": "89af35d9567dcc3a76f3db4f9544658b",
"assets/assets/fonts/Ubuntu-Regular.ttf": "2bbbdb8c03d2056361ebdf3d31c6d03f",
"assets/assets/logo-kogut-1000x1000.png": "67f790046ab81940d9213b45cab2585c",
"assets/assets/logo-kogut-100x100.png": "2f596cc777967b7f4665f034a20f734c",
"assets/assets/logo-kogut-200x200.png": "6116beb378eeea562fc04ab9fc5db1da",
"assets/assets/logo-kogut-250x250.png": "a28db96d66efbd401d10fb7ae1cf8b4e",
"assets/assets/logo-kogut-500x500.png": "1be82c64a9185015e9e192aa35641984",
"assets/assets/logo-kogut-64x64.png": "72528ba55710eba13898e64fc77d9593",
"assets/assets/logo-pluma.png": "77a4ee3d3d024b7aa76d193a28a35a80",
"assets/fonts/MaterialIcons-Regular.otf": "ff4f826e9283a693a744dbdd0e23505e",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/stretch_effect.frag": "f0ab847ccb98001d214e09f120664284",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.json": "8ecba2e2c0e12a23dc43d29312756939",
"canvaskit/canvaskit.js": "6cfe36b4647fbfa15683e09e7dd366bc",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js": "ba4a8ae1a65ff3ad81c6818fd47e348b",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/experimental_webparagraph/canvaskit.js": "230c0e2b182dcd1061c06c2fe7b64b5f",
"canvaskit/experimental_webparagraph/canvaskit.js.symbols": "0c6d97b036dffdc0f4bc4552ae7b5c9d",
"canvaskit/experimental_webparagraph/canvaskit.wasm": "e008e87c245b0718932b34e9a15be803",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm_heavy.js": "19b2126c270db6dde2255bec30c3e4f9",
"canvaskit/skwasm_heavy.js.symbols": "455930e12e6ef2d961627fe6f0c0cd0c",
"canvaskit/skwasm_heavy.wasm": "f22698a773ef756eff818039e37be5c3",
"canvaskit/wimp.js": "40195751139ab9e4b7c62b19c420f63b",
"canvaskit/wimp.js.symbols": "e9ac11318ebff9b7ad24ca7841f69b3f",
"canvaskit/wimp.wasm": "9242e201530449825b5645ed3d5af22c",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"flutter_bootstrap.js": "1978c890cd260a022551a35d97f077df",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "831aa907d47b9c5937d9b3a49810991b",
"/": "831aa907d47b9c5937d9b3a49810991b",
"main.dart.js": "5e99c58b8b42c1c7423a0ac825291713",
"manifest.json": "ff01f7bf070c45f2758b0797c90325d4",
"version.json": "b1a4e57cd3f01f06e8868ab0d9350d19",
"ziemniak.html": "2a957443cf1bf77dcc54e83dfd930443"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
