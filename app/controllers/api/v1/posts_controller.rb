class Api::V1::PostsController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token

  def index
    blogs = Post.publish

    render json: blogs, except: %i(updated_at deleted_at)
  end

  def show
    render json: post, except: %i(updated_at deleted_at)
  end

  private

  def post
    @post ||= Post.publish.find params[:id]
  end
end
