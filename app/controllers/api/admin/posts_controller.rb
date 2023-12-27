class Api::Admin::PostsController < Api::Admin::BaseController
  skip_before_action :verify_authenticity_token

  def index
    blogs = Post.all

    render json: blogs, except: %i(updated_at deleted_at)
  end

  def create
    post = Post.create! post_params

    render json: post, except: %i(created_at updated_at deleted_at)
  end

  def update
    post.update! post_params

    render json: post, except: %i(created_at updated_at deleted_at)
  end

  def show
    render json: post, except: %i(updated_at deleted_at)
  end

  def destroy
    post.destroy!

    render json: {message: "Delete post ok!"}
  end

  def categories
    render json: Post.categories
  end

  private

  def post_params
    params.required(:post).permit :title, :content, :category, :status
  end

  def post
    @post ||= Post.find params[:id]
  end
end
