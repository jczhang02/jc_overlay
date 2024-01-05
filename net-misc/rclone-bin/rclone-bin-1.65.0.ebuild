# Copyright 2016-2018 Jan Chren (rindeal)
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="rsync for cloud storage"
HOMEPAGE="https://rclone.org/ https://github.com/ncw/rclone"
LICENSE="MIT"

PN_NB="${PN%-bin}"
SLOT="0"

SRC_URI="
https://beta.rclone.org/branch/fix-completion/v1.65.0-beta.7527.5c9cfbbc8.fix-completion/rclone-v1.65.0-beta.7527.5c9cfbbc8.fix-completion-linux-amd64.zip -> ${P}.zip
"
KEYWORDS="-*"

RDEPEND="!!${CATEGORY}/${PN_NB}"

RESTRICT+=" mirror"

src_unpack() {
	default

	cd "${WORKDIR}"/rclone-v1.65.0-beta.7527.5c9cfbbc8.fix-completion-linux-amd64 || die
	S="${PWD}"
}

inst_d="/opt/${PN_NB}"

src_install() {
	into "${inst_d}"
	dobin "${PN_NB}"
	dosym "${inst_d}/bin/${PN_NB}" "/usr/bin/${PN_NB}"

}

QA_PRESTRIPPED="${inst_d#/}/bin/${PN_NB}"
