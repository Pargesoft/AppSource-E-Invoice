codeunit 70093480 "PRG_E-Invoice Efin. Connector"
{
    var
        Prefix_Integrator: Label 'edoksis', Locked = true;
        Prefix_Soap: Label 's', Locked = true;
        FaultPrefix_Soap: Label 'ns2', Locked = true;
        XPath_Body: Label '/s:Envelope/s:Body', Locked = true;
        XPath_BodyFault: Label '/ns2:Fault', Locked = true;
        Namespace_Soap: label 'http://schemas.xmlsoap.org/soap/envelope/', Locked = true;
        Namespace_Fault: label 'http://schemas.xmlsoap.org/soap/envelope/', Locked = true;
        Outs: OutStream;
        IntSetup: Record "PRG_E-Invoice Integrator Setup";
        EInvSetup: Record "PRG_E-Invoice Setup";
        Library: Codeunit "PRG_E-Invoice Library";
        GotEInvSetup: Boolean;
        GotSetup: Boolean;
        Window: Dialog;
        SecondRequest: Boolean;
        Text001: Label 'Connection problem. Please check in with system administrator';
        Text002: Label 'Xml value cant be found';
        Text005: Label '#1#################################\\';
        Text006: Label 'Total Pages                #2######\', Comment = 'Counter';
        Text007: Label 'Current Page               #3######\', Comment = 'Counter';
        Text008: Label 'Time Counter               #4######\', Comment = 'Counter';
        Text009: Label 'E-Invoice Scope has been updated. Time Elapsed : %1';
        Text010: Label 'Update User List';
        Text011: Label 'Error Occured';
        Text012: Label 'document can not read.';
        Text013: Label 'No record found to be import';
        Prefix_Wsse: Label 'wsse', Locked = true;
        Namespace_Schema: Label 'http://www.w3.org/2001/XMLSchema', Locked = true;
        Namespace_SchemaInstance: Label 'http://www.w3.org/2001/XMLSchema-instance', Locked = true;
        Namespace_Integrator: Label 'http://service.connector.uut.cs.com.tr/', Locked = true;
        Namespace_Wsse: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd', Locked = true;

    procedure GetSetup()
    begin
        IF NOT GotSetup then begin
            IntSetup.get();
            GotSetup := true;
        end;
    end;

    procedure GetEInvSetup()
    begin
        if not GotEInvSetup then begin
            EInvSetup.get();
            GotEInvSetup := true;
        end;
    end;

    procedure GetUserList()
    var
        StartDT: DateTime;
    begin

        StartDT := CurrentDateTime;
        IF GuiAllowed then begin
            Window.Open(Text005 + Text006 + Text007 + Text008);
            Window.Update(1, Text010);
        end;

        GetSetup();

        ReadUserList_FromCVList(StartDT);
        UpdateUserList(StartDT);
        IF GuiAllowed then
            Window.Close();
    end;

    procedure GetSingleUser(vknTckn: Text; CV: Option Cust,Vend)
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        LiableComps: Record "PRG_E-Invoice Liable Companies";
        EInvSetup: Record "PRG_E-Invoice Setup";
    begin
        ReadSingleUser(vknTckn);

        case CV of
            CV::Cust:
                begin
                    Cust.SetRange("VAT Registration No.", vknTckn);
                    if Cust.FindFirst() then begin
                        if Cust.PRG_Alias <> '' then begin
                            LiableComps.Reset();
                            LiableComps.SetRange(Identifier, Cust."VAT Registration No.");
                            LiableComps.SetRange(Alias, Cust.PRG_Alias);
                            if LiableComps.IsEmpty then begin
                                LiableComps.SetRange(Alias);
                                if LiableComps.FindFirst() then begin
                                    if not Cust."PRG_Locked Alias" then begin
                                        Cust.PRG_Alias := LiableComps.Alias;
                                        Cust.Modify();
                                    end;
                                end else begin
                                    if not Cust."PRG_Locked Alias" then begin
                                        Cust.PRG_Alias := '';
                                        Cust.Modify();
                                    end;
                                end;
                            end;
                        end else begin
                            LiableComps.Reset();
                            LiableComps.SetRange(Identifier, Cust."VAT Registration No.");
                            if LiableComps.FindFirst() then begin
                                if not Cust."PRG_Locked Alias" then
                                    Cust.PRG_Alias := LiableComps.Alias;
                                Cust."PRG_Profile ID" := EInvSetup."Default ProfileID";
                                Cust.Modify();
                            end;
                        end;
                    end;
                end;
            CV::Vend:
                begin
                    Vend.SetRange("VAT Registration No.", vknTckn);
                    if Vend.FindFirst() then begin
                        if Vend.PRG_Alias <> '' then begin
                            LiableComps.Reset();
                            LiableComps.SetRange(Identifier, Vend."VAT Registration No.");
                            LiableComps.SetRange(Alias, Vend.PRG_Alias);
                            if LiableComps.IsEmpty then begin
                                LiableComps.SetRange(Alias);
                                if LiableComps.FindFirst() then begin
                                    if not Vend."PRG_Locked Alias" then begin
                                        Vend.PRG_Alias := LiableComps.Alias;
                                        Vend.Modify();
                                    end;
                                end else begin
                                    if not Vend."PRG_Locked Alias" then begin
                                        Vend.PRG_Alias := '';
                                        Vend.Modify();
                                    end;
                                end;
                            end;
                        end else begin
                            LiableComps.Reset();
                            LiableComps.SetRange(Identifier, Vend."VAT Registration No.");
                            if LiableComps.FindFirst() then begin
                                if not Vend."PRG_Locked Alias" then
                                    Vend.PRG_Alias := LiableComps.Alias;
                                Vend."PRG_Profile ID" := EInvSetup."Default ProfileID";
                                Vend.Modify();
                            end;
                        end;
                    end;
                end;
        end;
    end;


    procedure UpdateUserList(StartDT: DateTime)
    var
        Cust: Record Customer;
        LiableComps: Record "PRG_E-Invoice Liable Companies";
        EInvSetup: Record "PRG_E-Invoice Setup";
        Vend: Record Vendor;
    begin

        EInvSetup.Get();
        EInvSetup.TestField("Default ProfileID");

        IF Cust.FINDSET() THEN
            REPEAT

                IF Cust."VAT Registration No." <> '' THEN BEGIN
                    if Cust.PRG_Alias <> '' then begin
                        LiableComps.RESET();
                        LiableComps.SETRANGE(Identifier, Cust."VAT Registration No.");
                        LiableComps.SetRange(Alias, Cust.PRG_Alias);
                        if LiableComps.IsEmpty then begin
                            LiableComps.SetRange(Alias);
                            if LiableComps.FindFirst() then begin
                                if not Cust."PRG_Locked Alias" then begin
                                    Cust.PRG_Alias := LiableComps.Alias;
                                    Cust.Modify();
                                end;
                            end else begin
                                if not Cust."PRG_Locked Alias" then begin
                                    Cust.PRG_Alias := '';
                                    Cust.Modify();
                                end;
                            end;
                        end;
                    end else begin
                        LiableComps.RESET();
                        LiableComps.SETRANGE(Identifier, Cust."VAT Registration No.");
                        if LiableComps.FindFirst() then begin
                            if not Cust."PRG_Locked Alias" then
                                Cust.PRG_Alias := LiableComps.Alias;
                            Cust."PRG_Profile ID" := EInvSetup."Default ProfileID";
                            Cust.Modify();
                        end;
                    end;
                END;

            UNTIL Cust.NEXT() = 0;


        IF Vend.FINDSET() THEN
            REPEAT

                IF Vend."VAT Registration No." <> '' THEN BEGIN
                    if Vend.PRG_Alias <> '' then begin
                        LiableComps.RESET();
                        LiableComps.SETRANGE(Identifier, Vend."VAT Registration No.");
                        LiableComps.SetRange(Alias, Vend.PRG_Alias);
                        if LiableComps.IsEmpty then begin
                            LiableComps.SetRange(Alias);
                            if LiableComps.FindFirst() then begin
                                if not Vend."PRG_Locked Alias" then begin
                                    Vend.PRG_Alias := LiableComps.Alias;
                                    Vend.Modify();
                                end;
                            end else begin
                                if not Vend."PRG_Locked Alias" then begin
                                    Vend.PRG_Alias := '';
                                    Vend.Modify();
                                end;
                            end;
                        end;
                    end else begin
                        LiableComps.RESET();
                        LiableComps.SETRANGE(Identifier, Vend."VAT Registration No.");
                        if LiableComps.FindFirst() then begin
                            if not Vend."PRG_Locked Alias" then
                                Vend.PRG_Alias := LiableComps.Alias;
                            Vend."PRG_Profile ID" := EInvSetup."Default ProfileID";
                            Vend.Modify();
                        end;
                    end;
                END;

            UNTIL Vend.NEXT() = 0;

        IF GUIALLOWED THEN
            MESSAGE(STRSUBSTNO(Text009, FORMAT(CURRENTDATETIME - StartDT)));
    end;

    local procedure ClearUserListTables()
    var
        AllUsers: Record "PRG_E-Invoice Liable Companies";
    begin
        AllUsers.Reset();
        AllUsers.DeleteAll();
    end;

    local procedure CreateEnvelope(var XmlDoc: XmlDocument; var BodyXmlNode: XmlNode)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        EnvelopeXmlNode: XmlNode;
        HeaderXmlNode: XmlNode;
        SecurityXmlNode: XmlNode;
        UserNameTokenXmlNode: XmlNode;
        TempXmlNode: XmlNode;
    begin
        GetSetup();
        XMLDOMMgt.AddRootElementWithPrefix(XmlDoc, 'Envelope', Prefix_Soap, Namespace_Soap, EnvelopeXmlNode);
        XMLDOMMgt.AddElementWithPrefix(EnvelopeXmlNode, 'Header', '', Prefix_Soap, Namespace_Soap, HeaderXmlNode);
        XMLDOMMgt.AddElementWithPrefix(HeaderXmlNode, 'Security', '', Prefix_Wsse, Namespace_Wsse, SecurityXmlNode);
        XMLDOMMgt.AddElementWithPrefix(SecurityXmlNode, 'UsernameToken', '', Prefix_Wsse, Namespace_Wsse, UserNameTokenXmlNode);
        XMLDOMMgt.AddElementWithPrefix(UserNameTokenXmlNode, 'Username', IntSetup."E-Invoice Web Service UserName", Prefix_Wsse, Namespace_Wsse, TempXmlNode);
        XMLDOMMgt.AddElementWithPrefix(UserNameTokenXmlNode, 'Password', IntSetup."E-Invoice Web Service Password", Prefix_Wsse, Namespace_Wsse, TempXmlNode);
        XMLDOMMgt.AddElementWithPrefix(EnvelopeXmlNode, 'Body', '', Prefix_Soap, Namespace_Soap, BodyXmlNode);
    end;

    local procedure CreateEnvelopeEArchive(var XmlDoc: XmlDocument; var BodyXmlNode: XmlNode)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        EnvelopeXmlNode: XmlNode;
        HeaderXmlNode: XmlNode;
        SecurityXmlNode: XmlNode;
        UserNameTokenXmlNode: XmlNode;
        TempXmlNode: XmlNode;
    begin
        GetSetup();
        XMLDOMMgt.AddRootElementWithPrefix(XmlDoc, 'Envelope', Prefix_Soap, Namespace_Soap, EnvelopeXmlNode);
        XMLDOMMgt.AddElementWithPrefix(EnvelopeXmlNode, 'Header', '', Prefix_Soap, Namespace_Soap, HeaderXmlNode);
        XMLDOMMgt.AddElementWithPrefix(HeaderXmlNode, 'Security', '', Prefix_Wsse, Namespace_Wsse, SecurityXmlNode);
        XMLDOMMgt.AddElementWithPrefix(SecurityXmlNode, 'UsernameToken', '', Prefix_Wsse, Namespace_Wsse, UserNameTokenXmlNode);
        XMLDOMMgt.AddElementWithPrefix(UserNameTokenXmlNode, 'Username', IntSetup."E-Archive Web Service UserName", Prefix_Wsse, Namespace_Wsse, TempXmlNode);
        XMLDOMMgt.AddElementWithPrefix(UserNameTokenXmlNode, 'Password', IntSetup."E-Archive Web Service Password", Prefix_Wsse, Namespace_Wsse, TempXmlNode);
        XMLDOMMgt.AddElementWithPrefix(EnvelopeXmlNode, 'Body', '', Prefix_Soap, Namespace_Soap, BodyXmlNode);
    end;

    procedure SendDocument(XmlDoc: XmlDocument; UUID: GUID): Boolean
    var
        Queue: Record "PRG_E-Invoice Queue";
    begin
        Queue.SetRange(Type, Queue.Type::Outbox);
        Queue.SetFilter(UniqueIdentifier, UUID);
        Queue.FindFirst();

        if Queue.IntegrationType = Queue.IntegrationType::EInvoice then
            SendInvoice(XmlDoc, UUID)
        else
            SendEArchive(XmlDoc, UUID);

    end;

    procedure SendEArchive(XmlDoc: XmlDocument; UUID: GUID): Boolean
    var
        varSoapTxt: Text;
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        Instr: InStream;
        Instr2: InStream;
        Outstr: OutStream;
        Outstr2: OutStream;
        hashValue: Text;
        Base64Value: Text;
        Queue: Record "PRG_E-Invoice Queue";
        Convert: Codeunit "Base64 Convert";
        CryptographyMgt: Codeunit "Cryptography Management";
        DataComp: Codeunit "Data Compression";
        RequestXML: XmlDocument;
        RequestBodyXml: XmlNode;
        XMLDOMMgt: Codeunit "XML DOM Management";
        RequestXMLNode: XmlNode;
        createdXmlNode: XmlNode;
        DataXMLNode: XmlNode;
        belgeGonderExtNode: XmlNode;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        ResponseText: Text;
        ResponseXMLDoc: XmlDocument;
        ResponseBodyXmlNode: XmlNode;
        ResponseBodyXmlNode2: XmlNode;
        ResponseXmlNode: XmlNode;
        NodeIsExist: Boolean;
        IsFoundFaultMessage: Boolean;
        FaultMessage: Text;
        ResponseOStream: OutStream;
        ResponseIStream: InStream;
        filename: Text;
        belgeOidXml: XmlNode;
        BodyNodeIsExist: Boolean;
        locInputText: Text;
        inputText: Label '{ "islemId" : "%1" ,  "vkn" : "%2"  , "sube": "%3" , "kasa": "%4", "erpKodu": "%5"  }', Locked = true;

        OStr: OutStream;
        IStr: InStream;
        ToFile: Text;
    begin
        GetSetup();
        GetEInvSetup();
        varSoapTxt := '';
        XmlDoc.WriteTo(varSoapTxt);
        hashValue := CryptographyMgt.GenerateHash(varSoapTxt, 0);
        Base64Value := Convert.ToBase64(varSoapTxt);
        varSoapTxt := '';

        CreateEnvelopeEArchive(RequestXML, RequestBodyXml);

        IntSetup.TestField("Document Type");
        IntSetup.TestField("Document Version");
        IntSetup.TestField("Company Code");

        locInputText := STRSUBSTNO(inputText, Library.FormatGUID(UUID), EInvSetup."Supplier Tax Registration No.", 'DFLT', 'DFLT', IntSetup."Company Code");
        XMLDOMMgt.AddElementWithPrefix(RequestBodyXml, 'faturaOlustur', '', 'ser', 'http://service.earsiv.uut.cs.com.tr/', belgeGonderExtNode);
        XMLDOMMgt.AddElement(belgeGonderExtNode, 'input', locInputText, '', createdXmlNode);
        XMLDOMMgt.AddElement(belgeGonderExtNode, 'fatura', '', '', RequestXMLNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'belgeFormati', 'UBL', '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'erpKodu', IntSetup."Company Code", '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'belgeIcerigi', Base64Value, '', createdXmlNode);

        RequestXML.WriteTo(varSoapTxt);

        // TempBlob.CreateOutStream(OStr);
        // RequestXML.WriteTo(OStr);
        // TempBlob.CreateInStream(IStr);
        // ToFile := 'asd.txt';
        // DownloadFromStream(IStr, '', '', '', ToFile);
        // Error('');

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', '');
        IF not Client.Post(IntSetup."E-Archive Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(ResponseText);
        XmlDocument.ReadFrom(ResponseText, ResponseXMLDoc);
        BodyNodeIsExist := XMLDOMMgt.FindNodeWithNamespace(ResponseXMLDoc.AsXmlNode(),
                XPath_Body,
                Prefix_Soap,
                Namespace_Soap,
                ResponseBodyXmlNode);

        IsFoundFaultMessage := XMLDOMMgt.FindNodeWithNamespace(ResponseBodyXmlNode,
        'ns2:Fault',
        'ns2',
        Namespace_Fault,
        ResponseBodyXmlNode2);

        if IsFoundFaultMessage then begin
            if ResponseBodyXmlNode2.SelectSingleNode('faultstring', ResponseBodyXmlNode) then
                Error(ResponseBodyXmlNode.AsXmlElement().InnerText)
            else
                Error(ResponseText);

        end;

        Queue.SetRange(Type, Queue.Type::Outbox);
        Queue.SetFilter(UniqueIdentifier, UUID);
        Queue.FindFirst();

        if not BodyNodeIsExist then begin
            Queue.ResultStatusCode := '9999';
            Queue.ResultStatusDescription := CopyStr(ResponseText, 1, MaxStrLen(Queue.ResultStatusDescription));
            Queue.Modify();
            exit;
        end;

        XMLDOMMgt.FindNodeWithNamespace(ResponseBodyXmlNode, 'ns2:faturaOlusturResponse', 'ns2', 'http://service.earsiv.uut.cs.com.tr/', ResponseXmlNode);
        ResponseXmlNode.SelectSingleNode('return', ResponseBodyXmlNode);
        if ResponseBodyXmlNode.SelectSingleNode('resultCode', createdXmlNode) then begin
            Queue.ResultStatusCode := createdXmlNode.AsXmlElement().InnerText();
            Queue.Modify();
        end;

        if ResponseBodyXmlNode.SelectSingleNode('resultText', createdXmlNode) then begin
            Queue.ResultStatusDescription := CopyStr(createdXmlNode.AsXmlElement().InnerText(), 1, MaxStrLen(Queue.ResultStatusDescription));
            Queue.Modify();
        end;

    end;

    procedure SendInvoice(XmlDoc: XmlDocument; UUID: GUID): Boolean
    var
        varSoapTxt: Text;
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        Instr: InStream;
        Instr2: InStream;
        Outstr: OutStream;
        Outstr2: OutStream;
        hashValue: Text;
        Base64Value: Text;
        Queue: Record "PRG_E-Invoice Queue";
        Convert: Codeunit "Base64 Convert";
        CryptographyMgt: Codeunit "Cryptography Management";
        DataComp: Codeunit "Data Compression";
        RequestXML: XmlDocument;
        RequestBodyXml: XmlNode;
        XMLDOMMgt: Codeunit "XML DOM Management";
        RequestXMLNode: XmlNode;
        createdXmlNode: XmlNode;
        DataXMLNode: XmlNode;
        belgeGonderExtNode: XmlNode;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        ResponseText: Text;
        ResponseXMLDoc: XmlDocument;
        ResponseBodyXmlNode: XmlNode;
        ResponseBodyXmlNode2: XmlNode;
        ResponseXmlNode: XmlNode;
        NodeIsExist: Boolean;
        IsFoundFaultMessage: Boolean;
        FaultMessage: Text;
        ResponseOStream: OutStream;
        ResponseIStream: InStream;
        filename: Text;
        belgeOidXml: XmlNode;
        BodyNodeIsExist: Boolean;
    begin
        GetSetup();
        GetEInvSetup();
        varSoapTxt := '';
        XmlDoc.WriteTo(varSoapTxt);
        hashValue := CryptographyMgt.GenerateHash(varSoapTxt, 0);
        Base64Value := Convert.ToBase64(varSoapTxt);
        varSoapTxt := '';

        CreateEnvelope(RequestXML, RequestBodyXml);

        IntSetup.TestField("Document Type");
        IntSetup.TestField("Document Version");
        IntSetup.TestField("Company Code");

        XMLDOMMgt.AddElementWithPrefix(RequestBodyXml, 'belgeGonderExt', '', Prefix_Integrator, Namespace_Integrator, belgeGonderExtNode);
        XMLDOMMgt.AddElement(belgeGonderExtNode, 'parametreler', '', '', RequestXMLNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'belgeHash', hashValue, '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'belgeNo', Library.FormatGUID(UUID), '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'belgeTuru', IntSetup."Document Type", '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'belgeVersiyon', IntSetup."Document Version", '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'donusTipiVersiyon', '1.0', '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'erpKodu', IntSetup."Company Code", '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'mimeType', 'application/xml', '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'vergiTcKimlikNo', EInvSetup."Supplier Tax Registration No.", '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'veri', Base64Value, '', createdXmlNode);

        RequestXML.WriteTo(varSoapTxt);

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', '');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(ResponseText);
        XmlDocument.ReadFrom(ResponseText, ResponseXMLDoc);
        BodyNodeIsExist := XMLDOMMgt.FindNodeWithNamespace(ResponseXMLDoc.AsXmlNode(),
                XPath_Body,
                Prefix_Soap,
                Namespace_Soap,
                ResponseBodyXmlNode);

        Queue.SetRange(Type, Queue.Type::Outbox);
        Queue.SetFilter(UniqueIdentifier, UUID);
        Queue.FindFirst();

        if not BodyNodeIsExist then begin
            Queue.ResultStatusCode := '9999';
            Queue.ResultStatusDescription := CopyStr(ResponseText, 1, MaxStrLen(Queue.ResultStatusDescription));
            Queue.Modify();
            exit;
        end;


        IsFoundFaultMessage := XMLDOMMgt.FindNodeWithNamespace(ResponseBodyXmlNode,
                'ns2:Fault',
                'ns2',
                Namespace_Fault,
                ResponseBodyXmlNode2);

        if IsFoundFaultMessage then begin
            ResponseBodyXmlNode2.SelectSingleNode('faultstring', ResponseBodyXmlNode);
            Queue.ResultStatusCode := '9999';
            Queue.ResultStatusDescription := CopyStr(ResponseBodyXmlNode.AsXmlElement().InnerText, 1, MaxStrLen(Queue.ResultStatusDescription));
            Queue.Modify();
            exit;
        end;

        XMLDOMMgt.FindNodeWithNamespace(ResponseBodyXmlNode, 'ns2:belgeGonderExtResponse', 'ns2', Namespace_Integrator, ResponseXmlNode);
        if ResponseXmlNode.SelectSingleNode('belgeOid', belgeOidXml) then begin
            // Queue."Integrator Uniq. Value" := belgeOidXml.AsXmlElement().InnerText;
            Queue.ResultStatusCode := '1000';
            Queue.ResultStatusDescription := 'Kuyruğa Eklendi';
            Queue.Modify();
        end;

    end;

    procedure DownloadOutgoingDocument(UUID: GUID; DocType: Text): Boolean
    var
        varSoapTxt: Text;
        Queue: Record "PRG_E-Invoice Queue";
        RequestXML: XmlDocument;
        RequestBodyXml: XmlNode;
        XMLDOMMgt: Codeunit "XML DOM Management";
        RequestXMLNode: XmlNode;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        ResponseText: Text;
        ResponseXMLDoc: XmlDocument;
        ResponseBodyXmlNode: XmlNode;
        ResponseXmlNode: XmlNode;
        NodeIsExist: Boolean;
        gidenBelgeleriIndirNode: XmlNode;
        createdXmlNode: XmlNode;
        BodyNodeIsExist: Boolean;
        IsFoundFaultMessage: Boolean;
        ResponseBodyXmlNode2: XmlNode;
        OStr: OutStream;
        IStr: InStream;
        TempBlob: Codeunit "Temp Blob";
        Convert: Codeunit "Base64 Convert";
        FileMgt: Codeunit "File Management";
        ToFile: Text;
        pdfValXml: XmlNode;
        Base64Value: Text;
    begin
        GetSetup();
        GetEInvSetup();
        varSoapTxt := '';
        CreateEnvelope(RequestXML, RequestBodyXml);
        XMLDOMMgt.AddElementWithPrefix(RequestBodyXml, 'gidenBelgeleriIndirEttn', '', Prefix_Integrator, Namespace_Integrator, gidenBelgeleriIndirNode);
        XMLDOMMgt.AddElement(gidenBelgeleriIndirNode, 'vergiTcKimlikNo', EInvSetup."Supplier Tax Registration No.", '', createdXmlNode);
        XMLDOMMgt.AddElement(gidenBelgeleriIndirNode, 'belgeEttnListesi', Library.FormatGUID(UUID), '', createdXmlNode);
        XMLDOMMgt.AddElement(gidenBelgeleriIndirNode, 'belgeFormati', DocType, '', createdXmlNode);
        XMLDOMMgt.AddElement(gidenBelgeleriIndirNode, 'belgeTuru', 'FATURA', '', createdXmlNode);

        RequestXML.WriteTo(varSoapTxt);
        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', '');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(ResponseText);
        if not XmlDocument.ReadFrom(ResponseText, ResponseXMLDoc) then
            Error(ResponseText);

        BodyNodeIsExist := XMLDOMMgt.FindNodeWithNamespace(ResponseXMLDoc.AsXmlNode(),
                XPath_Body,
                Prefix_Soap,
                Namespace_Soap,
                ResponseBodyXmlNode);

        if not BodyNodeIsExist then
            ERROR(ResponseText);

        IsFoundFaultMessage := XMLDOMMgt.FindNodeWithNamespace(ResponseBodyXmlNode,
                'ns2:Fault',
                'ns2',
                Namespace_Fault,
                ResponseBodyXmlNode2);

        if IsFoundFaultMessage then begin
            ResponseBodyXmlNode2.SelectSingleNode('faultstring', ResponseBodyXmlNode);
            Error(ResponseBodyXmlNode.AsXmlElement().InnerText);
        end;

        XMLDOMMgt.FindNodeWithNamespace(ResponseBodyXmlNode, 'ns2:gidenBelgeleriIndirEttnResponse', 'ns2', Namespace_Integrator, ResponseXmlNode);
        if ResponseXmlNode.SelectSingleNode('return', pdfValXml) then begin
            Base64Value := pdfValXml.AsXmlElement().InnerText;
            Tempblob.CreateOutStream(OStr, TextEncoding::UTF8);
            Convert.FromBase64(Base64Value, OStr);
            TempBlob.CreateInStream(IStr, TextEncoding::UTF8);
            UnzipAndDownloadFile(IStr);
        end;
    end;

    local procedure UnzipAndDownloadFile(ResponseInStream: InStream)
    var
        TempBlob: Codeunit "Temp Blob";
        EntryList: List of [Text];
        EntryListKey: Text;
        DataCompression: Codeunit "Data Compression";
        EntryOutStream: OutStream;
        FileMgt: Codeunit "File Management";
        Length: Integer;
        ToFile: Text;
        FileExtension: Text;
        UnzipInStream: InStream;
    begin
        DataCompression.OpenZipArchive(ResponseInStream, false);
        DataCompression.GetEntryList(EntryList);
        foreach EntryListKey in EntryList do begin
            ToFile := CopyStr(FileMgt.GetFileNameWithoutExtension(EntryListKey), 1, MaxStrLen(ToFile));
            FileExtension := CopyStr(FileMgt.GetExtension(EntryListKey), 1, MaxStrLen(FileExtension));
            TempBlob.CreateOutStream(EntryOutStream);
            Length := DataCompression.ExtractEntry(EntryListKey, EntryOutStream);
            TempBlob.CreateInStream(UnzipInStream);
            ToFile := ToFile + '.' + FileExtension;
            DownloadFromStream(UnzipInStream, 'Fatura Pdf', '', '', ToFile);
        end;
    end;

    procedure DownloadIncomingDocument(UUID: Text; DocType: Text): InStream
    var
        varSoapTxt: Text;
        Queue: Record "PRG_E-Invoice Queue";
        RequestXML: XmlDocument;
        RequestBodyXml: XmlNode;
        XMLDOMMgt: Codeunit "XML DOM Management";
        RequestXMLNode: XmlNode;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        ResponseText: Text;
        ResponseXMLDoc: XmlDocument;
        ResponseBodyXmlNode: XmlNode;
        ResponseXmlNode: XmlNode;
        NodeIsExist: Boolean;
        gidenBelgeleriIndirNode: XmlNode;
        createdXmlNode: XmlNode;
        BodyNodeIsExist: Boolean;
        IsFoundFaultMessage: Boolean;
        ResponseBodyXmlNode2: XmlNode;
        OStr: OutStream;
        IStr: InStream;
        TempBlob: Codeunit "Temp Blob";
        Convert: Codeunit "Base64 Convert";
        FileMgt: Codeunit "File Management";
        pdfValXml: XmlNode;
        Base64Value: Text;
        DocStream: InStream;
        ToFile: Text;
        IncomingBuffer: Record "PRG_E-Invoice Incoming Buffer";
        XmlBuffer: Record "XML Buffer" temporary;
        EntryList: List of [Text];
        EntryListKey: Text;
        DataCompression: Codeunit "Data Compression";
        EntryOutStream: OutStream;
        Length: Integer;
        FileExtension: Text;
        UnzipInStream: InStream;
        UblOstream: OutStream;
    begin
        GetSetup();
        GetEInvSetup();
        varSoapTxt := '';
        CreateEnvelope(RequestXML, RequestBodyXml);
        XMLDOMMgt.AddElementWithPrefix(RequestBodyXml, 'gelenBelgeleriIndir', '', Prefix_Integrator, Namespace_Integrator, gidenBelgeleriIndirNode);
        XMLDOMMgt.AddElement(gidenBelgeleriIndirNode, 'vergiTcKimlikNo', EInvSetup."Supplier Tax Registration No.", '', createdXmlNode);
        if SecondRequest then
            XMLDOMMgt.AddElement(gidenBelgeleriIndirNode, 'ettnler', LowerCase(Library.FormatGUID(UUID)), '', createdXmlNode)
        else
            XMLDOMMgt.AddElement(gidenBelgeleriIndirNode, 'ettnler', Library.FormatGUID(UUID), '', createdXmlNode);
        XMLDOMMgt.AddElement(gidenBelgeleriIndirNode, 'belgeFormati', DocType, '', createdXmlNode);
        XMLDOMMgt.AddElement(gidenBelgeleriIndirNode, 'belgeTuru', 'FATURA', '', createdXmlNode);

        RequestXML.WriteTo(varSoapTxt);
        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', '');

        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(ResponseText);
        if not XmlDocument.ReadFrom(ResponseText, ResponseXMLDoc) then
            Error(ResponseText);

        BodyNodeIsExist := XMLDOMMgt.FindNodeWithNamespace(ResponseXMLDoc.AsXmlNode(),
                XPath_Body,
                Prefix_Soap,
                Namespace_Soap,
                ResponseBodyXmlNode);

        if not BodyNodeIsExist then
            ERROR(ResponseText);

        IsFoundFaultMessage := XMLDOMMgt.FindNodeWithNamespace(ResponseBodyXmlNode,
                'ns2:Fault',
                'ns2',
                Namespace_Fault,
                ResponseBodyXmlNode2);

        if IsFoundFaultMessage then begin
            if not SecondRequest then begin
                SecondRequest := true;
                DownloadIncomingDocument(UUID, 'PDF');
                exit;
            end;
            ResponseBodyXmlNode2.SelectSingleNode('faultstring', ResponseBodyXmlNode);
            Error(ResponseBodyXmlNode.AsXmlElement().InnerText);
        end;

        XMLDOMMgt.FindNodeWithNamespace(ResponseBodyXmlNode, 'ns2:gelenBelgeleriIndirResponse', 'ns2', Namespace_Integrator, ResponseXmlNode);
        if ResponseXmlNode.SelectSingleNode('return', pdfValXml) then begin
            case DocType of
                'PDF':
                    begin
                        Base64Value := pdfValXml.AsXmlElement().InnerText;
                        Tempblob.CreateOutStream(OStr, TextEncoding::UTF8);
                        Convert.FromBase64(Base64Value, OStr);
                        TempBlob.CreateInStream(IStr, TextEncoding::UTF8);
                        UnzipAndDownloadFile(IStr);
                    end;
                'UBL':
                    begin
                        Base64Value := pdfValXml.AsXmlElement().InnerText;
                        Tempblob.CreateOutStream(OStr, TextEncoding::UTF8);
                        Convert.FromBase64(Base64Value, OStr);
                        TempBlob.CreateInStream(IStr, TextEncoding::UTF8);

                        IF IncomingBuffer.FindLast() then;

                        IncomingBuffer.Init();
                        IncomingBuffer."Entry No." := IncomingBuffer."Entry No." + 1;
                        IncomingBuffer."Document ID" := UUID;
                        IncomingBuffer."Invoice Value".CreateOutStream(UblOstream);
                        DataCompression.OpenZipArchive(IStr, false);
                        DataCompression.GetEntryList(EntryList);
                        foreach EntryListKey in EntryList do begin
                            Length := DataCompression.ExtractEntry(EntryListKey, UblOstream);
                        end;
                        IncomingBuffer.Insert(true);
                    end;
            end;
        end;
    end;

    local procedure SetInvoicesTaken(UUID: Guid)
    var
        IncomingBuffer: Record "PRG_E-Invoice Incoming Buffer";
        XmlBuffer: Record "XML Buffer" temporary;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        varSoapTxt: Text;
        XMLDOMMgt: Codeunit "XML DOM Management";
        RequestXMLNode: XmlNode;
        createdXmlNode: XmlNode;
        RequestXML: XmlDocument;
        RequestBodyXml: XmlNode;
        belgelerAlindi: XmlNode;
        ResponseText: Text;
        ResponseXMLDoc: XmlDocument;
    begin
        GetSetup();

        CreateEnvelope(RequestXML, RequestBodyXml);
        XMLDOMMgt.AddElementWithPrefix(RequestBodyXml, 'belgelerAlindi', '', Prefix_Integrator, Namespace_Integrator, belgelerAlindi);
        XMLDOMMgt.AddElement(belgelerAlindi, 'vergiTcKimlikNo', EInvSetup."Supplier Tax Registration No.", '', createdXmlNode);
        XMLDOMMgt.AddElement(belgelerAlindi, 'ettn', Library.FormatGUID(UUID), '', createdXmlNode);
        XMLDOMMgt.AddElement(belgelerAlindi, 'belgeTuru', 'FATURA', '', createdXmlNode);

        RequestXML.WriteTo(varSoapTxt);
        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', '');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(ResponseText);
        if not XmlDocument.ReadFrom(ResponseText, ResponseXMLDoc) then
            Error(ResponseText);
    end;

    procedure GetIncomingInvoiceList()
    var
        varSoapTxt: Text;
        Queue: Record "PRG_E-Invoice Queue";
        RequestXML: XmlDocument;
        RequestBodyXml: XmlNode;
        XMLDOMMgt: Codeunit "XML DOM Management";
        RequestXMLNode: XmlNode;
        createdXmlNode: XmlNode;
        DataXMLNode: XmlNode;
        belgeGonderExtNode: XmlNode;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        ResponseText: Text;
        ResponseXMLDoc: XmlDocument;
        ResponseBodyXmlNode: XmlNode;
        ResponseBodyXmlNode2: XmlNode;
        ResponseXmlNode: XmlNode;
        NodeIsExist: Boolean;
        IsFaultMessage: Boolean;
        FaultMessage: Text;
        StartingDate: DateTime;
        EndingDate: DateTime;
        BodyNodeIsExist: Boolean;
        ReturnXmlNodeList: XmlNodeList;
        ReturnXMLNode: XmlNode;
        IsFoundFaultMessage: Boolean;
        XmlBuffer: Record "XML Buffer" temporary;
        IncomingBuffer: Record "PRG_E-Invoice Incoming Buffer";
    begin

        GetSetup();
        GetEInvSetup();
        varSoapTxt := '';
        GetDateRange(StartingDate, EndingDate);
        CreateEnvelope(RequestXML, RequestBodyXml);
        XMLDOMMgt.AddElementWithPrefix(RequestBodyXml, 'gelenBelgeleriListeleExt', '', Prefix_Integrator, Namespace_Integrator, belgeGonderExtNode);
        XMLDOMMgt.AddElement(belgeGonderExtNode, 'parametreler', '', '', RequestXMLNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'erpKodu', IntSetup."Company Code", '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'vergiTcKimlikNo', EInvSetup."Supplier Tax Registration No.", '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'gelisTarihiBaslangic', Library.FormatDateTime(StartingDate), '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'gelisTarihiBitis', Library.FormatDateTime(EndingDate), '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'onayDurum', 'HEPSI', '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'belgeTuru', 'FATURA', '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'donusTipiVersiyon', IntSetup."Document Type Version", '', createdXmlNode);
        XMLDOMMgt.AddElement(RequestXMLNode, 'belgeVersiyon', IntSetup."Document Version", '', createdXmlNode);

        RequestXML.WriteTo(varSoapTxt);
        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', '');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(ResponseText);
        if not XmlDocument.ReadFrom(ResponseText, ResponseXMLDoc) then
            Error(ResponseText);

        BodyNodeIsExist := XMLDOMMgt.FindNodeWithNamespace(ResponseXMLDoc.AsXmlNode(),
                XPath_Body,
                Prefix_Soap,
                Namespace_Soap,
                ResponseBodyXmlNode);

        if not BodyNodeIsExist then
            Error(ResponseText);

        IsFoundFaultMessage := XMLDOMMgt.FindNodeWithNamespace(ResponseBodyXmlNode,
                'ns2:Fault',
                'ns2',
                Namespace_Fault,
                ResponseBodyXmlNode2);

        if IsFoundFaultMessage then begin
            ResponseBodyXmlNode2.SelectSingleNode('faultstring', ResponseBodyXmlNode);
            Error(ResponseBodyXmlNode.AsXmlElement().InnerText);
        end;

        NodeIsExist := XMLDOMMgt.FindNodeWithNamespace(ResponseBodyXmlNode,
           Prefix_Integrator + ':gelenBelgeleriListeleExtResponse',
           Prefix_Integrator, Namespace_Integrator, ResponseXmlNode);

        IF NOT NodeIsExist THEN begin
            Message(Text013);
            exit;
        end;

        XmlBuffer.LoadFromText(ResponseText);
        XmlBuffer.SetRange(Type, XmlBuffer.Type::Element);
        XmlBuffer.SetRange(Name, 'ettn');
        if not XmlBuffer.FindFirst() then
            exit;

        repeat
            IF NOT Library.IsAllReadyImported(XmlBuffer.Value) then begin
                DownloadIncomingDocument(XmlBuffer.Value, 'UBL');
                SetInvoicesTaken(XmlBuffer.Value);
                Commit();
            end;
        until XmlBuffer.Next() = 0;
    end;

    procedure GetOutboxStatus(var Queue: Record "PRG_E-Invoice Queue")
    var
        XmlBuffer: Record "XML Buffer" temporary;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        varSoapTxt: Text;
        RequestXML: XmlDocument;
        RequestBodyXml: XmlNode;
        XMLDOMMgt: Codeunit "XML DOM Management";
        RequestXMLNode: XmlNode;
        createdXmlNode: XmlNode;
        gidenBelgeDurumSorgulaNode: XmlNode;
        ResponseText: Text;
        ResponseXMLDoc: XmlDocument;
        BodyNodeIsExist: Boolean;
        ResponseBodyXmlNode: XmlNode;
        ResponseBodyXmlNode2: XmlNode;
        IsFoundFaultMessage: Boolean;
    begin

        GetSetup();
        GetEInvSetup();
        varSoapTxt := '';
        CreateEnvelope(RequestXML, RequestBodyXml);
        XMLDOMMgt.AddElementWithPrefix(RequestBodyXml, 'gidenBelgeDurumSorgulaEttn', '', Prefix_Integrator, Namespace_Integrator, gidenBelgeDurumSorgulaNode);
        //XMLDOMMgt.AddElement(gidenBelgeDurumSorgulaNode, 'parametreler', '', '', RequestXMLNode);
        XMLDOMMgt.AddElement(gidenBelgeDurumSorgulaNode, 'vergiTcKimlikNo', EInvSetup."Supplier Tax Registration No.", '', createdXmlNode);
        XMLDOMMgt.AddElement(gidenBelgeDurumSorgulaNode, 'ettn', UpperCase(Library.FormatGUID(Queue.UniqueIdentifier)), '', createdXmlNode);//Uppercase Added - BAO


        RequestXML.WriteTo(varSoapTxt);
        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', '');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(ResponseText);
        if not XmlDocument.ReadFrom(ResponseText, ResponseXMLDoc) then
            Error(ResponseText);

        BodyNodeIsExist := XMLDOMMgt.FindNodeWithNamespace(ResponseXMLDoc.AsXmlNode(),
                XPath_Body,
                Prefix_Soap,
                Namespace_Soap,
                ResponseBodyXmlNode);

        if not BodyNodeIsExist then
            Error(ResponseText);

        IsFoundFaultMessage := XMLDOMMgt.FindNodeWithNamespace(ResponseBodyXmlNode,
                'ns2:Fault',
                'ns2',
                Namespace_Fault,
                ResponseBodyXmlNode2);

        if IsFoundFaultMessage then begin
            ResponseBodyXmlNode2.SelectSingleNode('faultstring', ResponseBodyXmlNode);
            Error(ResponseBodyXmlNode.AsXmlElement().InnerText);
        end;

        Response.Content.ReadAs(varSoapTxt);
        XmlBuffer.LoadFromText(varSoapTxt);
        if not XmlBuffer.FindFirst() then
            Error(Text011);

        XmlBuffer.reset();
        XmlBuffer.SetRange(Name, 'gonderimCevabiKodu');
        XmlBuffer.FindFirst();
        Queue.Validate(ResultStatusCode, XmlBuffer.Value);

        XmlBuffer.reset();
        XmlBuffer.SetRange(Name, 'gonderimCevabiDetayi');
        XmlBuffer.FindFirst();
        Queue.ResultStatusDescription := XmlBuffer.Value;

    end;

    procedure GetEArchiveOutboxStatus(var Queue: Record "PRG_E-Invoice Queue")
    var
        XmlBuffer: Record "XML Buffer" temporary;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        varSoapTxt: Text;
        RequestXML: XmlDocument;
        RequestBodyXml: XmlNode;
        XMLDOMMgt: Codeunit "XML DOM Management";
        RequestXMLNode: XmlNode;
        createdXmlNode: XmlNode;
        gidenBelgeDurumSorgulaNode: XmlNode;
        ResponseText: Text;
        ResponseXMLDoc: XmlDocument;
        BodyNodeIsExist: Boolean;
        ResponseBodyXmlNode: XmlNode;
        ResponseBodyXmlNode2: XmlNode;
        IsFoundFaultMessage: Boolean;
    begin

        GetSetup();
        GetEInvSetup();
        varSoapTxt := '';
        CreateEnvelope(RequestXML, RequestBodyXml);
        XMLDOMMgt.AddElementWithPrefix(RequestBodyXml, 'faturaSorgulaExt', '', Prefix_Integrator, Namespace_Integrator, gidenBelgeDurumSorgulaNode);
        XMLDOMMgt.AddElement(gidenBelgeDurumSorgulaNode, 'input', '{"faturaNo":"' + Queue.InvoiceID + '"}', '', createdXmlNode);

        RequestXML.WriteTo(varSoapTxt);
        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', '');
        IF not Client.Post(IntSetup."E-Archive Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(ResponseText);
        if not XmlDocument.ReadFrom(ResponseText, ResponseXMLDoc) then
            Error(ResponseText);

        BodyNodeIsExist := XMLDOMMgt.FindNodeWithNamespace(ResponseXMLDoc.AsXmlNode(),
                XPath_Body,
                Prefix_Soap,
                Namespace_Soap,
                ResponseBodyXmlNode);

        if not BodyNodeIsExist then
            Error(ResponseText);

        IsFoundFaultMessage := XMLDOMMgt.FindNodeWithNamespace(ResponseBodyXmlNode,
                'ns2:Fault',
                'ns2',
                Namespace_Fault,
                ResponseBodyXmlNode2);

        if IsFoundFaultMessage then begin
            ResponseBodyXmlNode2.SelectSingleNode('faultstring', ResponseBodyXmlNode);
            Error(ResponseBodyXmlNode.AsXmlElement().InnerText);
        end;

        Response.Content.ReadAs(varSoapTxt);
        XmlBuffer.LoadFromText(varSoapTxt);
        if not XmlBuffer.FindFirst() then
            Error(Text011);

        XmlBuffer.reset();
        XmlBuffer.SetRange(Name, 'resultCode');
        XmlBuffer.FindFirst();
        Queue.Validate(ResultStatusCode, XmlBuffer.Value);

        XmlBuffer.reset();
        XmlBuffer.SetRange(Name, 'resultText');
        XmlBuffer.FindFirst();
        Queue.ResultStatusDescription := XmlBuffer.Value;

    end;

    local procedure GetDateRange(var StartingDate: DateTime; var EndingDate: DateTime)
    begin
        EInvSetup.GET;
        StartingDate := CREATEDATETIME(CALCDATE('<-7D>', TODAY), 0T);
        EndingDate := CREATEDATETIME(CalcDate('<+1D>', Today), 235900T);
    end;

    local procedure ReadSingleUser(vknTckn: Text)
    var
        Xmlbuffer: Record "XML Buffer" temporary;
        Xmlbuffer2: Record "XML Buffer" temporary;
        Customer: Record Customer;
        Vendor: Record Vendor;
        Liables: Record "PRG_E-Invoice Liable Companies";
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        EntryNo: Integer;
        i: Integer;
        ResponseText: Text;
        varSoapTxt: Text;
        srvText: Text;
        Found: Boolean;
        XMLDOMMgt: Codeunit "XML DOM Management";
        ResponseBodyXmlNode: XmlNode;
        ResponseXMLDoc: XmlDocument;
        Tempblob: Codeunit "Temp Blob";
        OStream: OutStream;
        IStream: InStream;
    begin
        GetSetup();
        //ClearUserListTables();

        IF (not Xmlbuffer.IsTemporary) OR (not Xmlbuffer2.IsTemporary) then
            Error('-');

        Clear(ResponseText);
        Clear(varSoapTxt);
        clear(Client);
        clear(Content);
        Clear(HeaderContent);
        Clear(Response);
        Clear(srvText);

        srvText := '<vergiTcKimlikNoListesi>' + vknTckn + '</vergiTcKimlikNoListesi>';

        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://service.connector.uut.cs.com.tr/" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">'
                        + '<soapenv:Header>'
                        + '<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                        + '<wsse:UsernameToken>'
                        + '<wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                        + '<wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">'
                        + IntSetup."E-Invoice Web Service Password"
                        + '</wsse:Password>'
                        + '</wsse:UsernameToken>'
                        + '</wsse:Security>'
                        + '</soapenv:Header>'
                        + '<soapenv:Body>'
                        + '<ser:efaturaKullaniciListesi>'
                        + srvText
                        + '</ser:efaturaKullaniciListesi>'
                        + '</soapenv:Body>'
                        + '</soapenv:Envelope>';

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);

        HeaderContent.Add('SOAPAction', '');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(ResponseText);

        Xmlbuffer.reset();
        Xmlbuffer.DeleteAll();
        CLEAR(Xmlbuffer);
        Xmlbuffer2.reset();
        Xmlbuffer2.DeleteAll();
        clear(Xmlbuffer2);
        XmlDocument.ReadFrom(ResponseText, ResponseXMLDoc);
        Found := XMLDOMMgt.FindNodeWithNamespace(ResponseXMLDoc.AsXmlNode(), XPath_Body, Prefix_Soap, Namespace_Soap, ResponseBodyXmlNode);
        IF NOT Found THEN
            ERROR(Text012);

        Tempblob.CreateOutStream(OStream, TextEncoding::UTF8);
        Tempblob.CreateInStream(IStream, TextEncoding::UTF8);
        ResponseBodyXmlNode.WriteTo(OStream);

        IF TryLoadUserXml(IStream, Xmlbuffer) then begin

            Xmlbuffer2.LoadFromStream(IStream);

            Xmlbuffer.reset();
            Xmlbuffer.SetRange(Type, Xmlbuffer.Type::Element);
            Xmlbuffer.SetRange(Name, 'efaturaKullaniciListesi');
            IF Xmlbuffer.FindFirst() then
                repeat
                    if Liables.FindLast() then
                        EntryNo := Liables."Entry No." + 1
                    else
                        EntryNo := EntryNo + 1;
                    InitAllUsers(EntryNo,
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'vergiTcKimlikNo', 1),
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'etiket', 1),
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'unvan', 1),
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'kamuKurulusu', 1),
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'kayitZamani', 1));
                until Xmlbuffer.Next() = 0;
        end;
    end;


    local procedure ReadUserList_FromCVList(StartDT: DateTime)
    var
        Xmlbuffer: Record "XML Buffer" temporary;
        Xmlbuffer2: Record "XML Buffer" temporary;
        Customer: Record Customer;
        Vendor: Record Vendor;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        EntryNo: Integer;
        i: Integer;
        ResponseText: Text;
        varSoapTxt: Text;
        srvText: Text;
        Found: Boolean;
        XMLDOMMgt: Codeunit "XML DOM Management";
        ResponseBodyXmlNode: XmlNode;
        ResponseXMLDoc: XmlDocument;
        Tempblob: Codeunit "Temp Blob";
        OStream: OutStream;
        IStream: InStream;
    begin
        GetSetup();
        ClearUserListTables();

        IF (not Xmlbuffer.IsTemporary) OR (not Xmlbuffer2.IsTemporary) then
            Error('-');

        IF GuiAllowed then begin
            Window.Update(3, i);
            Window.Update(4, CurrentDateTime - StartDT);
        end;

        Clear(ResponseText);
        Clear(varSoapTxt);
        clear(Client);
        clear(Content);
        Clear(HeaderContent);
        Clear(Response);
        Clear(srvText);

        Customer.SetFilter("VAT Registration No.", '<>%1', '');
        if Customer.FindSet() then
            repeat
                srvText += '<vergiTcKimlikNoListesi>' + Customer."VAT Registration No." + '</vergiTcKimlikNoListesi>';
            until Customer.Next() = 0;

        Vendor.SetFilter("VAT Registration No.", '<>%1', '');
        if Vendor.FindSet() then
            repeat
                srvText += '<vergiTcKimlikNoListesi>' + Vendor."VAT Registration No." + '</vergiTcKimlikNoListesi>';
            until Vendor.Next() = 0;

        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://service.connector.uut.cs.com.tr/" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">'
                        + '<soapenv:Header>'
                        + '<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                        + '<wsse:UsernameToken>'
                        + '<wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                        + '<wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">'
                        + IntSetup."E-Invoice Web Service Password"
                        + '</wsse:Password>'
                        + '</wsse:UsernameToken>'
                        + '</wsse:Security>'
                        + '</soapenv:Header>'
                        + '<soapenv:Body>'
                        + '<ser:efaturaKullaniciListesi>'
                        + srvText
                        + '</ser:efaturaKullaniciListesi>'
                        + '</soapenv:Body>'
                        + '</soapenv:Envelope>';

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);

        HeaderContent.Add('SOAPAction', '');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(ResponseText);

        Xmlbuffer.reset();
        Xmlbuffer.DeleteAll();
        CLEAR(Xmlbuffer);
        Xmlbuffer2.reset();
        Xmlbuffer2.DeleteAll();
        clear(Xmlbuffer2);
        XmlDocument.ReadFrom(ResponseText, ResponseXMLDoc);
        Found := XMLDOMMgt.FindNodeWithNamespace(ResponseXMLDoc.AsXmlNode(), XPath_Body, Prefix_Soap, Namespace_Soap, ResponseBodyXmlNode);
        IF NOT Found THEN
            ERROR(Text012);

        Tempblob.CreateOutStream(OStream, TextEncoding::UTF8);
        Tempblob.CreateInStream(IStream, TextEncoding::UTF8);
        ResponseBodyXmlNode.WriteTo(OStream);

        IF TryLoadUserXml(IStream, Xmlbuffer) then begin

            Xmlbuffer2.LoadFromStream(IStream);

            Xmlbuffer.reset();
            Xmlbuffer.SetRange(Type, Xmlbuffer.Type::Element);
            Xmlbuffer.SetRange(Name, 'efaturaKullaniciListesi');
            IF Xmlbuffer.FindFirst() then
                repeat
                    EntryNo := EntryNo + 1;
                    InitAllUsers(EntryNo,
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'vergiTcKimlikNo', 1),
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'etiket', 1),
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'unvan', 1),
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'kamuKurulusu', 1),
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'kayitZamani', 1));
                until Xmlbuffer.Next() = 0;
        end;
    end;

    local procedure ReadUserList(StartDT: DateTime)
    var
        Xmlbuffer: Record "XML Buffer" temporary;
        Xmlbuffer2: Record "XML Buffer" temporary;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        EntryNo: Integer;
        i: Integer;
        ResponseText: Text;
        varSoapTxt: Text;
        Found: Boolean;
        XMLDOMMgt: Codeunit "XML DOM Management";
        ResponseBodyXmlNode: XmlNode;
        ResponseXMLDoc: XmlDocument;
        Tempblob: Codeunit "Temp Blob";
        OStream: OutStream;
        IStream: InStream;

    begin

        GetSetup();
        ClearUserListTables();

        IF (not Xmlbuffer.IsTemporary) OR (not Xmlbuffer2.IsTemporary) then
            Error('-');



        IF GuiAllowed then begin
            Window.Update(3, i);
            Window.Update(4, CurrentDateTime - StartDT);
        end;

        Clear(ResponseText);
        Clear(varSoapTxt);
        clear(Client);
        clear(Content);
        Clear(HeaderContent);
        Clear(Response);

        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://service.connector.uut.cs.com.tr/" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">'
                        + '<soapenv:Header>'
                        + '<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                        + '<wsse:UsernameToken>'
                        + '<wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                        + '<wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">'
                        + IntSetup."E-Invoice Web Service Password"
                        + '</wsse:Password>'
                        + '</wsse:UsernameToken>'
                        + '</wsse:Security>'
                        + '</soapenv:Header>'
                        + '<soapenv:Body>'
                        + '<ser:eFaturaKayitliKullaniciListele>'
                        + '</ser:eFaturaKayitliKullaniciListele>'
                        + '</soapenv:Body>'
                        + '</soapenv:Envelope>';

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);

        HeaderContent.Add('SOAPAction', '');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(ResponseText);

        Xmlbuffer.reset();
        Xmlbuffer.DeleteAll();
        CLEAR(Xmlbuffer);
        Xmlbuffer2.reset();
        Xmlbuffer2.DeleteAll();
        clear(Xmlbuffer2);
        XmlDocument.ReadFrom(ResponseText, ResponseXMLDoc);
        Found := XMLDOMMgt.FindNodeWithNamespace(ResponseXMLDoc.AsXmlNode(), XPath_Body, Prefix_Soap, Namespace_Soap, ResponseBodyXmlNode);
        IF NOT Found THEN
            ERROR(Text012);

        Tempblob.CreateOutStream(OStream, TextEncoding::UTF8);
        Tempblob.CreateInStream(IStream, TextEncoding::UTF8);
        ResponseBodyXmlNode.WriteTo(OStream);

        IF TryLoadUserXml(IStream, Xmlbuffer) then begin

            Xmlbuffer2.LoadFromStream(IStream);

            Xmlbuffer.reset();
            Xmlbuffer.SetRange(Type, Xmlbuffer.Type::Element);
            Xmlbuffer.SetRange(Name, 'return');
            IF Xmlbuffer.FindFirst() then
                repeat
                    EntryNo := EntryNo + 1;
                    InitAllUsers(EntryNo,
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'vergiTcKimlikNo', 1),
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'etiket', 1),
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'unvan', 1),
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'kamuKurulusu', 1),
                    Library.GetChildValue(Xmlbuffer2, Xmlbuffer."Entry No.", 'kayitZamani', 1));
                until Xmlbuffer.Next() = 0;
        end;
    end;

    local procedure InitAllUsers(EntryNo: Integer; Identifier: Text; PostboxAlias: Text; Title: Text; _Type: Text; FirstCreateDate: Text)
    var
        AllUsers: Record "PRG_E-Invoice Liable Companies";
    begin
        AllUsers.Init();
        AllUsers."Entry No." := EntryNo;
        AllUsers.Identifier := Identifier;
        AllUsers.Alias := PostboxAlias;
        AllUsers.Title := COPYSTR(Title, 1, MaxStrLen(AllUsers.Title));
        AllUsers.Type := _Type;
        AllUsers."FirstCreationTime" := FirstCreateDate;
        AllUsers.Insert(true);
    end;

    [TryFunction]
    procedure TryLoadUserXml(ResponseStream: InStream; var XmlBuffer: Record "XML Buffer")
    begin
        Xmlbuffer.LoadFromStream(ResponseStream);
    end;

    procedure InitilazeClient(var Client: HttpClient; var Content: HttpContent; var HeaderContent: HttpHeaders; RequestText: Text)
    begin
        Content.WriteFrom(RequestText);
        Content.GetHeaders(HeaderContent);
        RemoveHeader(HeaderContent, 'Content-Type');
        InitHeaderContent(HeaderContent);
        Client.Timeout(300000);
        Client.SetBaseAddress(IntSetup."E-Invoice Integrator URL");
    end;

    procedure RemoveHeader(var HeaderContent: HttpHeaders; _Name: Text)
    begin
        HeaderContent.Remove(_Name);
    end;

    procedure InitHeaderContent(var HeaderContent: HttpHeaders)
    begin
        HeaderContent.Add('Content-Type', 'text/xml;charset=UTF-8');
        HeaderContent.Add('Return-Type', 'text/xml;charset=UTF-8');
    end;


}
