indexing
	description: "Objects that represent an EV_TITLED_WINDOW.%
		%The original version of this class was generated by EiffelBuild."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	EB_METRIC_HISTORY_PANEL

inherit
	EB_METRIC_HISTORY_PANEL_IMP

	EB_METRIC_PANEL
		undefine
			default_create,
			is_equal,
			copy
		end

create
	make

feature {NONE} -- Initialization

	make (a_tool: like metric_tool) is
			-- Initialize `metric_tool' with `a_too'.
		do
			create tree_grid.make (Current)
			create flat_grid.make (Current)
			create archive_change_actions
			create calculator
			create keep_result_btn.make (preferences.metric_tool_data.keep_archive_detailed_result_preference)
			create group_btn.make (preferences.metric_tool_data.tree_view_for_history_preference)
			create grid_support.make_with_grid (tree_grid.grid)
			grid_support.synchronize_color_or_font_change_with_editor
			grid_support.color_or_font_change_actions.extend (agent on_background_color_preference_change)
			set_grid_refresh_level (grid_rebind_level)
			on_hide_old_item_change_from_outside_agent := agent on_hide_old_item_change_from_outside
			on_item_age_change_from_outside_agent := agent on_item_age_change_from_outside
			preferences.metric_tool_data.hide_old_item_preference.change_actions.extend (on_hide_old_item_change_from_outside_agent)
			preferences.metric_tool_data.old_item_day_preference.change_actions.extend (on_item_age_change_from_outside_agent)
			set_metric_tool (a_tool)
			tree_grid.selection_change_actions.extend (agent on_selection_changes)
			flat_grid.selection_change_actions.extend (agent on_selection_changes)
			install_agents (a_tool)
			install_metric_history_agent
			grid := tree_grid
			tree_grid.input_domain_change_actions.extend (agent on_input_domain_changes)
			flat_grid.input_domain_change_actions.extend (agent on_input_domain_changes)

			calculator.step_actions.extend (agent on_process_gui)
			calculator.step_actions.extend (agent on_stop_archive_recalculation)
			calculator.archive_calculated_actions.extend (agent on_archive_retrieved)
			default_create
			tree_grid_area.extend (tree_grid.widget)
			flat_grid_area.extend (flat_grid.widget)
			if group_btn.is_selected then
				flat_grid_area.hide
			else
				tree_grid_area.hide
			end
			age_text.set_text (preferences.metric_tool_data.old_archive_item_age.out)
			age_text.change_actions.extend (agent on_item_age_change)
			hide_old_btn.select_actions.extend (agent on_hide_old_item_change)
			if preferences.metric_tool_data.is_old_archive_item_hidden then
				hide_old_btn.enable_select
			else
				hide_old_btn.disable_select
			end
		end

	user_initialization is
			-- Called by `initialize'.
			-- Any custom user initialization that
			-- could not be performed in `initialize',
			-- (due to regeneration of implementation class)
			-- can be added here.
		do
			run_btn.set_pixmap (pixmaps.icon_pixmaps.debug_run_icon)
			run_btn.set_tooltip (metric_names.f_run_history_recalculation)
			run_btn.select_actions.extend (agent on_recalculate_archive)

			stop_btn.set_pixmap (pixmaps.icon_pixmaps.debug_stop_icon)
			stop_btn.set_tooltip (metric_names.f_stop_history_recalculation)
			stop_btn.select_actions.extend (agent on_stop_button_pressed)

			remove_btn.set_pixmap (pixmaps.icon_pixmaps.general_remove_icon)
			remove_btn.set_tooltip (metric_names.f_remove_history_node)
			remove_btn.select_actions.extend (agent on_remove_archives)

			group_btn.set_pixmap (pixmaps.icon_pixmaps.metric_group_icon)
			group_btn.set_tooltip (metric_names.f_display_history_in_tree_view)
			group_btn.select_actions.extend (agent on_display_tree_view_changed)

			hide_old_item_lbl.set_text (metric_names.t_hide_old_archive)
			day_lbl.set_text (metric_names.t_days)

			keep_result_btn.set_pixmap (pixmaps.icon_pixmaps.metric_run_and_show_details_icon)
			keep_result_btn.set_tooltip (metric_names.f_keep_archive_detailed_result)

			remove_detailed_result_btn.set_pixmap (pixmaps.icon_pixmaps.general_reset_icon)
			remove_detailed_result_btn.set_tooltip (metric_names.f_remove_detailed_result)
			remove_detailed_result_btn.select_actions.extend (agent on_remove_detailed_result)

			select_all_btn.set_text (metric_names.t_select_all_history)
			select_all_btn.set_tooltip (metric_names.f_select_all_history)
			select_all_btn.select_actions.extend (agent on_select_all_history_items)

			deselect_all_btn.set_text (metric_names.t_deselect_all_history)
			deselect_all_btn.set_tooltip (metric_names.f_deselect_all_history)
			deselect_all_btn.select_actions.extend (agent on_deselect_all_history_items)

			select_recalculatable_btn.set_text (metric_names.t_select_recalculatable_history)
			select_recalculatable_btn.set_tooltip (metric_names.f_select_recalculatable_history)
			select_recalculatable_btn.select_actions.extend (agent on_select_all_recalculatable_history_items)

			deselect_recalculatable_btn.set_text (metric_names.t_deselect_recalculatable_history)
			deselect_recalculatable_btn.set_tooltip (metric_names.f_deselect_recalculatable_history)
			deselect_recalculatable_btn.select_actions.extend (agent on_deselect_all_recalculatable_history_items)

			keep_detailed_result_tool_bar.extend (keep_result_btn)
			group_tool_bar.extend (group_btn)
		end

