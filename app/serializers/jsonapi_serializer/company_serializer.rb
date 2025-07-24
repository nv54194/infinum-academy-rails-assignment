module JsonapiSerializer
  class CompanySerializer
    include JSONAPI::Serializer

    set_id :id
    attributes :name,
               :created_at,
               :updated_at
  end
end
