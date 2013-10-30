require 'active_record'

ActiveRecord::Base.establish_connection({
  :adapter   => 'sqlite3',
  :database  => ':memory:',
  :verbosity => 'quiet'
})

# silence STDOUT
current_stdout = $stdout.dup
$stdout = File.new('/dev/null', 'w')
ActiveRecord::Schema.define(:version => 1) do

  create_table "areas" do |t|
    t.string  "name"
    t.boolean "active"
    t.text    "description"
  end

  create_table "users" do |t|
    t.string  "parent_type"
    t.integer "parent_id"
    t.string  "name"
    t.integer "area_id"
    t.integer "managed_area_id"
  end

end
$stdout = current_stdout

class AreaRecord < ActiveRecord::Base
  include MR::Record
  self.table_name = 'areas'

  has_one :manager_user, :class_name => 'UserRecord', :foreign_key => 'managed_area_id'
  has_many :users, :class_name => 'UserRecord', :foreign_key => 'area_id'
end

class ValidAreaRecord < ActiveRecord::Base
  include MR::Record
  self.table_name = 'areas'
  validates_presence_of :name
end

class UserRecord < ActiveRecord::Base
  include MR::Record
  self.table_name = 'users'

  belongs_to :parent, :polymorphic => true
  belongs_to :area, :class_name => 'AreaRecord', :foreign_key => 'area_id'
end

class Area
  include MR::Model
  record_class AreaRecord
  has_one :manager_user, 'User'
  has_many :users, 'User'
end

class User
  include MR::Model
  record_class UserRecord
  polymorphic_belongs_to :parent
  belongs_to :area, 'Area'
end

class UserWithAreaData
  include MR::ReadModel

  field :user_name, :string, 'users.name'
  field :area_name, :string, 'areas.name'
  from UserRecord
  joins :area

  def self.all
    self.query.results
  end

end
