require 'active_record'
require 'mr'
require 'test/support/models/user_record'

class CommentRecord < ActiveRecord::Base
  include MR::Record
  self.table_name = "comments"

  belongs_to :parent, {
    :polymorphic => true
  }
  belongs_to :user, {
    :class_name  => 'UserRecord',
    :foreign_key => 'user_id'
  }
end
