# WoofCare web deployment

WoofCare compiles to a static single-page application in `build/web`. Cloudflare
Pages is the recommended host because it serves static assets from its global
network, has automatic SPA fallback behavior, and does not require a paid
always-on application server.

## Local production build

Create a dedicated Google Maps JavaScript API browser key. Enable the Maps
JavaScript API and restrict the key by HTTP referrer to the production and
preview domains. Do not reuse the Android- or iOS-restricted key.

```bash
export GOOGLE_MAPS_API_KEY='your-web-restricted-key'
export FIREBASE_WEB_VAPID_KEY='your-public-web-push-certificate-key'
bash tool/build_web.sh --release
```

The script runs Flutter's web build and substitutes the Maps key only into
`build/web/index.html`. The key is necessarily visible to browsers at runtime;
Google Cloud API restrictions, quotas, and billing alerts protect it. No Maps
key is committed to the repository.

`FIREBASE_WEB_VAPID_KEY` is optional at compile time but required for web push
tokens and notification parity. The build script forwards it as the
`FIREBASE_WEB_VAPID_KEY` Dart compile-time definition without printing it.

## Cloudflare Pages one-time setup

1. In Cloudflare, create a **Direct Upload** Pages project named `woofcare`.
2. In GitHub repository settings, add these Actions secrets:
   - `CLOUDFLARE_ACCOUNT_ID`
   - `CLOUDFLARE_API_TOKEN` with Account > Cloudflare Pages > Edit
   - `GOOGLE_MAPS_API_KEY` with the web-restricted browser key
   - `FIREBASE_WEB_VAPID_KEY` with Firebase Cloud Messaging's public Web Push
     certificate key
3. Add the final `pages.dev` URL and any custom domains to:
   - Firebase Authentication > Settings > Authorized domains
   - the Maps key's allowed HTTP referrers
4. Run the **Build and deploy Flutter web** workflow manually for the first
   preview, or merge to `main` for the production deployment.

The workflow validates pull requests without deploying them. Pushes to `main`
deploy production; manual runs on other branches create Pages preview builds.
Cloudflare reads `web/_headers` from the compiled output. Pages supplies the SPA
fallback automatically as long as there is no top-level `404.html`.

## Required Firebase console setup

The repository contains public Firebase web configuration and the background
messaging worker. To finish web push notifications, create/import a Web Push
certificate in Firebase Cloud Messaging and store its public VAPID key in the
GitHub secret described above. Browser notification permission must be granted
by the user.

## Hosting decision

- **Cloudflare Pages (recommended):** best fit for a static Flutter bundle,
  globally distributed, automatic SPA behavior, preview deployments, and a
  generous free Pages tier.
- **Vercel:** also a capable edge static host, but there is no Flutter framework
  preset; it needs essentially the same custom CI build and SPA rewrite.
- **Render:** supports static sites, CDN delivery, previews, and rewrites, but it
  provides no material advantage for this Firebase-backed static client.
- **Railway:** now supports static hosting, but starts with usage-based paid
  service economics and documents that it has no built-in CDN. It is better for
  a server/API than this static bundle.

The name **WordCell** does not identify a current mainstream Flutter/static web
host. This comparison assumes it meant **Vercel**. If a different service was
intended, evaluate that exact product before sending production traffic to it.

## Primary references

- Flutter web build: https://docs.flutter.dev/deployment/web
- Google Maps Flutter web setup: https://pub.dev/packages/google_maps_flutter_web
- Firebase Messaging on Flutter web: https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
- Cloudflare Pages direct upload CI: https://developers.cloudflare.com/pages/how-to/use-direct-upload-with-continuous-integration/
- Cloudflare Pages SPA serving: https://developers.cloudflare.com/pages/configuration/serving-pages/
- Cloudflare Pages limits: https://developers.cloudflare.com/pages/platform/limits/
- Vercel project configuration: https://vercel.com/docs/project-configuration/vercel-json
- Render static sites: https://render.com/docs/static-sites
- Railway static hosting: https://docs.railway.com/guides/static-hosting
