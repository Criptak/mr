require 'assert'
require 'mr'

require 'test/support/setup_test_db'
require 'test/support/factory/area'
require 'test/support/factory/user'
require 'test/support/models/area'
require 'test/support/models/comment'
require 'test/support/models/user'

class WithModelTests < DbTests
  desc "MR with an ActiveRecord model"
  setup do
    @area = Factory::Area.instance_stack.tap(&:create).model
    @user = User.new(:name => "Joe Test", :area => @area)
  end
  subject{ @user }

  should "allow accessing the record's attributes" do
    assert_nothing_raised do
      subject.name   = 'Joe Test'
      subject.number = 12345
    end

    # check that the attributes were set
    record = subject.send(:record)
    assert_equal 'Joe Test', record.name
    assert_equal 12345,      record.number

    # check that we can read the attributes
    assert_equal 'Joe Test', subject.name
    assert_equal 12345,      subject.number
  end

  should "allow reading previous values for a record's attribute" do
    assert_nil subject.name_was
    subject.name = 'Test'
    assert_nil subject.name_was
    subject.save
    assert_equal 'Test', subject.name_was
    subject.name = 'New Test'
    assert_equal 'Test', subject.name_was
  end

  should "allow mass setting and reading the record's attributes" do
    assert_nothing_raised do
      subject.fields = {
        :name   => 'Joe Test',
        :number => 12345,
      }
    end

    # check that the attributes were set
    record = subject.send(:record)
    assert_equal 'Joe Test', record.name
    assert_equal 12345,      record.number

    expected = {
      'id'         => nil,
      'name'       => 'Joe Test',
      'number'     => 12345,
      'salary'     => nil,
      'started_on' => nil,
      'dob'        => nil,
      'area_id'    => @area.id,
    }
    assert_equal expected, subject.fields
  end

  should "be able to save and destroy the model" do
    assert_nothing_raised do
      subject.fields = {
        :name   => 'Joe Test',
        :number => 12345,
      }
      subject.save
    end
    assert_not subject.destroyed?
    assert UserRecord.exists?(subject.id)

    assert_nothing_raised do
      subject.destroy
    end
    assert subject.destroyed?
    assert_not UserRecord.exists?(subject.id)
  end

end

class DetectChangedFieldsTests < WithModelTests
  setup do
    @user = User.new(:area => @area)
  end

  should "detect when it's fields have changed" do
    assert subject.new?
    assert_not subject.name_changed?
    subject.name = 'Test'
    assert subject.name_changed?

    subject.save
    assert_not subject.new?
    assert_not subject.name_changed?
    subject.name = 'New Test'
    assert subject.name_changed?
  end

end

class BelongsToTests < WithModelTests
  desc "using a belongs to association"
  setup do
    @user.area = nil
    @area = Area.new(:name => 'Alpha').tap(&:save)
  end

  should "be able to read it and write to it" do
    assert_nil subject.area
    assert_nothing_raised do
      subject.area = @area
    end
    assert_equal @area,    subject.area
    assert_equal @area.id, subject.area_id
  end

end

class HasManyTests < WithModelTests
  desc "using a has many association"
  setup do
    @user.save
    @comment = Comment.new(:body => "Test", :parent => @user)
  end

  should "be able to read it" do
    @comment.save
    assert_equal [ @comment ], subject.comments
  end

end

class HasOneTests < WithModelTests
  desc "using a has one association"
  setup do
    @user.save
    @image = Image.new(:file_path => "test", :user => @user)
  end

  should "be able to read it" do
    @image.save
    assert_equal @image, subject.image
  end

end

class PolymorphicBelongsToTests < WithModelTests
  desc "using a polymorphic belongs to association"
  setup do
    @user.save
    @area = Area.new(:name => 'Alpha')
    @area.save
    @comment = Comment.new(:body => "Test")
  end
  subject{ @comment }

  should "be able to read it and write to it" do
    assert_nil subject.parent

    assert_nothing_raised do
      subject.parent = @area
    end
    assert_equal @area,        subject.parent
    assert_equal @area.id,     subject.parent_id
    assert_equal 'AreaRecord', subject.parent_type

    assert_nothing_raised do
      subject.parent = @user
    end
    assert_equal @user,        subject.parent
    assert_equal @user.id,     subject.parent_id
    assert_equal 'UserRecord', subject.parent_type
  end

end

class QueryTests < WithModelTests
  desc "using a MR::Query"
  setup do
    @users = [*(0..4)].map do |i|
      User.new(:name => "test #{i}", :area => @area).tap(&:save)
    end
    @query = MR::Query.new(User, UserRecord.scoped)
  end
  subject{ @query }

  should "fetch the results with #results" do
    assert_equal @users.map(&:name), subject.results.map(&:name)
  end

  should "count the results with #count" do
    assert_equal 5, subject.count
  end

end

class PagedQueryTests < QueryTests
  setup do
    @paged_query = @query.paged(1, 3)
  end
  subject{ @paged_query }

  should "fetch the paged results with #results" do
    assert_equal @users[0, 3], subject.results

    paged_query = @query.paged(2, 3)
    assert_equal @users[3, 2], paged_query.results
  end

  should "count the paged results with #count" do
    assert_equal 3, subject.count

    paged_query = @query.paged(2, 3)
    assert_equal 2, paged_query.count
  end

  should "count the total number of results with #total_count" do
    assert_equal 5, subject.total_count
  end

end

class FinderTests < WithModelTests
  setup do
    @users = [*1..2].map do |i|
      Factory::User.instance(:area => @area).tap(&:save)
    end
  end

  should "allow fetching a single user with find" do
    assert_equal @users.first, User.find(@users.first.id)

    assert_raises(ActiveRecord::RecordNotFound) do
      User.find(1000)
    end
  end

  should "allow fetching a all users with all" do
    assert_equal @users, User.all
  end

end

class InvalidTests < WithModelTests
  desc "when saving an invalid model"
  setup do
    @area = Area.new(ValidAreaRecord.new)
  end
  subject{ @area }

  should "raise a InvalidModel exception with the ActiveRecord error messages" do
    exception = nil
    begin
      subject.save
    rescue Exception => exception
    end

    assert_instance_of MR::Model::InvalidError, exception
    assert_equal [ "can't be blank" ], exception.errors[:name]
    assert_includes ":name can't be blank", exception.message
  end

  should "return the ActiveRecord's error messages with errors" do
    subject.valid?
    assert_equal [ "can't be blank" ], subject.errors[:name]
  end

end
