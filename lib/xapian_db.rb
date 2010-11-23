require 'digest/sha1'
require 'rubygems'
require 'xapian'

module XapianDb
  
  def self.serialize_value(value)
    if value.kind_of?(Date)
      Xapian.sortable_serialise(value.to_time.to_i)
    elsif value.kind_of?(Time)
      Xapian.sortable_serialise(value.to_i)
    elsif value.kind_of?(Numeric) || value.to_s =~ /^[0-9]+$/
      Xapian.sortable_serialise(value.to_f)
    else
      value.to_s.downcase
    end
  end
end

