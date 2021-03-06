note
	description: "This class represents a Screen"
	legal: "See notice at end of class.";
	status: "See notice at end of class."; 
	date: "$Date$"; 
	revision: "$Revision$" 

class
	SCREEN_IMP 

inherit
	WEL_WINDOWS_ROUTINES

	WEL_COLOR_CONSTANTS

	DRAWABLE_DEVICE_WINDOWS
		rename
			clear as dd_clear,
			draw_arc as dd_draw_arc,
			draw_image_text as dd_draw_image_text,
			draw_inf_line as dd_draw_inf_line,
			draw_point as dd_draw_point,
			draw_polyline as dd_draw_polyline,
			draw_rectangle as dd_draw_rectangle,
			draw_segment as dd_draw_segment,
			draw_text as dd_draw_text,
			fill_arc as dd_fill_arc,
			fill_polygon as dd_fill_polygon,
			fill_rectangle as dd_fill_rectangle,
			update_dc as dd_update_dc,
			update_pen as dd_update_pen,
			update_font as dd_update_font
		redefine
			drawing_dc,
			set_drawing_dc,
			unset_drawing_dc
		end

	DRAWABLE_DEVICE_WINDOWS
		redefine
			clear,
			draw_arc,
			draw_image_text,
			draw_inf_line,
			draw_point,
			draw_polyline,
			draw_rectangle,
			draw_segment,
			draw_text,
			drawing_dc,
			fill_arc,
			fill_polygon,
			fill_rectangle, 
			set_drawing_dc,
			unset_drawing_dc,
			update_dc,
			update_font,
			update_pen
		select
			clear,
			draw_arc,
			draw_image_text,
			draw_inf_line,
			draw_point,
			draw_polyline,
			draw_rectangle,
			draw_segment,
			draw_text,
			fill_arc,
			fill_polygon,
			fill_rectangle,
			update_dc,
			update_font,
			update_pen
		end

	G_ANY_IMP

	SCREEN_I

	CURSOR_WIDGET_MANAGER

create
	make

feature -- Initialization

	make (a_screen: SCREEN)
			-- Create this screen
		do
			create drawing_dc
			set_line_width (1);
			create gc_fg_color.make_system (color_windowtext)
			create gc_bg_color.make_system (color_window)
			line_style := ps_solid
		end

feature -- Access

	drawing_dc: WEL_SCREEN_DC
			-- Device context of current screen

	x: INTEGER
			-- Current absolute horizontal coordinate of the mouse
		local
			point: WEL_POINT
		do
			create point.make (0, 0)
			point.set_cursor_position 
			Result := point.x
		end

	y: INTEGER
			-- Current absolute vertical coordinate of the mouse
		local
			point: WEL_POINT
		do
			create point.make (0, 0)
			point.set_cursor_position 
			Result := point.y
		end

	visible_width: INTEGER
		once
			Result := system_metrics.maximized_window_width
		end

	visible_height: INTEGER
		once
			Result := system_metrics.maximized_window_height
		end

	width: INTEGER
			-- Horizontal resolution of the screen
		once
			Result := system_metrics.screen_width
		end

	height: INTEGER
			-- Vertical resolution of the screen
		once
			Result := system_metrics.screen_height
		end

feature -- Status report

	is_valid: BOOLEAN
			-- Is screen created?
		do
			Result := true
		end

feature -- Element change

	add_expose_action (action: COMMAND; arg: ANY)
		do
		end

	remove_expose_action (action: COMMAND; arg: ANY)
		do
		end

