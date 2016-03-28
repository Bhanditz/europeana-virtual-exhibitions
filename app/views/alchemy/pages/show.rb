module Alchemy::Pages
  class Show < Alchemy::Base
    include MustacheHelper

    def elements
      page_object.elements
    end


    def page_data
      {
        elements: elements,
        title: @page.title,
        url: show_page_url(locale, @page.urlname),
        next_page: next_page,
        previous_page: previous_page
      }
    end

    def json
      JSON.pretty_generate({
        js_files: js_files,
        head_links: head_links,
        breakpoint_pixels: breakpoint_pixels,
        css_files: nil,
        page_data: page_data,
        breadcrumbs: breadcrumbs,
        elements: elements,
        title: title,
        url: url,
        share_links: share_links,
        next_page: next_page,
        previous_page: previous_page
      })
    end

    def title
      @page.title
    end

    def share_links
      [:facebook, :twitter, :pinterest, :instagram].each.collect do |network|
        [network, show_page_url(locale, @page.urlname, {utm_source: network, utm_medium: :social, utm_campaign: exhibition.slug })]
      end.to_h
    end

    def editor_attribute(attribute)
      " contenteditable='true' data-content-id=1 data-content-type='text' "
    end

    def next_page
      format_page(@page.right_sibling)
    end

    def previous_page
      format_page(@page.left_sibling)
    end

    def format_page(page)
      return false if !page.present?
      {
        title: page.title,
        url: show_page_url(page.language.language_code, page.urlname)
      }
    end


    def url
      show_page_url(locale, @page.urlname)
    end


    def breadcrumbs
      crumbs = base_crumbs + @page.self_and_ancestors.where('depth >= 2').map do | ancestor |
        {
          url: show_page_url(locale, ancestor.urlname),
          title: ancestor.title
        }
      end

      crumbs.last[:is_last] = true
      crumbs
    end

    def exhibition
      @exhibition ||= @page.self_and_ancestors.where(depth: 2).first
    end

    def debug_mode
      params.include?(:debug)
    end


    private
    def locale
      @locale ||= @page.language.language_code
    end
    def base_crumbs
      [
        {
          url: show_page_url(locale, 'start'),
          title: 'Home',
          is_first: true
        }
      ]
    end

    def body_cache_key
      @page.cache_key
    end
  end
end
