class Api::V1::PostsController < Api::V1::BaseController
  def index
    posts = Post.publish.ransack(title_cont: params[:title]).result

    render_paginated(posts, serializer: PostSerializer)
  end

  def show
    render json: post, serializer: PostSerializer
  end

  private

  def post
    @post ||= Post.publish.find params[:id]
  end
end
