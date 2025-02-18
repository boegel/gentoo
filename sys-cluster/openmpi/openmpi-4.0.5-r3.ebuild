# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

FORTRAN_NEEDED=fortran

inherit cuda flag-o-matic fortran-2 java-pkg-opt-2 toolchain-funcs multilib multilib-minimal

MY_P=${P/-mpi}
S=${WORKDIR}/${MY_P}

IUSE_OPENMPI_FABRICS="
	openmpi_fabrics_ofed
	openmpi_fabrics_knem
	openmpi_fabrics_psm"

IUSE_OPENMPI_RM="
	openmpi_rm_pbs
	openmpi_rm_slurm"

IUSE_OPENMPI_OFED_FEATURES="
	openmpi_ofed_features_control-hdr-padding
	openmpi_ofed_features_udcm
	openmpi_ofed_features_rdmacm
	openmpi_ofed_features_dynamic-sl"

DESCRIPTION="A high-performance message passing library (MPI)"
HOMEPAGE="https://www.open-mpi.org"
SRC_URI="https://www.open-mpi.org/software/ompi/v$(ver_cut 1-2)/downloads/${MY_P}.tar.bz2"
LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha amd64 arm ~ia64 ~ppc ~ppc64 ~riscv sparc x86 ~amd64-linux"
IUSE="cma cuda cxx fortran heterogeneous ipv6 java libompitrace peruse romio
	${IUSE_OPENMPI_FABRICS} ${IUSE_OPENMPI_RM} ${IUSE_OPENMPI_OFED_FEATURES}"

REQUIRED_USE="openmpi_rm_slurm? ( !openmpi_rm_pbs )
	openmpi_rm_pbs? ( !openmpi_rm_slurm )
	openmpi_fabrics_psm? ( openmpi_fabrics_ofed )
	openmpi_ofed_features_control-hdr-padding? ( openmpi_fabrics_ofed )
	openmpi_ofed_features_udcm? ( openmpi_fabrics_ofed )
	openmpi_ofed_features_rdmacm? ( openmpi_fabrics_ofed )
	openmpi_ofed_features_dynamic-sl? ( openmpi_fabrics_ofed )"

CDEPEND="
	!sys-cluster/mpich
	!sys-cluster/mpich2
	!sys-cluster/nullmpi
	>=dev-libs/libevent-2.0.22:=[${MULTILIB_USEDEP},threads]
	dev-libs/libltdl:0[${MULTILIB_USEDEP}]
	>=sys-apps/hwloc-2.0.2:=[${MULTILIB_USEDEP}]
	>=sys-libs/zlib-1.2.8-r1[${MULTILIB_USEDEP}]
	cuda? ( >=dev-util/nvidia-cuda-toolkit-6.5.19-r1:= )
	openmpi_fabrics_ofed? ( || ( sys-cluster/rdma-core sys-fabric/ofed:* ) )
	openmpi_fabrics_knem? ( sys-cluster/knem )
	openmpi_fabrics_psm? ( sys-fabric/infinipath-psm:* )
	openmpi_rm_pbs? ( sys-cluster/torque )
	openmpi_rm_slurm? ( sys-cluster/slurm )
	openmpi_ofed_features_rdmacm? ( || ( sys-cluster/rdma-core sys-fabric/librdmacm:* ) )"

RDEPEND="${CDEPEND}
	java? ( >=virtual/jre-1.8:* )"

DEPEND="${CDEPEND}
	java? ( >=virtual/jdk-1.8:* )"

MULTILIB_WRAPPED_HEADERS=(
	/usr/include/mpi.h
	/usr/include/openmpi/ompi/mpi/java/mpiJava.h
	/usr/include/openmpi/mpiext/mpiext_cuda_c.h
)

