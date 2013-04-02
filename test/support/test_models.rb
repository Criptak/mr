require 'mr'
require 'mr/fake_record'

class TestRecord
  include MR::Record
end

class TestFakeRecord
  include MR::FakeRecord

  attributes :id, :name, :active

end

class TestModel
  include MR::Model

  record_class TestFakeRecord

  field_reader :id
  field_accessor :name

  attr_reader :before_save_called, :after_save_called, :before_create_called,
    :after_create_called, :before_update_called, :after_update_called,
    :before_destroy_called, :after_destroy_called
  attr_accessor :special

  protected

  def before_save
    @before_save_called = true
  end

  def after_save
    @after_save_called = true
  end

  def before_create
    @before_create_called = true
  end

  def after_create
    @after_create_called = true
  end

  def before_update
    @before_update_called = true
  end

  def after_update
    @after_update_called = true
  end

  def before_destroy
    @before_destroy_called = true
  end

  def after_destroy
    @after_destroy_called = true
  end

end
