codeunit 70093483 "PRG_E-Invoice Idea Connector"
{
    local procedure ClearUserListTables()
    var
        AllUsers: Record "PRG_E-Invoice Liable Companies";
    begin
        AllUsers.Reset();
        AllUsers.DeleteAll();
    end;

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
        AuthKeyString: Text;
        XDoc: XmlDocument;
        XNode: XmlNode;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        varSoapTxt: Text;
        MsgCode: Text;
        CustomerListText: text;
        Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        EInvWBConn: Codeunit "PRG_E-Invoice WB Connector";
        IStr: InStream;
        OStr: OutStream;
        StartDT: DateTime;
        XNodeList: XmlNodeList;
    begin
        StartDT := CurrentDateTime;

        GetAuthKey(AuthKeyString);
        Commit();

        GetSetup();

        varSoapTxt := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/">'
                      + ' <soap:Header/>'
                      + '  <soap:Body>'
                      + '      <tem:GetCustomerInfoList>'
                      + '          <tem:AuthKey>' + AuthKeyString + '</tem:AuthKey>'
                      + '      </tem:GetCustomerInfoList>'
                      + '  </soap:Body>'
                      + '  </soap:Envelope>';


        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('Content-Type', 'application/soap+xml;charset=UTF-8');
        HeaderContent.Add('Return-Type', 'application/soap+xml;charset=UTF-8');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);
        varSoapTxt := XMLDOMMgt.RemoveNamespaces(varSoapTxt);

        XmlDocument.ReadFrom(varSoapTxt, XDoc);
        XDoc.SelectSingleNode('/Envelope/Body/GetCustomerInfoListResponse/GetCustomerInfoListResult/MessageCode', XNode);
        MsgCode := XNode.AsXmlElement().InnerText;
        if MsgCode <> 'EI000001' then begin
            XDoc.SelectSingleNode('/Envelope/Body/GetCustomerInfoListResponse/GetCustomerInfoListResult/Message', XNode);
            Error(XNode.AsXmlElement().InnerText);
        end;

        XDoc.SelectSingleNode('/Envelope/Body/GetCustomerInfoListResponse/GetCustomerInfoListResult/CustomerList', XNode);
        CustomerListText := XNode.AsXmlElement().InnerText;
        Tempblob.CreateOutStream(OStr, TextEncoding::UTF8);
        Convert.FromBase64(CustomerListText, OStr);
        TempBlob.CreateInStream(IStr, TextEncoding::UTF8);
        ClearUserListTables();
        Commit();
        ImportUserListFromStream(IStr);
        EInvWBConn.UpdateUserList(StartDT);
    end;

    local procedure ImportUserListFromStream(ResponseInStream: InStream)
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
        ImportUserList: XmlPort "PRG_E-Invoice Import User List";
        FullFileName: text;
    begin
        DataCompression.OpenZipArchive(ResponseInStream, false);
        DataCompression.GetEntryList(EntryList);
        foreach EntryListKey in EntryList do begin
            ToFile := CopyStr(FileMgt.GetFileNameWithoutExtension(EntryListKey), 1, MaxStrLen(ToFile));
            FileExtension := CopyStr(FileMgt.GetExtension(EntryListKey), 1, MaxStrLen(FileExtension));
            TempBlob.CreateOutStream(EntryOutStream);
            DataCompression.ExtractEntry(EntryListKey, EntryOutStream);
            TempBlob.CreateInStream(UnzipInStream);
            FullFileName := ToFile + FileExtension;
            Clear(ImportUserList);
            ImportUserList.SetSource(UnzipInStream);
            ImportUserList.Import();
            exit;
        end;
    end;

    [TryFunction]
    procedure GetAuthKey(var AuthKey: Text);
    var
        XDoc: XmlDocument;
        XNode: XmlNode;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        varSoapTxt: Text;
        ResponseBodyXmlNode: XmlNode;
    begin
        GetSetup();
        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:aut="http://vpservice/authorization">'
                     + '  <soapenv:Header/>'
                     + '  <soapenv:Body>'
                     + '      <aut:GetAuthorizationKey>'
                     + '          <aut:UserName>' + IntSetup."E-Invoice Web Service UserName" + '</aut:UserName>'
                     + '          <aut:Password>' + IntSetup."E-Invoice Web Service Password" + '</aut:Password>'
                     + '      </aut:GetAuthorizationKey>'
                     + '  </soapenv:Body>'
                     + '  </soapenv:Envelope>';

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('Content-Type', 'text/xml;charset=UTF-8');
        HeaderContent.Add('Return-Type', 'text/xml;charset=UTF-8');
        HeaderContent.Add('SOAPAction', 'http://vpservice/authorization/GetAuthorizationKey');
        IF not Client.Post(IntSetup."E-Invoice Int. Auth. URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);

        varSoapTxt := XMLDOMMgt.RemoveNamespaces(varSoapTxt);
        XmlDocument.ReadFrom(varSoapTxt, XDoc);
        if not XDoc.SelectSingleNode('/Envelope/Body/GetAuthorizationKeyResponse/GetAuthorizationKeyResult', XNode) then
            Error('Authorization error. Please check credentials');
        AuthKey := XNode.AsXmlElement().InnerText;

    end;

    procedure InitilazeClient(var Client: HttpClient; var Content: HttpContent; var HeaderContent: HttpHeaders; RequestText: Text)
    begin
        Content.WriteFrom(RequestText);
        Content.GetHeaders(HeaderContent);
        RemoveHeader(HeaderContent, 'Content-Type');
        Client.SetBaseAddress(IntSetup."E-Invoice Integrator URL");
    end;

    procedure RemoveHeader(var HeaderContent: HttpHeaders; _Name: Text)
    begin
        HeaderContent.Remove(_Name);
    end;

    local procedure GetDateRange(var StartingDate: DateTime; var EndingDate: DateTime)
    begin
        EInvSetup.GET;
        StartingDate := CREATEDATETIME(CALCDATE('<-8D>', TODAY), 0T);
        EndingDate := CREATEDATETIME(CalcDate('<+1D>', Today), 235900T);
    end;

    procedure GetIncomingInvoices()
    var
        AuthKeyString: Text;
        XDoc: XmlDocument;
        XNode: XmlNode;
        XNodeList: XmlNodeList;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        varSoapTxt: Text;
        MsgCode: Text;
        CustomerListText: text;
        Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        IStr: InStream;
        OStr: OutStream;
        StartDateTime: DateTime;
        EndDateTime: DateTime;
        Counter: Integer;
        InvoiceNumber: Text;
        SenderIdentification: Text;
        IncomingUUID: Text;
        DetailNode: XmlNode;
        STDate: Text;
        EndDate: Text;
    begin
        GetAuthKey(AuthKeyString);
        GetDateRange(StartDateTime, EndDateTime);
        Commit();

        GetSetup();

        STDate := Library.FormatDateTimeToISO(StartDateTime);
        EndDate := Library.FormatDateTimeToISO(EndDateTime);

        varSoapTxt := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/">'
                      + ' <soap:Header/>'
                      + '  <soap:Body>'
                      + '      <tem:SearchInvoiceIncome>'
                      + '          <tem:AuthKey>' + AuthKeyString + '</tem:AuthKey>'
                      + '          <tem:BeginDate> ' + STDate + '</tem:BeginDate>'
                      + '          <tem:EndDate>' + EndDate + '</tem:EndDate>'
                      + '      </tem:SearchInvoiceIncome>'
                      + '  </soap:Body>'
                    + '  </soap:Envelope>';

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('Content-Type', 'application/soap+xml;charset=UTF-8');
        HeaderContent.Add('Return-Type', 'application/soap+xml;charset=UTF-8');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);
        varSoapTxt := XMLDOMMgt.RemoveNamespaces(varSoapTxt);
        XmlDocument.ReadFrom(varSoapTxt, XDoc);
        XDoc.SelectSingleNode('/Envelope/Body/SearchInvoiceIncomeResponse/SearchInvoiceIncomeResult/MessageCode', XNode);
        MsgCode := XNode.AsXmlElement().InnerText;
        if MsgCode <> 'EI000001' then begin
            XDoc.SelectSingleNode('/Envelope/Body/SearchInvoiceIncomeResponse/SearchInvoiceIncomeResult/Message', XNode);
            Error(XNode.AsXmlElement().InnerText);
        end;

        XDoc.SelectNodes('/Envelope/Body/SearchInvoiceIncomeResponse/SearchInvoiceIncomeResult/IncomeResults/EInvoiceIncomeDetail', XNodeList);
        for Counter := 0 to XNodeList.Count - 1 do begin
            Clear(XNode);
            XNodeList.Get(Counter + 1, XNode);
            XNode.SelectSingleNode('InvoiceNumber', DetailNode);
            InvoiceNumber := DetailNode.AsXmlElement().InnerText;
            XNode.SelectSingleNode('SenderIdentifier', DetailNode);
            SenderIdentification := DetailNode.AsXmlElement().InnerText;
            XNode.SelectSingleNode('Uuid', DetailNode);
            IncomingUUID := DetailNode.AsXmlElement().InnerText;
            IF NOT Library.IsAllReadyImported(IncomingUUID) then begin
                RetrieveSingleDocument(InvoiceNumber, SenderIdentification, IncomingUUID);
                Commit();
            end;
        end;
    end;

    local procedure RetrieveSingleDocument(InvoiceNumber: Text; SenderIdentification: Text; IncomingUUID: Text)
    var
        AuthKeyString: Text;
        XDoc: XmlDocument;
        XNode: XmlNode;
        XNodeList: XmlNodeList;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        varSoapTxt: Text;
        MsgCode: Text;
        SingleDocumentText: Text;
        Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        IStr: InStream;
        OStr: OutStream;
    begin
        GetAuthKey(AuthKeyString);
        GetSetup();

        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                    + '   <soapenv:Header/>'
                    + '   <soapenv:Body>'
                    + '      <tem:GetInvoiceIncome>'
                    + '         <tem:authKey>' + AuthKeyString + '</tem:authKey>'
                    + '         <tem:invoiceNumber>' + InvoiceNumber + '</tem:invoiceNumber>'
                    + '         <tem:senderIdentifier>' + SenderIdentification + '</tem:senderIdentifier>'
                    + '         <tem:uuid>' + IncomingUUID + '</tem:uuid>'
                    + '      </tem:GetInvoiceIncome>'
                    + '   </soapenv:Body>'
                    + '</soapenv:Envelope>';

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('Content-Type', 'text/xml;charset=UTF-8');
        HeaderContent.Add('Return-Type', 'text/xml;charset=UTF-8');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);
        varSoapTxt := XMLDOMMgt.RemoveNamespaces(varSoapTxt);
        XmlDocument.ReadFrom(varSoapTxt, XDoc);
        XDoc.SelectSingleNode('/Envelope/Body/GetInvoiceIncomeResponse/GetInvoiceIncomeResult/MessageCode', XNode);
        MsgCode := XNode.AsXmlElement().InnerText;
        if MsgCode <> 'EI000001' then begin
            XDoc.SelectSingleNode('/Envelope/Body/GetInvoiceIncomeResponse/GetInvoiceIncomeResult/Message', XNode);
            Error(XNode.AsXmlElement().InnerText);
        end;
        XDoc.SelectSingleNode('/Envelope/Body/GetInvoiceIncomeResponse/GetInvoiceIncomeResult/File', XNode);
        SingleDocumentText := XNode.AsXmlElement().InnerText;
        Tempblob.CreateOutStream(OStr, TextEncoding::UTF8);
        Convert.FromBase64(SingleDocumentText, OStr);
        TempBlob.CreateInStream(IStr, TextEncoding::UTF8);
        ExtractAndImportToQueue(IStr, IncomingUUID);
    end;

    local procedure ExtractAndImportToQueue(ResponseInStream: InStream; IncomingUUID: Text)
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
        FullFileName: text;
        IncomingBuffer: Record "PRG_E-Invoice Incoming Buffer";
        UblOstream: OutStream;
    begin
        IF IncomingBuffer.FindLast() then;

        IncomingBuffer.Init();
        IncomingBuffer."Entry No." := IncomingBuffer."Entry No." + 1;
        IncomingBuffer."Document ID" := IncomingUUID;
        IncomingBuffer."Invoice Value".CreateOutStream(UblOstream);
        DataCompression.OpenZipArchive(ResponseInStream, false);
        DataCompression.GetEntryList(EntryList);
        foreach EntryListKey in EntryList do begin
            DataCompression.ExtractEntry(EntryListKey, UblOstream);
        end;
        IncomingBuffer.Insert(true);
    end;

    procedure GetOutboxPDF(UUID: GUID)
    var
        AuthKeyString: Text;
        XDoc: XmlDocument;
        XNode: XmlNode;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        varSoapTxt: Text;
        CustomerListText: text;
        Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        IStr: InStream;
        OStr: OutStream;
        Queue: Record "PRG_E-Invoice Queue";
        FileName: Text;
        FileMgt: Codeunit "File Management";
    begin
        Queue.SetRange(Type, Queue.Type::Outbox);
        Queue.SetFilter(UniqueIdentifier, UUID);
        Queue.FindFirst();

        GetAuthKey(AuthKeyString);
        Commit();

        GetEInvSetup();
        GetSetup();

        varSoapTxt := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/">'
                      + ' <soap:Header/>'
                      + '  <soap:Body>'
                      + '      <tem:GetInvoiceStagingPDF>'
                      + '          <tem:AuthKey>' + AuthKeyString + '</tem:AuthKey>'
                      + '           <tem:InvoiceNumber>' + Queue.InvoiceID + '</tem:InvoiceNumber>'
                      + '           <tem:SenderIdentifier>' + EInvSetup."Supplier Tax Registration No." + '</tem:SenderIdentifier>'
                      + '      </tem:GetInvoiceStagingPDF>'
                      + '  </soap:Body>'
                    + '  </soap:Envelope>';

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('Content-Type', 'application/soap+xml;charset=UTF-8');
        HeaderContent.Add('Return-Type', 'application/soap+xml;charset=UTF-8');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);
        varSoapTxt := XMLDOMMgt.RemoveNamespaces(varSoapTxt);
        XmlDocument.ReadFrom(varSoapTxt, XDoc);
        XDoc.SelectSingleNode('/Envelope/Body/GetInvoiceStagingPDFResponse/GetInvoiceStagingPDFResult/isCompleted', XNode);
        if XNode.AsXmlElement().InnerText = 'true' then begin
            XDoc.SelectSingleNode('/Envelope/Body/GetInvoiceStagingPDFResponse/GetInvoiceStagingPDFResult/FileName', XNode);
            FileName := XNode.AsXmlElement().InnerText;
            XDoc.SelectSingleNode('/Envelope/Body/GetInvoiceStagingPDFResponse/GetInvoiceStagingPDFResult/File', XNode);
            varSoapTxt := XNode.AsXmlElement().InnerText;
            Tempblob.CreateOutStream(OStr, TextEncoding::UTF8);
            Convert.FromBase64(varSoapTxt, OStr);
            Tempblob.CreateInStream(IStr, TextEncoding::UTF8);
            FileMgt.BLOBExportWithEncoding(Tempblob, FileName, true, TextEncoding::UTF8);
        end else begin
            XDoc.SelectSingleNode('/Envelope/Body/GetInvoiceStagingPDFResponse/GetInvoiceStagingPDFResult/Message', XNode);
            Error(XNode.AsXmlElement().InnerText);
        end;

    end;

    procedure GetInboxPdf(UUID: GUID)
    var
        AuthKeyString: Text;
        XDoc: XmlDocument;
        XNode: XmlNode;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        varSoapTxt: Text;
        CustomerListText: text;
        Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        IStr: InStream;
        OStr: OutStream;
        Queue: Record "PRG_E-Invoice Queue";
        FileName: Text;
        FileMgt: Codeunit "File Management";
    begin
        Queue.SetRange(Type, Queue.Type::Inbox);
        Queue.SetFilter(UniqueIdentifier, UUID);
        Queue.FindFirst();

        GetAuthKey(AuthKeyString);
        Commit();

        GetSetup();

        varSoapTxt := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/">'
                      + ' <soap:Header/>'
                      + '  <soap:Body>'
                      + '      <tem:GetInvoiceIncomePDF>'
                      + '          <tem:AuthKey>' + AuthKeyString + '</tem:AuthKey>'
                      + '           <tem:InvoiceNumber>' + Queue.InvoiceID + '</tem:InvoiceNumber>'
                      + '           <tem:SenderIdentifier>' + Queue.CVRegistrationNo + '</tem:SenderIdentifier>'
                      + '      </tem:GetInvoiceIncomePDF>'
                      + '  </soap:Body>'
                    + '  </soap:Envelope>';

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('Content-Type', 'application/soap+xml;charset=UTF-8');
        HeaderContent.Add('Return-Type', 'application/soap+xml;charset=UTF-8');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);
        varSoapTxt := XMLDOMMgt.RemoveNamespaces(varSoapTxt);
        XmlDocument.ReadFrom(varSoapTxt, XDoc);
        XDoc.SelectSingleNode('/Envelope/Body/GetInvoiceIncomePDFResponse/GetInvoiceIncomePDFResult/isCompleted', XNode);
        if XNode.AsXmlElement().InnerText = 'true' then begin
            XDoc.SelectSingleNode('/Envelope/Body/GetInvoiceIncomePDFResponse/GetInvoiceIncomePDFResult/FileName', XNode);
            FileName := XNode.AsXmlElement().InnerText;
            XDoc.SelectSingleNode('/Envelope/Body/GetInvoiceIncomePDFResponse/GetInvoiceIncomePDFResult/File', XNode);
            varSoapTxt := XNode.AsXmlElement().InnerText;
            Tempblob.CreateOutStream(OStr, TextEncoding::UTF8);
            Convert.FromBase64(varSoapTxt, OStr);
            Tempblob.CreateInStream(IStr, TextEncoding::UTF8);
            FileMgt.BLOBExportWithEncoding(Tempblob, FileName, true, TextEncoding::UTF8);
        end else begin
            XDoc.SelectSingleNode('/Envelope/Body/GetInvoiceIncomePDFResponse/GetInvoiceIncomePDFResult/Message', XNode);
            Error(XNode.AsXmlElement().InnerText);
        end;
    end;

    procedure SendInvoiceZip(XmlDoc: XmlDocument; UUID: GUID)
    var
        Queue: Record "PRG_E-Invoice Queue";
        Convert: Codeunit "Base64 Convert";
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
        stringType: Text;
        varSoapTxt: Text;
        EInvHeader: Record "PRG_E-Invoice Header";
        AuthKeyString: Text;
        XDoc: XmlDocument;
        MsgCode: Text;
        XNode: XmlNode;
    begin
        GetSetup();
        IntSetup.TestField("E-Invoice Integration Type");
        IntSetup.TestField(IntSetup."E-Invoice Integration Version");
        IntSetup.TestField(IntSetup."E-Invoice Active Company");
        IntSetup.TestField(IntSetup."E-Invoice Active Branch");

        GetAuthKey(AuthKeyString);
        Commit();

        EInvHeader.SetRange(UUID, UUID);
        EInvHeader.FindFirst();

        XmlDoc.WriteTo(varSoapTxt);

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
        varSoapTxt := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/">'
                      + '<soap:Header/>'
                      + '<soap:Body>'
                      + '   <tem:ConvertToUblAndSave>'
                      + '      <tem:AuthKey>' + AuthKeyString + '</tem:AuthKey>'
                      + '      <tem:ZippedSourceFile>' + stringType + '</tem:ZippedSourceFile>'
                      + '      <tem:IntegrationType>' + IntSetup."E-Invoice Integration Type" + '</tem:IntegrationType>'
                      + '      <tem:IntegrationVersion>' + IntSetup."E-Invoice Integration Version" + '</tem:IntegrationVersion>'
                      + '      <tem:ActiveCompany>' + IntSetup."E-Invoice Active Company" + '</tem:ActiveCompany>'
                      + '      <tem:ActiveBranch>' + IntSetup."E-Invoice Active Branch" + '</tem:ActiveBranch>'
                      + '      <tem:StagingRecordType></tem:StagingRecordType>'
                      + '   </tem:ConvertToUblAndSave>'
                      + '</soap:Body>'
                      + '</soap:Envelope>';


        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('Content-Type', 'application/soap+xml;charset=UTF-8');
        HeaderContent.Add('Return-Type', 'application/soap+xml;charset=UTF-8');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);
        varSoapTxt := XMLDOMMgt.RemoveNamespaces(varSoapTxt);
        XmlDocument.ReadFrom(varSoapTxt, XDoc);
        XDoc.SelectSingleNode('/Envelope/Body/ConvertToUblAndSaveResponse/ConvertToUblAndSaveResult/MessageCode', XNode);
        MsgCode := XNode.AsXmlElement().InnerText;
        if MsgCode <> 'EI000001' then begin
            XDoc.SelectSingleNode('/Envelope/Body/ConvertToUblAndSaveResponse/ConvertToUblAndSaveResult/ExceptionMessage', XNode);
            Error(XNode.AsXmlElement().InnerText);
        end;

        XDoc.SelectSingleNode('/Envelope/Body/ConvertToUblAndSaveResponse/ConvertToUblAndSaveResult/isCompleted', XNode);
        Queue.SetRange(Type, Queue.Type::Outbox);
        Queue.SetFilter(UniqueIdentifier, UUID);
        Queue.FindFirst();
        if XNode.AsXmlElement().InnerText = 'true' then begin
            Queue.ResultStatusCode := '1000';
            Queue.ResultStatusDescription := 'Kuyruğa Eklendi';
            Queue.Modify();
            exit;
        end;

        XDoc.SelectSingleNode('/Envelope/Body/ConvertToUblAndSaveResponse/ConvertToUblAndSaveResult/ExceptionMessage', XNode);
        varSoapTxt := XNode.AsXmlElement().InnerText;
        XDoc.SelectSingleNode('/Envelope/Body/ConvertToUblAndSaveResponse/ConvertToUblAndSaveResult/Message', XNode);
        varSoapTxt := varSoapTxt + XNode.AsXmlElement().InnerText;
        Queue.ResultStatusCode := '9999';
        Queue.ResultStatusDescription := CopyStr(varSoapTxt, 1, MaxStrLen(Queue.ResultStatusDescription));
        Queue.Modify();
    end;

    procedure GetOutboxStatus(var Queue: Record "PRG_E-Invoice Queue")
    var
        stringType: Text;
        varSoapTxt: Text;
        AuthKeyString: Text;
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        XDoc: XmlDocument;
        XNode: XmlNode;
    begin
        GetSetup();
        IntSetup.TestField("E-Invoice Integration Type");
        IntSetup.TestField(IntSetup."E-Invoice Integration Version");
        IntSetup.TestField(IntSetup."E-Invoice Active Company");
        IntSetup.TestField(IntSetup."E-Invoice Active Branch");

        GetAuthKey(AuthKeyString);
        Commit();

        varSoapTxt := '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/">'
                      + ' <soap:Header/>'
                      + '  <soap:Body>'
                      + '      <tem:GetStatusHistoryByInvoiceNumber>'
                      + '           <tem:AuthKey>' + AuthKeyString + '</tem:AuthKey>'
                      + '           <tem:ActiveCompany>' + IntSetup."E-Invoice Active Company" + '</tem:ActiveCompany>'
                      + '           <tem:ActiveBranch>' + IntSetup."E-Invoice Active Branch" + '</tem:ActiveBranch>'
                      + '           <tem:InvoiceNumber>' + Queue.InvoiceID + '</tem:InvoiceNumber>'
                      + '      </tem:GetStatusHistoryByInvoiceNumber>'
                      + '  </soap:Body>'
                      + '  </soap:Envelope>';

        InitilazeClient(Client, Content, HeaderContent, varSoapTxt);
        HeaderContent.Add('Content-Type', 'application/soap+xml;charset=UTF-8');
        HeaderContent.Add('Return-Type', 'application/soap+xml;charset=UTF-8');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Error(Text001);

        Response.Content.ReadAs(varSoapTxt);
        varSoapTxt := XMLDOMMgt.RemoveNamespaces(varSoapTxt);
        XmlDocument.ReadFrom(varSoapTxt, XDoc);

        XDoc.SelectSingleNode('/Envelope/Body/GetStatusHistoryByInvoiceNumberResponse/GetStatusHistoryByInvoiceNumberResult/StagingLogs/EInvoiceStagingLogResult/ToStatus', XNode);
        Queue.ResultStatusCode := CopyStr(XNode.AsXmlElement().InnerText, 1, MaxStrLen(Queue.ResultStatusCode));
        XDoc.SelectSingleNode('/Envelope/Body/GetStatusHistoryByInvoiceNumberResponse/GetStatusHistoryByInvoiceNumberResult/StagingLogs/EInvoiceStagingLogResult/StatusDesc', XNode);
        Queue.ResultStatusDescription := CopyStr(XNode.AsXmlElement().InnerText, 1, MaxStrLen(Queue.ResultStatusDescription));
    end;

    var
        IntSetup: Record "PRG_E-Invoice Integrator Setup";
        EInvSetup: Record "PRG_E-Invoice Setup";
        Library: Codeunit "PRG_E-Invoice Library";
        XMLDOMMgt: Codeunit "XML DOM Management";
        GotEInvSetup: Boolean;
        GotSetup: Boolean;
        Text001: Label 'Connection problem. Please check in with system administrator';
        XPath_Body: Label '/s:Envelope/s:Body', Locked = true;
        Prefix_Soap: Label 'aut', Locked = true;
        Namespace_Soap: label 'http://schemas.xmlsoap.org/soap/envelope/', Locked = true;
}