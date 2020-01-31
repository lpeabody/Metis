# Added 9/6/2018 by Les Peabody, distributed by Baxter Acquia TAMs.

# Default Varnish cache policy for Acquia Cloud and related products.
#
vcl 4.0;

import std;

backend default {
  .host = "{VARNISH_BACKEND_HOST}";
  .port = "{VARNISH_BACKEND_PORT}";
}

# Incoming HTTP request:
#
# All HTTP requests - both new and restarted requests - enter vcl_recv(). From
# this routine, requests are normalized and flow continues to any of the
# following follow-up routines:
#  - vcl_hash: decides what's unique about a request and usually calls:
#    - vcl_hit: called after a successful cache lookup operation.
#    - vcl_miss: called after a failed cache lookup operation.
#    - vcl_pass: sets the request in pass mode.
#  - vcl_pipe: directly diverts the request to the backend, skips everything.
#
sub vcl_recv {
  # Pipe all websocket requests.
  if (req.http.Upgrade ~ "(?i)websocket") {
    return(pipe);
  }

  if (req.http.X-AH-Redirect) {
    return (synth(751, req.http.X-AH-Redirect));
  }

  # First Click Free:
  #
  # See vcl-default/DOCUMENTATION.md#first-click-free
  if (req.http.referer ~
      "(?i)^https?://([^\./]+\.)?(google|twitter|facebook|linkedin|t)\." ||
        req.http.User-Agent ~ "(?i)googlebot|facebookexternalhit|linkedinBot") {
    set req.http.X-UA-FCF = "allow";
  } else {
    set req.http.X-UA-FCF = "deny";
  }

  # Varnish doesn't support Range requests: needs to be piped
  if (req.http.Range) {
    return(pipe);
  }

  # Cache invalidation:
  #
  # See vcl-default/DOCUMENTATION.md#cache-invalidation
  if (req.method == "PURGE") {
    if (!req.http.X-Acquia-Purge) {
      return (synth(405, "Not allowed."));
    }
    return(purge);
  }
  if (req.method == "BAN") {
    if (!req.http.X-Acquia-Purge) {
      return (synth(405, "Permission denied."));
    }
    set req.http.X-Acquia-Purge = std.tolower(req.http.X-Acquia-Purge);
    if (req.url == "/site") {
      ban("obj.http.X-Docksal-Site == " + req.http.X-Acquia-Purge);
      return (synth(200, "Site banned."));
    }
    else if ((req.url == "/tags") && req.http.Cache-Tags) {
      set req.http.Cache-Tags = "(^|\s)" + regsuball(std.tolower(req.http.Cache-Tags), "\ ", "(\\s|$)|(^|\\s)") + "(\s|$)";
      ban("obj.http.X-Docksal-Site == " + req.http.X-Acquia-Purge + " && obj.http.Cache-Tags ~ " + req.http.Cache-Tags);
      return (synth(200, "Tags banned."));
    }
    else {
      set req.url = std.tolower(req.url);
      if (req.url ~ "\*") {
        set req.url = regsuball(req.url, "\*", "\.*");
        ban("obj.http.X-Acquia-Host == " + req.http.host + " && obj.http.X-Acquia-Path ~ ^" + req.url + "$");
        return (synth(200, "WILDCARD URL banned."));
      }
      else {
        ban("obj.http.X-Acquia-Host == " + req.http.host + " && obj.http.X-Acquia-Path == " + req.url);
        return (synth(200, "URL banned."));
      }
    }
  }

  # Static file policy:
  #
  # See vcl-default/DOCUMENTATION.md#static-file-policy
  if (req.url ~ "\.(msi|exe|dmg|zip|tgz|gz|pkg)") {
    return(pipe);
  }

  # Don't check cache for POSTs and various other HTTP request types
  if (req.method != "GET" && req.method != "HEAD") {
    return(pass);
  }

  # Find out if the request is pinned to a specific device and store it for later.
  if (req.http.Cookie ~ "desktop") {
    set req.http.X-pinned-device = "desktop";
  }
  else if (req.http.Cookie ~ "mobile") {
    set req.http.X-pinned-device = "mobile";
  }
  else if (req.http.Cookie ~ "tablet") {
    set req.http.X-pinned-device = "tablet";
  }

  # Static file policy:
  #
  # See vcl-default/DOCUMENTATION.md#static-file-policy
  if (req.url ~ "(?i)/(modules|themes|files|libraries)/.*\.(png|gif|jpeg|jpg|ico|swf|css|js|flv|f4v|mov|mp3|mp4|pdf|doc|ttf|eot|ppt|ogv|woff)(\?[a-z0-9]+)?$"
    && req.url !~ "/system/files" && req.http.Cookie !~ "ah_app_server") {
    set req.http.X-static-asset = "True";
  }

  # Don't check cache for cron.php
  if (req.url ~ "^/cron.php") {
    return(pass);
  }

  # Don't check cache for feedburner or feedvalidator for ise
  if ((req.http.host ~ "^(www\.|web\.)?ise") &&
      (req.http.User-Agent ~ "(?i)feed")) {
       return(pass);
  }

  # Cookie policy:
  #
  # See vcl-default/DOCUMENTATION.md#cookie-policy
  if (req.http.X-static-asset) {
    unset req.http.Cookie;
  }
  if (req.http.Cookie ~ "acquia_extract:") {
    set req.http.X-Acquia-Cookie-Key = regsub(req.http.Cookie, ".*acquia_extract\:([A-Za-z0-9 _][^;]*)=([^;]+)(;|$).*", "\1");
    set req.http.X-Acquia-Cookie-Value = regsub(req.http.Cookie, ".*acquia_extract\:([A-Za-z0-9 _][^;]*)=([^;]+)(;|$).*", "\2");
    set req.http.Cookie = regsub(req.http.Cookie, "acquia_extract\:", "");
  }
  if (req.http.Cookie ~ "acquia_a=") {
    set req.http.X-Acquia-Cookie-A = regsub(req.http.Cookie, ".*acquia_a=([^;]+);.*", "\1");
  }
  if (req.http.Cookie ~ "acquia_b=") {
    set req.http.X-Acquia-Cookie-B = regsub(req.http.Cookie, ".*acquia_b=([^;]+);.*", "\1");
  }
  if (req.http.Cookie ~ "acquia_c=") {
    set req.http.X-Acquia-Cookie-C = regsub(req.http.Cookie, ".*acquia_c=([^;]+);.*", "\1");
  }
  if ((req.http.cookie ~ "(^|;\s*)(S?SESS[a-zA-Z0-9]*)") ||
    (req.http.cookie ~ "(NO_CACHE|PERSISTENT_LOGIN_[a-zA-Z0-9]+)")) {
    return(pass);
  }
  elseif (req.http.Cookie) {
    set req.http.X-Acquia-Cookie-Original = req.http.cookie;
    unset req.http.Cookie;
  }

  # This is part of Varnish's default behavior to pass through any request that
  # comes from an http auth'd user.
  if (req.http.Authorization) {
    return(pass);
  }

  # Pass requests from simpletest to drupal.
  if (req.http.User-Agent ~ "simpletest") {
    return(pipe);
  }

  # Marketing query parameter stripping:
  #
  # See vcl-default/DOCUMENTATION.md#marketing-query-parameter-stripping
  if (req.url ~ "(\?|&)([gd]clid|gclsrc|cx|ie|cof|hConversionEventId|siteurl|zanpid|origin|os_ehash|_ga|utm_[a-z]+|mr:[A-z]+)=") {
    set req.url = regsuball(req.url, "([gd]clid|gclsrc|cx|ie|cof|hConversionEventId|siteurl|zanpid|origin|os_ehash|_ga|utm_[a-z]+|mr:[A-z]+)=[A-z0-9%._+-:]*&?", "");
    set req.url = regsub(req.url, "(\??&?)$", "");
  }

  # Default cache check
  return(hash);
}

