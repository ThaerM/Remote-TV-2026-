# Diagnostics & Logging

TV remote apps talk to many unrelated transports (mDNS, websockets,
vendor SDKs, HTTP), so structured, greppable logs matter more than in a
typical CRUD app.

## Tagging convention

Use `AppLogger` (`lib/core/logging/app_logger.dart`), named per concern,
so log lines read like:

```
[TV][DISCOVERY][mDNS] found 2 devices
[TV][PAIRING][GoogleTV] pairing requested
[TV][CONNECTION][Samsung] connected
[TV][COMMAND][LG][VolumeUp] sent
[TV][CAST][GoogleCast] session started
```

In practice this means constructing a logger with a dotted name that
encodes the concern, e.g. `AppLogger('TV.Fake')` (used by
`FakeTvProvider`) or, for a real provider, `AppLogger('TV.Discovery.mDNS')`.

## Never log

Pairing PINs, tokens, keys, certificates, or any other pairing secret -
see `docs/architecture/security.md`. If a log line needs to reference
"the pairing succeeded," log that fact, not the value that proved it.

## The Diagnostics screen

`DiagnosticsScreen` (Settings > Advanced > Diagnostics) shows the current
`TvSessionState` read-only: connection state, selected device, discovered
device count, last error. It intentionally does not expose raw log
output in this foundation phase - only session state safe to display.

## Future work

A future phase can add an in-app log buffer surfaced in Diagnostics
(ring buffer of the last N structured log lines, still redacting
anything secret) to help debug provider issues without a connected
debugger. Not implemented yet - `AppLogger` prints to the debug console
only.
