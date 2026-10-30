#!/bin/bash
set -eo pipefail

cmake ${CMAKE_ARGS} -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_CXX_SCAN_FOR_MODULES=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DGAUDI_INSTALL_PYTHONDIR="${SP_DIR}" \
    -DGAUDI_DEFAULT_PLUGIN_PATH="${PREFIX}/lib" \
    -DPython_EXECUTABLE="${PYTHON}" \
    -DGAUDI_USE_DOXYGEN=OFF \
    -S "${SRC_DIR}" -B build
cmake --build build --parallel "${CPU_COUNT}"

# Same exclusions as conda-forge: the downstream-project test needs ROOT
# development files at test time, and the 10-thread whiteboard test times
# out on small runners. test_ConfDB_wrapper writes shelve files directly,
# which Python 3.12 can't keep in a single .confdb2 file, and the
# GaudiConfiguration coverage steps then miss its coverage file.
ctest --output-on-failure --test-dir build -j"${CPU_COUNT}" --repeat until-pass:3 \
    -E 'cmake\.test_dummyGaudiDownstreamProject|whiteboard\.test_bug_cfhep114|test_ConfDB_wrapper|GaudiConfiguration\.pytest\.python\.coverage_'
cmake --install build
