require 'mr/factory'
require 'test/support/models/comment'

module Factory; end
Factory::Comment = MR::Factory.new(Comment, FakeCommentRecord) do
  default_fake_args     :parent_type => 'FakeUserRecord'
  default_instance_args :parent_type => 'UserRecord'
end
