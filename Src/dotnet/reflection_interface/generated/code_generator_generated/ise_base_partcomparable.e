indexing
	generator: "Eiffel Emitter 2.8b2"
	external_name: "ISE.Base.PartComparable"
	assembly: "ISE.Reflection.CodeGenerator", "0.0.0.0", "neutral", "7626a3824bcc2b68"

deferred external class
	ISE_BASE_PARTCOMPARABLE

inherit
	ANY
		undefine
			finalize,
			get_hash_code,
			equals,
			to_string
		end

feature -- Basic Operations

	a_infix_ge (other: ISE_BASE_PARTCOMPARABLE): BOOLEAN is
		external
			"IL deferred signature (ISE.Base.PartComparable): System.Boolean use ISE.Base.PartComparable"
		alias
			"_infix_ge"
		end

	a_infix_lt (other: ISE_BASE_PARTCOMPARABLE): BOOLEAN is
		external
			"IL deferred signature (ISE.Base.PartComparable): System.Boolean use ISE.Base.PartComparable"
		alias
			"_infix_lt"
		end

	a_infix_gt (other: ISE_BASE_PARTCOMPARABLE): BOOLEAN is
		external
			"IL deferred signature (ISE.Base.PartComparable): System.Boolean use ISE.Base.PartComparable"
		alias
			"_infix_gt"
		end

	a_infix_le (other: ISE_BASE_PARTCOMPARABLE): BOOLEAN is
		external
			"IL deferred signature (ISE.Base.PartComparable): System.Boolean use ISE.Base.PartComparable"
		alias
			"_infix_le"
		end

end -- class ISE_BASE_PARTCOMPARABLE
