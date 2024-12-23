class Api::Admin::PostsController < Api::Admin::BaseController
  def index
    blogs = Post.all

    render json: blogs, except: %i(updated_at deleted_at)
  end

  def create
    post = Post.new(post_params)

    if params[:image].present?
      post.image.attach(params[:image])
    end

    if post.save
      render json: { message: "Post created successfully" }, status: :created
    else
      render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if params[:image].present?
      post.image.attach(params[:image])
    end

    post.update! post_params

    render json: post, except: %i(created_at updated_at deleted_at)
  end

  def show
    render json: PostRepresenter.new(post).to_json
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
    params.required(:post).permit :title, :content, :category, :status, :image
  end

  def post
    @post ||= Post.find params[:id]
  end
end
