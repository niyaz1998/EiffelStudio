indexing 
	description: "DIALOG class created by Wel Wizard."

class 
	DIALOG

inherit
	WEL_MAIN_DIALOG

creation
	make

feature {NONE} -- Initialization

	make is
			-- Create the dialog.
		do
			make_by_name ("Hello World") -- <FL_DIALOG_NAME>)
			create ok_button.make (Current, "Ok", 10, 10, 10, 5, Idok)
			create cancel_button.make (Current, "Cancel", 30, 10, 10, 5, Idcancel)
		end

feature -- Access

	ok_button: WEL_PUSH_BUTTON
	cancel_button: WEL_PUSH_BUTTON
	
end -- class DIALOG

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