feature -- Access

	grid: EB_METRIC_HISTORY_GRID
			-- Grid to display `archive'

	archive: EB_METRIC_ARCHIVE is
			-- Archive in current panel
		do
			if not metric_manager.has_archive_been_loaded then
				metric_manager.load_archive_history
				metric_tool.display_error_message
			end
			Result := metric_manager.archive_history
		end

	calculator: EB_METRIC_ARCHIVE_CALCULATOR
			-- Archive calculator

	selected_archives: DS_HASH_SET [EB_METRIC_ARCHIVE_NODE] is
			-- Selected archives
		do
			Result := grid.selected_archives
		end

	archive_change_actions: ACTION_SEQUENCE [TUPLE [EB_METRIC_ARCHIVE]]
			-- Actions to be called when archive changes.

	newly_changed_archives: DS_HASH_SET [EB_METRIC_ARCHIVE_NODE] is
			-- Newly changed archive nodes
		do
			if newly_changed_archives_internal = Void then
				create newly_changed_archives_internal.make (10)
			end
			Result := newly_changed_archives_internal
		ensure
			result_attached: Result /= Void
		end

feature{NONE} -- Status report

	is_original_starter: BOOLEAN
			-- Is this panel the original panel in which metric hitory recalculation starts?

	should_archive_be_shown (a_archive_node: EB_METRIC_ARCHIVE_NODE; a_time: DATE_TIME): BOOLEAN is
			-- Should `a_archive_node' be displayed?
			-- If `a_time' is Void, return True, other if calculated time of `a_archive_node' is more recent than `a_time', return True.
		require
			a_archive_node_attached: a_archive_node /= Void
			a_time_attached: a_time /= Void
		do
			Result := a_archive_node.calculated_time > a_time
		end

	is_archive_node_recalculatable (a_archive_node: EB_METRIC_ARCHIVE_NODE): BOOLEAN is
			-- Is `a_archive_node' recalculatable?
		require
			a_archive_node_attached: a_archive_node /= Void
		do
			Result := a_archive_node.is_recalculatable
		end

	is_cancel_evaluation_requested: BOOLEAN
			-- Is cancel archive recalculation requested?

feature -- Basic operations

	force_drop_stone (a_stone: STONE) is
			-- Force to drop `a_stone' in `domain_selector'.
		do
		end

	set_is_cancel_evaluation_requested (b: BOOLEAN) is
			-- Set `is_cancel_evaluation_requested' with `b'.
		do
			is_cancel_evaluation_requested := b
		ensure
			is_cancel_evaluation_requested_set: is_cancel_evaluation_requested = b
		end

