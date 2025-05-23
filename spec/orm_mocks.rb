# encoding: utf-8

# Mocks for the orm adapter tests
# @author Gernot Kogler

class PersistentObject

  @objects = []

  class << self

    attr_reader :hooks

    def reset
      @objects = []
      @hooks = {}
    end

    def count
      @objects.size
    end

    def where(conditions)
      @objects
    end

    def offset(number)
      self
    end

    def limit(number)
      self
    end

    def order(number)
      self
    end

    def each(&block)
      @objects.each{ |object| yield object }
    end
  end

  attr_accessor :id, :name, :date, :age

  def initialize(id, name, date = Date.today, age = 0)
    @id, @name, @date, @age = id, name, date, age
    @destroyed = false
  end

  def save
    self.class.where("1=1") << self
    instance_eval &self.class.hooks[:after_save] if self.class.hooks[:after_save]
  end

  def destroy
    self.class.where("1=1").delete self
    @destroyed = true
    instance_eval &self.class.hooks[:after_destroy]
  end

  def destroyed?
    @destroyed
  end

end

# Test class for indexed datamapper objects; this class mimics some behaviour
# of datamapper and has methods to test the helper methods

class DMSerial
  def name
    :id
  end
end

class DatamapperObject < PersistentObject

  class << self

    def serial
      @serial ||= DMSerial.new
      @serial
    end

    def get(id)
      @objects.detect{|o| o.id == id}
    end

    # Simulate the after method of datamapper
    def after(action, &block)
      @hooks ||= {}
      @hooks[:"after_#{action}"] = block
    end

  end

end

# Test class for indexed active_record objects; this class mimics some behaviour
# of active_record and has methods to test the helper methods
class ActiveRecordObject < PersistentObject

  def initialize(*)
    super

    previous_changes['name'] = @name
  end

  class << self
    def table_name
      self.name
    end

    def primary_key
      :id
    end

    def includes(*associations)
      self
    end

    def find(id)
      @objects.detect{|o| o.id == id}
    end

    # Simulate the after_commit method of activerecord
    #
    # Supported args: { on: [:update, :create, :destroy] }
    # - :update, :create get mapped to after_save
    # - :destroy gets mapped to after_destroy
    #
    # The mock does *not* simulate the transaction behaviour itself
    def after_commit(*args, &block)
      @hooks ||= {}
      options = args&.last&.is_a?(::Hash) ? args.pop : {}

      if options[:on]
        fire_on = Array(options[:on]) # wrap in an array, should it not already be an array
        @hooks[:after_save]    = block unless (fire_on & %i[create update]).empty?
        @hooks[:after_destroy] = block unless (fire_on & %i[destroy]).empty?
      else
        # keep with the old behaviour
        @hooks[:after_save] = block
      end
    end
  end

  def name=(new_name)
    @previous_changes['name'] = @name
    @name = new_name
  end

  def previous_changes
    @previous_changes ||= Hash.new
  end
end
