note
	description:
		"DECIMAL numbers. Following the 'General Decimal Arithmetic Specification'."
	copyright: "Copyright (c) SEL, York University, Toronto and others"
	license: "MIT License"
	date: "$Date$"
	revision: "$Revision$"

class DECIMAL

inherit

	NUMERIC
		rename
			plus as binary_plus alias "+",
			minus as binary_minus alias "-",
			quotient as numeric_quotient alias "/"
		redefine
			out,
			is_equal,
			copy,
			default_create
		end

	HASHABLE
		undefine
			out,
			is_equal,
			copy,
			default_create
		end

	COMPARABLE
		undefine
			out,
			is_equal,
			copy,
			default_create
		end

	DCM_MA_SHARED_DECIMAL_CONTEXT
		undefine
			out,
			is_equal,
			copy,
			default_create
		end

	DCM_MA_SHARED_DECIMAL_CONSTANTS
		undefine
			out,
			is_equal,
			copy,
			default_create
		end

	DCM_MA_DECIMAL_CONTEXT_CONSTANTS
		export
			{NONE} all
		undefine
			out,
			is_equal,
			copy,
			default_create
		end

create
	default_create,
	make_from_integer,
	make_from_string,
	make_from_string_ctx,
	make_copy,
	make_zero,
	make_one,
	make

create {DECIMAL}
	make_infinity,
	make_nan,
	make_snan,
	make_special

create {DCM_MA_DECIMAL_TEXT_PARSER}
	make_from_parser

convert
	make_from_string ({STRING}),
	make_from_integer ({INTEGER})

