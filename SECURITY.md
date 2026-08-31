<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Security policy

## Supported versions

Security fixes are made against the current release of zRAM Monitor for supported Plasma 6 environments.

## Reporting a vulnerability

Please report suspected vulnerabilities privately to [uglyegg@entropy.quest](mailto:uglyegg@entropy.quest). Include the affected version, relevant configuration, reproduction details, impact, and any proposed mitigation. Please do not open a public issue until a fix or coordinated disclosure plan is available.

The widget is intended to read local zram and memory statistics without elevated privileges or network access. Any behavior that writes to system state, unexpectedly executes caller-controlled input, exposes sensitive local information, or crosses those boundaries should be treated as a security concern.
