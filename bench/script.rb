GC.disable
require 'benchmark'

module Bench

  class Script

    def initialize
      @logger = Logger.new
    end

    def run
      @logger.puts "Benchmarking MR"
      benchmark = Benchmark.measure do
        require 'mr'
        require 'bench/setup_activerecord'
        profile_model_configuration
        profile_model_initialize
        profile_model_comparison
        profile_model_fields
        profile_model_associations
        profile_model_persistence
        profile_model_querying
        profile_read_model
        # profile_query
        # profile_paged_query
        # profile_record_factory
        # profile_model_factory
      end
      memory     = RoundedNumber.new(ProcessMemory.get)
      time_taken = RoundedNumber.new(benchmark.real)
      @logger.puts "Done #{time_taken}s #{memory}mb"
    end

    def profile_model_configuration
      @logger.puts "benchmarking MR::Model configuration"
      model_class = Class.new do
        include MR::Model
        record_class AreaRecord
      end

      profile("reading record class") do |n|
        model_class.record_class
      end
      profile("writing record class") do |n|
        model_class.record_class((n % 2 == 0) ? UserRecord : AreaRecord)
      end
    end

    def profile_model_initialize
      @logger.puts "benchmarking MR::Model initialize"
      model_class = Class.new do
        include MR::Model
        record_class AreaRecord
        field_accessor :name, :active, :description
      end
      record = AreaRecord.new

      profile("with no arguments") do |n|
        model_class.new
      end
      profile("with a record") do |n|
        model_class.new(record)
      end
      profile("with a hash of values") do |n|
        model_class.new({
          :name        => "Name #{n}",
          :active      => (n % 2 == 0),
          :description => "Description #{n}"
        })
      end
      profile("with a record and hash of values") do |n|
        model_class.new(record, {
          :name        => "Name #{n}",
          :active      => (n % 2 == 0),
          :description => "Description #{n}"
        })
      end
    end

    def profile_model_comparison
      @logger.puts "benchmarking MR::Model comparison"
      model_class = Class.new do
        include MR::Model
        record_class AreaRecord
        field_reader :id
      end
      first_model  = model_class.new.tap{ |m| m.save }
      second_model = model_class.new.tap{ |m| m.save }
      same_model   = model_class.find(second_model.id)

      profile("unequal") do |n|
        first_model == second_model
      end
      profile("equal") do |n|
        second_model == same_model
      end
    end

    def profile_model_fields
      @logger.puts "benchmarking MR::Model fields"
      model_class = Class.new{ include MR::Model }

      profile("adding readers") do |n|
        model_class.class_eval{ field_reader "reader_#{n}" }
      end
      profile("adding writers") do |n|
        model_class.class_eval{ field_writer "writer_#{n}" }
      end
      profile("adding accessors") do |n|
        model_class.class_eval{ field_accessor "accessor_#{n}" }
      end

      model_class = Class.new do
        include MR::Model
        record_class AreaRecord
        field_accessor :name, :active, :description
      end
      model = model_class.new.tap do |m|
        m.name        = 'Name'
        m.active      = true
        m.description = 'description'
      end

      profile("reading field") do |n|
        model.name
      end
      profile("writing field") do |n|
        model.name = "Name #{n}"
      end
      profile("reading many fields") do |n|
        model.fields
      end
      profile("writing many fields") do |n|
        model.fields = {
          :name        => "Name #{n}",
          :active      => (n % 2 == 0),
          :description => "Description #{n}"
        }
      end
    end

    def profile_model_associations
      @logger.puts "benchmarking MR::Model associations"
      model_class = Class.new{ include MR::Model }

      profile("adding a belongs to") do
        model_class.belongs_to :test, 'Test'
      end
      profile("adding a has many") do
        model_class.has_many :test, 'Test'
      end
      profile("adding a has one") do
        model_class.has_one :test, 'Test'
      end
      profile("adding a polymorphic belongs to") do
        model_class.polymorphic_belongs_to :test
      end

      first_area  = Area.new.tap{ |a| a.save }
      second_area = Area.new.tap{ |a| a.save }
      first_user  = User.new.tap{ |u| u.save }
      second_user = User.new.tap{ |u| u.save }
      first_user.area = first_area
      first_area.manager_user = first_user
      first_user.parent = first_area
      first_user.save
      first_area.save

      profile("reading a belongs to") do |n|
        first_user.area
      end
      profile("writing a belongs to") do |n|
        first_user.area = (n % 2 == 0) ? second_area : first_area
      end
      profile("reading a has many") do |n|
        first_area.users
      end
      profile("writing a has many") do |n|
        first_area.users = (n % 2 == 0) ? [ first_user, second_user ] : [ first_user ]
      end
      profile("reading a has one") do |n|
        first_area.manager_user
      end
      profile("writing a has one") do |n|
        first_area.manager_user = (n % 2 == 0) ? second_user : first_user
      end
      profile("reading a polymorphic belongs to") do |n|
        first_user.parent
      end
      profile("writing a polymorphic belongs to") do |n|
        first_user.parent = (n % 2 == 0) ? second_area : first_area
      end
    end

    def profile_model_persistence
      @logger.puts "benchmarking MR::Model persistence"
      model_class = Class.new do
        include MR::Model
        record_class AreaRecord
        field_accessor :name, :active, :description
      end

      profile("saving and destroying") do |n|
        model = model_class.new
        model.fields = {
          :name        => "Name #{n}",
          :active      => (n % 2 == 0),
          :description => "Description #{n}"
        }
        model.save
        model.destroy
      end

      profile("checking validations and reading errors") do
        model = model_class.new(ValidAreaRecord.new)
        model.valid?
        model.errors
      end
    end

    def profile_model_querying
      @logger.puts "benchmarking MR::Model querying"
      model_class = Class.new do
        include MR::Model
        record_class AreaRecord
        field_reader :id
      end
      first_model  = model_class.new.tap{ |m| m.save }
      second_model = model_class.new.tap{ |m| m.save }

      profile("finding one") do
        model_class.find(first_model.id)
      end
      profile("finding all") do
        model_class.all
      end
    end

    def profile_read_model
      @logger.puts "benchmarking MR::ReadModel"
      first_area  = AreaRecord.new(:name => 'Area1').tap{ |a| a.save }
      second_area = AreaRecord.new(:name => 'Area2').tap{ |a| a.save }
      first_user  = UserRecord.new(:name => 'User1').tap do |u|
        u.area = first_area
        u.save
      end
      second_user = UserRecord.new(:name => 'User2').tap do |u|
        u.area = second_area
        u.save
      end

      profile("querying records and initializing") do
        models = UserWithAreaData.all
        models.each do |m|
          m.user_name
          m.area_name
        end
      end
    end

    private

    ITERATIONS = 10000
    def profile(message, iterations = ITERATIONS, &block)
      GC.disable
      ActiveRecord::Base.transaction do
        memory = ProcessMemory.get
        benchmark = Benchmark.measure do
          [*1..iterations].each(&block)
        end
        memory_diff = RoundedNumber.new(ProcessMemory.get - memory)
        memory_diff = "+#{memory_diff}" if memory_diff.to_f > 0
        time_taken  = RoundedNumber.new(benchmark.real * 1000)
        @logger.puts "  #{message.ljust(50)} | " \
                       "#{time_taken.to_s.rjust(10)} ms | " \
                       "#{memory_diff.to_s.rjust(10)} mb"
        raise ActiveRecord::Rollback
      end
      GC.enable
      GC.start
      GC.disable
    end

  end

  class Logger
    def initialize
      @stdout = $stdout
      @file   = File.open("bench/results.txt", 'w')
    end

    def puts(message)
      @stdout.puts message
      @file.puts message
    end
  end

  module ProcessMemory
    def self.get
      (`ps -o rss= -p #{$$}`.to_i) / 1000.to_f
    end
  end

  module RoundedNumber
    ROUND_PRECISION = 2
    ROUND_MODIFIER  = 10 ** ROUND_PRECISION

    def self.new(number)
      rounded_number = (number * ROUND_MODIFIER).to_i / ROUND_MODIFIER.to_f
    end
  end

end
Bench::Script.new.run
