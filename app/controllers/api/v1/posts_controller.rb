class Api::V1::PostsController < Api::V1::BaseController
  def index
    posts = if current_user && current_user.admin?
      Post
    else
      Post.publish
    end.ransack(title_cont: params[:title], with_category_name: params[:category]).result

    render_paginated(posts, serializer: PostSerializer)
  end

  def show
    render json: { data: PostSerializer.new(post).as_json }
  end

  private

  def post
    @post ||= Post.find params[:id]
  end
end
