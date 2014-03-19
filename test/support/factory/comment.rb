require 'mr/factory'
require 'test/support/models/comment'

module Factory; end
Factory::Comment = MR::Factory.new(Comment, CommentRecord) do
  default_args :parent_type => 'UserRecord'
end
Factory::FakeComment = MR::Factory.new(Comment, FakeCommentRecord) do
  default_args :parent_type => 'FakeUserRecord'
end
