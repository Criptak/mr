require 'assert'
require 'mr/fake_record'
require 'ns-options/assert_macros'

module MR::FakeRecord

  class BaseTests < Assert::Context
    desc "FakeRecord"
    setup do
      @fake_record_class = Class.new do
        include MR::FakeRecord
        attribute :name,       :string
        attribute :active,     :boolean
        attribute :parent_id,  :integer
        attribute :created_at, :datetime
        attribute :updated_at, :datetime

        belongs_to :parent,   'FakeParentRecord'
        has_many   :children, 'FakeChildRecord'
        has_one    :thing,    'FakeThingRecord'
      end
      @fake_record = @fake_record_class.new
    end
    subject{ @fake_record }

    # should add accessors for all associations
    should have_accessors :parent, :children, :thing

    should have_cmeths :attribute, :attributes, :columns, :column_names
    should have_cmeths :associations, :belongs_to, :has_many, :has_one
    should have_cmeths :reflect_on_all_associations

    should have_imeths :attributes, :attributes=, :new_record?, :valid?
    should have_imeths :save!, :destroy, :transaction
    should have_imeths :saved_attributes, :destroyed?

    should "return it's attribute list with #attributes" do
      assert_instance_of Set, @fake_record_class.attributes
      @fake_record_class.attributes.each do |attribute|
        assert_instance_of MR::FakeRecord::Attribute, attribute
      end
      expected = [
        [ 'id',         :primary_key ],
        [ 'name',       :string ],
        [ 'active',     :boolean ],
        [ 'parent_id',  :integer ],
        [ 'created_at', :datetime ],
        [ 'updated_at', :datetime ]
      ].sort
      actual = @fake_record_class.attributes.map do |a|
        [ a.name.to_s, a.type ]
      end.sort
      assert_equal expected, actual
    end

    should "return it's association list with #associations" do
      assert_instance_of Set, @fake_record_class.associations
      @fake_record_class.associations.each do |association|
        assert_kind_of MR::FakeRecord::Association, association
      end
      expected = [
        [ 'parent',   :belongs_to, 'FakeParentRecord' ],
        [ 'children', :has_many,   'FakeChildRecord' ],
        [ 'thing',    :has_one,    'FakeThingRecord' ]
      ].sort
      actual = @fake_record_class.associations.map do |a|
        [ a.name.to_s, a.type, a.fake_record_class_name ]
      end.sort
      assert_equal expected, actual
    end

    should "mimic an AR record by exposing its `attributes` as `column_names`" do
      assert_not_empty @fake_record_class.attributes
      exp_col_names = @fake_record_class.attributes.map{|a| a.name.to_s }.sort
      assert_equal exp_col_names, @fake_record_class.column_names
    end

    should "allow reading and writing multiple attributes" do
      assert_nothing_raised do
        subject.attributes = {
          :name   => 'Joe Test',
          :active => true
        }
      end

      expected = {
        :id         => nil,
        :name       => 'Joe Test',
        :active     => true,
        :parent_id  => nil,
        :created_at => nil,
        :updated_at => nil
      }
      assert_equal expected, subject.attributes
    end

    should "store the attributes that were last saved and " \
           "default id, created_at and updated_at" do
      subject.attributes = {
        :name   => 'Joe Test',
        :active => true
      }
      subject.save!

      saved = subject.saved_attributes
      assert_not_nil saved[:id]
      assert_equal 'Joe Test', saved[:name]
      assert_equal true,       saved[:active]
      assert_equal nil,        saved[:area_id]
      assert_instance_of Time, saved[:created_at]
      assert_instance_of Time, saved[:updated_at]
    end

    should "set a flag when it's destroyed" do
      assert_equal false, subject.destroyed?
      subject.destroy
      assert_equal true, subject.destroyed?
    end

  end

  class ConfigTests < BaseTests
    include NsOptions::AssertMacros

    desc "fr_config"
    setup do
      @config = @fake_record_class.fr_config
    end
    subject{ @config }

    should have_option :attributes,   Set, :default => []
    should have_option :associations, Set, :default => []

  end

  class AttributeTests < BaseTests
    desc "Attribute"
    setup do
      @attribute = MR::FakeRecord::Attribute.new(:name, :string)
    end
    subject{ @attribute }

    should have_readers :name, :type

    should "know it's name, type and whether it's a primary key" do
      assert_equal 'name',  subject.name
      assert_equal :string, subject.type
      assert_equal false,   subject.primary

      attribute = MR::FakeRecord::Attribute.new(:id, :primary_key)
      assert_equal true, attribute.primary
    end

  end

end
