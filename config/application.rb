require File.expand_path('../boot', __FILE__)

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
require 'europeana/feedback_button'
require 'europeana/feeds'

module Exhibitions
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    config.action_controller.default_url_options = Rails.application.routes.default_url_options

    # Read relative URL root from env
    config.relative_url_root = ENV['RAILS_RELATIVE_URL_ROOT'] || ''

    config.assets.prefix = '/exhibitions/assets'
    config.active_job.queue_adapter = :delayed_job
    #config.assets.initialize_on_precompile = false

    config.i18n.enforce_available_locales = false

    # Load Redis config from config/redis.yml, if it exists
    config.cache_store = begin
      redis_config = Rails.application.config_for(:redis).symbolize_keys
      fail RuntimeError unless redis_config.present?
      [:redis_store, redis_config[:url]]
    rescue RuntimeError => e
      :null_store
    end

    # Load Action Mailer SMTP config from config/smtp.yml, if it exists
    config.action_mailer.smtp_settings = begin
      Rails.application.config_for(:smtp).symbolize_keys
    rescue RuntimeError
      {}
    end

    config.to_prepare do
      Dir.glob(File.join(File.dirname(__FILE__), '../app/**/*_extension.rb')) do |e|
        Rails.env.production? ? require(e) : load(e)
      end
    end
  end
end
