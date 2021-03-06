note
	description: "Keys used to store initialization values"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	ECDS_REGISTRY_KEYS

feature -- Access

	Serializer_hive_path: STRING = "Software\ISE\Eiffel Codedom Provider\Serializer"
			-- Key containing serializer information

	Start_destination_folder_path_key: STRING = "StartDestinationFolder"
			-- Key containing default destination folder

	Wsdl_start_directory_key: STRING = "WSDLStartDirectory"
			-- Key containing default WSDL file folder

	Last_file_title_key: STRING = "LastFileTitle"
			-- Key containing last serialized file title

	Last_wsdl_url_key: STRING = "LastWSDLURL"
			-- Last wsdl URL

	Last_aspnet_url_key: STRING = "LastASPNETURL"
			-- Last ASP.NET URL

	X_key: STRING = "StartingX"
			-- Key containing default x

	Y_key: STRING = "StartingY";
			-- Key containing default y

note
	copyright:	"Copyright (c) 1984-2006, Eiffel Software"
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
			distributed in the hope that it will be useful,	but
			WITHOUT ANY WARRANTY; without even the implied warranty
			of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
			See the	GNU General Public License for more details.
			
			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Eiffel Development
			Environment; if not, write to the Free Software Foundation,
			Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA
		]"
	source: "[
			 Eiffel Software
			 356 Storke Road, Goleta, CA 93117 USA
			 Telephone 805-685-1006, Fax 805-685-6869
			 Website http://www.eiffel.com
			 Customer support http://support.eiffel.com
		]"
end -- class ECDS_REGISTRY_KEYS

