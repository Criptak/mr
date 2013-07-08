require 'active_record'
require 'mr'
require 'mr/fake_record'

class AreaRecord < ActiveRecord::Base
  include MR::Record
  self.table_name = "areas"
end

class Area
  include MR::Model

  record_class AreaRecord

  field_reader :id
  field_accessor :name

end

class CommentRecord < ActiveRecord::Base
  include MR::Record
  self.table_name = "comments"

  belongs_to :user, {
    :class_name  => 'UserRecord',
    :foreign_key => 'user_id'
  }
end

class Comment
  include MR::Model

  record_class CommentRecord

  field_reader :id, :user_id
  field_accessor :favorite, :message

  belongs_to :user, 'User'

end

class UserRecord < ActiveRecord::Base
  include MR::Record
  self.table_name = "users"

  belongs_to :area, {
    :class_name  => 'AreaRecord',
    :foreign_key => 'area_id'
  }
  has_one :favorite_comment, {
    :class_name => 'CommentRecord',
    :foreign_key => 'user_id',
    :conditions => { :favorite => true }
  }
  has_many :comments, {
    :class_name  => 'CommentRecord',
    :foreign_key => 'user_id',
    :dependent   => :destroy
  }

  validates_presence_of :name
end

class FakeUserRecord
  include MR::FakeRecord

  attribute :name,       :string
  attribute :email,      :string
  attribute :active,     :boolean
  attribute :area_id,    :integer
  attribute :created_at, :time
  attribute :updated_at, :time

  belongs_to :area,          'FakeAreaRecord'
  has_many :comments,        'FakeCommentRecord'
  has_one :favorite_comment, 'FakeCommentRecord'

end

class User
  include MR::Model

  record_class UserRecord

  field_reader :id, :area_id, :created_at, :updated_at
  field_accessor :name, :email, :active

  belongs_to :area, 'Area'
  has_one :favorite_comment, 'Comment'
  has_many :comments, 'Comment'

  def self.all_of_em_query
    MR::Query.new(self, UserRecord.scoped)
  end

end

class CustomUser
  include MR::Model

  record_class UserRecord

  field_reader :created_at

  belongs_to :area, 'Area'

  def self.custom_all_of_em_query
    scope = UserRecord.select("users.id AS user_id")
    MR::Query.new(CustomUserSelectResult, scope)
  end

  def area
    value = super
    self.area = value = Area.new if !value
    value
  end

  def created_at
    super || Time.now
  end

end

class CustomUserSelectResult
  include MR::ReadModel

  def user_id
    super.to_i
  end

end
