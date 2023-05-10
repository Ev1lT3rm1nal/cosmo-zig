const cosmopolitan = @import("cosmopolitan");

export fn main() callconv(.C) void {
    _ = cosmopolitan.puts("Hello, world!\n");
    return;
}
