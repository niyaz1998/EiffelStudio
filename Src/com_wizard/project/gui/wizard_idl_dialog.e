indexing 
	description: "WIZARD_IDL_DIALOG class created by Resource Bench."

class 
	WIZARD_IDL_DIALOG

inherit
	APPLICATION_IDS
		export
			{NONE} all
		end

	WIZARD_DIALOG
		redefine
			setup_dialog,
			on_ok
		end

creation
	make

feature {NONE} -- Initialization

	make (a_parent: WEL_COMPOSITE_WINDOW) is
			-- Create the dialog.
		require
			a_parent_not_void: a_parent /= Void
			a_parent_exists: a_parent.exists
		do
			make_by_id (a_parent, Wizard_idl_dialog_constant)
			create virtual_table_standard_radio.make_by_id (Current, Virtual_table_standard_radio_constant)
			create automation_radio.make_by_id (Current, Automation_radio_constant)
			create virtual_table_universal_radio.make_by_id (Current, Virtual_table_universal_radio_constant)
			create id_ok.make_by_id (Current, Idok)
			create id_back.make_by_id (Current, id_back_constant)
			create help_button.make_by_id (Current, Help_button_constant)
			help_topic_id := 735
			create id_cancel.make_by_id (Current, Idcancel)
		end

feature -- Behavior

	setup_dialog is
			-- Initialize radio buttons.
		do
			Precursor {WIZARD_DIALOG}
			uncheck_all
			if Shared_wizard_environment.automation then
				automation_radio.set_checked
			else
				if Shared_wizard_environment.use_universal_marshaller then
					virtual_table_universal_radio.set_checked
				else
					virtual_table_standard_radio.set_checked
				end
			end
		end

	on_ok is
			-- Process next button activation
		local
			a_file: RAW_FILE
		do
			Shared_wizard_environment.set_automation (automation_radio.checked)
			shared_wizard_environment.set_use_universal_marshaller (virtual_table_universal_radio.checked or automation_radio.checked)
			Precursor {WIZARD_DIALOG}
		end

feature -- Access

	automation_radio: WEL_RADIO_BUTTON
			-- Automation server type radio button

	virtual_table_standard_radio: WEL_RADIO_BUTTON
			-- Virtual Table and standard marshalling server type radio button

	virtual_table_universal_radio: WEL_RADIO_BUTTON
			-- Virtual Table and universal marshalling server type radio button

feature {NONE} -- Implementation

	uncheck_all is
			-- Uncheck all buttons.
		do
			automation_radio.set_unchecked
			virtual_table_standard_radio.set_unchecked
			virtual_table_universal_radio.set_unchecked
		end

end -- class WIZARD_IDL_DIALOG

--|-------------------------------------------------------------------
--| This class was automatically generated by Resource Bench
--| Copyright (C) 1996-1997, Interactive Software Engineering, Inc.
--|
--| 270 Storke Road, Suite 7, Goleta, CA 93117 USA
--| Telephone 805-685-1006
--| Fax 805-685-6869
--| Information e-mail <info@eiffel.com>
--| Customer support e-mail <support@eiffel.com>
--|-------------------------------------------------------------------
