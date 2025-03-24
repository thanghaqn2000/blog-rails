class Api::Admin::PostsController < Api::Admin::BaseController
  def index
    posts = Post.ransack(title_cont: params[:title]).result

    render_paginated(posts, serializer: PostSerializer)
  end

  def create
    post = Post.new(post_params)

    post.image.attach(params[:image]) if params[:image].present?

    if post.save
      render json: { message: "Post created successfully" }, status: :created
    else
      render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    post.image.attach(params[:image]) if params[:image].present?

    post.update! post_params

    render json: post, serializer: PostSerializer
  end

  def show
    render json: post, serializer: PostSerializer
  end

  def destroy
    post.destroy!

    render json: { message: "Delete post ok!" }
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
