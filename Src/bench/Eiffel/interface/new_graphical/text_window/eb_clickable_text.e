indexing
	description: "EiffelBench notion of a clikable text"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	EB_CLICKABLE_TEXT
inherit
	EB_TEXT_STRUCTURE
		rename
			position as struct_position
		end

	EB_FORMATTED_TEXT
		export
			{ANY} process_text
		undefine
			copy, is_equal
		redefine
			put_address, put_feature_name, put_feature,
			put_error, put_class, put_after_class, put_classi, put_cluster,
			put_class_syntax, put_ace_syntax, process_breakpoint, 
			process_padded, disable_clicking, update_clickable_from_stone,
			put_operator, process_column_text, process_call_stack_item,
			put_feature_error, put_exported_feature_name
		end

	EB_GRAPHICAL_DATA
		undefine
			is_equal, copy
		end

	NEW_EB_CONSTANTS
		undefine
			is_equal, copy
		end

feature -- Properties

	focus_start, focus_end: INTEGER 
			-- Bounds of focus in the structured text

	changed: BOOLEAN
			-- Has the text been edited since last display?

feature -- Access

	focus: STONE is
			-- The stone where the focus currently is.
		do
			if struct_position > 0 and then struct_position <= clickable_count then
				Result := item (struct_position).node
			end
		end

feature -- Settings

	set_bounds (a, b: INTEGER) is
			-- Set the bounds of current focus.
		do
			focus_start := a
			focus_end := b
		ensure
			focus_start = a
			focus_end = b
		end

feature -- Input

	put_after_class (e_class: CLASS_C str: STRING) is
			-- Put "-- class" followed by `t' in the text.
		local
			class_stone: CLASSC_STONE
		do
			append_string (" -- class ")
			create class_stone.make (e_class)
			set_format (Graphical_resources.class_text)
			append_stone (class_stone, e_class.name_in_upper)
			new_line
		end

	put_operator (str: STRING e_feature: E_FEATURE; is_keyword: BOOLEAN) is
		   -- Process operator text.
		local
			stone: FEATURE_STONE	
		do
			create stone.make (e_feature)
			set_format (Graphical_resources.keyword_text)
			append_stone (stone, str)
		end

	put_string (s: STRING) is
			-- Add `s' to the text, don't record it in internal structure.
		do
			set_format (Graphical_resources.string_text)
			append_text (s)
			text_position := text_position + s.count
		end

	put_char (c: CHARACTER) is
			-- Add `c' to the text image, don't record it in internal structure.
		do
			io.putstring ("ERROR: putchar used")
--			append_text (c)
--			text_position := text_position + 1
		end

	new_line is
		do
			append_text ("%N")
			text_position := text_position + 1
		end

	put_classi (e_class: CLASS_I str: STRING) is
			-- Put `e_class' with string representation
			-- `str' at current position.
		local
			stone: CLASSI_STONE	
		do
			create stone.make (e_class)
			set_format (Graphical_resources.keyword_text)			
			append_stone (stone, str)
		end

	put_cluster (e_cluster: CLUSTER_I str: STRING) is
			-- Put `e_cluster' with string representation
			-- `str' at current position.
		do
			set_format (Graphical_resources.cluster_text)			
			put_string (str)
		end

	put_class (e_class: CLASS_C str: STRING) is
			-- Put `e_class' with string representation
			-- `str' at current position.
		local
			stone: CLASSC_STONE	
		do
			create stone.make (e_class)
			set_format (Graphical_resources.class_text)			
			append_stone (stone, str)
		end

	put_error (error: ERROR str: STRING) is
			-- Put `error' with string representation
			-- `str' at current position.
		local
			stone: ERROR_STONE	
		do
			create stone.make (error)
			set_format (Graphical_resources.error_text)			
			append_stone (stone, str)
		end

	put_feature (feat: E_FEATURE str: STRING) is
			-- Put feature `feat' with string
			-- representation `str' at current position.
		local
			stone: FEATURE_STONE	
		do
			create stone.make (feat)
			set_format (Graphical_resources.feature_text)			
			append_stone (stone, str)
		end

	put_feature_error (feat: E_FEATURE str: STRING; a_pos: INTEGER) is
			-- Put feature `feat' with string
			-- representation `str' at current position.
		local
			stone: FEATURE_ERROR_STONE	
		do
			create stone.make (feat, a_pos)
			set_format (Graphical_resources.feature_text)			
			append_stone (stone, str)
		end

	put_feature_name (f_name: STRING e_class: CLASS_C) is
			-- Put feature name `f_name' defined in `e_class'.
		local
			stone: FEATURE_NAME_STONE	
		do
			create stone.make (f_name, e_class)
			set_format (Graphical_resources.feature_text)			
			append_stone (stone, f_name)
		end

	put_exported_feature_name (f_name: STRING; class_c: CLASS_C; alias_name: STRING) is
		local
			stone: EXPORTED_FEATURE_NAME_STONE	
		do
			create stone.make (f_name, class_c, alias_name)
			set_format (Graphical_resources.feature_text)			
			append_stone (stone, f_name)
		end

	put_address (address: STRING a_name: STRING; e_class: CLASS_C) is
			-- Put `address' with `a_name' for `e_class'.
		local
			stone: OBJECT_STONE	
		do
			create stone.make (address, a_name, e_class)
			set_format (Graphical_resources.object_text)			
			append_stone (stone, address)
		end

	put_class_syntax (syn: SYNTAX_ERROR e_class: CLASS_C; str: STRING) is
			-- Put `address' for `e_class'.
		local
			stone: CL_SYNTAX_STONE	
		do
			create stone.make (syn, e_class)
			set_format (Graphical_resources.class_text)			
			append_stone (stone, str)
		end

	put_ace_syntax (syn: SYNTAX_ERROR str: STRING) is
			-- Put `address' for `e_class'.
		local
			stone: ACE_SYNTAX_STONE	
		do
			create stone.make (syn)
			set_format (Graphical_resources.class_text)			
			append_stone (stone, str)
		end

