# Discord runtime reliability investigation

Date: 2026-11-27

## Scope and source comparison

The bundled plugin is purple-discord revision
`2b85bbfad5e915f60f2c4ca30c1e7d720762c148` (recorded in
`third_party/purple-discord/UPSTREAM-REVISION`). The relevant upstream files
`purple2compat/http.c` and the reaction handlers were compared against that
revision; the observed defects were present in the vendored code. Local
changes in `libdiscord.c` also include Amethyst's account-consent and close
handling integration, which this work preserves. No upstream upgrade was
needed.

The supplied logs show successful DNS, IPv4 TCP, TLS 1.2 certificate
verification and successful HTTP transactions using NSS. They do not support
attributing those transactions to the XP OpenSSL changes. IPv6 remains an
independent variable: enabling it coincided with improvement in sending, but
XP sending was later reported intermittent.

## Findings and fixes

### HTTP response framing

The compatibility HTTP reader previously used `Content-Length`, completed
chunked transfer encoding, or EOF to decide when the response was complete.
Without a length header, a response on a persistent socket was treated as
close-delimited. That is incorrect for `HEAD`, 1xx, 204 and 304 responses,
whose response body ends at the header terminator. The typing API returns 204
with no body. Therefore the user's timeout trace is consistent with this
parser defect, though the captured trace alone did not establish the response
status.

The parser now classifies body framing by method/status and transfer headers.
It finishes bodyless responses at the end of headers, honors chunked framing
ahead of Content-Length, and retains length/EOF behavior for other responses.
Debug output records method, sanitized endpoint path, response status,
Content-Length presence/value, transfer encoding, socket reuse, framing mode,
expected/received byte counts and completion reason. Query strings and
authentication endpoint paths are omitted; response bodies and credentials
are never logged by this instrumentation.

`tests/test_http_framing.py` uses a local socket server to cover 200 JSON,
204 with a deliberately open connection, 204 with close, 304 on an open
connection, HEAD with Content-Length and chunked 200. All six tests passed.
This regression harness invokes the same framing classifier as the HTTP
parser; it is not an end-to-end run of libpurple's socket/event-loop parser.
Full runtime confirmation against Discord remains outstanding.

### Reaction callback safety

Reaction add/remove responses now validate JSON array/object structure,
message and author identifiers, and channel identity. The callback selects
the message whose ID matches the event rather than assuming the last array
entry is the target. If no matching message exists or its conversation has
closed while the request was pending, it frees callback state and drops the
update safely. Malformed reaction event identifiers and emoji nodes are
ignored. The command-side reaction lookup now validates responses and selects
the intended timestamped message instead of indexing `length - 1`.

`tests/test_reaction_lookup.c` covers null/object/empty/wrong-type responses,
missing or malformed IDs, selecting a target from multiple messages and
timestamp selection. It compiled for the XP x86 target and ran successfully
under Wine with the bundled GLib/JSON-GLib runtime. The same tests should be
run on an actual legacy Windows host before claiming OS runtime validation.

Disabling “Show reaction emojis” still prevents the reaction-event requests;
with the event callback now validating state, it is a useful diagnostic
comparison but no longer required to avoid the null-conversation assertion.

### Presence initialization

Discord statuses are now normalized to Amethyst's supported status IDs;
`invisible` and unknown values map to offline. In the Pidgin 2.11 core, the
buddy status update path could call `purple_status_is_online()` on a missing
old status during first initialization. It now treats a missing previous
status as offline and avoids emitting a status-changed signal with a null
previous status. The downstream status notification path also checks for a
missing resolved status. This addresses the null-status conditions in core,
but the supplied log does not identify which caller produced its assertion;
the exact original runtime stack was not captured.

### Keep-alive investigation

Keep-alive remains enabled by default. A diagnostic-only build switch,
`AMETHYST_DISCORD_DISABLE_KEEPALIVE=1`, builds the plugin without assigning
the shared pool. Compare it with the default build using the same account and
request sequence. No conclusion about stale sockets, pool exhaustion or
reliability can be drawn from the supplied logs or the deterministic framing
tests alone. Do not ship the no-pool build as a permanent behavior change
without comparative runtime evidence.

### Secondary observations

The GtkSpell dictionary warning and the unknown
`/pidgin/win32/minimize_new_convs` preference are separate packaging/core
integration issues. They are not changes in this reliability patch and do not
explain HTTP timeouts or Discord message delivery.

## Validation status

| Area | Result |
| --- | --- |
| Framing regression tests | Passed locally (6 cases) |
| Reaction lookup tests | Passed on Wine using XP x86 build/runtime dependencies |
| XP Discord DLL build | Passed; x86 PE subsystem 5.1; no detected Vista-only imports; QR auth omitted as configured for XP |
| Modern Discord DLL build | Passed; x86 PE subsystem 6.0; QR auth retained |
| No-keep-alive diagnostic DLL | Passed XP x86 build; pool assignment disabled only in this diagnostic variant |
| Full Amethyst XP package | Built as `output/diagnostic/discord-runtime-reliability-xp/amethyst-messenger-2.11.0-win32-xp.exe`; includes updated Discord DLL, JSON-GLib and existing XP Telegram plugin |
| Package contents and checksum | Verified the installer contains Amethyst, Discord, JSON-GLib and Telegram; checksum is beside the installer |
| Real Discord login/session | Not performed for this investigation |
| Discord receive/send reliability after fixes | Requires runtime comparison |
| XP/Vista physical or VM validation | Not performed here |
| IPv6 contribution | Unresolved; user observed correlation, not a complete fix |

The Discord XP DLL imports the existing libpurple/GLib/GObject runtime plus
JSON-GLib and the existing zlib/Windows socket libraries. The newly built
JSON-GLib DLL imports the bundled GIO/GLib/GObject runtime. The XP script's
static import checks passed; this does not establish actual XP execution.
The Modern DLL has Vista subsystem version 6.0. No recursive API-set/API
compatibility scan of every pre-existing runtime dependency was repeated in
this investigation.

Run the HTTP regression cases with `third_party/purple-discord/tests/test_http_framing.py`.
Run the reaction regression on this Windows cross-build setup with
`third_party/purple-discord/tests/run-reaction-test-xp.sh`; it cross-compiles
for XP x86 and executes under Wine. Both passed. `tests/run-tests.sh` runs the
HTTP tests and the native reaction test when system JSON-GLib development
files are installed; this host lacks those development files, so that wrapper
reported the native test as skipped.

The runtime logs included in the investigation contain no secrets in the
provided excerpt. Continue redacting tokens, cookies and session credentials
before sharing future debug logs.
