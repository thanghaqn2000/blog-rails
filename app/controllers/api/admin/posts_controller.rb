class Api::Admin::PostsController < Api::Admin::BaseController
  before_action :set_post, only: [:show, :update, :destroy]

  def index
    posts = Post.ransack(title_cont: params[:title]).result

    render_paginated(posts, serializer: PostSerializer)
  end

  def create
    post = @current_admin.posts.build(post_params)
    post.image.attach(params[:image]) if params[:image]

    if post.save
      render json: { message: "Post created successfully" }, status: :created
    else
      render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @post.image.attach(params[:image]) if params[:image].present?
    @post.update! post_params

    render json: @post, serializer: PostSerializer
  end

  def show
    render json: @post, serializer: PostSerializer
  end

  def destroy
    @post.destroy!
    render json: { message: "Delete post ok!" }
  end

  def categories
    render json: Post.categories
  end

  private

  def post_params
    params.required(:post).permit :title, :content, :category, :status, :image
  end

  def set_post
    @post = Post.find_by(id: params[:id])
    response_api({ errors: "Post not found" }, :not_found) unless @post
  end
end
