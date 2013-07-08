require 'mr/fake_record'

class FakeCommentRecord
  include MR::FakeRecord

  attribute :message,  :string
  attribute :user_id,  :integer
  attribute :favorite, :boolean

end
