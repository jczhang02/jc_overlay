# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit git-r3 bash-completion-r1 go-module

KEYWORDS="~amd64 ~arm ~arm64 ~riscv ~x86"

EGIT_REPO_URI="https://github.com/rclone/rclone.git"
EGIT_BRANCH="fix-completion"

SRC_URI="
https://github.com/jczhang02/jc_overlay/archive/refs/tags/untagged-b29d78a8caa72d6206d5.zip -> ${P}-deps.tar.xz
"

DESCRIPTION="A program to sync files to and from various cloud storage providers"
HOMEPAGE="https://rclone.org/"

LICENSE="Apache-2.0 BSD BSD-2 ISC MIT MPL-2.0"
SLOT="0"
IUSE=""

RDEPEND="sys-fs/fuse:3"

src_unpack() {
	git-r3_src_unpack
}
src_compile() {
	go build -mod=readonly . || die "compile failed"
}

src_test() {
	# Setting CI skips unreliable tests, see fstest/testy/testy.go
	# TestAddPlugin and TestRemovePlugin fail
	RCLONE_CONFIG="/notfound" CI="true" go test -mod=readonly -v -run "!Test.*Plugin" ./... || die "test failed"
}

src_install() {
	dobin ${PN}
	doman ${PN}.1
	dodoc README.md

	./rclone genautocomplete bash ${PN}.bash || die
	newbashcomp ${PN}.bash ${PN}

	./rclone genautocomplete zsh ${PN}.zsh || die
	insinto /usr/share/zsh/site-functions
	newins ${PN}.zsh _${PN}
}
