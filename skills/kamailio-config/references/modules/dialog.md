# Dialog Module

Tracks complete SIP dialogs (calls) for profiling, timeout control, and CDR.

## Load
```kamailio
loadmodule "dialog.so"
```

## Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `default_timeout` | 43200 | Dialog lifetime (seconds) |
| `early_timeout` | 300 | Early dialog timeout |
| `db_mode` | 0 | 0=none, 1=realtime, 2=delayed |
| `track_cseq_updates` | 0 | Track CSeq changes |
| `detect_spirals` | 1 | Detect routing loops |
| `timeout_avp` | - | AVP for per-dialog timeout |

```kamailio
modparam("dialog", "default_timeout", 21600)
modparam("dialog", "timeout_avp", "$avp(dialog_timeout)")
modparam("dialog", "track_cseq_updates", 1)
modparam("dialog", "db_mode", 0)
```

## Core Functions

### Dialog Management
| Function | Description |
|----------|-------------|
| `dlg_manage()` | Enable dialog tracking |
| `is_known_dlg()` | Check if in tracked dialog |
| `dlg_bye(side)` | Send BYE (caller/callee/all) |

### Timeout Control
| Function | Description |
|----------|-------------|
| `dlg_set_timeout(sec)` | Set dialog timeout |
| `dlg_set_timeout(sec, h_entry, h_id)` | Set for specific dialog |

### Profile Operations
| Function | Description |
|----------|-------------|
| `set_dlg_profile(profile)` | Add to profile |
| `unset_dlg_profile(profile)` | Remove from profile |
| `is_in_profile(profile)` | Check membership |
| `get_profile_size(profile, size)` | Count dialogs |

### Flags
| Function | Description |
|----------|-------------|
| `dlg_setflag(flag)` | Set dialog flag |
| `dlg_resetflag(flag)` | Clear flag |
| `dlg_isflagset(flag)` | Check flag |

## Dialog Variables

```kamailio
# Set dialog variable (persists across dialog)
$dlg_var(client_id) = $avp(client_id);
$dlg_var(start_time) = $Ts;

# Read in any route
if($dlg_var(client_id) != $null) {
    xlog("Client: $dlg_var(client_id)\n");
}
```

## Usage Pattern

```kamailio
request_route {
    if(is_method("INVITE") && !has_totag()) {
        dlg_manage();
        $dlg_var(client_id) = $avp(client_id);
        $dlg_var(created_at) = $(Ts{s.ftime,%Y-%m-%d %H:%M:%S});
    }
    ...
}

route[WITHINDLG] {
    if(!has_totag()) return;

    if(loose_route()) {
        if(is_method("BYE")) {
            dlg_manage();  # Track BYE for CDR
        }
        route(RELAY);
        exit;
    }
}
```

## Event Routes

```kamailio
event_route[dialog:start] {
    xlog("Call started: $ci\n");
}

event_route[dialog:end] {
    xlog("Call ended: duration=$dlg(lifetime)\n");
}

event_route[dialog:failed] {
    xlog("Call failed: $ci\n");
}
```

## Dialog States

1. **Unconfirmed** - INVITE sent
2. **Early** - 1xx received
3. **Confirmed** - 200 OK received
4. **Active** - ACK sent
5. **Deleted** - BYE or timeout

## Pseudo-Variables

| Variable | Description |
|----------|-------------|
| `$dlg(callid)` | Dialog Call-ID |
| `$dlg(state)` | Current state |
| `$dlg(lifetime)` | Duration |
| `$dlg(h_id)` | Hash ID |
| `$dlg(h_entry)` | Hash entry |
| `$dlg_var(name)` | Custom variable |
| `$dlg_ctx(timeout)` | Context timeout |
