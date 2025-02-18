# Copyright 2019-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..10} pypy3 )
inherit distutils-r1

DESCRIPTION="Python @deprecated decorator to deprecate old API"
HOMEPAGE="https://github.com/tantale/deprecated"
SRC_URI="
	https://github.com/tantale/deprecated/archive/v${PV}.tar.gz
		-> ${P}.gh.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ~arm64 x86"

RDEPEND="dev-python/wrapt[${PYTHON_USEDEP}]"

distutils_enable_tests pytest

python_test() {
	local EPYTEST_DESELECT=()

	[[ ${EPYTHON} == pypy3 ]] && EPYTEST_DESELECT+=(
		tests/test_deprecated.py::test_respect_global_filter
		tests/test_deprecated_class.py::test_class_respect_global_filter
	)

	epytest
}
