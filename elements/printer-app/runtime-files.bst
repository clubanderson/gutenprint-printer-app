kind: manual
description: Install isolated OCI launcher and shared CUPS executable links.

sources:
  - kind: local
    path: files

  - kind: local
    path: testpage.ps
build-depends:
  - fsdk-containers.bst:freedesktop-sdk.bst:public-stacks/runtime-gnu.bst
  - fsdk-containers.bst:freedesktop-sdk.bst:components/strace.bst
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
      echo "--- caps"; grep Cap /proc/self/status; cat /proc/self/uid_map /proc/self/gid_map
      echo "--- gs binary"; ls -la /usr/bin/gs; readlink -f /usr/bin/gs; file "$(readlink -f /usr/bin/gs)" || true
      cat testpage.ps > /dev/null && echo CAT_OK
      cp testpage.ps copy.ps && echo CP_OK
      sh -c ': <> probe-rdwr' && echo SH_RDWR_CREATE_OK
      sh -c ': <> testpage.ps' && echo SH_RDWR_EXISTING_OK
      sh -c ': < testpage.ps' && echo SH_RDONLY_OK
      cp testpage.ps /tmp/testpage.ps && gs -q -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=/tmp/o.pdf /tmp/testpage.ps && echo GS_ALL_TMP_OK
      gs -q -dNOSAFER -dBATCH -dNOPAUSE -sDEVICE=nullpage testpage.ps && echo GS_NULL_READ_OK
      echo "--- strace gs read"; strace -f -e trace=%file,%desc -o /tmp/st-read.txt gs -q -dNOSAFER -dBATCH -dNOPAUSE -sDEVICE=nullpage testpage.ps; grep -n "testpage\|EACCES\|EPERM\|EROFS" /tmp/st-read.txt | tail -20
      echo "--- strace gs write"; strace -f -e trace=%file,%desc -o /tmp/st-write.txt gs -q -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=probe-safer.pdf testpage.ps; grep -n "probe-safer\|testpage\|EACCES\|EPERM\|EROFS" /tmp/st-write.txt | tail -20
      echo "--- strace cat"; strace -e trace=%file -o /tmp/st-cat.txt cat testpage.ps >/dev/null; grep -n testpage /tmp/st-cat.txt
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
