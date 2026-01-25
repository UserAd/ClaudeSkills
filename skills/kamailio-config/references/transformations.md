# Kamailio Transformations Reference

## Syntax
```kamailio
$(pv{transformation})           # Single
$(pv{trans1}{trans2})           # Chained
$(var(x){s.len})                # Variable
$(hdr(Via){s.substr,0,10})      # Header
```

---

## String Transformations (s.*)

### Length & Type
| Transform | Description | Example |
|-----------|-------------|---------|
| `{s.len}` | String length | `$(var(x){s.len})` → 5 |
| `{s.int}` | Convert to integer | `$(var(x){s.int})` |

### Case & Whitespace
| Transform | Description |
|-----------|-------------|
| `{s.tolower}` | Lowercase |
| `{s.toupper}` | Uppercase |
| `{s.trim}` | Trim both ends |
| `{s.ltrim}` | Trim left |
| `{s.rtrim}` | Trim right |

### Substring & Selection
| Transform | Description |
|-----------|-------------|
| `{s.substr,offset,len}` | Substring (negative offset from end) |
| `{s.select,idx,sep}` | Split by separator, get index |
| `{s.before,x}` | Text before first x |
| `{s.after,x}` | Text after first x |

**Examples:**
```kamailio
$var(x) = "hello:world";
$(var(x){s.select,0,:})    # "hello"
$(var(x){s.select,1,:})    # "world"
$(var(x){s.before,:})      # "hello"
$(var(x){s.after,:})       # "world"

$var(y) = "abcdef";
$(var(y){s.substr,2,3})    # "cde"
$(var(y){s.substr,-3,0})   # "def"
```

### Replace
| Transform | Description |
|-----------|-------------|
| `{s.replace,match,repl}` | Replace all occurrences |
| `{s.numeric}` | Remove non-numeric chars |

### Hash Functions
| Transform | Output |
|-----------|--------|
| `{s.md5}` | MD5 hash |
| `{s.sha256}` | SHA-256 hash |
| `{s.sha384}` | SHA-384 hash |
| `{s.sha512}` | SHA-512 hash |

### Encoding/Decoding
| Transform | Description |
|-----------|-------------|
| `{s.encode.hexa}` | Hex encode |
| `{s.decode.hexa}` | Hex decode |
| `{s.encode.base64}` | Base64 encode |
| `{s.decode.base64}` | Base64 decode |
| `{s.encode.base64url}` | URL-safe base64 |
| `{s.decode.base64url}` | URL-safe base64 decode |

### Escaping
| Transform | Use Case |
|-----------|----------|
| `{s.escape.common}` | General escaping |
| `{s.escape.user}` | URI username |
| `{s.escape.param}` | URI parameter (URL encode) |
| `{s.escape.csv}` | CSV field |
| `{s.unescape.user}` | Decode user |
| `{s.unescape.param}` | URL decode |

**Common pattern:**
```kamailio
# URL encode for HTTP query
http_client_query("http://api/lcr?num=$(rU{s.escape.param})", "$var(r)");
```

---

## URI Transformations (uri.*)

Parse SIP URI components:

| Transform | Returns |
|-----------|---------|
| `{uri.user}` | Username |
| `{uri.host}` | Domain |
| `{uri.port}` | Port |
| `{uri.passwd}` | Password |
| `{uri.scheme}` | sip/sips/tel |
| `{uri.transport}` | Transport param |
| `{uri.params}` | All parameters |
| `{uri.param,name}` | Specific param |

### URI Construction
| Transform | Description |
|-----------|-------------|
| `{uri.duri}` | Destination URI (scheme:host:port;transport) |
| `{uri.saor}` | AoR (scheme:user@host) |
| `{uri.suri}` | Simple URI (user@host:port;transport) |

**Example:**
```kamailio
$var(uri) = "sip:user@domain.com:5060;transport=tcp";
$(var(uri){uri.user})      # "user"
$(var(uri){uri.host})      # "domain.com"
$(var(uri){uri.port})      # "5060"
$(var(uri){uri.transport}) # "tcp"
$(var(uri){uri.duri})      # "sip:domain.com:5060;transport=tcp"
```

