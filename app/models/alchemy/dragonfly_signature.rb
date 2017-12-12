# frozen_string_literal: true

module Alchemy
  class DragonflySignature < ActiveRecord::Base
    belongs_to :alchemy_picture_version, class_name: 'Alchemy::PictureVersion', foreign_key: :signature,
                                         primary_key: :signature
    validates_presence_of :picture_id, :version_key, :signature
  end
end
