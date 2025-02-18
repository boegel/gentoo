# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{8..10} )

inherit distutils-r1

DESCRIPTION="Pure Python CBOR (de)serializer with extensive tag support"
HOMEPAGE="https://github.com/agronholm/cbor2 https://pypi.org/project/cbor2/"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ~arm ~arm64 ~x86"

BDEPEND="
	dev-python/setuptools_scm[${PYTHON_USEDEP}]"

distutils_enable_tests pytest

python_prepare_all() {
	# remove pytest-cov dep
	sed -e "s/pytest-cov//" \
		-e "s/--cov //" \
		-i setup.cfg || die

	distutils-r1_python_prepare_all
}
