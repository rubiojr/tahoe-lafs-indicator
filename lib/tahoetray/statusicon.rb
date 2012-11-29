# encoding: utf-8
require 'gtk2'
require 'tahoetray/resources'
require 'tahoetray/threading_hack'
require 'tahoetray/notify'
require 'thread'
require 'excon'
require 'json'

module TahoeTray

  #
  # StatusIcon
  # http://ruby-gnome2.sourceforge.jp/hiki.cgi?Gtk%3A%3AStatusIcon
  #
  class StatusIcon 

    def initialize
      @icon = Gtk::StatusIcon.new
      @off_icon = Gdk::Pixbuf.new(TahoeTray::Resources.get_icon('tahoe-lafs.svg'))
      @icon.pixbuf = @off_icon
      @icon.tooltip ='Tahoe Lafs'
      #@settings = Settings.load

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

      create_menues
    end

    def start
      @thread = Thread.start do
        loop do
          response = Excon.get "http://localhost:3456/status/?t=json"
          if (JSON.parse response.body)['active'].size > 0
            animate
          else
            stop_animation
          end
          sleep 1 
        end
      end
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
      @info = Gtk::ImageMenuItem.new(Gtk::Stock::INFO)
      @info.signal_connect('activate'){ }
      @about = Gtk::ImageMenuItem.new(Gtk::Stock::ABOUT)
      @about.signal_connect('activate') do
        d = Gtk::AboutDialog.new
        d.name = 'Tahoe-LAFS Status Icon'
        d.version = TahoeTray::VERSION
        d.logo_icon_name = 'tahoe-lafs'
        d.copyright = '© 2012 Sergio Rubio'
        d.comments = "Tahoe-LAFS Activity Monitor"
        d.website = "http://tahoetray.frameos.org"
        d.authors = ["Sergio Rubio <rubiojr@frameos.org>"]
        d.artists = ["Kevin Reid\nhttps://en.wikipedia.org/wiki/File:Tahoe-LAFS-logo-kpreid-2.svg"]
        d.program_name = 'Tahoe-LAFS Status Icon'
        d.signal_connect('response') { d.destroy }
        d.run
      end
      @quit= Gtk::ImageMenuItem.new(Gtk::Stock::QUIT)
      @quit.signal_connect('activate'){ Gtk.main_quit }
      @menu = Gtk::Menu.new
      @menu.append(@info)
      @menu.append(@about)
      @menu.append(@quit)
      @menu.show_all
      @icon.signal_connect('button_press_event') do |widget, event|
        if event.button == 1
          @menu.popup(nil, nil, event.button, event.time) do
            @icon.position_menu(@menu)
          end
        #elsif event.button == 3
        #  @menu.popup(nil, nil, event.button, event.time) do
        #    @icon.position_menu(@status_menu)
        #  end
        #else
        end
      end
    end

  end

end
