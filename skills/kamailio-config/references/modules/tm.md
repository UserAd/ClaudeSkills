# TM Module - Transaction Management

Enables stateful SIP processing with retransmission handling.

## Load
```kamailio
loadmodule "tm.so"
```

## Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `fr_timer` | 30000 | Final response timeout (ms) |
| `fr_inv_timer` | 120000 | INVITE timeout after 1xx (ms) |
| `failure_reply_mode` | 3 | Branch discard on failure |
| `auto_inv_100` | 1 | Auto-send 100 Trying |
| `restart_fr_on_each_reply` | 1 | Reset timer on 1xx |

```kamailio
modparam("tm", "fr_timer", 30000)
modparam("tm", "fr_inv_timer", 120000)
modparam("tm", "failure_reply_mode", 3)
```

## Core Functions

### Relay
| Function | Description |
|----------|-------------|
| `t_relay()` | Forward statefully |
| `t_relay_to_udp(ip, port)` | Relay via UDP |
| `t_relay_to_tcp(ip, port)` | Relay via TCP |

### Transaction Control
| Function | Description |
|----------|-------------|
| `t_newtran()` | Create new transaction |
| `t_check_trans()` | Check if transaction exists |
| `t_lookup_request()` | Find matching transaction |
| `t_release()` | Remove from memory |

### Replies
| Function | Description |
|----------|-------------|
| `t_reply(code, reason)` | Send stateful reply |
| `t_send_reply(code, reason)` | Create trans + reply |
| `t_retransmit_reply()` | Resend last reply |

### Route Handlers
| Function | Description |
|----------|-------------|
| `t_on_failure(route)` | Set failure handler |
| `t_on_reply(route)` | Set reply handler |
| `t_on_branch(route)` | Set branch handler |
| `t_is_set(type)` | Check if handler set |

### Status Checking
| Function | Description |
|----------|-------------|
| `t_check_status(regex)` | Match reply code |
| `t_branch_timeout()` | Branch timed out? |
| `t_branch_replied()` | Branch got reply? |
| `t_is_canceled()` | Transaction canceled? |
| `t_any_timeout()` | Any branch timeout? |

### Timer Control
| Function | Description |
|----------|-------------|
| `t_set_fr(inv, noninv)` | Override FR timers |
| `t_reset_fr()` | Restore defaults |

## Usage Pattern

```kamailio
route[RELAY] {
    if(is_method("INVITE")) {
        if(!t_is_set("failure_route"))
            t_on_failure("MANAGE_FAILURE");
        if(!t_is_set("onreply_route"))
            t_on_reply("MANAGE_REPLY");
    }

    if(!t_relay()) {
        sl_reply_error();
    }
    exit;
}

failure_route[MANAGE_FAILURE] {
    if(t_is_canceled()) exit;

    if(t_check_status("408|5[0-9][0-9]")) {
        # Failover logic
    }
}

onreply_route[MANAGE_REPLY] {
    if($rs >= 200) {
        xlog("Final response: $rs\n");
    }
}
```

## Variables

| Variable | Description |
|----------|-------------|
| `$T_branch_idx` | Current branch index |
| `$T_reply_code` | Reply code |
| `$T_req(pv)` | Request PV access |
| `$T_rpl(pv)` | Reply PV access |
