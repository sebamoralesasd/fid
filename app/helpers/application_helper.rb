module ApplicationHelper
  def pagination_links(pagination, path_method)
    return "" if pagination[:total_pages] <= 1

    prev_link = build_prev_link(pagination, path_method)
    next_link = build_next_link(pagination, path_method)

    content_tag(:div, safe_join([ prev_link, " | ", next_link ]), class: "pagination")
  end

  private

  def build_prev_link(pagination, path_method)
    if pagination[:has_prev]
      prev_page = pagination[:current_page] - 1
      link_to("« Previous", send(path_method, page: prev_page))
    else
      content_tag(:span, "« Previous", class: "disabled")
    end
  end

  def build_next_link(pagination, path_method)
    if pagination[:has_next]
      next_page = pagination[:current_page] + 1
      link_to("Next »", send(path_method, page: next_page))
    else
      content_tag(:span, "Next »", class: "disabled")
    end
  end
end
