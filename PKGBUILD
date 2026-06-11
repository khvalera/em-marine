pkgname=em-marine
pkgver=0.0.3.2
pkgrel=1
pkgdesc="EM-marine reader software with Ethernet interface (TCP/IP)"
arch=('x86_64')
url="https://github.com/khvalera/${pkgname}"
license=('GPL2')
depends=('qt6-base' 'qt6pas')
makedepends=('lazarus' 'fpc' 'gettext' 'which')
source=("https://github.com/khvalera/${pkgname}/archive/${pkgver}.tar.gz")
md5sums=('e3005e050672852ff12144ef50e3f33f')
backup=("etc/${pkgname}/options.ini")

_lazarusdir() {
  local d

  for d in /usr/lib/lazarus /usr/share/lazarus /usr/lib64/lazarus; do
    if [[ -d "${d}/lcl" ]]; then
      printf '%s\n' "$d"
      return 0
    fi
  done

  return 1
}

build() {
  cd "$srcdir/${pkgname}-${pkgver}"

  local lazarusdir
  lazarusdir="$(_lazarusdir)" || {
    echo "ERROR: Lazarus directory with lcl was not found."
    echo "       Check that the lazarus package is installed correctly."
    exit 1
  }

  mkdir -p "$srcdir/lazarus-config"

  lazbuild \
    --lazarusdir="$lazarusdir" \
    --pcp="$srcdir/lazarus-config" \
    --ws=qt6 \
    em_marine.lpi
}

package() {
  cd "$srcdir/${pkgname}-${pkgver}"

  # Main program
  install -Dm755 em-marine "${pkgdir}/usr/bin/${pkgname}"

  # Configuration
  install -Dm644 options.ini "${pkgdir}/etc/${pkgname}/options.ini"

  # Desktop file
  install -Dm644 "${pkgname}.desktop" "${pkgdir}/usr/share/applications/${pkgname}.desktop"

  # Documentation
  install -Dm644 README.md "${pkgdir}/usr/share/doc/${pkgname}/README.md"

  if [[ -f README_UKR.md ]]; then
    install -Dm644 README_UKR.md "${pkgdir}/usr/share/doc/${pkgname}/README_UKR.md"
  fi

  # License
  install -Dm644 COPYING "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"

  # Images
  mkdir -p "${pkgdir}/usr/share/pixmaps/${pkgname}"
  cp -a images/. "${pkgdir}/usr/share/pixmaps/${pkgname}/"

  # Translations
  mkdir -p \
    "${pkgdir}/usr/share/locale/en/LC_MESSAGES" \
    "${pkgdir}/usr/share/locale/ru/LC_MESSAGES" \
    "${pkgdir}/usr/share/locale/uk/LC_MESSAGES"

  if [[ -f PO/em_marine.po ]]; then
    msgfmt PO/em_marine.po \
      -o "${pkgdir}/usr/share/locale/en/LC_MESSAGES/${pkgname}.mo"
  fi

  if [[ -f PO/em_marine.ru.po ]]; then
    msgfmt PO/em_marine.ru.po \
      -o "${pkgdir}/usr/share/locale/ru/LC_MESSAGES/${pkgname}.mo"
  fi

  if [[ -f PO/em_marine.uk.po ]]; then
    msgfmt PO/em_marine.uk.po \
      -o "${pkgdir}/usr/share/locale/uk/LC_MESSAGES/${pkgname}.mo"
  elif [[ -f PO/em_marine.uk_UA.po ]]; then
    msgfmt PO/em_marine.uk_UA.po \
      -o "${pkgdir}/usr/share/locale/uk/LC_MESSAGES/${pkgname}.mo"
  fi
}
