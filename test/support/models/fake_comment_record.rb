require 'mr/fake_record'
require 'test/support/models/fake_user_record'

class FakeCommentRecord
  include MR::FakeRecord

  attribute :message,  :string
  attribute :user_id,  :integer
  attribute :favorite, :boolean

  belongs_to :user, 'FakeUserRecord'

end