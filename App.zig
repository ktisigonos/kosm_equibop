//! Equibop's theme: a local theme, `kosm.theme.css`, recoloring Material Discord with the
//! theme's colors, font and rounding. The theme also sets them as `--kosm-*` custom
//! properties, for the user's own QuickCSS to use.

const App = @This();

const std = @import("std");
const kosm = @import("kosm");

/// Equibop's data folder, holding `themes/`. Default: the Flatpak's,
/// `~/.var/app/org.equicord.equibop/config/equibop`; a native Equibop uses `~/.config/equibop`.
directory: []const u8 = "~/.var/app/org.equicord.equibop/config/equibop",
/// How colors are spelled. Null fields take the CSS adapter's: `#rrggbbaa`.
format: kosm.Format = .{},
/// The colors, each also written as `--kosm-<name>` with `_` as `-`.
colors: Colors,
/// `--app-font`: the family text is shown in. Default: Material Discord's, "Google Sans Flex".
font: []const u8 = "Google Sans Flex",
/// Corner radius in pixels of messages, cards, popouts, buttons, inputs and tooltips; side
/// panels get half of it. null: Material Discord's own radii, round buttons and inputs.
rounding: ?u32 = null,

/// The colors the theme gives Material Discord, named for what they paint.
pub const Colors = struct {
    /// The app and chat background.
    background: kosm.Color,
    /// Side panels, messages, popouts, cards and inputs.
    background_alt: kosm.Color,
    /// Hovered and selected items.
    background_highlight: kosm.Color,
    /// Text.
    text: kosm.Color,
    /// Headings and emphasized text.
    text_highlight: kosm.Color,
    /// Placeholders in empty inputs, muted and disabled text.
    placeholder: kosm.Color,
    /// Links.
    link: kosm.Color,
    /// Buttons, switches and the accent. Material Discord takes its hue, saturation and
    /// lightness, not its alpha.
    accent: kosm.Color,
    /// Text on the accent.
    accent_text: kosm.Color,
    /// Borders and separators.
    outline: kosm.Color,
};

/// Colors from the theme: backgrounds from the background role with the theme's background
/// alpha and its surface and state steps, text from the foreground role, links and the accent
/// from their roles, text on the accent the opaque background role, outlines the theme's
/// `line.border` of the accent.
pub fn from(theme: kosm.Theme) App {
    const variations = theme.variations;
    const foreground = theme.roles.foreground;
    const background = theme.roles.background;
    return .{ .colors = .{
        .background = theme.asBackground(background),
        .background_alt = theme.asBackground(variations.surface.raised.apply(background)),
        .background_highlight = theme.asBackground(variations.state.selected.apply(background)),
        .text = foreground,
        .text_highlight = variations.emphasis.strong.apply(foreground),
        .placeholder = variations.state.placeholder.apply(foreground),
        .link = theme.roles.link,
        .accent = theme.roles.accent,
        .accent_text = background,
        .outline = variations.line.border.apply(theme.roles.accent),
    } };
}

/// What the template reads.
const Values = struct {
    colors: Colors,
    font: []const u8,
    /// The accent as Material Discord's `--accent-hsl`: `hue, saturation%, lightness%`.
    accent_hsl: kosm.Raw,
    /// One `--<name>-radius` line per radius, or nothing.
    rounding_properties: kosm.Raw,
};

/// Writes `themes/kosm.theme.css` in `directory`.
pub fn apply(self: App, output: *kosm.Output) !void {
    const file = try std.mem.concat(output.allocator, u8, &.{ self.directory, "/themes/kosm.theme.css" });
    if (std.mem.indexOfAny(u8, self.font, "\"\\\n") != null)
        return output.fail(file, "font '{s}' holds a quote, backslash or line break, which a CSS string would need escaped", .{self.font});
    const values: Values = .{
        .colors = self.colors,
        .font = self.font,
        .accent_hsl = kosm.raw(try accentHsl(output.allocator, self.colors.accent)),
        .rounding_properties = kosm.raw(if (self.rounding) |rounding| try roundingProperties(output.allocator, rounding) else ""),
    };
    try output.template(values, .{ .file = file, .text = @embedFile("theme.css"), .format = self.format });
}

