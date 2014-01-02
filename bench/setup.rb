$LOAD_PATH.push File.expand_path('../..', __FILE__)
require 'test/support/setup_test_db'
require 'mr'
require 'mr/fake_record/attributes'
require 'whysoslow'

require 'test/support/models/area'
require 'test/support/models/comment'
require 'test/support/models/image'
require 'test/support/models/user'
require 'test/support/read_models/user_with_area_data'

module Bench

  class Profiler

    def initialize(file_path)
      @logger = Logger.new(file_path)
    end

    def run(title, &block)
      printer = Printer.new(@logger, title)
      Whysoslow::Runner.new(printer, :time_unit => 's').run do
        self.instance_eval(&block)
      end
    end

    def section(title, &block)
      @logger.puts(title)
      ActiveRecord::Base.transaction do
        yield
        raise ActiveRecord::Rollback
      end
    end

    def benchmark(message, times = 10000, options = nil, &block)
      GC.disable
      iterations = [*0..(times - 1)]
      printer = BenchmarkPrinter.new(@logger, message)
      Whysoslow::Runner.new(printer, options || {}).run{ iterations.each(&block) }
      GC.enable
      GC.start
    end

  end

  class BasePrinter

    def initialize(logger, title)
      @logger = logger
      @title  = title
      @logger.sync = true
    end

    private

    def output_columns(*columns)
      @logger.puts "#{columns.join(" | ")} |"
    end

    def message(string)
      string.ljust(40)
    end

    def time_taken(results)
      measurement = results.measurements.find{ |(type, time)| type == :real }
      time_taken = RoundedNumber.new(measurement.last).to_s.rjust(10)
      unit = results.measurement_units.to_s.ljust(2)
      "#{time_taken} #{unit}"
    end

    def memory_diff(results)
      memory = results.snapshots.map(&:memory)
      memory_diff = RoundedNumber.new(memory.last - memory.first).to_s.rjust(10)
      unit = results.snapshot_units.to_s.ljust(2)
      "#{memory_diff} #{unit}"
    end

  end

  class Printer < BasePrinter

    def print(thing)
      case thing
      when :title
        @logger.puts(@title)
        @logger.puts('-' * @title.size)
      when Whysoslow::Results
        output_columns message("Total"),
                       time_taken(thing),
                       memory_diff(thing)
      end
    end

  end

  class BenchmarkPrinter < BasePrinter

    def print(thing)
      case thing
      when Whysoslow::Results
        output_columns message("  #{@title}"),
                       time_taken(thing),
                       memory_diff(thing)
      end
    end

  end

  class Logger

    def initialize(file_path)
      @file = File.open(file_path, 'w')
      @ios  = [ @file, $stdout ]
    end

    def method_missing(method, *args, &block)
      @ios.each{ |io| io.send(method, *args, &block) }
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
