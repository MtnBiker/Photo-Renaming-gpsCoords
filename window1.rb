# https://chatgpt.com/c/6775e2f5-d164-8012-bd15-d90e1d9e41db
#  First round of this in /Users/gscar/Documents/Ruby/Glimmer/myGlimmerTrials/radio_buttons_less_generic.rb

require 'glimmer-dsl-libui'

class RadioButtonExample
  include Glimmer

  def initialize
    @photos_from_option_index = 0 # Default selected option index
    @photos_from = ['SD card to be selected below (or in next window)', 'Process photos from an SD card or on a hard drive to be selected below (or next window)']
    @special_options_index = 0
    @special_options = ["Rename the files only and do not move.", "Add GPS coordinates while leaving photos in place. SELECT LOCATION OPTIONS ABOVE ALSO"]
  end

  def launch
    window('SD card or photos on hard drive', 300, 200) do
      margined true
       
      # Selecting location of photos. Radio button, one or the other
      vertical_box do
        # text = 'Process photos from an SD card or on a hard drive to be selected below (or next window)' # Doesn't show up, but has been replaced by the line below
        label('Where are the photos:')
        # stretchy false
            
        @location_selected = radio_buttons do
          items @photos_from
          selected @photos_from_option_index # Default to the first option
        end # location_selected
        
        horizontal_box do
          button('Cancel') do
            on_clicked do
              puts "Action canceled! [This isn't working at the moment and will crash. May be fixed]"
              destroy # Closes the current window # Closes the application window
            end
          end
          button('OK') do
            on_clicked do
              # Safely retrieve the selected option
              # selected_index = @location_selected.selected
              # puts "You confirmed: #{@photos_from[selected_index]}"
              selected_index = @location_selected.selected
              selected_text = @photos_from[selected_index]
              puts "You confirmed option ##{selected_index + 1}: #{selected_text}"
            end
          end
        end # horizontal_box for buttons
        
        # With the Pashua implementation I was sending three selections: location, rename (in place) and add GPS coordinates. Not sure if the latter two worked if selected an SD card.
        # This is checkboxes, 0, 1 or 2 selections
        # Selecting subset of normal operation
        vertical_box do
          # text = 'Process photos from an SD card or on a hard drive to be selected below (or next window)' # Doesn't show up, but has been replaced by the line below
          label("••  Select options below to perform one or more operations.   ••\n••  If you want them all, select one of the two options above   ••")
          
         
          # Not sure how the OK will be done
          # horizontal_box do
          #   button('Cancel') do
          #     on_clicked do
          #       puts "Action canceled! [This isn't working at the moment and will crash]"
          #       close # Closes the application window
          #     end
          #   end
          #   button('OK') do
          #     on_clicked do
          #       # Safely retrieve the selected option
          #       # selected_index = @radio_buttons.selected
          #       # puts "You confirmed: #{@photos_from[selected_index]}"
          #       selected_index = @radio_buttons.selected
          #       selected_text = @photos_from[selected_index]
          #       puts "You confirmed option ##{selected_index + 1}: #{selected_text}"
          #     end
          #   end
          end # second vertical box 
      end # window
    end.show
  end # launch
end # class

RadioButtonExample.new.launch

