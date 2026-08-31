<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Contributing

Thank you for helping improve zRAM Monitor.

## Development environment

The widget targets KDE Plasma 6 on Linux. Local validation expects:

- `kpackagetool6`
- `qmlformat-qt6` and `qmllint-qt6`
- `shellcheck`
- Python 3
- `zip` and GNU `tar`

Run the complete validation suite before submitting a change:

```sh
make format
make check
```

## Design constraints

- Keep the panel representation inexpensive and legible at normal Plasma panel sizes.
- Preserve correct RAM accounting: zram's physical allocation is already included in used system RAM.
- Do not classify capacity alone as distress; warnings require both memory pressure and zram traffic.
- Use inherited Plasma/Kirigami color roles rather than hard-coded light or dark palettes.
- Keep the snapshot helper read-only, unprivileged, offline, and compatible with POSIX `sh`.
- Avoid adding resident services or faster background polling.

## Patches

Keep changes focused, add or update tests for behavioral changes, and explain any user-visible accounting or alerting change. Report security issues privately as described in [SECURITY.md](SECURITY.md).