# Skip vcl_deliver()/vcl_synth() and go directly to backend, don't collect $200.
sub vcl_pipe {
  if (req.http.upgrade) {
    set bereq.http.upgrade = req.http.upgrade;
  }
  else {
    set req.http.connection = "close";
  }
}

# Fetch response from the backend, then call ONE of:
# - vcl_backend_response()
# - vcl_backend_error()
sub vcl_backend_fetch {

  # Cookie policy: temporarily restore the original request's cookie.
  if (bereq.http.X-Acquia-Cookie-Original) {
    set bereq.http.Cookie = bereq.http.X-Acquia-Cookie-Original;
    unset bereq.http.X-Acquia-Cookie-Original;
  }
}

# Decide to cache or to hit-for-pass (=miss), then call vcl_deliver().
sub vcl_backend_response {

  # Cookie policy: remove the temporary cookie, to prevent cookies from
  # skipping cache constantly. Responses with session cookies shall
  # hit-for-pass so that they aren't cached.
  if (bereq.http.Cookie) {
    unset bereq.http.Cookie;
  }
  if ((beresp.http.Set-Cookie ~ "(^|;\s*)(S?SESS[a-zA-Z0-9]*)") ||
    (beresp.http.Set-Cookie ~ "(NO_CACHE|PERSISTENT_LOGIN_[a-zA-Z0-9]+)")) {
    call ah_pass;
  }

  # Static file policy:
  #
  # See vcl-default/DOCUMENTATION.md#static-file-policy
  if ( beresp.http.Content-Length ~ "[0-9]{8,}" ) {
    set beresp.http.X-Acquia-Streamed-For = "length";
    set beresp.do_stream = true;
  }

  # Drupal Bigpipe support:
  # https://www.drupal.org/docs/8/core/modules/bigpipe/bigpipe-environment-requirements
  # Disable buffering only for BigPipe responses
  if (beresp.http.Surrogate-Control ~ "BigPipe/1.0") {
    set beresp.http.X-Acquia-Streamed-For = "bigpipe";
    set beresp.do_stream = true;
  }

  # Avoid attempting to gzip an empty response body
  # https://www.varnish-cache.org/trac/ticket/1320
  if (beresp.http.Content-Encoding ~ "gzip" && beresp.http.Content-Length == "0") {
    unset beresp.http.Content-Encoding;
  }

  # HTTP Methods, 3XX and 404 policy:
  #
  # See vcl-default/DOCUMENTATION.md#http-methods--3xx-and-404-policy
  if ((beresp.status == 301) || (beresp.status == 404)) {
    if (!beresp.http.X-Acquia-No-301-404-Caching-Enforcement) {
      if (beresp.ttl < 15m) {
        set beresp.http.Cache-Control = "max-age=900, public";
        set beresp.ttl = 15m;
      }
    }
  }
  else if (beresp.status >= 302 || !(beresp.ttl > 0s)
    || !((bereq.method == "GET") || bereq.method == "HEAD")) {
    call ah_pass;
  }

  # First Click Free:
  #
  # See vcl-default/DOCUMENTATION.md#first-click-free
  if (bereq.http.X-UA-FCF && beresp.http.X-UA-FCF-Enabled) {
    set beresp.http.X-UA-FCF = bereq.http.X-UA-FCF;
    if (!beresp.http.Vary) {
      set beresp.http.Vary = "X-UA-FCF";
    } elsif (beresp.http.Vary !~ "(?i)X-UA-FCF") {
      set beresp.http.Vary = beresp.http.Vary + ",X-UA-FCF";
    }
  }

  # Cache invalidation:
  #
  # See vcl-default/DOCUMENTATION.md#cache-invalidation
  set beresp.http.X-Acquia-Host = std.tolower(bereq.http.host);
  set beresp.http.X-Acquia-Path = std.tolower(bereq.url);
  set beresp.http.X-Docksal-Site = std.tolower(beresp.http.X-Docksal-Site);
  set beresp.http.Cache-Tags = std.tolower(beresp.http.Cache-Tags);

  # Respect explicit no-cache headers
  if (beresp.http.Pragma ~ "no-cache" ||
      beresp.http.Cache-Control ~ "no-cache" ||
      beresp.http.Cache-Control ~ "private") {
    call ah_pass;
  }

  # Don't cache cron.php
  if (bereq.url ~ "^/cron.php") {
    call ah_pass;
  }

  # Grace: Avoid thundering herd when an object expires by serving
  # expired stale object during the next N seconds while one request
  # is made to the backend for that object.
  set beresp.grace = 2m;

  # Cache anything else. Returning nothing here would fall-through
  # to Varnish's default cache store policies.
  return(deliver);
}

