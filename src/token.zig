const std = @import("std");

typ: Type,
value: Value,

const Token = @This();

pub fn lex(alloc: std.mem.Allocator, src: []const u8) !std.ArrayList(Token) {
    var out = std.ArrayList(Token).init(alloc);

    var buf = std.ArrayList(u8).init(alloc);

    var tok: Token = undefined;

    var place: usize = 0;

    while (place < src.len) : (place += 1) {
        switch (src[place]) {
            '-' => {
                place += 1;
                while (place < src.len and std.ascii.isAlNum(src[place])) : (place += 1) {
                    try buf.append(src[place]);
                }
                place -= 1;
                var num: u16 = try if (buf.items.len > 2 and buf.items[1] == 'x')
                    std.fmt.parseInt(u16, buf.items[2..], 16)
                else
                    std.fmt.parseInt(u16, buf.items, 10);
                try buf.resize(0);
                tok.typ = .integer;
                tok.value = .{ .integer = (~num) - 1 };
                try out.append(tok);
                tok = undefined;
            },
            '0'...'9' => {
                while (place < src.len and std.ascii.isAlNum(src[place])) : (place += 1) {
                    try buf.append(src[place]);
                }
                place -= 1;
                var num: u16 = try if (buf.items.len > 2 and buf.items[1] == 'x')
                    std.fmt.parseInt(u16, buf.items[2..], 16)
                else
                    std.fmt.parseInt(u16, buf.items, 10);
                try buf.resize(0);
                tok.typ = .integer;
                tok.value = .{ .integer = num };
                try out.append(tok);
                tok = undefined;
            },
            'a'...'z', 'A'...'Z' => {
                while (place < src.len and std.ascii.isAlNum(src[place])) : (place += 1) {
                    try buf.append(src[place]);
                }
                place -= 1;
                if (Register.check(buf.items)) {
                    tok.typ = .register;
                    tok.value = .{ .register = Register.get(buf.items).? };
                    try out.append(tok);
                    tok = undefined;
                } else if (Instruction.check(buf.items)) {
                    tok.typ = .instruction;
                    tok.value = .{ .instruction = Instruction.get(buf.items).? };
                    try out.append(tok);
                    tok = undefined;
                } else {
                    std.debug.print("shitty error here\n", .{});
                    std.debug.print("buf:\n{s}\n", .{buf.items});
                    std.os.exit(1);
                }
                try buf.resize(0);
            },
            '.' => {
                place += 1;
                while (place < src.len and std.ascii.isAlNum(src[place])) : (place += 1) {
                    try buf.append(src[place]);
                }
                if (Macro.get(buf.items)) |macro| {
                    tok.typ = .macro;
                    tok.value = .{ .macro = macro };
                } else {
                    // TODO: add label support
                }
                try out.append(tok);
                try buf.resize(0);
                tok = undefined;
            },
            '\r', '\n' => {
                tok.typ = .next;
                tok.value = .{ .next = {} };
                try out.append(tok);
                tok = undefined;
            },
            else => {},
        }
    }

    return out;
}

pub fn format(
    self: Token,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;

    try writer.print("type: {s} | value: {}", .{ @tagName(self.typ), self.value });
}

pub const Type = enum {
    instruction,
    register,
    macro,
    integer,
    next,
};

pub const Value = union(Type) {
    instruction: Instruction,
    register: Register,
    macro: Macro,
    integer: u16,
    next: void,
};

pub const Macro = enum(u8) {
    word,
    repeat,

    const map = std.ComptimeStringMap(Macro, .{
        .{ "word", .word },
        .{ "repeat", .repeat },
    });

    pub fn check(str: []const u8) bool {
        return map.has(str);
    }

    pub fn get(str: []const u8) ?Macro {
        return map.get(str);
    }
};

pub const Register = enum(u8) {
    ax = 0,
    bx = 3,
    cx = 1,
    dx = 2,

    const map = std.ComptimeStringMap(Register, .{
        .{ "ax", .ax },
        .{ "bx", .bx },
        .{ "cx", .cx },
        .{ "dx", .dx },
    });

    pub fn check(str: []const u8) bool {
        return map.has(str);
    }

    pub fn get(str: []const u8) ?Register {
        return map.get(str);
    }
};

pub const Instruction = enum(u8) {
    inc = 0xff,
    movi = 0xb8,
    movr = 0x8b,
    int = 0xcd,
    hlt = 0xf4,
    jmp = 0xe9,

    const map = std.ComptimeStringMap(Instruction, .{
        .{ "inc", .inc },
        .{ "movi", .movi },
        .{ "movr", .movr },
        .{ "int", .int },
        .{ "hlt", .hlt },
        .{ "jmp", .jmp },
    });

    pub fn check(str: []const u8) bool {
        return map.has(str);
    }

    pub fn get(str: []const u8) ?Instruction {
        return map.get(str);
    }
};
