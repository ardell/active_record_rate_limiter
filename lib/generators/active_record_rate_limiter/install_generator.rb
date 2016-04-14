module ActiveRecordRateLimiter
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def copy_migrations
        migration_dir = 'db/migrate'
        migration_file_name = 'install_active_record_rate_limiter.rb'

        if self.class.migration_exists?(migration_dir, migration_file_name)
          say_status 'skipped', "Migration #{migration_filename} already exists."
        else
          target_path = File.join(migration_dir, migration_file_name)
          migration_template migration_file_name, target_path
        end
      end

      def self.next_migration_number(path)
        @migration_number = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i.to_s
      end
    end
  end
end

