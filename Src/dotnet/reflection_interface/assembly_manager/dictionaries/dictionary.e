indexing
	description: "Useful constants for assembly manager"
	external_name: "ISE.AssemblyManager.Dictionary"

class
	DICTIONARY

feature -- Access

	Assembly_manager_icon: SYSTEM_DRAWING_ICON is
		indexing
			description: "Icon appearing in dialogs header"
			external_name: "AssemblyManagerIcon"
		once
			create Result.make_icon (Assembly_manager_icon_filename)
		ensure
			icon_created: Result /= Void
		end

	Assembly_manager_icon_filename: STRING is "F:\Src\dotnet\reflection_interface\assembly_manager\icons\icon_dotnet_wizard_color.ico"
		indexing
			description: "Filename of icon appearing in dialogs header"
			external_name: "AssemblyManagerIconFilename"
		end
		
	Border_style: INTEGER is 3
			-- Window border style: a fixed, single line border
		indexing
			external_name: "BorderStyle"
		end
				
	Button_height: INTEGER is 27
			-- Button height
		indexing
			external_name: "ButtonHeight"
		end
		
	Button_width: INTEGER is 73
			-- Width of current buttons
		indexing
			external_name: "ButtonWidth"
		end

	Confirmation_caption: STRING is "Confirmation - ISE Assembly Manager"
		indexing
			description: "Caption for confirmation message boxes"
			external_name: "ConfirmationCaption"
		end
		
	Error_caption: STRING is "ERROR - ISE Assembly Manager"
		indexing
			description: "Caption for error message boxes"
			external_name: "ErrorCaption"
		end
	
	Error_icon: INTEGER is 16
		indexing
			description: "Icon for error message boxes"
			external_name: "ErrorIcon"
		end
		
	Font_family_name: STRING is "Verdana"
			-- Name of label font family
		indexing
			external_name: "FontFamilyName"
		end

	Font_size: REAL is 8.0
			-- Font size
		indexing
			external_name: "FontSize"
		end

	Information_caption: STRING is "Information - ISE Assembly Manager"
		indexing
			description: "Caption for information message boxes"
			external_name: "InformationCaption"
		end
		
	Information_icon: INTEGER is 64
		indexing
			description: "Icon for information message boxes"
			external_name: "InformationIcon"
		end
		
	Label_font_size: REAL is 10.0
			-- Label font size
		indexing
			external_name: "LabelFontSize"
		end

	Label_height: INTEGER is 20
			-- Label height
		indexing
			external_name: "LabelHeight"
		end
		
	Margin: INTEGER is 10
			-- Margin
		indexing
			external_name: "Margin"
		end

	Ok_cancel_message_box_buttons: INTEGER is 1
		indexing
			description: "OK and Cancel message box buttons"
			external_name: "OkCancelMessageBoxButtons"
		end
		
	Ok_message_box_button: INTEGER is 0
		indexing
			description: "OK message box button"
			external_name: "OkMessageBoxButton"
		end

	Question_caption: STRING is "Question - ISE Assembly Manager"
		indexing
			description: "Caption for question message boxes"
			external_name: "QuestionCaption"
		end
		
	Question_icon: INTEGER is 32
		indexing
			description: "Icon for question message boxes"
			external_name: "QuestionIcon"
		end
		
	Regular_style: INTEGER is 0
			-- Regular style
		indexing
			external_name: "RegularStyle"
		end

	System_event_handler_type: STRING is "System.EventHandler"
			-- System.EventHandler type
		indexing
			external_name: "SystemEventHandlerType"
		end

	Yes: INTEGER is 6
		indexing
			description: "Value in case user clicked on `Yes'"
			external_name: "Yes"
		end
		
	Yes_no_message_box_buttons: INTEGER is 4
		indexing
			description: "Yes/No message box buttons"
			external_name: "YesNoMessageBoxButtons"
		end
		
end -- class DICTIONARY