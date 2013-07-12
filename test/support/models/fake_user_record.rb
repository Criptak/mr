require 'mr/fake_record'
require 'test/support/models/fake_area_record'
require 'test/support/models/fake_comment_record'
require 'test/support/models/user'

class FakeUserRecord
  include MR::FakeRecord
  model_class User

  attribute :name,       :string
  attribute :email,      :string
  attribute :active,     :boolean
  attribute :area_id,    :integer
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  belongs_to :area,          'FakeAreaRecord'
  has_many :comments,        'FakeCommentRecord'
  has_one :favorite_comment, 'FakeCommentRecord'

end
