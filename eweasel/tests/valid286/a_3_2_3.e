class A_3_2_3

create
	make

feature {NONE} -- Creation
	
	make
			-- Run test.
		local
			t: like Current
		do
			f (8, 9)              -- VUAR(1)
			f (8, 1, 9)           -- VUAR(2) VUAR(2)
			f (8, 2, 3, 9)        -- VUAR(1)
			f (8, "a", 4, "b", 9) -- VUAR(1)
			t := Current                    
			t (8, 9)              -- VUAR(1)
			t (8, 1, 9)           -- VUAR(2) VUAR(2)
			t (8, 2, 3, 9)        -- VUAR(1)
			t (8, "a", 4, "b", 9) -- VUAR(1)
		end

feature

	f alias "()" (i: INTEGER; t1, t2: TUPLE)
		do
		end

end
