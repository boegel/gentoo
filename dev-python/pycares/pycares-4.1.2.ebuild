# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{8..10} )

inherit distutils-r1

DESCRIPTION="Python interface for c-ares"
HOMEPAGE="https://github.com/saghul/pycares/"
SRC_URI="https://github.com/saghul/pycares/archive/${P/_p/-fix}.tar.gz"
S=${WORKDIR}/${PN}-${P/_p/-fix}

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
IUSE="test"
# Tests fail with network-sandbox, since they try to resolve google.com
PROPERTIES="test_network"
RESTRICT="test"

DEPEND="net-dns/c-ares"
BDEPEND="virtual/python-cffi[${PYTHON_USEDEP}]"
RDEPEND="
	dev-python/idna[${PYTHON_USEDEP}]
	${DEPEND}
	${BDEPEND}"
BDEPEND+="
	test? ( dev-python/idna[${PYTHON_USEDEP}] )"

export PYCARES_USE_SYSTEM_LIB=1

python_test() {
	"${EPYTHON}" tests/tests.py -v || die
}
