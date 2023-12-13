# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit systemd tmpfiles

DESCRIPTION="Another Clash Kernel."
HOMEPAGE="https://github.com/MetaCubeX/mihomo"

SRC_URI="
https://github.com/MetaCubeX/mihomo/releases/download/v1.17.0/mihomo-linux-amd64-compatible-v${PV}.gz
"

RESTRICT="mirror"
DEPEND=""
RDEPEND="${DEPEND}"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
S="${WORKDIR}"
# IUSE="+gvisor lwip"
IUSE=""

# src_compile() {
# 	local BUILDTIME=$(LC_ALL=C date -u || die)
# 	local MY_TAGS
# 	if use gvisor; then
# 		MY_TAGS="with_gvisor"
# 	fi
# 	if use lwip; then
# 		MY_TAGS+=" with_lwip"
# 	fi
# 	ego build \
#     -ldflags "-linkmode external -extldflags \"${LDFLAGS}\" \
#     -X \"github.com/Dreamacro/clash/constant.Version=${PV}\" \
#     -X \"github.com/Dreamacro/clash/constant.BuildTime=${BUILDTIME}\" \
#     " \
# 		-tags "$MY_TAGS" -o "${P}"
# }

src_install() {
	newbin "mihomo-linux-amd64-compatible-v${PV}" "clash-meta"

	insinto /usr/lib/sysusers.d/
	newins "${FILESDIR}/clash-meta.sysusers" clash-meta.conf

	# insinto /usr/lib/tmpfiles.d/
	newtmpfiles "${FILESDIR}/clash-meta.tmpfiles" clash-meta.conf

	systemd_dounit "${FILESDIR}/clash-meta.service"
	systemd_dounit "${FILESDIR}/clash-meta@.service"

	# newinitd "${FILESDIR}"/clash-meta.initd clash-meta
}

pkg_postinst() {
	tmpfiles_process clash-meta.conf
}
