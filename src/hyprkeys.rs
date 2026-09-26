// Bachy leaves the user's compositor configuration under their control.
// --default claims the XDG folder handler and portal only.
pub fn claim() -> Result<String, String> {
    Ok("keys: add a Bachy shortcut in your Hyprland configuration; see docs/bachy.md".into())
}
pub fn release() -> Result<String, String> {
    Ok("keys: no compositor configuration was changed by Bachy".into())
}
pub fn float_claim() -> Result<String, String> {
    Ok("window: add the optional picker floating rule from docs/bachy.md".into())
}
pub fn float_release() -> Result<String, String> {
    Ok("window: no compositor configuration was changed by Bachy".into())
}
