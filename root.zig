//! Equibop: a local theme recoloring Material Discord with the theme's colors, font and rounding.

const std = @import("std");

/// The theme; build one with `from`.
pub const App = @import("App.zig");
/// Colors from the theme.
pub const from = App.from;
/// The adapter the app writes the block with, so a config needs only this package.
pub const css_adapter = @import("kosm_css").adapter;

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(App);
}
