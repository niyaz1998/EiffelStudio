note
	description : "Objects used to evaluate a DBG_EXPRESSION ..."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	author      : "$Author$"
	date        : "$Date$"
	revision    : "$Revision$"

deferred class
	DBG_EXPRESSION_EVALUATOR

inherit
	COMPILER_EXPORTER

	DEBUGGER_COMPILER_UTILITIES

	SHARED_BENCH_NAMES
		export
			{NONE} all
		end

feature {NONE} -- Initialization

	make (dm: like debugger_manager; expr: like expression)
			-- Create Current from `expr'.
		require
			dm_not_void: dm /= Void
			expr_not_void: expr /= Void
		local
			ctx: DBG_EXPRESSION_CONTEXT
		do
			debugger_manager := dm

			initialize_dbg_error_handler

			debugger_manager.reset_dbg_evaluator
			get_dbg_evaluator

			expression := expr
			ctx := expr.context

			set_on_class (ctx.on_class)
			set_on_object (ctx.on_object)
			set_on_context (ctx.on_context)

			set_context_address (ctx.associated_address)
			set_context_class (ctx.associated_class)
		end

	initialize_dbg_error_handler
			-- Initialize error handler
		require
			dbg_error_handler_not_attached: dbg_error_handler = Void
		do
			create dbg_error_handler.make
		ensure
			dbg_error_handler_attached: dbg_error_handler /= Void
		end

	get_dbg_evaluator
			-- Get non void dbg_evaluator
		do
			if dbg_evaluator = Void then
				dbg_evaluator := debugger_manager.dbg_evaluator
			end
		end

feature -- Access

	expression: DBG_EXPRESSION
			-- Current expression to evaluate

	dbg_error_handler: DBG_ERROR_HANDLER
			-- Error handler

feature -- Status report

	error_occurred: BOOLEAN
			-- Error occurred?
		do
			Result := dbg_error_handler.error_occurred
		end

	expression_has_syntax_error: BOOLEAN
			-- has `expression' syntax error?
		do
			Result := expression.has_syntax_error
		end

	is_boolean_expression (f: FEATURE_I): BOOLEAN
			-- is feature `f' a boolean expression?
		require
			valid_f: f /= Void
			no_error: not expression_has_syntax_error
			good_state: f.written_class /= Void and then f.written_class.has_feature_table
		deferred
		end

	is_equal_evaluation_on_values (a_left, a_right: DBG_EVALUATED_VALUE): BOOLEAN
			-- Compare using `is_equal'
		require
			a_left_attached: a_left /= Void and then a_left.has_attached_value
			a_right_attached: a_right /= Void and then a_right.has_attached_value
		deferred
		end

	equal_evaluation_on_values (a_left, a_right: DBG_EVALUATED_VALUE): BOOLEAN
			-- Compare using ` = '
		require
			a_left_attached: a_left /= Void
			a_right_attached: a_right /= Void
		deferred
		end

feature {DBG_EXPRESSION_EVALUATION} -- Evaluation: Access

	final_result: DBG_EVALUATED_VALUE
			-- Final result of evaluation
			-- contains static_class, dynamic_class, dynamic_type, and value if any

feature -- Settings

	on_class: BOOLEAN
			-- Is the expression relative to a class ?

	on_object: BOOLEAN
			-- Is the expression relative to an object ?

	on_context: BOOLEAN
			-- Is the expression relative to a context ?	

	context_class_type: CLASS_TYPE
			-- Class related to the target, in on_object context

	context_class: CLASS_C
			-- Class related to the expression

	context_address: DBG_ADDRESS
			-- Object's address related to the expression	

	context_feature: FEATURE_I
			-- Feature associated to the context

	context_breakable_index: INTEGER
			-- Breakable index position

	context_bp_nested_index: INTEGER
			-- Breakable nested index position	

	context_object_test_locals: detachable LIST [TUPLE [id: ID_AS; type: TYPE_A]]
			-- Object test local info associated to the context

	side_effect_forbidden: BOOLEAN assign set_side_effect_forbidden
			-- Forbid potential side effect during evaluation?
			--| In practise, this mean, do we allow to evaluate routine?
			--| ie: non attribute, non once, ...
			--| For instance, for auto expression we don't want to evaluate
			--|   routine since it might have side effect,
			--|   and eventually put the debuggee in unstable state.


feature -- Change

	set_on_class (v: like on_class)
			-- set value of `on_class' with `v'
		do
			on_class := v
		end

	set_on_object (v: like on_object)
			-- set value of `on_object' with `v'	
		do
			on_object := v
		end

	set_on_context (v: like on_context)
			-- set value of `on_context' with `v'	
		do
			on_context := v
		end

	set_context_class (c: like context_class)
			-- set value of `context_class' with `c'
		do
			context_class := c
		end

	set_context_address (c: like context_address)
			-- set value of `context_address' with `c'
		do
			context_address := c
		end

	reset_error
			-- Reset error related data
		do
			dbg_error_handler.reset
		end

	set_side_effect_forbidden (b: like side_effect_forbidden)
			-- Set `side_effect_forbidden' with `b'
		do
			side_effect_forbidden := b
		end

feature {DBG_EXPRESSION_EVALUATION} -- Evaluation

	frozen evaluate (keep_assertion_checking: BOOLEAN)
			-- Compute the value of the last message of `Current'.
		require
			dbg_expression_valid_syntax: not expression.has_syntax_error
			running_and_stopped: application_is_stopped
		do
			initialize_evaluation
			process_evaluation (keep_assertion_checking)
		end

feature {NONE} -- Evaluation		

	initialize_evaluation
			-- Prepare Current for expression valuation
		do
			reset_error
			get_dbg_evaluator

				--| Clean evaluation.
			final_result := Void
		end

	process_evaluation (keep_assertion_checking: BOOLEAN)
		require
			dbg_evaluator_attached: dbg_evaluator /= Void
		deferred
		end

feature {DBG_EXPRESSION_EVALUATION} -- Implementation

	application_is_stopped: BOOLEAN
			-- Is application stopped?
		do
			Result := debugger_manager.safe_application_is_stopped
		end

	dump_value_at_address (addr: DBG_ADDRESS): DUMP_VALUE
			-- DUNP_VALUE object associated with object address `addr'
		require
			addr_attached: addr /= Void and then not addr.is_void
		do
			Result := dbg_evaluator.dump_value_at_address (addr)
		end

feature {NONE} -- Implementation

	debugger_manager: DEBUGGER_MANAGER
			-- Associated debugger manager.

	dbg_evaluator: DBG_EVALUATOR
			-- cached dbg evaluator		

invariant
	debugger_manager_attached: debugger_manager /= Void
	error_handler_initialized: dbg_error_handler /= Void and then dbg_error_handler.initialized

note
	copyright:	"Copyright (c) 1984-2009, Eiffel Software"
	license:	"GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options:	"http://www.eiffel.com/licensing"
	copying: "[
			This file is part of Eiffel Software's Eiffel Development Environment.
			
			Eiffel Software's Eiffel Development Environment is free
			software; you can redistribute it and/or modify it under
			the terms of the GNU General Public License as published
			by the Free Software Foundation, version 2 of the License
			(available at the URL listed under "license" above).
			
			Eiffel Software's Eiffel Development Environment is
			distributed in the hope that it will be useful, but
			WITHOUT ANY WARRANTY; without even the implied warranty
			of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
			See the GNU General Public License for more details.
			
			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Eiffel Development
			Environment; if not, write to the Free Software Foundation,
			Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
		]"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end -- class DBG_EXPRESSION_EVALUATOR
