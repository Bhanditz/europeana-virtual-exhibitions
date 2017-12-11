class Europeana::PictureVersionsJob < ActiveJob::Base
  queue_as :default
  include PictureVersionHelper

  def perform(id)
    picture = Alchemy::Picture.find(id)
    Europeana::Elements::Image::VERSIONS.each_pair do |version_key, settings|
      Rails.logger.info "Creating #{JSON.generate(settings)} of picture #{id}"
      next if settings[:size].nil?
      version = picture_version(picture, settings)
      # call .data on the version to ensure it is persisted
      version.data
      Alchemy::DragonflySignature.find_or_create_by(picture_id: id, version_key: version_key, signature: version.signature)
      true
    end
  end
end
