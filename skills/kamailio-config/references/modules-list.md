# Kamailio Modules Reference

Complete list of available Kamailio modules (v6.0.x).

**Documentation**: https://kamailio.org/docs/modules/6.0.x/

## Core/Essential Modules

| Module | Description | Docs |
|--------|-------------|------|
| `tm` | Transaction (stateful) module | [tm](https://kamailio.org/docs/modules/6.0.x/modules/tm.html) |
| `sl` | Stateless replier module | [sl](https://kamailio.org/docs/modules/6.0.x/modules/sl.html) |
| `rr` | Record-Route and Route module | [rr](https://kamailio.org/docs/modules/6.0.x/modules/rr.html) |
| `pv` | Module holding Pseudo-Variables | [pv](https://kamailio.org/docs/modules/6.0.x/modules/pv.html) |
| `maxfwd` | Max-Forward processor module | [maxfwd](https://kamailio.org/docs/modules/6.0.x/modules/maxfwd.html) |
| `textops` | Text operations module | [textops](https://kamailio.org/docs/modules/6.0.x/modules/textops.html) |
| `siputils` | SIP utilities | [siputils](https://kamailio.org/docs/modules/6.0.x/modules/siputils.html) |
| `sanity` | SIP message formatting sanity checks | [sanity](https://kamailio.org/docs/modules/6.0.x/modules/sanity.html) |
| `xlog` | Advanced logger module | [xlog](https://kamailio.org/docs/modules/6.0.x/modules/xlog.html) |
| `kex` | Kamailio core extensions module | [kex](https://kamailio.org/docs/modules/6.0.x/modules/kex.html) |
| `corex` | Core extensions via module interface | [corex](https://kamailio.org/docs/modules/6.0.x/modules/corex.html) |

## Dialog & Transaction

| Module | Description | Docs |
|--------|-------------|------|
| `dialog` | Dialog support module | [dialog](https://kamailio.org/docs/modules/6.0.x/modules/dialog.html) |
| `tmx` | Transaction management extensions | [tmx](https://kamailio.org/docs/modules/6.0.x/modules/tmx.html) |
| `dlgs` | Lightweight stateless dialog tracking | [dlgs](https://kamailio.org/docs/modules/6.0.x/modules/dlgs.html) |

## Accounting & CDR

| Module | Description | Docs |
|--------|-------------|------|
| `acc` | Accounting module | [acc](https://kamailio.org/docs/modules/6.0.x/modules/acc.html) |
| `acc_json` | Accounting with JSON to MQueue | [acc_json](https://kamailio.org/docs/modules/6.0.x/modules/acc_json.html) |
| `acc_radius` | Accounting for RADIUS backend | [acc_radius](https://kamailio.org/docs/modules/6.0.x/modules/acc_radius.html) |

## Database Drivers

| Module | Description | Docs |
|--------|-------------|------|
| `db_postgres` | PostgreSQL backend | [db_postgres](https://kamailio.org/docs/modules/6.0.x/modules/db_postgres.html) |
| `db_mysql` | MySQL backend | [db_mysql](https://kamailio.org/docs/modules/6.0.x/modules/db_mysql.html) |
| `db_sqlite` | SQLite backend | [db_sqlite](https://kamailio.org/docs/modules/6.0.x/modules/db_sqlite.html) |
| `db_text` | Text-file backend | [db_text](https://kamailio.org/docs/modules/6.0.x/modules/db_text.html) |
| `db_redis` | Redis backend | [db_redis](https://kamailio.org/docs/modules/6.0.x/modules/db_redis.html) |
| `db_mongodb` | MongoDB connector | [db_mongodb](https://kamailio.org/docs/modules/6.0.x/modules/db_mongodb.html) |
| `db_cluster` | Database connectors clustering | [db_cluster](https://kamailio.org/docs/modules/6.0.x/modules/db_cluster.html) |

## SQL & Data Operations

| Module | Description | Docs |
|--------|-------------|------|
| `sqlops` | SQL operations | [sqlops](https://kamailio.org/docs/modules/6.0.x/modules/sqlops.html) |
| `avpops` | AVP operations module | [avpops](https://kamailio.org/docs/modules/6.0.x/modules/avpops.html) |
| `htable` | Generic Hash Table in shared memory | [htable](https://kamailio.org/docs/modules/6.0.x/modules/htable.html) |
| `mtree` | Generic memory caching with tree indexes | [mtree](https://kamailio.org/docs/modules/6.0.x/modules/mtree.html) |

## JSON & HTTP

| Module | Description | Docs |
|--------|-------------|------|
| `jansson` | JSON using jansson library | [jansson](https://kamailio.org/docs/modules/6.0.x/modules/jansson.html) |
| `json` | JSON using json-c library | [json](https://kamailio.org/docs/modules/6.0.x/modules/json.html) |
| `http_client` | Sync/async HTTP client (CURL) | [http_client](https://kamailio.org/docs/modules/6.0.x/modules/http_client.html) |
| `http_async_client` | Async HTTP client | [http_async_client](https://kamailio.org/docs/modules/6.0.x/modules/http_async_client.html) |
| `jsonrpcs` | JSON-RPC server over HTTP | [jsonrpcs](https://kamailio.org/docs/modules/6.0.x/modules/jsonrpcs.html) |
| `jsonrpcc` | JSON-RPC client over netstrings | [jsonrpcc](https://kamailio.org/docs/modules/6.0.x/modules/jsonrpcc.html) |

## Authentication

| Module | Description | Docs |
|--------|-------------|------|
| `auth` | Authentication Interface | [auth](https://kamailio.org/docs/modules/6.0.x/modules/auth.html) |
| `auth_db` | Database-backend authentication | [auth_db](https://kamailio.org/docs/modules/6.0.x/modules/auth_db.html) |
| `auth_radius` | RADIUS-backend authentication | [auth_radius](https://kamailio.org/docs/modules/6.0.x/modules/auth_radius.html) |
| `auth_xkeys` | Shared keys authentication | [auth_xkeys](https://kamailio.org/docs/modules/6.0.x/modules/auth_xkeys.html) |

## Registrar & Location

| Module | Description | Docs |
|--------|-------------|------|
| `registrar` | SIP Registrar implementation | [registrar](https://kamailio.org/docs/modules/6.0.x/modules/registrar.html) |
| `usrloc` | User location implementation | [usrloc](https://kamailio.org/docs/modules/6.0.x/modules/usrloc.html) |
| `p_usrloc` | Partitioned/distributed user location | [p_usrloc](https://kamailio.org/docs/modules/6.0.x/modules/p_usrloc.html) |

## Routing & Load Balancing

| Module | Description | Docs |
|--------|-------------|------|
| `dispatcher` | Dispatcher (load-balancer) | [dispatcher](https://kamailio.org/docs/modules/6.0.x/modules/dispatcher.html) |
| `lcr` | Least Cost Routing | [lcr](https://kamailio.org/docs/modules/6.0.x/modules/lcr.html) |
| `drouting` | Prefix routing module | [drouting](https://kamailio.org/docs/modules/6.0.x/modules/drouting.html) |
| `carrierroute` | Routing for carriers | [carrierroute](https://kamailio.org/docs/modules/6.0.x/modules/carrierroute.html) |
| `dialplan` | Dialplan translation | [dialplan](https://kamailio.org/docs/modules/6.0.x/modules/dialplan.html) |
| `prefix_route` | Route blocks based on prefix | [prefix_route](https://kamailio.org/docs/modules/6.0.x/modules/prefix_route.html) |
| `rtjson` | SIP routing based on JSON API | [rtjson](https://kamailio.org/docs/modules/6.0.x/modules/rtjson.html) |

## NAT Traversal & Media

| Module | Description | Docs |
|--------|-------------|------|
| `nathelper` | NAT traversal - signaling functions | [nathelper](https://kamailio.org/docs/modules/6.0.x/modules/nathelper.html) |
| `rtpproxy` | RTPProxy media relay control | [rtpproxy](https://kamailio.org/docs/modules/6.0.x/modules/rtpproxy.html) |
| `rtpengine` | RTPEngine media relay control | [rtpengine](https://kamailio.org/docs/modules/6.0.x/modules/rtpengine.html) |
| `mediaproxy` | NAT traversal using mediaproxy | [mediaproxy](https://kamailio.org/docs/modules/6.0.x/modules/mediaproxy.html) |
| `sdpops` | SDP operations | [sdpops](https://kamailio.org/docs/modules/6.0.x/modules/sdpops.html) |

## Security & Filtering

| Module | Description | Docs |
|--------|-------------|------|
| `permissions` | Permissions control | [permissions](https://kamailio.org/docs/modules/6.0.x/modules/permissions.html) |
| `pike` | Flood detector | [pike](https://kamailio.org/docs/modules/6.0.x/modules/pike.html) |
| `secfilter` | SIP security filtering rules | [secfilter](https://kamailio.org/docs/modules/6.0.x/modules/secfilter.html) |
| `userblocklist` | User specific blocklists | [userblocklist](https://kamailio.org/docs/modules/6.0.x/modules/userblocklist.html) |
| `pipelimit` | Traffic shaping policies | [pipelimit](https://kamailio.org/docs/modules/6.0.x/modules/pipelimit.html) |
| `ratelimit` | Traffic shaping module | [ratelimit](https://kamailio.org/docs/modules/6.0.x/modules/ratelimit.html) |

## TLS & Encryption

| Module | Description | Docs |
|--------|-------------|------|
| `tls` | TLS operations module | [tls](https://kamailio.org/docs/modules/6.0.x/modules/tls.html) |
| `crypto` | Cryptographic extensions | [crypto](https://kamailio.org/docs/modules/6.0.x/modules/crypto.html) |
| `secsipid` | STIR/SHAKEN extensions | [secsipid](https://kamailio.org/docs/modules/6.0.x/modules/secsipid.html) |
| `stirshaken` | STIR/SHAKEN using libstirshaken | [stirshaken](https://kamailio.org/docs/modules/6.0.x/modules/stirshaken.html) |

## Presence & IM

| Module | Description | Docs |
|--------|-------------|------|
| `presence` | Presence server - common API | [presence](https://kamailio.org/docs/modules/6.0.x/modules/presence.html) |
| `presence_xml` | Presence - watcher info and XCAP | [presence_xml](https://kamailio.org/docs/modules/6.0.x/modules/presence_xml.html) |
| `presence_dialoginfo` | Presence - Dialog Info | [presence_dialoginfo](https://kamailio.org/docs/modules/6.0.x/modules/presence_dialoginfo.html) |
| `pua` | Common API for presence UA client | [pua](https://kamailio.org/docs/modules/6.0.x/modules/pua.html) |
| `rls` | Resource List Server | [rls](https://kamailio.org/docs/modules/6.0.x/modules/rls.html) |

## Management & RPC

| Module | Description | Docs |
|--------|-------------|------|
| `ctl` | Control connector for RPC | [ctl](https://kamailio.org/docs/modules/6.0.x/modules/ctl.html) |
| `cfg_rpc` | Update parameters at runtime via RPC | [cfg_rpc](https://kamailio.org/docs/modules/6.0.x/modules/cfg_rpc.html) |
| `counters` | Internal counter API | [counters](https://kamailio.org/docs/modules/6.0.x/modules/counters.html) |
| `statistics` | Script statistics support | [statistics](https://kamailio.org/docs/modules/6.0.x/modules/statistics.html) |
| `debugger` | Interactive config debugger | [debugger](https://kamailio.org/docs/modules/6.0.x/modules/debugger.html) |
| `benchmark` | Config file benchmarking | [benchmark](https://kamailio.org/docs/modules/6.0.x/modules/benchmark.html) |

## WebSocket & HTTP Server

| Module | Description | Docs |
|--------|-------------|------|
| `websocket` | WebSocket transport layer | [websocket](https://kamailio.org/docs/modules/6.0.x/modules/websocket.html) |
| `xhttp` | Basic HTTP request handling | [xhttp](https://kamailio.org/docs/modules/6.0.x/modules/xhttp.html) |
| `xhttp_rpc` | RPC commands over HTTP | [xhttp_rpc](https://kamailio.org/docs/modules/6.0.x/modules/xhttp_rpc.html) |
| `xhttp_prom` | Prometheus metrics over HTTP | [xhttp_prom](https://kamailio.org/docs/modules/6.0.x/modules/xhttp_prom.html) |

## Tracing & Capture

| Module | Description | Docs |
|--------|-------------|------|
| `siptrace` | SIP traffic tracing | [siptrace](https://kamailio.org/docs/modules/6.0.x/modules/siptrace.html) |
| `sipcapture` | SIP capture server (Homer) | [sipcapture](https://kamailio.org/docs/modules/6.0.x/modules/sipcapture.html) |
| `sipdump` | Save SIP traffic and attributes | [sipdump](https://kamailio.org/docs/modules/6.0.x/modules/sipdump.html) |

## Message Queues & Events

| Module | Description | Docs |
|--------|-------------|------|
| `mqueue` | Message queue system | [mqueue](https://kamailio.org/docs/modules/6.0.x/modules/mqueue.html) |
| `evapi` | Network event broadcast API | [evapi](https://kamailio.org/docs/modules/6.0.x/modules/evapi.html) |
| `dmq` | Distributed Message Queue (SIP) | [dmq](https://kamailio.org/docs/modules/6.0.x/modules/dmq.html) |
| `rabbitmq` | RabbitMQ client | [rabbitmq](https://kamailio.org/docs/modules/6.0.x/modules/rabbitmq.html) |
| `kafka` | Kafka producer | [kafka](https://kamailio.org/docs/modules/6.0.x/modules/kafka.html) |
| `nats` | NATS PubSub connector | [nats](https://kamailio.org/docs/modules/6.0.x/modules/nats.html) |
| `nsq` | NSQ consumer | [nsq](https://kamailio.org/docs/modules/6.0.x/modules/nsq.html) |

## NoSQL Connectors

| Module | Description | Docs |
|--------|-------------|------|
| `ndb_redis` | Redis NoSQL connector | [ndb_redis](https://kamailio.org/docs/modules/6.0.x/modules/ndb_redis.html) |
| `ndb_mongodb` | MongoDB NoSQL connector | [ndb_mongodb](https://kamailio.org/docs/modules/6.0.x/modules/ndb_mongodb.html) |
| `ndb_cassandra` | Cassandra NoSQL connector | [ndb_cassandra](https://kamailio.org/docs/modules/6.0.x/modules/ndb_cassandra.html) |
| `memcached` | Memcached connector | [memcached](https://kamailio.org/docs/modules/6.0.x/modules/memcached.html) |

## Scripting Languages

| Module | Description | Docs |
|--------|-------------|------|
| `app_lua` | Embedded Lua scripts | [app_lua](https://kamailio.org/docs/modules/6.0.x/modules/app_lua.html) |
| `app_python3` | Embedded Python3 scripts | [app_python3](https://kamailio.org/docs/modules/6.0.x/modules/app_python3.html) |
| `app_perl` | Embedded Perl functions | [app_perl](https://kamailio.org/docs/modules/6.0.x/modules/app_perl.html) |
| `app_jsdt` | Embedded JavaScript scripts | [app_jsdt](https://kamailio.org/docs/modules/6.0.x/modules/app_jsdt.html) |
| `app_ruby` | Embedded Ruby scripts | [app_ruby](https://kamailio.org/docs/modules/6.0.x/modules/app_ruby.html) |

## Utilities

| Module | Description | Docs |
|--------|-------------|------|
| `cfgutils` | Different config utilities | [cfgutils](https://kamailio.org/docs/modules/6.0.x/modules/cfgutils.html) |
| `ipops` | IP and DNS related operations | [ipops](https://kamailio.org/docs/modules/6.0.x/modules/ipops.html) |
| `regex` | Regular expression matching (PCRE) | [regex](https://kamailio.org/docs/modules/6.0.x/modules/regex.html) |
| `exec` | External application execution | [exec](https://kamailio.org/docs/modules/6.0.x/modules/exec.html) |
| `utils` | Set of useful functions | [utils](https://kamailio.org/docs/modules/6.0.x/modules/utils.html) |
| `geoip2` | GeoIP API with IPv6 support | [geoip2](https://kamailio.org/docs/modules/6.0.x/modules/geoip2.html) |
| `phonenum` | Phone number lookup (libphonenumber) | [phonenum](https://kamailio.org/docs/modules/6.0.x/modules/phonenum.html) |

## UAC Functions

| Module | Description | Docs |
|--------|-------------|------|
| `uac` | UAC functionalities (FROM mangling, auth) | [uac](https://kamailio.org/docs/modules/6.0.x/modules/uac.html) |
| `uac_redirect` | UAC redirection functionality | [uac_redirect](https://kamailio.org/docs/modules/6.0.x/modules/uac_redirect.html) |

## Topology Hiding

| Module | Description | Docs |
|--------|-------------|------|
| `topoh` | Topology hiding | [topoh](https://kamailio.org/docs/modules/6.0.x/modules/topoh.html) |
| `topos` | Topology stripping | [topos](https://kamailio.org/docs/modules/6.0.x/modules/topos.html) |

## External Links

- **All Modules**: https://kamailio.org/docs/modules/6.0.x/
- **Wiki Cookbooks**: https://www.kamailio.org/wikidocs/cookbooks/6.0.x/
- **GitHub Source**: https://github.com/kamailio/kamailio/tree/master/src/modules
