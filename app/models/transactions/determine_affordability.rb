module Transactions
  class DetermineAffordability
    include Dry::Transaction

    step :validate
    step :init_hra_object
    step :find_member_premium
    step :calculate_hra_cost
    step :determine_affordability
    step :store_hra_object
    step :load_results_defaulter

    def validate(params)
      output = ::Validations::HraContract.new.call(params)
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

    def init_hra_object(input)
      hra_obj = ::Operations::InitializeHra.new.call(input.to_h).success
      Success(hra_obj)
    end

    def find_member_premium(hra_obj)
      member_premium_result = ::Operations::MemberPremium.new.call(hra_obj)
      if member_premium_result.success?
        sucess_res = member_premium_result.success
        hra_obj.member_premium = sucess_res.first
        hra_obj.carrier_name = sucess_res[1]
        hra_obj.hios_id = sucess_res[2]
        hra_obj.plan_name = sucess_res[3]
        Success(hra_obj)
      else
        Failure(hra_obj.to_h)
      end
    end

    def calculate_hra_cost(hra_object)
      annual_household_income = ::Operations::AnnualAmount.new.call({frequency: hra_object.household_frequency, amount: hra_object.household_amount})
      annual_hra_amount = ::Operations::AnnualAmount.new.call({frequency: hra_object.hra_frequency, amount: hra_object.hra_amount})
      hra_object.hra = begin
                         ((hra_object.member_premium * 12) - annual_hra_amount)/annual_household_income
                       rescue => e
                         hra_object.errors += ['Could Not calculate hra for the given data']
                         return Failure(hra_object.to_h)
                       end
      Success(hra_object)
    end

    def determine_affordability(hra_object)
      year = hra_object.start_month.year
      benefit_year = ::Enterprises::BenefitYear.where(calendar_year: year).first
      return Failure({errors: ["Could not find a valid benefit year for given start_date: #{hra_object.start_month.to_s}"]}) if benefit_year.nil?

      hra_object.hra_determination = benefit_year.expected_contribution >= hra_object.hra ? :affordable : :unaffordable
      Success({hra_object: hra_object, expected_contribution: benefit_year.expected_contribution})
    end

    def store_hra_object(hash_input)
      ::Transactions::StoreHraDetermination.new.call(hash_input)
      Success(hash_input[:hra_object])
    end

    def load_results_defaulter(hra_object)
      hra_results_setter = ::Operations::HraDefaultResultsSetter.new.call(hra_object.tenant)
      result_hash = hra_object.to_h
      result_hash.merge!(hra_results_setter.success.to_h)
      Success(result_hash)
    end
  end
end