fn accentHsl(allocator: std.mem.Allocator, accent: kosm.Color) ![]const u8 {
    const hsl = kosm.Color.Hsl.fromRgb(accent.toRgb());
    return std.fmt.allocPrint(allocator, "{d:.1}, {d:.1}%, {d:.1}%", .{ hsl.hue, hsl.saturation * 100, hsl.lightness * 100 });
}

/// Material Discord's radii of the large rounded parts, written as `--<name>-radius`.
const large_radii = [_][]const u8{ "message", "media", "main-textarea", "popout", "popout-radius-big", "card", "card-radius-big", "button", "input", "tooltip", "sidebar-panel-radius-big" };
/// Radii rounded half as much.
const small_radii = [_][]const u8{"sidebar-panel-radius-small"};

fn roundingProperties(allocator: std.mem.Allocator, rounding: u32) ![]const u8 {
    var text: std.Io.Writer.Allocating = .init(allocator);
    for (large_radii) |name| try writeRadius(&text.writer, name, rounding);
    for (small_radii) |name| try writeRadius(&text.writer, name, rounding / 2);
    return text.written();
}

fn writeRadius(writer: *std.Io.Writer, name: []const u8, pixels: u32) !void {
    const suffix = if (std.mem.indexOf(u8, name, "radius") == null) "-radius" else "";
    try writer.print("  --{s}{s}: {d}px;\n", .{ name, suffix, pixels });
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

    fn init(fixture: *Fixture) !void {
        fixture.* = .{ .tmp = testing.tmpDir(.{}), .arena = .init(testing.allocator), .plan = .init(testing.allocator, testing.io) };
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
            if (std.mem.eql(u8, file.display_path, "~/.var/app/org.equicord.equibop/config/equibop/themes/kosm.theme.css")) return file.new;
        }
        return "(not planned)";
    }
};

fn testTheme() kosm.Theme {
    var theme = kosm.Theme.from(.{ .palette = .{ .black = kosm.hex("041c26"), .white = kosm.hex("a3c5cc"), .cyan = kosm.hex("2d8699") }, .mode = .dark });
    theme.background_alpha = 0.5;
    return theme;
}

fn expectContains(text: []const u8, part: []const u8) !void {
    if (std.mem.indexOf(u8, text, part) == null) {
        std.debug.print("missing: {s}\nin:\n{s}\n", .{ part, text });
        return error.TestExpectedEqual;
    }
}

test "the theme sets the colors and font and points Material Discord's variables at them" {
    var fixture: Fixture = undefined;
    try fixture.init();
    defer fixture.deinit();
    var app = from(testTheme());
    app.font = "Maple Mono Normal NFP";
    try app.apply(&fixture.output);

    const written = fixture.planned();
    try expectContains(written, "  --kosm-background: #041c2680;\n");
    try expectContains(written, "  --kosm-text: #a3c5ccff;\n");
    try expectContains(written, "  --kosm-font: \"Maple Mono Normal NFP\";\n");
    try expectContains(written, "  --main-color: var(--kosm-background);\n");
    try expectContains(written, "  --accent-hsl: 190.6, 54.5%, 38.8%;\n");
    try testing.expect(std.mem.indexOf(u8, written, "-radius:") == null);
    try testing.expect(std.mem.endsWith(u8, written, "var(--kosm-text);\n}\n"));
}

test "rounding sets the large radii and halves the small ones" {
    var fixture: Fixture = undefined;
    try fixture.init();
    defer fixture.deinit();
    var app = from(testTheme());
    app.rounding = 10;
    try app.apply(&fixture.output);

    const written = fixture.planned();
    try expectContains(written, "  --scrollbar-color: var(--kosm-text);\n  --message-radius: 10px;\n");
    try expectContains(written, "  --popout-radius-big: 10px;\n");
    try expectContains(written, "  --sidebar-panel-radius-small: 5px;\n}\n");
}

test "a font holding a quote fails instead of writing broken CSS" {
    var fixture: Fixture = undefined;
    try fixture.init();
    defer fixture.deinit();
    var app = from(testTheme());
    app.font = "Maple \"Mono\"";
    try testing.expectError(error.AppFailed, app.apply(&fixture.output));
    try testing.expectEqual(0, fixture.plan.files.items.len);
}
