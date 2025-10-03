const std = @import("std");

const Operator = enum { plus, minus, times, divide, modulo };
const Token = union(enum) {
	literal: isize,
	operator: Operator,
	end,
	paren_open,
	paren_close,
};

reader: *std.Io.Reader,

peaked_token: ?Token = null,

fn next_token(self: *@This()) !Token {
	if (self.peaked_token) |t| {
		self.peaked_token = null;
		return t;
	} else {
		return try self.read_token();
	}
}

fn peek_token(self: *@This()) !Token {
	if (self.peaked_token) |t| {
		return t;
	} else {
		const t = try self.read_token();
		self.peaked_token = t;
		return t;
	}
}

fn read_token(self: @This()) !Token {
	if (self.peaked_token) |t| {
		
		return t;
	}

	const reader = self.reader;
	while (try reader.peekByte() == ' ') reader.toss(1);

	switch (try reader.takeByte()) {
		'\n', '\r' => return .end,
		'('  => return .paren_open,
		')'  => return .paren_close,

		'+' => return .{ .operator = .plus   },
		'-' => return .{ .operator = .minus  },
		'*' => return .{ .operator = .times  },
		'/' => return .{ .operator = .divide },
		'%' => return .{ .operator = .modulo },

		'0',
		'1', '2', '3',
		'4', '5', '6',
		'7', '8', '9' => |c0| {
			var num: isize = c0 - '0';

			while (true) {
				switch (try reader.peekByte()) {
					'0',
					'1', '2', '3',
					'4', '5', '6',
					'7', '8', '9' => |c| {
						num *= 10;
						num += c - '0';
						reader.toss(1);
					},
					else => return .{ .literal = num },
				}
			}
		},
		else => return error.IllegalCharacter,
	}
}

const left_bind_power = std.EnumArray(Operator, usize).init(.{
	.plus   = 1,
	.minus  = 1,
	.times  = 3,
	.divide = 3,
	.modulo = 3,
});

const right_bind_power = std.EnumArray(Operator, usize).init(.{
	.plus   = 2,
	.minus  = 2,
	.times  = 4,
	.divide = 4,
	.modulo = 4,
});

fn pratt(self: *@This(), in_bind_power: usize) !isize {
	var lhs = switch (try self.next_token()) {
		.literal => |v| v,
		.paren_open => blk: {
			const res = try self.pratt(0);
			switch (try self.next_token()) { .paren_close => {}, else => return error.MissingClosingParen }
			break :blk res;
		},
		else => return error.IllegalToken,
	};

	while (true) {
		const operator = switch (try self.peek_token()) {
			.operator => |o| o,
			.end, .paren_close => return lhs,
			else => return error.IllegalToken,
		};

		if (left_bind_power.get(operator) < in_bind_power) return lhs;
		_ = try self.next_token();
		
		const rhs = try self.pratt(right_bind_power.get(operator));

		lhs = switch (operator) {
			.plus   => lhs + rhs,
			.minus  => lhs - rhs,
			.times  => lhs * rhs,
			.divide => @divFloor(lhs, rhs),
			.modulo => @mod(lhs, rhs),
		};
	}
}

pub fn parse(self: *@This()) !isize {
	const res = self.pratt(0);
	switch (try self.next_token()) {
		.end => {},
		else => return error.IllegalToken,
	}
	return res;
}