Sketch SVG Importer
===================

This is a plugin for Sketchup versions 6+. Use it to import simple SVG images
into sketchup, where they can be extruded into 3D and further modified.

# Dependencies

* The Bezier.rb plugin, available from the
  [Ruby Library Depot](http://rhin.crai.archi.fr/RubyLibraryDepot/plugin_details.php?id=33)
* The rexml ruby library
* forwardable.rb
* set.rb

Forwardable and set shipped with a standard ruby installation. REXML should
come with 1.8, but sketchup seems to expect it to be located inside the plugins
folder. Just copy the directory to your plugins directory.

# Installation

Copy svg.rb to your plugins folder. On Windows, this will be *C:\Program Files\Google\Google SketchUp #\Plugins*.
On a Mac, *~/Library/Application Support/Google SketchUp #/SketchUp/plugins*.
Bezier.rb can be installed the same way.

Installing the other three dependencies can be troublesome. Some instructions
for getting them on Windows are given in
[this thread](http://sketchucation.com/forums/viewtopic.php?f=323&p=258154).

On a Mac using MacPorts, forwarded.rb and set.rb were loaded automatically
(since Macs ship with Ruby). I used the following commands to install rexml.

    sudo port install rb-rexml
    ln -s /opt/local/lib/ruby/vendor_ruby/1.8/rexml "~/Library/Application Support/Google SketchUp 8/SketchUp/plugins"

# Usage

The plugin adds a 'Import SVG File...' option in the Plugins menu. The SVG will
be imported into a new group. The object structure within the SVG will be
preserved, meaning that groups of objects within the SVG will become nested
groups in Sketchup. Note that several explode operations may be required to
move geometry into the top-level model.

# Limitations

The plugin can currently handle only a limited subset of the SVG format. Unsupported features typically print a warning to the ruby console and then are ignored.

When using Inkscape, the following hints can produce simpler, more compatible svg output

* Convert all objects to paths before exporting (text, polygons, etc)
* In 'Inkscape Preferences>SVG Output', disable 'Allow relative coordinates' and enable 'Force repeat commands'
* Save files as 'Plain SVG' ('Simple SVG' in some locales)

(Suggested by Sketchucation user [TIG](http://sketchucation.com/forums/viewtopic.php?f=180&t=13475))

# Known Conflicts

The SVG Importer uses set.rb, which conflicts with Sketchup's built-in Set
class. This causes problems with some programs which require Set, namely smoove
from Sandbox Tools.

# License

Code is released under [GPL 3](http://www.gnu.org/licenses). See LICENSE for
the full terms.

# History

0.4     SVG compatibility improvements (Spencer Bliven)

0-0.3   Copyright (C) 2008 Uli Tessel (utessel@gmx.de)
