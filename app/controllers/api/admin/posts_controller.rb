class Api::Admin::PostsController < Api::Admin::BaseController
  before_action :set_post, only: [:show, :update, :destroy]

  def presign
    result = s3_storage_service.generate_presigned_put_url(
      filename: params[:filename],
      content_type: params[:content_type]
    )
    render json: result
  end

  def index
    posts = Post.ransack(title_cont: params[:title]).result
    .order(created_at: :desc)
    render_paginated(posts, serializer: PostSerializer)
  end

  def create
    attrs = post_params.to_h
    if (tmp_key = attrs[:image_key]).present?
      promoted = s3_storage_service.promote_tmp_object(tmp_key)
      attrs[:image_key] = promoted[:key]
      attrs[:image_url] = promoted[:url]
    end
    post = @current_admin.posts.build(attrs)

    if post.save
      render json: { message: "Post created successfully" }, status: :created
    else
      render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    attrs = post_params.to_h
    if (tmp_key = attrs.delete(:image_key)).present?
      old_key = @post.image_key
      if old_key.present? && old_key != tmp_key
        s3_storage_service.delete_object(old_key)
      end

      promoted = s3_storage_service.promote_tmp_object(tmp_key)
      attrs[:image_key] = promoted[:key]
      attrs[:image_url] = promoted[:url]
    end

    @post.update!(attrs)

    render json: @post, serializer: PostSerializer
  end

  def show
    render json: @post, serializer: PostSerializer
  end

  def destroy
    if @post.image_key.present?
      s3_storage_service.delete_object(@post.image_key)
    end
    @post.destroy!

    render json: { message: "Delete post ok!" }
  end

  def categories
    render json: Post.categories
  end

  private

  def s3_storage_service
    @s3_storage_service ||= S3StorageService.new
  end

  def post_params
    params.required(:post).permit :title, :content, :category, :status, :sub_type, :date_post, :description, :image_key
  end

  def set_post
    @post = Post.find_by(id: params[:id])

    return response_api({ errors: "Post not found" }, :not_found) unless @post
  end
end
