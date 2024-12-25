module Pagination
  extend ActiveSupport::Concern

  included do

    def render_paginated(collection, serializer: nil)
      paginated = collection.page(params[:page]).per(params[:per_page] || Settings.pagination.max_per_page)
      meta = {
        current_page: paginated.current_page,
        next_page: paginated.next_page,
        previous_page: paginated.prev_page,
        total_pages: paginated.total_pages,
        total_count: paginated.total_count,
        next_page_url: paginated.next_page.present? ? url_for(page: paginated.next_page) : nil,
        previous_page_url: paginated.prev_page.present? ? url_for(page: paginated.prev_page) : nil
      }
      
      response = { data: serializer ? serializer.new(paginated) : paginated, meta: meta }
      render json: response
    end
  end
end
