//! Equibop: the theme's colors and font as custom properties in QuickCSS, for Discord themes.

const std = @import("std");

/// The QuickCSS block; build one with `from`.
pub const App = @import("App.zig");
/// Colors from the theme.
pub const from = App.from;
/// The adapter the app writes the block with, so a config needs only this package.
pub const css_adapter = @import("kosm_css").adapter;

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(App);
}