# Normalize the response before delivering it to the client.
sub vcl_deliver {

  # Device redirects:
  #
  # See vcl-default/DOCUMENTATION.md#device-redirects
  if (resp.http.X-AH-Mobile-Redirect || resp.http.X-AH-Tablet-Redirect || resp.http.X-AH-Desktop-Redirect && !resp.http.X-AH-Mobile-Redirect) {
    # We run devicedetect as it will add the X-UA-Device header which specifies if the device is pc, phone or tablet.
//    call acquia_devicedetect;

    # Make sure remap header is added to req if needed
    if (resp.http.X-AH-Redirect-No-Remap) {
      set req.http.X-AH-Redirect-No-Remap = resp.http.X-AH-Redirect-No-Remap;
    }

    if ( resp.http.X-AH-Mobile-Redirect && req.http.X-UA-Device ~ "mobile" && req.http.X-pinned-device != "mobile" ) {
      if (resp.http.X-AH-Mobile-Redirect !~ "(?i)^https?://") {
        set resp.http.X-AH-Mobile-Redirect = "http://" + resp.http.X-AH-Mobile-Redirect;
      }
      set req.http.X-AH-Redirect = resp.http.X-AH-Mobile-Redirect;
      call ah_device_redirect_check;
    }
    else if ( resp.http.X-AH-Tablet-Redirect && req.http.X-UA-Device ~ "tablet" && req.http.X-pinned-device != "tablet" ) {
      if (resp.http.X-AH-Tablet-Redirect !~ "(?i)^https?://") {
        set resp.http.X-AH-Tablet-Redirect = "http://" + resp.http.X-AH-Tablet-Redirect;
      }
      set req.http.X-AH-Redirect = resp.http.X-AH-Tablet-Redirect;
      call ah_device_redirect_check;
    }
    else if ( resp.http.X-AH-Desktop-Redirect && req.http.X-UA-Device ~ "pc" && req.http.X-pinned-device != "desktop" ) {
      if (resp.http.X-AH-Desktop-Redirect !~ "(?i)^https?://") {
        set resp.http.X-AH-Desktop-Redirect = "http://" + resp.http.X-AH-Desktop-Redirect;
      }
      set req.http.X-AH-Redirect = resp.http.X-AH-Desktop-Redirect;
      call ah_device_redirect_check;
    }
  }

  # Unset the X-AH redirect headers if they exist here
  unset resp.http.X-AH-Mobile-Redirect;
  unset resp.http.X-AH-Tablet-Redirect;
  unset resp.http.X-AH-Desktop-Redirect;
  unset resp.http.X-AH-Redirect-No-Remap;

  # Add an X-Cache diagnostic header
  if (obj.hits > 0) {
    set resp.http.X-Varnish-Cache = "HIT";
    set resp.http.X-Cache-Hits = obj.hits;
  } else {
    set resp.http.X-Varnish-Cache = "MISS";
  }

  # Cookie policy: remove Set-Cookie from cached or static responses.
  if (resp.http.X-Cache-Hits || req.http.X-static-asset) {
    unset resp.http.Set-Cookie;
  }

  # Strip the age header for Akamai requests
  if (req.http.Via ~ "akamai") {
    set resp.http.X-Age = resp.http.Age;
    unset resp.http.Age;
  }

  # Unset identification headers not needed for general traffic.
  if (!req.http.X-Acquia-Debug) {
    unset resp.http.X-Acquia-Streamed-For;
  }

  # Cache invalidation:
  #
  # See vcl-default/DOCUMENTATION.md#cache-invalidation
  if (!req.http.X-Acquia-Purge-Debug) {
//    unset resp.http.X-Acquia-Host;
//    unset resp.http.X-Acquia-Path;
//    unset resp.http.X-Docksal-Site;
//    unset resp.http.Cache-Tags;
  }

  # ELB health checks respect HTTP keep-alives, but require the connection to
  # remain open for 60 seconds. Varnish's default keep-alive idle timeout is
  # 5 seconds, which also happens to be the minimum ELB health check interval.
  # The result is a race condition in which Varnish can close an ELB health
  # check connection just before a health check arrives, causing that check to
  # fail. Solve the problem by not allowing HTTP keep-alive for ELB checks.
  if (req.http.user-agent ~ "ELB-HealthChecker") {
    set resp.http.Connection = "close";
  }
  return(deliver);
}


