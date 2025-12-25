module Paginatable
  extend ActiveSupport::Concern

  private

  def paginate_array(array, page:, per_page:)
    page = normalize_page(page)
    total_items = array.length
    total_pages = calculate_total_pages(total_items, per_page)
    page = [ page, total_pages ].min

    build_pagination_result(array, page, per_page, total_pages, total_items)
  end

  def normalize_page(page)
    [ page.to_i, 1 ].max
  end

  def calculate_total_pages(total_items, per_page)
    pages = (total_items.to_f / per_page).ceil
    [ pages, 1 ].max
  end

  # rubocop:disable Metrics/MethodLength
  def build_pagination_result(array, page, per_page, total_pages, total_items)
    offset = (page - 1) * per_page
    items = array[offset, per_page] || []

    {
      items: items,
      current_page: page,
      total_pages: total_pages,
      per_page: per_page,
      total_items: total_items,
      has_prev: page > 1,
      has_next: page < total_pages
    }
  end
  # rubocop:enable Metrics/MethodLength
end
