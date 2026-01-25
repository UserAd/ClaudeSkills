# HTTP Client Module

Make HTTP requests from Kamailio configuration.

## Load
```kamailio
loadmodule "http_client.so"
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `connection_timeout` | 0 | Connect timeout (seconds) |
| `timeout_mode` | 0 | 0=ms, 1=seconds |
| `httpredirect` | 1 | Follow redirects |
| `maxdatasize` | 0 | Max response size |
| `verify_peer` | 1 | Verify SSL cert |
| `verify_host` | 2 | Verify hostname |
| `keep_connections` | 0 | Reuse connections |
| `query_result` | 1 | 0=full, 1=first line |

```kamailio
modparam("http_client", "timeout_mode", 1)
modparam("http_client", "connection_timeout", 20)
```

### Named Connections
```kamailio
modparam("http_client", "httpcon",
    "api=>http://api.example.com/v1/;timeout=5")
```

## Functions

### http_client_query
Simple GET/POST request.

```kamailio
# GET
http_client_query("http://api/endpoint", "$var(result)");

# POST with data
http_client_query("http://api/endpoint", "key=value", "$var(result)");

# POST with headers
http_client_query("http://api/endpoint", "data",
    "Content-Type: application/json", "$var(result)");
```

**Returns:** HTTP status code, or negative on error.

```kamailio
$var(rc) = http_client_query("http://api/check", "$var(resp)");
if($var(rc) != 200) {
    xlog("HTTP error: $var(rc)\n");
}
```

### http_connect
Use named connection.

```kamailio
# GET
http_connect("api", "/users/123", "$var(result)");

# POST
http_connect("api", "/users", "application/json",
    '{"name":"test"}', "$var(result)");
```

### http_connect_raw
POST without variable expansion in data.

```kamailio
http_connect_raw("api", "/webhook", "application/json",
    $var(raw_json), "$var(result)");
```

### http_client_get
GET with separate response variable.

```kamailio
http_client_get("http://api/data", "$var(body)",
    "Authorization: Bearer token", "$var(resp)");
```

### http_get_redirect
Get final URL after redirects.

```kamailio
http_get_redirect("api", "$var(final_url)");
```

## Return Codes

| Code | Meaning |
|------|---------|
| 200-299 | Success |
| 400-499 | Client error |
| 500-599 | Server error |
| -1 | Connection failed |
| -2 | Timeout |

## Usage Patterns

### LCR API Call
```kamailio
route[LCR] {
    sl_send_reply("100", "Selecting trunk");

    $var(url) = "http://web:3000/api/v1/kamailio-lcr"
        + "?a_number=" + $(fU{s.escape.param})
        + "&b_number=" + $(rU{s.escape.param})
        + "&user_id=" + $avp(client_id);

    http_client_query($var(url), "$var(lcr_result)");

    xlog("L_NOTICE", "LCR response code: $rc\n");

    if($rc != 200) {
        sl_send_reply("503", "Routing service unavailable");
        exit;
    }

    # Parse JSON response
    if(!jansson_get("routes", $var(lcr_result), "$var(routes)")) {
        sl_send_reply("486", "No routes available");
        exit;
    }
    ...
}
```

### Webhook Notification
```kamailio
event_route[dialog:end] {
    $var(payload) = "{}";
    jansson_set("string", "callid", "$ci", "$var(payload)");
    jansson_set("integer", "duration", "$dlg(lifetime)", "$var(payload)");

    http_client_query("http://webhook/call-ended",
        $var(payload),
        "Content-Type: application/json",
        "$var(resp)");
}
```

### Error Handling
```kamailio
$var(rc) = http_client_query("http://api/check", "$var(resp)");

switch($var(rc)) {
    case 200:
        # Success
        break;
    case 400:
    case 403:
        sl_send_reply("403", "Forbidden");
        exit;
    case 404:
        sl_send_reply("404", "Not Found");
        exit;
    case -1:
    case -2:
        xlog("L_ERR", "API connection failed\n");
        sl_send_reply("503", "Service Unavailable");
        exit;
    default:
        sl_send_reply("500", "Internal Error");
        exit;
}
```

## Tips

### URL Encoding
Always escape user input in URLs:
```kamailio
$var(url) = "http://api?user=" + $(fU{s.escape.param});
```

### Timeouts
Set appropriate timeouts for SIP processing:
```kamailio
modparam("http_client", "connection_timeout", 5)
modparam("tm", "fr_timer", 30000)  # Must be > HTTP timeout
```

### Connection Reuse
For high-volume, enable keepalive:
```kamailio
modparam("http_client", "keep_connections", 1)
```
