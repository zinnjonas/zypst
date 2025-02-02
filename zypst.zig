const std = @import("std");
const allocator = std.heap.page_allocator;

const TypstParameter = struct {
    length: usize,
    content: []u8 = undefined,

    pub fn init(length: usize) !TypstParameter {
        return .{
            .length = length,
            .content = try allocator.alloc(u8, length),
        };
    }

    pub fn deinit(self: TypstParameter) void {
        allocator.free(self.content);
    }
};

// ===
// Functions for the protocol

extern "typst_env" fn wasm_minimal_protocol_send_result_to_host(ptr: [*]const u8, len: usize) void;
extern "typst_env" fn wasm_minimal_protocol_write_args_to_buffer(ptr: [*]u8) void;

// Function to ease the communication with typst

pub fn send_error(err: anyerror) u8 {
    const buffer = std.fmt.allocPrint(allocator, "{}", .{err}) catch return 1;
    send(buffer);
    return 1;
}

pub fn send_error_msg(text: []const u8) u8 {
    send(text);
    return 1;
}

pub fn send(text: []const u8) void {
    wasm_minimal_protocol_send_result_to_host(text.ptr, text.len);
}

pub fn send_number(number: anytype) u8 {
    const result = std.fmt.allocPrint(allocator, "{d}", .{number}) catch return 1;
    defer allocator.free(result);
    send(result);
    return 0;
}

pub fn receive(parameters: []const TypstParameter) !void {
    var total: usize = 0;
    for (parameters) |parameter| {
        total += parameter.length;
    }
    const arguments = try allocator.alloc(u8, total);
    defer allocator.free(arguments);
    wasm_minimal_protocol_write_args_to_buffer(arguments.ptr);

    var start: usize = 0;
    for (parameters) |parameter| {
        _ = try std.fmt.bufPrint(parameter.content, "{s}", .{arguments[start .. start + parameter.length]});
        start += parameter.length;
    }
}

pub fn get_parameters(lengths: []const usize) ![]const TypstParameter {
    const parameters: []TypstParameter = try allocator.alloc(TypstParameter, lengths.len);
    for (0..lengths.len) |index| {
        parameters[index] = try TypstParameter.init(lengths[index]);
    }
    try receive(parameters);
    return parameters;
}

pub fn deinit_parameters(parameters: []const TypstParameter) void {
    for (parameters) |parameter| {
        parameter.deinit();
    }
    allocator.free(parameters);
}

pub fn generate_json(content: anytype) !std.ArrayList(u8) {
    var buf: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var string = std.ArrayList(u8).init(fba.allocator());
    try std.json.stringify(content, .{}, string.writer());
    return string;
}

// ===
