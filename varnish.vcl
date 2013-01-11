import std;


// variable availability in VCL
//   https://www.varnish-software.com/static/book/VCL_functions.html#variable-availability-in-vcl



# php -S localhost:3000
# requires php5.4
backend default {
    .host = "127.0.0.1";
    .port = "3000";
}

sub vcl_recv {
    if (req.restarts == 0) {
        if (req.http.x-forwarded-for) {
            set req.http.X-Forwarded-For =
                req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }

    if (req.request != "GET" &&
      req.request != "HEAD" &&
      req.request != "PUT" &&
      req.request != "POST" &&
      req.request != "TRACE" &&
      req.request != "OPTIONS" &&
      req.request != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }

    if (req.request != "GET" && req.request != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return (pass);
    }


    /*******************
    // cache static content
    if (req.url ~ "\.(js|css|jpg|png)$") {
        return (lookup);
    }

    if (req.url == "/favicon.ico") {
        return (error);
    }

    // manipulate url parameters
    if (req.url ~ "param.php\?name=.*") {
        set req.url = regsub(req.url, "param.php\?name=.*", "param.php?name=bob");
        return (lookup);
    }

    // ip based rules
    if (req.url ~ "client.php") {
        return (lookup);
    }
    *******************/

    // To avoid cache collisions and littering the cache with large
    // amount of copies of the same content, Varnish does not cache a
    // page if the Cookie request-header or Set-Cookie response header
    // is present.

    // Best practices for cookies
    //   https://www.varnish-software.com/static/book/Content_Composition.html#best-practices-for-cookies
    // if (req.http.Authorization || req.http.Cookie) {
    //    return (pass);
    // }

    return (pass);
}


sub vcl_pipe {
    # Note that only the first request to the backend will have
    # X-Forwarded-For set.  If you use X-Forwarded-For and want to
    # have it set for all requests, make sure to have:
    # set bereq.http.connection = "close";
    # here.  It is not set by default as it might break some broken web
    # applications, like IIS with NTLM authentication.
    return (pipe);
}

sub vcl_pass {
    return (pass);
}

sub vcl_hash {

    // What makes this page unique, and how can I let caches know.
    // The most important lessons, though, is to start with what you know
    // Which pages are user specific and which ones are not 
    hash_data(req.url);
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }
    return (hash);
}

sub vcl_hit {
    return (deliver);
}

sub vcl_miss {
    return (fetch);
}

sub vcl_fetch {
    // The initial value of beresp.ttl is:
    // The s-maxage variable in the Cache-Control response header
    // The max-age variable in the Cache-Control response header
    // The Expires response header
    // The default_ttl parameter.    
    if (beresp.ttl <= 0s ||
        // if response sets a cookie
        // don't cache
        beresp.http.Set-Cookie ||
        // if response has a Vary:* header
        // don't cache
        beresp.http.Vary == "*") {
		set beresp.ttl = 120 s;
        // Cache hits for pass, is when varnish gets a
        // response(beresp) from the backend and finds out it cannot
        // be cached, it will then create a cache object that records
        // that fact, so that the next request goes directly to
        // "pass".
		return (hit_for_pass);
    }
    return (deliver);
}

sub vcl_deliver {
    // Modify final varnish output here
    // E.g. remove or add a header that isn't supposed to be stored in the cache
    // set resp.http.blah = ...
    return (deliver);
}

sub vcl_error {
    set obj.http.Content-Type = "text/html; charset=utf-8";
    set obj.http.Retry-After = "5";
    synthetic {"
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>"} + obj.status + " " + obj.response + {"</title>
  </head>
  <body>
    <h1>Error "} + obj.status + " " + obj.response + {"</h1>
    <p>"} + obj.response + {"</p>
    <h3>Guru Meditation:</h3>
    <p>XID: "} + req.xid + {"</p>
    <hr>
    <p>Varnish cache server</p>
  </body>
</html>
"};
    return (deliver);
}

sub vcl_init {
	return (ok);
}

sub vcl_fini {
	return (ok);
}
