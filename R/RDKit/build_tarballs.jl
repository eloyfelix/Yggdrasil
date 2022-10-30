using BinaryBuilder, Pkg

name = "RDKit"
version = v"2022.09.1"

sources = [
    GitSource("https://github.com/rdkit/rdkit.git", "dc16d0e160033ac215b574beed12a52d0b344fc5"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/rdkit

# Windows build fails to link a test, despite the fact we don't want tests.
atomic_patch -p1 ../patches/do-not-build-cffi-test.patch

# seen in the conda-forge feedstock: https://github.com/conda-forge/rdkit-feedstock/blob/main/recipe/build.sh#L18
atomic_patch -p1 ../patches/2022-09-1.patch

FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    FLAGS+=(-DRDK_BUILD_THREADSAFE_SSS=OFF)
fi

mkdir build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DRDK_INSTALL_INTREE=OFF \
    -DRDK_BUILD_INCHI_SUPPORT=ON \
    -DRDK_BUILD_PYTHON_WRAPPERS=OFF \
    -DRDK_BUILD_CFFI_LIB=ON \
    -DRDK_BUILD_FREETYPE_SUPPORT=ON \
    -DRDK_BUILD_CPP_TESTS=OFF \
    -DRDK_BUILD_SLN_SUPPORT=OFF \
    -DRDK_TEST_MULTITHREADED=OFF \
    "${FLAGS[@]}" \
    ..
make -j${nproc}
make install
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]

platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("librdkitcffi", :librdkitcffi),
]

dependencies = [
    Dependency("FreeType2_jll"),
    Dependency("boost_jll"; compat="=1.79.0"),
    BuildDependency("Eigen_jll"),
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               # GCC 8 is needed for `std::from_chars`
               preferred_gcc_version=v"8", julia_compat="1.6")
