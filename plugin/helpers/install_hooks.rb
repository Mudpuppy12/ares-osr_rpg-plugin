module AresMUSH
  module OsrRpg
    module InstallHooks
      BACKUP_SIZE_THRESHOLD = 200

      SERVER_HOOKS = {
        'chargen/custom_app_review.rb' => File.join(AresMUSH.plugin_path, 'chargen', 'custom_app_review.rb'),
        'profile/custom_char_fields.rb' => File.join(AresMUSH.plugin_path, 'profile', 'custom_char_fields.rb'),
        'scenes/custom_char_card.rb' => File.join(AresMUSH.plugin_path, 'scenes', 'custom_char_card.rb'),
        'website/custom_web_data.rb' => File.join(AresMUSH.plugin_path, 'website', 'custom_web_data.rb')
      }.freeze

      PORTAL_HOOK_FILES = %w[
        chargen-custom-tabs.hbs
        chargen-custom.hbs
        chargen-custom.js
        profile-custom-tabs.hbs
        profile-custom.hbs
        live-scene-custom-play.hbs
        live-scene-custom-play.js
        char-card-custom-tabs.hbs
        char-card-custom-tabs-content.hbs
        sidebar-custom.hbs
      ].freeze

      OSR_ROUTES = [
        "router.route('osr-rpg-spells', { path: '/osr_rpg/spells' });",
        "router.route('osr-rpg-spell-detail', { path: '/osr_rpg/spells/:tradition/:level/:name' });",
        "router.route('osr-rpg-equipment', { path: '/osr_rpg/equipment' });",
        "router.route('osr-rpg-shop', { path: '/osr_rpg/shop' });"
      ].freeze

      WEBSITE_NAV = {
        'Play' => [{ 'title' => 'Equipment Shop', 'route' => 'osr-rpg-shop' }],
        'System' => [
          { 'title' => 'Spell Lists', 'route' => 'osr-rpg-spells' },
          { 'title' => 'Equipment List', 'route' => 'osr-rpg-equipment' }
        ]
      }.freeze

      def self.install_dir
        File.join(OsrRpg.plugin_dir, 'install')
      end

      def self.backup_dir
        dir = File.join(install_dir, 'backups', Time.now.strftime('%Y%m%d%H%M%S'))
        FileUtils.mkdir_p(dir)
        dir
      end

      def self.copy_with_backup(src, dest, backup_root, messages)
        if File.exist?(dest)
          size = File.size(dest)
          if size > BACKUP_SIZE_THRESHOLD
            backup_path = File.join(backup_root, dest.sub(%r{^/}, ''))
            FileUtils.mkdir_p(File.dirname(backup_path))
            FileUtils.cp(dest, backup_path)
            messages << t('osr_rpg.install_backed_up', dest: dest, size: size)
          end
        end
        FileUtils.mkdir_p(File.dirname(dest))
        FileUtils.cp(src, dest)
        messages << t('osr_rpg.install_installed', dest: dest)
      end

      def self.install_server_hooks(backup_root, messages)
        SERVER_HOOKS.each do |rel, dest|
          src = File.join(install_dir, 'server_hooks', rel)
          next unless File.exist?(src)

          copy_with_backup(src, dest, backup_root, messages)
        end
      end

      def self.portal_components_path
        File.join(AresMUSH.website_code_path, 'app', 'components')
      end

      def self.portal_hooks_source
        bundled = File.join(install_dir, 'portal_hooks')
        return bundled if File.directory?(bundled)

        repo = File.expand_path(File.join(OsrRpg.plugin_dir, '..', '..', 'webportal', 'components'))
        return repo if File.directory?(repo)

        portal_components_path
      end

      def self.install_portal_hooks(backup_root, messages)
        components_src = portal_hooks_source

        PORTAL_HOOK_FILES.each do |name|
          src = File.join(components_src, name)
          next unless File.exist?(src)

          dest = File.join(portal_components_path, name)
          copy_with_backup(src, dest, backup_root, messages)
        end
      end

      def self.install_styles(backup_root, messages)
        src = File.join(install_dir, 'osr_rpg_chargen.scss')
        dest = File.join(AresMUSH.game_path, 'styles', 'osr_rpg_chargen.scss')
        return unless File.exist?(src)

        copy_with_backup(src, dest, backup_root, messages)

        custom_style = File.join(AresMUSH.game_path, 'styles', 'custom_style.scss')
        return unless File.exist?(custom_style)

        text = File.read(custom_style)
        if text.include?('osr_rpg_chargen.scss')
          messages << t('osr_rpg.install_styles_already_imported')
        else
          File.open(custom_style, 'a') do |f|
            f.puts ''
            f.puts '@import "osr_rpg_chargen.scss";'
          end
          messages << t('osr_rpg.install_styles_import_added')
        end
      end

      def self.install_routes(backup_root, messages)
        routes_file = File.join(AresMUSH.website_code_path, 'custom-routes.js')
        unless File.exist?(routes_file)
          messages << t('osr_rpg.install_routes_missing', path: routes_file)
          return
        end

        text = File.read(routes_file)
        if text.include?('osr-rpg-spells')
          messages << t('osr_rpg.install_routes_already_present')
          return
        end

        marker = 'export default function setupCustomRoutes(router) {'
        unless text.include?(marker)
          messages << t('osr_rpg.install_routes_marker_missing')
          return
        end

        backup_path = File.join(backup_root, 'custom-routes.js')
        FileUtils.cp(routes_file, backup_path)
        routes_block = "\n  #{OSR_ROUTES.join("\n  ")}\n"
        text = text.sub(marker, "#{marker}#{routes_block}")
        File.write(routes_file, text)
        messages << t('osr_rpg.install_routes_merged')
      end

      def self.menu_has_route?(menu, route)
        return false if menu.nil?

        menu.any? do |item|
          item['route'] == route || item[:route] == route
        end
      end

      def self.append_menu_items(menu, items)
        menu ||= []
        items.each do |item|
          next if menu_has_route?(menu, item['route'])

          menu << item
        end
        menu
      end

      def self.merge_website_config(messages)
        path = File.join(AresMUSH.game_path, 'config', 'website.yml')
        unless File.exist?(path)
          messages << t('osr_rpg.install_website_missing', path: path)
          return
        end

        data = YAML.load_file(path) || {}
        website = data['website'] ||= {}

        navbar = website['top_navbar'] || []

        WEBSITE_NAV.each do |nav_title, items|
          entry = navbar.find { |e| e['title'] == nav_title }
          if entry
            entry['menu'] = append_menu_items(entry['menu'], items)
          else
            navbar << { 'title' => nav_title, 'menu' => items.dup }
          end
        end

        website['top_navbar'] = navbar
        if website['character_gallery_group'].blank?
          website['character_gallery_group'] = 'Kingdom'
          messages << t('osr_rpg.install_website_gallery_group_set')
        end
        if website['character_gallery_subgroup'].blank?
          website['character_gallery_subgroup'] = 'Region'
          messages << t('osr_rpg.install_website_gallery_subgroup_set')
        end

        data['website'] = website
        File.write(path, data.to_yaml)
        Global.config_reader.load_game_config
        messages << t('osr_rpg.install_website_merged')
      end

      def self.run
        messages = []
        backup_root = backup_dir
        messages << t('osr_rpg.install_start')

        install_server_hooks(backup_root, messages)
        install_portal_hooks(backup_root, messages)
        install_styles(backup_root, messages)
        install_routes(backup_root, messages)
        merge_website_config(messages)

        messages << t('osr_rpg.install_done', backup: backup_root)
        messages << t('osr_rpg.install_next_steps')
        messages
      end

      def self.check
        issues = []
        warnings = []

        SERVER_HOOKS.each_value do |path|
          if !File.exist?(path)
            issues << t('osr_rpg.install_check_missing', path: path)
          elsif !File.read(path).include?('osr_rpg')
            issues << t('osr_rpg.install_check_invalid', path: path)
          end
        end

        PORTAL_HOOK_FILES.each do |name|
          path = File.join(portal_components_path, name)
          issues << t('osr_rpg.install_check_missing', path: path) unless File.exist?(path)
        end

        routes_file = File.join(AresMUSH.website_code_path, 'custom-routes.js')
        if !File.exist?(routes_file) || !File.read(routes_file).include?('osr-rpg-shop')
          issues << t('osr_rpg.install_check_routes')
        end

        custom_style = File.join(AresMUSH.game_path, 'styles', 'custom_style.scss')
        if !File.exist?(custom_style) || !File.read(custom_style).include?('osr_rpg_chargen.scss')
          issues << t('osr_rpg.install_check_styles')
        end

        website_path = File.join(AresMUSH.game_path, 'config', 'website.yml')
        if File.exist?(website_path)
          data = YAML.load_file(website_path) || {}
          navbar = data.dig('website', 'top_navbar') || []
          play = navbar.find { |e| e['title'] == 'Play' }
          system = navbar.find { |e| e['title'] == 'System' }
          warnings << t('osr_rpg.install_check_nav_play') unless menu_has_route?(play&.dig('menu'), 'osr-rpg-shop')
          warnings << t('osr_rpg.install_check_nav_spells') unless menu_has_route?(system&.dig('menu'), 'osr-rpg-spells')
          warnings << t('osr_rpg.install_check_nav_equipment') unless menu_has_route?(system&.dig('menu'), 'osr-rpg-equipment')
        else
          warnings << t('osr_rpg.install_check_website_missing')
        end

        { issues: issues, warnings: warnings }
      end
    end
  end
end
