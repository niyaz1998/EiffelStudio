note
	legal: "See notice at end of class."
	status: "See notice at end of class."
-- Table recording all the derivations of all the generic classes indexed by class id

class
	DERIVATIONS

inherit
	HASH_TABLE [FILTER_LIST, INTEGER]

	COMPILER_EXPORTER
		undefine
			is_equal, copy
		end

create
	make

feature

	has_derivation (an_id: INTEGER; a_type: CL_TYPE_A): BOOLEAN
		local
			derivations: FILTER_LIST;
		do
			derivations := item (an_id)
			if derivations /= Void then
					-- Only add generic derivations for type except
					-- TUPLE that doesn't require any generic derivations.
				Result := attached {TUPLE_TYPE_A} a_type or else derivations.has_item (a_type)
			end;
		end;

	insert_derivation (an_id: INTEGER; a_type: CL_TYPE_A)
		local
			derivations: FILTER_LIST;
		do
			derivations := item (an_id);
			if derivations = Void then
				create derivations.make;
				put (derivations, an_id);
			end;

				-- Do not add any TUPLE derivations
			if not attached {TUPLE_TYPE_A} a_type then
				derivations.put (a_type);
			end
		end;

note
	copyright:	"Copyright (c) 1984-2015, Eiffel Software"
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
