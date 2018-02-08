# Copyright 2004-2005, @Last Software, Inc.

# This software is provided as an example of using the Ruby interface
# to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name        :   Bezier Curve Tool 1.0
# Description :   A tool to create Bezier curves.
# Menu Item   :   Draw->Bezier Curves
# Context Menu:   Edit Bezier Curve
# Usage       :   Select 4 points-
#             :   1. Start point of the curve
#             :   2. Endpoint of the curve
#             :   3. Second control point.  It determines the tangency at the start
#             :   4. Next to last control point.  It determines the tangency at the end
# Date        :   8/26/2004
# Type        :   Tool
#-----------------------------------------------------------------------------

# Ruby implementation of Bezier curves
require 'sketchup.rb'

module Bezier

# Evaluate a Bezier curve at a parameter.
# The curve is defined by an array of its control points.
# The parameter ranges from 0 to 1
# This is based on the technique described in "CAGD  A Practical Guide, 4th Editoin"
# by Gerald Farin. page 60

def Bezier.eval(pts, t)

    degree = pts.length - 1
    if degree < 1
        return nil
    end
    
    t1 = 1.0 - t
    fact = 1.0
    n_choose_i = 1

    x = pts[0].x * t1
    y = pts[0].y * t1
    z = pts[0].z * t1
    
    for i in 1...degree
		fact = fact*t
		n_choose_i = n_choose_i*(degree-i+1)/i
        fn = fact * n_choose_i
		x = (x + fn*pts[i].x) * t1
		y = (y + fn*pts[i].y) * t1
		z = (z + fn*pts[i].z) * t1
    end

	x = x + fact*t*pts[degree].x
	y = y + fact*t*pts[degree].y
	z = z + fact*t*pts[degree].z

    Geom::Point3d.new(x, y, z)
    
end # method eval

# Evaluate the curve at a number of points and return the points in an array
def Bezier.points(pts, numpts)
    
    curvepts = []
    dt = 1.0 / numpts

    # evaluate the points on the curve
    for i in 0..numpts
        t = i * dt
        curvepts[i] = Bezier.eval(pts, t)
    end
    
    curvepts
end

# Create a Bezier curve in SketchUp
def Bezier.curve(pts, numseg = 16)

    model = Sketchup.active_model
    entities = model.active_entities
    model.start_operation "Bezier Curve"
    
    curvepts = Bezier.points(pts, numseg)
    
    # create the curve
    edges = entities.add_curve(curvepts);
    model.commit_operation
    edges
    
end

#-----------------------------------------------------------------------------
# Define the tool class for creating Bezier curves

class BezierTool

def initialize(degree = 3)
    @degree = degree
    if( @degree < 1 )
        UI.messagebox "Minimum degree is 1"
        @degree = 1
    elsif( @degree > 20 )
        UI.messagebox "Maximum degree is 20"
        @degree = 20
    end
    # TODO: I should probably adjust the number of segments used for
    # display and creating the curve based on the the degree and/or the
    # maximum curvature.
end

def reset
    @pts = []
    @state = 0
    Sketchup::set_status_text "Click for start point"
    @drawn = false
end

def activate
    # There are up to 4 input points that we keep track of
    # @ip1 is the start point of the curve
    # @ip2 is the endpoint of the curve
    # @ip3 is the second control point.  It determines the tangency at the start
    # @ip4 is the next to last control point.  It determines the tangency at the end
    # @ip5 is an internal input point
    @ip1 = Sketchup::InputPoint.new
    @ip2 = Sketchup::InputPoint.new
    @ip3 = Sketchup::InputPoint.new
    @ip4 = Sketchup::InputPoint.new
    @ip5 = Sketchup::InputPoint.new
    # @ip is a temporary input point used to get other positions
    @ip = Sketchup::InputPoint.new
    self.reset
    Sketchup::set_status_text "Degree", SB_VCB_LABEL
    Sketchup::set_status_text @degree, SB_VCB_VALUE
end

def deactivate(view)
    view.invalidate if @drawn
    @ip1 = nil
    @ip2 = nil
    @ip3 = nil
    @ip4 = nil
    @ip5 = nil
end

