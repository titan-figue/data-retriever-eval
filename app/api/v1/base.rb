# -*- encoding : utf-8 -*-
module DataRetriever
  module V1
    class Base < Grape::API
      mount DataRetriever::V1::AdminEndpoint
      mount DataRetriever::V1::Estimate
      mount DataRetriever::V1::ApiEndpoint
    end
  end
end
