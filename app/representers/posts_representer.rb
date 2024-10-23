class PostsRepresenter < Representable::Decorator
  include Representable::JSON::Collection

  items extend: PostRepresenter, class: Post
end
