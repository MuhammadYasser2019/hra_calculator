module Transactions
  class CountyZipFile
    include Dry::Transaction

    step :fetch
    step :validate
    step :persist

    private

    def fetch(input)
      @tenant = ::Tenants::Tenant.find(input['tenant_id'])
      @year = input['county_zip_year']
      action_dispatch = input['county_zip']['value']
      return Failure('Uploaded file is not in expected naming') unless action_dispatch.original_filename.include?("_ZipCode_")

      file = action_dispatch.tempfile.path
      if @tenant.blank?
        Failure({errors: {tenant_id: "Unable to find tenant record with id #{input[:id]}"}})
      elsif @year.blank?
        Failure({errors: {year: "Unable to year"}})
      else
        Success({county_zip_file: file})
      end
    end

    def validate(input)
      output = ::Validations::CountyZipFileContract.new.call(input)

      if output.failure?
        result = output.to_h
        result[:errors] = []
        output.errors.to_h.each_pair do |keyy, val|
          result[:errors] << "#{keyy.to_s} #{val.first}"
        end
        Failure(result)
      else
        Success(output)
      end
    end

    def persist(input)
      params = { file: input.to_h[:county_zip_file], tenant: @tenant, year: @year }
      success_result = if @tenant.has_rating_area_constraints?
                         county_zip_result = ::Operations::ImportCountyZip.new.call(params)
                         county_zip_result.success?
                       else
                         true
                       end

      if success_result
        rating_area_result = ::Operations::ImportRatingArea.new.call(params)
        if rating_area_result.failure?
          return Failure("Unable to create RatingArea")
        else
          Success("created CountyZips/RatingArea")
        end
      else
        Failure("Unable to create CountyZips")
      end
    end
  end
end