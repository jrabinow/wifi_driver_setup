#!/usr/bin/env bash

set -e -u
set -o pipefail

# to setup:
#   - copy the files in `dom0` directory to dom0 domain
#   - copy the files in `sys-usb` directory to sys-usb domain
#   - run the following in sys-net console
# `sudo bash -c 'echo "/home/user/wifi_driver_setup/build_dkms.sh &" >> /rw/config/rc.local'`

function usage ()
{
    cat << EOF
Usage: $(basename $0) [OPTION]...
Options: --help, -h: show this help dialog
EOF
}

function new_build ()
{
    notify-send 'Rebuilding DKMS kernel package'
    VER=$(sed -n 's/\PACKAGE_VERSION="\(.*\)"/\1/p' ${KERNEL_MODULE_SRCDIR}/dkms.conf)
    sudo rsync -rvhP "${KERNEL_MODULE_SRCDIR}/" /usr/src/rtl88x2bu-${VER}
    if [[ -z $(dkms status -m rtl88x2bu) ]]; then
        sudo dkms add -m rtl88x2bu -v ${VER}
    fi
    sudo dkms build -m rtl88x2bu -v ${VER}
    sudo dkms install -m rtl88x2bu -v ${VER}

    mkdir -p "${CACHED_BUILDDIR}"
    cp "${INSTALLDIR}/${KERNEL_MODULE_FILE}" "${CACHED_BUILDDIR}"
}

function load_module ()
{
    readonly local CACHED_KERNEL_MODULE="${CACHED_BUILDDIR}/${KERNEL_MODULE_FILE}"

    test -f "${INSTALLDIR}/${KERNEL_MODULE_FILE}" || \
        test -f "${CACHED_KERNEL_MODULE}" || \
        new_build
    sudo cp "${CACHED_KERNEL_MODULE}"  "${INSTALLDIR}"
    sudo chown root:root "${INSTALLDIR}/${KERNEL_MODULE_FILE}"
    sudo depmod
    sudo modprobe "$(basename "${KERNEL_MODULE_FILE}" .ko)" || \
        notify-send "failed to install wifi kernel module, no internet for you 💩💩💩"
}

function main ()
{
    readonly local BASEDIR=$(realpath $(dirname $0))
    readonly local KERNEL_MODULE_SRCDIR="${BASEDIR}/src/rtl88x2bu"
    readonly local CACHED_BUILDDIR="${BASEDIR}/cached_build/$(uname -r)"
    readonly local KERNEL_MODULE_FILE=88x2bu.ko
    readonly local INSTALLDIR=/lib/modules/$(uname -r)/extra

    while getopts "h-:" opt; do
        case ${opt} in
            h)  # help message
                usage
                exit 0
                ;;
            -)
                case "${OPTARG}" in
                    help)
                        usage
                        exit 0
                        ;;
                    *)
                        printf 'Unknown option, exiting now\n' >&2
                        exit 1
                        ;;
                esac
                ;;
            ?)
                printf 'Unknown option, exiting now\n' >&2
                exit 1
                ;;
        esac
    done
    shift $((OPTIND - 1))
    [[ "${1:-}" == '--' ]] && shift

    cd "$(dirname $0)"
    load_module
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    main "$@"
fi
