class PostSerializer < ActiveModel::Serializer
  attributes :id, :slug, :title, :content, :created_at, :updated_at, :image_url, :category,
             :status, :sub_type, :date_post, :description, :source, :author_type, :author

  def content
    mode = instance_options[:content_mode]
    return object.content if mode == :full || mode.nil?

    truncate_to_single_sentence(object.content)
  end

  def image_url
    object.image_url
  end

  def author
    return nil unless object.user

    {
      name: object.user.name,
      avatar_url: object.user.avatar_url
    }
  end

  def author_type
    object.author_type
  end

  private

  def truncate_to_single_sentence(text)
    t = text.to_s.strip
    return "" if t.empty?

    # Lấy tới dấu câu kết thúc câu đầu tiên (. ! ?). Nếu không có dấu câu thì trả về toàn bộ.
    if (m = t.match(/(.+?[.!?])(?:\s|$)/m))
      m[1].strip
    else
      t
    end
  end
end
