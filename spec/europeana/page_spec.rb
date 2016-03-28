require 'rails_helper'

module Alchemy
  describe 'Show' do
    let(:basic_exhibition_page) do
      create(:alchemy_page, :public, visible: true, name: 'Page 1', page_layout: 'exhibition_theme_page')
    end

    describe "#elements" do
      context 'page with only one element' do
        before do
          basic_exhibition_page.elements << create(:alchemy_element, name: 'text')
        end

        let(:page) { Europeana::Page.new(basic_exhibition_page)}

        it 'has set is_full_section_element to true' do
          expect(page.elements[:items].first[:is_full_section_element]).to eq(true)
        end
      end

      context 'page with two elements' do
        let(:basic_exhibition) do
          create(:alchemy_page, :public, visible: true, name: 'page with two elements', page_layout: 'exhibition_theme_page')
        end
        before do
          basic_exhibition.elements << create(:alchemy_element, create_contents_after_create: true, name: 'text')
          basic_exhibition.elements << create(:alchemy_element, name: 'quote', create_contents_after_create: true)
        end

        let(:page) { Europeana::Page.new(basic_exhibition)}

        it 'has set is_full_section_element to false' do
          expect(page.elements[:items].first[:is_full_section_element]).to eq(false)
        end
      end
    end
  end
end
