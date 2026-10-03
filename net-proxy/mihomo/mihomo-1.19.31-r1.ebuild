# Copyright 2023-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit go-module systemd

DESCRIPTION="Another Clash Kernel, formerly Clash.Meta"
HOMEPAGE="
	https://wiki.metacubex.one/
	https://github.com/MetaCubeX/mihomo/
	https://github.com/vernesong/mihomo/
"
# Smart uses the 2026-09-18 Alpha snapshot, not the upstream release.
# It shares 1.19.31's module versions, adding only leaves.
SMART_COMMIT="8b9aaeeb61b55c56e57d854ff6ac527e0a9c7ef4"
LEAVES_COMMIT="2a1c022f37d06377727f33761c22bb4d0fdd752e"
SRC_URI="
	!smart? ( https://github.com/MetaCubeX/mihomo/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz )
	smart? (
		https://github.com/vernesong/mihomo/archive/${SMART_COMMIT}.tar.gz -> ${PN}-smart-${SMART_COMMIT}.tar.gz
		https://github.com/vernesong/leaves/archive/${LEAVES_COMMIT}.tar.gz -> leaves-${LEAVES_COMMIT}.tar.gz
	)
	https://github.com/gentoo-zh-drafts/mihomo/releases/download/v${PV}/${P}-vendor.tar.xz
"

BDEPEND=">=dev-lang/go-1.20.4"

LICENSE="GPL-3 smart? ( MIT )"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~loong"
IUSE="+gvisor smart"

src_prepare() {
	if use smart; then
		# The shared vendor archive creates S; overlay the matching fork sources.
		cp -a "${WORKDIR}/${PN}-${SMART_COMMIT}/." "${S}/" || die
		mkdir -p vendor/github.com/vernesong || die
		cp -a "${WORKDIR}/leaves-${LEAVES_COMMIT}" vendor/github.com/vernesong/leaves || die
		eapply "${FILESDIR}/${P}-smart-vendor.patch"
	fi
	default
}

src_compile() {
	local BUILDTIME=$(LC_ALL=C date -u || die)
	local MY_TAGS
	local MY_VERSION=${PV}
	use gvisor && MY_TAGS="with_gvisor"
	use smart && MY_VERSION="alpha-smart-${SMART_COMMIT:0:7}"
	ego build -tags "${MY_TAGS}" -trimpath -ldflags "
		-linkmode external -extldflags '${LDFLAGS}' \
		-X github.com/metacubex/mihomo/constant.Version=${MY_VERSION} \
		-X 'github.com/metacubex/mihomo/constant.BuildTime=${BUILDTIME}'"
}

src_install() {
	dobin mihomo
	dosym mihomo /usr/bin/clash-meta
	systemd_dounit .github/release/mihomo.service
	systemd_dounit .github/release/mihomo@.service
	newinitd "${FILESDIR}"/mihomo.initd mihomo

	keepdir /etc/mihomo
	insinto /etc/mihomo
	newins .github/release/config.yaml config.yaml.example
	einstalldocs
}
