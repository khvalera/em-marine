pkgname=em-marine
pkgver=0.0.1.5
pkgrel=1
pkgdesc="Sound system events for the snuglinux distribution."
arch=('any')
url="https://github.com/snuglinux/${pkgname}"
license=('GPL2')
makedepends=("lazarus" "git" "which")
source=("https://github.com/khvalera/${pkgname}/archive/${pkgver}.tar.gz")
md5sums=('f596364fc76ae6499670a1860b633e70')
backup=( "etc/${pkgname}/options.ini" )

package(){
  cd "$srcdir/${pkgname}-${pkgver}"

  export lazbuild=$(which lazbuild)
  ${lazbuild} em_marine.lpi

  # Create folders
  mkdir -p ${pkgdir}/etc/${pkgname} \
           ${pkgdir}/usr/bin \
           ${pkgdir}/usr/share/pixmaps/${pkgname} \
           ${pkgdir}/usr/share/applications \
           ${pkgdir}/usr/share/doc/${pkgname} \
           ${pkgdir}/usr/share/licenses/${pkgname} \
           ${pkgdir}/usr/share/locale/en/LC_MESSAGES \
           ${pkgdir}/usr/share/locale/ru/LC_MESSAGES \
           ${pkgdir}/usr/share/locale/uk/LC_MESSAGES

  # Copy files
  install -m755 em_marine         "${pkgdir}/usr/bin/${pkgname}"
  install -m644 README.md         "${pkgdir}/usr/share/doc/${pkgname}/README"
  install -Dm 644 COPYING         "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
  install -Dm 644 options.ini     "${pkgdir}/etc/${pkgname}"
  install -Dm 644 ${pkgname}.desktop "${pkgdir}/usr/share/applications"

  msgfmt PO/em_marine.po \
         -o ${pkgdir}/usr/share/locale/en/LC_MESSAGES/${pkgname}.mo
  msgfmt PO/em_marine.ru.po \
         -o ${pkgdir}/usr/share/locale/ru/LC_MESSAGES/${pkgname}.mo

  cp -r images/* ${pkgdir}/usr/share/pixmaps/${pkgname}/
}

