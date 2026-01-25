# Kamailio Pseudo-Variables Reference

Complete reference for Kamailio pseudo-variables (v5.6.x).

**Documentation**: https://www.kamailio.org/wikidocs/cookbooks/5.6.x/pseudovariables/

## Table of Contents
- [Request URI & Routing](#request-uri--routing)
- [Destination URI](#destination-uri)
- [From/To Headers](#fromto-headers)
- [Source & Received](#source--received)
- [Local Socket](#local-socket)
- [Send Socket](#send-socket)
- [Message Info](#message-info)
- [Headers](#headers)
- [Reply Variables](#reply-variables)
- [Script Variables](#script-variables)
- [AVP & XAVP](#avp--xavp)
- [Dialog Variables](#dialog-variables)
- [Time Variables](#time-variables)
- [Authentication](#authentication)
- [P-Asserted/P-Preferred Identity](#p-assertedp-preferred-identity)
- [Flags](#flags)
- [Branch Variables](#branch-variables)
- [Process/System](#processsystem)
- [Special Variables](#special-variables)
- [Module-Specific Variables](#module-specific-variables)

---

## Request URI & Routing

| Variable | R/W | Description |
|----------|-----|-------------|
| `$ru` | RW | Request-URI from first line |
| `$rU` | RW | Username portion of Request-URI |
| `$rUl` | R | Length of Request-URI username |
| `$rd` | RW | Domain in Request-URI |
| `$rp` | RW | Port in Request-URI |
| `$rP` | R | Transport protocol of Request-URI |
| `$rz` | R | URI scheme (sip, sips, tel, urn) |
| `$ou` | R | Original Request-URI before modifications |
| `$oU` | R | Username in original Request-URI |
| `$oUl` | R | Length of original Request-URI username |
| `$od` | R | Domain in original Request-URI |
| `$op` | R | Port in original Request-URI |
| `$oP` | R | Protocol of original Request-URI |

**Assignment:**
```kamailio
$ru = "sip:user@domain.com";
$rU = "newuser";
$du = "sip:10.0.0.1:5060;transport=tcp";
$du = $null;  # Reset destination
```

---

## Destination URI

| Variable | R/W | Description |
|----------|-----|-------------|
| `$du` | RW | Destination URI for next hop |
| `$dd` | R | Domain portion of destination URI |
| `$dp` | R | Port of destination URI |
| `$dP` | R | Transport protocol of destination URI |
| `$nh(key)` | R | Next hop address attributes |

---

## From/To Headers

| Variable | R/W | Description |
|----------|-----|-------------|
| `$fu` | RW | Complete From header URI |
| `$fU` | RW | Username in From URI |
| `$fUl` | R | Length of From username |
| `$fd` | RW | Domain in From URI |
| `$fn` | RW | Display name from From header |
| `$ft` | R | Tag parameter of From header |
| `$fti` | R | Initial From tag from dialog start |
| `$tu` | RW | Complete To header URI |
| `$tU` | RW | Username in To URI |
| `$tUl` | R | Length of To username |
| `$td` | RW | Domain in To URI |
| `$tn` | RW | Display name from To header |
| `$tt` | R | Tag parameter of To header |
| `$tti` | R | Initial To tag from dialog start |

---

## Source & Received

| Variable | R/W | Description |
|----------|-----|-------------|
| `$si` | R | Source IP address |
| `$siz` | R | Source IP with brackets for IPv6 |
| `$sp` | R | Source port number |
| `$su` | R | Source as SIP URI (UDP proto omitted) |
| `$sut` | R | Source as full SIP URI (all protos shown) |
| `$sas` | R | Source address in socket format |
| `$pr` / `$proto` | R | Protocol of received message |
| `$prid` | R | Protocol ID (0-7) |

---

## Local Socket

| Variable | R/W | Description |
|----------|-----|-------------|
| `$Ri` | R | Local IP where message received |
| `$Rp` | R | Local port where message received |
| `$Rn` | R | Name of local socket |
| `$RAi` | R | Advertised IP of receive socket |
| `$RAp` | R | Advertised port of receive socket |
| `$Ru` | R | Receive socket as URI (no UDP proto) |
| `$Rut` | R | Receive socket as URI (all protos) |
| `$RAu` | R | Advertised socket as URI (no UDP) |
| `$RAut` | R | Advertised socket as URI (all protos) |

---

## Send Socket

| Variable | R/W | Description |
|----------|-----|-------------|
| `$fs` | RW | Forced send socket (proto:ip:port) |
| `$fsn` | RW | Name of forced send socket |
| `$sndfrom(key)` | R | Attributes of local send socket |
| `$sndto(key)` | R | Attributes of remote send socket |
| `$conid` | R | TCP connection ID |

---

## Message Info

| Variable | R/W | Description |
|----------|-----|-------------|
| `$rm` | R | SIP method name |
| `$rmid` | R | SIP method as integer ID |
| `$mt` | R | Message type: 1=request, 2=reply |
| `$ci` | R | Call-ID header value |
| `$cs` | R | CSeq sequence number |
| `$csb` | R | Complete CSeq header body |
| `$ml` | R | SIP message length in bytes |
| `$mb` | R | Complete SIP message buffer |
| `$mbu` | R | Updated SIP message buffer after modifications |
| `$mi` | R | SIP message unique identifier |
| `$rb` | R | Message body content |
| `$bs` | R | Body size |
| `$rv` | R | SIP protocol version |

---

## Headers

| Variable | R/W | Description |
|----------|-----|-------------|
| `$hdr(Name)` | R | Body of named header field |
| `$hdr(Name)[0]` | R | First header |
| `$hdr(Name)[*]` | R | All headers concatenated |
| `$hdr(Name)[-1]` | R | Last header |
| `$hdrc(Name)` | R | Count of headers with given name |
| `$hfl(Name)` | R | Individual body from comma-separated header |
| `$hflc(Name)` | R | Count of bodies in multi-body header |
| `$ct` | R | Contact header |
| `$cT` | R | Content-Type header |
| `$cl` | R | Content-Length header value |
| `$ua` | R | User-Agent header |
| `$route_uri` | R | URI from first Route header |

**Examples:**
```kamailio
if($hdr(X-Custom) != $null) { ... }
$var(via) = $hdr(Via)[0];
$var(count) = $hdrc(Via);
```

---

## Reply Variables

| Variable | R/W | Description |
|----------|-----|-------------|
| `$rs` | R | Reply status code |
| `$rr` | R | Reply reason phrase |
| `$rc` | R | Return code from last function call |
| `$retcode` | R | Alias for return code |

---

## Script Variables

| Type | Syntax | Scope | Notes |
|------|--------|-------|-------|
| Script var | `$var(name)` | Request processing | Defaults to 0 |
| Zero var | `$vz(name)` | Request processing | Zero default |
| Null var | `$vn(name)` | Request processing | Can be null |
| Shared var | `$shv(name)` | All processes | Shared memory |

**Usage:**
```kamailio
$var(counter) = 0;
$var(counter) = $var(counter) + 1;
$shv(global_counter) = $shv(global_counter) + 1;
```

---

## AVP & XAVP

### AVP (Attribute-Value Pairs)
Stack-like, multiple values per name, transaction scope.

```kamailio
$avp(myavp) = "value1";    # Push value
$avp(myavp) = "value2";    # Push another (stack)
$var(v) = $avp(myavp);     # Get top value ("value2")
$var(v) = $avp(myavp)[0];  # First (top)
$var(v) = $avp(myavp)[1];  # Second
$avp(myavp) = $null;       # Delete all values
```

### XAVP (Extended AVP)
Supports nested structures with named fields.

```kamailio
$xavp(root=>field) = "value";
$xavp(root[0]=>field) = "value";  # Specific index
$var(v) = $xavp(root=>field);
$xavp(root) = $null;              # Delete
```

### XAVU (Single-value Extended AVP)
```kamailio
$xavu(name=>field) = "value";   # Single value (no stack)
```

### XAVI (Case-insensitive Extended AVP)
```kamailio
$xavi(Name=>Field) = "value";   # Case-insensitive keys
```

**Multi-value access:**
```kamailio
$avp(trunks) = $var(trunk1);
$avp(trunks) = $var(trunk2);
# Access: $(avp(trunks)[$var(idx)])
```

---

## Dialog Variables

Require dialog module. Persist across dialog lifetime.

```kamailio
$dlg_var(myvar) = "value";
if($dlg_var(myvar) != $null) { ... }
```

**Common pattern:**
```kamailio
route[AUTH] {
    $dlg_var(client_id) = $xavp(res=>id);
    $dlg_var(created_at) = $(Ts{s.ftime,%Y-%m-%d %H:%M:%S});
}
```

---

## Time Variables

| Variable | R/W | Description |
|----------|-----|-------------|
| `$Ts` | R | Cached Unix timestamp |
| `$TS` | R | Current Unix timestamp (recomputed) |
| `$Tf` | R | Cached formatted time string |
| `$TF` | R | Current formatted time (recomputed) |
| `$Tb` | R | Startup/boot timestamp |
| `$time(name)` | R | Broken-down local time components |
| `$utime(name)` | R | Broken-down UTC time components |
| `$timef(format)` | R | Strftime-formatted local time |
| `$utimef(format)` | R | Strftime-formatted UTC time |
| `$TV(name)` | R | Seconds and microseconds |

**Formatting:**
```kamailio
$(Ts{s.ftime,%Y-%m-%d %H:%M:%S})  # 2024-01-15 14:30:00
$time(hour)                        # Current hour
$timef(%H:%M)                      # 14:30
```

---

## Authentication

| Variable | R/W | Description |
|----------|-----|-------------|
| `$au` | R | Username from Authorization header |
| `$ad` | R | Domain from Authorization header |
| `$aU` | R | Complete username from Authorization header |
| `$aa` | R | Algorithm from Authorization header |
| `$ar` | R | Realm from Authorization header |
| `$adu` | R | Digest URI from Authorization header |
| `$Au` | R | Accounting username (auth or From) |
| `$AU` | R | Accounting username only (auth or From) |

---

## P-Asserted/P-Preferred Identity

| Variable | R/W | Description |
|----------|-----|-------------|
| `$ai` | R | P-Asserted-Identity header URI |
| `$pu` | R | P-Preferred-Identity header URI |
| `$pU` | R | Username in P-Preferred-Identity |
| `$pd` | R | Domain in P-Preferred-Identity |
| `$pn` | R | Display name in P-Preferred-Identity |

---

## Other Header Variables

| Variable | R/W | Description |
|----------|-----|-------------|
| `$di` | R | Diversion header URI |
| `$dip` | R | Privacy parameter from Diversion |
| `$dir` | R | Reason parameter from Diversion |
| `$dic` | R | Counter parameter from Diversion |
| `$re` | R | Remote-Party-ID header URI |
| `$rt` | R | Refer-To header URI |

---

## Flags

| Variable | R/W | Description |
|----------|-----|-------------|
| `$mf` | RW | Message/transaction flags (decimal) |
| `$mF` | RW | Message/transaction flags (hexadecimal) |
| `$sf` | RW | Script flags (decimal) |
| `$sF` | RW | Script flags (hexadecimal) |
| `$bf` | RW | Branch flags (decimal) |
| `$bF` | RW | Branch flags (hexadecimal) |

**Usage:**
```kamailio
setflag(1);
if(isflagset(1)) { ... }
resetflag(1);
```

---

## Branch Variables

| Variable | R/W | Description |
|----------|-----|-------------|
| `$br` | RW | First branch of request |
| `$bR` | R | All branches of request |
| `$branch(name)` | RW | Named attributes of branch |
| `$sbranch(attr)` | RW | Static branch attributes |

---

## Process/System

| Variable | R/W | Description |
|----------|-----|-------------|
| `$pp` | R | Process ID |
| `$sid` | R | Server ID |
| `$version()` | R | Version as number or full string |
| `$env(NAME)` | R | Environment variable value |
| `$RANDOM` | R | Random number |
| `$K(key)` | R | Kamailio constants |

---

## Special Variables

| Variable | R/W | Description |
|----------|-----|-------------|
| `$null` | R | Null value (for deletion/reset) |
| `$$` | R | Literal dollar sign character |
| `$_s(format)` | R | Evaluates all pseudo-variables within format string |
| `$def(name)` | R | Preprocessor-defined value |
| `$defn(name)` | R | Preprocessor-defined numeric value |
| `$cnt(pv)` | R | Count of AVP/XAVP occurrences |
| `$expires(key)` | R | Min/max expires from headers |
| `$stat(name)` | R | Statistics value |
| `$ruid` | R | Record unique ID from location |
| `$sruid` | R | Unique system ID |

---

## Module-Specific Variables

### Dialog Module (dlg)
```kamailio
$dlg(callid)      # Dialog Call-ID
$dlg(state)       # Dialog state
$dlg(timeout)     # Timeout value
$dlg(lifetime)    # Dialog lifetime
$dlg_ctx(timeout) # Context timeout
$dlg_var(key)     # Custom dialog variables
$rdir(key)        # Request direction in dialog
```

### Transaction Module (tm/tmx)
```kamailio
$T_branch_idx     # Current branch index in transaction
$T_reply_code     # Reply code of transaction
$T_reply_ruid     # Record ID of transaction branch
$T_req(pv)        # Request attributes in reply context
$T_rpl(pv)        # Reply attributes in failure context
$T_inv(pv)        # INVITE request attributes
$T(name)          # Transaction metadata
$T_branch(name)   # Transaction branch metadata
```

### HTable Module
```kamailio
$sht(htable=>key)     # Hash table entry
$shtex(htable=>key)   # Hash table entry expiry
$shtcn(htable=>exp)   # Count entries by name
$shtcv(htable=>exp)   # Count entries by value
$shtinc(htable=>key)  # Atomic increment
$shtdec(htable=>key)  # Atomic decrement
```

### HTTP Async Client Module
```kamailio
$http_req_id      # Request unique ID
$http_req(key)    # Set custom HTTP parameters
$http_ok          # Success flag (in callback)
$http_err         # Error message (in callback)
$http_rs          # HTTP status code (in callback)
$http_rr          # HTTP reason phrase (in callback)
$http_hdr(Name)   # Response header value
$http_mb          # Response buffer
$http_ml          # Response length
$http_rb          # Response body
$http_bs          # Response body size
```

### NDB_REDIS Module
```kamailio
$redis(res=>key)  # Redis response attributes
$redisd(key)      # Redis reply type constants
```

### GeoIP Modules
```kamailio
$gip(pvc=>key)    # GeoIP location attributes
$gip2(pvc=>key)   # GeoIP2 location attributes
```

### Via Header Variables
```kamailio
$via0(attr)       # First Via header attributes
$via1(attr)       # Second Via header attributes
$viaZ(attr)       # Last Via header attributes
```

### TLS Module
```kamailio
$tls(key)              # TLS connection attributes
$tls_version           # TLS/SSL version string
$tls_cipher_info       # Cipher information
$tls_peer_verified     # Peer verification status
$tls_peer_subject      # Peer subject line
$tls_peer_issuer       # Peer issuer line
$tls_peer_subject_cn   # Peer common name
```

### Record-Route Module
```kamailio
$rr_count         # Count of Record-Route headers
$rr_top_count     # Count of top Record-Route bodies
```

### UAC Module
```kamailio
$uac_req(key)     # UAC request parameters
```

### Dispatcher Module
```kamailio
$dsv(key)         # Dispatcher module attributes
```

---

## Legend

- **R** = Read-only
- **RW** = Read-write
