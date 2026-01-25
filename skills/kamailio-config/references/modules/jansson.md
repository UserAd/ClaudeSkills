# Jansson Module

JSON parsing and manipulation using libjansson.

## Load
```kamailio
loadmodule "jansson.so"
```

## Functions

### jansson_get
Extract value from JSON at path.

```kamailio
jansson_get("path", "json_string", "$var(result)");
```

**Path syntax:**
- Dot notation: `foo.bar.baz`
- Array index: `list[0]`
- Combined: `data.items[2].name`

**Returns:** FALSE if parse fails, TRUE otherwise.

```kamailio
$var(json) = '{"user":"john","id":123,"tags":["a","b"]}';

jansson_get("user", $var(json), "$var(name)");     # "john"
jansson_get("id", $var(json), "$var(id)");         # 123
jansson_get("tags[0]", $var(json), "$var(tag)");   # "a"
```

### jansson_pv_get
Same as jansson_get but source must be variable reference.

```kamailio
jansson_pv_get("user", "$var(json)", "$var(name)");
```

### jansson_set
Insert value into JSON.

```kamailio
jansson_set("type", "path", "value", "$var(result)");
```

**Types:** `string`/`str`, `integer`/`int`, `real`, `object`/`obj`, `array`, `true`, `false`, `null`

```kamailio
$var(json) = "{}";
jansson_set("string", "name", "John", "$var(json)");
jansson_set("integer", "age", 30, "$var(json)");
jansson_set("object", "data", '{"x":1}', "$var(json)");
# Result: {"name":"John","age":30,"data":{"x":1}}
```

### jansson_append
Append to array or merge objects.

```kamailio
$var(arr) = "[]";
jansson_append("int", "", 1, "$var(arr)");
jansson_append("int", "", 2, "$var(arr)");
# Result: [1,2]

# Append to nested array
jansson_append("string", "tags", "new", "$var(json)");
```

### jansson_array_size
Get array length.

```kamailio
jansson_array_size("path", $var(json), "$var(size)");
```

### jansson_xdecode
Parse JSON into XAVP structure.

```kamailio
jansson_xdecode('{"foo":"bar","num":123}', "data");
xlog("foo = $xavp(data=>foo)\n");   # bar
xlog("num = $xavp(data=>num)\n");   # 123
```

### jansson_xencode
Encode XAVP as JSON.

```kamailio
$xavp(data=>name) = "test";
$xavp(data=>value) = 42;
jansson_xencode("data", "$var(json)");
# Result: {"name":"test","value":42}
```

### jansson_get_field
Get field without path parsing (for field names with dots).

```kamailio
jansson_get_field("foo.bar", '{"foo.bar":"value"}', "$var(v)");
# Returns "value" (treats "foo.bar" as literal field name)
```

## Usage Patterns

### Parse HTTP API Response
```kamailio
route[LCR] {
    http_client_query("http://api/routes?num=$rU", "$var(resp)");

    # Check routes array
    if(!jansson_get("routes", $var(resp), "$var(routes)")) {
        sl_send_reply("486", "No routes");
        exit;
    }

    jansson_array_size("routes", $var(resp), "$var(count)");

    if($var(count) == 0) {
        sl_send_reply("486", "No routes available");
        exit;
    }

    # Iterate routes
    $var(i) = 0;
    while($var(i) < $var(count)) {
        jansson_get("routes[$var(i)]", $var(resp), "$var(route)");
        $avp(routes) = $var(route);
        $var(i) = $var(i) + 1;
    }
}
```

### Access Route Details
```kamailio
route[PROCESS_ROUTE] {
    # Access current route from AVP stack
    jansson_get("host", "$(avp(routes)[$avp(idx)])", "$var(host)");
    jansson_get("port", "$(avp(routes)[$avp(idx)])", "$var(port)");
    jansson_get("trunk_id", "$(avp(routes)[$avp(idx)])", "$var(trunk_id)");

    $du = "sip:" + $var(host) + ":" + $var(port);
}
```

### Build JSON Request
```kamailio
$var(req) = "{}";
jansson_set("string", "callid", "$ci", "$var(req)");
jansson_set("string", "from", "$fU", "$var(req)");
jansson_set("string", "to", "$rU", "$var(req)");
jansson_set("integer", "timestamp", "$Ts", "$var(req)");

http_connect("api", "/notify", "application/json",
    $var(req), "$var(resp)");
```

## Common Errors

**Extra parenthesis in destination:**
```kamailio
# WRONG - extra )
jansson_get("routes", $var(json), "$var(routes))");

# CORRECT
jansson_get("routes", $var(json), "$var(routes)");
```

**Missing quotes around JSON source:**
```kamailio
# WRONG - unquoted literal
jansson_get("key", {invalid}, "$var(v)");

# CORRECT - quoted
jansson_get("key", '{"key":"value"}', "$var(v)");
jansson_get("key", $var(json), "$var(v)");
```
