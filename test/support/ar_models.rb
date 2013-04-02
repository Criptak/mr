require 'active_record'
require 'mr'
require 'mr/fake_record'

class AreaRecord < ActiveRecord::Base
  self.table_name = "areas"
end

class Area
  include MR::Model

  record_class AreaRecord

  field_reader :id
  field_accessor :name

end

class CommentRecord < ActiveRecord::Base
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
  field_accessor :message

  # belongs_to :user, 'User'

end

class UserRecord < ActiveRecord::Base
  self.table_name = "users"

  belongs_to :area, {
    :class_name  => 'AreaRecord',
    :foreign_key => 'area_id'
  }
  has_many :comments, {
    :class_name  => 'CommentRecord',
    :foreign_key => 'user_id',
    :dependent   => :destroy
  }
end

class FakeUserRecord
  include MR::FakeRecord

  attributes :id, :name, :email, :active, :area_id, :created_at, :updated_at

  belongs_to :area
  has_many :comments

end

class User
  include MR::Model

  record_class UserRecord

  field_reader :id, :area_id, :created_at, :updated_at
  field_accessor :name, :email, :active

  # belongs_to :area, 'Area'
  # has_many :comments, 'Comment'

end
