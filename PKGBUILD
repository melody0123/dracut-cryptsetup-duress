# Maintainer: Chenglong Yu <chenglong.yu.cs@proton.me>
pkgname=dracut-cryptsetup-duress
pkgver=0.1.0
pkgrel=1
pkgdesc="A Dracut module for defensive data protection and emergency key management in high-security environments."
arch=('any')
url="https://github.com/melody0123/dracut-cryptsetup-duress"
license=('GPL-3.0-or-later')
depends=('dracut' 'cryptsetup' 'bash' 'python3' 'tpm2-tools' 'systemd' 'keyutils' 'openssl' 'coreutils')
makedepends=('git' 'make' 'coreutils')
source=("${pkgname}-${pkgver}.tar.gz")
sha256sums=('SKIP')
install=dracut-cryptsetup-duress.install

package() {
  cd "${pkgname}-${pkgver}"
  make DESTDIR="${pkgdir}" install
}
