#!/usr/bin/env bash

ci_dir="$(dirname "$0")"
. "${ci_dir}/ci-common.sh"

VST_CI_DIR="${CI_BUILD_DIR}/VST"

# opam install -j ${NJOBS} -y menhir
git_checkout "${VST_CI_BRANCH}" "${VST_CI_GITURL}" "${VST_CI_DIR}"

# We have to omit progs as otherwise we timeout on Travis; on Gitlab
# we will be able to just use `make`
( cd "${VST_CI_DIR}" && make IGNORECOQVERSION=true -o progs )
