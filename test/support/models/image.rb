require 'mr'
require 'mr/fake_record'
require 'test/support/models/user'

class ImageRecord < ActiveRecord::Base
  include MR::Record
  self.table_name = 'images'

  belongs_to :user, {
    :class_name  => 'UserRecord',
    :foreign_key => 'user_id'
  }

  belongs_to :benchmark_user, {
    :class_name  => 'UserRecord',
    :foreign_key => 'benchmark_user_id'
  }

end

class Image
  include MR::Model
  record_class ImageRecord

  field_reader :id, :user_id
  field_accessor :file_path, :data

  belongs_to :user

  belongs_to :benchmark_user

end

class FakeImageRecord
  include MR::FakeRecord
  model_class Image

  attribute :file_path, :string
  attribute :data,      :binary
  attribute :user_id,   :integer, :null => false

  belongs_to :user, 'FakeUserRecord'

  belongs_to :benchmark_user, 'FakeUserRecord'

end

