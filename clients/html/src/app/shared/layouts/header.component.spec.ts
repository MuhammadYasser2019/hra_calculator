import { HeaderComponent } from './header.component';
import { HeaderFooterConfigurationConsumer } from '../../configuration/header_footer/header_footer_configuration.service';
import { HeaderFooterConfigurationResource } from '../../configuration/header_footer/header_footer_configuration.resources';

class MockHFConfigurationProvider {
  getHeaderFooterConfiguration(consumer: HeaderFooterConfigurationConsumer) : any {
    consumer.applyHeaderFooterConfiguration(mockResource);
  }
}

class MockFontCustomizer {
  public assignedTypefaceUrl: string | null;
  public assignedTypefaceName: string | null;

  customizeFontFromTypefaceUrl(typefacesUrlValue: string | null, typefacesName) : void {
    this.assignedTypefaceUrl = typefacesUrlValue;
    this.assignedTypefaceName = typefacesName;
  }
}

var mock_marketplace_name = "My Marketplace Name";
var mock_tenant_logo = "My Logo URL";
var mock_tenant_url = "My Tenant URL";
var mock_primary_color_code = "My Primary Color Code";
var mock_typeface_url = "https://fonts.googleapis.com/css?family=Lato:400,700,400italic";
var mock_typeface_name = "Lato";

var mockResource: HeaderFooterConfigurationResource = {
  marketplace_name: mock_marketplace_name,
  site_logo: mock_tenant_logo,
  marketplace_website_url: mock_tenant_url,
  colors: {
    primary_color: mock_primary_color_code,
    typefaces: mock_typeface_url,
    typeface_url: mock_typeface_url,
    typeface_name: mock_typeface_name
  }
};

describe("HeaderComponent",
  () => {
    it("initializes successfully", () => {
      var mockProvider = new MockHFConfigurationProvider();
      var fontCustomizer = new MockFontCustomizer();
      new HeaderComponent(mockProvider, fontCustomizer);
    });
    it("assigns the properties on when the component is initialized", () => {
      var mockProvider = new MockHFConfigurationProvider();
      var fontCustomizer = new MockFontCustomizer();
      var component = new HeaderComponent(mockProvider, fontCustomizer);
      component.ngOnInit();
      expect(component.marketplaceName).toBe(mock_marketplace_name);
      expect(component.tenant_logo_file).toBe('data:image/png;base64,' + mock_tenant_logo);
      expect(component.tenant_url).toBe(mock_tenant_url);
      expect(component.primaryColorCode).toBe(mock_primary_color_code);
    });

    it("customizes the font when the component initialized", () => {
      var mockProvider = new MockHFConfigurationProvider();
      var fontCustomizer = new MockFontCustomizer();
      var component = new HeaderComponent(mockProvider, fontCustomizer);
      component.ngOnInit();
      expect(fontCustomizer.assignedTypefaceUrl).toEqual(mock_typeface_url);
      expect(fontCustomizer.assignedTypefaceName).toEqual(mock_typeface_name);
    });
  }
);