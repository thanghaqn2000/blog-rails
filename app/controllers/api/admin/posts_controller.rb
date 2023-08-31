class Api::Admin::PostsController < Api::Admin::BaseController
  def index
    blogs = Post.all
    render json: blogs
  end
end
