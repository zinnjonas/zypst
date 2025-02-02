const std = @import("std");
const allocator = std.heap.page_allocator;
const zypst = @import("zypst");

// demo functions analog to: https://github.com/astrale-sharp/wasm-minimal-protocol/blob/master/examples/hello_zig/hello.zig

export fn hello() i32 {
    const message = "Hello from zypst!";
    zypst.send(message);
    return 0;
}

export fn double_it(arg1_len: usize) i32 {
    const parameters = zypst.get_parameters(&.{arg1_len}) catch |err| return zypst.send_error(err);
    defer zypst.deinit_parameters(parameters);
    var result = allocator.alloc(u8, arg1_len * 2) catch |err| return zypst.send_error(err);
    defer allocator.free(result);
    @memcpy(result[0..parameters[0].length], parameters[0].content);
    for (0..arg1_len) |i| {
        result[i + arg1_len] = result[i];
    }
    zypst.send(result);
    return 0;
}

export fn concatenate(arg1_len: usize, arg2_len: usize) i32 {
    const parameters = zypst.get_parameters(&.{ arg1_len, arg2_len }) catch |err| return zypst.send_error(err);
    defer zypst.deinit_parameters(parameters);

    const total: usize = arg1_len + arg2_len + 1;
    var result = allocator.alloc(u8, total) catch |err| return zypst.send_error(err);
    defer allocator.free(result);

    @memcpy(result[0..parameters[0].length], parameters[0].content);
    result[parameters[0].length] = '*';
    @memcpy(result[parameters[0].length + 1 ..], parameters[1].content);

    zypst.send(result);
    return 0;
}

export fn shuffle(arg1_len: usize, arg2_len: usize, arg3_len: usize) i32 {
    const args_len = arg1_len + arg2_len + arg3_len;
    const parameters = zypst.get_parameters(&.{ arg1_len, arg2_len, arg3_len }) catch |err| return zypst.send_error(err);
    defer zypst.deinit_parameters(parameters);

    var result = allocator.alloc(u8, args_len + 2) catch |err| return zypst.send_error(err);
    defer allocator.free(result);

    @memcpy(result[0..parameters[2].length], parameters[2].content);
    result[parameters[2].length] = '-';
    @memcpy(result[parameters[2].length + 1 ..][0..parameters[0].length], parameters[0].content);
    result[parameters[0].length + parameters[2].length + 1] = '-';
    @memcpy(result[parameters[0].length + parameters[2].length + 2 ..], parameters[1].content);

    zypst.send(result);
    return 0;
}

export fn returns_ok() i32 {
    const message = "This is an `Ok`";
    zypst.send(message);
    return 0;
}

export fn returns_err() i32 {
    const messge = "This is an `Err`";
    return zypst.send_error_msg(messge);
}

export fn will_panic() i32 {
    std.debug.panic("Panicking, this mesasge will not be seen...", .{});
}

// demo function from the json example of zig: https://zig.guide/standard-library/json/

const Place = struct { lat: f32, long: f32 };

export fn get_place() i32 {
    const x = Place{
        .lat = 51.997664,
        .long = -0.740687,
    };

    const string = zypst.generate_json(x) catch |err| return zypst.send_error(err);
    zypst.send(string.items);
    return 0;
}

export fn set_place(arg1_len: usize) i32 {
    const parameters = zypst.get_parameters(&.{arg1_len}) catch |err| return zypst.send_error(err);
    defer zypst.deinit_parameters(parameters);

    const parsed = std.json.parseFromSlice(Place, allocator, parameters[0].content, .{}) catch |err| return zypst.send_error(err);
    defer parsed.deinit();

    const place = parsed.value;
    return zypst.send_number(place.lat);
}
