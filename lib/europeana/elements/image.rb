module Europeana
  module Elements
    class Image < Europeana::Elements::Base
      include Europeana::Mixins::ImageVersion
      include Europeana::Mixins::ImageCredit

      protected
      def data
        image = @element.content_by_name('image') ? @element.content_by_name('image').essence : nil
        picture = image.present? && image.picture.present? ? image.picture : nil
        {
          image: versions,
          caption: caption,
          stripped_caption: stripped_caption,
          image_credit: image_credit
        }.merge({
          is_portrait: picture.present? ? image.image_size[:height] >= image.image_size[:width] : false,
          is_landscape: picture.present? ? image.image_size[:height] < image.image_size[:width] : false
        })
      end
    end
  end
end
