# Rejects any request carrying a NUL byte with a 400. Postgres can't store NUL, and the PG
# adapter raises ArgumentError when one is bound into a query, so these used to surface as
# 500s from search, sign-in, Rack::Attack's token lookup and more (#246).
class NullByteGuard
  NULL_BYTE = "\0"
  API_PATH = %r{\A/api/}
  # Malformed bodies/queries: let Rails respond to those itself, as it did before this guard.
  PARSE_ERRORS = [
    ActionController::BadRequest,
    ActionDispatch::Http::Parameters::ParseError,
    Rack::Utils::ParameterTypeError,
    Rack::Utils::InvalidParameterError
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    null_byte_in_request?(ActionDispatch::Request.new(env)) ? bad_request(env) : @app.call(env)
  end

  private

  # Parsing here is cached in the env, so controllers reuse it rather than parsing twice.
  # Only Clearance's cookie is checked: it's an unverified DB lookup key, while a stray NUL in
  # any other cookie (e.g. one set on a parent domain) shouldn't lock a browser out.
  def null_byte_in_request?(request)
    null_byte_in?(Rack::Utils.unescape_path(request.path_info)) ||
      null_byte_in?(request.authorization) ||
      null_byte_in?(request.cookies[Clearance.configuration.cookie_name]) ||
      null_byte_in?(request.query_parameters) ||
      null_byte_in?(request.request_parameters)
  rescue *PARSE_ERRORS
    false
  end

  # Uploaded files are skipped (they aren't Strings): binary content legitimately contains NUL.
  def null_byte_in?(value)
    case value
    when String then value.include?(NULL_BYTE)
    when Hash then value.any? { |key, item| null_byte_in?(key) || null_byte_in?(item) }
    when Array then value.any? { |item| null_byte_in?(item) }
    else false
    end
  end

  def bad_request(env)
    # Rack::TempfileReaper sits downstream and never sees this response, so close any
    # multipart upload tempfiles the parse created rather than leaving them open until GC.
    env[Rack::RACK_TEMPFILES]&.each(&:close!)
    # No controller runs, so nothing else logs the outcome. Param, cookie and header values stay out of the log.
    Rails.logger.info("NullByteGuard: 400 for #{env["REQUEST_METHOD"]} #{env["PATH_INFO"].inspect} (null byte in request)")

    if API_PATH.match?(env["PATH_INFO"])
      [400, {"content-type" => "application/json"}, [{error: "Request contains a null byte"}.to_json]]
    else
      [400, {"content-type" => "text/html; charset=utf-8"}, [Rails.public_path.join("400.html").read]]
    end
  end
end
