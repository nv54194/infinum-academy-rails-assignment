module TestHelpers
  module JsonResponse
    def json_body
      JSON.parse(response.body)
    end

    def api_headers(serializer: nil, root: 1, token: nil)
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X_API_SERIALIZER': serializer,
        'X_API_SERIALIZER_ROOT': root.to_s,
        'Authorization': token
      }
    end
  end
end
