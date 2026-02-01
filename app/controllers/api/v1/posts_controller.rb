class Api::V1::PostsController < Api::V1::BaseController
  before_action :set_post, only: [:show]

  def index
    posts = post_scope.ransack(title_cont: params[:title], with_category_name: params[:category]).result

    render_paginated(posts, serializer: PostListSerializer)
  end

  def show
    render json: { data: PostSerializer.new(@post).as_json }
  end

  private
  def set_post
    @post = post_scope.find_by(id: params[:id])

    response_api({ errors: "Post not found" }, :not_found) unless @post
  end

  def post_scope
    if current_user&.admin?
      Post.all
    elsif current_user&.vip?
      Post.publish.where(sub_type: %i[normal vip])
    else
      Post.publish.normal
    end
  end
end
