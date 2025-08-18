require "aws-sdk-s3"
require "securerandom"

class S3StorageService
  DEFAULT_TMP_PREFIX = "tmp/".freeze
  DEFAULT_UPLOADS_PREFIX = "uploads/".freeze

  def initialize(access_key_id: ENV["AWS_ACCESS_KEY_ID"], secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"], region: ENV["AWS_REGION"], bucket_name: ENV["S3_BUCKET_NAME"])
    @access_key_id = access_key_id
    @secret_access_key = secret_access_key
    @region = region
    @bucket_name = bucket_name
  end

  # Tạo presigned URL dạng PUT để client upload trực tiếp lên S3
  # Trả về hash { url:, key: }
  def generate_presigned_put_url(filename:, content_type:, expires_in: 600, tmp_prefix: DEFAULT_TMP_PREFIX)
    key = "#{tmp_prefix}#{SecureRandom.uuid}/#{filename}"
    obj = s3_resource.bucket(@bucket_name).object(key)
    url = obj.presigned_url(:put, expires_in: expires_in, content_type: content_type)
    { url: url, key: key }
  end

  # "Promote" file từ thư mục tạm (tmp/) sang thư mục chính (uploads/)
  # Trả về hash { key:, url: }
  def promote_tmp_object(tmp_key, destination_prefix: DEFAULT_UPLOADS_PREFIX)
    unless tmp_key&.start_with?(DEFAULT_TMP_PREFIX)
      return { key: tmp_key, url: public_url_for(tmp_key) }
    end

    upload_key = tmp_key.sub(/^#{Regexp.escape(DEFAULT_TMP_PREFIX)}/, destination_prefix)
    s3_client.copy_object(
      bucket: @bucket_name,
      copy_source: "#{@bucket_name}/#{tmp_key}",
      key: upload_key
    )

    { key: upload_key, url: public_url_for(upload_key) }
  end

  def delete_object(key)
    return unless key.present?

    s3_client.delete_object(bucket: @bucket_name, key: key)
  rescue Aws::S3::Errors::NoSuchKey
    Rails.logger.error("No such key: #{key}")
  end

  private

  def public_url_for(key)
    "https://#{@bucket_name}.s3.#{@region}.amazonaws.com/#{key}"
  end

  def s3_resource
    @s3_resource ||= Aws::S3::Resource.new(
      access_key_id: @access_key_id,
      secret_access_key: @secret_access_key,
      region: @region
    )
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(
      access_key_id: @access_key_id,
      secret_access_key: @secret_access_key,
      region: @region
    )
  end
end


