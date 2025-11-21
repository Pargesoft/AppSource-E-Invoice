codeunit 70093471 "PRG_E-Invoice WB Connector"
{
    var
        IntSetup: Record "PRG_E-Invoice Integrator Setup";
        EInvSetup: Record "PRG_E-Invoice Setup";
        Library: Codeunit "PRG_E-Invoice Library";
        GotEInvSetup: Boolean;
        GotSetup: Boolean;
        Window: Dialog;
        Text001: Label 'Connection problem. Please check in with system administrator';
        Text002: Label 'Xml value cant be found';
        Text005: Label '#1#################################\\';
        Text006: Label 'Total Pages                #2######\', Comment = 'Counter';
        Text007: Label 'Current Page               #3######\', Comment = 'Counter';
        Text008: Label 'Time Counter               #4######\', Comment = 'Counter';
        Text009: Label 'E-Invoice Scope has been updated. Time Elapsed : %1';
        Text010: Label 'Update User List';
        Text011: Label 'Error Occured';
        Text012: Label 'XSLT file not found!';
        Text013: Label 'Upload E-Invoice XSLT';
        Text014: Label 'Upload E-Archive XSLT';
        Text015: Label 'If you want to see Preview of E-Invoice PDF, you can upload XSLT from the E-Invoice Setup page or use the buttons below.';
        Text016: Label 'File Upload Successful.';
        Text017: Label 'E-Invoice Approval Status: Sent as %1.';
        Text018: Label '%1 invoice(s) status sent to the service.';

    procedure BatchProcessOutboxStatus(var Queue: Record "PRG_E-Invoice Queue")
    var
        Queue2: Record "PRG_E-Invoice Queue";
    begin

        Queue.SetRange("Queue Status", Queue."Queue Status"::SentToService);
        if not Queue.FindFirst() then
            exit;

        repeat
            Queue2.Get(Queue.EntryNo);
            GetOutboxStatus(Queue2);
            Queue2.Modify();
            Commit();
        until Queue.Next() = 0;

    end;

    procedure FindXmlValue(var XmlBuffer: Record "XML Buffer" temporary; filtertype: Integer; _fieldname: Text)
    begin
        Xmlbuffer.SetRange(Type, filtertype);
        Xmlbuffer.SetRange(Name, _fieldname);
        IF not Xmlbuffer.FindFirst() then
            Error(Text002);
    end;

    procedure GetEInvSetup()
    begin
        if not GotEInvSetup then begin
            EInvSetup.get();
            GotEInvSetup := true;
        end;
    end;

    procedure GetInboxPdf(UUID: GUID)
    var
        XmlBuffer: Record "XML Buffer" temporary;
        Convert: Codeunit "Base64 Convert";
        FileMgt: Codeunit "File Management";
        Tempblob: Codeunit "Temp Blob";
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        IStr: InStream;
        IStr2: InStream;
        OStr: OutStream;
        ToFile: Text;
        varSoapTxt: Text;
    begin

        GetSetup();

        ToFile := Library.FormatGUID(UUID) + '.pdf';

        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                         + ' <soapenv:Header>'
                         + '      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                         + '          <wsse:UsernameToken>'
                         + '              <wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                         + '               <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' + IntSetup."E-Invoice Web Service Password" + '</wsse:Password>'
                         + '            </wsse:UsernameToken>'
                         + '        </wsse:Security>'
                         + '    </soapenv:Header>'
                         + '<soapenv:Body>'
                         + '   <tem:GetInboxInvoicePdf>'
                         + '       <tem:invoiceId>' + Library.FormatGUID(UUID) + '</tem:invoiceId>'
                         + '   </tem:GetInboxInvoicePdf>'
                         + '</soapenv:Body>'
                         + '</soapenv:Envelope>';

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', 'http://tempuri.org/IIntegration/GetInboxInvoicePdf');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);
        XmlBuffer.LoadFromText(varSoapTxt);
        XmlBuffer.SetRange(Name, 'IsSucceded');
        if not XmlBuffer.FindFirst() then
            Error(Text011);

        if XmlBuffer.Value = 'false' then begin
            XmlBuffer.reset();
            XmlBuffer.SetRange(Name, 'Message');
            XmlBuffer.FindFirst();
            Error(XmlBuffer.Value);
        end;

        XmlBuffer.reset();
        XmlBuffer.SetRange(Name, 'Data');
        XmlBuffer.FindFirst();
        XmlBuffer.CalcFields("Value BLOB");

        XmlBuffer."Value BLOB".CreateInStream(IStr, TextEncoding::UTF8);
        Tempblob.CreateOutStream(OStr, TextEncoding::UTF8);
        IStr.Read(varSoapTxt);
        Convert.FromBase64(varSoapTxt, OStr);
        Tempblob.CreateInStream(IStr2, TextEncoding::UTF8);

        FileMgt.BLOBExportWithEncoding(Tempblob, ToFile, true, TextEncoding::UTF8);
    end;

    procedure GetIncomingInvoiceList()
    var
        XmlBuffer: Record "XML Buffer" temporary;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        varSoapTxt: Text;
    begin

        GetSetup();

        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                         + ' <soapenv:Header>'
                         + '      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                         + '          <wsse:UsernameToken>'
                         + '              <wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                         + '               <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' + IntSetup."E-Invoice Web Service Password" + '</wsse:Password>'
                         + '            </wsse:UsernameToken>'
                         + '        </wsse:Security>'
                         + '    </soapenv:Header>'
                         + '<soapenv:Body>'
                         + '  <tem:GetInboxInvoiceList>'
                         + '      <tem:query PageIndex="0" PageSize="500" OnlyNewestInvoices="true">'
                         + '      </tem:query>'
                         + ' </tem:GetInboxInvoiceList>'
                         + '</soapenv:Body>'
                         + '</soapenv:Envelope>';


        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', 'http://tempuri.org/IIntegration/GetInboxInvoiceList');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);
        XmlBuffer.LoadFromText(varSoapTxt);
        XmlBuffer.SetRange(Name, 'IsSucceded');
        if not XmlBuffer.FindFirst() then
            Error(Text011);

        if XmlBuffer.Value = 'false' then begin
            XmlBuffer.reset();
            XmlBuffer.SetRange(Name, 'Message');
            XmlBuffer.FindFirst();
            Error(XmlBuffer.Value);
        end;

        XmlBuffer.reset();
        XmlBuffer.SetRange(Type, XmlBuffer.Type::Element);
        XmlBuffer.SetRange(Name, 'DocumentId');
        if not XmlBuffer.FindFirst() then
            exit;

        repeat
            IF NOT Library.IsAllReadyImported(XmlBuffer.Value) then begin
                RetrieveSingleInvoice(XmlBuffer.Value);
                Commit();
            end;
        until XmlBuffer.Next() = 0;

    end;


    procedure GetOutboxPdf(UUID: GUID)
    var
        XmlBuffer: Record "XML Buffer" temporary;
        Convert: Codeunit "Base64 Convert";
        FileMgt: Codeunit "File Management";
        Tempblob: Codeunit "Temp Blob";
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        IStr: InStream;
        IStr2: InStream;
        OStr: OutStream;
        ToFile: Text;
        varSoapTxt: Text;
    begin

        GetSetup();

        ToFile := Library.FormatGUID(UUID) + '.pdf';

        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                         + ' <soapenv:Header>'
                         + '      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                         + '          <wsse:UsernameToken>'
                         + '              <wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                         + '               <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' + IntSetup."E-Invoice Web Service Password" + '</wsse:Password>'
                         + '            </wsse:UsernameToken>'
                         + '        </wsse:Security>'
                         + '    </soapenv:Header>'
                         + '<soapenv:Body>'
                         + '   <tem:GetOutboxInvoicePdf>'
                         + '       <tem:invoiceId>' + Library.FormatGUID(UUID) + '</tem:invoiceId>'
                         + '   </tem:GetOutboxInvoicePdf>'
                         + '</soapenv:Body>'
                         + '</soapenv:Envelope>';


        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', 'http://tempuri.org/IIntegration/GetOutboxInvoicePdf');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);
        XmlBuffer.LoadFromText(varSoapTxt);
        XmlBuffer.SetRange(Name, 'IsSucceded');
        if not XmlBuffer.FindFirst() then
            Error(Text011);

        if XmlBuffer.Value = 'false' then begin
            XmlBuffer.reset();
            XmlBuffer.SetRange(Name, 'Message');
            XmlBuffer.FindFirst();
            Error(XmlBuffer.Value);
        end;

        XmlBuffer.reset();
        XmlBuffer.SetRange(Name, 'Data');
        XmlBuffer.FindFirst();
        XmlBuffer.CalcFields("Value BLOB");

        XmlBuffer."Value BLOB".CreateInStream(IStr, TextEncoding::UTF8);
        Tempblob.CreateOutStream(OStr, TextEncoding::UTF8);
        IStr.Read(varSoapTxt);
        Convert.FromBase64(varSoapTxt, OStr);
        Tempblob.CreateInStream(IStr2, TextEncoding::UTF8);

        FileMgt.BLOBExportWithEncoding(Tempblob, ToFile, true, TextEncoding::UTF8);
    end;

    procedure GetOutboxStatus(var Queue: Record "PRG_E-Invoice Queue")
    var
        XmlBuffer: Record "XML Buffer" temporary;
        StatusCodes: Record "PRG_E-Invoice Status Code";
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        varSoapTxt: Text;
    begin

        GetSetup();

        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                         + ' <soapenv:Header>'
                         + '      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                         + '          <wsse:UsernameToken>'
                         + '              <wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                         + '               <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' + IntSetup."E-Invoice Web Service Password" + '</wsse:Password>'
                         + '            </wsse:UsernameToken>'
                         + '        </wsse:Security>'
                         + '    </soapenv:Header>'
                         + '<soapenv:Body>'
                         + '  <tem:QueryOutboxInvoiceStatus>'
                         + '      <tem:invoiceIds>'
                         + '          <tem:string>' + Library.FormatGUID(Queue.UniqueIdentifier) + '</tem:string>'
                         + '      </tem:invoiceIds>'
                         + '  </tem:QueryOutboxInvoiceStatus>'
                         + '</soapenv:Body>'
                         + '</soapenv:Envelope>';


        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', 'http://tempuri.org/IIntegration/QueryOutboxInvoiceStatus');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);
        XmlBuffer.LoadFromText(varSoapTxt);
        XmlBuffer.SetRange(Name, 'IsSucceded');
        if not XmlBuffer.FindFirst() then
            Error(Text011);

        if XmlBuffer.Value = 'false' then begin
            XmlBuffer.reset();
            XmlBuffer.SetRange(Name, 'Message');
            XmlBuffer.FindFirst();
            Error(XmlBuffer.Value);
        end;

        XmlBuffer.reset();
        XmlBuffer.SetRange(Name, 'StatusCode');
        if XmlBuffer.FindFirst() then
            Queue.ResultStatusCode := XmlBuffer.Value;

        if StatusCodes.Get(Queue.ResultStatusCode) then
            Queue.ResultStatusDescription := StatusCodes.Description
        else begin
            XmlBuffer.reset();
            XmlBuffer.SetRange(Name, 'Message');
            if XmlBuffer.FindFirst() then begin
                Queue.ResultStatusDescription := XmlBuffer.Value;
                if Queue.ResultStatusCode = '2000' then
                    Queue."Queue Status" := Queue."Queue Status"::Failed;
            end;
        end;

        XmlBuffer.reset();
        XmlBuffer.SetRange(Name, 'Status');
        if XmlBuffer.FindFirst() then
            case XmlBuffer.Value of
                'Approved':
                    Queue."Queue Status" := Queue."Queue Status"::Approved;
                'Declined':
                    Queue."Queue Status" := Queue."Queue Status"::Declined;
            end;

    end;

    procedure GetSetup()
    begin
        IF NOT GotSetup then begin
            IntSetup.get();
            GotSetup := true;
        end;
    end;

    procedure GetUserList()
    var
        StartDT: DateTime;
        TotalPages: Integer;
    begin

        StartDT := CurrentDateTime;
        IF GuiAllowed then begin
            Window.Open(Text005 + Text006 + Text007 + Text008);
            Window.Update(1, Text010);
        end;

        GetSetup();
        TotalPages := GetTotalPages();
        IF TotalPages = 0 then begin
            IF GuiAllowed then
                Window.Close();
            exit;
        END;

        IF GuiAllowed then
            Window.Update(2, TotalPages);
        ReadUserList(TotalPages, StartDT);
        UpdateUserList(StartDT);
        IF GuiAllowed then
            Window.Close();
    end;

    procedure InitHeaderContent(var HeaderContent: HttpHeaders)
    begin
        HeaderContent.Add('Content-Type', 'text/xml;charset=UTF-8');
        HeaderContent.Add('Return-Type', 'text/xml;charset=UTF-8');
    end;

    procedure InitilazeClient(var Client: HttpClient; var Content: HttpContent; var HeaderContent: HttpHeaders; RequestText: Text)
    begin
        Content.WriteFrom(RequestText);
        Content.GetHeaders(HeaderContent);
        RemoveHeader(HeaderContent, 'Content-Type');
        InitHeaderContent(HeaderContent);
        Client.SetBaseAddress(IntSetup."E-Invoice Integrator URL");
    end;

    procedure RemoveHeader(var HeaderContent: HttpHeaders; _Name: Text)
    begin
        HeaderContent.Remove(_Name);
    end;

    procedure RetrieveSingleInvoice(UUID: Text)
    var
        IncomingBuffer: Record "PRG_E-Invoice Incoming Buffer";
        XmlBuffer: Record "XML Buffer" temporary;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        varSoapTxt: Text;
    begin

        GetSetup();

        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                         + ' <soapenv:Header>'
                         + '      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                         + '          <wsse:UsernameToken>'
                         + '              <wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                         + '               <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' + IntSetup."E-Invoice Web Service Password" + '</wsse:Password>'
                         + '            </wsse:UsernameToken>'
                         + '        </wsse:Security>'
                         + '    </soapenv:Header>'
                         + '<soapenv:Body>'
                         + '  <tem:GetInboxInvoiceData>'
                         + '      <tem:invoiceId>' + Library.FormatGUID(UUID) + '</tem:invoiceId>'
                         + ' </tem:GetInboxInvoiceData>'
                         + '</soapenv:Body>'
                         + '</soapenv:Envelope>';

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', 'http://tempuri.org/IIntegration/GetInboxInvoiceData');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);
        XmlBuffer.LoadFromText(varSoapTxt);
        XmlBuffer.SetRange(Name, 'IsSucceded');
        if not XmlBuffer.FindFirst() then
            Error(Text011);

        if XmlBuffer.Value = 'false' then begin
            XmlBuffer.reset();
            XmlBuffer.SetRange(Name, 'Message');
            XmlBuffer.FindFirst();
            Error(XmlBuffer.Value);
        end;

        XmlBuffer.reset();
        XmlBuffer.SetRange(Type, XmlBuffer.Type::Element);
        XmlBuffer.SetRange(Name, 'Data');
        if not XmlBuffer.FindFirst() then
            exit;

        XmlBuffer.CalcFields("Value BLOB");

        Clear(varSoapTxt);
        IF IncomingBuffer.FindLast() then;

        IncomingBuffer.Init();
        IncomingBuffer."Entry No." := IncomingBuffer."Entry No." + 1;
        IncomingBuffer."Document ID" := UUID;
        IncomingBuffer."Invoice Value" := XmlBuffer."Value BLOB";
        IncomingBuffer.Insert(true);

        SetInvoicesTaken(UUID);
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
    begin
        GetSetup();

        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                        + ' <soapenv:Header>'
                        + '      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                        + '          <wsse:UsernameToken>'
                        + '              <wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                        + '               <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' + IntSetup."E-Invoice Web Service Password" + '</wsse:Password>'
                        + '            </wsse:UsernameToken>'
                        + '        </wsse:Security>'
                        + '    </soapenv:Header>'
                        + '<soapenv:Body>'
                        + '  <tem:SetInvoicesTaken>'
                        + '    <tem:invoices>'
                        + '      <tem:string>' + Library.FormatGUID(UUID) + '</tem:string>'
                        + '    </tem:invoices>'
                        + ' </tem:SetInvoicesTaken>'
                        + '</soapenv:Body>'
                        + '</soapenv:Envelope>';

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', 'http://tempuri.org/IIntegration/SetInvoicesTaken');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);
    end;

    procedure SendInvoiceZip(XmlDoc: XmlDocument; UUID: GUID)
    var
        Queue: Record "PRG_E-Invoice Queue";
        XmlBuffer: Record "XML Buffer" temporary;
        Convert: Codeunit "Base64 Convert";
        CryptographyMgt: Codeunit "Cryptography Management";
        DataComp: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        Instr: InStream;
        Instr2: InStream;
        Outstr: OutStream;
        Outstr2: OutStream;
        hashValue: Text;
        stringType: Text;
        varSoapTxt: Text;
        EInvHeader: Record "PRG_E-Invoice Header";
    begin

        GetSetup();

        EInvHeader.SetRange(UUID, UUID);
        IF EInvHeader.FindFirst() Then;

        XmlDoc.WriteTo(varSoapTxt);
        varSoapTxt := varSoapTxt.Replace('<Invoice xmlns', '<InvoiceInfo xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><Invoice xmlns');
        varSoapTxt := varSoapTxt + ' <TargetCustomer VKN="' + EInvHeader.CustRegistrationNo + '" Alias="' + EInvHeader.CustIdentifier + '" />';
        varSoapTxt := varSoapTxt + '</InvoiceInfo>';

        TempBlob.CreateOutStream(Outstr, TextEncoding::UTF8);
        TempBlob2.CreateOutStream(Outstr2, TextEncoding::UTF8);
        Outstr.Write(varSoapTxt);
        TempBlob.CreateInStream(Instr, TextEncoding::UTF8);
        varSoapTxt := '';

        DataComp.CreateZipArchive();
        DataComp.AddEntry(Instr, format(Library.FormatGUID(UUID)) + '.xml');
        DataComp.SaveZipArchive(Outstr2);
        TempBlob2.CreateInStream(Instr2, TextEncoding::UTF8);

        stringType := Convert.ToBase64(Instr2);

        varSoapTxt := '';

        hashValue := CryptographyMgt.GenerateHash(stringType, 0);

        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                         + ' <soapenv:Header>'
                         + '      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                         + '          <wsse:UsernameToken>'
                         + '              <wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                         + '               <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' + IntSetup."E-Invoice Web Service Password" + '</wsse:Password>'
                         + '            </wsse:UsernameToken>'
                         + '        </wsse:Security>'
                         + '    </soapenv:Header>'
                         + '<soapenv:Body>'
                         + '  <tem:CompressedSendInvoice>'
                         + '     <tem:data>'
                         + '        <tem:Hash>' + hashValue + '</tem:Hash>'
                         + '        <tem:Data>' + stringType + '</tem:Data>'
                         + '     </tem:data>'
                         + '  </tem:CompressedSendInvoice>'
                         + '</soapenv:Body>'
                         + '</soapenv:Envelope>';

        OnBeforeInitilazeClient_SendInvoiceZip(XmlDoc, UUID, varSoapTxt, hashValue, stringType);
        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', 'http://tempuri.org/IIntegration/CompressedSendInvoice');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);
        XmlBuffer.LoadFromText(varSoapTxt);
        XmlBuffer.SetRange(Name, 'IsSucceded');
        if not XmlBuffer.FindFirst() then
            Error(Text011);

        if XmlBuffer.Value = 'false' then begin
            XmlBuffer.SetRange(Name, 'Message');
            if XmlBuffer.FindFirst() then
                Error(XmlBuffer.Value);
            exit;
        end;

        Queue.SetFilter(UniqueIdentifier, UUID);
        Queue.FindFirst();

        GetOutboxStatus(Queue);
        Queue.Modify();

    end;

    procedure SendInvoiceDraft(XmlDoc: XmlDocument; UUID: GUID)
    var
        Queue: Record "PRG_E-Invoice Queue";
        XmlBuffer: Record "XML Buffer" temporary;
        Convert: Codeunit "Base64 Convert";
        CryptographyMgt: Codeunit "Cryptography Management";
        DataComp: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        Instr: InStream;
        Instr2: InStream;
        Outstr: OutStream;
        Outstr2: OutStream;
        hashValue: Text;
        stringType: Text;
        varSoapTxt: Text;
        EInvHeader: Record "PRG_E-Invoice Header";
    begin

        GetSetup();

        EInvHeader.SetRange(UUID, UUID);
        IF EInvHeader.FindFirst() Then;

        XmlDoc.WriteTo(varSoapTxt);
        varSoapTxt := varSoapTxt.Replace('<Invoice xmlns', '<InvoiceInfo xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><Invoice xmlns');
        varSoapTxt := varSoapTxt + ' <TargetCustomer VKN="' + EInvHeader.CustRegistrationNo + '" Alias="' + EInvHeader.CustIdentifier + '" />';
        varSoapTxt := varSoapTxt + '</InvoiceInfo>';

        TempBlob.CreateOutStream(Outstr, TextEncoding::UTF8);
        TempBlob2.CreateOutStream(Outstr2, TextEncoding::UTF8);
        Outstr.Write(varSoapTxt);
        TempBlob.CreateInStream(Instr, TextEncoding::UTF8);
        varSoapTxt := '';

        DataComp.CreateZipArchive();
        DataComp.AddEntry(Instr, format(Library.FormatGUID(UUID)) + '.xml');
        DataComp.SaveZipArchive(Outstr2);
        TempBlob2.CreateInStream(Instr2, TextEncoding::UTF8);

        stringType := Convert.ToBase64(Instr2);

        varSoapTxt := '';

        hashValue := CryptographyMgt.GenerateHash(stringType, 0);

        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                         + ' <soapenv:Header>'
                         + '      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                         + '          <wsse:UsernameToken>'
                         + '              <wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                         + '               <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' + IntSetup."E-Invoice Web Service Password" + '</wsse:Password>'
                         + '            </wsse:UsernameToken>'
                         + '        </wsse:Security>'
                         + '    </soapenv:Header>'
                         + '<soapenv:Body>'
                         + '  <tem:CompressedSaveAsDraft>'
                         + '     <tem:data>'
                         + '        <tem:Hash>' + hashValue + '</tem:Hash>'
                         + '        <tem:Data>' + stringType + '</tem:Data>'
                         + '     </tem:data>'
                         + '  </tem:CompressedSaveAsDraft>'
                         + '</soapenv:Body>'
                         + '</soapenv:Envelope>';

        OnBeforeInitilazeClient_SendInvoiceZip(XmlDoc, UUID, varSoapTxt, hashValue, stringType);
        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', 'http://tempuri.org/IIntegration/CompressedSaveAsDraft');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);
        XmlBuffer.LoadFromText(varSoapTxt);
        XmlBuffer.SetRange(Name, 'IsSucceded');
        if not XmlBuffer.FindFirst() then
            Error(Text011);

        Queue.SetFilter(UniqueIdentifier, UUID);
        Queue.FindFirst();

        case XmlBuffer.Value of
            'true':
                begin
                    Queue.ResultStatusCode := '1000';
                    Queue.ResultStatusDescription := 'Kuyruğa Eklendi';
                    Queue.Modify();
                end;
            else begin
                XmlBuffer.reset();
                XmlBuffer.SetRange(Name, 'Message');
                XmlBuffer.FindFirst();
                Queue.ResultStatusCode := '9999';
                Queue.ResultStatusDescription := CopyStr(XmlBuffer.Value, 1, MaxStrLen(Queue.ResultStatusDescription));
                Queue.Modify();
            end;
        end

    end;

    [TryFunction]
    procedure TryLoadUserXml(ResponseText: Text; var XmlBuffer: Record "XML Buffer")
    begin
        Xmlbuffer.LoadFromText(ResponseText);
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

        OnBeforeCustUpdate_UpdateserList(LiableComps, Cust, EInvSetup);
        IF Cust.FINDSET() THEN
            REPEAT

                IF (Cust."VAT Registration No." <> '') and not (Cust."PRG_Locked Alias") THEN BEGIN

                    if Cust.PRG_Alias <> '' then begin
                        LiableComps.RESET();
                        LiableComps.SETRANGE(Identifier, Cust."VAT Registration No.");
                        LiableComps.SetRange(Alias, Cust.PRG_Alias);
                        if LiableComps.IsEmpty then begin
                            LiableComps.SetRange(Alias);
                            if LiableComps.FindFirst() then begin
                                Cust.PRG_Alias := LiableComps.Alias;
                                Cust.Modify();
                            end else begin
                                Cust.PRG_Alias := '';
                                Cust.Modify();
                            end;
                        end;
                    end else begin
                        LiableComps.RESET();
                        LiableComps.SETRANGE(Identifier, Cust."VAT Registration No.");
                        if LiableComps.FindFirst() then begin
                            Cust.PRG_Alias := LiableComps.Alias;
                            Cust."PRG_Profile ID" := EInvSetup."Default ProfileID";
                            Cust.Modify();
                        end;
                    end;
                END;

            UNTIL Cust.NEXT() = 0;

        OnBeforeVendUpdate_UpdateserList(LiableComps, Vend, EInvSetup);
        IF Vend.FINDSET() THEN
            REPEAT

                IF (Vend."VAT Registration No." <> '') and not (Cust."PRG_Locked Alias") THEN BEGIN

                    if Vend.PRG_Alias <> '' then begin
                        LiableComps.RESET();
                        LiableComps.SETRANGE(Identifier, Vend."VAT Registration No.");
                        LiableComps.SetRange(Alias, Vend.PRG_Alias);
                        if LiableComps.IsEmpty then begin
                            LiableComps.SetRange(Alias);
                            if LiableComps.FindFirst() then begin
                                Vend.PRG_Alias := LiableComps.Alias;
                                Vend.Modify();
                            end else begin
                                Vend.PRG_Alias := '';
                                Vend.Modify();
                            end;
                        end;
                    end else begin
                        LiableComps.RESET();
                        LiableComps.SETRANGE(Identifier, Vend."VAT Registration No.");
                        if LiableComps.FindFirst() then begin
                            Vend.PRG_Alias := LiableComps.Alias;
                            Vend."PRG_Profile ID" := EInvSetup."Default ProfileID";
                            Vend.Modify();
                        end;
                    end;
                END;

            UNTIL Vend.NEXT() = 0;

        FinishUpdateUserList(LiableComps, Cust, Vend, EInvSetup);

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

    local procedure GetTotalPages(): Integer
    var
        Xmlbuffer: Record "XML Buffer" temporary;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        TotalPages: Integer;
        ResponseText: Text;
        varSoapTxt: Text;
    begin
        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                + ' <soapenv:Header>'
                + '      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                + '          <wsse:UsernameToken>'
                + '              <wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                + '               <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' + IntSetup."E-Invoice Web Service Password" + '</wsse:Password>'
                + '            </wsse:UsernameToken>'
                + '        </wsse:Security>'
                + '    </soapenv:Header>'
                + '<soapenv:Body>'
                + '<tem:GetEInvoiceUsers>'
                + '<tem:pagination PageIndex="0" PageSize="1000"/>'
                + '</tem:GetEInvoiceUsers>'
                + '</soapenv:Body>'
                + '</soapenv:Envelope>';

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', 'http://tempuri.org/IIntegration/GetEInvoiceUsers');

        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(ResponseText);
        Xmlbuffer.LoadFromText(ResponseText);
        FindXmlValue(Xmlbuffer, 2, 'TotalPages');
        Evaluate(TotalPages, Xmlbuffer.Value);
        exit(TotalPages);
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
        AllUsers.Insert(false);
    end;

    local procedure ReadUserList(TotalPages: Integer; StartDT: DateTime)
    var
        Xmlbuffer: Record "XML Buffer" temporary;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        EntryNo: Integer;
        i: Integer;
        ResponseText: Text;
        varSoapTxt: Text;
    begin

        GetSetup();
        ClearUserListTables();

        IF (not Xmlbuffer.IsTemporary) then
            Error('-');

        for i := 0 to TotalPages - 1 do begin

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

            varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                        + ' <soapenv:Header>'
                        + '      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                        + '          <wsse:UsernameToken>'
                        + '              <wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                        + '               <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' + IntSetup."E-Invoice Web Service Password" + '</wsse:Password>'
                        + '            </wsse:UsernameToken>'
                        + '        </wsse:Security>'
                        + '    </soapenv:Header>'
                        + '<soapenv:Body>'
                        + '<tem:GetEInvoiceUsers>'
                        + '<tem:pagination PageIndex="' + format(i) + '" PageSize="1000"/>'
                        + '</tem:GetEInvoiceUsers>'
                        + '</soapenv:Body>'
                        + '</soapenv:Envelope>';

            InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
            HeaderContent.Add('SOAPAction', 'http://tempuri.org/IIntegration/GetEInvoiceUsers');
            IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
                Error(Text001);

            Response.Content.ReadAs(ResponseText);

            Xmlbuffer.Reset();
            Xmlbuffer.DeleteAll();
            IF TryLoadUserXml(ResponseText, Xmlbuffer) then begin
                Xmlbuffer.reset();
                Xmlbuffer.SetRange(Type, Xmlbuffer.Type::Element);
                Xmlbuffer.SetRange(Name, 'Items');
                IF Xmlbuffer.FindFirst() then
                    repeat
                        EntryNo := EntryNo + 1;

                        InitAllUsers(EntryNo,
                            XmlBuffer.GetAttributeValueAsText('Identifier'),
                            XmlBuffer.GetAttributeValueAsText('PostboxAlias'),
                            XmlBuffer.GetAttributeValueAsText('Title'),
                            XmlBuffer.GetAttributeValueAsText('Type'),
                            XmlBuffer.GetAttributeValueAsText('FirstCreateDate'));
                    until Xmlbuffer.Next() = 0;
            end;

            IF EntryNo MOD 5000 = 0 THEN
                Commit();

        end;
    end;

    procedure PDFPriview(EntryNo: Integer)
    var
        Queue: Record "PRG_E-Invoice Queue";
        EInvMgt: Codeunit "PRG_E-Invoice Management";
        Convert: Codeunit "Base64 Convert";
        Tempblob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        UBLMgt: Codeunit "PRG_E-Invoice UBL Management";
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        RequestHeaders: HttpHeaders;
        ContentHeaders: HttpHeaders;
        JsonObject: JsonObject;
        JObj: JsonObject;
        ResponseTxt: Text;
        IsSuccessful: Boolean;
        Client: HttpClient;
        ContentTxt: Text;
        RequestUrl: Text;
        OStr: OutStream;
        IStr: InStream;
        pXMLdoc: XmlDocument;
        base64XML: Text;
        txtXSLT: Text;
        base64XSLT: Text;
        token: Text;
        ErrInfo: ErrorInfo;

    begin
        IF not Queue.Get(EntryNo) then
            exit;

        GetEInvSetup();

        token := GetPDFToken();
        pXMLdoc := UBLMgt.CreateOutgoingXML(Queue, true);
        base64XML := Convert.ToBase64(Format(pXMLdoc), TextEncoding::UTF8);

        case Queue.IntegrationType of
            Queue.IntegrationType::EInvoice:
                begin
                    EInvSetup.CalcFields("XSLT File");
                    IF not EInvSetup."XSLT File".HasValue then begin
                        ErrInfo.Title(Text012);
                        ErrInfo.Message(Text015);
                        ErrInfo.AddAction(Text013, CODEUNIT::"PRG_E-Invoice WB Connector", 'UploadEInvoiceXSLT');
                        ErrInfo.Verbosity(Verbosity::Normal);
                        Error(ErrInfo);
                    end;
                    EInvSetup."XSLT File".CreateInStream(IStr, TextEncoding::UTF8);
                    IStr.Read(txtXSLT);
                    base64XSLT := Convert.ToBase64(txtXSLT, TextEncoding::UTF8);
                end;
            Queue.IntegrationType::EArchive:
                begin
                    EInvSetup.CalcFields("E-Archive XSLT File");
                    IF not EInvSetup."E-Archive XSLT File".HasValue then begin
                        ErrInfo.Title(Text012);
                        ErrInfo.Message(Text015);
                        ErrInfo.AddAction(Text014, CODEUNIT::"PRG_E-Invoice WB Connector", 'UploadArchiveXSLT');
                        Error(ErrInfo);
                    end;
                    EInvSetup."E-Archive XSLT File".CreateInStream(IStr, TextEncoding::UTF8);
                    IStr.Read(txtXSLT);
                    base64XSLT := Convert.ToBase64(txtXSLT, TextEncoding::UTF8);
                end;
        end;

        RequestUrl := 'https://pargeapi.erp365.com.tr/XML/GetPDF';
        Request.Method := 'POST';
        Request.SetRequestUri(RequestUrl);
        RequestHeaders := Client.DefaultRequestHeaders();
        RequestHeaders.Add('Authorization', 'Bearer ' + GetPDFToken());
        Content.WriteFrom(StrSubstNo('{"Xml": "%1", "Xslt": "%2"}', base64XML, base64XSLT));
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');
        Request.Content := Content;
        IsSuccessful := Client.Send(Request, Response);
        Response.Content.ReadAs(ResponseTxt);
        if not Response.IsSuccessStatusCode() then
            Error(Format(Response.HttpStatusCode()) + ' - ' + Response.ReasonPhrase + ' - ' + Format(Response.Headers));

        Tempblob.CreateOutStream(OStr, TextEncoding::UTF8);
        Convert.FromBase64(ResponseTxt, OStr);
        Tempblob.CreateInStream(IStr, TextEncoding::UTF8);
        FileMgt.BLOBExportWithEncoding(Tempblob, Queue.UniqueIdentifier + '.pdf', true, TextEncoding::UTF8);
    end;

    local procedure GetPDFToken(): Text
    var
        Result: Text;
        IsSuccessful: Boolean;
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        RequestHeaders: HttpHeaders;
        ContentHeaders: HttpHeaders;
        JsonObject: JsonObject;
        ContentTxt: Text;
        RequestUrl: Text;
        JObj: JsonObject;
        JToken: JsonToken;
        token: Text;
    begin
        RequestUrl := 'https://pargeapi.erp365.com.tr/Auth/LoginUser';
        Request.Method := 'POST';
        Request.SetRequestUri(RequestUrl);
        RequestHeaders := Client.DefaultRequestHeaders();
        Content.WriteFrom(StrSubstNo('{"username": "%1", "password": "%2"}', 'PargesoftApiUser', 'uQA2ckR4HSDfC3nKJ8hNjr'));
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');
        Request.Content := Content;
        IsSuccessful := Client.Send(Request, Response);
        Response.Content.ReadAs(Result);
        JObj.ReadFrom(Result);
        JObj.SelectToken('token', JToken);
        exit(JToken.AsValue().AsText());
    end;

    procedure UploadEInvoiceXSLT(ErrInfo: ErrorInfo): Text
    var
        FilePath: Text;
        Instr: InStream;
        Outstr: OutStream;
    begin
        GetEInvSetup();

        if UploadIntoStream('Select File...', '', '', FilePath, Instr) then begin
            EInvSetup."XSLT File".CreateOutStream(OutStr);
            CopyStream(OutStr, Instr);
            EInvSetup.Modify(true);
            exit(Text016);
        end;
    end;

    procedure UploadArchiveXSLT(ErrInfo: ErrorInfo): Text
    var
        FilePath: Text;
        Instr: InStream;
        Outstr: OutStream;
    begin
        if UploadIntoStream('Select File...', '', '', FilePath, Instr) then begin
            EInvSetup."E-Archive XSLT File".CreateOutStream(OutStr);
            CopyStream(OutStr, Instr);
            EInvSetup.Modify(true);
            exit(Text016);
        end;
    end;

    procedure GetSingleCustomer(var Cust: Record Customer)
    var
        LiableComps: Record "PRG_E-Invoice Liable Companies";
        EInvSetup: Record "PRG_E-Invoice Setup";
    begin
        EInvSetup.Get();

        LiableComps.Reset();
        LiableComps.SetRange(Identifier, Cust."VAT Registration No.");
        if LiableComps.FindFirst() then begin
            if not Cust."PRG_Locked Alias" then begin
                Cust.PRG_Alias := LiableComps.Alias;
                Cust."PRG_Profile ID" := EInvSetup."Default ProfileID";
                if Cust.Modify() then;
            end;
        end else begin
            if not Cust."PRG_Locked Alias" then begin
                Cust.PRG_Alias := '';
                Cust."PRG_Profile ID" := Cust."PRG_Profile ID"::" ";
                if Cust.Modify() then;
            end;
        end;
    end;

    procedure GetSingleVendor(var Vend: Record Vendor)
    var
        LiableComps: Record "PRG_E-Invoice Liable Companies";
        EInvSetup: Record "PRG_E-Invoice Setup";
    begin
        EInvSetup.Get();

        LiableComps.Reset();
        LiableComps.SetRange(Identifier, Vend."VAT Registration No.");
        if LiableComps.FindFirst() then begin
            if not Vend."PRG_Locked Alias" then begin
                Vend.PRG_Alias := LiableComps.Alias;
                Vend."PRG_Profile ID" := EInvSetup."Default ProfileID";
                Vend.Modify();
            end;
        end else begin
            if not Vend."PRG_Locked Alias" then begin
                Vend.PRG_Alias := '';
                Vend."PRG_Profile ID" := Vend."PRG_Profile ID"::" ";
                Vend.Modify();
            end;
        end;
    end;

    local procedure GetTotalPages(startDT: DateTime; endDT: DateTime): Integer
    var
        Xmlbuffer: Record "XML Buffer" temporary;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        TotalPages: Integer;
        ResponseText: Text;
        varSoapTxt: Text;
        i: Integer;
    begin

        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">' +
                      '   <soapenv:Header>' +
                      '      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">' +
                      '         <wsse:UsernameToken>' +
                      '            <wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>' +
                      '            <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' + IntSetup."E-Invoice Web Service Password" + '</wsse:Password>' +
                      '         </wsse:UsernameToken>' +
                      '      </wsse:Security>' +
                      '   </soapenv:Header>' +
                      '   <soapenv:Body>' +
                      '      <tem:FilterEInvoiceUsers>' +
                      '         <tem:context PageIndex="' + format(i) + '" PageSize="1000">' +
                      '            <tem:SystemCreateDateBegin>' + Library.FormatDateTimeToISO(startDT) + '</tem:SystemCreateDateBegin>' +
                      '            <tem:SystemCreateDateEnd>' + Library.FormatDateTimeToISO(endDT) + '</tem:SystemCreateDateEnd>' +
                      '         </tem:context>' +
                      '      </tem:FilterEInvoiceUsers>' +
                      '   </soapenv:Body>' +
                      '</soapenv:Envelope>';

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('SOAPAction', 'http://tempuri.org/IIntegration/FilterEInvoiceUsers');

        if not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(ResponseText);
        Xmlbuffer.LoadFromText(ResponseText);
        FindXmlValue(Xmlbuffer, 2, 'TotalPages');
        Evaluate(TotalPages, Xmlbuffer.Value);
        exit(TotalPages);
    end;

    procedure QueryUpdateEInvoiceList()
    var
        EndDT: DateTime;
        varSoapTxt: Text;
        TotalPages: Integer;
        i: Integer;
        ResponseText: Text;
        EntryNo: Integer;
        LiableCompanies: Record "PRG_E-Invoice Liable Companies";
        LiableCompanies2: Record "PRG_E-Invoice Liable Companies";
        Xmlbuffer: Record "XML Buffer" temporary;
        Xmlbuffer2: Record "XML Buffer" temporary;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        CommitCounter: Integer;
    begin
        GetEInvSetup();
        GetSetup();
        EndDT := CurrentDateTime;

        if EInvSetup."Last Updated E-Inv. User List" = 0DT then begin
            IF GuiAllowed then begin
                Window.Open(Text005 + Text006 + Text007 + Text008);
                Window.Update(1, Text010);
            end;

            TotalPages := GetTotalPages();

            if GuiAllowed then
                Window.Update(2, TotalPages);

            ReadUserList(TotalPages, EndDT);

            EInvSetup."Last Updated E-Inv. User List" := EndDT;
            EInvSetup.Modify(true);
            exit;
        end;

        TotalPages := GetTotalPages(EInvSetup."Last Updated E-Inv. User List", EndDT);

        if LiableCompanies.FindLast() then
            EntryNo := LiableCompanies."Entry No.";

        for i := 1 to TotalPages do begin

            Clear(ResponseText);
            Clear(varSoapTxt);
            clear(Client);
            clear(Content);
            Clear(HeaderContent);
            Clear(Response);

            varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">' +
                          '   <soapenv:Header>' +
                          '      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">' +
                          '         <wsse:UsernameToken>' +
                          '            <wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>' +
                          '            <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' + IntSetup."E-Invoice Web Service Password" + '</wsse:Password>' +
                          '         </wsse:UsernameToken>' +
                          '      </wsse:Security>' +
                          '   </soapenv:Header>' +
                          '   <soapenv:Body>' +
                          '      <tem:FilterEInvoiceUsers>' +
                          '         <tem:context PageIndex="' + format(i) + '" PageSize="1000">' +
                          '            <tem:SystemCreateDateBegin>' + Library.FormatDateTimeToISO(EInvSetup."Last Updated E-Inv. User List") + '</tem:SystemCreateDateBegin>' +
                          '            <tem:SystemCreateDateEnd>' + Library.FormatDateTimeToISO(EndDT) + '</tem:SystemCreateDateEnd>' +
                          '         </tem:context>' +
                          '      </tem:FilterEInvoiceUsers>' +
                          '   </soapenv:Body>' +
                          '</soapenv:Envelope>';

            InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
            HeaderContent.Add('SOAPAction', 'http://tempuri.org/IIntegration/FilterEInvoiceUsers');
            if not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
                Error(Text001);

            Response.Content.ReadAs(ResponseText);

            Xmlbuffer.Reset();
            IF TryLoadUserXml(ResponseText, Xmlbuffer) then begin

                Xmlbuffer.reset();
                Xmlbuffer.SetRange(Type, Xmlbuffer.Type::Element);
                Xmlbuffer.SetRange(Name, 'Items');
                IF Xmlbuffer.FindFirst() then
                    repeat
                        EntryNo := EntryNo + 1;

                        LiableCompanies2.SetRange(Identifier, XmlBuffer.GetAttributeValueAsText('Identifier'));
                        LiableCompanies2.SetRange(Alias, XmlBuffer.GetAttributeValueAsText('PostboxAlias'));
                        if not LiableCompanies2.FindFirst() then
                            InitAllUsers(EntryNo,
                                XmlBuffer.GetAttributeValueAsText('Identifier'),
                                XmlBuffer.GetAttributeValueAsText('PostboxAlias'),
                                XmlBuffer.GetAttributeValueAsText('Title'),
                                XmlBuffer.GetAttributeValueAsText('Type'),
                                XmlBuffer.GetAttributeValueAsText('FirstCreateDate'));

                        CommitCounter += 1;
                    until Xmlbuffer.Next() = 0;

                IF CommitCounter MOD 5000 = 0 THEN
                    Commit();
            end;
        end;

        UpdateUserList(EndDT);
        EInvSetup."Last Updated E-Inv. User List" := EndDT;
        EInvSetup.Modify(true);

    end;

    procedure SendDocumentResponse(var Queue: Record "PRG_E-Invoice Queue"; Status: Enum "PRG_E-Invoice Approval Status"; StatusDescription: Text[250])
    var
        QueueLog: Record "PRG_E-Invoice Queue Log";
        XMLBuffer: Record "XML Buffer" temporary;
        EInvMgt: Codeunit "PRG_E-Invoice Management";
        varSoapText: Text;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        ResponseTxt: Text;
        ResponceCounter: Integer;
        UUID: Text;
        ApprovalStatus: Text;
    begin
        GetEInvSetup();
        GetSetup();

        EInvSetup.TestField(Activated);
        IntSetup.TestField("E-Invoice Integrator URL");
        IntSetup.TestField("E-Invoice Web Service UserName");
        IntSetup.TestField("E-Invoice Web Service Password");

        if Status = Status::Approved then
            ApprovalStatus := 'Approved'
        else
            ApprovalStatus := 'Declined';

        if Queue.FindSet() then
            repeat
                Clear(UUID);
                UUID := Format(Queue.UniqueIdentifier).TrimStart('{').TrimEnd('}').ToUpper();

                varSoapText := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                            + '   <soapenv:Header>'
                            + '      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                            + '         <wsse:UsernameToken>'
                            + '            <wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                            + '            <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' + IntSetup."E-Invoice Web Service Password" + '</wsse:Password>'
                            + '         </wsse:UsernameToken>'
                            + '      </wsse:Security>'
                            + '   </soapenv:Header>'
                            + '   <soapenv:Body>'
                            + '      <tem:SendDocumentResponse>'
                            + '         <tem:responses>'
                            + '            <tem:DocumentResponseInfo>'
                            + '               <tem:InvoiceId>' + UUID + '</tem:InvoiceId>'
                            + '               <tem:ResponseStatus>' + ApprovalStatus + '</tem:ResponseStatus>'
                            + '               <tem:Reason>' + StatusDescription + '</tem:Reason>'
                            + '            </tem:DocumentResponseInfo>'
                            + '         </tem:responses>'
                            + '      </tem:SendDocumentResponse>'
                            + '   </soapenv:Body>'
                            + '</soapenv:Envelope>';

                InitilazeClient(Client, Content, HeaderContent, varSoapText);
                HeaderContent.Add('SOAPAction', 'http://tempuri.org/IIntegration/SendDocumentResponse');
                if not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
                    Error(Text001);

                Response.Content.ReadAs(ResponseTxt);
                XMLBuffer.DeleteAll();
                XmlBuffer.LoadFromText(ResponseTxt);
                XmlBuffer.SetRange(Name, 'IsSucceded');
                if not XmlBuffer.FindFirst() then
                    Error(Text001);

                Queue."Approval Status" := Status;
                Queue.Modify();

                EInvMgt.InsertQueueLog(Queue.EntryNo, QueueLog.Status::SentToResponse, StrSubstNo(Text017, ApprovalStatus));

                Commit();

                ResponceCounter += 1;
            until Queue.Next() = 0;

        if ResponceCounter > 0 then
            Message(StrSubstNo(Text018, ResponceCounter));

    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInitilazeClient_SendInvoiceZip(var XmlDoc: XmlDocument; var UUID: GUID; var varSoapTxt: Text; var hashValue: Text; var stringType: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCustUpdate_UpdateserList(LiableComps: Record "PRG_E-Invoice Liable Companies"; var Cust: Record Customer; EInvSetup: Record "PRG_E-Invoice Setup")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeVendUpdate_UpdateserList(LiableComps: Record "PRG_E-Invoice Liable Companies"; var Vend: Record Vendor; EInvSetup: Record "PRG_E-Invoice Setup")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure FinishUpdateUserList(LiableComps: Record "PRG_E-Invoice Liable Companies"; var Cust: Record Customer; var Vend: Record Vendor; EInvSetup: Record "PRG_E-Invoice Setup")
    begin
    end;
}