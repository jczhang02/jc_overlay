# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Local-first IDE for coding agent orchestration (Tauri 2)"
HOMEPAGE="https://helmor.ai https://github.com/dohooo/helmor"
SRC_URI="
	https://github.com/dohooo/helmor/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
"
S="${WORKDIR}/${P}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
REQUIRED_USE="elibc_glibc"

# bun install pulls ~1GB node_modules; cargo fetches crates via network;
# tauri bundles a Bun-compiled sidecar + helmor-cli release binary; strip
# would corrupt the embedded Bun runtime in the sidecar binary.
RESTRICT="network-sandbox mirror strip test"

# bun-bin lives in gentoo-zh overlay; upstream pins bun@1.3.2 via
# packageManager but bun does not enforce self-version like corepack,
# so the system bun is used as-is.
BDEPEND="
	>=net-libs/bun-bin-1.2.21
	|| ( >=dev-lang/rust-1.80 >=dev-lang/rust-bin-1.80 )
	virtual/pkgconfig
	app-arch/tar
	app-arch/gzip
	app-arch/dpkg
"

# Tauri 2 Linux runtime: webkit2gtk-4.1 + libsoup-3 stack.
RDEPEND="
	dev-libs/glib:2
	dev-libs/openssl:0=
	gnome-base/librsvg:2
	net-libs/libsoup:3.0
	net-libs/webkit-gtk:4.1
	sys-apps/dbus
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/pango
"
DEPEND="${RDEPEND}"

QA_PREBUILT="opt/helmor/*"

PATCHES=(
	"${FILESDIR}/${PN}-0.23.4-disable-updater.patch"
)

src_prepare() {
	default
	# Strip sccache probe from postinstall — sccache not required for ebuild
	# builds and would warn under the portage sandbox.
	sed -i '/sccache --version/,/}\\n\"/d' package.json || true
}

src_compile() {
	export HOME="${T}/home"
	export XDG_CACHE_HOME="${T}/cache"
	export XDG_CONFIG_HOME="${T}/config"
	export XDG_DATA_HOME="${T}/share"
	export CARGO_HOME="${T}/cargo"
	export RUSTC_WRAPPER=""
	# Disable Tauri updater artifact generation (requires signing key).
	export TAURI_BUNDLE_UPDATER=false
	mkdir -p "${HOME}" "${XDG_CACHE_HOME}" "${XDG_CONFIG_HOME}" \
		"${XDG_DATA_HOME}" "${CARGO_HOME}" || die

	einfo "Resolved tool versions:"
	einfo "  bun     $(bun --version)"
	einfo "  rustc   $(rustc --version)"
	einfo "  cargo   $(cargo --version)"

	einfo "bun install (workspace + sidecar)"
	bun install --frozen-lockfile \
		|| bun install \
		|| die "bun install failed"

	local tgt
	case ${ARCH} in
		amd64) tgt="x86_64-unknown-linux-gnu" ;;
		arm64) tgt="aarch64-unknown-linux-gnu" ;;
		*) die "unsupported ARCH=${ARCH}" ;;
	esac

	einfo "tauri build --target ${tgt} --bundles deb"
	# beforeBuildCommand chain runs prepare-sidecar.mjs (bun-compile sidecar
	# + cargo build --release --bin helmor-cli) and `bun run build` (Vite).
	bun run tauri build --target "${tgt}" --bundles deb \
		|| die "tauri build failed"

	# Stash target triple for src_install (different scope from src_compile
	# in a real bash run, so re-derive there too — but cache as env hint).
	echo "${tgt}" > "${T}/.helmor-target-triple" || die
}

src_install() {
	local tgt
	tgt="$(cat "${T}/.helmor-target-triple")"
	local deb_root="src-tauri/target/${tgt}/release/bundle/deb"
	local deb
	deb=$(find "${deb_root}" -maxdepth 2 -name '*.deb' -type f 2>/dev/null \
		| head -n1)
	[[ -n ${deb} && -f ${deb} ]] || die "no .deb produced under ${deb_root}"

	einfo "Extracting ${deb##*/} payload into image"
	mkdir -p "${T}/deb-extract" || die
	pushd "${T}/deb-extract" >/dev/null || die
	dpkg-deb -x "${WORKDIR}/${P}/${deb}" "${D}" \
		|| ar x "${WORKDIR}/${P}/${deb}" data.tar.gz data.tar.xz data.tar.zst 2>/dev/null \
		|| die "deb extract failed"
	# Fallback path: if dpkg-deb missing and ar used, untar payload.
	for arch in data.tar.gz data.tar.xz data.tar.zst; do
		if [[ -f ${arch} ]]; then
			tar -xf "${arch}" -C "${D}" || die "tar extract ${arch} failed"
		fi
	done
	popd >/dev/null || die

	# Tauri .deb installs to /usr/bin + /usr/share already; relocate to
	# /opt-style only if upstream changed paths. Otherwise keep as-is.

	local d
	for d in README.md NOTICE LICENSE; do
		[[ -f ${d} ]] && dodoc "${d}"
	done
}

pkg_postinst() {
	elog "Helmor ${PV} installed."
	elog
	elog "Launch:  helmor"
	elog
	elog "Note: upstream has no Linux CI; this ebuild is best-effort. File"
	elog "Linux-specific issues at https://github.com/dohooo/helmor/issues"
	elog
	elog "Auto-updater is disabled (no signing key in ebuild builds)."
	elog "Update via portage: emerge --sync && emerge -u dev-util/helmor"
}
