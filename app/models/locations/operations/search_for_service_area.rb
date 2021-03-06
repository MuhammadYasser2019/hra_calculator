# frozen_string_literal: true

module Locations::Operations
  class SearchForServiceArea
    include Dry::Transaction::Operation

    def call(hra_object)
      county_name = hra_object.county.blank? ? "" : hra_object.county.titlecase
      zip_code = hra_object.zipcode
      year = hra_object.start_month.year
      state_abbreviation = hra_object.tenant.to_s.upcase
      tenant = Tenants::Tenant.find_by_key(hra_object.tenant)
      query_criteria = {
        :county_name => county_name,
        :state => state_abbreviation
      }
      query_criteria.merge!({:zip => zip_code}) if tenant.geographic_rating_area_model == 'zipcode'
      county_zip_ids = ::Locations::CountyZip.where(query_criteria).pluck(:id).uniq
      service_areas = ::Locations::ServiceArea.where(
        "active_year" => year,
        "$or" => [
          {"county_zip_ids" => { "$in" => county_zip_ids }},
          {"covered_states" =>  state_abbreviation}
        ]
      )

      return Success(service_areas) if service_areas.present?

      hra_object.errors += ['Could Not find Service Areas for the given data']
      Failure(hra_object)
    end
  end
end