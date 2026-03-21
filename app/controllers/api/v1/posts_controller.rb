class Api::V1::PostsController < Api::V1::BaseController
  before_action :set_post, only: [:show]

  def index
    posts = post_scope.ransack(title_cont: params[:title], with_category_name: params[:category]).result
      .order(Arel.sql("date_post IS NULL"), date_post: :desc)

    render_paginated(posts, serializer: PostListSerializer)
  end

  def show
    full_content = current_user&.admin? || current_user&.vip?
    content_mode = full_content ? :full : :single_sentence
    render json: { data: PostSerializer.new(@post, { content_mode: content_mode }).as_json }
  end

  private
  def set_post
    post_id = Post.id_from_slug(params[:id])
    @post = post_scope.find_by(id: post_id) if post_id > 0

    response_api({ errors: "Post not found" }, :not_found) unless @post
  end

  def post_scope
    if current_user&.admin?
      Post.all
    else
      Post.publish
    end
  end
end
