indexing
	description: "Error Handling"
	date: "$Date$"
	revision: "$Revision$"

class
	CGI_ERROR_HANDLING
	
inherit
	CGI_IN_AND_OUT

	EXCEPTIONS
		export
			{NONE} all
		end

feature -- Basic Operations

	handle_exception is
			-- General exception hanlding.
		local
			msg: STRING
		do
			if raised_error /= Void then
				msg := raised_error
			else
				msg := ""
			end
			response_header.send_trace (msg + exception_trace)
		end

	raise_error(msg: STRING) is
			-- Raise an error
		require
			message_exists: msg /= Void
		do
			raised_error := msg
			handle_exception
		ensure
			exists: raised_error /= Void
		end

feature {CGI_ERROR_HANDLING} -- Access

		raised_error: STRING
			-- Error explicitely raised by developer code.

end -- class CGI_ERROR_HANDLING
