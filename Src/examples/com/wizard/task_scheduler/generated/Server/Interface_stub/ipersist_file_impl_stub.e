note
	description: "Implemented `IPersistFile' interface."
	generator: "Automatically generated by the EiffelCOM Wizard."

class
	IPERSIST_FILE_IMPL_STUB

inherit
	IPERSIST_FILE_INTERFACE

	ECOM_STUB

feature -- Basic Operations

	get_class_id (p_class_id: ECOM_GUID)
			-- `p_class_id' [out].  
		do
			-- Put Implementation here.
		end

	is_dirty
			-- 
		do
			-- Put Implementation here.
		end

	load (psz_file_name: STRING; dw_mode: INTEGER)
			-- `psz_file_name' [in].  
			-- `dw_mode' [in].  
		do
			-- Put Implementation here.
		end

	save (psz_file_name: STRING; f_remember: INTEGER)
			-- `psz_file_name' [in].  
			-- `f_remember' [in].  
		do
			-- Put Implementation here.
		end

	save_completed (psz_file_name: STRING)
			-- `psz_file_name' [in].  
		do
			-- Put Implementation here.
		end

	get_cur_file (ppsz_file_name: CELL [STRING])
			-- `ppsz_file_name' [out].  
		do
			-- Put Implementation here.
		end

	create_item
			-- Initialize `item'
		do
			item := ccom_create_item (Current)
		end

feature {NONE}  -- Externals

	ccom_create_item (eif_object: IPERSIST_FILE_IMPL_STUB): POINTER
			-- Initialize `item'
		external
			"C++ [new ecom_MS_TaskSched_lib::IPersistFile_impl_stub %"ecom_MS_TaskSched_lib_IPersistFile_impl_stub.h%"](EIF_OBJECT)"
		end

end -- IPERSIST_FILE_IMPL_STUB


