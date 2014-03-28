require 'mr'
require 'mr/fake_record'
require 'test/support/models/user'

class CommentRecord < ActiveRecord::Base
  include MR::Record
  self.table_name = 'comments'

  belongs_to :parent, {
    :polymorphic => true
  }
  belongs_to :created_by, {
    :class_name  => 'UserRecord',
    :foreign_key => 'created_by_id'
  }

end

class Comment
  include MR::Model
  record_class CommentRecord

  field_reader :id, :parent_id
  field_accessor :body, :parent_type, :created_at

  polymorphic_belongs_to :parent
  belongs_to :created_by

end

class FakeCommentRecord
  include MR::FakeRecord
  model_class Comment

  attribute :body,          :text
  attribute :parent_type,   :string,   :null => false
  attribute :parent_id,     :integer,  :null => false
  attribute :created_at,    :datetime
  attribute :created_by_id, :integer

  polymorphic_belongs_to :parent
  belongs_to :created_by, 'FakeUserRecord'

end