def onMouseMove(flags, x, y, view)
    case @state
    when 0 # getting the first end point
        @ip.pick view, x, y
        if( @ip.valid? && @ip != @ip1 )
            @ip1.copy! @ip
            view.invalidate
        end
    when 1 # getting the second end point
        @ip.pick view, x, y, @ip1
        if( @ip.valid? && @ip != @ip2 )
            @ip2.copy! @ip
            @pts[1] = @ip2.position
            view.invalidate
        end
    when 2 # the second control point - tangency at start
        @ip.pick view, x, y, @ip1
        if( @ip.valid? && @ip != @ip3 )
            @ip3.copy! @ip
            @pts[1] = @ip3.position
            view.invalidate
        end
    when @degree # the next to last point = tangency at end
        @ip.pick view, x, y, @ip2
        if( @ip.valid? && @ip != @ip4 )
            @ip4.copy! @ip
            @pts[@degree-1] = @ip4.position
            view.invalidate
        end
    when 3..@degree-1 # internal points - if degree > 3
        @ip.pick view, x, y
        if( @ip.valid? && @ip != @ip5 )
            @ip5.copy! @ip
            @pts[@state-1] = @ip5.position
            view.invalidate
        end
    end
    view.tooltip = @ip.tooltip if @ip.valid?
end

def create_curve
    curve = Bezier.curve @pts, 20
    # see if this fills in any new faces
    if( curve )
        edge1 = curve[0]
        edge1.find_faces
        
        # Attach an attribute to the curve with the array of points
        curve = edge1.curve
        if( curve )
            curve.set_attribute "skp", "crvtype", "Bezier"
            curve.set_attribute "skp", "crvpts", @pts
        end
        
    end
    self.reset
end

def onLButtonDown(flags, x, y, view)
    # TODO: Use the two point form of the input point finder to get the new points.
    # I need a way to generate an ip at a given position from code.
    @ip.pick view, x, y
    if( @ip.valid? )
        case @state
        when 0
            @pts[0] = @ip.position
            Sketchup::set_status_text "Click for end point"
            @state = 1
        when @degree
            self.create_curve
        when 1
            @pts[2] = @ip.position
            @state = 2
            Sketchup::set_status_text "Click for point 2"
        when 2...@degree
            nextstate = @state+1
            @pts[nextstate] = @pts[@state]
            @pts[@state] = @ip.position
            @state = nextstate
            Sketchup::set_status_text "Click for point #{@state}"
        end
    end
end

def onCancel(flag, view)
    view.invalidate if @drawn
    reset
end

def onUserText(text, view)
    # get the degree from the text
    newdegree = text.to_i
    if( newdegree > 0 )
        @degree = newdegree
        self.create_curve if( @state > @degree )
    else
        UI.beep
        Sketchup::set_status_text @degree, SB_VCB_VALUE
    end
end

def getExtents
    bb = Geom::BoundingBox.new
    if( @state == 0 )
        # We are getting the first point
        if( @ip.valid? && @ip.display? )
            bb.add @ip.position
        end
    else
        bb.add @pts
    end
    bb
end

def draw(view)

    # Show the current input point
    if( @ip.valid? && @ip.display? )
        @ip.draw(view)
        @drawn = true
    end

    # show the curve
    if( @state == 1 )
        # just draw a line from the start to the end point
        view.set_color_from_line(@ip1, @ip2)
        view.draw(GL_LINE_STRIP, @pts)
        @drawn = true
    elsif( @state > 1 )
        # draw the curve
        view.drawing_color = "black"
        curvepts = Bezier.points(@pts, 12)
        view.draw(GL_LINE_STRIP, curvepts)
        # draw the control polygon
        # determine the colos for the first and last segments from the input points
        case @state
        when 2
            view.set_color_from_line(@ip1, @ip3)
            view.draw(GL_LINE_STRIP, @pts[0], @pts[1])
            view.drawing_color = "gray"
            view.draw(GL_LINE_STRIP, @pts[1..-1])
        when @degree
            view.drawing_color = "gray"
            view.draw(GL_LINE_STRIP, @pts[0..-2])
            view.set_color_from_line(@ip2, @ip4)
            view.draw(GL_LINE_STRIP, @pts[@degree-1], @pts[@degree])
        else
            view.drawing_color = "gray"
            view.draw(GL_LINE_STRIP, @pts)
        end
        @drawn = true
    end
end

end # class BezierTool

#-----------------------------------------------------------------------------
# Define the tool class for editing Bezier curves

class EditBezierTool

def activate

    @state = 0
    @drawn = false
    @selection = nil
    @pt_to_move = nil
    
    # Make sure that there is really a Bezier curve selected
    @curve = Bezier.selected_curve
    if( not @curve )
        Sketchup.active_model.select_tool nil
        return
    end
    
    # Get the control points
    @pts = @curve.get_attribute "skp", "crvpts"
    if( not @pts )
        UI.beep
        Sketchup.active_model.select_tool nil
        return
    end
    
    # Get the curve points from the vertices
    @vertices = @curve.vertices
    @crvpts = @vertices.collect {|v| v.position}
    @numseg = @vertices.length - 1
    
    @ip = Sketchup::InputPoint.new
