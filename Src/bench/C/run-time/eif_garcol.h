/*
--|----------------------------------------------------------------
--| Eiffel runtime header file
--| Copyright (C) 1985-2004 Eiffel Software. All rights reserved.
--| Duplication and distribution prohibited.  May be used only with
--| ISE Eiffel, under terms of user license.
--| Contact Eiffel Software for any other use.
--|
--| Interactive Software Engineering Inc.
--| dba Eiffel Software
--| 356 Storke Road, Goleta, CA 93117 USA
--| Telephone 805-685-1006, Fax 805-685-6869
--| Contact us at: http://www.eiffel.com/general/email.html
--| Customer support: http://support.eiffel.com
--| For latest info on our award winning products, visit:
--|     http://www.eiffel.com
--|----------------------------------------------------------------
*/

/*
	Declarations for garbage collector routines.
*/

#ifndef _eif_garcol_h_
#define _eif_garcol_h_

#include "eif_portable.h"
#include "eif_macros.h"
#include "eif_struct.h"
#ifndef TEST
#include "eif_plug.h"		/* Not wanted when runnning tests */
#endif

#include "eif_malloc.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifndef EIF_THREADS
#ifdef ISE_GC
RT_LNK struct stack loc_stack;	/* Local indirection stack */
RT_LNK struct stack loc_set;	/* Local variable stack */
#endif
RT_LNK struct stack once_set;	/* Once functions */
RT_LNK struct stack oms_set;	/* Once manifest strings */
#endif

/*
 * Eiffel flags -- edit with care.
 */
#define EO_MARK		0x80000000		/* Garbage collector's mark */
#define EO_TUPLE	0x40000000		/* Assertion loop control flag: in creation routine */
#define EO_DISP		0x20000000		/* Does object's associated class define `dispose' */
#define EO_AGE		0x1e000000		/* Object's age before immortality */
#define EO_SPEC		0x01000000		/* Object is special (C area) */
#define EO_REF		0x00800000		/* Special object is full of references */
#define EO_STORE	0x00400000		/* Mark for objects to be stored */
#define EO_OLD		0x00200000		/* Object belongs to the old generation */
#define EO_REM		0x00100000		/* Object belongs to the remembered set */
#define EO_NEW		0x00080000		/* Object is new, outside scavenge zone */
#define EO_C		0x00040000		/* Object is a C one (malloc'ed) */
#define EO_EXP		0x00020000		/* Object is an expanded one */
#define EO_COMP		0x00010000		/* Composite (has expanded or special) */
#define EO_TYPE		0x0000ffff		/* Mask to get the dynamic type */
#define EO_UPPER	0xffff0000		/* Mask to get upper half of flags */
#define EO_MOVED	(EO_NEW | EO_MARK)

/* Exported data-structure declarations */
RT_LNK EIF_REFERENCE root_obj;	/* Address of `root' object */	

/* General-purpose exported functions */
RT_LNK void plsc(void);					/* Partial scavenging */
RT_LNK void reclaim(void);				/* Reclaim all the objects */
RT_LNK int collect(void);				/* Generation-based collector */
#ifdef ISE_GC
RT_LNK void eremb(EIF_REFERENCE obj);				/* Remembers old object */
RT_LNK void erembq(EIF_REFERENCE obj);				/* Quick veersion (no GC call) of eremb */
#endif
RT_LNK char *onceset(void);				/* Recording of once function result */
RT_LNK void new_onceset(EIF_REFERENCE);				/* Recording of once function result */
#ifdef EIF_THREADS
RT_LNK void globalonceset(EIF_REFERENCE);			/* Recording of once function result */
#endif
RT_LNK void register_oms (EIF_REFERENCE *address);	/* Register an address of a once manifest string */
RT_LNK void gc_stop(void);				/* Stop the garbage collector */
RT_LNK void gc_run(void);				/* Restart the garbage collector */

#ifdef __cplusplus
}
#endif

#endif
