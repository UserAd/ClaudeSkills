# SQLOps Module

Execute raw SQL queries in Kamailio configuration.

## Load
```kamailio
loadmodule "db_postgres.so"  # or db_mysql.so
loadmodule "sqlops.so"
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `sqlcon` | - | Connection definition |
| `connect_mode` | 0 | 0=fail on error, 1=continue |
| `results_maxsize` | 32 | Max result containers |

```kamailio
modparam("sqlops", "sqlcon",
    "rw=>postgres://user:pass@host/dbname")
```

## Functions

### sql_query
Execute query, store result.

```kamailio
sql_query("rw", "SELECT * FROM table", "res");
# Returns: -1=error, 1=rows, 2=no rows, 3=success (no result needed)
```

### sql_xquery
Store results in XAVP (recommended).

```kamailio
$var(r) = sql_xquery("rw",
    "SELECT id, name FROM clients WHERE api_key='$var(key)' LIMIT 1",
    "res");

if($var(r) == 1) {
    xlog("Found: $xavp(res=>id) $xavp(res=>name)\n");
}

sql_result_free("res");
```

### sql_pvquery
Direct PV assignment.

```kamailio
sql_pvquery("rw",
    "SELECT id, name FROM clients LIMIT 1",
    "$var(id), $var(name)");
```

### sql_query_async
Non-blocking (no result).

```kamailio
sql_query_async("rw", "INSERT INTO logs VALUES(...)");
```

### sql_result_free
Free result memory.

```kamailio
sql_result_free("res");
```

## Result Access

### With sql_query
```kamailio
$dbr(res=>rows)      # Row count
$dbr(res=>cols)      # Column count
$dbr(res=>[0,0])     # First row, first col
$dbr(res=>[0,1])     # First row, second col
```

### With sql_xquery (Recommended)
```kamailio
$xavp(res=>column_name)       # By column name
$xavp(res[0]=>column_name)    # Specific row
```

## Usage Patterns

### Authentication
```kamailio
route[AUTH] {
    if($hdr(X-APIID) == $null) {
        sl_send_reply(401, "Auth required");
        exit;
    }

    $var(key) = $hdr(X-APIID);

    # Escape user input!
    $var(r) = sql_xquery("rw",
        "SELECT id, trunkset_id, pricelist_id
         FROM clients
         WHERE api_key='$(var(key){s.escape.common})'
         AND enabled='1'
         LIMIT 1",
        "res");

    if($var(r) != 1) {
        sql_result_free("res");
        sl_send_reply(401, "Invalid credentials");
        exit;
    }

    $avp(client_id) = $xavp(res=>id);
    $avp(trunkset_id) = $xavp(res=>trunkset_id);
    $avp(pricelist_id) = $xavp(res=>pricelist_id);

    sql_result_free("res");
}
```

### Insert with Logging
```kamailio
sql_query_async("rw",
    "INSERT INTO call_log (callid, src, dst, time)
     VALUES ('$ci', '$fU', '$rU', NOW())");
```

## SQL Transformations

Safely format values for SQL:

```kamailio
$(var(x){sql.val})       # Auto-type
$(var(x){sql.val.int})   # As integer
$(var(x){sql.val.str})   # As quoted string
```

## Security

**Always escape user input:**
```kamailio
# BAD - SQL injection risk
sql_query("rw", "SELECT * FROM users WHERE name='$fU'", "r");

# GOOD - escaped
sql_query("rw",
    "SELECT * FROM users WHERE name='$(fU{s.escape.common})'",
    "r");
```

## Multiple Connections

```kamailio
modparam("sqlops", "sqlcon", "read=>postgres://ro_user:pass@slave/db")
modparam("sqlops", "sqlcon", "write=>postgres://rw_user:pass@master/db")

# Use appropriate connection
sql_query("read", "SELECT ...", "res");
sql_query_async("write", "INSERT ...");
```
