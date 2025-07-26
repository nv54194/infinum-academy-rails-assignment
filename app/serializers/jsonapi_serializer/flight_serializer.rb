module JsonapiSerializer
  class FlightSerializer
    include JSONAPI::Serializer

    set_id :id
    attributes :name,
               :no_of_seats,
               :base_price,
               :departs_at,
               :arrives_at,
               :created_at,
               :updated_at

    belongs_to :company, serializer: JsonapiSerializer::CompanySerializer
  end
end
