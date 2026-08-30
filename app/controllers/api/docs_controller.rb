class Api::DocsController < ApplicationController
  skip_before_action :require_login

  OPENAPI_PATH = Rails.root.join("doc/openapi.yaml")

  def index
    render layout: false
  end

  def openapi
    send_data OPENAPI_PATH.read, type: "application/yaml", disposition: "inline"
  end
end
