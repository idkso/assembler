const std = @import("std");
const Token = @import("token.zig");

pub fn parse(
    alloc: std.mem.Allocator,
    toks: std.ArrayList(Token),
) !std.ArrayList(Statement) {
    var out = std.ArrayList(Statement).init(alloc);

    var started: bool = false;
    var state: State = undefined;
    var inst: Instruction = undefined;
    var macro: Macro = undefined;

    for (toks.items) |x| {
        if (!started and x.typ == .instruction) {
            inst.op = x;
            inst.ops = std.ArrayList(Token).init(alloc);
            started = true;
            state = .instruction;
        } else if (!started and x.typ == .macro) {
            macro.op = x;
            macro.ops = std.ArrayList(Token).init(alloc);
            started = true;
            state = .macro;
        } else if (started and x.typ == .next) {
            started = false;
            if (state == .macro) {
                try out.append(.{ .macro = macro });
            } else {
                try out.append(.{ .instruction = inst });
            }
        } else if (started and x.typ != .instruction) {
            if (state == .macro) {
                try macro.ops.append(x);
            } else {
                try inst.ops.append(x);
            }
        } else if (x.typ == .next) {
            
        } else {
            std.debug.print("ummm idk: {any} {any} {any}\n", .{x, state, started});
            std.os.exit(1);
        }
    }

    return out;
}

pub const Statement = union(enum) {
    macro: Macro,
    instruction: Instruction,
};

pub const State = enum(u8) {
    instruction,
    macro,
};

pub const Macro = struct {
    op: Token,
    ops: std.ArrayList(Token),
    
    pub fn format(
        self: *const Macro,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("macro: {}\n", .{self.op});
        try writer.print("ops:\n", .{});
        for (self.ops.items) |x| {
            try writer.print("{}\n", .{x});
        }
    }

};

pub const Instruction = struct {
    op: Token,
    ops: std.ArrayList(Token),

    pub fn format(
        self: *const Instruction,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("instruction: {}\n", .{self.op});
        try writer.print("ops:\n", .{});
        for (self.ops.items) |x| {
            try writer.print("{}\n", .{x});
        }
    }
};
