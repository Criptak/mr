require 'mr'
require 'test/support/models/comment_record'
require 'test/support/models/user'

class Comment
  include MR::Model

  record_class CommentRecord

  field_reader :id, :user_id, :parent_id
  field_accessor :favorite, :message, :parent_type

  polymorphic_belongs_to :parent
  belongs_to :user

end
