# SL Module - Stateless Replies

Send SIP replies without transaction state.

## Load
```kamailio
loadmodule "sl.so"
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `default_code` | 500 | Default error code |
| `default_reason` | "Internal Server Error" | Default reason |
| `bind_tm` | 1 | Bind to TM module |

## Functions

### sl_send_reply
Send stateless reply.

```kamailio
sl_send_reply("200", "OK");
sl_send_reply("404", "Not Found");
sl_send_reply("503", "Service Unavailable");
```

**Note:** No retransmission handling. Use for:
- Early rejection (before transaction)
- OPTIONS keepalive
- Error responses

### send_reply
Smart reply - uses TM if transaction exists, else stateless.

```kamailio
send_reply("200", "OK");
```

### sl_reply_error
Send error based on last internal error.

```kamailio
if(!t_relay()) {
    sl_reply_error();
}
```

### sl_forward_reply
Forward received reply statelessly.

```kamailio
sl_forward_reply();
sl_forward_reply("200", "Custom Reason");
```

## Usage Patterns

### Early Rejection
```kamailio
request_route {
    # Reject scanners immediately
    if($ua =~ "sipvicious|scanner") {
        exit;  # Silent drop
    }

    # Reject unsupported methods
    if(!is_method("INVITE|ACK|BYE|CANCEL|OPTIONS|NOTIFY")) {
        sl_send_reply("405", "Method Not Allowed");
        exit;
    }

    ...
}
```

### OPTIONS Keepalive
```kamailio
request_route {
    if(is_method("OPTIONS")) {
        sl_send_reply("200", "OK");
        exit;
    }
    ...
}
```

### Initial Checks
```kamailio
route[REQINIT] {
    # Max-Forwards
    if(!mf_process_maxfwd_header("10")) {
        sl_send_reply("483", "Too Many Hops");
        exit;
    }

    # Sanity check
    if(!sanity_check("1511", "7")) {
        sl_send_reply("400", "Bad Request");
        exit;
    }
}
```

### Authentication Failure
```kamailio
route[AUTH] {
    if($hdr(X-APIID) == $null) {
        sl_send_reply("401", "Authentication Required");
        exit;
    }

    # Lookup failed
    if($var(found) != 1) {
        sl_send_reply("403", "Forbidden");
        exit;
    }
}
```

### Fallback After t_relay
```kamailio
route[RELAY] {
    t_on_failure("HANDLE_FAILURE");

    if(!t_relay()) {
        sl_reply_error();
    }
    exit;
}
```

## When to Use

| Scenario | Use |
|----------|-----|
| Before transaction | `sl_send_reply()` |
| After transaction | `t_reply()` |
| Unknown state | `send_reply()` |
| Relay failure | `sl_reply_error()` |
| OPTIONS ping | `sl_send_reply()` |

## Common Response Codes

| Code | Reason | Use |
|------|--------|-----|
| 100 | Trying | Processing started |
| 180 | Ringing | Alerting |
| 200 | OK | Success |
| 400 | Bad Request | Malformed |
| 401 | Unauthorized | Auth required |
| 403 | Forbidden | Not allowed |
| 404 | Not Found | User unknown |
| 408 | Request Timeout | No response |
| 480 | Temporarily Unavailable | User offline |
| 486 | Busy Here | User busy |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Overloaded |
| 603 | Decline | Call rejected |