feature -- Processing for text_struct

	process_padded is
			-- Process padded spaces in place of breakpoints.
		do
			append_string ("   ")
		end

	process_breakpoint (a_bp: BREAKPOINT_ITEM) is
			-- Put a 'break stone' in the text.
		local
			breakable_stone: BREAKABLE_STONE
			debug_mark: STRING
			click_break: CLICK_BREAKABLE
		do
			create breakable_stone.make (a_bp.e_feature, a_bp.index)
			if a_bp.display_number then
				append_stone (breakable_stone, a_bp.index.out)
			else
				append_string (" ")
				create breakable_stone.make (a_bp.e_feature, a_bp.index)
				create click_break.make (breakable_stone,
						text_position, text_position + 3)
				add_click_stone (click_break)
				text_position := text_position + 3
				append_text (breakable_stone.sign)
				append_string (" ")
			end
		end

	process_column_text (t: COLUMN_TEXT) is
			-- Process `text'.
		local
			last_pos: INTEGER
			str: STRING
		do
			last_pos := text_position - current_line_pos.item
			create str.make (t.number_of_blanks (last_pos))
			str.fill_blank
			append_string (str)
		end

	process_call_stack_item (t: CALL_STACK_ITEM) is
			-- Process the current callstack text.
		local
			stone: CALL_STACK_STONE
			ln: INTEGER
		do
			ln := t.level_number
			if ln > 0 then
				create stone.make (ln)
				append_stone (stone, t.image)
			else
				append_string (t.image)
			end
			current_line_pos.set_item (text_position)
		end

feature -- Update

	update_clickable_from_stone (a_stone: STONE) is
			-- Update the clickable information from tool's stone.
			-- click list if text uses character position.
		local
			c_list: ARRAY [CLICK_STONE]
		do
			c_list := a_stone.click_list
			if c_list /= Void then
				share (c_list)
			end
		end

	update_focus (i: INTEGER) is
			-- Select the stone corresponding to text position `i'.
		do
			if clickable_count /= 0 then
				search_by_index (i)
				set_bounds (item (struct_position).start_position, item (struct_position).end_position)
			end
		end

	disable_clicking is
			-- Disable the drag and drop mechanism.
		do
			clear_clickable
			set_changed (False)
		end

feature -- Breakpoint update

	highlight_breakable (f: E_FEATURE index: INTEGER) is
			-- Highlight the line containing the `index'-th breakable point.
		local
			cb: CLICK_BREAKABLE
		do
			cb := breakable_for (f, index)
			if index >= 1 and cb /= Void then
				set_bounds (cb.start_position, cb.end_position)
				highlight_focus
			end
		end

	highlight_focus is
			-- Highlight focus (using reverse video) on the screen 
			-- from `focus_start' to `focus_end'.
			-- Put cursor on the focus if not already done.
		do
			highlight_selected (focus_start, focus_end)
			set_position (focus_start)
		end

feature {NONE} -- Implementation

	text_position: INTEGER
			-- Current position in the structured document text

	breakable_for (f: E_FEATURE index: INTEGER): CLICK_BREAKABLE is
			-- Breakable stone for `f' with index `index'
		local
			cb: CLICK_BREAKABLE
			b: BREAKABLE_STONE
			bid: BODY_ID
			found: BOOLEAN
			i: INTEGER
			local_copy: like Current
		do
			from
				bid := f.body_id
				local_copy := Current
				i := 1
			until
				i > count or else found
			loop
				cb ?= local_copy.item (i)
				if cb /= Void then
					b := cb.breakable
					found := (bid.is_equal (b.routine.body_id) and then b.index = index)
				end
				i := i + 1
			end
			if found then
				Result := cb
			end
		end

	append_stone (a_stone: STONE stone_string: STRING) is
			-- Add `stone_string' to the text and 
			-- record `a_stone' as clickable.
		local
			p: CLICK_STONE
			length: INTEGER
		do
			append_text (stone_string)
			length := stone_string.count
			create p.make (a_stone, text_position, text_position + length)
			add_click_stone (p)
			text_position := text_position + length
		end

	append_string (s: STRING) is
			-- Add non processed text `s' to the text.
			-- Note: `put_string' is called as a result from the processing
			-- of TEXT_ITEMS whereas `append_string' is not. The reason
			-- this was done so that the descendant class GRAPHICAL_TEXT_WINDOWS
			-- for windows can redefine `put_string' to set a specific 
			-- character format where `append_string' does not.
		do
			append_text (s)
			text_position := text_position + s.count
		end

	append_text (s: STRING) is
			-- appends `s' to the text.
		deferred
		end

	set_format (fr: EB_FORMAT_RESOURCE) is
			-- changes current format according to `fr'
		deferred
		end

	current_line_pos: INTEGER_REF is
			-- Current position in line for callstack
		once
			create Result
		end

end -- class EB_CLICKABLE_TEXT
