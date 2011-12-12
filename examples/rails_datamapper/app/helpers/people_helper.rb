module PeopleHelper

  def person_doc_as_string(doc)
    "#{doc.name} #{doc.first_name}, #{doc.address[:street]}, #{doc.address[:zip]} #{doc.address[:city]} (#{doc.score}%)"
  end

end
