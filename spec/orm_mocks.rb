# encoding: utf-8

# Mocks for the orm adapter tests
# @author Gernot Kogler

class PersistentObject

  @objects = []

  class << self

    attr_reader :hooks

    def reset
      @objects = []
      @hooks = {
        after_save: [],
        after_destroy: [],
      }
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
    self.class.hooks[:after_save].each do |hook|
      instance_eval &hook
    end
  end

  def destroy
    self.class.where("1=1").delete self
    @destroyed = true
    self.class.hooks[:after_destroy].each do |hook|
      instance_eval &hook
    end
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
      @hooks["after_#{action}".to_sym] << block
    end

  end

end

# Test class for indexed active_record objects; this class mimics some behaviour
# of active_record and has methods to test the helper methods
class ActiveRecordObject < PersistentObject

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
    def after_commit(&block)
      @hooks[:after_save] << block
      @hooks[:after_destroy] << block
    end

    # Simulate the after_destroy method of activerecord
    def after_destroy(&block)
      @hooks ||= {}
      @hooks[:after_destroy] << block
    end
  end

  def previous_changes
    Hash.new
  end
end
