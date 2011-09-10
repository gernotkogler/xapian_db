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

    def all(options={})
      @objects
    end

  end

  attr_accessor :id, :name, :date, :age

  def initialize(id, name, date = Date.today, age = 0)
    @id, @name, @date, @age = id, name, date, age
  end

  def save
    self.class.all << self
    instance_eval &self.class.hooks[:after_save] if self.class.hooks[:after_save]
  end

  def destroy
    self.class.all.delete self
    instance_eval &self.class.hooks[:after_destroy]
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
      @hooks["after_#{action}".to_sym] = block
    end

  end

end

# Test class for indexed active_record objects; this class mimics some behaviour
# of active_record and has methods to test the helper methods
class ActiveRecordObject < PersistentObject

  class << self

    def primary_key
      :id
    end

    def after_commit
    end

    def includes(*associations)
    end

    def find(id)
      @objects.detect{|o| o.id == id}
    end

    # Simulate the after_commit method of activerecord
    def after_commit(&block)
      @hooks ||= {}
      @hooks["after_save".to_sym] = block
    end

    # Simulate the after_destroy method of activerecord
    def after_destroy(&block)
      @hooks ||= {}
      @hooks["after_destroy".to_sym] = block
    end

  end

end
