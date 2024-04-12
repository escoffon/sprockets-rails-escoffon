require 'rake'
require 'rake/sprocketstask'
require 'sprockets'
require 'action_view'

module Sprockets
  module Rails
    class Task < Rake::SprocketsTask
      attr_accessor :app

      def initialize(app = nil)
        #print("++++++++++ Sprockets::Rails::Task.new - #{app}\n")
        self.app = app
        super()
      end

      def environment
        if app
          #print("++++++++++ Sprockets::Rails::Task.environment - app.assets: #{app.assets}\n")
          # Use initialized app.assets or force build an environment if
          # config.assets.compile is disabled
          #print("++++++++++ Sprockets::Rails::Task.environment returns #{app.assets || Sprockets::Railtie.build_environment(app)}\n")
          app.assets || Sprockets::Railtie.build_environment(app)
        else
          super
        end
      end

      def output
        if app
          config = app.config
          File.join(config.paths['public'].first, config.assets.prefix)
        else
          super
        end
      end

      def assets
        if app
          app.config.assets.precompile
        else
          super
        end
      end

      def manifest
        if app
          Sprockets::Manifest.new(index, output, app.config.assets.manifest)
        else
          super
        end
      end

      def define
        namespace :assets do
          %w( environment precompile clean clobber ).each do |task|
            Rake::Task[task].clear if Rake::Task.task_defined?(task)
          end

          # Override this task change the loaded dependencies
          desc "Load asset compile environment"
          task :environment do
            # Load full Rails environment by default
            Rake::Task['environment'].invoke
          end

          desc "Compile all the assets named in config.assets.precompile"
          task :precompile => :environment do
            with_logger do
              #++ manifest.compile(assets)
              #++ START
              print("\n++++++++++ assets:precompile will run manifest.compile (#{assets})\n")
              filenames = manifest.compile(assets)
              print("\n++++++++++ assets:precompile did run manifest.compile, filenames:\n")
              if filenames.is_a?(Array)
                filenames.each do |fn|
                  stat = File.stat(fn)
                  if (stat.is_a?(File::Stat))
                    print("  ++++++++ asset:precompile filename #{fn} ftype: #{stat.ftype}\n")
                  else
                    print("  ++++++++ asset:precompile filename #{fn} File.stat failed\n")
                  end
                end
              end
              print("\n++++++++++ assets:precompile contents of #{output}:\n")
              manifest_file = nil
              Dir.entries(output).sort.each do |fn|
                print("  ++++++++ assets:precompile contents #{fn}\n")
                manifest_file = fn if fn =~ /^\.sprockets-manifest/
              end
              unless manifest_file.nil?
                mj = nil
                File.open(File.join(output, manifest_file)) do |f|
                  mj = JSON.parse(f.read)
                end
                print("\n++++++++++ assets:precompile contents of manifest file:\n")
                mj['files'].keys.sort.each do |fn|
                  print("  ++++++++ assets:precompile manifest #{fn} - #{mj['files'][fn]['logical_path']}\n")
                end
              end
              #++ END
            end
          end

          desc "Remove old compiled assets"
          task :clean, [:keep] => :environment do |t, args|
            with_logger do
              print("++++++++++ assets:clean will manifest.clean - #{Integer(args.keep || self.keep)}\n")
              manifest.clean(Integer(args.keep || self.keep))
            end
          end

          desc "Remove compiled assets"
          task :clobber => :environment do
            with_logger do
              print("++++++++++ assets:clobber will manifest.clobber\n")
              manifest.clobber
            end
          end
        end
      end
    end
  end
end
