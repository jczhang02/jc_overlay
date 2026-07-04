# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
ETYPE="sources"
K_WANT_GENPATCHES="base extras"
#Note: to bump xanmod, check K_GENPATCHES_VER in sys-kernel/gentoo-sources
K_GENPATCHES_VER="23"

inherit check-reqs kernel-2
detect_version
detect_arch

MY_P=linux-${PV%.*}
DESCRIPTION="Full XanMod source, including the Gentoo patchset and other patch options"
HOMEPAGE="https://xanmod.org"

XANMOD_VERSION="1"
OKV="${OKV}-xanmod"
SRC_URI="
	https://gitlab.com/xanmod/linux/-/archive/${PV}-xanmod${XANMOD_VERSION}/linux-${PV}-xanmod${XANMOD_VERSION}.tar.bz2
		-> ${P}-xanmod${XANMOD_VERSION}.tar.bz2
	${GENPATCHES_URI}
"
S="${WORKDIR}/linux-${PV}-xanmod${XANMOD_VERSION}"

LICENSE+=" CDDL"
KEYWORDS="~amd64"

pkg_pretend() {
	CHECKREQS_DISK_BUILD="4G"
	check-reqs_pkg_pretend
}

src_unpack() {
	default
}

src_prepare() {
	kernel-2_src_prepare
	rm -f "${S}/tools/testing/selftests/tc-testing/action-ebpf"
	# delete linux version patches
	rm -f "${WORKDIR}"/*${MY_P}*.patch
	# delete failed patches
	rm -f "${WORKDIR}/1710_disable_sse4a.patch"
	rm -f "${WORKDIR}/2701-drm-amdgpu-don-t-attach-the-tlb-fence-for-SI.patch"

	local PATCHES=(
		# genpatches
		"${WORKDIR}"/*.patch
	)
	default
}

pkg_postinst() {
	elog "MICROCODES"
	elog "Use xanmod-sources with microcodes"
	elog "Read https://wiki.gentoo.org/wiki/Intel_microcode"
	kernel-2_pkg_postinst
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
