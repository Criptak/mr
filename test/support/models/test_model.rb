require 'mr'
require 'test/support/models/area'
require 'test/support/models/fake_test_record'

class TestModel
  include MR::Model

  record_class FakeTestRecord

  field_reader :id
  field_accessor :name, :active

  belongs_to :area

  attr_accessor :special

  def active
    super ? 'Yes' : 'No'
  end

  def area
    super || raise('no area')
  end

end