end

def deactivate(view)
    view.invalidate if @drawn
    @ip = nil
end

def resume(view)
    @drawn = false
end

def pick_point_to_move(x, y, view)
    old_pt_to_move = @pt_to_move
    ph = view.pick_helper x, y
    @selection = ph.pick_segment @pts
    if( @selection )
        if( @selection < 0 )
            # We got a point on a segment.  Compute the point closest
            # to the pick ray.
            pickray = view.pickray x, y
            i = -@selection
            segment = [@pts[i-1], @pts[i]]
            result = Geom.closest_points segment, pickray
            @pt_to_move = result[0]
        else
            # we got a control point
            @pt_to_move = @pts[@selection]
        end
    else
        @pt_to_move = nil
    end
    old_pt_to_move != @pt_to_move
end

def onLButtonDown(flags, x, y, view)
    # Select the segment or control point to move
    self.pick_point_to_move x, y, view
    @state = 1 if( @selection )
end

def onLButtonUp(flags, x, y, view)
    return if not @state == 1
    @state = 0
    
    # Update the actual curve.  Move the vertices on the curve
    # to the new curve points
    if( @vertices.length != @crvpts.length )
        UI.messagebox "Count of curve points is wrong!"
        return
    end

    model = @vertices[0].model
    model.start_operation "Edit Bezier Curve"

    # Move the vertices
    @curve.move_vertices @crvpts
    
    # Update the control points stored with the curve
    @curve.set_attribute "skp", "crvpts", @pts
    
    model.commit_operation
end

def onMouseMove(flags, x, y, view)
    # Make sure that the control polygon is shown
    view.invalidate if not @drawn
    
    # Move the selected point if state = 1
    if( @state == 1 && @selection )
        @ip.pick view, x, y
        return if not @ip.valid?
        if( @selection >= 0 )
            # Moving a control point
            @pt_to_move = @ip.position
            @pts[@selection] = @pt_to_move
        else
            # moving a segment
            pt = @ip.position
            vec = pt - @pt_to_move
            i = -@selection
            @pts[i-1].offset! vec
            @pts[i].offset! vec
            @pt_to_move = pt
        end
        @crvpts = Bezier.points(@pts, @numseg)
        view.invalidate
    else # state != 1
        # See if we can select something to move
        view.invalidate if( self.pick_point_to_move(x, y, view) )
    end
end

def getMenu(menu)
    menu.add_item("Done") {Sketchup.active_model.select_tool nil}
end

def getExtents
    bb = Geom::BoundingBox.new
    bb.add @pts
    bb
end

def draw(view)
    # Draw the control polygon
    view.drawing_color = "gray"
    view.draw(GL_LINE_STRIP, @pts)
    
    if( @pt_to_move )
        view.draw_points(@pt_to_move, 10, 1, "red");
    end
    
    if( @state == 1 )
        view.drawing_color = "black"
        view.draw(GL_LINE_STRIP, @crvpts)
    end
    
    @drawn = true
end

end # class EditBezierTool

#-----------------------------------------------------------------------------

# Function to test to see if the selection set contains only a Bezier curve
# Returns the curve if there is one or else nil
def Bezier.selected_curve
    ss = Sketchup.active_model.selection
    return nil if not ss.is_curve?
    edge = ss.first
    return nil if not edge.kind_of? Sketchup::Edge
    curve = edge.curve
    return nil if not curve
    return nil if curve.get_attribute("skp", "crvtype") != "Bezier"
    curve
end

# Edit a selected Bezier curve
def Bezier.edit_curve
    curve = Bezier.selected_curve
    if( not curve )
        UI.beep
        return
    end
    Sketchup.active_model.select_tool EditBezierTool.new
end

# Select the Bezier curve tool
def Bezier.tool(degree=3)
    Sketchup.active_model.select_tool BezierTool.new(degree)
end

# Add a menu choice for creating bezier curves
if( not file_loaded?("bezier.rb") )
    add_separator_to_menu("Draw")
    UI.menu("Draw").add_item("Bezier Curves") { Bezier.tool }

    # Add a context menu handler to let you edit a Bezier curve
    UI.add_context_menu_handler do |menu|
        if( Bezier.selected_curve )
            menu.add_separator
            menu.add_item("Edit Bezier Curve") { Bezier.edit_curve }
        end
    end

end

end # module Bezier
file_loaded("bezier.rb")
