indexing
	description: "Objects that represent an EV_DIALOG.%
		%The original version of this class was generated by EiffelBuild."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	GB_SYSTEM_WINDOW

inherit
	GB_SYSTEM_WINDOW_IMP
	
	GB_SHARED_COMMAND_HANDLER
		export
			{NONE} all
		end
		
	GB_SHARED_SYSTEM_STATUS
		undefine
			default_create, copy, is_equal
		end
		
	GB_NAMING_UTILITIES
		undefine
			default_create, copy, is_equal
		end
		
	GB_CONSTANTS
		undefine
			default_create, copy, is_equal
		end
		
	EIFFEL_RESERVED_WORDS
		export
			{NONE} all
		undefine
			default_create, copy, is_equal
		end
		
	GB_SHARED_TOOLS
		export
			{NONE} all
		undefine
			default_create, copy, is_equal
		end
		
feature {NONE} -- Initialization

	user_initialization is
			-- called by `initialize'.
			-- Any custom user initialization that
			-- could not be performed in `initialize',
			-- (due to regeneration of implementation class)
			-- can be added here.
		do
			display_project_information
				-- Set up default buttons.
			set_default_cancel_button (cancel_button)
			
				-- Closing window
			close_request_actions.wipe_out
			close_request_actions.put_front (agent cancel_pressed)
		end

feature {NONE} -- Events

	
	class_build_type_selected is
			-- Called by `select_actions' of `project_radio_button'.
		do
			rebuild_ace_file_check_button.disable_sensitive
			class_naming_frame.disable_sensitive
		end


	project_build_type_selected is
			-- Called by `select_actions' of `class_radio_button'.
		do
			rebuild_ace_file_check_button.enable_sensitive
			class_naming_frame.enable_sensitive
		end


	ok_pressed is
			-- Called by `select_actions' of `ok_button'.
		do
			validate_settings
			if last_validation_successful then
					-- Store the settings into the current project
					-- settings.
				store_project_information
					-- Save the current project settings to disk.
				system_status.current_project_settings.save
				hide
			end
			command_handler.update
		end


	cancel_pressed is
			-- Called by `select_actions' of `cancel_button'.
		do
			hide
			command_handler.update
		end
		
feature {NONE} -- Implementation

	display_project_information is
			-- Update all members of `tab_list' to display
			-- details held in project currently being developed
			-- in the system.
		require else
			project_open: system_status.project_open
		do
				-- Firstly displaying the project location.
			location_field.set_text (project_settings.project_location)
			location_field.set_tooltip ("%"" + location_field.text + "%" (This entry is the location of the project, and may not be modified)")
			
				-- Then display all information for "Build" tab.
			application_class_name_field.set_text (project_settings.application_class_name)
			project_class_name_field.set_text (project_settings.project_name)
			if project_settings.complete_project then
				project_radio_button.enable_select
			else
				class_radio_button.enable_select
			end
			if project_settings.rebuild_ace_file then
				rebuild_ace_file_check_button.enable_select
			else
				rebuild_ace_file_check_button.disable_select
			end
			
				-- Then display all information for "Generation" tab
			if project_settings.grouped_locals then
				local_check_button.enable_select
			else
				local_check_button.disable_select
			end
			if project_settings.debugging_output then
				debugging_check_button.enable_select
			else
				debugging_check_button.disable_select
			end
			if project_settings.attributes_local then
				attributes_local_check_button.enable_select
			else
				attributes_local_check_button.disable_select
			end
			if project_settings.client_of_window then
				client_check_button.enable_select
			else
				client_check_button.disable_select
			end
			if project_settings.load_constants then
				load_constants_check_button.enable_select
			else
				load_constants_check_button.disable_select
			end
		end
		
	store_project_information is
			-- Update project settings to reflect information
			-- entered into `Current'.
		require
			project_open: system_status.project_open
		do
				-- Firstly stors all information from "Build" tab.
				--	project_settings.set_main_window_class_name (main_window_class_name_field.text.as_upper)
			project_settings.set_application_class_name (application_class_name_field.text.as_upper)
			project_settings.set_project_name (project_class_name_field.text)
			if project_radio_button.is_selected then
				project_settings.enable_complete_project
			else
				project_settings.disable_complete_project
			end
			if rebuild_ace_file_check_button.is_selected then
				project_settings.enable_rebuild_ace_file
			else
				project_settings.disable_rebuild_ace_file
			end
			
				-- Now store all information from "Generation" tab.
			if local_check_button.is_selected then
				project_settings.enable_grouped_locals
			else
				project_settings.disable_grouped_locals
			end
			if debugging_check_button.is_selected then
				project_settings.enable_debugging_output
			else
				project_settings.disable_debugging_output
			end
			if attributes_local_check_button.is_selected then
				project_settings.enable_attributes_local
			else
				project_settings.disable_attributes_local
			end
			if client_check_button.is_selected then
				project_settings.enable_client_of_window
			else
				project_settings.disable_client_of_window
			end
			if load_constants_check_button.is_selected then
				project_settings.enable_constant_loading
			else
				project_settings.disable_constant_loading
			end
		end

	validate_settings is
			--
		local
			warning_dialog: EV_WARNING_DIALOG
			application_name_lower, class_name_lower, project_name_lower,
			invalid_text, warning_message: STRING
		do
					-- Check for invalid eiffel names as language specification.
			last_validation_successful := True
			application_name_lower := application_class_name_field.text.as_lower
			project_name_lower := project_class_name_field.text.as_lower
			if not valid_class_name (application_name_lower) then
				invalid_text := application_name_lower
			elseif not valid_class_name (project_name_lower) then
				invalid_text := project_name_lower
			end
			if invalid_text /= Void then
				warning_message := Class_invalid_name_warning
			else
				warning_message := Reserved_word_warning
			end
				-- Check for names that are Eiffel reserved words.
			if reserved_words.has (application_name_lower) then
				invalid_text := application_name_lower
			elseif reserved_words.has (class_name_lower) then
				invalid_text := class_name_lower
			elseif reserved_words.has (project_name_lower) then
				invalid_text := project_name_lower
			end
			if invalid_text /= Void then
			--	select_in_parent
				create warning_dialog.make_with_text ("'" + invalid_text + warning_message)
				warning_dialog.show_modal_to_window (main_window)
				last_validation_successful := False				
			end
		end
		
	last_validation_successful: BOOLEAN
		-- Was last call to `validate_settings' succesful?
		-- True if all valication succeeded.
		
	project_settings: GB_PROJECT_SETTINGS is
			-- `Result' is access to current project settings.
		do
			Result := System_status.current_project_settings
		end
		
	

end -- class GB_SYSTEM_WINDOW

