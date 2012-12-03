module TahoeTray

  class Resources

    def self.base_dir
      "#{File.dirname(__FILE__)}/share/"
    end

    def self.get_icon(name)
      File.join base_dir, 'icons', name
    end
    
    def self.get_glade(name)
      File.join base_dir, 'glade', name
    end

    def self.app_desktop_file
      File.join base_dir, 'applications/tahoe-lafs-indicator.desktop'
    end

  end

end