---

## Parameter Transformations (param.*)

Parse name=value pairs (default separator: `;`).

| Transform | Description |
|-----------|-------------|
| `{param.value,name}` | Get param value |
| `{param.value,name,delim}` | Custom delimiter |
| `{param.in,name}` | Check exists (1/0) |
| `{param.valueat,idx}` | Value at index |
| `{param.name,idx}` | Name at index |
| `{param.count}` | Total params |

**Example:**
```kamailio
$var(p) = "a=1;b=2;c=3";
$(var(p){param.value,b})     # "2"
$(var(p){param.in,b})        # 1
$(var(p){param.count})       # 3
$(var(p){param.valueat,0})   # "1"
$(var(p){param.name,1})      # "b"
```

---

## Name-Address Transformations (nameaddr.*)

Parse `"Display" <uri>` format:

| Transform | Returns |
|-----------|---------|
| `{nameaddr.name}` | Display name |
| `{nameaddr.uri}` | URI |
| `{nameaddr.len}` | Total length |

**Example:**
```kamailio
$var(na) = '"John Doe" <sip:john@domain.com>';
$(var(na){nameaddr.name})  # "John Doe"
$(var(na){nameaddr.uri})   # "sip:john@domain.com"
```

---

## To-Body Transformations (tobody.*)

Access To header components:

| Transform | Returns |
|-----------|---------|
| `{tobody.uri}` | URI |
| `{tobody.user}` | Username |
| `{tobody.host}` | Domain |
| `{tobody.display}` | Display name |
| `{tobody.tag}` | Tag parameter |
| `{tobody.params}` | All parameters |

---

## Line Transformations (line.*)

| Transform | Description |
|-----------|-------------|
| `{line.count}` | Number of lines |
| `{line.at,pos}` | Line at position |
| `{line.sw,match}` | Lines starting with |

---

## Regex Transformations (re.*)

Requires textops module.

```kamailio
{re.subst,/pattern/replacement/flags}
```

**Flags:**
- `i` - Case insensitive
- `g` - Global (all matches)
- `s` - Dot matches newline

**Example:**
```kamailio
$var(x) = "Hello World";
$(var(x){re.subst,/world/universe/i})  # "Hello universe"
```

---

## SQL Transformations (sql.*)

Requires sqlops module.

| Transform | Description |
|-----------|-------------|
| `{sql.val}` | SQL-safe value |
| `{sql.val.int}` | Integer value |
| `{sql.val.str}` | String value (quoted) |

---

## JSON Transformation (json.*)

Requires json module.

```kamailio
{json.parse,field}
```

---

## Socket Transformations (sock.*)

| Transform | Returns |
|-----------|---------|
| `{sock.host}` | IP address |
| `{sock.port}` | Port |
| `{sock.proto}` | Protocol |
| `{sock.touri}` | As SIP URI |

---

## Value Transformations (val.*)

| Transform | Description |
|-----------|-------------|
| `{val.json}` | JSON encode value |
| `{val.jsonqe}` | JSON with quotes escaped |
| `{val.n0}` | Null as 0 |
| `{val.ne}` | Null as empty string |

---

## Common Patterns

### URL-safe HTTP query
```kamailio
$var(url) = "http://api/check?user=" + $(fU{s.escape.param});
```

### Parse header with delimiter
```kamailio
# X-APIID: prefix:key
$var(key) = $(hdr(X-APIID){s.select,1,:});
```

### Extract domain from URI
```kamailio
$var(domain) = $(ru{uri.host});
```

### Timestamp formatting
```kamailio
$dlg_var(created) = $(Ts{s.ftime,%Y-%m-%d %H:%M:%S});
```

### Chained transformations
```kamailio
$(hdr(Test){s.escape.common}{s.len})
$(var(x){param.value,$(var(x){param.name,1})}{s.len})
```
