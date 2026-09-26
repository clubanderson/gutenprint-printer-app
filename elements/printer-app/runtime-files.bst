kind: manual
description: Install isolated OCI launcher and shared CUPS executable links.

sources:
  - kind: local
    path: files

  - kind: local
    path: testpage.ps
build-depends:
  - fsdk-containers.bst:freedesktop-sdk.bst:public-stacks/runtime-gnu.bst
  - fsdk-containers.bst:printing/base.bst

config:
  build-commands:
    - |
      set +e
      echo "=== PROBE fsdk-containers#332"; pwd; id; uname -a
      cat /proc/mounts
      echo "--- ls -la ."; ls -la .
      echo "--- ls -ld / . /buildstream-install /tmp"; ls -ld / . /buildstream-install /tmp
      echo "--- stat -f ."; stat -f .
      touch probe-touch && echo TOUCH_OK
      echo hi > probe-redirect && echo REDIRECT_OK
      mkdir probe-dir && echo MKDIR_OK
      rm -f probe-touch probe-redirect && echo RM_OK
      gs -q -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=probe-safer.pdf testpage.ps && echo GS_SAFER_OK
      gs -q -dNOSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=probe-nosafer.pdf testpage.ps && echo GS_NOSAFER_OK
      gs -q -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=/tmp/probe-tmp.pdf testpage.ps && echo GS_TMP_OK
      gs -q -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile="$PWD/probe-abs.pdf" testpage.ps && echo GS_ABS_OK
      echo "--- ls -la . /tmp"; ls -la . /tmp
      echo "--- env"; env | sort
      echo "=== PROBE END"
    # testpage.ps sizes itself from the device page, so pin the US Letter
    # geometry its %%BoundingBox declares instead of Ghostscript's default.
    - gs -q -dSAFER -dBATCH -dNOPAUSE -dFIXEDMEDIA -sPAPERSIZE=letter -sDEVICE=pdfwrite -sOutputFile=testpage.pdf testpage.ps
    - test -s testpage.pdf
  install-commands:
    - install -D -m 0755 container-entrypoint.sh "%{install-root}/usr/libexec/gutenprint-printer-app/container-entrypoint"
    - install -D -m 0644 testpage.pdf "%{install-root}/usr/share/gutenprint-printer-app/testpage.pdf"
    - install -d "%{install-root}/usr/share/ppd" "%{install-root}/usr/lib/gutenprint-printer-app/backend" "%{install-root}/usr/lib/gutenprint-printer-app/filter"
    - ln -s /usr/lib/gutenprint-printer-app/driver/gutenprint.5.3 "%{install-root}/usr/share/ppd/gutenprint.5.3"
    - |
      for backend in /usr/lib/cups/backend/{snmp,dnssd,socket,ipp,ipps,lpd,usb}; do
        test -x "$backend"
        ln -s "$backend" "%{install-root}/usr/lib/gutenprint-printer-app/backend/${backend##*/}"
      done
      for filter in /usr/lib/cups/filter/*; do
        test -x "$filter" || continue
        ln -s "$filter" "%{install-root}/usr/lib/gutenprint-printer-app/filter/${filter##*/}"
      done
