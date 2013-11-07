require 'mr'
require 'test/support/models/area'
require 'test/support/models/comment'
require 'test/support/models/user_record'

class User
  include MR::Model

  record_class UserRecord

  field_reader :id, :area_id, :created_at, :updated_at
  field_accessor :name, :email, :active

  belongs_to :area
  has_one    :favorite_comment
  has_many   :comments

  def self.all_of_em_query
    MR::Query.new(self, UserRecord.scoped)
  end

end
