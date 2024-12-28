class Api::V1::PostsController < Api::V1::BaseController
  def index
    posts = Post.publish

    render_paginated(posts, serializer: PostsRepresenter)
  end

  def show
    render json: post, except: %i(updated_at deleted_at)
  end

  private

  def post
    @post ||= Post.publish.find params[:id]
  end
end
