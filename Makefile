# SPDX-License-Identifier: GPL-3.0-or-later

QML_FILES := $(shell find contents -type f -name '*.qml' -print)
SHELL_FILES := contents/tools/zram-monitor-snapshot scripts/build-release.sh tests/check-fixture.sh tests/check-package.sh tests/check-snapshot.sh tests/check-source.sh

.PHONY: check check-portable format package

check-portable:
	./tests/check-source.sh
	shellcheck $(SHELL_FILES)
	./tests/check-fixture.sh
	./tests/check-snapshot.sh

check: check-portable
	./tests/check-package.sh
	# Plasma provides i18n and Plasmoid context properties at runtime.
	qmllint-qt6 --unqualified disable --max-warnings 0 $(QML_FILES)
	QT_QPA_PLATFORM=offscreen qmltestrunner-qt6 -input tests/qml

format:
	qmlformat-qt6 -i $(QML_FILES)

package: check
	./scripts/build-release.sh
