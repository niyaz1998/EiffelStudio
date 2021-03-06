/*
indexing
	description: "EiffelCOM: library of reusable components for COM."
	copyright:	"Copyright (c) 1984-2006, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			 Eiffel Software
			 356 Storke Road, Goleta, CA 93117 USA
			 Telephone 805-685-1006, Fax 805-685-6869
			 Website http://www.eiffel.com
			 Customer support http://support.eiffel.com
		]"
*/

#ifndef __ECOM_E_SAFE_ARRAY_BOUND_H_INC__
#define __ECOM_E_SAFE_ARRAY_BOUND_H_INC__

#include <oaidl.h>

#define ccom_safearraybound_elements(_ptr_) ((EIF_INTEGER) (((SAFEARRAYBOUND*)_ptr_)->cElements))
#define ccom_safearraybound_low_bound(_ptr_) ((EIF_INTEGER) (((SAFEARRAYBOUND*)_ptr_)->lLbound))

#define ccom_safearraybound_set_elements(_ptr_, _value_) ((((SAFEARRAYBOUND*)_ptr_)->cElements)=(ULONG)(_value_))
#define ccom_safearraybound_set_low_bound(_ptr_, _value_) ((((SAFEARRAYBOUND*)_ptr_)->lLbound)=(LONG)(_value_))

#endif // !__ECOM_E_SAFE_ARRAY_BOUND_H_INC__
