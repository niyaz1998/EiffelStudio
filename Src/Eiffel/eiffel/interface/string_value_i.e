note
	description: "Description of a manifest string constant."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	STRING_VALUE_I

inherit
	VALUE_I
		rename
			string_value as internal_string_value
		redefine
			is_string, append_signature, is_propagation_equivalent,
			internal_string_value, set_real_type
		end

	SHARED_WORKBENCH
		export
			{NONE} all
		end

	CHARACTER_ROUTINES
		export
			{NONE} all
		end

create
	make

feature {NONE} -- Initialization

	make (s: STRING; is_dotnet: BOOLEAN)
			-- Set `string_value' with `s'.
			-- Set `is_dotnet_string' with `is_dotnet'.
		require
			s_not_void: s /= Void
		do
			string_value := s
			is_dotnet_string := is_dotnet
		ensure
			string_value_set: string_value = s
			is_dotnet_string_set: is_dotnet_string = is_dotnet
		end

feature -- Comparison

	is_equivalent (other: like Current): BOOLEAN
			-- Is `other' equivalent to the current object ?
		do
			Result := string_value.is_equal (other.string_value)
		end

	is_propagation_equivalent (other: like Current): BOOLEAN
			-- Is `Current' equivalent for propagation of pass2/pass3?
		do
			Result := True
		end

feature -- Access

	string_value: STRING
			-- Integer constant value

feature -- Status Report

	is_dotnet_string: BOOLEAN
			-- Is current a manifest System.String constant?

	is_string: BOOLEAN = True
			-- Is the current constant a string one ?

	valid_type (t: TYPE_A): BOOLEAN
			-- Is the current value compatible with `t' ?
		local
			class_type: CL_TYPE_A
		do
			class_type ?= t
			Result := class_type /= Void and then
				(class_type.class_id = System.string_8_id or
				class_type.class_id = system_string_id)
		end

	internal_string_value: STRING
		do
			Result := eiffel_string (string_value)
		end

feature -- Settings

	set_real_type (t: CL_TYPE_A)
			-- Extract type and set `is_dotnet_string' accordingly.
		local
			l_cl_type: CL_TYPE_A
		do
			l_cl_type ?= t
			if l_cl_type /= Void then
				is_dotnet_string := l_cl_type.class_id = system_string_id
			end
		end

feature -- Code generation

	generate (buffer: GENERATION_BUFFER)
			-- Generate value in `buffer'.
		do
			buffer.put_string ({C_CONST}.rtms_ex_h)
			buffer.put_character ('(')
			buffer.put_string_literal (string_value)
			buffer.put_character (',')
			buffer.put_integer (string_value.count)
			buffer.put_character (',')
			buffer.put_integer (string_value.hash_code)
			buffer.put_character (')')
		end

	generate_il
			-- Generate IL code for string constant value.
		do
			if is_dotnet_string then
				il_generator.put_system_string (string_value)
			else
				il_generator.put_manifest_string (string_value)
			end
		end

	make_byte_code (ba: BYTE_ARRAY)
			-- Generate byte code for a string constant value.
		do
			ba.append (Bc_string)
			ba.append_integer (string_value.count)
			ba.append_raw_string (string_value)
		end

	dump: STRING
		do
			create Result.make (string_value.count + 2)
			Result.extend ('"')
			Result.append (string_value)
			Result.extend ('"')
		end

	append_signature (a_text_formatter: TEXT_FORMATTER)
		do
			a_text_formatter.add_char ('"')
			a_text_formatter.add_manifest_string (eiffel_string (string_value))
			a_text_formatter.add_char ('"')
		end

feature {NONE} -- Implementation

	system_string_id: INTEGER
			-- ID of SYSTEM_STRING if we are in IL code generation
			-- Otherwise, -1 (to avoid conflicts with basic type
			-- that have a class_id of 0).
		once
			if System.system_string_class /= Void and System.system_string_class.is_compiled then
				Result := System.system_string_id
			else
				Result := -1
			end
		end

note
	copyright:	"Copyright (c) 1984-2010, Eiffel Software"
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
