# This file is used by Rack-based servers to start the application.

require 'rack/rewrite'

require ::File.expand_path('../config/environment', __FILE__)

relative_url_root = Rails.application.config.relative_url_root

if relative_url_root.present?
  use Rack::Rewrite do
    r301 '/', relative_url_root
  end

  map relative_url_root do
    run Rails.application
  end
else
  run Rails.application
end
