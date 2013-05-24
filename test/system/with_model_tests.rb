require 'assert'
require 'test/support/db_schema_context'
require 'test/support/ar_models'

class WithModelTests < DBSchemaTests
  desc "MR with an ActiveRecord model"
  setup do
    @user = User.new({ :name => "Joe Test" })
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

class BelongsToTests < WithModelTests
  desc "using a belongs to association"
  setup do
    @area = Area.new({ :name => 'Alpha' })
    @area.save
  end
  teardown do
    @area.destroy
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
    @comment = Comment.new({ :message => "Test", :user => @user })
  end
  teardown do
    @comment.destroy
    @user.destroy
  end

  should "be able to read it" do
    @comment.save

    assert_equal [ @comment ], subject.comments
  end

end

class QueryTests < WithModelTests
  desc "using a MR::Query"
  setup do
    @users = [*(0..4)].map do |i|
      User.new({ :name => "test #{i}" }).tap{|u| u.save }
    end
    @query = User.all_of_em_query
  end
  teardown do
    @users.each(&:destroy)
  end
  subject{ @query }

  should "allow fetching the models with #models" do
    assert_equal @users, subject.models
  end

  should "allow counting the models with #count" do
    assert_equal 5, subject.count
  end

end

class PagedQueryTests < QueryTests
  setup do
    @paged_query = @query.paged(1, 3)
  end
  subject{ @paged_query }

  should "allow fetching the models paged with #models" do
    assert_equal @users[0, 3], subject.models

    paged_query = @query.paged(2, 3)
    assert_equal @users[3, 2], paged_query.models
  end

  should "allow fetching the models paged with #models" do
    assert_equal 3, subject.count

    paged_query = @query.paged(2, 3)
    assert_equal 2, paged_query.count
  end

  should "allow counting the total number of models with #total_count" do
    assert_equal 5, subject.total_count
  end

end

class FinderTests < WithModelTests
  setup do
    @users = [*(1..3)].map do |i|
      record = UserRecord.new({ :name => "test #{i}" }).tap do |u|
        u.id = i
        u.save!
      end
      User.new(record)
    end
  end
  teardown do
    @users.each(&:destroy)
  end

  should "allow fetching a single user with find" do
    assert_equal @users[0], User.find(1)

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
    @user = User.new
  end

  should "raise a InvalidModel exception with the ActiveRecord error messages" do
    exception = nil
    begin
      subject.save
    rescue Exception => exception
    end

    assert_instance_of MR::Model::InvalidError, exception
    assert_equal [ "can't be blank" ], exception.errors[:name]
  end

  should "return the ActiveRecord's error messages with errors" do
    subject.valid?

    assert_equal [ "can't be blank" ], subject.errors[:name]
  end

end
