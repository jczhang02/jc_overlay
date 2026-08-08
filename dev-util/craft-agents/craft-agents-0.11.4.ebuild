# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop

# Craft Agents desktop app built from source. Two bun runtimes are involved:
# - BUN_PV        : build-time toolchain (runs `bun install` / `bun run electron:build`)
# - BUN_RUNTIME_PV: vendored runtime bun pinned by upstream
#                   apps/electron/scripts/build-linux.sh (shipped inside the app)
BUN_PV="1.3.14"
BUN_RUNTIME_PV="1.3.9"

DESCRIPTION="Open-source agent-native desktop app for Craft Agents"
HOMEPAGE="https://agents.craft.do https://github.com/craft-ai-agents/craft-agents-oss"
BUN_BASE="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_PV}"
BUN_RUNTIME_BASE="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_RUNTIME_PV}"

# upstream pins bun-linux-x64-baseline for x64 (see build-linux.sh)
SRC_URI="
	https://github.com/craft-ai-agents/craft-agents-oss/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
	amd64? (
		${BUN_BASE}/bun-linux-x64.zip
			-> bun-${BUN_PV}-linux-x64.zip
		${BUN_RUNTIME_BASE}/bun-linux-x64-baseline.zip
			-> bun-v${BUN_RUNTIME_PV}-linux-x64-baseline.zip
	)
"

S="${WORKDIR}/craft-agents-oss-${PV}"

LICENSE="Apache-2.0 all-rights-reserved"
SLOT="0"

KEYWORDS="-* ~amd64"
IUSE="+python_targets_python3_13"

# Upstream only ships/targets glibc x86_64 for Linux; musl/x32 dev profiles
# are intentionally unsupported (KEYWORDS="-*" masks this package there).
# pkgcheck ignore: MissingPythonEclass,RequiredUseDefaults,RequiredUseUnsatisfiableInDev,NonsolvableDepsInDev,NonsolvableDepsInStable
REQUIRED_USE="elibc_glibc"

# Build deps are fetched from npm/GitHub at build time (bun install, npm pack,
# electron-builder electron dist, @vscode/ripgrep + sharp postinstalls).
RESTRICT="network-sandbox mirror test strip"

# App bundles prebuilt Electron/Chromium, the ~210 MB Claude Agent SDK native
# binary, bun, and uv — none can be stripped or rebuilt by portage.
QA_PREBUILT="opt/${PN}/*"
QA_SONAME="*"

BDEPEND="
	app-arch/unzip
	app-arch/tar
	>=net-libs/nodejs-22.19.0[npm]
"

# Electron runtime deps (aligned with codex-desktop-linux) plus python3 for the
# bundled CLI tool scripts (markitdown/pdf-tool wrappers, see electron-builder.yml).
RDEPEND="
	app-accessibility/at-spi2-core
	dev-libs/glib
	dev-libs/nss
	dev-libs/nspr
	dev-lang/python:3.13
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon
	x11-libs/libXrandr
	x11-libs/libXScrnSaver
	x11-libs/libXi
	x11-libs/libXtst
	x11-libs/pango
	x11-misc/xdg-utils
"

src_unpack() {
	unpack "${P}.tar.gz"

	# Stage the build-time bun toolchain under ${T}/bun (keep it out of ${S}).
	local bun_zip="bun-${BUN_PV}-linux-x64.zip"
	mkdir -p "${T}/bun" || die
	pushd "${T}/bun" > /dev/null || die
	unzip -q "${DISTDIR}/${bun_zip}" || die "build bun zip extract failed"
	local extracted
	extracted=$(find . -maxdepth 2 -name bun -type f -executable | head -n1)
	[[ -n ${extracted} ]] || die "bun binary not found inside zip"
	mv "${extracted}" bun || die
	chmod +x bun || die
	popd > /dev/null

	# Stage the vendored runtime bun (bun-linux-x64-baseline, per upstream pin).
	local runtime_zip="bun-v${BUN_RUNTIME_PV}-linux-x64-baseline.zip"
	mkdir -p "${T}/bun-runtime" || die
	pushd "${T}/bun-runtime" > /dev/null || die
	unzip -q "${DISTDIR}/${runtime_zip}" || die "runtime bun zip extract failed"
	popd > /dev/null
}

