# frozen_string_literal: true
RSpec.describe 'alchemy/pages/show.html.mustache' do
  context 'when page has multiple languages' do
    let(:sample_pages) do
      {}.tap do |hash|
        %w(de en fr).each do |lang_code|
          hash[lang_code] = alchemy_pages("sample_page_#{lang_code}".to_sym)
        end
      end
    end

    it 'should have language switching links' do
      assign(:page, sample_pages['en'])
      render
      (sample_pages.keys - ['en']).each do |locale|
        expect(rendered).to have_selector(%(ul#settings-menu li a[href$="/#{locale}/exhibitions/sample"]))
      end
    end

    it 'should have default language meta link' do
      assign(:page, sample_pages['en'])
      render
      expect(rendered).to have_selector(
        'link[hreflang="x-default"][rel="alternate"][href="http://test.host/exhibitions/sample"]',
        visible: false
      )
    end

    it 'should have alternate language meta links' do
      assign(:page, sample_pages['en'])
      render
      sample_pages.keys.each do |locale|
        expect(rendered).to have_selector(
          %(link[hreflang="#{locale}"][rel="alternate"][href="http://test.host/#{locale}/exhibitions/sample"]),
          visible: false
        )
      end
    end
  end
end