feature {NONE} -- Initialization

	default_create
			-- Initialize a new `zero' decimal instance.
		do
			make_zero
		end

	make (a_precision: INTEGER)
			-- Create a new decimal using `a_precision' digits.
		require
			a_precision_positive: a_precision > 0
		do
			create {DCM_MA_DECIMAL_COEFFICIENT_IMP} coefficient.make (a_precision)
			set_is_negative (False)
			coefficient.put (0, 0)
		ensure
			zero: is_zero
		end

	make_copy (other: like Current)
			-- Make a copy of `other'.
		require
			other_not_void: other /= Void
		do
			if not other.is_special then
				make (other.count)
				copy (other)
			else
				make_special (other.special)
				set_is_negative (other.is_negative)
			end
		ensure
			special_copy: special = other.special
			coefficient_copy: coefficient.is_equal (other.coefficient)
			sign_copy: sign = other.sign
			exponent_copy: exponent = other.exponent
		end

	make_zero
			-- Make zero.
		do
			coefficient := special_coefficient
		ensure
			zero: is_zero
		end

	make_one
			-- Make one.
		do
			make (1)
			coefficient.put (1, 0)
		ensure
			is_one: is_one
			positive: not is_negative
		end

	make_from_integer (a_value: INTEGER)
			-- Make a new decimal from integer `a_value'.
		local
			temp_value, v, index, ten_exponent: INTEGER
		do
				-- Sign handling.
			temp_value := a_value
			set_is_negative (a_value < 0)
			if a_value >= 0 then
				temp_value := -temp_value
			end
			v := temp_value
				-- Calculate size of coefficient.
			from
				ten_exponent := 0
			until
				v = 0
			loop
				v := v // 10
				if v /= 0 then
					ten_exponent := ten_exponent + 1
				end
			end
				-- Create coefficient.
			create {DCM_MA_DECIMAL_COEFFICIENT_IMP} coefficient.make (ten_exponent + 1)
				-- Fill it, from least significant digit (lower index) to most significant (upper index) digit.
			if temp_value = 0 then
				coefficient.put (0, 0)
			else
				from
						-- ten_exponent
					index := 0
					v := temp_value
				until
					v = 0
				loop
					coefficient.put (-(v \\ 10), index)
					v := v // 10
					if v /= 0 then
						index := index + 1
					end
				end
			end
		ensure
			equal_to_value: to_integer = a_value
		end

	make_from_string_ctx (value_string: STRING; ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Make a new decimal from `value_string' relative to `ctx'.
		require
			value_string_not_void: value_string /= Void
			context_not_void: ctx /= Void
		local
			l_parser: like parser
		do
			l_parser := parser
			l_parser.decimal_parse (value_string)
			make_from_parser (l_parser, ctx)
		end

	make_from_parser (a_decimal_parser: DCM_MA_DECIMAL_TEXT_PARSER; a_context: DCM_MA_DECIMAL_CONTEXT)
			-- Make from `a_decimal_parser', relative to `a_context'.
		require
			a_decimal_parser_not_void: a_decimal_parser /= Void
			a_context_not_void: a_context /= Void
		local
			l_last_parsed: detachable STRING
		do
			if a_decimal_parser.error then
				if a_context.is_extended then
					make_nan
				else
					make_snan
				end
			else
				if a_decimal_parser.is_infinity then
					make_infinity (parser.sign)
				elseif a_decimal_parser.is_snan then
					make_snan
				elseif a_decimal_parser.is_nan then
					make_nan
				else
					set_is_negative (a_decimal_parser.sign < 0)
					if a_decimal_parser.has_exponent then
						if a_decimal_parser.exponent_as_double > {INTEGER}.max_value then
							exponent := a_context.Maximum_exponent + a_context.digits + a_decimal_parser.exponent_count + 2
						else
							exponent := a_decimal_parser.exponent_as_double.truncated_to_integer
						end
						if parser.exponent_sign < 0 then
							exponent := -exponent
						end
					else
						exponent := 0
					end
					if a_decimal_parser.has_point then
						exponent := exponent - a_decimal_parser.fractional_part_count
					end
					create {DCM_MA_DECIMAL_COEFFICIENT_IMP} coefficient.make ((a_context.digits + 1).max (a_decimal_parser.coefficient_count))
					l_last_parsed := a_decimal_parser.last_parsed
					check l_last_parsed /= Void end -- implied by `not a_decimal_parser.error'
					coefficient.set_from_substring (l_last_parsed, a_decimal_parser.coefficient_begin, a_decimal_parser.coefficient_end)
					clean_up (a_context)
				end
			end
		end

	make_from_string (value_string: STRING)
			-- Make a new decimal from string `value_string' relative to `shared_decimal_context'.
		require
			value_string_not_void: value_string /= Void
		do
			make_from_string_ctx (value_string, shared_decimal_context)
		end

	make_special (code_special: NATURAL_8)
			-- Make special from code.
		require
			valid_code_special: code_special = Special_infinity or else code_special = Special_quiet_nan
				or else code_special = Special_signaling_nan
		do
			coefficient := special_coefficient
			flags := (flags & special_mask.bit_not) | code_special
			exponent := 0
		ensure
			is_special: is_special
			exponent_zero: exponent = 0
		end

	make_nan
			-- Make quiet 'Not a Number'.
		do
			make_special (Special_quiet_nan)
		ensure
			is_nan: is_quiet_nan
		end

	make_snan
			-- Make Signaling 'Not a Number'.
		do
			make_special (Special_signaling_nan)
		ensure
			is_snan: is_signaling_nan
		end

	make_infinity (a_sign: INTEGER)
			-- Make Infinity.
		require
			a_sign_valid: a_sign = -1 or else a_sign = 1
		do
			make_special (Special_infinity)
			set_is_negative (a_sign < 0)
		ensure
			is_infinity: is_infinity
			sign_set: sign = a_sign
		end

feature -- Access

	sign: INTEGER
			-- Sign: positive = 1; negative = -1
		do
			if is_negative then
				Result := -1
			else
				Result := 1
			end
		ensure
			definition1: Result = -1 implies is_negative
			definition2: Result = 1 implies is_positive
		end

	exponent: INTEGER
			-- Current exponent

	hash_code: INTEGER
			-- Hash code value
		local
			i: INTEGER
			l_exponent, l_coefficient_lsd, l_coefficient_msd: INTEGER
			l_is_zero: BOOLEAN
		do
				-- 'One-at-a-Time Hash' from http://burtleburtle.net/bob/hash/doobs.html.
			l_is_zero := is_zero
			Result := special
			Result := Result + Result |<< 10
			Result := Result.bit_xor (Result |>> 6)
			if not l_is_zero then
				Result := Result + sign
			end
			Result := Result + Result |<< 10
			Result := Result.bit_xor (Result |>> 6)
			if not is_special then
					-- Adjust `l_exponent' and `l_coefficient_lsd'.
				from
					l_coefficient_msd := coefficient.msd_index
					l_coefficient_lsd := coefficient.lower
					l_exponent := exponent
				until
					l_coefficient_lsd > l_coefficient_msd or else coefficient.item (l_coefficient_lsd) /= 0
				loop
					l_coefficient_lsd := l_coefficient_lsd + 1
					l_exponent := l_exponent + 1
				end
					-- Exponent.
				if not l_is_zero then
					Result := Result + l_exponent
				end
				Result := Result + Result |<< 10
				Result := Result.bit_xor (Result |>> 6)
					-- Significant digits of exponent.
				from
					i := l_coefficient_lsd
				until
					i > l_coefficient_msd
				loop
					Result := Result + coefficient.item (i)
					Result := Result + Result |<< 10
					Result := Result.bit_xor (Result |>> 6)
					i := i + 1
				end
			end
			Result := Result + Result |<< 3
			Result := Result.bit_xor (Result |>> 11)
			Result := Result + Result |<< 15
			Result := Result.bit_and ({INTEGER}.max_value)
		end

feature -- Constants

	one: like Current
			-- Neutral element for "*" and "/"
		do
			Result := once_one
		ensure then
			one_is_one: Result.is_one
			one_is_positive: not Result.is_negative
		end

	minus_one: DECIMAL
			-- Minus one
		once
			create Result.make_copy (one)
			Result.set_is_negative (True)
		ensure
			minus_one_not_void: Result /= Void
			is_minus_one: Result.is_one and then Result.is_negative
		end

	zero: like Current
			-- Neutral element for "+" and "-"
		do
			Result := once_zero
		ensure then
			is_zero: Result.is_zero
		end

	negative_zero: DECIMAL
			-- Negative zero
		once
			create Result.make_zero
			Result.set_is_negative (True)
		ensure
			negative_zero_not_void: Result /= Void
			is_zero: Result.is_zero
			is_negative: Result.is_negative
		end

	nan: DECIMAL
			-- Not a Number
		do
			create Result.make_nan
		ensure
			nan_not_void: Result /= Void
			is_nan: Result.is_nan
		end

	snan: DECIMAL
			-- Signaling Not a Number
		do
			create Result.make_snan
		ensure
			snan_not_void: Result /= Void
			is_snan: Result.is_signaling_nan
		end

	infinity: DECIMAL
			-- Infinity
		do
			create Result.make_infinity (1)
		ensure
			infinity_not_void: Result /= Void
			is_infinity: Result.is_infinity
			is_positive: Result.is_positive
		end

	negative_infinity: DECIMAL
			-- Negative infinity
		do
			create Result.make_infinity (-1)
		ensure
			negative_infinity_not_void: Result /= Void
			is_infinity: Result.is_infinity
			is_negative: Result.is_negative
		end

feature {DECIMAL} -- Access

	adjusted_exponent: INTEGER
			-- Exponent of the most significant digit; see SDAS page 5
		do
			Result := exponent + count - 1
		ensure
			definition: Result = (exponent + count - 1)
		end

feature {DECIMAL, DCM_MA_DECIMAL_PARSER, DCM_MA_DECIMAL_HANDLER} -- Access

	coefficient: DCM_MA_DECIMAL_COEFFICIENT
			-- Storage for digits

feature -- Status report

	is_integer: BOOLEAN
			-- Is this an integer?
			-- (i.e no fractional part other than all zeroes)
		local
			fractional_count, index: INTEGER
		do
			if is_zero then
				Result := True
			elseif exponent < 0 then
				if adjusted_exponent >= 0 then
					fractional_count := -exponent
					from
						index := fractional_count.min (count)
					until
						index <= 0 or else coefficient.item (index - 1) /= 0
					loop
						index := index - 1
					variant
						index
					end
					Result := index = 0
				else
					Result := False
				end
			else
				Result := True
			end
		end

	is_double: BOOLEAN
			-- Is this a double?
		local
			str: STRING
		do
			str := to_scientific_string
			Result := str.is_double
		end

	divisible (other: like Current): BOOLEAN
			-- May current object be divided by `other'?
		do
			Result := not other.is_zero
		ensure then
			definition: Result = not other.is_zero
		end

	exponentiable (other: NUMERIC): BOOLEAN
			-- May current object be elevated to the power `other'?
		do
				--| TODO
		end

	is_negative: BOOLEAN
			-- Is the number negative?
		do
			Result := (flags & is_negative_flag) = is_negative_flag
		end

	is_positive: BOOLEAN
			-- Is the number positive?
		do
			Result := not is_negative
		ensure
			definition: Result = not is_negative
		end

	is_nan: BOOLEAN
			-- Is this "Not a Number" (NaN)?
		do
			Result := is_signaling_nan or is_quiet_nan
		ensure
			definition: Result = (is_signaling_nan or is_quiet_nan)
		end

	is_special: BOOLEAN
			-- Is this a special value?
		do
			Result := (special /= Special_none)
		ensure
			definition: Result = (is_nan or else is_infinity)
		end

	is_signaling_nan: BOOLEAN
			-- Is this a "Signaling NaN"?
		do
			Result := (special = Special_signaling_nan)
		end

	is_quiet_nan: BOOLEAN
			-- Is this a "Quiet NaN"?
		do
			Result := (special = Special_quiet_nan)
		end

	is_infinity: BOOLEAN
			-- Is this an Infinity?
		do
			Result := (special = Special_infinity)
		end

	is_zero: BOOLEAN
			-- Is this a Zero value?
		do
			Result := not is_special and then coefficient.is_zero
		ensure
			definition: Result = (not is_special and then coefficient.is_zero)
		end

	is_one: BOOLEAN
			-- Is this a One ?
		do
			Result := not is_special and then exponent = 0 and then coefficient.is_one
		ensure
			definition: Result = (not is_special and then exponent = 0 and then coefficient.is_one)
		end

feature -- Basic operations

	product alias "*" (other: like Current): like Current
			-- Product by `other'
		do
			Result := multiply (other, shared_decimal_context)
		ensure then
			product_not_void: Result /= Void
		end

	identity alias "+": like Current
			-- Unary plus
		do
			Result := plus (shared_decimal_context)
		ensure then
			unary_plus_not_void: Result /= Void
		end

	binary_plus alias "+" (other: like Current): like Current
			-- Sum with `other' (commutative)
		do
			Result := add (other, shared_decimal_context)
		ensure then
			sum_not_void: Result /= Void
		end

	opposite alias "-": like Current
			-- Unary minus
		do
			Result := minus (shared_decimal_context)
		ensure then
			unary_minus_not_void: Result /= Void
		end

	binary_minus alias "-" (other: like Current): like Current
			-- Result of subtracting `other'
		do
			Result := subtract (other, shared_decimal_context)
		ensure then
			subtract_not_void: Result /= Void
		end

	numeric_quotient alias "/" (other: like Current): like Current
			-- Division by `other'
		require else
			exception_trap: not shared_decimal_context.exception_on_trap or else not (other.is_zero)
		do
			Result := divide (other, shared_decimal_context)
		ensure then
			division_not_void: Result /= Void
		end

	integer_remainder alias "\\" (other: like Current): like Current
			-- Remainder of integer division
		do
			Result := remainder (other, shared_decimal_context)
		ensure
			remainder_not_void: Result /= Void
		end

	integer_quotient alias "//" (other: like Current): like Current
			-- Integer division
		do
			Result := divide_integer (other, shared_decimal_context)
		ensure
			integer_division_not_void: Result /= Void
		end


	is_less alias "<" (other: like Current): BOOLEAN
			-- Is current decimal less than `other'?
		local
			res: DECIMAL
		do
			res := compare (other, shared_decimal_context)
			Result := res.is_negative
		end

feature -- epsilon

	epsilon: DCM_EPSILON
			-- Shared Epsilon
		once
			create Result.make
		ensure
			one_not_void: Result /= Void
			is_five: Result.epsilon = 5
		end

	no_digits_after_point: INTEGER
			-- number of digits after decimal point
		local
			count_of_decimal, exponent_of_decimal: INTEGER
		do
			count_of_decimal := count
			exponent_of_decimal := exponent

			if count_of_decimal = 1 and exponent_of_decimal < 0 then
				Result := exponent_of_decimal.abs
			elseif exponent_of_decimal >= 0 then
				Result := 0
			else
				Result := exponent_of_decimal.abs
			end
		end

	approximately_equal_epsilon(d, e: DECIMAL): BOOLEAN
			-- Is `d' approximately equal to `Current' within epsilon `e'?
		require
			e >= e.zero and not e.is_special
		do
				Result := (Current-d).abs <= e
		ensure
			Result = ((Current-d).abs <= e)
		end

	approximately_equal alias "|~" (d: like Current): BOOLEAN
			-- Is `d' approximately equal to `Current'?
			-- Epsilon used to compare is `epsilon'E-no_digits_after_point from DCM_EPSILON class. Use approximately_equal_epsilon feature to
			-- define your own epsilon for comparison.
			-- Epsilon is based on which of `Current' and `d' has the most number of digits after the decimal point
		do
			if is_special or d.is_special then
				Result := False
			elseif  no_digits_after_point >= d.no_digits_after_point then
				Result := approximately_equal_epsilon (d, epsilon.epsilon.out + "E-" + no_digits_after_point.out)
			else
				Result := approximately_equal_epsilon (d, epsilon.epsilon.out + "E-" + d.no_digits_after_point.out)
			end
		ensure
			(is_special or d.is_special) implies
				not Result
			(not (is_special or d.is_special) and no_digits_after_point >= d.no_digits_after_point) implies
				Result = approximately_equal_epsilon (d, epsilon.epsilon.out + "E-" + no_digits_after_point.out)
			(not (is_special or d.is_special) and no_digits_after_point < d.no_digits_after_point) implies
				Result = approximately_equal_epsilon (d, epsilon.epsilon.out + "E-" + d.no_digits_after_point.out)
		end

feature -- Measurement

	count: INTEGER
			-- Count of significant digits
		do
			if is_special then
				Result := 0
			else
				Result := coefficient.count
			end
		ensure
			zero_when_special: is_special implies Result = 0
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Are `Current' and `other' considered equal?
		local
			comparison_result: like Current
		do
			if is_nan and then other.is_nan then
				if is_quiet_nan then
					Result := other.is_quiet_nan
				elseif is_signaling_nan then
					Result := other.is_signaling_nan
				end
			elseif is_infinity and then other.is_infinity then
				Result := (sign = other.sign)
			else
				comparison_result := compare (other, shared_decimal_context)
				Result := comparison_result.is_zero
			end
		end

feature -- Conversion

	out: STRING
			-- Printable representation
		do
			create Result.make (0)
			Result.append_string ("[")
				-- Sign.
			if is_negative then
				Result.append_string ("1")
			else
				Result.append_string ("0")
			end
				-- Coefficient.
			Result.append_string (",")
			if is_infinity then
				Result.append_string ("inf")
			elseif is_signaling_nan then
				Result.append_string ("sNaN")
			elseif is_quiet_nan then
				Result.append_string ("qNaN")
			else
				Result.append_string (coefficient.out)
					-- Exponent.
				Result.append_string (",")
				Result.append_string (exponent.out)
			end
			Result.append_string ("]")
		end

	to_double: DOUBLE
			-- `Current' as a DOUBLE
		require
			is_double: is_double
		local
			str: STRING
		do
			str := to_scientific_string
			Result := str.to_double
		end

	to_integer: INTEGER
			-- `Current' as an INTEGER
		require
			is_integer: is_integer
			large_enough: Current >= decimal.minimum_integer
			small_enough: Current <= decimal.maximum_integer
		local
			ctx: DCM_MA_DECIMAL_CONTEXT
		do
			create ctx.make_double
			Result := to_integer_ctx (ctx)
		end

	to_integer_ctx (ctx: DCM_MA_DECIMAL_CONTEXT): INTEGER
			-- `Current' as an INTEGER wrt `ctx'
		require
			is_integer: is_integer
			large_enough: Current >= decimal.minimum_integer
			small_enough: Current <= decimal.maximum_integer
		local
			temp: like Current
			index: INTEGER
		do
			temp := round_to_integer (ctx)
			from
				index := temp.count - 1
				Result := 0
			until
				index < 0
			loop
				Result := Result * 10 + temp.coefficient.item (index)
				index := index - 1
			variant
				index + 1
			end
			if is_negative then
				Result := -Result
			end
		end

	to_engineering_string: STRING
			-- `Current' as a number in engineering notation
		do
			Result := to_string_general (True)
		ensure
			to_string_not_void: Result /= Void
		end

	to_scientific_string: STRING
			-- `Current' as a sting expressed in scientific notation
		do
			Result := to_string_general (False)
		ensure
			to_string_not_void: Result /= Void
		end

feature -- Duplication

	copy (other: like Current)
			-- Copy `other' to current decimal.
		do
			if other /= Current then
				if other.is_special then
					coefficient := special_coefficient
				elseif coefficient = Void or else is_special then
  					coefficient := other.coefficient.to_twin
  				else
  					coefficient.copy (other.coefficient)
  				end
  				exponent := other.exponent
  				flags := other.flags
			end
		end

feature -- Basic operations

	add (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Add `other' with respect to the `ctx' context
		require
			other_not_void: other /= Void
			ctx_not_void: ctx /= Void
		local
			operand_a, operand_b: like Current
		do
				-- Special values are handled in a special way.
			if is_special or else other.is_special then
				Result := add_special (other, ctx)
			else
					-- Addition of non-special values.
					-- Instantiate "registers" for destructive operations: operand_a and operand_b.
				create operand_a.make (ctx.digits + 1)
				operand_a.copy (Current)
				create operand_b.make (ctx.digits + 1)
				operand_b.copy (other)
					-- Go.
				if is_negative and then other.is_positive then
						-- -a + b = (b-a)
					operand_b.unsigned_subtract (operand_a, ctx)
					Result := operand_b
				elseif is_negative and then other.is_negative then
						-- -a + -b = - (a+b)
					operand_a.unsigned_add (operand_b, ctx)
					Result := operand_a
					Result.set_is_negative (True)
				elseif is_positive and then other.is_negative then
						-- a + -b = (a-b)
					operand_a.unsigned_subtract (operand_b, ctx)
					Result := operand_a
				else
						-- a + b = (a+b)
					operand_a.unsigned_add (operand_b, ctx)
					Result := operand_a
				end
				if Result.is_zero then
					Result.set_is_negative ((is_negative and then other.is_negative) or else (ctx.rounding_mode = Round_floor and then sign /= other.sign))
				end
				Result.clean_up (ctx)
			end
		ensure
			add_not_void: Result /= Void
		end

	subtract (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Subtract `other' with respect to the `ctx' context
		require
			other_not_void: other /= Void
			ctx_not_void: ctx /= Void
		local
			operand_b: like Current
		do
				-- Special values are handled in a special way.
			if is_special or else other.is_special then
				Result := subtract_special (other, ctx)
			else
					-- a + b = a + (-b)
				create operand_b.make_copy (other)
				operand_b.set_is_negative (operand_b.is_positive)
				Result := add (operand_b, ctx)
			end
		ensure
			subtract_not_void: Result /= Void
		end

	multiply (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Multiply `other' with respect to `ctx'
		require
			other_not_void: other /= Void
			ctx_not_void: ctx /= Void
		local
			operand_a, operand_b: like Current
		do
				-- Specials.
			if is_special or else other.is_special then
					-- sNan
				if is_nan or else other.is_nan then
					if is_signaling_nan or else other.is_signaling_nan then
						ctx.signal (Signal_invalid_operation, "sNan in multiply")
					end
					Result := nan
				elseif is_infinity or else other.is_infinity then
					if is_zero or else other.is_zero then
						ctx.signal (Signal_invalid_operation, "0 * Inf")
						Result := nan
					else
						if sign = other.sign then
							Result := infinity
						else
							Result := negative_infinity
						end
					end
				else
					Result := nan
				end
			else
				if is_zero or else other.is_zero then
					create Result.make (ctx.digits)
					Result.set_exponent (exponent + other.exponent)
					Result.set_is_negative (sign /= other.sign)
				else
					operand_a := Current
					operand_b := other
					create Result.make (operand_a.count + operand_b.count + 2)
					Result.coefficient.integer_multiply (operand_a.coefficient, operand_b.coefficient)
					Result.set_exponent (operand_a.exponent + operand_b.exponent)
					Result.set_is_negative (sign /= other.sign)
					Result.clean_up (ctx)
				end
			end
		ensure
			multiply_not_void: Result /= Void
		end

	divide (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Divide `Current' by `other' whith respect to `ctx'
		require
			other_not_void: other /= Void
			ctx_not_void: ctx /= Void
			exception_trap: not ctx.exception_on_trap or else not (other.is_zero)
		do
				-- a E m / b E n = a/b E m-n
			Result := do_divide (other, ctx, division_standard)
		ensure
			divide_not_void: Result /= Void
		end

	divide_integer (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Integer division of `Current' by `other' whith respect to `ctx'
		require
			other_not_void: other /= Void
			ctx_not_void: ctx /= Void
		do
			Result := do_divide (other, ctx, division_integer)
		ensure
			divide_integer_not_void: Result /= Void
		end

	sqrt: like Current
			-- Perform sqrt on `Current' using shared_decimal_context
		do
			Result := sqrt_with_ctx (shared_decimal_context)
		ensure
			result_not_void: Result /= Void
		end


	sqrt_with_ctx (ctx: DCM_MA_DECIMAL_CONTEXT): like Current
		--Square root of the `Current'

		require
			greater_than_equal_zero: not ctx.exception_on_trap or else is_greater_equal ("0")
		local
			two, x, y, e, m, m_prev: DECIMAL
			exp_local, i, factor: INTEGER
		do
			if is_zero then
				create Result.make_from_string_ctx ("0", ctx)
			elseif is_less ("0") or is_nan or is_signaling_nan then
				create Result.make_from_string_ctx ("NaN", ctx)
			elseif is_infinity and is_positive then
				Result := "Infinity"
			else
				create e.make_nan
				create two.make_from_string_ctx ("2", ctx)

				x := multiply (two, ctx)
				y := x.multiply (x, ctx)
				y := y.add (Current, ctx)
				y := y.divide (x.multiply (two, ctx), ctx)

				create e.make_from_string_ctx ("1", ctx)

				if exponent.abs > ctx.precision then
					factor := (exponent.abs / ctx.precision).ceiling
					exp_local := -1 * (ctx.precision * factor)
				else
					exp_local := -1 * (ctx.precision)
				end


				e.set_exponent (exp_local)
				from --Using newton's approximation method.
					m := x.subtract (y, ctx).abs
					i := 0
					create m_prev.make_copy (m)
				until
					m.is_less_equal (e) or i = 5
				loop
					x := y
					y := x.multiply (x, ctx)
					y := y.add (Current, ctx)
					y := y.divide (x.multiply (two, ctx), ctx)
					m := x.subtract (y, ctx).abs

					if m_prev.is_equal (m) then -- Added a break from loop in case the value converges to one number and never changes.
						i := i + 1
					else
						m_prev := m
						i := 0
					end
				end
				Result := y
			end
	end

	get_coeff (ctx: DCM_MA_DECIMAL_CONTEXT): like Current
		require
			ctx_not_void: ctx /= Void
		local
			index: INTEGER
			num, ten, c: DECIMAL
		do
			from
				index := coefficient.count - 1
				create c.make_from_string_ctx ("0", ctx)
				create ten.make_from_string_ctx ("10", ctx)
				create num.make_nan
			until
				index < 0
			loop
				c := c.multiply (ten, ctx)
				create num.make_from_string_ctx (coefficient.item (index).out, ctx)
				c := c.add (num, ctx)
				index := index - 1
			end
			c.set_exponent (exponent)
			Result := c
		end

	remainder (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Remainder of integer division of `Current' by `other' whith respect to `ctx'
		require
			other_not_void: other /= Void
			ctx_not_void: ctx /= Void
		do
			if is_special or else other.is_special then
					-- sNan
				if is_nan or else other.is_nan then
					if is_signaling_nan or else other.is_signaling_nan then
						ctx.signal (Signal_invalid_operation, "sNan in remainder")
					end
					Result := nan
				elseif is_infinity then
					ctx.signal (Signal_invalid_operation, "[+-] Inf dividend in remainder")
					Result := nan
				elseif other.is_infinity then
					create Result.make_copy (Current)
					Result.set_is_negative (is_negative)
				else
					Result := nan
				end
			else
				if other.is_zero then
					ctx.signal (Signal_invalid_operation, "Zero divisor in remainder")
					Result := nan
				elseif is_zero then
					create Result.make_zero
					if exponent < 0 then
						Result.set_exponent (exponent)
					else
						Result.set_exponent (0)
					end
					Result.set_is_negative (is_negative)
				else
					Result := internal_divide (other, ctx, division_remainder)
					Result.set_is_negative (is_negative)
					Result.clean_up (ctx)
				end
			end
		ensure
			remainder_not_void: Result /= Void
		end

	rescale (new_exponent: INTEGER; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Decimal from `Current' rescaled to `new_exponent'
		require
			ctx_not_void: ctx /= Void
		local
			shared_digits, digits_upto_new_exponent, exponent_delta: INTEGER
			saved_exponent_limit, result_count: INTEGER
		do
			if not (new_exponent <= ctx.exponent_limit and then new_exponent >= ctx.e_tiny) then
				ctx.signal (Signal_invalid_operation, "new exponent is not within limits [Etiny..Emax]")
				Result := nan
			else
					-- Rescale to new_exponent.
				if is_special then
					create Result.make_copy (Current)
					Result.do_rescale_special (ctx)
				elseif exponent < new_exponent then
						-- Same as underflowing to e_tiny where e_tiny = new_exponent.
					if not is_zero then
						shared_digits := adjusted_exponent - new_exponent + 1
						if shared_digits < 0 then
								-- Impossible to share any digit with new_exponent.
							result_count := ctx.digits + count + 1
						elseif shared_digits = 0 then
								-- msd at new_exponent - 1. See if rounding shall carry some new_exponent digit.
							result_count := ctx.digits + count
						else
								-- shared_digits > 0 (and shared_digits <= ctx.digits).
							result_count := ctx.digits + (count - shared_digits)
						end
						create Result.make (result_count)
						Result.copy (Current)
						Result.coefficient.set_count (result_count)
						Result.round (ctx)
						Result.strip_leading_zeroes
						if Result.is_underflow (ctx) then
							Result.do_underflow (ctx)
						end
						if ctx.is_flagged (Signal_subnormal) and then ctx.is_flagged (Signal_inexact) then
							ctx.signal (Signal_underflow, "Underflow when rescaling")
						end
						if Result.is_overflow (ctx) then
							Result.do_overflow (ctx)
						end
						if exponent > new_exponent then
							Result.shift_left (exponent - new_exponent)
						end
					else
						create Result.make_copy (Current)
					end
					Result.set_exponent (new_exponent)
				elseif exponent > new_exponent then
					if not is_zero then
						digits_upto_new_exponent := adjusted_exponent - new_exponent + 1
						if digits_upto_new_exponent > ctx.digits then
								-- There should be an overflow.
							create Result.make (count + 1)
							Result.copy (Current)
							Result.shift_left (1)
							saved_exponent_limit := ctx.exponent_limit
								-- Make sure overflow can be called.
							ctx.set_exponent_limit (count - 1)
--							Result.set_exponent (adjusted_exponent.abs - 1)
							Result.set_exponent (1)
							Result.do_overflow (ctx)
							if not Result.is_special then
								Result.set_exponent (new_exponent)
							end
							ctx.set_exponent_limit (saved_exponent_limit)
						else
							exponent_delta := exponent - new_exponent
							create Result.make (count + exponent_delta)
							Result.copy (Current)
							Result.shift_left (exponent_delta)
						end
					else
							-- is_zero
						if new_exponent < 0 and then exponent < 0 and then count > 1 then
								-- "decimal places" have some importance
							digits_upto_new_exponent := -new_exponent + 1
						else
							digits_upto_new_exponent := 1
						end
						if digits_upto_new_exponent > ctx.digits then
								-- There should be an overflow.
							create Result.make (count + 1)
							Result.copy (Current)
							Result.shift_left (1)
							saved_exponent_limit := ctx.exponent_limit
							ctx.set_exponent_limit (Result.adjusted_exponent - 1)
							Result.do_overflow (ctx)
							ctx.set_exponent_limit (saved_exponent_limit)
						else
								-- No overflow.
							if digits_upto_new_exponent > 1 then
									-- By definition exponent < 0 and count > 1.
								exponent_delta := exponent - new_exponent
								create Result.make (count + exponent_delta)
								Result.copy (Current)
								Result.shift_left (exponent_delta)
							else
								create Result.make_copy (Current)
							end
							Result.set_exponent (new_exponent)
						end
					end
					Result.clean_up (ctx)
				else
						-- new_exponent = exponent
						-- Still detect conditions.
					create Result.make_copy (Current)
					Result.clean_up (ctx)
				end
			end
		ensure
			rescale_not_void: Result /= Void
		end

	rescale_decimal (new_exponent: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Rescale using decimal `new_exponent'
		require
			new_exponent_not_void: new_exponent /= Void
			ctx_not_void: ctx /= Void
		local
			e_max, e_min: DECIMAL
			new_integer_exponent: INTEGER
			temp_ctx: DCM_MA_DECIMAL_CONTEXT
		do
			if new_exponent.is_special or else is_special then
				if new_exponent.is_signaling_nan or else is_signaling_nan then
					ctx.signal (Signal_invalid_operation, "sNaN as new exponent in 'rescale_decimal'")
					Result := nan
				elseif new_exponent.is_quiet_nan then
					Result := nan
				elseif new_exponent.is_infinity then
					ctx.signal (Signal_invalid_operation, "Inf as new exponent in 'rescale_decimal'")
					Result := nan
				else
					create Result.make_copy (Current)
					Result.do_rescale_special (ctx)
				end
			else
				create e_max.make_from_integer (ctx.exponent_limit)
				create e_min.make_from_integer (ctx.e_tiny)
				if new_exponent <= e_max and then new_exponent >= e_min then
					create temp_ctx.make_double
					if new_exponent.is_integer then
						new_integer_exponent := new_exponent.to_integer_ctx (temp_ctx)
						if new_integer_exponent <= ctx.exponent_limit and then new_integer_exponent >= ctx.e_tiny then
							Result := rescale (new_integer_exponent, ctx)
						else
							ctx.signal (Signal_invalid_operation, "new exponent is not within limits [Etiny..Emax]")
							Result := nan
						end
					else
						ctx.signal (Signal_invalid_operation, "new exponent has fractional part in 'rescale_decimal'")
						Result := nan
					end
				else
					ctx.signal (Signal_invalid_operation, "new exponent if not within limits [Etiny..Emax]")
					Result := nan
				end
			end
		ensure
			rescale_decimal_not_void: Result /= Void
		end

	round_to_integer (ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Round to an integer with exponent 0
		require
			ctx_not_void: ctx /= Void
		do
			Result := rescale (0, ctx)
		ensure
			round_to_integer_not_void: Result /= Void
			definition: not Result.is_special implies Result.exponent = 0
		end

	plus (ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Prefix "+" with respect to the `ctx' context
		require
			ctx_not_void: ctx /= Void
		local
			l_zero: like Current
		do
			create l_zero.make (ctx.digits + 1)
			l_zero.set_exponent (exponent)
			Result := l_zero.add (Current, ctx)
		ensure
			plus_not_void: Result /= Void
		end

	normalize: like Current
			-- Normalized version of current decimal
		local
			l_count, trailing_zeroes: INTEGER
		do
			Result := plus (shared_decimal_context)
			if Result.is_zero then
				Result.coefficient.keep_head (1)
				Result.set_exponent (0)
			elseif not Result.is_special then
				from
					trailing_zeroes := 0
					l_count := Result.count
				until
					trailing_zeroes >= count or else Result.coefficient.item (trailing_zeroes) /= 0
				loop
					trailing_zeroes := trailing_zeroes + 1
				end
				if trailing_zeroes > 0 then
					Result.shift_right (trailing_zeroes)
					Result.coefficient.keep_head (Result.coefficient.msd_index + 1)
				end
			end
			Result.set_is_negative (is_negative)
		ensure
			normalize_not_void: Result /= Void
		end

	minus (ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Prefix "-" with respect to the `ctx' context
		require
			ctx_not_void: ctx /= Void
		local
			l_zero: like Current
		do
			create l_zero.make (ctx.digits + 1)
			l_zero.set_exponent (exponent)
			Result := l_zero.subtract (Current, ctx)
		ensure
			minus_not_void: Result /= Void
		end

	abs: like Current
			-- Absolute value of `Current'
		do
			Result := abs_ctx (shared_decimal_context)
		ensure
			abs_not_void: Result /= Void
		end

	abs_ctx (ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Absolute value of `Current' relative to `ctx'
		require
			ctx_not_void: ctx /= Void
		do
			if is_negative then
				Result := minus (ctx)
			else
				Result := plus (ctx)
			end
		ensure
			abs_ctx_not_void: Result /= Void
			definition: Result.sign >= 0
		end

	max_ctx (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Max between `Current' and `other' relative to `ctx'
		require
			other_not_void: other /= Void
			ctx_not_void: ctx /= Void
		local
			comparison_result: DECIMAL
		do
			if is_nan or else other.is_nan then
				if is_signaling_nan or else other.is_signaling_nan then
					ctx.signal (Signal_invalid_operation, "sNan in max")
				end
				Result := nan
			else
				comparison_result := compare (other, ctx)
				if comparison_result.is_negative then
					Result := other
				else
					Result := Current
				end
				Result.clean_up (ctx)
			end
		ensure
			max_ctx_not_void: Result /= Void
		end

	min_ctx (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Min between `Current' and `other' relative to `ctx'
		require
			other_not_void: other /= Void
			ctx_not_void: ctx /= Void
		local
			comparison_result: DECIMAL
		do
			if is_nan or else other.is_nan then
				if is_signaling_nan or else other.is_signaling_nan then
					ctx.signal (Signal_invalid_operation, "sNan in max")
				end
				Result := nan
			else
				comparison_result := compare (other, ctx)
				if comparison_result.is_negative or comparison_result.is_zero then
					Result := Current
				else
					Result := other
				end
				Result.clean_up (ctx)
			end
		ensure
			min_ctx_not_void: Result /= Void
		end

	compare (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Compare value of `Current' and `other';
			-- Result = 0 if Current = other,
			-- Result = -1 if Current < other,
			-- Result = +1 if Current > other.
		require
			other_not_void: other /= Void
			ctx_not_void: ctx /= Void
		local
			operand_a, operand_b: like Current
			temp_ctx: DCM_MA_DECIMAL_CONTEXT
		do
			if is_special or else other.is_special then
				if is_nan or else other.is_nan then
					Result := nan
					if is_signaling_nan or else other.is_signaling_nan then
						ctx.signal (Signal_invalid_operation, "sNaN in 'compare'")
					end
				elseif is_infinity then
					if other.is_infinity and then is_negative = other.is_negative then
							-- compare (Inf,Inf) or compare (-Inf,-Inf)
						Result := zero
					elseif is_negative then
							-- compare (-Inf, x) : -Inf < x
						Result := minus_one
					else
						Result := one
					end
				elseif other.is_infinity then
					if is_infinity and then is_negative = other.is_negative then
							-- compare (Inf,Inf) or compare (-Inf,-Inf)
						Result := zero
					elseif other.is_negative then
							-- compare ( x, -Inf) : x > -Inf
						Result := one
					else
							-- compare (x, +inf) : x < Inf
						Result := minus_one
					end
				else
					Result := nan
				end
			else
				create operand_a.make_copy (Current)
				create operand_b.make_copy (other)
					-- Avoid over/underflow during comparison.
				if is_negative /= other.is_negative then
						-- Signs are different.
					if is_zero then
						create operand_a.make_zero
					else
						create operand_a.make_one
						operand_a.set_is_negative (is_negative)
					end
					if other.is_zero then
						create operand_b.make_zero
					else
						create operand_b.make_one
						operand_b.set_is_negative (other.is_negative)
					end
				end
				temp_ctx := ctx.twin
				temp_ctx.reset_flags
				Result := operand_a.subtract (operand_b, temp_ctx)
				if Result.is_zero and then not temp_ctx.is_flagged (Signal_subnormal) then
						-- Avoid considering equal, numbers whose difference is an epsilon.
					Result := zero
				else
					if Result.is_negative then
						Result := minus_one
					else
						Result := one
					end
				end
			end
		ensure
			compare_not_void: Result /= Void
		end

feature {DECIMAL,ES_TEST} -- Log, Root and Power and their helper functions

--	exp_lower_bound: like Current
--	-- Rounded down value of a number at its last significant digit.

--	local
--		d1: DECIMAL
--	do
--		d1 := current.coefficient.item (0)
--		if d1.is_less ("5") then
--		d1.set_exponent (current.no_digits_after_point * -1)
--		Result := current - d1
--	else
--		Result := current
--	end

--	end

	exp_lower_bound: like Current
    -- Rounded down value of a number at its last significant digit.

    local
        d1: DECIMAL
    do
        d1 := current.coefficient.item (0)
        d1.set_exponent (current.no_digits_after_point * -1)
        Result := current - d1
    end



--	exp_upper_bound: like Current
--    -- Rounded up value of a number at its last significant digit.
--	local
--		d1: DECIMAL
--	do
--		d1 := current.coefficient.item (0)
--		if d1.is_greater_equal ("5") then
--		d1 := "10" - d1
--		d1.set_exponent (current.no_digits_after_point * -1)
--		Result := current + d1
--	else
--		Result := current
--	end

--	end


    exp_upper_bound: like Current
    -- Rounded up value of a number at its last significant digit.
    local
        d1: DECIMAL
    do
        d1 := current.coefficient.item (0)
        d1 := "10" - d1
        d1.set_exponent (current.no_digits_after_point * -1)
        Result := current + d1
    end



	exp: like Current
		-- Perform e^`Current' using shared_default_context

		require
			current_not_void: Current /= Void
		do
			Result := exp_wrt_ctx (shared_decimal_context)
		ensure
			exp_not_void: Result /= Void
		end

	exp_wrt_ctx (ctx: DCM_MA_DECIMAL_CONTEXT): like Current
--		 Perform e^`Current' using ctx as context
--       Implemented using the "Variable Precision Exponential Function" algorithm by T.E Hull.
--       Result differs from "MPCalcRB" source by two or three significant digits when evaluating large numbers.
--       Higher precision does not negatively impact accuracy of final result, but lower precision causes rounding errors.
		require
			current_not_void: current /= Void
			context_not_void: ctx /= Void
		local
			t_val: INTEGER
			neg: BOOLEAN
			x, half_sum, i, sum, n, pbyr_exp, step2, step1, denom, f, pbyr, numer, prec, p, r, t, k, rval, base, Forty: DECIMAL
			ctx_local: DCM_MA_DECIMAL_CONTEXT
			q: DCM_PRECOMPUTED_VALUES
		do
			create q.make
			if is_zero then
				create Result.make_from_string_ctx ("2", ctx)
			elseif is_one and sign = 1 then
				create Result.make_from_string_ctx (q.natural_e, ctx)
			elseif is_one and sign = -1 then
				Result := one.divide (q.natural_e, ctx)
			else
				create ctx_local.make_default
				ctx_local.copy (ctx)
				ctx_local.set_rounding_mode (6)

				if is_negative then
					create x.make_copy (current)
					x := x.multiply ("-1", ctx_local)
					neg := True
				else
					neg := False
					create x.make_copy (current)
				end

				create prec.make_from_string_ctx (ctx_local.digits.out, ctx_local)

				t_val := (x.count - x.no_digits_after_point - 1)
				if t_val <= 0 then
					create t.make_from_string_ctx ("1", ctx_local)
				else
					create t.make_from_string_ctx (t_val.out, ctx_local)
				end

				if x.is_less_equal ("40") then

					t_val := x.exponent

					if t_val <= 0 then
					create t.make_from_string_ctx ("0", ctx_local)
					else
					create t.make_from_string_ctx (t_val.out, ctx_local)
					end

					create t.make_from_string_ctx ("1", ctx_local)

					create k.make_from_string_ctx ("10", ctx_local)

					k := k.power_wrt_ctx (t, ctx_local)
					r := x.divide (k, ctx_local)
					p := prec.add (t, ctx_local)
					p := p.add ("2", ctx_local)

					if p.is_less_equal ("4") then

					create p.make_from_string_ctx ("4", ctx_local)
					end

					create numer.make_from_string_ctx ("1.435", ctx_local)
					numer := numer.multiply (p, ctx_local)
					numer := numer.subtract ("1.182", ctx_local)
					pbyr := p.divide (r.abs, ctx_local) --Lower bound
					pbyr := pbyr.exp_lower_bound

					pbyr.set_exponent (0)
					create f.make_copy (pbyr)

					create step1.make_from_string_ctx ("1.558", ctx_local)
					step1 := step1.multiply (f, ctx_local) --Round down
					step1 := step1.exp_lower_bound
					step1 := step1.add ("0.7441", ctx_local) --Round down
					step1 := step1.exp_lower_bound

					create step2.make_from_string_ctx ("1", ctx_local)
					step2 := step2.subtract (f, ctx_local)
					step2 := step2.divide (step1, ctx_local) --Round up
					step2 := step2.exp_upper_bound

					create pbyr_exp.make_from_string_ctx (pbyr.exponent.out, ctx_local)
					denom := pbyr_exp.subtract (step2, ctx_local)
					denom := denom.exp_lower_bound --Round down
					n := numer.divide (denom, ctx_local)
					n := n.exp_upper_bound
					n := n.ceiling_wrt_ctx (ctx_local) --Round up
					from
						create sum.make_from_string_ctx ("1", ctx_local)
						create i.make_copy (n)
					until
						i.is_zero
					loop
						half_sum := r.divide (i, ctx_local)
						sum := sum.multiply (half_sum, ctx_local)
						sum := sum.add ("1", ctx_local)

						if i.sign = -1 then
							i := i.add ("1", ctx_local)
						else
							i := i.subtract ("1", ctx_local)
						end
					end
					sum := sum.power_wrt_ctx (k, ctx_local)
					if neg then
						create Result.make_from_string_ctx ("1", ctx_local)
						Result := Result.divide (sum, ctx_local)
					else
						Result := sum
					end

				else
					create Forty.make_from_string_ctx ("40", ctx_local)
					create rval.make_from_string_ctx ("0", ctx_local)
					rval := x.subtract (Forty, ctx)
					base:= q.e40
				    create Result.make_from_string_ctx("1", ctx_local)
					Result := base.multiply(rval.exp, ctx_local)
                end
			end
		ensure
			exp_not_void: Result /= Void
		end


--   exp_wrt_ctx (ctx: DCM_MA_DECIMAL_CONTEXT): like Current
-- --        Perform e^`Current' using ctx as context
-- --       Using "Table Driven Implementation of the Exponential Function" by Ping Tak Peter Tang.

--        require
--            current_not_void: Current /= Void
--            context_not_void: ctx /= Void
--        local

--            lead_array : ARRAY[INTEGER_64]
--            trail_array : ARRAY[INTEGER_64]
--            neg: BOOLEAN
--            J: INTEGER
--            A1, A2, A3, A4, A5, N, Ntemp, negN, N1, N2, Inv_L, part2, temp1, temp2, temp3, two, twom, logtwo, Thirty2, P, R, R1, R2, L1, L2, x, M, S: DECIMAL
--            ctx_local: DCM_MA_DECIMAL_CONTEXT
--            q: DCM_PRECOMPUTED_VALUES
--        do
--           create q.make
--            if is_zero then
--                create Result.make_from_string_ctx ("1", ctx)
--            elseif is_one and sign = 1 then
--                create Result.make_from_string_ctx (q.natural_e, ctx)
--            elseif is_one and sign = -1 then
--                Result := one.divide (q.natural_e, ctx)
--            else
--                create ctx_local.make_default
--                ctx_local.copy (ctx)
--                ctx_local.set_rounding_mode (6)

--                if is_negative then
--                    create x.make_copy (current)
--                    x := x.multiply ("-1", ctx_local)
--                    neg := True
--                else
--                    neg := False
--                    create x.make_copy (current)
--                end
--               -- Step 1: Check all special cases.
--                if is_nan then
--                	create Result.make_from_string_ctx ("NaN", ctx_local)
--                elseif is_infinity and sign = -1 then
--                    create Result.make_from_string_ctx ("0", ctx_local)
--                elseif is_infinity and sign = 1 then
--                    create result.make_infinity (1)
--                elseif x.is_greater (q.Threshold_1) then
--                   	create result.make_infinity (1)
--                elseif x.is_less (q.Threshold_2) then
--                	Result := x.add ("1", ctx_local)
--                else

--               		-- Step 2: argument reduction.
--                	create two.make_from_string_ctx ("2", ctx_local)
--                	create Thirty2.make_from_string_ctx ("32", ctx_local)
--                	logtwo := two.log10_wrt_ctx (ctx)
--                	Inv_L := Thirty2.divide (logtwo, ctx_Local)
--                	N:= x.multiply(Inv_L, ctx_local)
--                	N := N.round_to_integer (ctx_local)
--                	--Mod Opperation
--                	Ntemp := N.divide (Thirty2, ctx_local)
--					Ntemp := Ntemp.floor_wrt_ctx (ctx)
--                	Ntemp := Ntemp.multiply (Thirty2,ctx_local)
--                	N2 := N.subtract (Ntemp, ctx_local)
--                	N1 := N.subtract (N2, ctx_local)
--                 	-- Finding the value of R1 and R2.
--              	 	create L1.make_from_string_ctx ("4581900536175919000", ctx_local)
--               		create L2.make_from_string_ctx ("4432795332353620000", ctx_local)
--               		temp1 := x.subtract (N1, ctx_local)
--               		temp1 := temp1.multiply (L1, ctx_local)
--               		temp2 := N2.multiply (L1, ctx_local)
--                	if
--                    	N.abs.is_greater_equal ("512")
--                	then
--                    	 R1 := temp1.subtract (temp2, ctx_local)
--                	else
--                    	temp3 := N.multiply (L1, ctx_local)
--                    	R1 := x.subtract (temp3, ctx_local)
--                	end
--                	negN := N.multiply ("-1", ctx_local)
--                	R2 := negN.multiply (L2, ctx_local)
--                	-- Decompose N into M and J.
--                	M := N1.divide (Thirty2, ctx_local)
--                	J:= N2                	-- Step 3: Polynomial computation
--                	R := R1.add (R2, ctx_local)
--				  	create A1.make_from_string_ctx ("4602678819172647000", ctx_local)
--				  	create A2.make_from_string_ctx ("4595172819793645600", ctx_local)
--				  	create A3.make_from_string_ctx ("4586165620538892000", ctx_local)
--				  	create A4.make_from_string_ctx ("4575957481358528500", ctx_local)
--				  	create A5.make_from_string_ctx ("4564047970130172000", ctx_local)
--				  	p := R.add (A1.multiply(R.power (2), ctx_local), ctx_local)
--				  	p := p.add (A2.multiply(R.power (3), ctx_local), ctx_local)
--				  	p := p.add (A3.multiply(R.power (4), ctx_local), ctx_local)
--				  	p := p.add (A4.multiply(R.power (5), ctx_local), ctx_local)
--				  	p := p.add (A5.multiply(R.power (6), ctx_local), ctx_local)
--					--Step 4: Reconstruction Step.
--					--Store Values for Leading numbers in array.
--					-- Hex Values need to be recomputed after this step since the provided values do not
--                	-- produce the correct result.
--				  	create lead_array.make_filled(0, 0, 31)
--				  	lead_array.put(4607182418800017400,0)
--				  	lead_array.put(4607281034790536700,1)
--				  	lead_array.put(4607381810190059500,2)
--				  	lead_array.put(4607484792283487000,3)
--				  	lead_array.put(4607590029391123000,4)
--				  	lead_array.put(4607697570891348500,5)
--				  	lead_array.put(4607807467243791000,6)
--				  	lead_array.put(4607919770012999000,7)
--				  	lead_array.put(4608034531892640000,8)
--				  	lead_array.put(4608151806730217500,9)
--				  	lead_array.put(4608271649552348000,10)
--				  	lead_array.put(4608394116590569500,11)
--				  	lead_array.put(4608519265307732500,12)
--				  	lead_array.put(4608647154424959000,13)
--				  	lead_array.put(4608777843949196300,14)
--				  	lead_array.put(4608911395201373700,15)
--				  	lead_array.put(4609047870845172700,16)
--				  	lead_array.put(4609187334916432000,17)
--				  	lead_array.put(4609329852853190700,18)
--				  	lead_array.put(4609475491526397400,19)
--				  	lead_array.put(4609624319271280600,20)
--				  	lead_array.put(4609776405919417300,21)
--				  	lead_array.put(4609931822831497000,22)
--				  	lead_array.put(4610090642930803700,23)
--				  	lead_array.put(4610252940737434600,24)
--				  	lead_array.put(4610418792403263000,25)
--				  	lead_array.put(4610588275747672600,26)
--				  	lead_array.put(4610761470294069000,27)
--				  	lead_array.put(4610938457307194400,28)
--				  	lead_array.put(4611119319831256000,29)
--				  	lead_array.put(4611304142728892400,30)
--				  	lead_array.put(4611493012720993300,31)
--				  	--Store Values for trailing values in array.
--				  	create trail_array.make_filled (0, 0, 31)
--				  	trail_array.put(0,0)
--				  	trail_array.put(4398360369641583600,1)
--				  	trail_array.put(4390663502895179000,2)
--				  	trail_array.put(4391190969116716500,3)
--				  	trail_array.put(4399293837223536600,4)
--				  	trail_array.put(4396986594175829000,5)
--				  	trail_array.put(4398947427695824400,6)
--				  	trail_array.put(4395678244271009300,7)
--				  	trail_array.put(4392467489609770000,8)
--				  	trail_array.put(4387999348500588500,9)
--				  	trail_array.put(4395824235047678000,10)
--				  	trail_array.put(4397344514665107000,11)
--				  	trail_array.put(4396514486804543000,12)
--				  	trail_array.put(4376919018230634500,13)
--				  	trail_array.put(4396828684267982000,14)
--				  	trail_array.put(4382785031611610000,15)
--				  	trail_array.put(4389075691822542000,16)
--				  	trail_array.put(4398308820736637000,17)
--				  	trail_array.put(4385203477640371000,18)
--				  	trail_array.put(4391725210595732500,19)
--				  	trail_array.put(4394206637558733300,20)
--				  	trail_array.put(4396210498721256000,21)
--				  	trail_array.put(4391040956773724700,22)
--				  	trail_array.put(4394540453141269000,23)
--				  	trail_array.put(4397394791062093000,24)
--				  	trail_array.put(4385286261012081700,25)
--				  	trail_array.put(4394424860648055000,26)
--				  	trail_array.put(4396791426733110300,27)
--				  	trail_array.put(4385546610465757700,28)
--				  	trail_array.put(4395154146089737700,29)
--				  	trail_array.put(4393689762643415000,30)
--				  	trail_array.put(4366754277802680300,31)
--				  	S := lead_array.item(J) + trail_array.item(J)
--                  twom := two.nth_root (Thirty2)
--                  twom := twom.multiply (twom.power (N1), ctx_local)
--                  part2 := p.multiply (S, ctx_local)
--                  part2 := part2.add (trail_array.item(J), ctx_local)
--                  part2 := part2.add (lead_array.item (J), ctx_local)
--                  Result := twom.multiply (part2, ctx_local)
--				end
--		   end
--		   ensure
--			     exp_not_void: Result /= Void
--			end

	nth_root (other: like Current): like Current
			-- Perform root of `Current' by `other' as root using shared_default_context
		do
			Result := nth_root_wrt_ctx (other, shared_decimal_context)
		ensure
			nth_root_not_void: Result /= Void
		end

	nth_root_wrt_ctx (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Perform root of `Current' by `other' as root using ctx as context
			-- Off by 3 ULP for very large numbers.
		require
			invalid_op: not ctx.exception_on_trap or else (other.is_greater_equal ("0") and is_greater_equal ("0") and other.is_integer)
		local
			m, prec, x_prev, x, x1: DECIMAL
		do
			if other.is_less ("0") or is_less("0") then
				create Result.make_from_string_ctx ("NaN", ctx)
			elseif other.is_zero and is_zero then
				create Result.make_from_string_ctx ("0", ctx)
			elseif other.is_zero and not is_zero then
				create Result.make_from_string_ctx ("Infinity", ctx)
			elseif not other.is_zero and is_zero then
				create Result.make_from_string_ctx ("0", ctx)
			elseif is_special or other.is_special then -- Not sure if this condition is correct
				Result := "NaN"
			else
				create x_prev.make_copy (Current)
				x := x_prev.divide (other.multiply (other, ctx), ctx) --Initial guess

				from --Compute using newton's method
					create prec.make_from_string_ctx ("1", ctx)
					prec.set_exponent ((ctx.digits - 2) * -1) --Set precision to context digits - 2. This resolves the issue of infinite loop.
				until
					x.subtract (x_prev, ctx).abs.is_less (prec)
				loop
					create x_prev.make_copy (x)
					create x1.make_copy (x)
					x := other.subtract ("1", ctx).multiply (x1, ctx)
					m := divide (x1.power_wrt_ctx (other.subtract ("1", ctx), ctx), ctx)
					x := x.add (m, ctx)
					x := x.divide (other, ctx)
				end
				Result := x
			end
		ensure
			nth_root_not_void: Result /= Void
		end

	power alias "^" (other: like Current): DECIMAL
			-- Current decimal to the power `other'
		do
			Result := power_wrt_ctx (other, shared_decimal_context)
		ensure
			power_not_void: Result /= Void
		end

	power_wrt_ctx (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
		-- Perform x^y of real numbers
		-- Inaccuracy of exp_wrt_ctx causes a propagating rounding error in power_wrt_ctx

		require
			current_not_void: Current /= Void
			other_not_void: other /= Void
			context_not_void: ctx /= Void
			curr_not_negative_if_exp_pos: not ctx.exception_on_trap or else not (other.is_double and is_double and is_negative)
		local
			computed_power: DECIMAL
			q: DCM_PRECOMPUTED_VALUES
		do
			create q.make

			if (is_nan or other.is_nan) then
				create Result.make_from_string_ctx ("NaN", ctx)
			elseif (is_signaling_nan or other.is_signaling_nan) then
				create Result.make_snan
			elseif (is_zero and other.is_zero) then
				create Result.make_from_string_ctx ("NaN", ctx)
			elseif (is_zero and other.is_infinity and other.sign = 1) then
				create Result.make_from_string_ctx ("0", ctx)
			elseif (is_zero and other.sign = -1) then
				create Result.make_from_string_ctx ("Infinity", ctx)
			elseif ((sign = -1 and (other.is_infinity or other.is_nan))) then
				create Result.make_from_string_ctx ("NaN", ctx)
			elseif ((sign = -1 and (other.is_infinity or other.is_signaling_nan))) then
				create Result.make_snan
			elseif (sign = 1 and is_infinity and other.sign = -1) then
				create Result.make_from_string_ctx ("0", ctx)
			elseif (sign = 1 and is_infinity and other.is_zero) then
				create Result.make_from_string_ctx ("1", ctx)
			elseif (sign = 1 and is_infinity and other.sign = 1) then
				create Result.make_from_string_ctx ("Infinity", ctx)
			elseif (sign = -1 and is_infinity and other.sign = -1) then
				create Result.make_from_string_ctx ("-0", ctx)
			elseif (sign = -1 and is_infinity and other.is_zero) then
				create Result.make_from_string_ctx ("0", ctx)
			elseif (sign = -1 and is_infinity and other.sign = 1 and (other.remainder ("2", ctx).is_zero)) then
				create Result.make_from_string_ctx ("Infinity", ctx)
			elseif (sign = -1 and is_infinity and other.sign = 1 and (not other.remainder ("2", ctx).is_zero)) then
				create Result.make_from_string_ctx ("-Infinity", ctx)
			elseif (other.is_zero and not (is_signaling_nan or is_nan)) then
				create Result.make_from_string_ctx ("1", ctx)
			elseif other.is_double and is_double and is_negative then
				create Result.make_from_string_ctx ("NaN", ctx)
			elseif other.is_integer then
				-- If y is an integer in x^y then just compute x^y using the power of integer feature.
				Result := power_integer_wrt_ctx (other, ctx)
			else
				-- If y is real in x^y then do e^(y ln(x))
				-- loge := 1/log10(e)  pre-computed to precision 10000 in python

				computed_power := other.multiply (log10_wrt_ctx (ctx), ctx)
				computed_power := computed_power.multiply (q.ln10, ctx)
				Result := computed_power.exp_wrt_ctx (ctx)
			end
		ensure
			power_not_void: Result /= Void
		end


	power_integer_wrt_ctx (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
		--`Current' decimal to the power of `other' (integer) with respect to `ctx'

		require
			other_not_void: other /= Void
			ctx_not_void: ctx /= Void
			other_is_integer: other.is_integer
		local
			cur, ot, final: DECIMAL
			flag: BOOLEAN
		do
			create final.make_one
			create cur.make_copy (Current)
			create ot.make_copy (other)

			ot := ot.abs

			from
				flag := FALSE
			until
				ot.to_double.floor = 0 or ot.to_double.floor = -0 or flag = TRUE
			loop
				if (not (ot.remainder ("2", ctx).is_zero)) then
					final := final.multiply (cur, ctx)
					ot := ot - once_one
				end
				cur := cur.multiply (cur, ctx)
				ot := ot.divide ("2", ctx)
				if final.is_infinity or final.is_nan or final.is_signaling_nan then
					flag := TRUE
				end
			end

			if other.sign = -1 then
				if final.is_infinity and final.sign = -1 then
					ctx.reset_flags
					ctx.set_flag (2)
					ctx.set_flag (6)
					ctx.set_flag (7)
					ctx.set_flag (8)
				end
				final := once_one.divide (final, ctx)
			end
			Result := final
		ensure
			power_not_void: Result /= Void
		end

	position_of_decimal_point: INTEGER

	do
		Result := position_of_decimal_point_wrt_ctx(shared_decimal_context)
	end

	position_of_decimal_point_wrt_ctx(ctx: DCM_MA_DECIMAL_CONTEXT): INTEGER

		require
			current_not_void: Current /= Void
			context_not_void: ctx /= Void
		local
			cp: DECIMAL
		do
			If is_equal (one) then
				Result := 0
			elseif is_greater (one) then
				Result := position_of_decimal_point_positive(ctx)
			else
--				create cp.make_copy (current)
--				cp.set_exponent (cp.exponent.abs)
				Result := position_of_decimal_point_negative(ctx)
			end
		end

	position_of_decimal_point_negative(ctx: DCM_MA_DECIMAL_CONTEXT): INTEGER
			-- position of decimal point for `Current'

		require
			is_greater (zero)
			is_less (one)
			current_not_void: Current /= Void
			context_not_void: ctx /= Void
		local
			i, ten, start_interval, end_interval, x, y: DECIMAL
			terminate: BOOLEAN
		do
			from
				create ten.make_from_string_ctx ("10", ctx)
				create i.make_from_string_ctx ("1", ctx)
				create start_interval.make_from_string_ctx ("1", ctx)
				end_interval := "1"
			until
				terminate
			loop
				x := ten_ten_exp(i, ctx)
				start_interval := "1"
				start_interval := start_interval.divide (x, ctx)

				if start_interval.is_less_equal (Current) and is_less (end_interval) then
					terminate := True
				else
					i := i.add (one, ctx)
				end
			end
			i := i.max_ctx (zero, ctx)
			if i.is_zero then
				Result := 0
			else
				Result := i.to_integer - 1
			end
		end

	position_of_decimal_point_positive(ctx: DCM_MA_DECIMAL_CONTEXT): INTEGER
			-- position of decimal point for `Current'

		require
			current_greater_equal_to_one: is_greater_equal (one)
			current_not_void: Current /= Void
			context_not_void: ctx /= Void
		local
			i, ten, start_interval, end_interval : DECIMAL
			terminate: BOOLEAN
		do
			from
				create ten.make_from_string_ctx ("10", ctx)
				create i.make_from_string_ctx ("1", ctx)
				create start_interval.make_from_string_ctx ("1", ctx)
			until
				terminate
			loop
				end_interval := ten_ten_exp(i, ctx)
				if start_interval.is_less_equal (Current) and is_less (end_interval) then
					terminate := True
				else
					start_interval := end_interval
					i := i.add (one, ctx)
				end
			end
			i := i.max_ctx (zero, ctx)
			Result := i.to_integer - 1
		end

	ten_ten_exp(n: DECIMAL; ctx: DCM_MA_DECIMAL_CONTEXT): DECIMAL
		require
			n_not_void: n /= Void
			ctx_not_void: ctx /= Void
		local
			ten_ten, ten: DECIMAL
		do
			create ten_ten.make_from_string_ctx ("10", ctx)
			create ten.make_copy (ten_ten)
			ten_ten.set_exponent (n.subtract (one, ctx).subtract (one, ctx).to_integer)
			Result := ten.power_wrt_ctx (ten_ten, ctx)
		ensure
			result_not_void: Result /= Void
		end

	an_no_of_digits_before_decimal_point (ctx: DCM_MA_DECIMAL_CONTEXT): INTEGER
			--return factor a_n in M. Goldberg algorithm for Computing Log Digit by Digit
		require
			ctx_not_void: ctx /= Void
		do
			if exponent = 0 then
				Result := count
			elseif exponent < ctx.precision then
				if count > exponent.abs then
					Result := (count + exponent).abs
				else
					Result := 1
				end
			else
				Result := count + exponent
			end
		end

	log10: like Current
		--Perform log10 on `Current' using shared_decimal_context
		do
			Result := log10_wrt_ctx (shared_decimal_context)
		ensure then
			division_not_void: Result /= Void
		end

	log10_wrt_ctx (ctx: DCM_MA_DECIMAL_CONTEXT): like Current
		--Perform log10 on `Current' using ctx as context
		--Using Mayer Goldberg algorithm, Computing Logarithms Digit-by-Digit

		require
			current_not_void: Current /= Void
			ctx_not_void: ctx /= Void
			greater_than_equal_zero: not ctx.exception_on_trap or else (is_greater_equal ("0"))
		local
			a, index: INTEGER
			a1, x, ten, ten_w: DECIMAL
			s: BOOLEAN
		do
			--If 0 < x < 1 then inverse the number and calculate the log10 and make the sign of Result = -1
			--If x > 1 then calculate the log10 using Mayer Goldberg algorithm, Computing Logarithms Digit-by-Digit
			--If x = 0 then Result is -Inf
			--If x is +Inf then Result is +Inf
			--If x is -Inf or x is sNan, NaN then Result is NaN
			--If x is 1 then Result is 0
			if is_zero then
				create Result.make_infinity(-1)
			elseif is_infinity and is_positive then
				create Result.make_infinity (1)
			elseif (is_infinity and is_negative) or is_less ("0") or is_nan or is_signaling_nan then
				create Result.make_from_string_ctx ("NaN", ctx)
			elseif is_one and sign = 1 then
				create Result.make_from_string_ctx ("0", ctx)
			else
				s := is_less (one)
					--Set flag to True if 0 < x < 1 and take inverse
				if s then
					x := one.divide (Current, ctx)
				else
					create x.make_copy (Current)
				end
				from
					index := 0
					create ten.make_from_string_ctx ("10", ctx)
					create ten_w.make_from_string_ctx ("10", ctx)
					create Result.make_from_string_ctx ("0", ctx)
				until
					index > ctx.precision
				loop --M. Goldberg Algorithm
					a := x.an_no_of_digits_before_decimal_point(ctx) - 1
					ten_w.set_exponent (a - 1)
					x := x.divide (ten_w, ctx)
					x := x.power_wrt_ctx (ten, ctx)
					create a1.make_from_string_ctx (a.out, ctx)
					Result := Result.multiply (ten, ctx)
					Result := Result.add (a1, ctx)
					index := index + 1
				end
				a := position_of_decimal_point_wrt_ctx (ctx) --Find the decimal position for the answer and set the exponent accordingly
				if a = 0 then
					Result.set_exponent ((ctx.precision) * -1)
				elseif a <= ctx.precision then
					Result.set_exponent ((ctx.precision - a) * -1)
				else
					Result.set_exponent ((ctx.precision + a) * -1)
				end
					-- If answer is integer then remove all the zeros				
				if Result.is_integer then
					Result := Result.round_to_integer (ctx)
				end
					-- If 0 < x < 1 then set Result to negative
				Result.set_is_negative (s)
			end
		ensure
			answer_not_void: Result /= Void
		end

	log2: like Current
		--Perform log2 on `Current' using shared_decimal_context
		do
			Result := log2_wrt_ctx (shared_decimal_context)
		ensure then
			division_not_void: Result /= Void
		end

	log2_wrt_ctx (ctx: DCM_MA_DECIMAL_CONTEXT): like Current
		--Perform log2 on `Current' using ctx as context
		require
			current_not_void: Current /= Void
			ctx_not_void: ctx /= Void
			greater_than_equal_zero: not ctx.exception_on_trap or else (is_greater_equal ("0"))
		local
		 	two, user, base, peak: DECIMAL
		 do
		-- Check extreme cases where user input is either zero, infinity, or NaN.
		if is_zero then
			create Result.make_infinity(-1)
		elseif is_infinity and is_positive then
			create Result.make_infinity (1)
		elseif (is_infinity and is_negative) or is_less ("0") or is_nan or is_signaling_nan then
			create Result.make_from_string_ctx ("NaN", ctx)
			ctx.reset_flags
		elseif is_one and sign = 1 then
			create Result.make_from_string_ctx ("0", ctx)
		else
		-- In all other cases, we return the logarithm in base 2 of the user input
			create Result.make_from_string_ctx ("0", ctx)
     		create two.make_from_string_ctx ("2", ctx)
			create base.make_from_string_ctx ("0", ctx)
	    	base := two.log10_wrt_ctx (ctx)
     		create user.make_copy (current)
			peak := user.log10_wrt_ctx (ctx)
			Result := peak.divide (base, ctx)
		end
		ensure
			answer_not_void: Result /= Void
		end

feature {DECIMAL, DCM_MA_DECIMAL_PARSER} -- Element change

	set_exponent (e: like exponent)
			-- Set `exponent' to `e'.
		do
			exponent := e
		ensure
			exponent_set: exponent = e
		end

	set_is_negative (a_is_negative: like is_negative)
			-- Set negative.
		local
			l_flags: like flags
		do
				-- Keep only the special mask.
			l_flags := flags & special_mask
			if a_is_negative then
				flags := l_flags | is_negative_flag
			else
				flags := l_flags
			end
		ensure
			negative: is_negative = a_is_negative
		end

feature {NONE} -- Constants

	Align_hint_current: INTEGER = 1

	Align_hint_other: INTEGER = 2

	Align_hint_both: INTEGER = 3

	Align_hint_current_zero: INTEGER = 4

	Align_hint_other_zero: INTEGER = 5

feature {DECIMAL} -- Status setting

	flags: NATURAL_8
			-- Storage for `special' and `is_negative'.
			-- Lower 4 bits are for `special'.
			-- Upper first bit for `is_negative'.

	is_negative_flag: NATURAL_8 = 0x10
			-- Flag marking if decimal is negative or not.

	special_mask: NATURAL_8 = 0x0F
			-- Mask marking the special part of `flags'.

	special: NATURAL_8
			-- Lower 4 bits of `flags'.
		do
			Result := flags & special_mask
		end

	set_quiet_nan
			-- Set to qNaN.
		do
			make_nan
		ensure
			qnan: is_quiet_nan
		end

feature {DECIMAL} -- Basic operations

	add_special (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Add special numbers.
		require
			other_not_void: other /= Void
			special: is_special or else other.is_special
			ctx_not_void: ctx /= Void
		do
				-- Prepare result.
				-- Set its value.
			if is_nan or else other.is_nan then
				if is_signaling_nan or else other.is_signaling_nan then
					ctx.signal (Signal_invalid_operation, "sNaN operand in add")
				end
				Result := nan
			elseif is_infinity and then other.is_infinity then
				if sign /= other.sign then
					ctx.signal (Signal_invalid_operation, "+Inf and -Inf operands in add")
					Result := nan
				else
					if is_negative then
						Result := negative_infinity
					else
						Result := infinity
					end
				end
			elseif is_infinity or else other.is_infinity then
				if is_infinity then
					if is_negative then
						Result := negative_infinity
					else
						Result := infinity
					end
				else
						-- `other' is Inf
					if other.is_negative then
						Result := negative_infinity
					else
						Result := infinity
					end
				end
			else
				Result := nan
			end
		ensure
			add_special_not_void: Result /= Void
		end

	subtract_special (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT): like Current
			-- Subtract special numbers.
		require
			other_not_void: other /= Void
			special: is_special or else other.is_special
			ctx_not_void: ctx /= Void
		do
				-- Prepare result.
				-- Set its value.
			if is_nan or else other.is_nan then
				if is_signaling_nan or else other.is_signaling_nan then
					ctx.signal (Signal_invalid_operation, "sNaN operand in subtract")
				end
				Result := nan
			elseif is_infinity and then other.is_infinity then
				if sign = other.sign then
					ctx.signal (Signal_invalid_operation, "Inf and Inf operands in subtract")
					Result := nan
				else
					if is_negative then
						Result := negative_infinity
					else
						Result := infinity
					end
				end
			elseif is_infinity or else other.is_infinity then
				Result := infinity
				if is_infinity then
					if is_negative then
							-- -Inf - x = -Inf
						Result := negative_infinity
					end
				else
						-- `other' is Inf
					if other.is_positive then
							-- x - +Inf = -Inf
						Result := negative_infinity
					else
							-- x - -Inf = +Inf
						Result := infinity
					end
				end
			else
				Result := nan
			end
		ensure
			subtract_special_not_void: Result /= Void
		end

	unsigned_add (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Add `other' to `Current'.
			-- Note: this will alter `other' and `Current'.
		require
			other_not_void: other /= Void
			ctx_not_void: ctx /= Void
		local
			align_hint: INTEGER
			msd: INTEGER
		do
				-- Avoid costly operations.
				-- Align.
			align_hint := align_and_hint (other, ctx.digits)
			if align_hint = Align_hint_current then
					-- Keep `Current'.
				shift_left (ctx.digits + 2 - count)
				coefficient.put (other.coefficient.item (other.coefficient.msd_index), 0)
				ctx.signal (Signal_inexact, "")
			elseif align_hint = Align_hint_other then
					-- Copy `other'.
				msd := coefficient.item (coefficient.msd_index)
				copy (other)
				shift_left (ctx.digits + 2 - count)
				coefficient.put (msd, 0)
				ctx.signal (Signal_inexact, "")
			elseif align_hint = Align_hint_other_zero then
				copy (other)
			elseif align_hint = Align_hint_current_zero then
					-- Keep `Current'.
			else
				coefficient.integer_add (other.coefficient)
				exponent := exponent.min (other.exponent)
			end
		end

	unsigned_subtract (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Subtract `other' without taking the sign into account.
		require
			other_not_void: other /= Void
			ctx_not_void: ctx /= Void
		local
			test, align_hint: INTEGER
		do
				-- Avoid costly operations.
				-- Align.
			align_hint := align_and_hint (other, ctx.digits)
			if align_hint = Align_hint_current then
					-- Keep `Current', but subtract -1E-precision
				shift_left (ctx.digits + 2 - count)
				coefficient.integer_quick_subtract_msd (1, coefficient.count)
			elseif align_hint = Align_hint_other then
					-- Copy `other'.
				copy (other)
				shift_left (ctx.digits + 2 - count)
				coefficient.integer_quick_subtract_msd (1, coefficient.count)
				set_is_negative (True)
			elseif align_hint = Align_hint_current_zero then
					-- Keep `Current'.
			elseif align_hint = Align_hint_other_zero then
					-- Copy `other'.
				copy (other)
				set_is_negative (True)
			else
				test := coefficient.three_way_comparison (other.coefficient)
				if test = 0 then
					coefficient.keep_head (1)
					coefficient.put (0, 0)
				elseif test > 0 then
					coefficient.integer_subtract (other.coefficient)
				else
						-- other > Current
					other.coefficient.integer_subtract (coefficient)
					coefficient.copy (other.coefficient)
					set_is_negative (True)
				end
				exponent := exponent.min (other.exponent)
			end
		end

	round (ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Round `Current' according to ctx.rounding_mode.
		require
			not_special: not is_special
			roundable: ctx.digits > 0 and then count > ctx.digits
		do
			if is_special then
				if is_signaling_nan then
					ctx.signal (Signal_invalid_operation, "sNaN in 'round'")
				end
			elseif count > ctx.digits then
				ctx.signal (Signal_rounded, "Argument rounded")
				if lost_digits (ctx) then
					ctx.signal (Signal_inexact, "Inexact when rouding")
				end
				inspect ctx.rounding_mode
				when Round_up then
					do_round_up (ctx)
				when Round_down then
					do_round_down (ctx)
				when Round_ceiling then
					do_round_ceiling (ctx)
				when Round_floor then
					do_round_floor (ctx)
				when Round_half_up then
					do_round_half_up (ctx)
				when Round_half_down then
					do_round_half_down (ctx)
				when Round_half_even then
					do_round_half_even (ctx)
				else
						-- Do nothing.
				end
			end
		ensure
			rounded: count <= ctx.digits
		end

	align_and_hint (other: like Current; precision: INTEGER): INTEGER
			-- Align `Current' and `other' with respect to `precision'
			-- and give hint for further operations
		local
			new_count, new_exponent: INTEGER
			limited_precision: BOOLEAN
			shift_count: INTEGER
		do
			limited_precision := (precision > 0)
			if exponent = other.exponent then
					-- Adjust each other's count?
				new_count := count.max (other.count)
				if new_count > count then
					grow (new_count)
				end
				if new_count > other.count then
					other.grow (new_count)
				end
				Result := Align_hint_both
			elseif exponent > other.exponent then
					-- Need to pad `Current' so that exponent = other.exponent.
					-- Examine if `other' would NOT affect `Current'
					-- i.e. if `Current' would be longer than `other' by digits + 1 or more
					-- we only need to pad up to a length of `precision' + 1
					--
					-- except when `Current' is Zero. In this case `other' is returned, unchanged.
				new_exponent := exponent.min (adjusted_exponent - (precision + 1))
				if new_exponent > other.adjusted_exponent then
						-- `other' shall not affect `Current'.
					if is_zero then
						Result := Align_hint_other_zero
					else
						if limited_precision then
							if other.is_zero then
									-- Avoid unnecessary rounding.
								Result := Align_hint_current_zero
							else
								Result := Align_hint_current
							end
							shift_count := precision + 1 - count
							if shift_count > 0 then
								shift_left (shift_count)
							end
						end
					end
				else
					if limited_precision then
						align_overlapped (other, precision)
					else
						align_unlimited (other)
					end
					Result := Align_hint_both
				end
			else
					-- exponent < other.exponent
					-- Need to pad other so that other.exponent = exponent
				new_exponent := other.exponent.min (other.adjusted_exponent - (precision + 1))
				if new_exponent > adjusted_exponent then
						-- `Current' shall not affect `other',
						-- except when `other' is Zero. In this case `Current' is returned, unchanged.
					if other.is_zero then
						Result := Align_hint_current_zero
					else
						if limited_precision then
							if is_zero then
								Result := Align_hint_other_zero
							else
								Result := Align_hint_other
							end
							shift_count := precision + 1 - other.count
							if shift_count > 0 then
								other.shift_left (shift_count)
							end
						end
					end
				else
					if limited_precision then
						other.align_overlapped (Current, precision)
					else
						other.align_unlimited (Current)
					end
					Result := Align_hint_both
				end
			end
		ensure
			hint_both_is_same_count: Result = Align_hint_both implies count = other.count
			hint_both_is_same_exponent: Result = Align_hint_both implies exponent = other.exponent
		end

	align_overlapped (other: like Current; precision: INTEGER)
			-- Align overlapping numbers.
		require
			other_not_void: other /= Void
			exponent_greater: exponent > other.exponent
		local
			exponent_delta, new_digits: INTEGER
		do
				-- Adjust exponents.
			exponent_delta := exponent - other.exponent
			if exponent_delta > 0 then
				shift_left (exponent_delta)
			end
			new_digits := count.max (other.count)
				-- Adjust `count' to be `precision'.
			if new_digits > other.count then
				other.grow (new_digits)
			end
			if new_digits > count then
				grow (new_digits)
			end
		ensure
			same_count: count = other.count
			same_exponent: exponent = other.exponent
		end

	align_unlimited (other: like Current)
			-- Align unlimited.
		require
			other_not_void: other /= Void
			exponent_greater: exponent > other.exponent
		local
			count_alignment: INTEGER
		do
				-- Adjust `Current'.
			shift_left (exponent - other.exponent)
			count_alignment := count - other.count
			if count_alignment > 0 then
					-- Must grow `other'.
				other.grow (count)
			elseif count_alignment < 0 then
				grow (other.count)
			else
					-- Do nothing.
			end
		ensure
			same_count: count = other.count
			same_exponent: exponent = other.exponent
		end

	shift_left (a_count: INTEGER)
			-- Shift the coefficient left `a_count' position and adjust `exponent'.
			-- value still must be the same as with the original `exponent'.
		require
			not_special: not is_special
			a_count_positive: a_count > 0
		do
			coefficient.shift_left (a_count)
			exponent := exponent - a_count
		ensure
			count_adapted: count = old count + a_count
			exponent_adapted: exponent = old exponent - a_count
		end

	shift_right (a_count: INTEGER)
			-- Shift the coefficient right `a_count' position and adjust `exponent'.
			-- Digits are lost.
		require
			not_special: not is_special
			a_count_positive: a_count > 0
		do
			coefficient.shift_right (a_count)
			exponent := exponent + a_count
		ensure
			exponent_adapted: exponent = old exponent + a_count
		end

	grow (a_count: INTEGER)
			-- Grow `coefficient' so that it can accommodate `a_count' digits.
		require
			not_special: not is_special
			a_count_greater_zero: a_count > 0
			a_count_less_10_000: a_count < 10_000
		do
			coefficient.grow (a_count)
		ensure
			count_set: count = a_count
		end

	do_round_up (ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Round away from zero.
		require
			ctx_not_void: ctx /= Void
		local
			old_count, exponent_increment: INTEGER
		do
			if lost_digits (ctx) then
				old_count := count
				coefficient.integer_quick_add_msd (1, ctx.digits)
				exponent_increment := old_count - ctx.digits
				exponent := exponent + exponent_increment
			end
			if count > ctx.digits then
				shift_right (count - ctx.digits)
				coefficient.keep_head (ctx.digits)
			end
		end

	do_round_down (ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Round towards zero.
		require
			ctx_not_void: ctx /= Void
			positive_precision: ctx.digits >= 1
		local
			exponent_increment: INTEGER
			l_count: INTEGER
		do
			l_count := count - ctx.digits
			coefficient.shift_right (l_count)
			exponent_increment := l_count
			exponent := exponent + exponent_increment
			coefficient.keep_head (ctx.digits)
		end

	do_round_ceiling (ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Round to a more positive number.
		require
			ctx_not_void: ctx /= Void
		do
			if is_negative or else not lost_digits (ctx) then
				do_round_down (ctx)
			else
				do_round_up (ctx)
			end
		end

	do_round_floor (ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Round to a more negative number.
		require
			ctx_not_void: ctx /= Void
		do
			if is_positive or else not lost_digits (ctx) then
				do_round_down (ctx)
			else
				do_round_up (ctx)
			end
		end

	do_round_half_up (ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Round to nearest neighbor, where an equidistant value is rounded up.
			-- If the discarded digits represent greater than or equal to half (0.5 times) the value
			-- of a one in the next position then the result should be rounded up (away from zero).
			-- Otherwise the discarded digits are ignored.
		require
			ctx_not_void: ctx /= Void
		do
			inspect three_way_compare_discarded_to_half (ctx)
			when 1, 0 then
					-- Greater, equal.
				do_round_up (ctx)
			else
					-- Less.
				do_round_down (ctx)
			end
		end

	do_round_half_down (ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Round to nearest neighbor, where an equidistant value is rounded down.
			-- If the discarded digits represent greater than half (0.5 times)
			-- the value of a one in the next position then the result should be
			-- rounded up (away from zero). Otherwise the discarded digits are ignored.
		require
			ctx_not_void: ctx /= Void
		do
			inspect three_way_compare_discarded_to_half (ctx)
			when -1 then
					-- Less.
				do_round_down (ctx)
			when 1 then
					-- Greater.
				do_round_up (ctx)
			else
					-- Equal.
				do_round_down (ctx)
			end
		end



	three_way_compare_discarded_to_half (ctx: DCM_MA_DECIMAL_CONTEXT): INTEGER
			-- Compare discarded digits greater than 0.5
		require
			ctx_not_void: ctx /= Void
		local
			digit, index: INTEGER
		do
			digit := coefficient.item (count - ctx.digits - 1)
			if digit > 5 then
				Result := 1
			elseif digit < 5 then
				Result := -1
			else
				index := count - ctx.digits - 2
					-- Search for non zero digit to the right.
				from
				until
					index < 0 or else coefficient.item (index) /= 0
				loop
					index := index - 1
				end
				if index >= 0 then
						-- More than half.
					Result := 1
				else
						-- Exactly half.
					Result := 0
				end
			end
		ensure
			definition: Result >= -1 and then Result <= 1
		end

	do_round_half_even (ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Round to nearest neighbor, where an equidistant value is rounded to the nearest even neighbor.
			-- If the discarded digits represent greater than half (0.5 times) the value of a one in the
			-- next position then the result should be rounded up (away from zero).
			-- If they represent less than half, then the result should be rounded down.
			-- Otherwise (they represent exactly half) the result is rounded down if its rightmost digit
			-- is even, or rounded up if its rightmost digit is odd (to make an even digit).
		require
			ctx_not_void: ctx /= Void
		do
			inspect three_way_compare_discarded_to_half (ctx)
			when -1 then
					-- Less.
				do_round_down (ctx)
			when 1 then
					-- Greater.
				do_round_up (ctx)
			else
					-- Equal.
				if (coefficient.item (count - ctx.digits) \\ 2 = 0) then
					do_round_down (ctx)
				else
					do_round_up (ctx)
				end
			end
		end

	lost_digits (ctx: DCM_MA_DECIMAL_CONTEXT): BOOLEAN
			-- Should Current loose digits if rounded wrt `ctx'?
		require
			ctx_not_void: ctx /= Void
		local
			index: INTEGER
		do
			from
				index := count - ctx.digits - 1
			until
				index < 0 or else coefficient.item (index) /= 0
			loop
				index := index - 1
			end
				-- True if found non-zero digits in [0..count-ctx.digits-1].
			Result := index >= 0
		ensure
			definition1: (count - ctx.digits - 1) >= 0 implies Result = (coefficient.subcoefficient (0, count - ctx.digits - 1)).is_significant
			definition2: (count - ctx.digits - 1) < 0 implies not Result
		end

	is_overflow (ctx: DCM_MA_DECIMAL_CONTEXT): BOOLEAN
			-- Is there an overflow condition wrt `ctx'?
		require
			ctx_not_void: ctx /= Void
		do
			Result := adjusted_exponent > ctx.exponent_limit
		ensure
			definition: Result = (adjusted_exponent > ctx.exponent_limit)
		end

	is_underflow (ctx: DCM_MA_DECIMAL_CONTEXT): BOOLEAN
			-- Is there an underflow condition wrt `ctx'?
		require
			ctx_not_void: ctx /= Void
		do
			Result := adjusted_exponent < -ctx.exponent_limit
		ensure
			definition: Result = (adjusted_exponent < -ctx.exponent_limit)
		end

	clean_up (ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Clean up Current wrt `ctx', rounding it if necessary.
		require
			ctx_not_void: ctx /= Void
		local
			lost_digits_trap, lost_digits_flag: BOOLEAN
		do
			if not is_special then
				lost_digits_trap := ctx.is_trapped (Signal_lost_digits)
				lost_digits_flag := ctx.is_flagged (Signal_lost_digits)
					-- Round as if no lost_digits trap existed.
				ctx.disable_trap (Signal_lost_digits)
				ctx.reset_flag (Signal_lost_digits)
					-- Avoid losing significant digits in msd.
				strip_leading_zeroes
				if is_underflow (ctx) then
					do_underflow (ctx)
				else
					if ctx.digits > 0 and then count > ctx.digits then
						round (ctx)
					end
					if is_overflow (ctx) then
						do_overflow (ctx)
					end
				end
					-- Restore flags and traps.
				if lost_digits_trap then
					ctx.enable_trap (Signal_lost_digits)
				end
				if lost_digits_flag or else ctx.is_flagged (Signal_lost_digits) then
					ctx.set_flag (Signal_lost_digits)
				else
					ctx.reset_flag (Signal_lost_digits)
				end
			end
		end

	strip_leading_zeroes
			-- Strip leading zeroes.
		require
			not_special: not is_special
		do
			coefficient.strip_leading_zeroes
		end

	set_largest (ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Set to largest finite number that can be represented with ctx.precision.
		require
			ctx_not_void: ctx /= Void
		local
			index: INTEGER
		do
			if count < ctx.digits then
				grow (ctx.digits)
			end
			from
				index := 0
			until
				index >= count
			loop
				coefficient.put (9, index)
				index := index + 1
			end
			coefficient.keep_head (ctx.digits)
			if exponent < 0 then
				exponent := -ctx.exponent_limit + (count - 1)
			else
				exponent := ctx.exponent_limit - (count - 1)
			end
		end

	promote_to_infinity (a_sign: INTEGER)
			-- Promote to infinity.
		do
			make_infinity (a_sign)
		ensure
			infinity: is_infinity
			sign_set: sign = a_sign
		end

	do_overflow (ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Do overflow.
		require
			ctx_not_void: ctx /= Void
			overflow: is_overflow (ctx)
		do
			if not is_zero then
				ctx.signal (Signal_overflow, "")
				inspect ctx.rounding_mode
				when Round_half_up, Round_half_even, Round_half_down, Round_up then
					promote_to_infinity (sign)
				when Round_down then
					set_largest (ctx)
				when Round_ceiling then
					if is_negative then
						set_largest (ctx)
					else
						promote_to_infinity (sign)
					end
				when Round_floor then
					if is_positive then
						set_largest (ctx)
					else
						promote_to_infinity (sign)
					end
				end
				ctx.signal (Signal_inexact, "do_overflow")
				ctx.signal (Signal_rounded, "do_overflow")
			else
				set_exponent (ctx.exponent_limit)
			end
		end

	do_underflow (ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Do underflow.
		require
			ctx_not_void: ctx /= Void
			underflow: is_underflow (ctx)
		local
			e_tiny, shared_digits, subnormal_count, count_upto_elimit, saved_digits: INTEGER
			l_is_zero, l_was_rounded: BOOLEAN
			value: INTEGER
			l_reason: detachable STRING
		do
			l_is_zero := is_zero
			if not l_is_zero then
				ctx.signal (Signal_subnormal, "")
			else
				l_was_rounded := ctx.is_flagged (Signal_rounded)
			end
				-- Rescale to `e_tiny'.
			e_tiny := ctx.e_tiny
			if exponent < e_tiny then
				saved_digits := ctx.digits
				shared_digits := adjusted_exponent - e_tiny + 1
				if shared_digits < 0 then
						-- Impossible to share any digit with `e_tiny'.
					saved_digits := ctx.digits
					ctx.force_digits (coefficient.count - 1)
					value := 0
					inspect ctx.rounding_mode
					when Round_up then
						value := 1
					when Round_ceiling then
						if is_positive and then lost_digits (ctx) then
							value := 1
						end
					when Round_floor then
						if is_positive or else not lost_digits (ctx) then
							value := 0
						else
							value := 1
						end
					else
						value := 0
					end
					ctx.set_digits (saved_digits)
					coefficient.put (value, 0)
					coefficient.keep_head (1)
					exponent := e_tiny
					ctx.signal (Signal_inexact, "Rescaling to e_tiny")
					ctx.signal (Signal_rounded, "Rescaling to e_tiny")
					ctx.signal (Signal_underflow, "Rescaling to e_tiny")
				else
					if shared_digits = 0 then
							-- msd at e_tiny - 1. See if rounding shall carry some e_tiny digit.
						ctx.set_digits (1)
						grow (count + 1)
					else
						check
--							shared_digits > 0 and shared_digits <= ctx.digits
						end
						count_upto_elimit := -ctx.exponent_limit - exponent + 1
						if count < count_upto_elimit then
							grow (count_upto_elimit)
						end
						subnormal_count := -ctx.exponent_limit - e_tiny + 1
						ctx.set_digits (subnormal_count)
					end
					round (ctx)
					ctx.set_digits (saved_digits)
					strip_leading_zeroes
					if ctx.is_flagged (Signal_subnormal) and then ctx.is_flagged (Signal_inexact) then
						ctx.signal (Signal_underflow, "Underflow when rescaling")
					end
					if is_overflow (ctx) then
						do_overflow (ctx)
					end
				end
				exponent := e_tiny
				if l_is_zero then
					if l_was_rounded then
						l_reason := ctx.reason
						check l_reason /= Void end -- implied by ... ?
						ctx.signal (Signal_rounded, l_reason)
					else
						ctx.reset_flag (Signal_rounded)
					end
				end
			end
		end

	division_standard: INTEGER = 1

	division_integer: INTEGER = 2

	division_remainder: INTEGER = 3
			-- Division types

	do_divide (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT; division_type: INTEGER): like Current
			-- Do a `division_type' of `Current' by `other'
		require
			other_not_void: other /= Void
			ctx_not_void: ctx /= Void
		local
			integer_division: BOOLEAN
		do
			integer_division := (division_type = division_integer) or else (division_type = division_remainder)
			if is_special or else other.is_special then
					-- sNan.
				if is_nan or else other.is_nan then
					if is_signaling_nan or else other.is_signaling_nan then
						ctx.signal (Signal_invalid_operation, "sNan in divide")
					end
					Result := nan
				elseif is_infinity and then other.is_infinity then
					ctx.signal (Signal_invalid_operation, "[+-] Inf / [+-] Inf")
					Result := nan
				elseif is_infinity then
					if sign = other.sign then
						Result := infinity
					else
						Result := negative_infinity
					end
					if other.is_zero then
						ctx.signal (Signal_division_by_zero, "[+-] Inf / [+-] 0")
					end
				elseif other.is_infinity then
					if sign = other.sign then
						Result := zero
					else
						Result := negative_zero
					end
				else
					Result := nan
				end
			else
				if other.is_zero then
					if is_zero then
						ctx.signal (Signal_invalid_operation, "Division Undefined : O/O")
						Result := nan
					else
						ctx.signal (Signal_division_by_zero, "Division by zero")
						if sign = other.sign then
							Result := infinity
						else
							Result := negative_infinity
						end
					end
				elseif is_zero then
					create Result.make_zero
					if integer_division then
						Result.set_exponent (0)
					else
						Result.set_exponent (exponent - other.adjusted_exponent)
					end
					Result.set_is_negative (sign /= other.sign)
					Result.clean_up (ctx)
				else
					Result := internal_divide (other, ctx, division_type)
					Result.set_is_negative (sign /= other.sign)
					Result.clean_up (ctx)
				end
			end
		ensure
			divide_not_void: Result /= Void
		end

	internal_divide (other: like Current; ctx: DCM_MA_DECIMAL_CONTEXT; division_type: INTEGER): like Current
			-- Divide `Current' by `other' whith respect to `ctx'
		require
			other_not_void: other /= Void
			ctx_not_void: ctx /= Void
		local
			dividend, divisor, local_remainder: like Current
			adjust, divisor_adjust, dividend_adjust, current_digit_exponent, new_exponent: INTEGER
			original_dividend_exponent, original_divisor_exponent, bias: INTEGER
			done, integer_division, impossible, is_negative_exponent, dividend_is_zero: BOOLEAN
		do
			integer_division := (division_type /= division_standard)
			create dividend.make_copy (Current)
			create divisor.make_copy (other)
				--
			original_divisor_exponent := divisor.exponent
			original_dividend_exponent := dividend.exponent
			dividend_is_zero := dividend.is_zero
				-- Prepare result.
			create Result.make (ctx.digits + 1)
			adjust := 0
			divisor_adjust := 0
			dividend_adjust := 0
				-- Adjust coefficients so that
				-- 1. divisor.coefficient <= dividend.coefficient
				-- 2. dividend.coefficient < 10 * divisor.coefficient
			from
					-- While coefficient of dividend is less than coefficient of divisor
					-- multiply coefficient of divident by 10.
			until
				dividend.coefficient >= divisor.coefficient
			loop
				dividend.shift_left (1)
				adjust := adjust + 1
				dividend_adjust := dividend_adjust + 1
			end
			check
				dividend.coefficient >= divisor.coefficient
			end
			from
					-- While coefficient of divisor >= 10 * coefficient of dividend,
					-- Until dividend.coefficient / 10 < divisor.coefficient,
					-- Multiply divisor by 10.
					--
					-- Init: compute 10 * coefficient of dividend
				divisor.shift_left (1)
					-- Adjust coefficient sizes.
			until
				dividend.coefficient < divisor.coefficient
			loop
				adjust := adjust - 1
				divisor.shift_left (1)
				divisor_adjust := divisor_adjust + 1
			end
				-- Divide by 10.
			check
				dividend.coefficient < divisor.coefficient
			end
				-- Get back to divisor: undo 'init'.
			divisor.shift_right (1)
			divisor.coefficient.keep_head (divisor.coefficient.count - 1)
				-- Do divide.
			from
				if integer_division then
						-- Determine if division is possible.
					current_digit_exponent := (original_dividend_exponent - (original_divisor_exponent + adjust))
					impossible := (current_digit_exponent >= ctx.digits)
					is_negative_exponent := (current_digit_exponent) < 0
					done := is_negative_exponent or else impossible
				else
					impossible := False
					done := False
				end
				if not done then
						-- Prepare `Result' so that it can accomodate ctx.digits + 1 digits.
					Result.coefficient.grow (ctx.digits + 1)
					Result.coefficient.keep_head (1)
				end
			until
				done
			loop
					-- Compute digit of rank 'current_digit_exponent' by repeatedly subtracting divisor from dividend.
				from
				until
					divisor.coefficient > dividend.coefficient
				loop
					dividend.coefficient.integer_subtract (divisor.coefficient)
					Result.coefficient.integer_quick_add_msd (1, Result.count)
				end
					-- Determine if division is done.
				inspect division_type
				when division_standard then
					done := (dividend.is_zero and then adjust >= 0) or else (Result.count = ctx.digits)
				else
					done := current_digit_exponent = 0
				end
					-- Prepare processing of next digit.
				if not done then
					Result.coefficient.shift_left (1)
					dividend.coefficient.shift_left (1)
					adjust := adjust + 1
					current_digit_exponent := current_digit_exponent - 1
				end
			end
			if impossible then
				Result.set_quiet_nan
				ctx.signal (Signal_invalid_operation, "Division impossible")
			else
				local_remainder := dividend
				inspect division_type
				when division_standard then
						-- Give some indications for rounding.
					if local_remainder.is_zero then
						if adjust < 0 then
								-- `Result' has been artificially rounded.
							ctx.signal (Signal_rounded, "Artificial rounding in division where remainder is zero")
						end
					else
						Result.coefficient.shift_left (1)
						adjust := adjust + 1
						divisor.coefficient.integer_subtract (local_remainder.coefficient)
						inspect divisor.coefficient.three_way_comparison (local_remainder.coefficient)
						when 0 then
								-- Half way: divisor - remainder = remainder <=> 2 * remainder = divisor
							Result.coefficient.put (5, 0)
						when 1 then
								-- Half way down: divisor - remainder > remainder <=> 2 * remainder < divisor
							Result.coefficient.put (4, 0)
						else
								-- Half way up: divisor - remainder < remainder <=> 2 remainder > divisor
							Result.coefficient.put (6, 0)
						end
					end
						-- Compute `exponent'.
					if dividend.is_zero then
						Result.set_exponent (original_dividend_exponent - (original_divisor_exponent + adjust))
					else
						Result.set_exponent (exponent - (original_divisor_exponent + adjust))
					end
				when division_integer then
					Result.set_exponent (0)
				else
					Result := local_remainder
						-- Correct value if necessary.
					if is_negative_exponent then
							-- Correct left_shift bias introduced in steps preparing division.
							-- Division has not occurred.
						create Result.make_copy (Current)
					else
						new_exponent := original_dividend_exponent.min (original_divisor_exponent)
						bias := new_exponent - (dividend.exponent.min (divisor.exponent))
						if Result.is_zero then
							if dividend_is_zero then
								new_exponent := original_dividend_exponent
							elseif new_exponent >= 0 then
								new_exponent := 0
							else
								new_exponent := exponent - (original_divisor_exponent + adjust)
							end
--						elseif divisor.adjusted_exponent >= 0 then
						else
								-- Real division.
							if bias /= 0 then
								Result.coefficient.shift_right (bias.abs)
							end
						end
						Result.set_exponent (new_exponent)
					end
				end
			end
		ensure
			divide_not_void: Result /= Void
		end

	do_rescale_special (ctx: DCM_MA_DECIMAL_CONTEXT)
			-- Rescale special numbers.
		require
			is_special: is_special
			not_constant_infinity: Current /= infinity
			not_constant_negative_infinity: Current /= negative_infinity
			not_constant_nan: Current /= nan
			not_constant_snan: Current /= snan
		do
			if is_quiet_nan then
					-- Do nothing.
			elseif is_signaling_nan then
				ctx.signal (Signal_invalid_operation, "sNaN as operand in rescale")
				set_quiet_nan
			elseif is_infinity then
					-- Do nothing.
			end
		end

	to_string_general (is_engineering: BOOLEAN): STRING
			-- `Current' as a number in engineering notation if `is_engineering'
			-- is True, in scientific notation otherwise.
		local
			str_coefficient: STRING
			str_zero_pad: STRING
			index, after_point_count, the_exponent, printed_exponent, exponent_difference: INTEGER
			digits_before_point: INTEGER
			exponential: BOOLEAN
		do
			create Result.make (0)
			if is_special then
				if is_quiet_nan then
					Result.append_string ("NaN")
				elseif is_signaling_nan then
					Result.append_string ("sNaN")
				else
					if is_negative then
						Result.append_string ("-")
					end
					Result.append_string ("Infinity")
				end
			else
					-- Coefficient conversion.
				if is_negative then
					Result.append_string ("-")
				end
				create str_coefficient.make (count)
				from
					index := count - 1
				until
					index < 0
				loop
					str_coefficient.append_character ((('0').code + coefficient.item (index)).to_character_8)
					index := index - 1
				end
					-- Determine if exponential notation shall be used.
				the_exponent := adjusted_exponent
				exponential := not (exponent <= 0 and then adjusted_exponent >= -6)
				if exponential then
					printed_exponent := the_exponent
					if is_engineering then
						from
						until
							printed_exponent \\ 3 = 0
						loop
							printed_exponent := printed_exponent - 1
						end
						exponent_difference := the_exponent - printed_exponent
						if not is_zero then
							digits_before_point := 1 + exponent_difference
							from
							until
								str_coefficient.count >= digits_before_point
							loop
								str_coefficient.append_character ('0')
							end
						else
							digits_before_point := 1
						end
					else
						digits_before_point := 1
					end
					if str_coefficient.count > digits_before_point then
						Result.append_string (str_coefficient.substring (1, digits_before_point))
						Result.append_character ('.')
						Result.append_string (str_coefficient.substring (digits_before_point + 1, str_coefficient.count))
					else
						Result.append_string (str_coefficient)
					end
					if printed_exponent /= 0 then
						Result.append_character ('E')
						if the_exponent < 0 then
							Result.append_character ('-')
						else
							Result.append_character ('+')
						end
						Result.append_string ((printed_exponent.abs).out)
					end
				else
					if exponent < 0 then
						after_point_count := exponent.abs
						if after_point_count > str_coefficient.count then
							create str_zero_pad.make_filled ('0', after_point_count - str_coefficient.count)
							Result.append_string ("0.")
							Result.append_string (str_zero_pad)
							Result.append_string (str_coefficient)
						elseif after_point_count = str_coefficient.count then
							Result.append_string ("0.")
							Result.append_string (str_coefficient)
						else
							Result.append_string (str_coefficient.substring (1, str_coefficient.count - after_point_count))
							Result.append_string (".")
							Result.append_string (str_coefficient.substring (str_coefficient.count - after_point_count + 1, str_coefficient.count))
						end
					else
						Result.append_string (str_coefficient)
					end
				end
			end
		ensure
			to_string_not_void: Result /= Void
		end

feature {NONE} -- Implementation

	parser: DCM_MA_DECIMAL_TEXT_PARSER
			-- Decimal text parser
		once
			create Result.make
		ensure
			parser_not_void: Result /= Void
		end

	once_zero: DECIMAL
			-- Shared Zero
		once
			create Result.make_zero
		ensure
			zero_not_void: Result /= Void
			is_zero: Result.is_zero
		end

	once_one: DECIMAL
			-- Shared One
		once
			create Result.make_one
		ensure
			one_not_void: Result /= Void
			is_one: Result.is_one
		end

	special_coefficient: DCM_MA_DECIMAL_COEFFICIENT
		once
			create {DCM_MA_DECIMAL_COEFFICIENT_IMP} Result.make (1)
			Result.put (0, 0)
		ensure
			special_coefficient_not_void: Result /= Void
			zero: Result.is_zero
		end

feature -- rounding

	round_to (n: INTEGER): DECIMAL
			-- round `current' to `n' decimal points
			-- using the context rounding menthod in the current context
		do
			Result := round_to_wrt_ctx (n, shared_decimal_context)
		ensure
			-- If n > 0 then the current is rounded to specified number of decimal places
			-- If n = 0 then number is rounded to the nearest integer
			-- If n < 0 then the number is rounded up to the left of the decimal point.
		end

	round_to_wrt_ctx (n: INTEGER; ctx: DCM_MA_DECIMAL_CONTEXT): DECIMAL
			-- round `current' to `n' decimal points
			-- using the context rounding menthod in the current context

		local
			j: INTEGER
			x, y: DECIMAL
		do

			if is_special then
				Result := "NaN"
			else
				if n = 0 then
					Result := round_to_integer (ctx)
				elseif n > 0 then
					if exponent = 0 and ((count + n) <= ctx.precision) then
						create x.make_copy (current)
						x.shift_left (n)
						Result := x
					elseif exponent = 0 and ((count + n) > ctx.precision) then
						create x.make_copy (current)
						x.shift_left (n)
						Result := x
					elseif exponent > 0 then
						if (count + exponent + n) > ctx.precision then
							create x.make_copy (current)
							x.shift_left (n* 2)
							Result := x
						else
							create x.make_copy (current)
							x.shift_left (exponent.abs + n)
							Result := x
						end
					else
						j := n * -1
						Result := rescale_decimal (j.out, ctx)
					end
				else
					if (count - no_digits_after_point) < n.abs then
						Result := "0"
					else
						create x.make_copy (current)

						if x.no_digits_after_point > 0 then
							x.shift_right (x.no_digits_after_point)
						end
						if x.coefficient.item (n.abs - 1) >= 5 then
							x.shift_right (n.abs)
							y := "1"
							y.set_exponent (n.abs)
							x := x + y
						else
							x.shift_right (n.abs)
						end

						x.shift_left (n.abs)
						x.strip_leading_zeroes
						Result := x
					end
				end
			end


		ensure
			-- If n > 0 then the current is rounded to specified number of decimal places
			-- If n = 0 then number is rounded to the nearest integer
			-- If n < 0 then the number is rounded up to the left of the decimal point.
		end

	ceiling: like Current

		require
			current_not_void: Current /= Void
			current_not_special: not is_special
		do
			Result := ceiling_wrt_ctx (shared_decimal_context)
		ensure
			result_an_int: Result.is_integer
		end

	ceiling_wrt_ctx (ctx: DCM_MA_DECIMAL_CONTEXT): like Current

		require
			ctx_not_void: ctx /= Void
			current_not_void: Current /= Void
			current_not_special: not is_special
		local
			ctx_local: DCM_MA_DECIMAL_CONTEXT
		do
			create ctx_local.make_default
			ctx_local.copy (ctx)
			ctx_local.set_rounding_mode (0)
			Result := round_to_integer (ctx_local)
		ensure
			result_an_int: Result.is_integer
		end

	floor: like Current

		require
			current_not_void: Current /= Void
			current_not_special: not is_special
		do
			Result := floor_wrt_ctx (shared_decimal_context)
		ensure
			result_an_int: Result.is_integer
		end

	floor_wrt_ctx (ctx: DCM_MA_DECIMAL_CONTEXT): like Current

		require
			ctx_not_void: ctx /= Void
			current_not_void: Current /= Void
			current_not_special: not is_special
		local
			ctx_local: DCM_MA_DECIMAL_CONTEXT
		do
			create ctx_local.make_default
			ctx_local.copy (ctx)
			ctx_local.set_rounding_mode (1)
			Result := round_to_integer (ctx_local)
		ensure
			result_an_int: Result.is_integer
		end

invariant

	special_values: special >= Special_none and then special <= Special_quiet_nan
	coefficient_not_void: coefficient /= Void
	special_share_coefficient: is_special implies coefficient = special_coefficient
	special_has_exponent_zero: is_special implies exponent = 0
	special_coefficient_is_zero: special_coefficient.is_zero

note
	copyright: "Copyright (c) SEL, York University, Toronto and others"
	license: "MIT license"
	details: "[
			Originally developed by Paul G. Crismer as part of Gobo. 
			Revised by Jocelyn Fiat for void safety.
			Revised by Jonathan Ostroff, Manu Stapf, Moksh Khurana, and Alex Fevga
			for full void safety and additional features such as
			approximately_equal
			log10(x)
			log2(x)
			sqrt(x)
			nth_root(x,y)
			round_to(n)
			exp(x) and the related power(x) are not yet working
		]"

end
