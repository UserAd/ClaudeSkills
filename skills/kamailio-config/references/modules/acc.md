# ACC Module - Accounting

Logs SIP transactions to syslog or database. Generates CDRs with dialog module.

## Load
```kamailio
loadmodule "acc.so"
```

## Key Parameters

### Flags
| Parameter | Description |
|-----------|-------------|
| `log_flag` | Flag for syslog accounting |
| `db_flag` | Flag for DB accounting |
| `log_missed_flag` | Log missed calls |
| `db_missed_flag` | DB missed calls |
| `failed_transaction_flag` | Account failures |

### Database
| Parameter | Default | Description |
|-----------|---------|-------------|
| `db_url` | - | Database connection |
| `db_table_acc` | "acc" | Success table |
| `db_table_missed_calls` | "missed_calls" | Missed table |

### CDR
| Parameter | Default | Description |
|-----------|---------|-------------|
| `cdr_enable` | 0 | Enable CDR generation |
| `cdrs_table` | "" | CDR database table |
| `cdr_on_failed` | 1 | CDR for failed calls |
| `cdr_start_on_confirmed` | 0 | Start from 200 OK |
| `cdr_extra` | - | Custom CDR fields |

### Extra Fields
| Parameter | Description |
|-----------|-------------|
| `log_extra` | Syslog extra fields |
| `db_extra` | Database extra fields |

## Configuration Example

```kamailio
modparam("acc", "db_url", "postgres://user:pass@host/db")

# Flags
modparam("acc", "log_flag", 1)
modparam("acc", "db_flag", 1)
modparam("acc", "log_missed_flag", 2)
modparam("acc", "db_missed_flag", 2)
modparam("acc", "failed_transaction_flag", 3)

# Extra fields (semicolon-separated)
modparam("acc", "log_extra",
    "src_user=$fU;src_domain=$fd;src_ip=$si;"
    "dst_user=$rU;dst_domain=$rd;client_id=$avp(client_id)")

modparam("acc", "db_extra",
    "src_user=$fU;src_domain=$fd;src_ip=$si;"
    "dst_user=$rU;dst_domain=$rd;client_id=$avp(client_id)")

# CDR Configuration (requires dialog module)
modparam("acc", "cdr_enable", 1)
modparam("acc", "cdr_on_failed", 1)
modparam("acc", "cdr_start_on_confirmed", 1)
modparam("acc", "cdrs_table", "cdrs")

# CDR extra uses dialog variables
modparam("acc", "cdr_extra",
    "client_id=$dlg_var(client_id);"
    "trunk_id=$dlg_var(trunk_id);"
    "a_number=$dlg_var(a_number);"
    "b_number=$dlg_var(b_number);"
    "sip_code=$dlg_var(sip_code)")

# Column names
modparam("acc", "db_table_acc", "call_events")
modparam("acc", "acc_callid_column", "callid")
modparam("acc", "acc_sip_code_column", "sip_code")
```

## Functions

| Function | Description |
|----------|-------------|
| `acc_log_request(comment)` | Log to syslog |
| `acc_db_request(comment, table)` | Log to database |
| `acc_request(comment, table)` | Log to both |

## Usage Pattern

```kamailio
#!define FLT_ACC 1
#!define FLT_ACCMISSED 2
#!define FLT_ACCFAILED 3

request_route {
    if(is_method("INVITE")) {
        setflag(FLT_ACC);

        # Initialize dialog for CDR
        if(!has_totag()) {
            dlg_manage();
            $dlg_var(client_id) = $avp(client_id);
        }
    }
    ...
}

route[WITHINDLG] {
    if(is_method("BYE")) {
        setflag(FLT_ACC);
        setflag(FLT_ACCFAILED);  # Account even if fails
    }
    ...
}

onreply_route[MANAGE_REPLY] {
    # Store response code for CDR
    if(is_method("INVITE|CANCEL")) {
        $dlg_var(sip_code) = $rs;
    }
}
```

## Fixed Fields

ACC always logs:
- Method
- From-tag
- To-tag
- Call-ID
- SIP code
- Reason
- Timestamp

## Database Schema

```sql
CREATE TABLE acc (
    id SERIAL PRIMARY KEY,
    method VARCHAR(16),
    from_tag VARCHAR(64),
    to_tag VARCHAR(64),
    callid VARCHAR(255),
    sip_code VARCHAR(3),
    sip_reason VARCHAR(128),
    time TIMESTAMP,
    -- Extra fields
    src_user VARCHAR(64),
    dst_user VARCHAR(64),
    client_id INTEGER
);

CREATE TABLE cdrs (
    id SERIAL PRIMARY KEY,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    duration DECIMAL(10,3),
    -- CDR extra fields
    client_id INTEGER,
    trunk_id INTEGER,
    a_number VARCHAR(32),
    b_number VARCHAR(32)
);
```
