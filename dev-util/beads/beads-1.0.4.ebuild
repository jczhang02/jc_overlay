# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Distributed graph issue tracker for AI agents, powered by Dolt"
HOMEPAGE="https://github.com/gastownhall/beads"
SRC_URI="https://github.com/gastownhall/beads/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# Dolt embedded backend requires CGO. go mod download/build pulls modules
# from proxy.golang.org at compile time; vendor tarball is not shipped
# upstream, so allow network access during build.
RESTRICT="network-sandbox mirror test strip"

# go.mod pins go 1.26.2; rely on GOTOOLCHAIN=auto if local toolchain is older.
BDEPEND=">=dev-lang/go-1.24"

src_compile() {
	export CGO_ENABLED=1
	export GOTOOLCHAIN=auto
	export GOFLAGS="-mod=mod -trimpath"
	export GOCACHE="${T}/go-cache"
	export GOMODCACHE="${T}/go-mod"

	# gms_pure_go drops the ICU runtime dep so the binary is portable
	# across libc variants (matches upstream Makefile BUILD_TAGS).
	go build \
		-tags gms_pure_go \
		-ldflags="-X main.Build=v${PV}" \
		-o bd \
		./cmd/bd || die "go build failed"
}

src_install() {
	dobin bd
	dosym bd /usr/bin/beads

	einstalldocs
}

pkg_postinst() {
	elog "beads (bd) installed. Both 'bd' and 'beads' invoke the binary."
	elog "Run 'bd init' inside a git repo to create a .beads database."
}
