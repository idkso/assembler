const std = @import("std");

const Token = @import("token.zig");
const AST = @import("ast.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var cwd = std.fs.cwd();

    var srcfile = try cwd.openFile(std.mem.sliceTo(std.os.argv[1], 0), .{ .mode = .read_only });

    var src = try srcfile.readToEndAlloc(alloc, std.math.maxInt(u32));

    var x = try Token.lex(alloc, src);

    var y = try AST.parse(alloc, x);

    var code = std.ArrayList(u8).init(alloc);

    try codegen(y, code.writer());

    var f = try cwd.createFile("out.bin", .{});
    try f.writeAll(code.items);
    f.close();
}

pub fn codegen(
    ast: std.ArrayList(AST.Statement),
    writer: anytype,
) !void {
    var lol = ast.items;

    var place: usize = 0;
    var index: usize = 0;
    var started: bool = false;
    var state: AST.State = switch (lol[place]) {
        .macro => .macro,
        .instruction => .instruction,
    };

    var inst: Token.Instruction = undefined;
    var macro: Token.Macro = undefined;

    while (place < lol.len) {
        var idk = switch (lol[place]) {
            .macro => lol[place].macro.ops.items,
            .instruction => lol[place].instruction.ops.items,
        };
        if (!started and state == .instruction) {
            started = true;
            inst = lol[place].instruction.op.value.instruction;
            continue;
        } else if (!started and state == .macro) {
            started = true;
            macro = lol[place].macro.op.value.macro;
            continue;
        } else if (started and index >= idk.len) {
            // idk yet
            place += 1;
            if (place == lol.len) continue;
            state = switch (lol[place]) {
                .macro => .macro,
                .instruction => .instruction,
            };
            index = 0;
            started = false;
        } else if (started and state == .macro and idk[index].typ != .instruction) {
            switch (macro) {
                .word => {
                    try writer.writeIntLittle(u16, idk[index].value.integer);
                },
                .repeat => {
                    var x: usize = 0;
                    while (x < idk[index+1].value.integer) : (x += 1) {
                        try writer.writeIntLittle(u16, idk[index].value.integer);
                    }
                    index += 1;
                },
            }
            index += 1;
        } else if (started and state == .instruction and idk[index].typ != .instruction) {
            switch (inst) {
                .movi => {
                    // try writer.writeByte(0x66);
                    try writer.writeByte(@enumToInt(inst) + @enumToInt(idk[index].value.register));
                    try writer.writeIntLittle(u16, idk[index + 1].value.integer);
                    index += 1;
                },
                .int => {
                    try writer.writeByte(@enumToInt(inst));
                    try writer.writeIntLittle(u8, @intCast(u8, idk[index].value.integer));
                },
                .movr => {
                    // no
                },
                .inc => {
                    try writer.writeByte(0x66);
                    try writer.writeByte(@enumToInt(inst));
                    try writer.writeByte(0xc0 + @enumToInt(idk[index].value.register));
                },
                .hlt => {
                    try writer.writeByte(@enumToInt(inst));
                },
                .jmp => {
                    try writer.writeByte(@enumToInt(inst));
                    try writer.writeIntLittle(u16, idk[index].value.integer);
                }
            }
            index += 1;
        }
    }
}

test "adding 1 and 1" {
    try std.testing.expectEqual(1 + 1, 2);
}
