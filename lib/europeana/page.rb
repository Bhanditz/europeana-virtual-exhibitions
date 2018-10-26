# frozen_string_literal: true

module Europeana
  class Page
    include ActionView::Helpers::TagHelper
    include Rails.application.routes.url_helpers
    include FeedHelper
    include LanguageHelper

    delegate :t, to: ::I18n
    delegate :exhibition, to: :page
    delegate :exhibition?, to: :page
    alias_method :is_exhibition, :exhibition?

    attr_reader :page

    def initialize(page)
      @page = page
    end

    def elements
      {
        present: non_chapter_elements.count >= 1,
        items: non_chapter_elements.map.with_index do |element, index|
          {
            is_last: index == (page_elements.count - 1),
            is_first: index.zero?,
            is_full_section_element: section_element_count[element.id] == 1
          }.merge(Europeana::Elements::Base.build(element).to_hash)
        end
      }
    end

    def page_elements
      @page_elements ||= @page.elements.published
    end

    def non_chapter_elements
      page_elements.reject { |element| element.name == 'chapter' }
    end

    def chapter_elements
      return { present: false } if is_foyer
      {
        present: true,
        items: chapters.map do |page|
          Europeana::Page.new(page).as_chapter
        end
      }
    end

    def credit_elements
      if !is_credit
        return { present: false, items: [] }
      end
      {
        present: true,
        items: exhibition.self_and_descendants.map do |page|
          Europeana::Page.new(page).media
        end.flatten.compact
      }
    end

    ##
    # For an exhibition foyer page, looks for a credits child page and returns a hash
    # of info about the image attached to the credit image of said page.
    # For an exhibition child page it will return the same image data by first identifying
    # the exhibition foyer page which the child page belongs to, then using the same logic as above.
    # For a language root page no credits image info is returned since many exhibitions are featured
    # and it would be ambiguous as to which one contains the desired credits.
    # @return Hash
    def credit_image
      return @credit_image if instance_variable_defined?(:@credit_image)
      return @credit_image = nil if is_foyer
      credits_page = exhibition.self_and_descendants.where(page_layout: 'exhibition_credit_page').first
      credit_image_element = credits_page&.elements&.where(name: 'credit_intro')&.first
      return @credit_image = nil unless credit_image_element
      element = Europeana::Elements::Base.build(credit_image_element)
      @credit_image = element&.to_hash&.dig(:image, :thumbnail, :url)
    end

    def media_elements
      @media_elements ||= page_elements.select { |element| %w(image rich_image intro image_compare).include?(element.name) }
    end

    def media
      media_elements.map do |element|
        element = Europeana::Elements::Base.build(element)
        next if element.hide_in_credits
        element.to_hash(include_url: url)
      end
    end

    def as_chapter
      @as_chapter ||= {
        is_chapter_nav: true,
        title: @page.title,
        url: show_page_url(@page.language_code, @page.urlname),
        label: chapter_thumbnail[:label] || false,
        image: chapter_thumbnail[:image] || false
      }
    end

    ##
    # Looks for a chapter thumbnail element and if that is present, splits
    # the labels on the pipe symbol in order to return an array of 'labels'.
    # @return Array<String>
    def chapter_labels
      return [] unless chapter_thumbnail[:label]
      chapter_thumbnail[:label].split('|').map(&:strip)
    end

    def is_chapter
      @page.depth >= 3
    end

    def is_exhibition
      @page.depth == 2
    end

    def is_foyer
      @page.depth == 1
    end

    def is_credit
      @page.page_layout == 'exhibition_credit_page'
    end

    def meta_tags
      robots_tag
    end

    def link_tags
      language_alternatives_tags
    end

    def chapters
      @chapters ||= exhibition.descendants
    end

    def all_pages
      if exhibition
        return exhibition.self_and_descendants
      end
      [@page]
    end

    def title
      @page.title
    end

    def url
      @url ||= show_page_url(locale: @page.language_code, urlname: @page.urlname)
    end

    def breadcrumbs
      crumbs = page_and_ancestors.select { |page| page.depth >= 1 }.map do |ancestor|
        {
          url: show_page_url(@page.language_code, ancestor.urlname),
          title: ancestor.title
        }
      end
      # Set the index page's breadcrumb title to locale specific string.
      crumbs[0][:title] = t('site.navigation.breadcrumb.exhibitions.return_home')
      crumbs = prepend_portal_breadcrumb crumbs
      crumbs.last[:is_last] = true
      crumbs
    end

    def page_and_ancestors
      @page_and_ancestors ||= @page.self_and_ancestors
    end

    ##
    # All this logic except for the exhibition related
    # elements come from the europeana collection portal.
    # TODO: This should be refactored to reuse rather than duplicate the portal code.
    #
    def menu_data
      [
        {
          text: t('global.navigation.collections'),
          is_current: false,
          submenu: {
            items: navigation_global_primary_nav_collections_submenu_items
          }
        },
        {
          text: t('global.navigation.browse'),
          is_current: false,
          submenu: {
            items: navigation_global_primary_nav_browse_submenu_items
          }
        },
        {
          text: is_foyer ? page.title : exhibition.title,
          url: '#',
          is_current: true,
          submenu: {
            items: menu_items.map do |chapter|
              {
                text: chapter.title,
                url: show_page_url(urlname: chapter.urlname, locale: chapter.language_code),
                is_current: chapter == @page,
                submenu: false
              }
            end
          }
        },
        {
          url: cached_feed(Feed.top_nav_feeds('en')[:blog])&.url,
          text: t('global.navigation.blog'),
          submenu: {
            items: navigation_global_primary_nav_blog_submenu_items
          }
        }
      ]
    end

    ##
    # Support method for menu_data, remove upon refactor.
    #
    def navigation_global_primary_nav_collections_submenu_items
      feed_entry_nav_items(Feed.top_nav_feeds('en')[:collections], 0)
    end

    ##
    # Support method for menu_data, remove upon refactor.
    #
    def navigation_global_primary_nav_browse_submenu_items
      [
        link_item(t('global.navigation.browse_newcontent'), URI.join(europeana_collections_url, 'explore/newcontent'),
                  is_current: false),
        link_item(t('global.navigation.browse_colours'), URI.join(europeana_collections_url, 'explore/colours'),
                  is_current: false),
        link_item(t('global.navigation.browse_sources'), URI.join(europeana_collections_url, 'explore/sources'),
                  is_current: false),
        link_item(t('global.navigation.concepts'), URI.join(europeana_collections_url, 'explore/topics'),
                  is_current: false),
        link_item(t('global.navigation.agents'), URI.join(europeana_collections_url, 'explore/people'),
                  is_current: false),
        navigation_global_primary_nav_galleries
      ]
    end

    ##
    # Support method for menu_data, remove upon refactor.
    #
    def navigation_global_primary_nav_blog_submenu_items
      blog_feed_url = Feed.top_nav_feeds('en')[:blog]
      items = feed_entry_nav_items(blog_feed_url, 6)
      items << link_item(t('global.navigation.all_blog_posts'), cached_feed(blog_feed_url)&.url, is_morelink: true)
    end

    ##
    # Support method for menu_data, remove upon refactor.
    #
    def navigation_global_primary_nav_galleries
      {
        text: t('global.navigation.galleries'),
        is_current: false,
        url: collections_galleries_path,
        submenu:  {
          items: navigation_global_primary_nav_galleries_submenu_items
        }
      }
    end

    ##
    # Support method for menu_data, remove upon refactor.
    #
    def navigation_global_primary_nav_galleries_submenu_items
      galleries_feed_url = Feed.top_nav_feeds('en')[:galleries]
      items = feed_entry_nav_items(galleries_feed_url, 6)
      items << link_item(t('global.navigation.all_galleries'), cached_feed(galleries_feed_url)&.url, is_morelink: true)
    end

    ##
    # Support method for menu_data, remove upon refactor.
    #
    def link_item(text, url, options = {})
      { text: text, url: url, submenu: false }.merge(options)
    end

    ##
    # Support method for menu_date, remove upon refactor.
    #
    def feed_entry_nav_items(url, max)
      feed_entries(url)[0..(max - 1)].map do |item|
        link_item(CGI.unescapeHTML(item.title || ''), CGI.unescapeHTML(item.url || ''))
      end
    end

    ##
    # Support method for menu_data, remove upon refactor.
    #
    def europeana_collections_url
      ENV['EUROPEANA_COLLECTIONS_URL'] || 'http://www.europeana.eu/portal/'
    end

    ##
    # Support method for menu_data, remove upon refactor.
    #
    def collections_galleries_path
      europeana_collections_url + 'explore/galleries'
    end

    def menu_items
      return exhibitions.limit(6) if is_foyer
      chapters
    end

    def exhibitions
      @exhibitions ||= Alchemy::Page.published.visible.where(depth: 2, language_code: @page.language_code).order('lft ASC').all
    end

    def chapter_thumbnail
      @chapter_thumbnail ||= begin
        if intro_element = page_elements.detect { |element| element.name == 'intro' }
          Europeana::Elements::ChapterThumbnail.new(intro_element).to_hash
        elsif img_element = page_elements.detect { |element| %w(image rich_image credit_intro).include?(element.name) }
          Europeana::Elements::ChapterThumbnail.new(img_element).to_hash
        else
          {}
        end
      end
    end

    def alternatives
      @alternatives ||= begin
        Alchemy::Page.published.where.not(language_code: @page.language_code).where(urlname: @page.urlname).all
      end
    end

    def section_element_count
      if @elements_sections.nil?
        @sections = []
        current_index = 0
        @sections[current_index] = []
        page_elements.each do |element|
          if element.name != 'section'
            @sections[current_index] << element.id
          else
            current_index = current_index.next
            @sections[current_index] = []
          end
        end
        @elements_sections = {}
        @sections.each do |section|
          count = section.length
          section.each do |element|
            @elements_sections[element] = count
          end
        end
      end
      @elements_sections
    end

    def robots_tag
      content = []
      content << (@page.robot_index? ? 'index' : 'noindex')
      content << (@page.robot_follow? ? 'follow' : 'nofollow')

      { meta_name: 'robots', content: content.join(',') }
    end

    def language_alternatives_tags
      ([@page] + alternatives).map do |page|
        { rel: 'alternate', hreflang: page.language_code, href: show_page_url(page.language_code, page.urlname), title: nil }
      end
    end

    def language_default_link
      [{ rel: 'alternate', hreflang: 'x-default', href: url_without_locale(url, locale: @page.language_code), title: nil }]
    end

    # meta information
    def description
      element = @page.find_elements(only: %w(intro text rich_image)).first
      if element
        element = Europeana::Elements::Base.build(element).get(:body, :stripped_body)
      end
      return element if element
      @page.title
    end

    def thumbnail(version = :full)
      if chapter_thumbnail&.key?(:image) && chapter_thumbnail[:image].present?
        return chapter_thumbnail[:image][version][:url]
      end
      false
    end

    private

    def prepend_portal_breadcrumb(crumbs)
      # Prepend the link to the portal.
      crumbs.unshift(
        url: europeana_collections_url,
        title: t('site.navigation.breadcrumb.return_home'),
        is_first: true
      )
      crumbs
    end
  end
end
