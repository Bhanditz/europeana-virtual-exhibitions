module Europeana
  module Mixins
    module ImageVersion
      VERSIONS = {
        original: {size: nil, format: 'jpeg', 'quality': nil },
        full: {size: '1600x1600', format: 'jpeg', 'quality': 85 },
        fullx2: {size: '3200x3200', format: 'jpeg', 'quality': 85 },
        half: {size: '800x800', format: 'jpeg', 'quality': 85 },
        halfx2: {size: '1600x1600', format: 'jpeg', 'quality': 85 },
        small: {size: '400x400', format: 'jpeg', 'quality': 85 },
        smallx2: {size: '800x800', format: 'jpeg', 'quality': 85 },
        thumbnail: {size: '400x400', format: 'jpeg', 'quality': 85 },
        thumbnailx2: {size: '800x800', format: 'jpeg', 'quality': 85 },
        thumbnail_png: {size: '400x400', format: 'png', 'quality': nil },
        facebook: {size: '1200x630', format: 'jpeg', quality: 85, crop: true, upsample: true},
        twitter: {size: '750x560', format: 'jpeg', quality: 85, crop: true, upsample: true},
      }

      def versions(name = 'image')
        image = @element.content_by_name(name)
        return false if image.nil? || image.essence.picture.nil?
        Hash[VERSIONS.map {|version,settings|
          options = { image_size: settings[:size], format: settings[:format], quality: settings[:quality] }
          if settings[:crop]
            options.merge!({crop_size: 1, crop: 1, crop_from: 1, upsample: settings[:upsample] || false})
          end
          [version,
          {
            url: image.essence.picture_url(options)
          }
        ]}]
      end
    end
  end
end
