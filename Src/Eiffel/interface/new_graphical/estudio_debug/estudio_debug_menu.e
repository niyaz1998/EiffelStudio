note
	description: "Objects that represent the special debug menu for eStudio"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	ESTUDIO_DEBUG_MENU

inherit
	EV_MENU

	SYSTEM_CONSTANTS
		undefine
			default_create, is_equal, copy
		end

	EB_SHARED_WINDOW_MANAGER
		undefine
			default_create, is_equal, copy
		end

create
	make_with_window

feature {NONE} -- Initialization

	make_with_window (w: EV_WINDOW)
		do
			window := w
			default_create
			set_text (compiler_version_number.version)

			add_extension_set (create {ESTUDIO_DEBUG_EXTENSION_SET_STANDARD}.make (Current))
			add_extension_set (create {ESTUDIO_DEBUG_EXTENSION_SET_CUSTOM}.make (Current))
		end

	add_extension_set (a_ext_set: ESTUDIO_DEBUG_EXTENSION_SET)
		do
			if a_ext_set.is_valid then
				a_ext_set.attach_to_menu (Current)
			end
		end

	add_extension (a_ext: ESTUDIO_DEBUG_EXTENSION)
		do
			if a_ext.is_valid then
				a_ext.attach_to_menu (Current)
			end
		end

feature {ESTUDIO_DEBUG_EXTENSION} -- Access

	window: EV_WINDOW;
			-- Main development window.


note
	copyright: "Copyright (c) 1984-2010, Eiffel Software"
	license:   "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
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
