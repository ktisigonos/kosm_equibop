//! Equibop's QuickCSS: the theme's colors and font as `--kosm-*` custom properties, written as
//! a block in the QuickCSS file. A Discord theme such as Material Discord reads them through
//! `var(--kosm-background)` in the user's own CSS, which the block leaves as it is.

const App = @This();

const std = @import("std");
const kosm = @import("kosm");

/// The QuickCSS file holding the block; created when missing.
/// Default: `~/.config/equibop/settings/quickCss.css`.
file: []const u8 = "~/.config/equibop/settings/quickCss.css",
/// How colors are spelled. Null fields take the CSS adapter's: `#rrggbbaa`.
format: kosm.Format = .{},
/// The colors, each written as `--kosm-<name>` with `_` as `-`. null: not written.
colors: Colors = .{},
/// `--kosm-font`: the family the theme shows text in, quoted. null: not written.
font: ?[]const u8 = null,

/// The custom properties the app writes, named for what a Discord theme uses them for.
pub const Colors = struct {
    /// `--kosm-background`: the app and chat background.
    background: ?kosm.Color = null,
    /// `--kosm-background-alt`: side panels, messages, popouts and inputs.
    background_alt: ?kosm.Color = null,
    /// `--kosm-background-highlight`: hovered and selected items.
    background_highlight: ?kosm.Color = null,
    /// `--kosm-text`: text.
    text: ?kosm.Color = null,
    /// `--kosm-text-highlight`: emphasized text and mentions.
    text_highlight: ?kosm.Color = null,
    /// `--kosm-placeholder`: placeholders in empty inputs.
    placeholder: ?kosm.Color = null,
    /// `--kosm-link`: links.
    link: ?kosm.Color = null,
    /// `--kosm-accent`: buttons, switches and the accent.
    accent: ?kosm.Color = null,
    /// `--kosm-outline`: borders and separators.
    outline: ?kosm.Color = null,
};

/// Colors from the theme: backgrounds from black (white in light mode) with the theme's
/// background alpha and its surface and state steps, text from white, links and the accent
/// cyan, outlines the theme's `line.border` of cyan.
pub fn from(theme: kosm.Theme) App {
    const palette = theme.palette;
    const variations = theme.variations;
    const foreground = if (theme.mode == .dark) palette.white else palette.black;
    const background = if (theme.mode == .dark) palette.black else palette.white;
    return .{ .colors = .{
        .background = theme.asBackground(background),
        .background_alt = theme.asBackground(variations.surface.raised.apply(background)),
        .background_highlight = theme.asBackground(variations.state.selected.apply(background)),
        .text = foreground,
        .text_highlight = variations.emphasis.strong.apply(foreground),
        .placeholder = variations.state.placeholder.apply(foreground),
        .link = palette.cyan,
        .accent = palette.cyan,
        .outline = variations.line.border.apply(palette.cyan),
    } };
}

/// Writes the set values as block `kosm` of `file`, a `:root` rule of custom properties.
pub fn apply(self: App, output: *kosm.Output) !void {
    var entries: std.ArrayList(kosm.Value.Entry) = .empty;
    inline for (@typeInfo(Colors).@"struct".field_names) |name| {
        if (@field(self.colors, name)) |color| try entries.append(output.allocator, .{ .key = name, .value = .{ .color = color } });
    }
    if (self.font) |font| try entries.append(output.allocator, .{ .key = "font", .value = .{ .string = font } });
    try output.block(.{ .file = self.file, .id = "kosm", .lang = "css", .format = self.format }, kosm.Value{ .table = &.{
        .{ .key = "kosm", .value = .{ .table = entries.items } },
    } });
}

const testing = std.testing;
const adapter = @import("root.zig").css_adapter;

const Fixture = struct {
    tmp: testing.TmpDir,
    arena: std.heap.ArenaAllocator,
    plan: kosm.Plan,
    diagnostics: kosm.Diagnostics = .{},
    warnings: kosm.Warnings = undefined,
    home_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined,
    output: kosm.Output = undefined,

    fn init(fixture: *Fixture, quick_css: ?[]const u8) !void {
        fixture.* = .{ .tmp = testing.tmpDir(.{}), .arena = .init(testing.allocator), .plan = .init(testing.allocator, testing.io) };
        if (quick_css) |text| {
            try fixture.tmp.dir.createDirPath(testing.io, ".config/equibop/settings");
            try fixture.tmp.dir.writeFile(testing.io, .{ .sub_path = ".config/equibop/settings/quickCss.css", .data = text });
        }
        fixture.warnings = .init(fixture.arena.allocator());
        const length = try fixture.tmp.dir.realPath(testing.io, &fixture.home_buffer);
        fixture.output = .{
            .allocator = fixture.arena.allocator(),
            .home = fixture.home_buffer[0..length],
            .adapters = &.{adapter},
            .plan = &fixture.plan,
            .diagnostics = &fixture.diagnostics,
            .warnings = &fixture.warnings,
            .app = "equibop",
        };
    }

    fn deinit(fixture: *Fixture) void {
        fixture.plan.deinit();
        fixture.arena.deinit();
        fixture.tmp.cleanup();
    }

    fn planned(fixture: *Fixture) []const u8 {
        for (fixture.plan.files.items) |file| {
            if (std.mem.eql(u8, file.display_path, "~/.config/equibop/settings/quickCss.css")) return file.new;
        }
        return "(not planned)";
    }
};

const user_css =
    \\.theme-dark {
    \\    --background-col: var(--kosm-background);
    \\}
    \\
;

test "the colors and font are a block after the user's own CSS, which is kept" {
    var fixture: Fixture = undefined;
    try fixture.init(user_css);
    defer fixture.deinit();
    var theme = kosm.Theme.from(.{ .black = kosm.hex("041c26"), .white = kosm.hex("a3c5cc"), .cyan = kosm.hex("2d8699") }, .dark);
    theme.background_alpha = 0.5;
    var app = from(theme);
    app.font = "Maple Mono Normal NFP";
    try app.apply(&fixture.output);

    const written = fixture.planned();
    try testing.expect(std.mem.startsWith(u8, written, user_css));
    try testing.expect(std.mem.indexOf(u8, written, "  --kosm-background: #041c2680;\n  --kosm-background-alt: ") != null);
    try testing.expect(std.mem.indexOf(u8, written, "  --kosm-text: #a3c5ccff;\n") != null);
    try testing.expect(std.mem.indexOf(u8, written, "  --kosm-link: #2d8699ff;\n") != null);
    try testing.expect(std.mem.indexOf(u8, written, "  --kosm-font: \"Maple Mono Normal NFP\";\n}") != null);
}

test "a missing QuickCSS is created holding only the block, and null values are left out" {
    var fixture: Fixture = undefined;
    try fixture.init(null);
    defer fixture.deinit();
    const app: App = .{ .colors = .{ .text = kosm.hex("ffffff") } };
    try app.apply(&fixture.output);
    const written = fixture.planned();
    try testing.expect(std.mem.indexOf(u8, written, ":root {\n  --kosm-text: #ffffffff;\n}") != null);
    try testing.expect(std.mem.indexOf(u8, written, "--kosm-background") == null);
}
