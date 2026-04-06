# Cloudflare Staging Worker Setup

This document describes how to expose the `staging-pages` branch of this repository at `https://oxy-dev.lex-0.org/` using a Cloudflare Worker.

## Purpose

- production remains available at `https://oxy.lex-0.org/`
- `dev` pushes publish generated staging output to the `staging-pages` branch in this repository
- a Cloudflare Worker serves files from that branch at `https://oxy-dev.lex-0.org/`

## GitHub preparation

Before configuring Cloudflare:

1. create the `staging-pages` branch in this repository
2. ensure GitHub Actions can push to `staging-pages`
3. optionally add repository variable `STAGING_PAGES_BRANCH=staging-pages`

No extra staging repository is needed.

## Worker code

Create a Cloudflare Worker named `oxy-staging` and use this code:

```js
const OWNER = "BCDH";
const REPO = "oxygen-tei-lex-0";
const BRANCH = "staging-pages";
const RAW_BASE = `https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}`;

const CONTENT_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".xml": "application/xml; charset=utf-8",
  ".txt": "text/plain; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".svg": "image/svg+xml",
  ".zip": "application/zip",
  ".ico": "image/x-icon",
};

function contentType(pathname) {
  const match = pathname.match(/\.[A-Za-z0-9]+$/);
  return (match && CONTENT_TYPES[match[0].toLowerCase()]) || "application/octet-stream";
}

function cacheControl(pathname) {
  if (pathname === "/addon.xml" || pathname === "/robots.txt") {
    return "no-store";
  }
  if (pathname.endsWith(".zip")) {
    return "public, max-age=60";
  }
  return "public, max-age=300";
}

async function fetchFromBranch(pathname) {
  const upstream = `${RAW_BASE}${pathname}`;
  return fetch(upstream, {
    headers: { "User-Agent": "Cloudflare Worker" },
  });
}

function buildResponseHeaders(pathname, upstreamResp) {
  const headers = new Headers();

  headers.set("Content-Type", contentType(pathname));
  headers.set("Cache-Control", cacheControl(pathname));
  headers.set("X-Robots-Tag", "noindex, nofollow, noarchive");
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set("X-Content-Type-Options", "nosniff");

  const etag = upstreamResp.headers.get("etag");
  const lastModified = upstreamResp.headers.get("last-modified");

  if (etag) headers.set("ETag", etag);
  if (lastModified) headers.set("Last-Modified", lastModified);

  return headers;
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    let path = url.pathname;

    if (path === "/") path = "/index.html";
    else if (path.endsWith("/")) path = `${path}index.html`;

    let upstreamResp = await fetchFromBranch(path);

    if (upstreamResp.status === 404 && !path.endsWith(".html") && !path.includes(".", path.lastIndexOf("/") + 1)) {
      upstreamResp = await fetchFromBranch(`${path}.html`);
      if (upstreamResp.ok) path = `${path}.html`;
    }

    if (upstreamResp.status === 404) {
      return new Response("Not found", {
        status: 404,
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "X-Robots-Tag": "noindex, nofollow, noarchive",
          "Cache-Control": "no-store",
          "Access-Control-Allow-Origin": "*",
          "X-Content-Type-Options": "nosniff",
        },
      });
    }

    return new Response(upstreamResp.body, {
      status: upstreamResp.status,
      headers: buildResponseHeaders(path, upstreamResp),
    });
  },
};
```

## Cloudflare setup

1. open `Workers & Pages`
2. create a new Worker named `oxy-staging`
3. replace the default code with the Worker code above
4. deploy the Worker
5. open the Worker settings
6. go to `Domains & Routes`
7. add a `Custom Domain`
8. enter `oxy-dev.lex-0.org`
9. let Cloudflare create and manage the DNS record for the Worker

Important:

- do not create a manual CNAME for `oxy-dev.lex-0.org` first
- if one already exists, remove it before creating the Worker custom domain

## Behavior

The Worker:

- serves files from `https://raw.githubusercontent.com/BCDH/oxygen-tei-lex-0/staging-pages`
- maps `/` to `/index.html`
- maps directory paths to `index.html`
- sets correct content types for HTML, XML, images, and ZIP files
- does not forward GitHub Raw response headers such as the restrictive CSP sandbox
- adds `X-Robots-Tag: noindex, nofollow, noarchive`
- disables caching for `addon.xml` and `robots.txt`
- uses a short cache for ZIPs

## Verification

After a push to `dev`, verify:

- `https://oxy-dev.lex-0.org/`
- `https://oxy-dev.lex-0.org/addon.xml`
- `https://oxy-dev.lex-0.org/robots.txt`
- `https://oxy-dev.lex-0.org/oxygen-tei-lex-0.zip`

Expected results:

- the page shows the red staging banner
- the HTML contains `noindex` metadata
- responses include `X-Robots-Tag: noindex, nofollow, noarchive`
- `robots.txt` disallows all crawling
- the staging ZIP and descriptor are served from the staging host
