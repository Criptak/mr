require 'mr/fake_record'
require 'test/support/models/comment'
require 'test/support/models/fake_user_record'

class FakeCommentRecord
  include MR::FakeRecord
  model_class Comment

  attribute :message,       :string
  attribute :user_id,       :integer
  attribute :favorite,      :boolean
  attribute :parent_id,     :integer
  attribute :parent_type,   :string
  attribute :created_by_id, :integer

  polymorphic_belongs_to :parent
  belongs_to :user, 'FakeUserRecord'

end