feature -- Output

	clear
			-- Clear the entire area.
		do
		end

	draw_arc (center: COORD_XY; radius1, radius2: INTEGER; angle1, angle2, orientation: REAL; arc_style: INTEGER)
			-- Draw an arc centered in (`x', `y') with a great radius of
			-- `radius1' and a small radius of `radius2'
			-- beginnning at `angle1' and finishing at `angle1'+`angle2'
			-- and with an orientation of `orientation'.
		do
			drawing_dc.get
			dd_draw_arc (center, radius1, radius2, angle1, angle2, orientation, arc_style)
			drawing_dc.release
		end

	draw_image_text (base: COORD_XY; text: STRING)
			-- Draw text
		do
			set_drawing_dc (drawing_dc)
			dd_draw_image_text (base, text)
			unset_drawing_dc
		end

	draw_inf_line (point1, point2: COORD_XY)
			-- Draw an infinite line traversing `point1' and `point2'.
		do
			set_drawing_dc (drawing_dc)
			dd_draw_inf_line (point1, point2)
			unset_drawing_dc
		end

	draw_point (a_point: COORD_XY)
			-- Draw `a_point'.
		do
			set_drawing_dc (drawing_dc)
			dd_draw_point (a_point)
			unset_drawing_dc
		end

	draw_polyline (points: LIST [COORD_XY]; is_closed: BOOLEAN)
			-- Draw a polyline, close it automatically if `is_closed'.
		do
			set_drawing_dc (drawing_dc)
			dd_draw_polyline (points, is_closed)
			unset_drawing_dc
		end

	draw_rectangle (center: COORD_XY; rwidth, rheight: INTEGER; an_orientation: REAL)
			-- Draw a rectangle whose center is `center' and
			-- whose size is `rwidth' and `rheight'.
		do
			set_drawing_dc (drawing_dc)
			dd_draw_rectangle (center, rwidth, rheight, an_orientation)
			unset_drawing_dc
		end

	draw_segment (point1, point2: COORD_XY)
			-- Draw a segment between `point1' and `point2'.
		do
			set_drawing_dc (drawing_dc)
			dd_draw_segment (point1, point2)
			unset_drawing_dc
		end

	draw_text (base: COORD_XY; text: STRING)
			-- Draw text
		do
			set_drawing_dc (drawing_dc)
			dd_draw_text (base, text)
			unset_drawing_dc
		end

	fill_arc (center: COORD_XY; radius1, radius2 : INTEGER; angle1, angle2, orientation: REAL; arc_style: INTEGER)
			-- Fill an arc centered in (`x', `y') with a great radius of
			-- `radius1' and a small radius of `radius2'
			-- beginnning at `angle1' and finishing at `angle1'+`angle2'
			-- and with an orientation of `orientation'.
		do
			set_drawing_dc (drawing_dc)
			dd_fill_arc (center, radius1, radius2, angle1, angle2, orientation, arc_style)
			unset_drawing_dc
		end

	fill_polygon (points: LIST [COORD_XY])
			 -- Fill a polygon.
		do
			set_drawing_dc (drawing_dc)
			dd_fill_polygon (points)
			unset_drawing_dc
		end

	fill_rectangle (center: COORD_XY; rwidth, rheight : INTEGER; an_orientation: REAL)
			-- Fill a rectangle whose center is `center' and
			-- whose size is `rwidth' and `rheight'.
		do
			set_drawing_dc (drawing_dc)
			dd_fill_rectangle (center, rwidth, rheight, an_orientation)
			unset_drawing_dc
		end 

feature {NONE} -- Inapplicable

	screen_object: POINTER
			-- No value for a screen
		do
			--| This is correct for Windows a
			--| GetDC passed a NULL will
			--| return the DC of the screen
		end

feature -- Implementation

	set_drawing_dc (dc: WEL_DC)
			-- Set `drawing_dc' as necessary
		do
			drawing_dc.get
			update_brush
			if drawing_font /= Void then
				update_font
			end
			dd_update_dc
			update_pen
		end

	unset_drawing_dc
			-- Reset the dc to the original contents
		do
			drawing_dc.unselect_all
			drawing_dc.release
		end

	update_dc
			-- Update the `drawing_dc' due to dc details changing
		require else
			drawing_dc: drawing_dc /= Void
		do
			if drawing_dc.exists then
				dd_update_dc
			end
		end

	update_font
			-- Update the `drawing_dc' due to font details changing
		require else
			drawing_dc: drawing_dc /= Void
		do
			if drawing_dc.exists then
				dd_update_font
			end
		end

	update_pen
			-- Update the `drawing_dc' due to pen details changing
		require else
			drawing_dc: drawing_dc /= Void
		do
			if drawing_dc.exists then
				dd_update_pen
			end
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




end -- class SCREEN_WINDOWS

