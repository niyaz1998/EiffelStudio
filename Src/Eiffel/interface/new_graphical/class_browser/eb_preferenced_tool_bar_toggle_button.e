indexing
	description: "[
					Toolbar toggle button with the ability to synchronize its status with its related preference.
				]"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	EB_PREFERENCED_TOOL_BAR_TOGGLE_BUTTON

inherit
	EV_TOOL_BAR_TOGGLE_BUTTON

	EB_RECYCLABLE
		undefine
			copy,
			is_equal,
			default_create
		end

create
	make

feature{NONE} -- Initialization

	make (a_preference: BOOLEAN_PREFERENCE) is
			-- Initialize `preference' with `a_preference'.
		require
			a_preference_attached: a_preference /= Void
		do
			default_create
			preference := a_preference
			create synchronizer
			button_status_change_agent := agent notify_synchronizer (Current)
			preference_status_change_agent := agent notify_synchronizer (preference)

			synchronizer.register_host (
				preference,
				[
					agent (a_syn: EB_VALUE_SYNCHRONIZER [BOOLEAN]) do preference.change_actions.extend (preference_status_change_agent) end,
					agent (a_syn: EB_VALUE_SYNCHRONIZER [BOOLEAN]) do preference.change_actions.prune_all (preference_status_change_agent) end,
					agent: BOOLEAN do Result := preference.value end,
					agent preference.set_value
				],
				True
			)

			synchronizer.register_host (
				Current,
				[
					agent (a_syn: EB_VALUE_SYNCHRONIZER [BOOLEAN]) do select_actions.extend (button_status_change_agent) end,
					agent (a_syn: EB_VALUE_SYNCHRONIZER [BOOLEAN]) do select_actions.prune_all (button_status_change_agent) end,
					agent: BOOLEAN do Result := is_selected end,
					agent set_selection_status
				],
				False
			)
		end

feature -- Access

	preference: BOOLEAN_PREFERENCE
			-- Boolean preference associated with Current
			-- Current is reponsible for synchronizing with `preference'

feature {NONE} -- Implementation

	synchronizer: EB_VALUE_SYNCHRONIZER [BOOLEAN]
			-- Synchronizer used to synchroize selection status of Current toggle button and its associated `preference'

	button_status_change_agent: PROCEDURE [ANY, TUPLE]
			-- Agent to be performed when selection status of Current toggle button changes

	preference_status_change_agent: PROCEDURE [ANY, TUPLE]
			-- Agent to be performed when value of `preference' changes

	set_selection_status (b: BOOLEAN) is
			-- Set selection status of Current toggle button with `b'.
			-- `b' is True means enable selection of Current,
			-- `b' is False means disable selection of Current.
		do
			if b then
				enable_select
			else
				disable_select
			end
		ensure
			selection_status_set: (b implies is_selected) and then (not b implies not is_selected)
		end

	notify_synchronizer (a_value_host: ANY)	is
			-- Notify `synchronizer' that value from `a_value_host' changes
		require
			a_value_host_valid: a_value_host = Current or else a_value_host = preference
		do
			synchronizer.on_value_change_from (a_value_host)
		ensure
			value_synchronized: synchronizer.is_value_synchronized
		end

feature{NONE} -- Recycle

	internal_recycle is
			-- To be called when the button has became useless.
		do
			synchronizer.wipe_out_hosts
		end

invariant
	preference_attached: preference /= Void
	synchronizer_attached: synchronizer /= Void
	button_status_change_agent_attached: button_status_change_agent /= Void
	preference_status_change_agent_attached: preference_status_change_agent /= Void

end
