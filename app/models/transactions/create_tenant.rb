module Transactions
  class CreateTenant

    include Dry::Transaction(container: ::Registry)

    step :fetch
    step :construct_attributes
    step :validate, with: "resource_registry.tenants.validate"
    step :persist

    private

    def fetch(input, enterprise:)
      @enterprise = enterprise
      @account    = Account.where(email: input[:account_email]).first

      if @enterprise.blank?
        Failure({errors: {enterprise_id: "Unable to find enterprise record with id #{enterprise_id}"}})
      elsif @account.blank?
        Failure({errors: {account_email: "Unable to find account with id #{input[:account_email]}"}})
      elsif @account.tenant.present?
        Failure({errors: {account_email: "(#{input[:account_email]}) is owner for another marketplace. Please choose different account."}})
      elsif @enterprise.tenants.where(key: input[:key]).present?
        Failure({errors: {marketplace: "already exists for the selected state."}})
      else
        Success(input.slice(:key, :owner_organization_name))
      end
    end

    def construct_attributes(input)
      tenant_settings   = ResourceRegistry::AppSettings[:tenants][0]
      tenant_attributes = tenant_settings.merge(input)
      
      Success(tenant_attributes)
    end

    def validate(input)
      result = super(input)

      if result.success?
        Success(result)
      else
        Failure(result.errors)
      end
    end

    def persist(input)
      tenant = Tenants::Tenant.new(input.to_h)
      tenant.enterprise_id = @enterprise.id
      consumer_site = tenant.sites.detect{|site| site.key == :consumer_portal}
      consumer_site.options.build(key: :translations, namespaces: translations.map(&:to_h))
      
      if tenant.save
        @account.update_attributes!(tenant_id: tenant.id)
        Success(tenant)
      else
        Failure(tenant)
      end
    end

    def translations
      translations = Transactions::LoadTranslations.new.call
      translations.value!
    end
  end
end