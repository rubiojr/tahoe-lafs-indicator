# encoding: utf-8
require 'gtk2'
require 'tahoetray/resources'
require 'tahoetray/threading_hack'
require 'tahoetray/notify'
require 'thread'
require 'excon'
require 'json'
require 'tahoetray/preferences_dialog'
require 'ruby-libappindicator'

module TahoeTray

  class NotificationAreaIcon
    def start
      @thread = Thread.start do
        loop do
          begin
            response = Excon.get "http://localhost:3456/status/?t=json"
            if (JSON.parse response.body)['active'].size > 0
              animate
            else
              stop_animation
            end
          rescue Exception => e
            Log.error "Error fetching status from gateway"
            Log.error e.message
            Log.debug e.backtrace
          end
          sleep 1 
        end
      end
    end

    private
    def stop_animation
    end

    def animate
    end
    
    def create_menues
      @info = Gtk::ImageMenuItem.new(Gtk::Stock::INFO)
      @info.signal_connect('activate'){ }
      @preferences = Gtk::ImageMenuItem.new(Gtk::Stock::PREFERENCES)
      @preferences.signal_connect('activate') do
        unless defined?(@preferences_dialog) and @preferences_dialog
          @preferences_dialog = PreferencesDialog.new
          @preferences_dialog.run
          @preferences_dialog = nil
        end
      end
      @about = Gtk::ImageMenuItem.new(Gtk::Stock::ABOUT)
      @about.signal_connect('activate') do
        d = Gtk::AboutDialog.new
        d.name = 'Tahoe-LAFS Indicator'
        d.version = TahoeTray::VERSION
        d.logo_icon_name = 'tahoe-lafs'
        d.copyright = '© 2012 Sergio Rubio'
        d.comments = "Tahoe-LAFS Activity Monitor"
        d.website = "http://tahoetray.frameos.org"
        d.authors = ["Sergio Rubio <rubiojr@frameos.org>"]
        d.artists = ["Kevin Reid\nhttps://en.wikipedia.org/wiki/File:Tahoe-LAFS-logo-kpreid-2.svg"]
        d.program_name = 'Tahoe-LAFS Indicator'
        d.signal_connect('response') { d.destroy }
        d.run
      end
      @quit= Gtk::ImageMenuItem.new(Gtk::Stock::QUIT)
      @quit.signal_connect('activate'){ Gtk.main_quit }
      @menu = Gtk::Menu.new
      @menu.append(@info)
      @menu.append(Gtk::SeparatorMenuItem.new)
      @menu.append(@preferences)
      @menu.append(@about)
      @menu.append(@quit)
      @menu.show_all
    end
  end

  #
  # StatusIcon
  # http://ruby-gnome2.sourceforge.jp/hiki.cgi?Gtk%3A%3AStatusIcon
  #
  class StatusIcon < NotificationAreaIcon

    def initialize
      @icon = Gtk::StatusIcon.new
      @off_icon = Gdk::Pixbuf.new(TahoeTray::Resources.get_icon('tahoe-lafs.svg'))
      @icon.pixbuf = @off_icon
      @icon.tooltip ='Tahoe-LAFS'

      # 
      # Send files animation
      #
      @frames = []
      1.upto(3) do |i| 
        icon = TahoeTray::Resources.get_icon("tahoe-lafs-#{i}.svg")
        @frames << Gdk::Pixbuf.new(icon)
      end
      @active = false
      @animate_thread = nil
      @builder = Gtk::Builder.new

      create_menues
    end


    private
    def stop_animation
      if @animate_thread and @animate_thread.alive?
        @animate_thread.kill
        Gtk.queue do
          Log.debug 'Stop status icon animation'
          @icon.pixbuf = @off_icon 
        end
      end
    end

    def animate
      return if @animate_thread and @animate_thread.alive?
      @animate_thread = Thread.start do
        loop do
          1.upto(3) do |i|
            sleep 0.3
            Gtk.queue do
              @icon.pixbuf = @frames[i - 1]
            end
          end
        end
      end
    end

    def create_menues
      super
      @icon.signal_connect('button_press_event') do |widget, event|
        if event.button == 1
          @menu.popup(nil, nil, event.button, event.time) do
            @icon.position_menu(@menu)
          end
        end
      end
    end

  end
  
  class Indicator < NotificationAreaIcon

    def initialize
      @off_indicator = 'tahoe-lafs'
      @indicator = AppIndicator::AppIndicator.new "Tahoe-LAFS", 
                                                  @off_indicator, 
                                                  AppIndicator::Category::APPLICATION_STATUS
      @indicator.set_icon_theme_path TahoeTray::Resources.base_dir + "/icons"
      @indicator.set_status AppIndicator::Status::ACTIVE

      @frames = %w[tahoe-lafs-1 tahoe-lafs-2 tahoe-lafs-3]
      @animate_thread = nil
      @gw_url = Settings.load[:gateway_url] + "/status/?t=json"

      create_menues
    end

    private
    def stop_animation
      if @animate_thread and @animate_thread.alive?
        # Do not notify more than once every 60 secods
        @animate_thread.kill
        Gtk.queue do
          Log.debug 'Stop status icon animation'
          @indicator.set_icon_full @off_indicator, "Inactive"
        end
      end
    end

    def animate
      return if @animate_thread and @animate_thread.alive?
      @animate_thread = Thread.start do
        loop do
          1.upto(3) do |i|
            sleep 0.3
            Gtk.queue do
              @indicator.set_icon_full @frames[i - 1], "Transfers in progress"
            end
          end
        end
      end
    end

    def create_menues 
      super
      @indicator.set_menu @menu
    end

  end

end