pkg_setup() {
	fortran-2_pkg_setup
	java-pkg-opt-2_pkg_setup

	elog
	elog "OpenMPI has an overwhelming count of configuration options."
	elog "Don't forget the EXTRA_ECONF environment variable can let you"
	elog "specify configure options if you find them necessary."
	elog
}

src_prepare() {
	default

	# Necessary for scalibility, see
	# http://www.open-mpi.org/community/lists/users/2008/09/6514.php
	echo 'oob_tcp_listen_mode = listen_thread' \
		>> opal/etc/openmpi-mca-params.conf || die
}

multilib_src_configure() {
	if use java; then
		# We must always build with the right -source and -target
		# flags. Passing flags to javac isn't explicitly supported here
		# but we can cheat by overriding the configure test for javac.
		export ac_cv_path_JAVAC="$(java-pkg_get-javac) $(java-pkg_javac-args)"
	fi

	local myconf=(
		--enable-mpi-fortran=$(usex fortran all no)
		--enable-orterun-prefix-by-default
		--enable-pretty-print-stacktrace

		--sysconfdir="${EPREFIX}/etc/${PN}"

		--with-hwloc="${EPREFIX}/usr"
		--with-hwloc-libdir="${EPREFIX}/usr/$(get_libdir)"
		--with-libltdl="${EPREFIX}/usr"
		--with-libevent="${EPREFIX}/usr"
		--with-libevent-libdir="${EPREFIX}/usr/$(get_libdir)"

		$(use_enable cxx mpi-cxx)
		$(use_enable heterogeneous)
		$(use_enable ipv6)
		$(use_enable libompitrace)
		$(use_enable peruse)
		$(use_enable romio io-romio)

		$(use_with cma)

		$(multilib_native_use_enable java mpi-java)
		$(multilib_native_use_enable openmpi_ofed_features_control-hdr-padding openib-control-hdr-padding)
		$(multilib_native_use_enable openmpi_ofed_features_rdmacm openib-rdmacm)
		$(multilib_native_use_enable openmpi_ofed_features_udcm openib-udcm)
		$(multilib_native_use_enable openmpi_ofed_features_dynamic-sl openib-dynamic-sl)

		$(multilib_native_use_with cuda cuda "${EPREFIX}"/opt/cuda)
		$(multilib_native_use_with openmpi_fabrics_ofed verbs "${EPREFIX}"/usr)
		$(multilib_native_use_with openmpi_fabrics_knem knem "${EPREFIX}"/usr)
		$(multilib_native_use_with openmpi_fabrics_psm psm "${EPREFIX}"/usr)
		$(multilib_native_use_with openmpi_rm_pbs tm)
		$(multilib_native_use_with openmpi_rm_slurm slurm)
	)
	ECONF_SOURCE=${S} econf "${myconf[@]}"
}

multilib_src_test() {
	# Doesn't work with the default src_test as the dry run (-n) fails.
	emake -j1 check
}

multilib_src_install() {
	default

	# fortran header cannot be wrapped (bug #540508), workaround part 1
	if multilib_is_native_abi && use fortran; then
		mkdir "${T}"/fortran || die
		mv "${ED}"/usr/include/mpif* "${T}"/fortran || die
	else
		# some fortran files get installed unconditionally
		rm \
			"${ED}"/usr/include/mpif* \
			"${ED}"/usr/bin/mpif* \
			|| die
	fi
}

multilib_src_install_all() {
	# fortran header cannot be wrapped (bug #540508), workaround part 2
	if use fortran; then
		mv "${T}"/fortran/mpif* "${ED}"/usr/include || die
	fi

	# Remove la files, no static libs are installed and we have pkg-config
	find "${ED}" -name '*.la' -delete || die

	if use java; then
		local mpi_jar="${ED}"/usr/$(get_libdir)/mpi.jar
		java-pkg_dojar "${mpi_jar}"
		# We don't want to install the jar file twice
		# so let's clean after ourselves.
		rm "${mpi_jar}" || die
	fi
	einstalldocs
}
