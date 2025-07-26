module JsonapiSerializer
  class UserSerializer
    include JSONAPI::Serializer

    set_id :id
    attributes :first_name,
               :last_name,
               :email,
               :created_at,
               :updated_at
  end
end
