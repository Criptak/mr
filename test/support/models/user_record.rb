require 'active_record'
require 'mr'
require 'test/support/models/area_record'
require 'test/support/models/comment_record'

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
