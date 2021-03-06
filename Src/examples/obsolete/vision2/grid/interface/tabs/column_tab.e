note
	description: "Objects that represent an EV_TITLED_WINDOW.%
		%The original version of this class was generated by EiffelBuild."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	COLUMN_TAB

inherit
	COLUMN_TAB_IMP
	
	GRID_ACCESSOR
		undefine
			copy, default_create, is_equal
		end


feature {NONE} -- Initialization

	user_initialization
			-- Called by `initialize'.
			-- Any custom user initialization that
			-- could not be performed in `initialize',
			-- (due to regeneration of implementation class)
			-- can be added here.
		do
			current_column_index := 1
			column_finder.set_prompt ("Column Finder : ")
			column_finder.motion_actions.extend (agent column_motion)
			move_to_column_finder.motion_actions.extend (agent move_to_column_motion)
			move_to_column_finder.set_prompt ("Locate Column : ")
			add_default_colors_to_combo (foreground_color_combo)
			add_default_colors_to_combo (background_color_combo)
			add_default_pixmaps_to_combo (column_pixmap_combo)
		end

feature {NONE} -- Implementation

	current_column_index: INTEGER
			-- Current index of column for property change.

	column_index_changed (a_value: INTEGER)
			-- Called by `change_actions' of `column_index'.
		do
			current_column_index := a_value
			column_motion (grid.column (current_column_index).item (1))
		end
	
	column_width_changed (a_value: INTEGER)
			-- Called by `change_actions' of `column_width'.
		do
			grid.column (current_column_index).set_width (a_value)
		end

	move_to_column_motion (an_item: EV_GRID_ITEM)
			--
		do
			fixme ("COLUMN_TAB.move_to_column_motion Must add preconditions based on those of `move_column'.")
			if an_item /= Void then
				current_move_to_column_index := an_item.column.index
			else
				current_move_to_column_index := 0
			end
			update_swap_column_button_text
		end

	update_swap_column_button_text
			-- Update the text of swap_column_button to match user values.
		local
			l_text: STRING
		do
			if columns_to_move_button.value = 1 then
				l_text := "Move Column " + current_column_index.out 
			else
				l_text := "Move Columns " + current_column_index.out + " to " + ((current_column_index + columns_to_move_button.value - 1).min (grid.column_count)).out
			end
			l_text := l_text + " past Column " + current_past_column
			swap_column_button.set_text (l_text)
		end
		

	current_move_to_column_index: INTEGER
			-- Currently selected column index for the move column button.

	column_motion (an_item: EV_GRID_ITEM)
			--
		local
			l_column: EV_GRID_COLUMN
			l_color: EV_COLOR
		do
			if an_item /= Void then
				l_column := an_item.column
				current_column_index := l_column.index

				column_properties_frame.enable_sensitive
				column_operations_frame.enable_sensitive
				column_index.change_actions.block
				column_index.set_value (l_column.index)
				column_index.change_actions.resume
				column_width.change_actions.block
				column_width.set_value (l_column.width)
				column_width.change_actions.resume
				column_title_entry.change_actions.block
				column_title_entry.set_text (l_column.title)
				column_title_entry.change_actions.resume
				select_pixmap_from_combo (column_pixmap_combo, l_column.pixmap)
				column_selected_button.select_actions.block
				if l_column.is_selected then
					column_selected_button.enable_select
				else
					column_selected_button.disable_select
				end
				column_selected_button.select_actions.resume
				column_visible_button.select_actions.block
				if grid.column_displayed (l_column.index) then
					column_visible_button.enable_select
				else
					column_visible_button.disable_select
				end
				column_visible_button.select_actions.resume
				update_swap_column_button_text
				background_color_combo.select_actions.block
				if l_column.background_color /= Void then
					from
						background_color_combo.start
					until
						background_color_combo.off
					loop
						l_color ?= background_color_combo.item.data		
						if l_color /= Void and then l_color.is_equal (l_column.background_color) then
							background_color_combo.item.enable_select
							background_color_combo.go_i_th (background_color_combo.count)
						end
						background_color_combo.forth
					end
				else
					background_color_combo.first.enable_select
				end
				background_color_combo.select_actions.resume
				foreground_color_combo.select_actions.block
				if l_column.foreground_color /= Void then
					from
						foreground_color_combo.start
					until
						foreground_color_combo.off
					loop
						l_color ?= foreground_color_combo.item.data		
						if l_color /= Void and then l_color.is_equal (l_column.foreground_color) then
							foreground_color_combo.item.enable_select
							foreground_color_combo.go_i_th (foreground_color_combo.count)
						end
						foreground_color_combo.forth
					end
				else
					foreground_color_combo.first.enable_select
				end
				foreground_color_combo.select_actions.resume
			else
				column_properties_frame.disable_sensitive
				column_operations_frame.disable_sensitive
				update_swap_column_button_text
			end
		end

	current_past_column: STRING
			-- Return a string indicating the selected column to move past.
		do
			if current_move_to_column_index = 0 then
				Result := "?"
			else
				Result := current_move_to_column_index.out
			end
		ensure
			result_not_void: Result /= Void
		end
		
		
	column_selected_button_selected
			-- Called by `select_actions' of `column_selected_button'.
		do
			if column_selected_button.is_selected then
				grid.column (current_column_index).enable_select
			else
				grid.column (current_column_index).disable_select
			end
		end
		
	column_title_entry_changed
			-- Called by `change_actions' of `column_title_entry'.
		do
			grid.column (current_column_index).set_title (column_title_entry.text)
		end
		
	swap_column_button_selected
			-- Called by `select_actions' of `swap_column_button'.
		local
			l_columns_to_move: INTEGER
		do
			l_columns_to_move := (current_column_index + columns_to_move_button.value).min (grid.column_count) - current_column_index
			grid.move_columns (current_column_index, current_move_to_column_index, l_columns_to_move)
		end
		
	column_visible_button_selected
			-- Called by `select_actions' of `column_visible_button'.
		do
			if column_visible_button.is_selected then
				grid.show_column (current_column_index)
			else
				grid.hide_column (current_column_index)
			end
		end

	clear_column_button_selected
			-- Called by `select_actions' of `clear_column_button'.
		do
			grid.column (current_column_index).clear
		end

	remove_column_button_selected
			-- Called by `select_actions' of `remove_column_button'.
		do
			grid.remove_column (current_column_index)
		end

	foreground_color_combo_selected
			-- Called by `select_actions' of `foreground_color_combo'.
		local
			column: EV_GRID_COLUMN
			color: EV_COLOR
		do
			if current_column_index < grid.column_count then
				column := grid.column (current_column_index)
				if column /= Void then
					color ?= foreground_color_combo.selected_item.data
					column.set_foreground_color (color)
				end
			end
		end
	
	background_color_combo_selected
			-- Called by `select_actions' of `background_color_combo'.
		local
			column: EV_GRID_COLUMN
			color: EV_COLOR
		do
			if current_column_index < grid.column_count then
				column := grid.column (current_column_index)
				if column /= Void then
					color ?= background_color_combo.selected_item.data
					column.set_background_color (color)
				end
			end
		end

	column_pixmap_combo_selected
			-- Called by `select_actions' of `column_pixmap_combo'.
		local
			selected_item_index: INTEGER
			column: EV_GRID_COLUMN
			pixmap: EV_PIXMAP
		do
			if current_column_index < grid.column_count then
				column := grid.column (current_column_index)
				if column /= Void then
					selected_item_index := column_pixmap_combo.index_of (column_pixmap_combo.selected_item, 1)
					inspect selected_item_index
					when 1 then
						column.remove_pixmap
					else
						pixmap ?= column_pixmap_combo.selected_item.data
						column.set_pixmap (pixmap)
					end
				end
			end
		end

	column_to_move_button_selected (a_value: INTEGER)
			-- Called by `change_actions' of `columns_to_move_button'.
		do
			update_swap_column_button_text
		end

note
	copyright:	"Copyright (c) 1984-2006, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			 Eiffel Software
			 356 Storke Road, Goleta, CA 93117 USA
			 Telephone 805-685-1006, Fax 805-685-6869
			 Website http://www.eiffel.com
			 Customer support http://support.eiffel.com
		]"


end -- class COLUMN_TAB

