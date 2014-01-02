require 'assert'
require 'mr/fake_record'

module MR::FakeRecord

  class UnitTests < Assert::Context
    desc "MR::FakeRecord"
    setup do
      @fake_record_class = Class.new do
        include MR::FakeRecord
        attribute :name,   :string
        attribute :active, :boolean
      end
    end
    subject{ @fake_record_class }

    should have_imeths :model_class

    should "be an MR record" do
      assert_includes MR::Record, subject
    end

    should "include the associations, attributes and persistence mixins" do
      assert_includes MR::FakeRecord::Associations, subject
      assert_includes MR::FakeRecord::Attributes, subject
      assert_includes MR::FakeRecord::Persistence, subject
    end

    should "allow reading and writing it's model class using `model_class`" do
      assert_nil subject.model_class
      model_class = Class.new
      subject.model_class(model_class)
      assert_equal model_class, subject.model_class
    end

    should "allow passing attributes to it's initialize" do
      fake_record = subject.new(:name => 'test')
      assert_equal 'test', fake_record.name
    end

  end

  class InstanceTests < UnitTests
    desc "for a fake record instance"
    setup do
      @fake_record = @fake_record_class.new(:name => 'test', :active => true)
      @fake_record.save!
    end
    subject{ @fake_record }

    should have_imeths :inspect

    should "return a readable inspect" do
      object_hex = (subject.object_id << 1).to_s(16)
      expected = "#<#{subject.class}:0x#{object_hex} @active=true " \
                 "@id=#{subject.id} @name=\"test\">"
      assert_equal expected, subject.inspect
    end

    should "be comparable" do
      same_fake_record  = @fake_record_class.new(:id => @fake_record.id)
      assert_equal same_fake_record, subject
      other_fake_record = @fake_record_class.new.tap(&:save!)
      assert_not_equal other_fake_record, subject
    end

  end

end
