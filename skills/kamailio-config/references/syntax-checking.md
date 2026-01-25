# Kamailio Configuration Syntax Checking

## Quick Check (Recommended)

Use the provided script for syntax validation:

```bash
# Default (validates kamailio/kamailio.cfg)
.claude/skills/kamailio-config/scripts/check-kamailio.sh

# Custom config path
.claude/skills/kamailio-config/scripts/check-kamailio.sh path/to/config.cfg
```

**Exit codes**: 0 = valid (PASS), non-zero = syntax error (FAIL)

The script automatically:
- Builds the Docker test container if missing
- Substitutes environment variable placeholders with test values
- Runs kamailio syntax check
- Reports PASS/FAIL result

---

## Project Environment Variables

| Placeholder | Description | Test Value |
|-------------|-------------|------------|
| `DB_HOST` | PostgreSQL host | `127.0.0.1` |
| `DB_NAME` | Database name | `testdb` |
| `DB_USER` | Database user | `testuser` |
| `DB_PASSWORD` | Database password | `testpass` |
| `DOMAIN` | SIP domain | `localhost` |
| `ADVERTISE_IP` | Public IP for SIP | `127.0.0.1` |

---

## ARM64 / Apple Silicon Note

The Kamailio Docker image only supports `linux/amd64`. The script uses `--platform linux/amd64` flag automatically (runs via Rosetta emulation on Apple Silicon).

---

## Generic Validation Methods

### Local Check (if kamailio installed)
```bash
kamailio -c -f /path/to/kamailio.cfg
```

### Command Options

| Flag | Description |
|------|-------------|
| `-c` | Check config syntax only (don't start) |
| `-f <file>` | Specify config file |
| `-D` | Control debug mode |
| `-dd` | Increase debug verbosity |
| `-E` | Log to stderr |

---

## Common Syntax Errors

### Missing Semicolon
```
ERROR: parse error at line 45, column 1-5: syntax error, unexpected $end
```
**Fix:** Add semicolon at end of statement.

### Undefined Module
```
ERROR: failed to load module: xyz.so
```
**Fix:** Add `loadmodule "xyz.so"` or remove function call.

### Undefined Variable
```
ERROR: unknown pseudo variable
```
**Fix:** Check PV syntax, ensure module is loaded.

### Wrong Parameter Type
```
ERROR: modparam("module", "param", value): bad value type
```
**Fix:** Check if parameter expects int vs string.

### Duplicate Route
```
ERROR: duplicate route block
```
**Fix:** Rename or merge route blocks.

---

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Check Kamailio Config
  run: .claude/skills/kamailio-config/scripts/check-kamailio.sh
```

---

## Template Variable Handling

This project uses sed-based substitution in `kamailio/start-kamailio.sh`:

```bash
# Production substitution (from start-kamailio.sh)
sed -e "s/DB_NAME/${DB_NAME}/g" \
    -e "s/DB_USER/${DB_USER}/g" \
    -e "s/DB_PASSWORD/${DB_PASSWORD}/g" \
    -e "s/DB_HOST/${DB_HOST}/g" \
    -e "s/DOMAIN/${DOMAIN}/g" \
    /tmp/kamailio.cfg.template > /etc/kamailio/kamailio.cfg
```

For validation, the script uses dummy test values automatically.
