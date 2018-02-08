#-----------------------------------------------------------------------------
#  Copyright (C) 2018 Samuel Tallet-Sabathé
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
#  SVG File Import for Inkscape files (Version 0.6)
#
#  This script allows to use Inkscape to create 2D images (for example by
#  using Inkscapes bitmap vectorizer) and to create SketchUp group(s)
#  from the SVG File Inkscape has written.
#
#  The code will try to keep the hierarchy of the SVG file, so you
#  will get a whole tree of groups if you had one in your SVG File.
#
#-----------------------------------------------------------------------------

require 'sketchup.rb'
require 'extensions.rb'

module SVGImport

	#---------------------------------------
	# Define convenient constants like PATH.
	# Since: Version 0.6
	#---------------------------------------

	PATH = File.join( File.expand_path(File.dirname(__FILE__)), 'svg_import' )
	LIB_PATH = File.join(PATH, 'libraries')

	#----------------------------------------
	# Register within SketchUp, standard way.
	# Since: Version 0.6
	#----------------------------------------

	extension = SketchupExtension.new('SVG Import', File.join(PATH, 'loader'))
	# See: svg_import/loader.rb
	
	extension.version = '0.6'
	extension.creator = 'Samuel Tallet-Sabathé, Spencer Bliven, Uli Tessel'
	extension.copyright = '2018-2008 ' + extension.creator
	extension.description = 'Use it to import simple SVG images into SketchUp, where they can be extruded into 3D and further modified.'

	if Sketchup.register_extension(extension, true)
  		UI.menu('Plugins').add_item('Import SVG File...') { SVGImport::do() }
  	end

end
