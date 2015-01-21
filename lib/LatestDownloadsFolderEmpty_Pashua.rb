#!/usr/bin/ruby

#
# USAGE INFORMATION:
# As you can see this text, you obviously have opened the file in a text editor.
# 
# If you would like to *run* this example rather than *read* it, you
# should open Terminal.app, drag this document's icon onto the terminal
# window, bring Terminal.app to the foreground (if necessary) and hit return.
# 

# This example code was contributed by Mike Hall. It uses a module
# Pashua.rb, which is expected to be located either in this script's
# parent directory or in some standard Ruby search path. Please note
# the comments at the top of Pashua.rb.

def downloadsFolderEmpty(destPhoto, folderPhotoCount)

$:.push(File.dirname($0))

# require 'Pashua'
include Pashua

config = <<EOS
# Set transparency: 0 is transparent, 1 is opaque
*.transparency=0.95

# Set window title
*.title = Latest Downloads Folder Empty?

# Introductory text
txt.type = text
txt.default = There are #{folderPhotoCount} photos in the Lastest Downloads Folder and they should be deleted or they will be reprocessed during the adding of gps coordinates.[return][return]You can delete them and the come back and continue. (Or this program could be set up to do that.)[return][return]The path to Latest Download Folder is:[return][return]#{destPhoto}
txt.height = 276
txt.width = 310
txt.x = 44
txt.y = 64


tf2.type = text
# tf2.label =
tf2.default = #{Dir.entries(destPhoto)}
tf2.width = 310
#
# # Add a filesystem browser
# ob.type = openbrowser
# ob.label = Example filesystem browser (textfield + open panel)
# ob.width=310
# ob.tooltip = Blabla filesystem browser
#
# # Define radiobuttons
# rb.type = radiobutton
# rb.label = Example radiobuttons
# rb.option = Radiobutton item #1
# rb.option = Radiobutton item #2
# rb.option = Radiobutton item #3
# rb.option = Radiobutton item #4
# rb.default = Radiobutton item #2
#
# # Add a popup menu
# pop.type = popup
# pop.label = Example popup menu
# pop.width = 310
# pop.option = Popup menu item #1
# pop.option = Popup menu item #2
# pop.option = Popup menu item #3
# pop.default = Popup menu item #2
#
# # Add a checkbox
# chk1.type = checkbox
# chk1.label = Pashua offers checkboxes, too
# chk1.rely = -18
# chk1.default = 1
#
# # Add another one
# chk2.type = checkbox
# chk2.label = But this one is disabled
# chk2.disabled = 1

# Add a cancel button with default label
cb.type = cancelbutton

EOS

# Set the images' paths relative to this file's path / 
# skip images if they can not be found in this file's path
icon  = File.dirname($0) << "/.icon.png";
bgimg = File.dirname($0) << "/.demo.png";

if File::exists?(icon)
	# Display Pashua's icon
	Config << "img.type = image
	img.x = 530
	img.y = 255
	img.path = #{icon}
	"
end

if File::exists?(bgimg)
	# Display Pashua's icon
	Config << "bg.type = image
	bg.x = 30
	bg.y = 2
	bg.path = #{bgimg}
	"
end

res = pashua_run(config, 'utf8')

if res['cb'] == "1"
  puts "Looks like the dialog was cancelled"
else
  puts "Pashua returned the following values:"
  puts " cb  = #{res['cb']}"
  puts " pop  = #{res['pop']}"
  puts " rb   = #{res['rb']}"
  puts " ob   = #{res['ob']}"
  puts " tf   = #{res['tf']}"
  puts " chk  = #{res['chk']}"
end
end