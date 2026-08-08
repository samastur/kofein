import AppKit

let app = NSApplication.shared
// Menubar-only app: no Dock icon, no app menu (LSUIElement in the bundle,
// activation policy for when the bare executable is run during development).
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
