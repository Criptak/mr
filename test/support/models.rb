require 'active_record'
require 'mr'
require 'mr/fake_record'

class UserRecord < ActiveRecord::Base
  self.table_name = "users"
end

class FakeUserRecord
  include MR::FakeRecord

  attributes :id, :name, :email, :active, :area_id, :created_at, :updated_at

  belongs_to :area
  has_many :comments

end

class User
  # include MR::Model

  # record_class UserRecord

  # field_reader :id, :area_id, :created_at, :updated_at
  # field_accessor :name, :email, :active

  # belongs_to :area, 'Area'
  # has_many :comments, 'Comment'

end
