
--| Copyright (c) 1993-2006 University of Southern California and contributors.
--| All rights reserved.
--| Your use of this work is governed under the terms of the GNU General
--| Public License version 2.

class A
create
	default_create,
	make

feature
	make
   		do
   		end

	to_reference: A
		do
			create Result.make
		end
end
