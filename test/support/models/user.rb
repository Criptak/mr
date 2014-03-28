require 'mr'
require 'mr/fake_record'
require 'test/support/models/area'
require 'test/support/models/comment'
require 'test/support/models/image'

class UserRecord < ActiveRecord::Base
  include MR::Record
  self.table_name = 'users'

  belongs_to :area, {
    :class_name  => 'AreaRecord',
    :foreign_key => 'area_id'
  }
  has_one :image, {
    :class_name  => 'ImageRecord',
    :foreign_key => 'user_id',
    :autosave    => false
  }
  has_many :comments, {
    :class_name  => 'CommentRecord',
    :as          => :parent
  }

end

class User
  include MR::Model
  record_class UserRecord

  field_reader :id, :area_id
  field_accessor :name, :number, :salary, :started_on, :dob

  belongs_to :area
  has_one :image
  has_many :comments

end

class FakeUserRecord
  include MR::FakeRecord
  model_class User

  attribute :name,       :string
  attribute :number,     :integer
  attribute :salary,     :float
  attribute :started_on, :date
  attribute :dob,        :timestamp
  attribute :area_id,    :integer,   :null => false

  belongs_to :area, 'FakeAreaRecord'
  has_one :image, 'FakeImageRecord'
  has_many :comments, 'FakeCommentRecord'

end

