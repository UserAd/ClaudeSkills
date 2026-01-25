# Kamailio SIP Routing Logic

## Routing Block Overview

```
Incoming SIP Request
        │
        ▼
   request_route { }      ← Main entry point
        │
        ├─► route[SUBROUTE]     ← Named subroutes
        │
        └─► t_relay()
                │
                ├─► branch_route[X]    ← Before forwarding each branch
                │
                ├─► onreply_route[X]   ← When response received
                │
                └─► failure_route[X]   ← When all branches fail
```

---

## request_route

**Entry point for ALL incoming SIP requests.** Every message starts here.

```kamailio
request_route {
    # 1. Security filtering
    if($ua =~ "scanner|sipvicious") {
        exit;
    }

    # 2. Initial checks
    route(REQINIT);

    # 3. CANCEL handling
    if(is_method("CANCEL")) {
        if(t_check_trans()) {
            route(RELAY);
        }
        exit;
    }

    # 4. Retransmission handling
    if(!is_method("ACK")) {
        if(t_precheck_trans()) {
            t_check_trans();
            exit;
        }
        t_check_trans();
    }

    # 5. In-dialog requests (has To-tag)
    route(WITHINDLG);

    # 6. Initial requests only (no To-tag)
    remove_hf("Route");
    if(is_method("INVITE|SUBSCRIBE")) {
        record_route();
    }

    # 7. Business logic
    route(AUTH);
    route(DISPATCH);
    route(RELAY);
}
```

---

## Named Routes (route[NAME])

Reusable subroutines. Called with `route(NAME)`.

```kamailio
route[REQINIT] {
    # Max-Forwards check
    if(!mf_process_maxfwd_header("10")) {
        sl_send_reply("483", "Too Many Hops");
        exit;
    }

    # Sanity check
    if(!sanity_check("1511", "7")) {
        xlog("L_WARN", "Malformed SIP from $si:$sp\n");
        exit;
    }
}

route[RELAY] {
    # Set event routes before relay
    if(is_method("INVITE|BYE|SUBSCRIBE|UPDATE")) {
        if(!t_is_set("branch_route")) t_on_branch("MANAGE_BRANCH");
    }
    if(is_method("INVITE|SUBSCRIBE|UPDATE")) {
        if(!t_is_set("onreply_route")) t_on_reply("MANAGE_REPLY");
    }
    if(is_method("INVITE")) {
        if(!t_is_set("failure_route")) t_on_failure("MANAGE_FAILURE");
    }

    if(!t_relay()) {
        sl_reply_error();
    }
    exit;
}
```

---

## In-Dialog Requests (route[WITHINDLG])

Handle requests within established dialogs (have To-tag).

```kamailio
route[WITHINDLG] {
    if(!has_totag()) return;  # Not in-dialog

    # Follow Record-Route path
    if(loose_route()) {
        if(is_method("BYE")) {
            setflag(FLT_ACC);
            setflag(FLT_ACCFAILED);
        }
        route(RELAY);
        exit;
    }

    # Stateful ACK
    if(is_method("ACK")) {
        if(t_check_trans()) {
            route(RELAY);
            exit;
        }
        exit;  # Orphan ACK - discard
    }

    sl_send_reply("404", "Not here");
    exit;
}
```

---

## branch_route

**Executed BEFORE forwarding each branch.** Use for per-branch modifications.

```kamailio
branch_route[MANAGE_BRANCH] {
    xdbg("Branch [$T_branch_idx] to $ru\n");
    # Modify $ru, $du, add headers per branch
}
```

**Set with:** `t_on_branch("MANAGE_BRANCH");`

---

## onreply_route

**Executed when SIP response arrives.** Process provisional (1xx) and final (2xx-6xx) responses.

```kamailio
onreply_route[MANAGE_REPLY] {
    xdbg("Reply: $rs $rr\n");

    if($rs != "100") {
        # Store response code for CDR
        if(is_method("INVITE|CANCEL")) {
            $dlg_var(sip_code) = $rs;
        }
    }

    # Handle specific responses
    if($rs == "180" || $rs == "183") {
        # Early media handling
    }
}
```

**Set with:** `t_on_reply("MANAGE_REPLY");`

---

## failure_route

**Executed when ALL branches fail (3xx-6xx or timeout).** Use for failover logic.

```kamailio
failure_route[MANAGE_FAILURE] {
    if(t_is_canceled()) exit;

    xlog("L_NOTICE", "Failure: $rm $rs\n");

    # Failover on specific codes
    if(t_check_status("408|5[0-9][0-9]")) {
        # Try alternate route
        $du = "sip:backup@10.0.0.2:5060";
        t_on_failure("MANAGE_FAILURE");
        route(RELAY);
        exit;
    }
}
```

**Set with:** `t_on_failure("MANAGE_FAILURE");`

---

## LCR Failover Pattern

Serial forking through multiple routes:

```kamailio
route[LCR] {
    # Load routes into AVP stack
    $var(i) = 0;
    while($var(i) < $var(route_count)) {
        $avp(routes) = $var(route[$var(i)]);
        $var(i) = $var(i) + 1;
    }

    $avp(current) = $var(route_count) - 1;
    route(LCR_NEXT);
}

route[LCR_NEXT] {
    if($avp(current) == -1) {
        sl_send_reply("603", "No routes");
        exit;
    }

    # Extract route details from AVP
    jansson_get("host", "$(avp(routes)[$avp(current)])", "$var(host)");
    jansson_get("port", "$(avp(routes)[$avp(current)])", "$var(port)");

    $du = "sip:" + $var(host) + ":" + $var(port);
    $avp(current) = $avp(current) - 1;

    t_on_failure("LCR_FAILURE");
    route(RELAY);
}

failure_route[LCR_FAILURE] {
    if(t_is_canceled()) exit;

    # Try next on failure codes
    if(t_check_status("4[0-9][0-9]|5[0-9][0-9]") || t_branch_timeout()) {
        route(LCR_NEXT);
        exit;
    }
}
```

---

## Control Flow

### Exit vs Return
- `exit;` - Stop ALL processing, exit request_route
- `return;` - Return from current route to caller

```kamailio
route[CHECK] {
    if(!valid) {
        sl_send_reply("403", "Forbidden");
        exit;     # Stop everything
    }
    return;       # Continue in caller
}
```

### Flags
```kamailio
#!define FLT_ACC 1
#!define FLT_NATS 5

setflag(FLT_ACC);
if(isflagset(FLT_ACC)) { ... }
resetflag(FLT_ACC);
```

---

## Event Routes

### Dialog Events
```kamailio
event_route[dialog:start] {
    xlog("Call started: $ci\n");
}

event_route[dialog:end] {
    xlog("Call ended: $ci duration=$dlg(lifetime)\n");
}

event_route[dialog:failed] {
    xlog("Call failed: $ci\n");
}
```

---

## Typical Request Flow

```
INVITE sip:bob@domain.com
    │
    ▼
request_route
    │
    ├─► REQINIT (sanity, max-forwards)
    │
    ├─► WITHINDLG (return - no to-tag)
    │
    ├─► record_route()
    │
    ├─► AUTH (validate client)
    │
    ├─► LCR (select route)
    │
    └─► RELAY
            │
            ├─► t_on_branch("X")
            ├─► t_on_reply("X")
            ├─► t_on_failure("X")
            └─► t_relay()

    [Response arrives]
            │
            ▼
    onreply_route[X]
            │
    [If failure]
            │
            ▼
    failure_route[X]
            │
            └─► Try next route or return error
```
