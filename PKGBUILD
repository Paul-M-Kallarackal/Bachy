# Bachy packaging, adapted from Flea (GM).

pkgname=bachy
pkgver=0.1.0
pkgrel=1
pkgdesc='Keyboard-first file manager for CachyOS, forked from Flea'
url='https://github.com/Paul-M-Kallarackal/Bachy'
arch=('x86_64' 'aarch64')
license=('MIT')
# Self-contained QML components; no distribution shell dependency.
depends=('bubblewrap' 'expect' 'gcc-libs' 'glib2' 'glibc' 'gvfs' 'gvfs-afc' 'gvfs-dnssd' 'gvfs-gphoto2' 'gvfs-mtp' 'gvfs-nfs' 'gvfs-smb' 'hicolor-icon-theme' 'kimageformats' 'libheif' 'python' 'python-gobject' 'qt6-multimedia' 'qt6-webengine' 'quickshell>=0.3.1' 'qt6-wayland' 'noto-fonts' 'shared-mime-info' 'usbmuxd' 'util-linux' 'wl-clipboard' 'xdg-terminal-exec' 'xdg-utils')
makedepends=('cargo')
conflicts=()
optdepends=('libarchive: archive listing and extraction'
            '7zip: 7z archive support'
            'imagemagick: image conversion'
            'tailscale: Taildrop sharing'
            'ffmpeg: media metadata in the preview column'
            'ffmpegthumbnailer: video thumbnails, made by one pre-linked worker through libffmpegthumbnailer.so.4, or by the ffmpegthumbnailer program per video when that library will not load'
            'dropbox-cli: Dropbox share links')
# The release profile strips, so a debug package would have nothing to hold.
options=('!debug')
# Empty on purpose: with no source array makepkg builds from $startdir, so a clone is the source.
source=()

build() {
  # Its own target directory, so a makepkg run never disturbs the checkout's target/.
  export CARGO_TARGET_DIR="$srcdir/target"
  cd "$startdir"
  cargo build --release --locked
}

check() {
  export CARGO_TARGET_DIR="$srcdir/target"
  cd "$startdir"
  cargo test --release --locked
  # These two need no built binary and locate themselves, so they run correctly under makepkg.
  # The rest of tests/ resolves ./target/<profile>/bachy against the repo root, which CARGO_TARGET_DIR
  # has moved, so they would refuse on a clean clone or silently test a stale binary on a dev box.
  ./tests/js.sh
  ./tests/keymap-gen.sh
}

package() {
  cd "$startdir"
  install -Dm755 "$srcdir/target/release/bachy" "$pkgdir/usr/bin/bachy"
  install -Dm755 tools/bachy-gio-auth "$pkgdir/usr/lib/bachy/bachy-gio-auth"
  # The portal backend, its registration and its D-Bus activation: xdg-desktop-portal 1.22 reads
  # portals/ out of every data dir, and this is Bachy's own package writing Bachy's own files.
  install -Dm755 tools/bachy-portal "$pkgdir/usr/lib/bachy/bachy-portal"
  install -Dm644 packaging/bachy.portal -t "$pkgdir/usr/share/xdg-desktop-portal/portals"
  install -Dm644 packaging/org.freedesktop.impl.portal.desktop.bachy.service -t "$pkgdir/usr/share/dbus-1/services"
  # org.freedesktop.FileManager1, which is what Chromium's "Show in folder" calls. The file is named
  # for Bachy and not for the interface: nautilus owns the plain org.freedesktop.FileManager1.service
  # path here, and dolphin, thunar and nemo each ship their own vendor-named file declaring the same
  # Name=, so a vendor name is the convention and the only way to avoid a pacman file conflict.
  install -Dm755 tools/bachy-filemanager1 "$pkgdir/usr/lib/bachy/bachy-filemanager1"
  install -Dm644 packaging/local.bachy.FileManager.FileManager1.service -t "$pkgdir/usr/share/dbus-1/services"
  install -Dm644 packaging/local.bachy.FileManager.desktop -t "$pkgdir/usr/share/applications"
  install -Dm644 packaging/local.bachy.FileManager.svg -t "$pkgdir/usr/share/icons/hicolor/scalable/apps"
  install -Dm644 LICENSE -t "$pkgdir/usr/share/licenses/$pkgname"
  # Issue 173: a tracked alpm hook, not a scriptlet, that prints the per-user undo commands on removal.
  install -Dm644 packaging/bachy.hook -t "$pkgdir/usr/share/libalpm/hooks"

  # paths.rs looks for /usr/share/bachy/ui/boot/shell.qml, so the UI ships as data beside the binary.
  install -Dm644 ui/qmldir ui/*.qml -t "$pkgdir/usr/share/bachy/ui"
  install -Dm644 ui/js/*.js -t "$pkgdir/usr/share/bachy/ui/js"
  # The two Quickshell entries, in their own directory so ui/qmldir's singletons stay off the startup path.
  install -Dm644 ui/boot/shell.qml ui/boot/picker.qml -t "$pkgdir/usr/share/bachy/ui/boot"
}
