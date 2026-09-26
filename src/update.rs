// A personal fork must never replace itself with an upstream package.
pub fn check() -> i32 {
    println!("unchecked local {} -", env!("CARGO_PKG_VERSION"));
    3
}
pub fn launch() -> i32 {
    eprintln!("bachy: update this personal build from its source directory with makepkg -si");
    3
}
