# RR Module - Record-Route

Handles SIP Record-Route for dialog routing.

## Load
```kamailio
loadmodule "rr.so"
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `enable_full_lr` | 0 | Use `;lr=on` instead of `;lr` |
| `append_fromtag` | 1 | Add from-tag for direction |
| `enable_double_rr` | 1 | Two RR for topology hiding |
| `add_username` | 0 | Include username in RR |
| `force_send_socket` | 0 | Force local socket |

```kamailio
modparam("rr", "enable_full_lr", 0)
modparam("rr", "append_fromtag", 0)
```

## Functions

### record_route
Add Record-Route header for dialog routing.

```kamailio
record_route();                    # Basic
record_route(";nat=yes");          # With parameter
```

### loose_route
Route in-dialog requests via Record-Route path.

```kamailio
if(loose_route()) {
    # Request has Route headers, follow them
    route(RELAY);
    exit;
}
```

### add_rr_param
Add parameter to existing Record-Route.

```kamailio
record_route();
add_rr_param(";myapp=true");
```

### check_route_param
Check Route header for parameter.

```kamailio
if(check_route_param("nat=yes")) {
    # NAT detected via RR
    setflag(NAT_FLAG);
}
```

### is_direction
Check request direction in dialog.

```kamailio
if(is_direction("downstream")) {
    # From caller to callee
}
if(is_direction("upstream")) {
    # From callee to caller
}
```

### remove_record_route
Remove RR lumps (before adding new ones).

```kamailio
remove_record_route();
record_route();
```

### record_route_preset
Use preset address instead of local.

```kamailio
record_route_preset("sip:proxy.example.com:5060");
```

### record_route_advertised_address
Use advertised address.

```kamailio
record_route_advertised_address("sip:public.ip:5060");
```

## Variables

| Variable | Description |
|----------|-------------|
| `$route_uri` | First Route header URI |
| `$rr_count` | Number of RR headers |
| `$rr_top_count` | Topmost RR count (1 or 2) |

## Usage Pattern

```kamailio
request_route {
    ...

    # Handle in-dialog requests
    route(WITHINDLG);

    # Initial requests only
    remove_hf("Route");  # Remove preloaded routes

    if(is_method("INVITE|SUBSCRIBE")) {
        record_route();
    }

    route(RELAY);
}

route[WITHINDLG] {
    if(!has_totag()) return;

    if(loose_route()) {
        # In-dialog request with Route header
        if(is_method("BYE")) {
            setflag(FLT_ACC);
        }
        route(RELAY);
        exit;
    }

    if(is_method("ACK")) {
        if(t_check_trans()) {
            route(RELAY);
            exit;
        }
        exit;
    }

    sl_send_reply("404", "Not here");
    exit;
}
```

## How Record-Route Works

1. **Initial INVITE:**
   - Proxy adds `Record-Route: <sip:proxy:5060;lr>`
   - Response includes same RR

2. **Subsequent requests (BYE, re-INVITE):**
   - Client includes `Route: <sip:proxy:5060;lr>`
   - `loose_route()` processes and removes top Route
   - Request forwarded to next hop

3. **Direction detection:**
   - With `append_fromtag=1`, RR includes original from-tag
   - `is_direction()` compares current from-tag to detect direction

## Double Record-Route

When topology hiding or protocol change:

```kamailio
modparam("rr", "enable_double_rr", 1)

# Results in:
# Record-Route: <sip:external:5060;lr>
# Record-Route: <sip:internal:5060;lr>
```
