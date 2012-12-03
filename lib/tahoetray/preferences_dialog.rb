require 'uri'

module TahoeTray
  class PreferencesDialog
    def initialize
      @builder = Gtk::Builder.new
      @builder.add_from_file TahoeTray::Resources.get_glade('preferences.glade')
      @autostart_file = File.join ENV['HOME'], '.config/autostart/tahoe-lafs-indicator.desktop'
      if File.exist? @autostart_file
        @builder['autostart_check'].set_active true
      end

      @settings = TahoeTray::Settings.load
      if @settings[:gateway_url]
        @builder['gateway_url_entry'].text = @settings[:gateway_url] 
      else
        @builder['gateway_url_entry'].text = 'http://localhost:3456' 
      end

      @builder['prefs_autostart_action'].signal_connect('activate') do
        activate_autostart_callback
      end

      @builder['close_btn'].signal_connect 'clicked' do
        close_callback
      end
    end

    def run
      @builder['preferences_dialog'].run
    end
    
    private
    def activate_autostart_callback
      if @builder['autostart_check'].active?
        File.open @autostart_file, 'w' do |f|
          f.puts File.read(TahoeTray::Resources.app_desktop_file)
          f.puts "X-GNOME-Autostart-enabled=true"
        end 
      else
        File.delete @autostart_file if File.exist?(@autostart_file)
      end
    end

    def close_callback
      begin
        url = @builder['gateway_url_entry'].text
        URI.parse url
        @settings[:gateway_url] = url
        @settings.save
        @builder['preferences_dialog'].destroy
      rescue URI::InvalidURIError
        error = Gtk::MessageDialog.new @builder['preferences_dialog'],
                                       Gtk::Dialog::MODAL,
                                       Gtk::MessageDialog::WARNING,
                                       Gtk::MessageDialog::BUTTONS_CLOSE,
                                       "Invalid gateway URL"
        error.secondary_text = "The Tahoe-LAFS Gateway URL is not a valid URL."
        error.run
        error.destroy
      end
    end

  end
end
