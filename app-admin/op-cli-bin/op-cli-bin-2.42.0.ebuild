# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Command line interface for the 1Password password manager"
HOMEPAGE="https://developer.1password.com/docs/cli/"
SITE="https://cache.agilebits.com/dist/1P/op2/pkg/v${PV}"
SRC_URI="
	amd64? ( ${SITE}/op_linux_amd64_v${PV}.zip )
	arm64? ( ${SITE}/op_linux_arm64_v${PV}.zip )
"

S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"

# The desktop app's CLI integration requires /usr/bin/op to be setgid
# onepassword-cli, so the group must exist when the image is installed.
DEPEND="acct-group/onepassword-cli"
RDEPEND="${DEPEND}"
BDEPEND="app-arch/unzip"

RESTRICT="bindist mirror"

QA_PREBUILT="usr/bin/op"

src_install() {
	dobin op
	fowners root:onepassword-cli /usr/bin/op
	fperms 2755 /usr/bin/op
}
