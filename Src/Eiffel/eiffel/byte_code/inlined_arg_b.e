note
	legal: "See notice at end of class."
	status: "See notice at end of class."
class INLINED_ARG_B

inherit
	ARGUMENT_B
		redefine
			enlarged, propagate, analyze, generate,
			free_register, print_register, type,
			current_register, is_argument, print_checked_target_register
		end

feature -- Access

	type: TYPE_A
		do
			Result := System.remover.inliner.inlined_feature.argument_type (position)
		end

	enlarged: INLINED_ARG_B
		do
			Result := Current
		end

feature -- Status report

	is_argument: BOOLEAN = False
			-- Current should not be considered as an actual argument

feature -- Settings

	fill_from (a: ARGUMENT_B)
		do
			parent := a.parent;
			position := a.position
		end

feature -- Register and code generation

	Current_register: INLINED_CURRENT_B
		once
			create Result
		end

	propagate (r: REGISTRABLE)
			-- Do nothing
		do
		end;

	analyze
			-- Do nothing
		do
		end;

	generate
			-- Do nothing
		do
		end;

	free_register
			-- Do nothing
		do
		end;

	print_register
		local
			inlined_feature: INLINED_FEAT_B
			current_reg: REGISTRABLE
		do
				-- We need to go back to the caller's context to
				-- generate the argument as, if no temporary register
				-- is needed, calling `print_register' may have to
				-- evaluate types.

			inlined_feature := System.remover.inliner.inlined_feature

			current_reg := Context.inlined_current_register
			context.suspend_inline_context
			context.set_inlined_current_register (Void)

			inlined_feature.argument_regs.item (position).print_register

			context.resume_inline_context
			context.set_inlined_current_register (current_reg)
		end

feature {REGISTRABLE} -- C code generation

	print_checked_target_register
			-- <Precursor>
		local
			inlined_feature: INLINED_FEAT_B
			current_reg: REGISTRABLE
		do
				-- We need to go back to the caller's context to
				-- generate the argument as, if no temporary register
				-- is needed, calling `print_register' may have to
				-- evaluate types.

			inlined_feature := System.remover.inliner.inlined_feature

			current_reg := Context.inlined_current_register
			context.suspend_inline_context
			context.set_inlined_current_register (Void)

			inlined_feature.argument_regs.item (position).print_checked_target_register

			context.resume_inline_context
			context.set_inlined_current_register (current_reg)
		end

note
	copyright:	"Copyright (c) 1984-2016, Eiffel Software"
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

end
