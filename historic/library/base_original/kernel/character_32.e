note
	description: "Unicode characters, with comparison operations"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	assembly: "mscorlib"
	external_name: "System.UInt32"
	date: "$Date$"
	revision: "$Revision$"

frozen expanded class
	CHARACTER_32

inherit
	WIDE_CHARACTER_REF

create
	default_create,
	make_from_reference

convert
	make_from_reference ({WIDE_CHARACTER_REF})

note
	library:	"EiffelBase: Library of reusable components for Eiffel."
	copyright:	"Copyright (c) 1984-2006, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			 Eiffel Software
			 356 Storke Road, Goleta, CA 93117 USA
			 Telephone 805-685-1006, Fax 805-685-6869
			 Website http://www.eiffel.com
			 Customer support http://support.eiffel.com
		]"

end