feature -- Actions

	on_archive_retrieved (a_archive: EB_METRIC_ARCHIVE_NODE) is
			-- Action to be performed when one archive `a_archive' recalculation has finished
		require
			a_archive_attached: a_archive /= Void
		do
			grid.on_archive_retrieved (a_archive)
		end

	on_recalculate_archive is
			-- Action to be performed to recalculate select metric archive nodes
		local
			l_selected_archives: LINEAR [EB_METRIC_ARCHIVE_NODE]
			l_recalculated_archives: LIST [EB_METRIC_ARCHIVE_NODE]
			l_archive_node: EB_METRIC_ARCHIVE_NODE
		do
			set_is_cancel_evaluation_requested (False)
			l_selected_archives := selected_archives.to_array.linear_representation
			metric_manager.on_history_recalculation_starts (Current)
			calculator.calculate_archive (recalculation_task (l_selected_archives))
			if calculator.has_error then
				display_status_message (calculator.last_error_message)
			else
				display_status_message ("")
				l_recalculated_archives := calculator.calculated_archives
				from
					l_selected_archives.start
					l_recalculated_archives.start
				until
					l_recalculated_archives.after
				loop
					l_archive_node := l_selected_archives.item
					merge_archive (l_archive_node, l_recalculated_archives.item)
					l_archive_node.set_is_up_to_date (True)
					l_selected_archives.forth
					l_recalculated_archives.forth
				end
				newly_changed_archives.wipe_out
				l_selected_archives.do_all (agent newly_changed_archives.force_last)
			end
			metric_manager.on_history_recalculation_stops (Current)
		end

	on_remove_archives is
			-- Action to be performed to remove select metric archive nodes
		do
			selected_archives.to_array.linear_representation.do_all (agent remove_archive_node)
			set_is_up_to_date (False)
			set_grid_refresh_level (grid_rebind_level)
			update_ui
		end

	on_stop_archive_recalculation (a_item: QL_ITEM) is
			-- Action to be performed when archive recalculation is stopped
		local
			l_domain_generator: QL_CLASS_DOMAIN_GENERATOR
		do
			if is_cancel_evaluation_requested then
				create l_domain_generator
				if is_eiffel_compiling then
					l_domain_generator.error_handler.insert_interrupt_error (metric_names.e_interrupted_by_compile)
				else
					l_domain_generator.error_handler.insert_interrupt_error (metric_names.e_interrupted_by_user)
				end
			end
		end

	on_stop_button_pressed is
			-- Action to be performed when stop button is pressed.
		do
			set_is_cancel_evaluation_requested (True)
		end

	on_project_loaded is
			-- Action to be performed when project loaded
		do
			set_is_up_to_date (False)
			update_ui
		end

	on_project_unloaded is
			-- Action to be performed when project unloaded
		do
			set_is_up_to_date (False)
			update_ui
		end

	on_compile_start is
			-- Action to be performed when Eiffel compilation starts
		do
			set_is_up_to_date (False)
			update_ui
		end

	on_compile_stop is
			-- Action to be performed when Eiffel compilation stops
		do
			if workbench.system_defined and then workbench.is_already_compiled then
				set_is_up_to_date (False)
				archive.mark_archive_as_old
				if grid.has_grid_been_binded then
					set_grid_refresh_level (grid_update_level)
				else
					set_grid_refresh_level (grid_rebind_level)
				end
				update_ui
			end
		end

	on_metric_evaluation_start (a_data: ANY) is
			-- Action to be performed when metric evaluation starts
			-- `a_data' can be the metric tool panel from which metric evaluation starts.
		do
			set_is_up_to_date (False)
			update_ui
		end

	on_metric_evaluation_stop (a_data: ANY) is
			-- Action to be performed when metric evaluation stops
			-- `a_data' can be the metric tool panel from which metric evaluation stops.
		do
			set_is_up_to_date (False)
			update_ui
		end

	on_archive_calculation_start (a_data: ANY) is
			-- Action to be performed when metric archive calculation starts
			-- `a_data' can be the metric tool panel from which metric archive calculation starts.
		do
			set_is_up_to_date (False)
			update_ui
		end

	on_archive_calculation_stop (a_data: ANY) is
			-- Action to be performed when metric archive calculation stops
			-- `a_data' can be the metric tool panel from which metric archive calculation stops.
		do
			set_is_up_to_date (False)
			update_ui
		end

	on_metric_loaded is
			-- Action to be performed when metrics loaded in `metric_manager'
		do
			set_is_up_to_date (False)
			set_grid_refresh_level (grid_rebind_level)
			update_ui
		end

	on_history_recalculation_start (a_data: ANY) is
			-- Action to be performed when archive history recalculation starts
			-- `a_data' can be the metric tool panel from which metric history recalculation starts.
		local
			l_panel: like Current
		do
			l_panel ?= a_data
			set_is_original_starter (l_panel = Current)
			set_is_up_to_date (False)
			update_ui
		end

	on_history_recalculation_stop (a_data: ANY) is
			-- Action to be performed when archive history recalculation stops
			-- `a_data' can be the metric tool panel from which metric history recalculation stops.
		local
			l_panel: like Current
		do
			l_panel ?= a_data
			set_is_original_starter (l_panel = Current)
			set_is_up_to_date (False)
			set_grid_refresh_level (grid_update_level)
			update_ui
		end

	on_metric_sent_to_history (a_archive: EB_METRIC_ARCHIVE_NODE; a_panel: ANY) is
			-- Action to be performed when metric calculation information contained in `a_archive' has been sent to history
		local
			l_archive_list: LIST [EB_METRIC_ARCHIVE_NODE]
		do
			newly_changed_archives.wipe_out
			l_archive_list := archive.equivalent_archives (a_archive)
			if l_archive_list.is_empty then
				archive.insert_archive_node (a_archive)
				newly_changed_archives.force_last (a_archive)
			else
				l_archive_list.do_all (agent merge_archive (?, a_archive))
				l_archive_list.do_all (agent newly_changed_archives.force_last (?))
			end
			set_is_up_to_date (False)
			set_grid_refresh_level (grid_rebind_level)
			update_ui
		end

	on_selection_changes is
			-- Action to be performed when selection in `grid' changes
		do
			set_is_up_to_date (False)
			update_ui
		end

	on_metric_renamed (a_old_name, a_new_name: STRING) is
			-- Action to be performed when a metric with `a_old_name' has been renamed to `a_new_name'.
		do
			archive.rename_metric (a_old_name, a_new_name)
			set_is_up_to_date (False)
			set_grid_refresh_level (grid_rebind_level)
			update_ui
		end

	on_hide_old_item_change is
			-- Action to be performed when hide old item selection changes
		do
			preferences.metric_tool_data.hide_old_item_preference.set_value (hide_old_btn.is_selected)
			set_is_up_to_date (False)
			set_grid_refresh_level (grid_rebind_level)
			update_ui
		end

	on_hide_old_item_change_from_outside is
			-- Action to be performed when hide old item selection changes from outside
		local
			l_selected: BOOLEAN
		do
			l_selected := preferences.metric_tool_data.is_old_archive_item_hidden
			if l_selected /= hide_old_btn.is_selected then
				if l_selected then
					hide_old_btn.enable_select
				else
					hide_old_btn.disable_select
				end
			end
		end

	on_item_age_change is
			-- Action to be performed when age of item changes
		local
			l_text: STRING_32
			l_days: INTEGER
		do
			l_text := age_text.text
			if l_text.is_integer then
				l_days := l_text.to_integer
				if l_days > 0 then
					preferences.metric_tool_data.old_item_day_preference.set_value (l_days)
					if hide_old_btn.is_selected then
						delayed_timeout.request_call
					end
				end
			end
		end

	on_item_age_change_from_outside is
			-- Action to be performed when age of itme changes from outside
		local
			l_age: INTEGER
		do
			l_age := preferences.metric_tool_data.old_archive_item_age
			if not l_age.out.as_string_32.is_equal (age_text.text) then
				age_text.set_text (l_age.out.as_string_32)
			end
		end

	on_remove_detailed_result is
			-- Action to be performed to remove detailed result
		do
			archive.archive.do_all (agent remove_detailed_result)
			set_is_up_to_date (False)
			set_grid_refresh_level (grid_update_level)
			update_ui
		end

	on_input_domain_changes is
			-- Action to be performed when input domain of an archive item in `grid' changes
		do
			set_is_up_to_date (False)
			set_grid_refresh_level (grid_update_level)
			update_ui
		end

	on_select_all_history_items is
			-- Action to be performed to select all history items
		do
			grid.on_select_all_history_items
		end

	on_deselect_all_history_items is
			-- Action to be performed to deselect all history items
		do
			grid.on_deselect_all_history_items
		end

	on_select_all_recalculatable_history_items is
			-- Action to be performed to select all recalculatable history items
		do
			grid.on_select_all_recalculatable_history_items
		end

	on_deselect_all_recalculatable_history_items is
			-- Action to be performed to deselect all recalculatable history items
		do
			grid.on_deselect_all_recalculatable_history_items
		end

	on_background_color_preference_change is
			-- Action to be performed when even/odd background color preferences changes
		do
			if grid = tree_grid then
				set_grid_refresh_level (grid_update_level)
				set_is_up_to_date (False)
				update_ui
			end
		end

feature{NONE} -- UI Update

	update_ui is
			-- Update interface
		local
			l_selected_archives: like selected_archives
			l_date: DATE_TIME
			l_selected_archived: DS_HASH_SET [EB_METRIC_ARCHIVE_NODE]
		do
			if is_selected and then not is_up_to_date then
				if
					(not is_project_loaded) or else
					is_metric_evaluating or else
					is_archive_calculating or else
					is_eiffel_compiling or else
					(is_history_recalculationg_running and then not is_original_starter)
				then
					disable_sensitive
				else
					enable_sensitive
					if is_history_recalculationg_running then
						run_btn.disable_sensitive
						group_btn.disable_sensitive
						remove_btn.disable_sensitive
						if is_original_starter then
							stop_btn.enable_sensitive
						else
							stop_btn.disable_sensitive
						end
						grid.widget.disable_sensitive
						hide_old_btn.disable_sensitive
						old_item_area.disable_sensitive
						remove_detailed_result_btn.disable_sensitive
						keep_result_btn.disable_sensitive
						selector_toolbar.disable_sensitive
					else
						metric_tool.load_metrics (False, metric_names.t_loading_metrics)
						if not metric_tool.is_metric_validation_checked.item then
							metric_tool.check_metric_validation
						end
						inspect
							grid_refresh_level
						when grid_rebind_level then
							if hide_old_btn.is_selected then
								create l_date.make_now
								l_date.add (create {DATE_TIME_DURATION}.make_definite (-preferences.metric_tool_data.old_item_day_preference.value, 0, 0, 0))
								grid.bind (archive.filtered_archive (agent should_archive_be_shown (?, l_date)), Void)
							else
								grid.bind (archive, Void)
							end
						when grid_switch_level then
							l_selected_archived := grid.selected_archives
							switch_grid
							if hide_old_btn.is_selected then
								create l_date.make_now
								l_date.add (create {DATE_TIME_DURATION}.make_definite (-preferences.metric_tool_data.old_item_day_preference.value, 0, 0, 0))
								grid.bind (archive.filtered_archive (agent should_archive_be_shown (?, l_date)), l_selected_archived)
							else
								grid.bind (archive, l_selected_archived)
							end
						when grid_update_level then
							grid.update
						else
						end
						set_grid_refresh_level (grid_up_to_date_level)
						hide_old_btn.enable_sensitive
						grid.widget.enable_sensitive
						l_selected_archives := selected_archives
						if not l_selected_archives.is_empty then
							if l_selected_archives.to_array.linear_representation.for_all (agent is_archive_node_recalculatable) then
								run_btn.enable_sensitive
							else
								run_btn.disable_sensitive
							end
							remove_btn.enable_sensitive
						else
							run_btn.disable_sensitive
							remove_btn.disable_sensitive
						end
						group_btn.enable_sensitive
						stop_btn.disable_sensitive
						remove_detailed_result_btn.enable_sensitive
						keep_result_btn.enable_sensitive
						if hide_old_btn.is_selected then
							old_item_area.enable_sensitive
						else
							old_item_area.disable_sensitive
						end
						selector_toolbar.enable_sensitive
					end
				end
				set_is_up_to_date (True)
			end
		end

feature{NONE} -- Recycle

	internal_recycle is
			-- To be called when the button has became useless.
		do
			grid_support.desynchronize_color_or_font_change_with_editor
			preferences.metric_tool_data.hide_old_item_preference.change_actions.prune_all (on_hide_old_item_change_from_outside_agent)
			preferences.metric_tool_data.old_item_day_preference.change_actions.prune_all (on_item_age_change_from_outside_agent)
			uninstall_agents (metric_tool)
			uninstall_metric_history_agent
			group_btn.recycle
			keep_result_btn.recycle
		end

feature{NONE} -- Implementation

	set_is_original_starter (b: BOOLEAN) is
			-- Set `is_original_starter' with `b'.
		do
			is_original_starter := b
		ensure
			is_original_starter_set: is_original_starter = b
		end

	tree_grid: EB_METRIC_TREE_HISTORY_GRID
			-- Tree grid to display archive

	flat_grid: EB_METRIC_FLAT_HISTORY_GRID
			-- Flat grid to display archive

	newly_changed_archives_internal: like newly_changed_archives
			-- Implementation of `newly_changed_archives'

	switch_grid is
			-- Switch grid according selection status of `group_btn'.
		local
			l_grid: like grid
			l_old_container: EV_CONTAINER
			l_container: EV_CONTAINER
		do
			l_old_container := grid.widget.parent
			if group_btn.is_selected then
				l_grid := tree_grid
			else
				l_grid := flat_grid
			end
			l_container := l_grid.widget.parent
			if grid /= l_grid then
				l_old_container.hide
				grid := l_grid
				l_container.show
			end
		end

	merge_archive (a_source_archive_node, a_new_archive_node: EB_METRIC_ARCHIVE_NODE) is
			-- Merge `a_new_archive_node' into `a_source_archive_node'.
		require
			a_source_archive_node_attached: a_source_archive_node /= Void
			a_new_archive_node_attached: a_new_archive_node /= Void
			mergable: a_source_archive_node.is_mergable (a_new_archive_node)
		do
			a_source_archive_node.merge (a_new_archive_node)
			a_source_archive_node.set_is_up_to_date (True)
			a_source_archive_node.set_is_value_valid (True)
			a_source_archive_node.set_is_result_filtered (a_new_archive_node.is_result_filtered)
		end

	recalculation_task (a_selected_archives: LINEAR [EB_METRIC_ARCHIVE_NODE]): LINKED_LIST [TUPLE [EB_METRIC, EB_METRIC_DOMAIN, BOOLEAN, BOOLEAN]] is
			-- Task for history recalculation
		require
			a_selected_archives_attached: a_selected_archives /= Void
		do
			create Result.make
			from
				a_selected_archives.start
			until
				a_selected_archives.after
			loop
				Result.extend ([a_selected_archives.item.metric, a_selected_archives.item.input_domain, keep_result_btn.is_selected, a_selected_archives.item.is_result_filtered])
				a_selected_archives.forth
			end
		ensure
			result_attached: Result /= Void
		end

	remove_archive_node (a_archive_node: EB_METRIC_ARCHIVE_NODE) is
			-- Remove archive node `a_archive_node' from `archive'.
		require
			archive_node_attached: a_archive_node /= Void
			archive_node_exists: archive.has_archive_by_uuid (a_archive_node.uuid)
		do
			archive.remove_archive_node (a_archive_node.uuid)
		end

	delayed_timeout: ES_DELAYED_ACTION
			-- Delayed timeout
		do
			if delayed_timeout_internal = Void then
				create delayed_timeout_internal.make (agent delayed_update, 1000)
			end
			Result := delayed_timeout_internal
		ensure
			result_attached: Result /= Void
		end

	delayed_timeout_internal: like delayed_timeout
			-- Implementation of `delayed_timeout'

	delayed_update is
			-- Delayed update.
		do
			set_is_up_to_date (False)
			set_grid_refresh_level (grid_rebind_level)
			update_ui
		end

	remove_detailed_result (a_archive_node: EB_METRIC_ARCHIVE_NODE) is
			-- Remove detailed result stored in `a_archive_node'.
		require
			a_archive_node_attached: a_archive_node /= Void
		do
			a_archive_node.set_detailed_result (Void)
		end

	on_hide_old_item_change_from_outside_agent: PROCEDURE [ANY, TUPLE]
			-- Agent of `on_hide_old_item_change_from_outside'

	on_item_age_change_from_outside_agent: PROCEDURE [ANY, TUPLE]
			-- Agent of `on_item_age_change_from_outside'

	grid_refresh_level: INTEGER
			-- Grid refresh level

	grid_rebind_level: INTEGER is 1
	grid_update_level: INTEGER is 2
	grid_up_to_date_level: INTEGER is 3
	grid_switch_level: INTEGER is 4

	set_grid_refresh_level (a_level: INTEGER) is
			-- Set `grid_refresh_level' with `a_level'.
		require
			a_level_valid: is_grid_refresh_level_valid (a_level)
		do
			grid_refresh_level := a_level
		ensure
			grid_refresh_level_set: grid_refresh_level = a_level
		end

	is_grid_refresh_level_valid (a_level: INTEGER): BOOLEAN is
			-- Is `a_level' a valid grid refresh level?
		do
			Result := a_level = grid_rebind_level or
					  a_level = grid_update_level or
					  a_level = grid_up_to_date_level or
					  a_level = grid_switch_level
		end

	grid_support: EB_EDITOR_TOKEN_GRID_SUPPORT
			-- Grid support (used in odd/even row background preference change synchronization)

	keep_result_btn: EB_PREFERENCED_TOOL_BAR_TOGGLE_BUTTON
			-- Keep result button

	group_btn: EB_PREFERENCED_TOOL_BAR_TOGGLE_BUTTON
			-- Show tree view button

feature{NONE} -- Actions

	on_display_tree_view_changed is
			-- Action to be performed when selection status of `group_btn' changes
			-- When `group_btn' is selected, tree view is displayed, otherwise, flat view is displayed.
		do
			set_grid_refresh_level (grid_switch_level)
			set_is_up_to_date (False)
			update_ui
		end

invariant
	grid_attached: grid /= Void
	tree_grid_attached: tree_grid /= Void
	flat_grid_attached: flat_grid /= Void
	calculator_attached: calculator /= Void
	grid_support_attached: grid_support /= Void
	keep_result_btn_attached: keep_result_btn /= Void
	group_btn_attached: group_btn /= Void
	archive_change_actions_attached: archive_change_actions /= Void
	on_item_age_change_from_outside_agent_attached: on_item_age_change_from_outside_agent /= Void
	on_hide_old_item_change_from_outside_agent_attached: on_hide_old_item_change_from_outside_agent /= Void

indexing
        copyright:	"Copyright (c) 1984-2006, Eiffel Software"
        license:	"GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
        licensing_options:	"http://www.eiffel.com/licensing"
        copying: "[
                        This file is part of Eiffel Software's Eiffel Development Environment.
                        
                        Eiffel Software's Eiffel Development Environment is free
                        software; you can redistribute it and/or modify it under
                        the terms of the GNU General Public License as published
                        by the Free Software Foundation, version 2 of the License
                        (available at the URL listed under "license" above).

                        Eiffel Software's Eiffel Development Environment is
                        distributed in the hope that it will be useful,	but
                        WITHOUT ANY WARRANTY; without even the implied warranty
                        of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
                        See the	GNU General Public License for more details.

                        You should have received a copy of the GNU General Public
                        License along with Eiffel Software's Eiffel Development
                        Environment; if not, write to the Free Software Foundation,
                        Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA
                ]"
        source: "[
                         Eiffel Software
                         356 Storke Road, Goleta, CA 93117 USA
                         Telephone 805-685-1006, Fax 805-685-6869
                         Website http://www.eiffel.com
                         Customer support http://support.eiffel.com
                ]"


end
