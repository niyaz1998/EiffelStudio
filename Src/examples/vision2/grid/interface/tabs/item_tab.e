indexing
	description: "Objects that represent an EV_TITLED_WINDOW.%
		%The original version of this class was generated by EiffelBuild."
	date: "$Date$"
	revision: "$Revision$"

class
	ITEM_TAB

inherit
	ITEM_TAB_IMP

	GRID_ACCESSOR
		undefine
			copy, default_create, is_equal
		end

feature {NONE} -- Initialization

	user_initialization is
			-- Called by `initialize'.
			-- Any custom user initialization that
			-- could not be performed in `initialize',
			-- (due to regeneration of implementation class)
			-- can be added here.
		do
			item_finder.set_prompt ("Item Finder : ")
			item_finder.motion_actions.extend (agent finding_item)
		end

feature {NONE} -- Implementation

	found_item: EV_GRID_ITEM
	
	finding_item (an_item: EV_GRID_ITEM) is
			--
		local
			row_index, column_index: INTEGER
		do
			if an_item /= Void then
				if not item_frame.is_sensitive then
					item_frame.enable_sensitive
				end
				found_item := an_item
				row_index := found_item.row.index
				column_index := found_item.column.index
				item_x_index.change_actions.block
				item_x_index.set_value (column_index)
				item_x_index.change_actions.resume
				item_y_index.change_actions.block
				item_y_index.set_value (row_index)
				item_y_index.change_actions.resume
				update_item_data (column_index, row_index)
			else
				found_item := Void
				if item_frame.is_sensitive then
					item_frame.disable_sensitive
				end
			end
		end
	
	item_x_index_changed (a_value: INTEGER) is
			-- Called by `change_actions' of `item_x_index'.
		do
			--found_item := grid.item (a_value, item_y_index.value)
			update_item_data (a_value, item_y_index.value)
		end
	
	item_y_index_changed (a_value: INTEGER) is
			-- Called by `change_actions' of `item_y_index'.
		do
			--found_item := grid.item (item_x_index.value, a_value)
			update_item_data (item_x_index.value, a_value)
		end
		
	update_item_data (an_x, ay: INTEGER) is
			-- Display data for item at grid position `an_x', `a_y'.
		local
			textable: EV_TEXTABLE
			deselectable: EV_DESELECTABLE
		do
			if found_item /= Void then
				main_box.enable_sensitive
				textable ?= found_item
				if textable /= Void then
					textable_frame.enable_sensitive
					textable_entry.change_actions.block
					textable_entry.set_text (textable.text)
					textable_entry.change_actions.resume
				else
					textable_frame.disable_sensitive
				end
				deselectable ?= found_item
				if deselectable /= Void then
					selectable_frame.enable_sensitive
					is_selected.select_actions.block
					if deselectable.is_selected then
						is_selected.enable_select
					else
						is_selected.disable_select
					end
					is_selected.select_actions.resume
				else
					selectable_frame.disable_sensitive
				end
			else
				main_box.disable_sensitive
			end
		end
		
	textable_entry_changed is
			-- Called by `change_actions' of `textable_entry'.
		local
			textable: EV_TEXTABLE
		do
			textable ?= found_item
			if textable /= Void then
				textable.set_text (textable_entry.text)
			end
		end
		
	is_selected_selected is
			-- Called by `select_actions' of `is_selected'.
		local
			deselectable: EV_DESELECTABLE
		do
			deselectable ?= found_item
			if deselectable /= Void then
				if deselectable.is_selected then
					deselectable.enable_select
				else
					deselectable.enable_select
				end
			end
		end
		
	remove_item_button_selected is
			-- Called by `select_actions' of `remove_item_button'.
		do
			grid.remove_item (found_item.column.index, found_item.row.index)
			update_item_data (item_x_index.value, item_y_index.value)
		end

end -- class ITEM_TAB

