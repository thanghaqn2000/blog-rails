class Api::V1::PostsController < Api::V1::BaseController
  skip_before_action :verify_authenticity_token

  def index
    posts = Post.publish

    render json: PostsRepresenter.new(posts).to_json
  end

  def show
    render json: post, except: %i(updated_at deleted_at)
  end

  private

  def post
    @post ||= Post.publish.find params[:id]
  end
end
