class Europeana::VersionsCleanupJob < ActiveJob::Base
  queue_as :default
  include PictureVersionHelper

  def perform(id)
    %w(halfx2 small smallx2 thumbnailx2 thumbnail_png facebook twitter).each do |version_key|
      signature = Alchemy::DragonflySignature.find(picture_id: id, version_key: version_key)
      version = Alchemy::PictureVersion.find_by_signature(signature.signature)
      version.delete
      true
    end
  end
end
