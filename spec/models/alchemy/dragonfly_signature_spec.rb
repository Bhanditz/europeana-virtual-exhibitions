# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Alchemy::DragonflySignature do
  it { should belong_to(:alchemy_picture_version) }
  it { is_expected.to validate_presence_of(:picture_id) }
  it { is_expected.to validate_presence_of(:version_key) }
  it { is_expected.to validate_presence_of(:signature) }
end