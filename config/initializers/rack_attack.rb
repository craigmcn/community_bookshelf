class Rack::Attack
  throttle("api/token", limit: 120, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      req.get_header("HTTP_AUTHORIZATION")&.split(" ")&.last
    end
  end

  throttle("api/ip-unauthenticated", limit: 30, period: 1.minute) do |req|
    if req.path.start_with?("/api/") && req.get_header("HTTP_AUTHORIZATION").blank?
      req.ip
    end
  end

  self.throttled_responder = lambda do |_request|
    [429, {"Content-Type" => "application/json"}, [{error: "Rate limit exceeded"}.to_json]]
  end
end
