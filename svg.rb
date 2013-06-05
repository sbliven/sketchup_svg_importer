#-----------------------------------------------------------------------------
#  Copyright (C) 2013 Spencer Bliven (spencer@bliven.us)
#  Copyright (C) 2008 Uli Tessel (utessel@gmx.de)
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#-----------------------------------------------------------------------------
#
#  SVG File Import for Inkscape files (Version 0.4)
#
#  This script allows to use Inkscape to create 2D images (for example by
#  using Inkscapes bitmap vectorizer) and to create Sketchup group(s)
#  from the SVG File Inkscape has written.
#
#  The code will try to keep the hierarchy of the SVG file, so you
#  will get a whole tree of groups if you had one in your SVG File.
#
#-----------------------------------------------------------------------------

require 'Sketchup.rb'
# Available at http://rhin.crai.archi.fr/RubyLibraryDepot/plugin_details.php?id=33
require 'bezier.rb'

require 'rexml/parsers/pullparser.rb'


#----------------------------------------------------------------------------
class SVGFileImport

  #--------------------------------------------------------------------------
  def initialize()
    @matrixdef = Regexp.new( "matrix\(.*\)" )
    @translatedef = Regexp.new( "translate\(.*\)" )
    @scaledef = Regexp.new( "scale\(.*\)" )
    # Correctly handles integers, floating point, and exponentials
    @numberdef = /[+-]?(?:(?:\d*\.\d+|\d+\.)(?:[eE][+-]?\d+)?|\d+[eE][+-]?[0-9]+|\d+)/
  end

  #--------------------------------------------------------------------------
  def DebugUnexpected( where )
    if $svgImportScriptDebug
      puts "Unexpected token in "+where
      puts @event.inspect
    end
  end

  #--------------------------------------------------------------------------
  def DebugPuts( what )
    if $svgImportScriptDebug
      puts what
    end
  end

  #--------------------------------------------------------------------------
  # XML Stuff
  #--------------------------------------------------------------------------

  #--------------------------------------------------------------------------
  # My implementation of a "Pull-Parser": read tag after tag
  def NextTag()
    while @xml.has_next?
       @event = @xml.pull
       #DebugPuts "Tag: "+@event.event_type.to_s
       case @event.event_type
         when :start_element then return String2Token( @event[0] )
         #when :text then return :tkContent
         when :end_element then return :tkEndOfTag
       end
    end
    return :tkEndOfTag
  end

  #--------------------------------------------------------------------------
  # or Ignore them including all sub-Tags (also used to "eat" the rest)
  def IgnoreTag
    while @xml.has_next?
       event = @xml.pull
       #DebugPuts "Ignoring "+ event.event_type.to_s
       case event.event_type
         when :start_element then IgnoreTag()
         when :end_element then break
       end
    end
  end

  #--------------------------------------------------------------------------
  # instead of general "tag", I use a token for the different types:
  def String2Token( name )
    # could be made more general by using a hash for this?
    
    # the entries here are found by scanning a lot of svg files:
    case name
    when 'svg' then return :tk_svg
    when 'g' then return :tk_group
    when 'a' then return :tk_a
    when 'path' then return :tk_path
    when 'polygon' then return :tk_polygon
    when 'polyline' then return :tk_polyline
    when 'line' then return :tk_line
    when 'image' then return :tk_image
    when 'rect' then return :tk_rect
    when 'defs' then return :tk_defs
    when 'sodipodi:namedview' then return :tk_sodipodi_namedview
    when 'sodipodi:guide' then return :tk_sodipodi_guide
    when 'metadata' then return :tk_metadata
    when 'rdf:RDF' then return :tk_rdf_RDF
    when 'cc:Work' then return :tk_cc_Work
    when 'text' then return :tk_text
    when 'textPath' then return :tk_textPath
    when 'tspan' then return :tk_tspan
    when 'linearGradient' then return :tk_linearGradient
    when 'radialGradient' then return :tk_radialGradient
    when 'stop' then return :tk_stop
    when 'filter' then return :tk_filter
    when 'feBlend' then return :tk_feBlend
    when 'script' then return :tk_script
    when 'tref' then return :tk_tref
    when 'cc:license' then return :tk_cc_license
    when 'cc:Agent' then return :tk_cc_Agent
    when 'cc:permits' then return :tk_cc_permits
    when 'cc:requires' then return :tk_cc_requires
    when 'cc:prohibit' then return :tk_cc_prohibit
    when 'dc:format' then return :tk_dc_format
    when 'dc:type' then return :tk_dc_type
    when 'dc:title' then return :tk_dc_title
    when 'dc:date' then return :tk_dc_date
    when 'dc:creator' then return :tk_dc_creator
    when 'dc:description' then return :tk_dc_description
    when 'dc:contributor' then return :tk_dc_contributor
    when 'dc:subject' then return :tk_dc_subject
    when 'dc:language' then return :tk_dc_language
    when 'dc:rights' then return :tk_dc_rights
    when 'rdf:Bag' then return :tk_rdf_Bag
    when 'rdf:li' then return :tk_rdf_li
    when 'title' then return :tk_title
    when 'desc' then return :tk_desc
    when 'flowRoot' then return :tk_flowRoot
    when 'flowRegion' then return :tk_flowRegion
    when 'flowRegionExclude' then return :tk_flowRegionExclude
    when 'use' then return :tk_use
    when 'flowDiv' then return :tk_flowDiv
    when 'flowPara' then return :tk_flowPara
    when 'flowSpan' then return :tk_flowSpan
    when 'flowLine' then return :tk_flowLine
    when 'clipPath' then return :tk_clipPath
    when 'feGaussianBlur' then return :tk_feGaussianBlur
    when 'marker' then return :tk_marker
    when 'inkscape_path_effect' then return :tk_inkscape_path_effect
    when 'feDiffuseLighting' then return :tk_feDiffuseLighting
    when 'feDistantLight' then return :tk_feDistantLight
    when 'feSpecularLighting' then return :tk_feSpecularLighting
    when 'feComposite' then return :tk_feComposite
    when 'style' then return :tk_style
    when 'animate' then return :tk_animate
    when 'circle' then return :tk_circle
    when 'font' then return :tk_font
    when 'Previous' then return :tk_Previous
    when 'Next' then return :tk_Next
    when 'Parent' then return :tk_Parent
    when 'Child' then return :tk_Child
    when 'Paragraph' then return :tk_Paragraph
    else
      DebugPuts "no Token found for " + name
      return :tkUNKNOWN
    end
  end

  #---------------------------------------------------------------------
  # help stuff
  #---------------------------------------------------------------------

  #---------------------------------------------------------------------
  # create a matrix from a transformation="...."
  def getTransformation( line )

    if line =~ @matrixdef

      # transformation="matrix(...)"
      line.slice!(0,7)
      line.slice!(-1,1)
      m = line.split(",")
      matrix = Array.new( 16 )
      matrix[0] = m[0].to_f; matrix[1] = m[1].to_f; matrix[2] = 0.0; matrix[3] = 0.0;
      matrix[4] = m[2].to_f; matrix[5] = m[3].to_f; matrix[6] = 0.0; matrix[7] = 0.0;
      matrix[8] = 0.0;       matrix[9] = 0.0;       matrix[10]= 1.0; matrix[11]= 0.0;
      matrix[12]= m[4].to_f; matrix[13]= m[5].to_f; matrix[14]= 0.0; matrix[15]= 1.0;
      return Geom::Transformation.new( matrix )

    elsif line =~ @translatedef

      # transformation="translate(...)"
      line.slice!(0,10) # cut "translate"
      line.slice!(-1,1)
      info = line.split(",")
      move = Geom::Vector3d.new( info[0].to_f, info[1].to_f, 0 )
      return Geom::Transformation.new( move )

    elsif line =~ @scaledef

      # transformation="scale(...)"
      line.slice!(0,6) # cut "scale"
      line.slice!(-1,1)
      info = line.split(",")
      x= info[0].to_f
      y= info[1].to_f

      matrix = Array.new( 16 )
      matrix[0] = x;   matrix[1] = 0.0; matrix[2] = 0.0; matrix[3] = 0.0;
      matrix[4] = 0.0; matrix[5] = y;   matrix[6] = 0.0; matrix[7] = 0.0;
      matrix[8] = 0.0; matrix[9] = 0.0; matrix[10]= 1.0; matrix[11]= 0.0;
      matrix[12]= 0.0; matrix[13]= 0.0; matrix[14]= 0.0; matrix[15]= 1.0;

      return Geom::Transformation.new( matrix )
      
    else
      DebugPuts "Unknown transformation "+ line
      return nil
    end
  end

  #---------------------------------------------------------------------
  # SVG Paint Stuff
  #---------------------------------------------------------------------

  #---------------------------------------------------------------------
  # perform the transformation-string to a group:
  def DoTransform( group, transform )
    m = getTransformation( transform )
    if (m) then
      group.transform!( m )
    end
  end

  #---------------------------------------------------------------------
  # Called for all kind of entities, but set color only for faces
  def DoSetColor( entity, color )
    if (entity.is_a? Sketchup::Face)
      entity.material = color
      if $svgImportScriptSetback_material
        entity.back_material = color
      end
    end
  end

  #---------------------------------------------------------------------
  # handle all kind of style definitions
  # currently only filling is used
  def DoStyleEntry( group, entry )
    entry.slice!(";")
    styleDef = entry.split( ":" )

    case styleDef[0]
    when "fill" #
      if styleDef[1] == "none"
      # no filling? todo: remove all faces again
      else
        r = styleDef[1].slice(1,2).hex
        g = styleDef[1].slice(3,2).hex
        b = styleDef[1].slice(5,2).hex
        color = b*65536+g*256+r
        group.entities.each { |entity| DoSetColor(entity, color ) }
      end
    end
  end

  #---------------------------------------------------------------------
  # execute the style definition string
  def DoStyle( group, style )
     style.each(';') { |entry| DoStyleEntry( group, entry ) }
  end

  #---------------------------------------------------------------------
  # PATH
  #---------------------------------------------------------------------

  #---------------------------------------------------------------------
  # cut the d="..." line to separate commands
  def DoPathDef(sugroup, d)

    DebugPuts "Path Def"

    @cmd = nil #single character representing the current state
    @currGroup = sugroup
    @parameter = [] #stores numeric parameters
    @p0 = nil #current point
    @ps = nil #initial point
    
    # Split path into path tokens
    # Note that the spec is quite flexible about tokenization
    # For instance, "M 1.0,2.0 L 3.1,0.4" is equivalent to "M1.0 2.L,3.1.4"
    d.scan( /#{@numberdef}|[a-zA-Z]/ ) {| sub | PathEntry( sub ) }
  end

  #---------------------------------------------------------------------
  # each entry in the d="..." string comes here
  def PathEntry( token )
    token.strip!
    
    # To implement new commands, add a handler in the case @cmd and also add 
    # it to the regex above "Unhandled Path Command"
    
    case token
    when /^[MZLCHVSQTA]$/i # Valid (but not all supported) path commands
      @cmd = token
      
      case @cmd
      when "Z","z" then CloseCommand()
      when /^[^MmLlCcZz]$/ #List supported commands here
        DebugPuts "Unhandled Path Command: #{@cmd}"
      end
    when /^#{@numberdef}$/ #parameters
      @parameter.push token.to_f
      
      case @cmd
      when "M"
        MoveCommand(true) if @parameter.length == 2
      when "m"
        MoveCommand(false) if @parameter.length == 2
      when "L"
        LineCommand(true) if @parameter.length == 2
      when "l"
        LineCommand(false) if @parameter.length == 2
      when "C"
        CubicCommand(true) if @parameter.length == 6
      when "c"
        CubicCommand(false) if @parameter.length == 6
      else
        @parameter = [] #consume parameters for unsupported commands
      end
    else
      DebugPuts "Malformed path command. Unknown token #{@cmd}"
    end

  end

  #---------------------------------------------------------------------
  # a "M" (abs=true) or "m" (abs=false) in the d="..." string
  #
  def MoveCommand(abs)
    #DebugPuts "Move"

    
    x0 = @parameter[0].to_f
    y0 = @parameter[1].to_f
    @parameter = []

    if !abs and @p0 != nil #relative AND not the first point
        x0 += @p0.x
        y0 += @p0.y
    end
    
    @p0 = Geom::Point3d.new(x0, y0)
    @ps = @p0 #all moves update initial point
    
    #Treat further points as implicit line commands
    if abs
        @cmd = 'L'
    else
        @cmd = 'l'
    end
  end

  #---------------------------------------------------------------------
  # a "L" (abs=true) or "l" (abs=false) in the d="..." string
  def LineCommand(abs)

    #DebugPuts "Line"

    x1 = @parameter[0].to_f
    y1 = @parameter[1].to_f
    @parameter = []
    
    if !abs and @p0 != nil #relative AND not the first point
        x1 += @p0.x
        y1 += @p0.y
    end

    p1 = Geom::Point3d.new(x1, y1);

    edge = @currGroup.entities.add_line( @p0, p1 )

    if (edge)
      @lastEdge = edge
    end

    @p0 = p1
  end

  #---------------------------------------------------------------------
  # a "C" (abs=true) or "c" (abs=false) in the d="..." string
  def CubicCommand(abs)

    #DebugPuts "CubicBezier"

    x1 = @parameter[0].to_f
    y1 = @parameter[1].to_f

    x2 = @parameter[2].to_f
    y2 = @parameter[3].to_f

    x3 = @parameter[4].to_f
    y3 = @parameter[5].to_f
    @parameter = []
    
    if !abs and @p0 != nil #relative AND not the first point
        x1 += @p0.x
        y1 += @p0.y
        x2 += @p0.x
        y2 += @p0.y
        x3 += @p0.x
        y3 += @p0.y
    end
    
    p1 = Geom::Point3d.new(x1, y1);
    p2 = Geom::Point3d.new(x2, y2);
    p3 = Geom::Point3d.new(x3, y3);

    ctrl = [@p0,p1,p2,p3];

    pts = Bezier::points( ctrl, 16 )

    edges = @currGroup.entities.add_curve( pts )

    if (edges)
      edge = edges[0]
      curve = edge.curve
      if (curve)
        curve.set_attribute "skp", "crvtype", "Bezier"
        curve.set_attribute "skp", "crvpts", ctrl
      end

      if (edge)
         @lastEdge = edge
      end

    end

    @p0 = p3
  end

  #---------------------------------------------------------------------
  # a "z" in the d="..." string
  def CloseCommand()

     #DebugPuts "Close"

     edge =@currGroup.entities.add_line( @p0, @ps )

     if (@lastEdge)
       @lastEdge.find_faces
       @lastEdge = nil
     end
     
     @p0 = @ps # current point becomes initial point
     
  end

  #---------------------------------------------------------------------
  # RECT
  #---------------------------------------------------------------------
  def DoRect( sugroup, x,y,rx,ry,w,h )
    #DebugPuts "Rect"

    if (ry!=0) and (rx==0) then rx=ry; end

    if (rx!=0) then # this rect is using arcs?

      if (ry==0) then ry=rx; end

      # the arc implementation here is a bit of a hack:
      # SVG uses two radi, but the standard add_arc call does not
      # allow that:
      # So I create a standard arc with 90 degrees and scale it.
      # Later I copy it to the correct position, as all 4 arcs are
      # rotated versions

      center = Geom::Point3d.new( 0, 0 )
      xaxis = Geom::Vector3d.new( 1.0, 0.0, 0.0 )
      normal = Geom::Vector3d.new( 0.0, 0.0, 1.0 )

      # To get the arc at once, I place it in a group that is later removed
      # todo: any other idea how to scale an arc in code?
      arcGroup = sugroup.entities.add_group
      arc = arcGroup.entities.add_arc( center, xaxis, normal, 1, 0.degrees, 90.degrees )
      matrix = [ rx,  0.0,  0.0, 0.0,
                 0.0,  ry,  0.0, 0.0,
                 0.0, 0.0,  1.0, 0.0,
                 -rx, -ry,  0.0, 1.0 ];
      # the matrix also moves it which makes the next movements simpler to read
      arcGroup.transform!( Geom::Transformation.new( matrix ) )
    end

    # the following comments are from the SVG Specification:

    # perform an absolute moveto operation to location (x+rx,y),
    # where x is the value of the 'rect' element's x attribute converted to user space,
    # rx is the effective value of the rx attribute converted to user space and
    # y is the value of the y attribute converted to user space
    ps = Geom::Point3d.new( x+rx, y)

    # perform an absolute horizontal lineto operation to location (x+width-rx,y),
    # where width is the 'rect' element's width attribute converted to user space
    pe = Geom::Point3d.new( x+w-rx,y )
    sugroup.entities.add_edges( ps, pe)
    ps = pe

    # perform an absolute elliptical arc operation to coordinate (x+width,y+ry),
    # where the effective values for the rx and ry attributes on the 'rect'
    # element converted to user space are used as the rx and ry attributes on
    # the elliptical arc command,
    # respectively, the x-axis-rotation is set to zero,
    # the large-arc-flag is set to zero,
    # and the sweep-flag is set to one
    if (rx!=0.0)
      dest = arcGroup.copy
      matrix = [ 1.0,  0.0,  0.0, 0.0,
                 0.0, -1.0,  0.0, 0.0,
                 0.0,  0.0,  1.0, 0.0,
                 x+w,    y,  0.0, 1.0 ];
      dest.transform!( Geom::Transformation.new( matrix ) )
      dest.explode
      ps = Geom::Point3d.new( x+w, y+ry )
    end

    # perform a absolute vertical lineto to location (x+width,y+height-ry),
    # where height is the 'rect' element's height attribute converted to user space

    pe = Geom::Point3d.new( x+w,y+h-ry )
    sugroup.entities.add_edges( ps, pe)
    ps = pe

    # perform an absolute elliptical arc operation to coordinate (x+width-rx,y+height)
    if (rx!=0.0)
      dest = arcGroup.copy
      matrix = [ 1.0,  0.0,  0.0, 0.0,
                 0.0,  1.0,  0.0, 0.0,
                 0.0,  0.0,  1.0, 0.0,
                 x+w,  y+h,  0.0, 1.0 ];
      dest.transform!( Geom::Transformation.new( matrix ) )
      dest.explode
      ps = Geom::Point3d.new( x+w-rx, y+h )
    end

    # perform an absolute horizontal lineto to location (x+rx,y+height)
    pe = Geom::Point3d.new( x+rx,y+h )
    sugroup.entities.add_edges( ps, pe)
    ps = pe

    # perform an absolute elliptical arc operation to coordinate (x,y+height-ry)
    if (rx!=0.0)
      dest = arcGroup.copy
      matrix = [ -1.0, 0.0,  0.0, 0.0,
                 0.0,  1.0,  0.0, 0.0,
                 0.0,  0.0,  1.0, 0.0,
                   x,  y+h,  0.0, 1.0 ];
      dest.transform!( Geom::Transformation.new( matrix ) )
      dest.explode
      ps = Geom::Point3d.new( x, y+h-ry )
    end

    # perform an absolute absolute vertical lineto to location (x,y+ry)
    pe = Geom::Point3d.new( x,y+ry )
    finalEdges = sugroup.entities.add_edges( ps, pe)
    ps = pe

    # perform an absolute elliptical arc operation to coordinate (x+rx,y)
    if (rx!=0.0)
      dest = arcGroup
      matrix = [ -1.0,  0.0,  0.0, 0.0,
                 0.0, -1.0,  0.0, 0.0,
                 0.0,  0.0,  1.0, 0.0,
                   x,    y,  0.0, 1.0 ];
      dest.transform!( Geom::Transformation.new( matrix ) )
      dest.explode
    end

    # finally: find=create a face for all these edges
    finalEdges[0].find_faces
  end


  def DoImage( sugroup, filename, x, y, width, height )

      # images are bit tricky:
      # to get it correctly, I mirror it and
      # move it to the right pos using a transformation

      pt = Geom::Point3d.new( 0.0,0.0 )
      w = width.to_f
      h = height.to_f

      img = sugroup.entities.add_image( filename, pt, w,h )
      x = x.to_f
      y = y.to_f + h
      matrix = [ 1.0, 0.0, 0.0, 0.0,
                 0.0,-1.0, 0.0, 0.0,
                 0.0, 0.0, 1.0, 0.0,
                   x,   y, 0.0, 1.0 ];

      img.transform! Geom::Transformation.new( matrix )

  end


  #---------------------------------------------------------------------
  # After the file was read, the final group comes here:
  #---------------------------------------------------------------------
  def DoFinalize( all )

    # fix coordinates from Inkscape (90 dots per inch)) to Sketchup (inch)
    scaling = 1.0/90.0
    
    if ($svgImportScriptScaling)
      scaling = scaling * $svgImportScriptScaling
    end

    # remove absolute positions
    bb = all.bounds
    min = bb.min
    max = bb.max

    px = -min.x*scaling
    py = (max.y)*scaling

    matrix = [ scaling,      0.0,   0.0, 0.0,
                   0.0, -scaling,   0.0, 0.0,
                   0.0,      0.0,  -1.0, 0.0,
                    px,       py,   0.0, 1.0 ];
    all.transform!( Geom::Transformation.new( matrix ) )

    #if ($svgScriptAutoExplode && (all.entities.count == 1)) then
    #  all.explode()
    #end
  end

  #---------------------------------------------------------------------
  # SVG File hierarchy
  #---------------------------------------------------------------------
  def Path(sugroup)

    attributes = @event[1]
    id = attributes["id"]
    d = attributes["d"]
    style = attributes["style"]
    transform = attributes["transform"]

    DoPathDef( sugroup, d )

    if (id) then sugroup.name = id; end
    if (style) then DoStyle( sugroup, style ); end
    if (transform) then DoTransform( sugroup, transform ); end

    IgnoreTag()
  end

  def Polygon(sugroup)
    attributes = @event[1]
    id = attributes["id"]
    DebugPuts "polygon not implemented"
    IgnoreTag()
  end
  
  def Polyline(sugroup)
    DebugPuts "Polyline not implemented"
    IgnoreTag()
  end
  
  #---------------------------------------------------------------------
  def Image(sugroup)
    # attributes:
    # 'style',
    # 'xlink:href',
    # 'filter'

    attributes = @event[1]
    x = attributes['x']
    y = attributes['y']
    width = attributes['width']
    height = attributes['height']
    filename = attributes['sodipodi:absref']
    transform = attributes["transform"]
    id = attributes["id"]

    if (filename and x and y and width and height)
      DoImage( sugroup, filename, x, y, width, height )
    end

    # additionaly the SVG file might define its own transformation
    if (transform) then DoTransform( sugroup, transform ); end

    # finally: The image itself is some kind of group, so there is no
    # need to have a group around.
    if (sugroup.entities.count == 1)
      sugroup.explode
    end

    IgnoreTag()
  end

  #---------------------------------------------------------------------
  def Rect(sugroup)
    attributes = @event[1]
    # attributes not used (yet):
    # 'fill'

    x = attributes['x']
    y = attributes['y']
    rx = attributes['rx']
    ry = attributes['ry']
    width = attributes['width']
    height = attributes['height']
    style = attributes['style']

    if (x) then x=x.to_f; end
    if (y) then y=y.to_f; end
    if (rx) then rx=rx.to_f; else rx = 0.0; end
    if (ry) then ry=ry.to_f; else ry = 0.0; end
    if (width) then width=width.to_f; end
    if (height) then height=height.to_f; end

    if (x and y and width and height)
      DoRect( sugroup, x,y,rx,ry,width,height )
    end

    transform = attributes["transform"]
    if (transform) then DoTransform( sugroup, transform ); end
    if (style) then DoStyle( sugroup, style ); end
    id = attributes["id"]
    if (id) then sugroup.name = id; end

    IgnoreTag()
  end

  def Line(sugroup)
    DebugPuts "Line not implemented"
    IgnoreTag()
  end

  def Group(sugroup)
    DebugPuts "Begin of Group"
    attributes = @event[1]
    while true
      case NextTag()
      when :tkEndOfTag then break;

      when :tk_group then Group( sugroup.entities.add_group )
      when :tk_path then Path( sugroup.entities.add_group )
      when :tk_image then Image( sugroup.entities.add_group )
      when :tk_rect then Rect( sugroup.entities.add_group )
      when :tk_line then Line( sugroup.entities.add_group )
      when :tk_polygon then Polygon( sugroup.entities.add_group )
      when :tk_polyline then Polyline( sugroup.entities.add_group )

      when :tk_text then IgnoreTag()
      when :tk_use then IgnoreTag()
      when :tk_flowroot then IgnoreTag()
      when :tk_a then IgnoreTag()

      else
        DebugUnexpected( 'group' )
        IgnoreTag()
      end
    end

    style = attributes["style"]

    id = attributes['inkscape:label']
    if (id==nil) then id = attributes['id']; end
    if (id) then sugroup.name = id; end

    transform = attributes["transform"]
    if (transform) then DoTransform( sugroup, transform ); end

    #if ($svgScriptAutoExplode && (sugroup.entities.count == 1)) then
    #  sugroup.explode()
    #end

    DebugPuts "End of Group"
  end

  def SVGBlock(sugroup)
    DebugPuts "Begin of SVG"
    while true
      case NextTag()
      when :tkEndOfTag then break

      when :tk_defs then IgnoreTag()
      when :tk_sodipodi_namedview then IgnoreTag()
      when :tk_metadata then IgnoreTag()
      when :tk_group then Group(sugroup.entities.add_group)
      when :tk_path then Path(sugroup.entities.add_group)
      when :tk_image then Image(sugroup.entities.add_group)
      when :tk_rect then Rect(sugroup.entities.add_group)
      when :tk_line then Line(sugroup.entities.add_group)
      when :tk_polyline then PolyLine(sugroup.entities.add_group)
      when :tk_polygon then Polygon(sugroup.entities.add_group)
      when :tk_text then IgnoreTag()
      when :tk_use then IgnoreTag()
      when :tk_script then IgnoreTag()
      when :tk_title then IgnoreTag()
      when :tk_desc then IgnoreTag()
      when :tk_flowRoot then IgnoreTag()
      when :tk_style then IgnoreTag()
      when :tk_a then IgnoreTag()
      else
        DebugUnexpected( 'svg' );
        IgnoreTag()
      end
    end
    
    DebugPuts "end of SVG"
  end

  def TopLevel(entities)

    all = entities.add_group
    all.name = "SVG"

    while @xml.has_next?
      event = @xml.pull
      case event.event_type
      when :start_element then
          case String2Token(event[0])
          when :tk_svg then
            SVGBlock(all)
          else
            IgnoreTag()
          end
      end
    end

    DoFinalize( all )

    #if ($svgScriptAutoExplode && (all.entities.count == 1)) then
    #  all.explode()
    #end

    return all
  end

  #--------------------------------------------------------------------------
  # General
  #--------------------------------------------------------------------------
  def ParseFile( filename )
    if (filename == nil) then return nil; end

    model = Sketchup.active_model
    model.start_operation "Import SVG File"
    begin
      DebugPuts "Parsing: "+ filename
      entities = model.active_entities

      f = File.new( filename, 'r' )
      begin
        @xml = REXML::Parsers::PullParser.new( f )
        model.selection.clear
        model.selection.add TopLevel(entities)
      ensure
        f.close
      end

      model.commit_operation

    rescue => bang
      if (model)
        model.abort_operation
      end
      UI.messagebox( "Error (in script) while reading \"" + filename + "\":\n" + bang )
    end
  end
end
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
# Quick Debug Code, can be called by the ruby console
def svgParserTest(file=File.dirname(__FILE__)+'/test.svg')
  was = $svgImportScriptDebug
  begin
    $svgImportScriptDebug = true
    f = SVGFileImport.new()
    f.ParseFile( file )
  ensure
    $svgImportScriptDebug = was
  end
end
#--------------------------------------------------------------------------

def DoSVGImport
    filename = UI.openpanel "Import SVG File",nil,"*.svg"
    if (filename)
      f = SVGFileImport.new()
      f.ParseFile( filename )
    end
end

#--------------------------------------------------------------------------
# Register within Sketchup
if(file_loaded("svg.rb"))
  menu = UI.menu("Plugins");
  menu.add_item("Import SVG File...") { DoSVGImport() }
end

#--------------------------------------------------------------------------
file_loaded("svg.rb")

