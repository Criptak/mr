require 'assert'
require 'test/support/db_schema_context'
require 'test/support/ar_models'

class WithModelTests < DBSchemaTests
  desc "MR with an ActiveRecord model"
  setup do
    @user = User.new
  end
  teardown do
    @user.destroy rescue nil
  end
  subject{ @user }

  should "allow accessing the record's attributes" do
    assert_nothing_raised do
      subject.name   = 'Joe Test'
      subject.email  = 'joe.test@example.com'
      subject.active = true
    end

    # check that the attributes were set
    record = subject.send(:record)
    assert_equal 'Joe Test',             record.name
    assert_equal 'joe.test@example.com', record.email
    assert_equal true,                   record.active

    # check that we can read the attributes
    assert_equal 'Joe Test',             subject.name
    assert_equal 'joe.test@example.com', subject.email
    assert_equal true,                   subject.active
  end

  should "allow mass setting and reading the record's attributes" do
    assert_nothing_raised do
      subject.fields = {
        :name   => 'Joe Test',
        :email  => 'joe.test@example.com',
        :active => true
      }
    end

    # check that the attributes were set
    record = subject.send(:record)
    assert_equal 'Joe Test',             record.name
    assert_equal 'joe.test@example.com', record.email
    assert_equal true,                   record.active

    expected = {
      :id         => nil,
      :name       => 'Joe Test',
      :email      => 'joe.test@example.com',
      :active     => true,
      :area_id    => nil,
      :created_at => nil,
      :updated_at => nil
    }
    assert_equal expected, subject.fields
  end

  should "be able to save and destroy the model" do
    assert_nothing_raised do
      subject.save({
        :name   => 'Joe Test',
        :email  => 'joe.test@example.com',
        :active => true
      })
    end
    assert UserRecord.exists?(subject.id)

    assert_nothing_raised do
      subject.destroy
    end
    assert_not UserRecord.exists?(subject.id)
  end

end
