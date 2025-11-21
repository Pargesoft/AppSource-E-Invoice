page 70093485 "PRG_E-Export Setup"
{
    ApplicationArea = All;
    Caption = 'E-Export Setup';
    PageType = Card;
    SourceTable = "PRG_E-Export Setup";
    UsageCategory = Administration;
    layout
    {
        area(content)
        {
            group(Genel)
            {
                Caption = 'General';
                field("E-Export Starting Date"; Rec."E-Export Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'E-Export Starting Date';
                    ToolTip = 'Specifies the value of the E-Export Starting Date field.';
                }
                field("Company Country/Region Code"; Rec."Company Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Country/Region Code';
                    ToolTip = 'Specifies the value of the Country/Region Code field.';
                }
            }
            group(Default)
            {
                Caption = 'Default';
                field("Default Party Identification"; Rec."Default Party Identification")
                {
                    ApplicationArea = All;
                    Caption = 'Default Party Identification';
                    ToolTip = 'Specifies the value of the Default Party Identification field.';
                }
                field("E-Export ProfileID"; Rec."E-Export ProfileID")
                {
                    ApplicationArea = All;
                    Caption = 'ProfileID';
                    ToolTip = 'Specifies the value of the ProfileID field.';
                }
                field("Default Delivery Terms ID"; Rec."Default Delivery Terms ID")
                {
                    ApplicationArea = All;
                    Caption = 'Default Delivery Terms ID';
                    ToolTip = 'Specifies the value of the Default Delivery Terms ID field.';
                }
            }
            group(Tax)
            {
                Caption = 'Tax';
                field("Default Exemption Tax Code"; Rec."Default Exemption Tax Code")
                {
                    ApplicationArea = All;
                    Caption = 'Default Exemption Type Code';
                    ToolTip = 'Specifies the value of the Default Exemption Type Code field.';
                }
                field("Default Exemption Tax Desc"; Rec."Default Exemption Tax Desc")
                {
                    ApplicationArea = All;
                    Caption = 'Default Tax Exemption Reason Description';
                    ToolTip = 'Specifies the value of the Default Tax Exemption Reason Description field.';
                }
            }
            group(Ministry)
            {
                Caption = 'Ministry';
                field("Ministry Web Adress"; Rec."Ministry Web Adress")
                {
                    ApplicationArea = All;
                    Caption = 'Ministry Web Adress';
                    ToolTip = 'Specifies the value of the Ministry Web Adress field.';
                }
                field("Ministry Building Number"; Rec."Ministry Building Number")
                {
                    ApplicationArea = All;
                    Caption = 'Ministry Building Number';
                    ToolTip = 'Specifies the value of the Ministry Building Number field.';
                }
                field("Ministry TaxScheme"; Rec."Ministry TaxScheme")
                {
                    ApplicationArea = All;
                    Caption = 'Ministry TaxScheme';
                    ToolTip = 'Specifies the value of the Ministry TaxScheme field.';
                }
                field("Ministry Mail Adress"; Rec."Ministry Mail Adress")
                {
                    ApplicationArea = All;
                    Caption = 'Ministry Mail Adress';
                    ToolTip = 'Specifies the value of the Ministry Mail Adress field.';
                }
                field("Ministry Telephone"; Rec."Ministry Telephone")
                {
                    ApplicationArea = All;
                    Caption = 'Ministry Telephone';
                    ToolTip = 'Specifies the value of the Ministry Telephone field.';
                }
                field("Ministry Telefax"; Rec."Ministry Telefax")
                {
                    ApplicationArea = All;
                    Caption = 'Ministry Telefax';
                    ToolTip = 'Specifies the value of the Ministry Telefax field.';
                }
                field("Ministry URN"; Rec."Ministry URN")
                {
                    ApplicationArea = All;
                    Caption = 'GTB E-Invoice Mail Address';
                    ToolTip = 'Specifies the value of the GTB E-Invoice Mail Address field.';
                }
                field("Ministry VKN"; Rec."Ministry VKN")
                {
                    ApplicationArea = All;
                    Caption = 'Ministry Tax Registration No';
                    ToolTip = 'Specifies the value of the Ministry Tax Registration No field.';
                }
                field("Ministry Party Name"; Rec."Ministry Party Name")
                {
                    ApplicationArea = All;
                    Caption = 'Ministry Name';
                    ToolTip = 'Specifies the value of the Ministry Name field.';
                }
                field("Ministry Adress"; Rec."Ministry Adress")
                {
                    ApplicationArea = All;
                    Caption = 'Ministry Adress';
                    ToolTip = 'Specifies the value of the Ministry Adress field.';
                }
                field("Ministry City Subdivision Name"; Rec."Ministry City Subdivision Name")
                {
                    ApplicationArea = All;
                    Caption = 'Ministry Subdivision';
                    ToolTip = 'Specifies the value of the Ministry Subdivision field.';
                }
                field("Ministry CityName"; Rec."Ministry CityName")
                {
                    ApplicationArea = All;
                    Caption = 'Ministry City';
                    ToolTip = 'Specifies the value of the Ministry City field.';
                }
                field("Ministry PostalZone"; Rec."Ministry PostalZone")
                {
                    ApplicationArea = All;
                    Caption = 'Ministry Postal Zone';
                    ToolTip = 'Specifies the value of the Ministry Postal Zone field.';
                }
                field("Ministry CountryName"; Rec."Ministry CountryName")
                {
                    ApplicationArea = All;
                    Caption = 'Ministry Country';
                    ToolTip = 'Specifies the value of the Ministry Country field.';
                }
                field("Ministry Party Tax Scheme"; Rec."Ministry Party Tax Scheme")
                {
                    ApplicationArea = All;
                    Caption = 'Ministry Party Tax Scheme';
                    ToolTip = 'Specifies the value of the Ministry Party Tax Scheme field.';
                }
            }
        }
    }

    actions
    {
    }
}