# Generate content for synth() calls, redirects and vcl_backend_error().
sub vcl_synth {
  # mobile browsers redirect
  if (resp.status == 750) {
    set resp.http.Location = resp.reason + req.url;
    set resp.status = 302;
    set resp.reason = "Found";
    return(deliver);
  }

  # user defined device redirect
  if (resp.status == 751) {
    if (req.http.X-AH-Redirect-No-Remap) {
      set resp.http.Location = resp.reason;
    }
    else {
      set resp.http.Location = resp.reason + req.url;
    }
    set resp.status = 302;
    set resp.reason = "Found";
    return(deliver);
  }

  set resp.http.Content-Type = "text/html; charset=utf-8";
  set resp.http.Retry-After = "5";
  synthetic( {"<!DOCTYPE html>
<html>
  <head>
    <title>"} + resp.status + " " + resp.reason + {"</title>
  </head>
  <body>
    <h1>This server is experiencing technical problems. Please
try again in a few moments. Thanks for your continued patience, and
we're sorry for any inconvenience this may cause.</h1>
    <p>Error "} + resp.status + " " + resp.reason + {"</p>
    <p>"} + resp.reason + {"</p>
    <h3>Guru Meditation:</h3>
    <p>XID: "} + req.xid + {"</p>
    <hr>
    <p>Varnish cache server</p>
  </body>
</html>
"} );
  return (deliver);
}

# Backend is down, so deliver a error-page response.
sub vcl_backend_error {

  # Default Varnish error (Nginx didn't reply)
  set beresp.http.Content-Type = "text/html; charset=utf-8";

  synthetic( {"<!DOCTYPE html>
  <html>
    <head>
      <title>"} + beresp.status + " " + beresp.reason + {"</title>
    </head>
    <body>
    <h1>This server is experiencing technical problems. Please
try again in a few moments. Thanks for your continued patience, and
we're sorry for any inconvenience this may cause.</h1>
    <p>Error "} + beresp.status + " " + beresp.reason + {"</p>
    <p>"} + beresp.reason + {"</p>
      <p>XID: "} + bereq.xid + {"</p>
    </body>
   </html>
   "} );
  return(deliver);
}

# Generate a hit-for-pass object:
#
# These objects are stored in the cache for a short time instead of the fetched
# object, this hit-for-pass object makes subsequent requests pass cache. This
# is most commonly used in the case of Set-Cookie response headers.
sub ah_pass {
  set beresp.uncacheable = true;
  set beresp.ttl = 10s;
  return(deliver);
}

# Test if a device redirect is attempting to redirect to the same path as the
# request came from. This should stop the state machine restart and remove the
# redirect from the headers.
sub ah_device_redirect_check {
  if (req.http.X-AH-Redirect-No-Remap) {
    if (req.http.X-Forwarded-Proto) {
      if (req.http.X-AH-Redirect != req.http.X-Forwarded-Proto + "://" + req.http.host + req.url) {
        return(restart);
      }
    }
    else {
      if (req.http.X-AH-Redirect != "http://" + req.http.host + req.url) {
        return(restart);
      }
    }
  }
  else {
    if (req.http.X-Forwarded-Proto) {
      if (req.http.X-AH-Redirect != req.http.X-Forwarded-Proto + "://" + req.http.host) {
        return(restart);
      }
    }
    else {
      if (req.http.X-AH-Redirect != "http://" + req.http.host) {
        return(restart);
      }
    }
  }
  # Redirection fell through so we will remove the redirect header.
  unset req.http.X-AH-Redirect;
}