src_compile() {
	# Sandbox all caches under ${T}.
	export BUN_INSTALL_CACHE_DIR="${T}/bun-cache"
	# Bun 1.3.14 can intermittently fail while streaming npm tarballs
	# (oven-sh/bun#34821 and #34861); use the buffered extraction path.
	export BUN_FEATURE_FLAG_DISABLE_STREAMING_INSTALL=1
	export HOME="${T}/home"
	export XDG_CACHE_HOME="${T}/cache"
	export npm_config_cache="${T}/npm-cache"
	mkdir -p "${HOME}" "${XDG_CACHE_HOME}" "${BUN_INSTALL_CACHE_DIR}" \
		"${npm_config_cache}" || die

	# Vendored build bun first on PATH.
	export PATH="${T}/bun:${PATH}"

	# Skip electron's own postinstall binary download; electron-builder fetches
	# the pinned 39.2.7 dist into its own cache during packaging.
	export ELECTRON_SKIP_BINARY_DOWNLOAD=1
	export ELECTRON_BUILDER_CACHE="${T}/electron-cache"
	export CSC_IDENTITY_AUTO_DISCOVERY=false
	export USE_HARD_LINKS=false
	export HUSKY=0

	local electron_dir="${S}/apps/electron"

	einfo "Using bun $(bun --version)"

	einfo "Installing dependencies (bun install --frozen-lockfile)"
	cd "${S}" || die
	bun install --frozen-lockfile || die "bun install failed"

	# --- Replicate upstream apps/electron/scripts/build-linux.sh staging ---

	einfo "Staging vendored bun runtime"
	mkdir -p "${electron_dir}/vendor/bun" || die
	local runtime_bun
	runtime_bun=$(find "${T}/bun-runtime" -maxdepth 2 -name bun -type f -executable | head -n1)
	[[ -n ${runtime_bun} ]] || die "runtime bun binary not found"
	cp "${runtime_bun}" "${electron_dir}/vendor/bun/bun" || die
	chmod +x "${electron_dir}/vendor/bun/bun" || die

	einfo "Staging Claude Agent SDK core"
	local sdk_source="${S}/node_modules/@anthropic-ai/claude-agent-sdk"
	[[ -d ${sdk_source} ]] || die "claude-agent-sdk not installed by bun"
	mkdir -p "${electron_dir}/node_modules/@anthropic-ai" || die
	cp -r "${sdk_source}" "${electron_dir}/node_modules/@anthropic-ai/" || die

	einfo "Staging Claude Agent SDK native binary"
	local sdk_bin_pkg="claude-agent-sdk-linux-x64"
	local sdk_bin_source="${S}/node_modules/@anthropic-ai/${sdk_bin_pkg}"
	if [[ ! -d ${sdk_bin_source} ]]; then
		ewarn "${sdk_bin_pkg} not hoisted by bun; cross-fetching from npm"
		local sdk_version
		sdk_version=$(node -p \
			"require('${S}/package.json').dependencies['@anthropic-ai/claude-agent-sdk']" \
			| tr -d '"')
		local pkg_tmp="${T}/sdk-bin"
		mkdir -p "${pkg_tmp}" || die
		(
			cd "${pkg_tmp}" || die
			npm pack "@anthropic-ai/${sdk_bin_pkg}@${sdk_version}" > /dev/null \
				|| die "npm pack for ${sdk_bin_pkg} failed"
			tar -xzf "$(ls anthropic-ai-*.tgz | head -n1)" || die "sdk tarball extract failed"
		)
		mkdir -p "${sdk_bin_source}" || die
		cp -r "${pkg_tmp}/package/." "${sdk_bin_source}/" || die
	fi
	local alias_dest="${electron_dir}/node_modules/@anthropic-ai/claude-agent-sdk-binary"
	rm -rf "${alias_dest}"
	mkdir -p "${alias_dest}" || die
	cp -r "${sdk_bin_source}/." "${alias_dest}/" || die
	chmod +x "${alias_dest}/claude" || die
	local bin_size
	bin_size=$(stat -c%s "${alias_dest}/claude")
	if [[ ${bin_size} -lt 50000000 ]]; then
		die "claude binary only ${bin_size} bytes (expected ~210 MB)"
	fi
	einfo "  claude binary: $(( bin_size / 1024 / 1024 )) MB"

	einfo "Staging @vscode/ripgrep"
	local rg_source="${S}/node_modules/@vscode/ripgrep"
	[[ -f ${rg_source}/bin/rg ]] || die "@vscode/ripgrep postinstall did not run (bin/rg missing)"
	mkdir -p "${electron_dir}/node_modules/@vscode" || die
	cp -r "${rg_source}" "${electron_dir}/node_modules/@vscode/" || die

	einfo "Staging network interceptor sources"
	mkdir -p "${electron_dir}/packages/shared/src" || die
	cp "${S}/packages/shared/src/unified-network-interceptor.ts" \
		"${electron_dir}/packages/shared/src/" || die
	local dep
	for dep in interceptor-common.ts feature-flags.ts interceptor-request-utils.ts; do
		if [[ -f ${S}/packages/shared/src/${dep} ]]; then
			cp "${S}/packages/shared/src/${dep}" \
				"${electron_dir}/packages/shared/src/" || die
		fi
	done

	einfo "Building Electron app (bun run electron:build)"
	cd "${S}" || die
	bun run electron:build || die "electron:build failed"

	einfo "Packaging with electron-builder (--dir, no AppImage)"
	cd "${electron_dir}" || die
	npx electron-builder --config electron-builder.yml --linux --x64 --dir \
		|| die "electron-builder failed"

	[[ -d ${electron_dir}/release/linux-unpacked ]] \
		|| die "expected release/linux-unpacked output missing"
}

src_install() {
	local unpacked="${S}/apps/electron/release/linux-unpacked"
	[[ -d ${unpacked} ]] || die "linux-unpacked missing"

	# Install the complete unpacked tree (cp -pR preserves exec bits/symlinks).
	dodir "/opt/${PN}"
	cp -pR "${unpacked}"/. "${D}/opt/${PN}/" || die

	# Electron sandbox helper needs setuid root, otherwise the app would need
	# --no-sandbox to run.
	fperms 4755 "/opt/${PN}/chrome-sandbox"

	# Discover the launcher binary (name varies with electron-builder version).
	local exe
	exe=$(find "${D}/opt/${PN}" -maxdepth 1 -type f -perm /111 \
		! -name chrome-sandbox ! -name '*.so' | head -n1)
	[[ -n ${exe} ]] || die "launcher binary not found"
	local exe_name
	exe_name=$(basename "${exe}")
	einfo "launcher: ${exe_name}"

	dosym "../../opt/${PN}/${exe_name}" /usr/bin/craft-agents

	doicon "${S}/apps/electron/resources/icon.png"
	make_desktop_entry craft-agents "Craft Agents" craft-agents "Utility;"

	local d
	for d in README.md LICENSE; do
		[[ -f ${d} ]] && dodoc "${d}"
	done
}

pkg_postinst() {
	elog "Craft Agents ${PV} installed. Launch with: craft-agents"
	elog "Configuration and data live in ~/.craft-agent/ (incl. credentials.enc)."
	elog "Updates are managed by Portage."
}
