indexing
	description:
		"Projection to Postscript files."
	status: "See notice at end of class"
	keywords: "projector, events, postscript"
	date: "$Date$"
	revision: "$Revision$"

class
	EV_POSTSCRIPT_PROJECTOR

inherit
	EV_PROJECTOR

	EV_FIGURE_POSTSCRIPT_DRAWER

	EV_PROJECTION_ROUTINES

create
	make_with_filename

feature {NONE} -- Initialization

	make_with_filename (a_world: EV_FIGURE_WORLD; a_filename: FILE_NAME) is
			-- Create with `a_world' and `a_filename'.
		require
			a_world_not_void: a_world /= Void
			a_filename_not_void: a_filename /= Void
		do
			create draw_routines.make (0, 20)
			make_with_world (a_world)
			set_margins (20, 20)
			set_page_size (Letter, False)
			register_basic_figures
			create filename.make
			filename.set_file_name (a_filename)
		end

feature {NONE} -- Implementation

	filename: FILE_NAME

	file: PLAIN_TEXT_FILE

	output_to_postscript is
			-- Output standard projection to postscript.
		local
			rectangle: EV_RECTANGLE
		do
			create rectangle.make (0, 0, point_width - (2 * left_margin), point_height - (2 * bottom_margin))
			create postscript_result.make (0)
			add_ps ("%%%%!PS-Adobe-3.0 EPSF-3.0")
			add_ps("%%%%Creator: N/A")
			add_ps ("%%%%Title: N/A")
			add_ps ("%%%%CreationDate: N/A")
			add_ps ("%%%%DocumentData: N/A")
			add_ps ("%%%%Origin: 0 0")
			add_ps ("%%%%BoundingBox: 0 0 " + point_width.out + " " + point_height.out)
			add_ps ("%%%%LanguageLevel: 2")
			add_ps ("%%%%Pages: 1")
			add_ps ("%%%%Page: 1")
			add_eiffel_header
			add_ps ("%%Setting Clip Path and Origin")
			add_ps ("newpath%N" + left_margin.out + " " + bottom_margin.out + " moveto")
			add_ps (point_width.out + " 0 rlineto")
			add_ps ("0 " + point_height.out + " rlineto")
			add_ps ((-point_width).out + " 0 rlineto%Nclosepath%Nclip%Nclippath%N1 setgray fill")
			translate_to (left_margin, bottom_margin)
			if world.grid_enabled and world.grid_visible then
				draw_grid
			end
			if world.is_show_requested then
				project_figure_group (world, rectangle)
			end
			--if world.points_visible then
			--	project_rel_point (world.point)
			--end
			add_footer
		end

	add_eiffel_header is
		do
			add_ps ("%N%%Generated by:%N%
			%%%EiffelVision2: library of reusable components for ISE Eiffel.%N%
			%%%Copyright (C) 1986-2000 Interactive Software Engineering Inc.%N%
			%%%All rights reserved. Duplication and distribution prohibited.%N%
			%%%May be used only with ISE Eiffel, under terms of user license.%N%
			%%%Contact ISE for any other use.%N%N%
			%%%Interactive Software Engineering Inc.%N%
			%%%ISE Building, 2nd floor%N%
			%%%270 Storke Road, Goleta, CA 93117 USA%N%
			%%%Telephone 805-685-1006, Fax 805-685-6869%N%
			%%%Electronic mail <info@eiffel.com>%N%
			%%%Customer support e-mail <support@eiffel.com>%N%
			%%%For latest info see award-winning pages: http://www.eiffel.com%N")
		end

	add_footer is
		do
			add_ps ("%%%%EOF")
		end

	draw_grid is
			-- Draw grid on canvas.
		do
			add_ps ("%%Drawing PS Grid")
			add_ps ("gsave")
			translate_to (0, 0)
			add_ps ("1 setlinewidth")
			add_ps ("[] 0 setdash")
			add_ps ("1 1 scale")
			add_ps (Default_colors.Grey.out + " setrgbcolor")
			add_ps ("/draw_grid_point")
			add_ps ("{moveto 1 0 rlineto stroke} def")
			add_ps ("/grid_x_increase")
			add_ps ("{grid_x_pos " + world.grid_x.out + " add /grid_x_pos exch def} def")
			add_ps ("/grid_y_decrease")
			add_ps ("{grid_y_pos " + world.grid_y.out + " sub /grid_y_pos exch def} def")
			add_ps ("/draw_grid_line")
			add_ps ("{/grid_x_pos 0 def")
			add_ps ("{grid_x_pos " + point_width.out + " le {grid_x_pos grid_y_pos draw_grid_point grid_x_increase}{exit} ifelse}loop} def")
			add_ps ("/draw_grid")
			add_ps ("{/grid_y_pos " + (point_height-1).out + " def")
			add_ps ("{grid_y_pos 0 ge {draw_grid_line grid_y_decrease}{exit} ifelse}loop} def")
			add_ps ("draw_grid")
			add_ps ("grestore")
		end

feature -- Basic operations

	project is
			-- Make standard projection of world on device.
		do
			if not is_projecting then
				is_projecting := True
				-- Full projection.
				output_to_postscript
				create file.make_open_write (filename)
				file.put_string (postscript_result)
				file.close
				file := Void
				filename := Void
			end
			is_projecting := False
		end

end -- class EV_POSTSCRIPT_PROJECTOR

--|----------------------------------------------------------------
--| EiffelVision2: library of reusable components for ISE Eiffel.
--| Copyright (C) 1986-2001 Interactive Software Engineering Inc.
--| All rights reserved. Duplication and distribution prohibited.
--| May be used only with ISE Eiffel, under terms of user license. 
--| Contact ISE for any other use.
--|
--| Interactive Software Engineering Inc.
--| ISE Building
--| 360 Storke Road, Goleta, CA 93117 USA
--| Telephone 805-685-1006, Fax 805-685-6869
--| Electronic mail <info@eiffel.com>
--| Customer support: http://support.eiffel.com>
--| For latest info see award-winning pages: http://www.eiffel.com
--|----------------------------------------------------------------

