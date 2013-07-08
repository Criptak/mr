require 'mr'
require 'test/support/models/comment_record'
require 'test/support/models/user'

class Comment
  include MR::Model

  record_class CommentRecord

  field_reader :id, :user_id
  field_accessor :favorite, :message

  belongs_to :user, 'User'

end
