require 'mr'
require 'mr/fake_record'
require 'test/support/models/user'

class AreaRecord < ActiveRecord::Base
  include MR::Record
  self.table_name = 'areas'

  has_many :users, {
    :class_name  => 'UserRecord',
    :foreign_key => 'area_id'
  }

  has_many :benchmark_users, {
    :class_name  => 'UserRecord',
    :foreign_key => 'benchmark_area_id'
  }

end

class ValidAreaRecord < AreaRecord
  validates_presence_of :name
end

class Area
  include MR::Model
  record_class AreaRecord

  field_reader :id
  field_accessor :name, :active, :description, :percentage, :meeting_time

  has_many :users

  has_many :benchmark_users

end

class FakeAreaRecord
  include MR::FakeRecord
  model_class Area

  attribute :name,         :string
  attribute :active,       :boolean
  attribute :description,  :text
  attribute :percentage,   :float
  attribute :meeting_time, :time

  has_many :users, 'FakeUserRecord'

  has_many :benchmark_users, 'FakeUserRecord'

end
