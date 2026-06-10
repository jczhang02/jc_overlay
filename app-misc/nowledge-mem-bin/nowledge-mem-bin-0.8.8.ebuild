# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd xdg-utils

MY_PN="nowledge-mem"
MY_DEB="${MY_PN}_${PV}_amd64.deb"

DESCRIPTION="Personal memory and context management system"
HOMEPAGE="https://mem.nowledge.co https://github.com/nowledge-co/nowledge-mem"
SRC_URI="https://download-mem.nowledge.co/apt/pool/${MY_DEB} -> ${P}.deb"
S="${WORKDIR}/${P}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="systemd +x11-workaround"
RESTRICT="mirror strip test"

BDEPEND="
	app-arch/dpkg
	app-arch/zstd
	dev-util/patchelf
"

# Debian package declares: libgtk-3-0, libwebkit2gtk-4.1-0,
# libayatana-appindicator3-1, zstd. WebKit pulls libsoup/cairo/pango/etc.
RDEPEND="
	app-arch/zstd
	dev-libs/libayatana-appindicator
	net-libs/webkit-gtk:4.1
	x11-libs/gtk+:3
"
DEPEND="${RDEPEND}"

# Upstream ships a prebuilt desktop app, Python runtime, native extensions,
# and CLI helpers. Do not strip; treat installed payload as binary blob.
QA_PREBUILT="*"
QA_SONAME="*"
QA_DT_NEEDED="*"

src_unpack() {
	mkdir -p "${S}" || die
	dpkg-deb -x "${DISTDIR}/${P}.deb" "${S}" || die
}

src_install() {
	cp -a "${S}"/. "${ED}"/ || die

	local runtime_dir="${ED}/usr/lib/Nowledge Mem/_up_"
	local runtime_archive="${runtime_dir}/python-runtime.tar.zst"
	if [[ -f ${runtime_archive} ]]; then
		einfo "Extracting bundled Python runtime"
		tar --zstd -xf "${runtime_archive}" -C "${runtime_dir}" \
			|| die "failed to extract bundled Python runtime"

		if [[ -f ${runtime_dir}/runtime-version.txt ]]; then
			cp "${runtime_dir}/runtime-version.txt" \
				"${runtime_dir}/python-standalone/.runtime-version" \
				|| die
		fi

		local libpython_shim="${runtime_dir}/python-standalone/python/lib/libpython3.so"
		if [[ -f ${libpython_shim} ]] && \
			readelf -d "${libpython_shim}" 2>/dev/null | \
			grep -q '\$ORIGIN/../lib/libpython3.13.so.1.0'; then
			patchelf \
				--replace-needed '$ORIGIN/../lib/libpython3.13.so.1.0' \
				'libpython3.13.so.1.0' \
				--set-rpath '$ORIGIN' \
				"${libpython_shim}" \
				|| die "failed to patch libpython3.so DT_NEEDED"
		fi

		# The Debian postinst keeps this archive and extracts untracked files at
		# install time. In Gentoo, own the extracted runtime and avoid duplication.
		rm -f "${runtime_archive}" || die
	fi

	dodir /usr/bin
	cat > "${ED}/usr/bin/nmem" <<-EOF || die
		#!/usr/bin/env bash
		PYTHON_STANDALONE="${EPREFIX}/usr/lib/Nowledge Mem/_up_/python-standalone"
		PYTHON="\${PYTHON_STANDALONE}/python/bin/python3"
		APP_SRC="\${PYTHON_STANDALONE}/app/src"

		if [[ ! -x \${PYTHON} ]]; then
			echo "Error: bundled Python not found at \${PYTHON}" >&2
			exit 1
		fi

		export PYTHONPATH="\${APP_SRC}:\${PYTHONPATH}"
		exec "\${PYTHON}" -m nowledge_graph_server.ncli "\$@"
	EOF
	fperms 0755 /usr/bin/nmem

	cat > "${ED}/usr/bin/browse-now" <<-EOF || die
		#!/usr/bin/env bash
		PYTHON_STANDALONE="${EPREFIX}/usr/lib/Nowledge Mem/_up_/python-standalone"
		PYTHON="\${PYTHON_STANDALONE}/python/bin/python3"

		if [[ ! -x \${PYTHON} ]]; then
			echo "Error: bundled Python not found at \${PYTHON}" >&2
			exit 1
		fi

		exec "\${PYTHON}" -c 'from browse_now.cli import main; main()' "\$@"
	EOF
	fperms 0755 /usr/bin/browse-now

	local desktop_file="${ED}/usr/share/applications/Nowledge Mem.desktop"
	if use x11-workaround && [[ -f ${desktop_file} ]] && \
		! grep -q "GDK_BACKEND=x11" "${desktop_file}"; then
		sed -i 's|^Exec=|Exec=env GDK_BACKEND=x11 |' "${desktop_file}" \
			|| die "failed to patch desktop file"
	fi

	if use systemd; then
		cat > "${T}/nmem.service" <<-EOF || die
			[Unit]
			Description=Nowledge Mem Server
			After=network.target

			[Service]
			Type=simple
			ExecStart=${EPREFIX}/usr/bin/nmem serve --host 127.0.0.1 --port 14242
			WorkingDirectory=%h
			Restart=on-failure
			RestartSec=5
			Environment=NMEM_API_URL=http://127.0.0.1:14242
			StandardOutput=journal
			StandardError=journal
			SyslogIdentifier=nmem

			[Install]
			WantedBy=default.target
		EOF
		systemd_douserunit "${T}/nmem.service"

		cat > "${T}/nmem@.service" <<-EOF || die
			[Unit]
			Description=Nowledge Mem Server (%i)
			After=network.target

			[Service]
			Type=simple
			User=%i
			ExecStart=${EPREFIX}/usr/bin/nmem serve --host 127.0.0.1 --port 14242
			WorkingDirectory=%h
			Restart=on-failure
			RestartSec=5
			Environment=HOME=%h
			Environment=XDG_CONFIG_HOME=%h/.config
			Environment=XDG_DATA_HOME=%h/.local/share
			Environment=NMEM_API_URL=http://127.0.0.1:14242
			StandardOutput=journal
			StandardError=journal
			SyslogIdentifier=nmem

			[Install]
			WantedBy=multi-user.target
		EOF
		systemd_dounit "${T}/nmem@.service"
	fi
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update

	elog "Nowledge Mem ${PV} installed from upstream Debian package."
	elog "Launch desktop app: nowledge-mem"
	elog "Run headless server: nmem serve"
	elog "Open web UI: http://127.0.0.1:14242/app"
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
