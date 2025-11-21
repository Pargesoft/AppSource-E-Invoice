report 70093473 "PRG_Create E-Inv. No. Series"
{
    Caption = 'Create E-Invoice No. Series';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(StartingDate; StartingDate)
                {
                    ApplicationArea = All;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the value of the Starting Date field.';
                }
                field(EndingDate; EndingDate)
                {
                    ApplicationArea = All;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the value of the Ending Date field.';
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = All;
                    Caption = 'Period Type';
                    OptionCaption = ' ,Day,Month,Year';
                    ToolTip = 'Specifies the value of the Period Type field.';
                }
                field(Prefix; Prefix)
                {
                    ApplicationArea = All;
                    Caption = 'Prefix';
                    ToolTip = 'Specifies the value of the Prefix field.';
                }
                field(GlobNoSeriesCode; GlobNoSeriesCode)
                {
                    ApplicationArea = All;
                    Caption = 'Code To Create';
                    ToolTip = 'Specifies the value of the Code To Create field.';
                }
                field(CreationType; CreationType)
                {
                    ApplicationArea = All;
                    Caption = 'Creation Type';
                    OptionCaption = 'E-Invoice,E-Archive';
                    ToolTip = 'Specifies the value of the Creation Type field.';
                }
                field(UpdateSetup; UpdateSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Update Setup';
                    ToolTip = 'Specifies the value of the Update Setup field.';

                    trigger OnValidate()
                    begin
                        if UpdateSetup then
                            if not Confirm(Text010) then
                                Error('');
                    end;
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Message(Text005);
    end;

    trigger OnPreReport()
    begin
        if StartingDate = 0D then
            Error(Text003);

        if EndingDate = 0D then
            Error(Text004);

        if Prefix = '' then
            Error(Text006);

        if GlobNoSeriesCode = '' then
            Error(Text007);

        EInvSetup.Get();
        if UpdateSetup then
            EInvSetup.LockTable();

        SetNoSeries();
    end;

    var
        NoSeriesLine: Record "No. Series Line";
        EInvSetup: Record "PRG_E-Invoice Setup";
        UpdateSetup: Boolean;
        GlobNoSeriesCode: Code[10];
        EndingDate: Date;
        StartingDate: Date;
        InitValueText: Label '00001';
        Text003: Label 'Start Date must be specified!';
        Text004: Label 'End Date must be specified!';
        Text005: Label 'Creation Completed';
        Text006: Label 'Prefix can''t be empty';
        Text007: Label 'Code To Create can''t be empty';
        Text008: Label '%1 is allready registered at %2';
        Text010: Label 'Do you want to update setup?';
        PeriodType: Option " ",Day,Month,Year;
        CreationType: Option EInvoice,Earchive;
        Prefix: Text[3];

    procedure CheckNoSeries()
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(GlobNoSeriesCode) then
            Error(Text008, GlobNoSeriesCode, NoSeries.TableCaption);
    end;

    procedure CreateNoSeriesLines()
    var
        DateTable: Record Date;
    begin
        case PeriodType of
            PeriodType::Day:
                begin
                    DateTable.SetRange("Period Type", DateTable."Period Type"::Date);
                    DateTable.SetFilter("Period Start", '%1..', StartingDate);
                    DateTable.SetFilter("Period End", '..%1', EndingDate);
                    if DateTable.FindSet() then
                        repeat
                            InsertNoSeries(GlobNoSeriesCode, DateTable."Period Start");
                        until DateTable.Next() = 0;
                end;

            PeriodType::Month:
                begin
                    DateTable.SetRange("Period Type", DateTable."Period Type"::Month);
                    DateTable.SetFilter("Period Start", '%1..', StartingDate);
                    DateTable.SetFilter("Period End", '..%1', EndingDate);
                    if DateTable.FindSet() then
                        repeat
                            InsertNoSeries(GlobNoSeriesCode, DateTable."Period Start");
                        until DateTable.Next() = 0;
                end;

            PeriodType::Year:
                begin
                    DateTable.SetRange("Period Type", DateTable."Period Type"::Year);
                    DateTable.SetFilter("Period Start", '%1..', StartingDate);
                    DateTable.SetFilter("Period End", '..%1', EndingDate);
                    if DateTable.FindSet() then
                        repeat
                            InsertNoSeries(GlobNoSeriesCode, DateTable."Period Start");
                        until DateTable.Next() = 0;
                end;
            else
                Error('');
        end;
    end;

    procedure InsertNoSeries(SeriesCode: Code[10]; LineStartingDate: Date)
    begin
        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := SeriesCode;
        NoSeriesLine."Line No." := NoSeriesLine."Line No." + 10000;
        NoSeriesLine."Starting Date" := LineStartingDate;
        NoSeriesLine."Starting No." := Prefix + Format(LineStartingDate, 0, '<Year4><Month,2><Day,2>') + InitValueText;
        NoSeriesLine.Open := true;
        NoSeriesLine.Insert();
    end;

    procedure SetNoSeries()
    begin
        CheckNoSeries();
        CreateNoSeriesHeader();
        CreateNoSeriesLines();
        UpdateEInvSetup();
    end;

    local procedure CreateNoSeriesHeader()
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Init();
        NoSeries.Code := UpperCase(GlobNoSeriesCode);//Just in case
        NoSeries.Description := GlobNoSeriesCode;
        NoSeries."Default Nos." := true;
        NoSeries.Insert(true);
    end;

    local procedure UpdateEInvSetup()
    begin
        case CreationType of
            CreationType::EInvoice:
                begin
                    EInvSetup."E-Invoice No. Series" := GlobNoSeriesCode;
                    EInvSetup.Modify();
                end;
            CreationType::Earchive:
                begin
                    EInvSetup."E-Archive No. Series" := GlobNoSeriesCode;
                    EInvSetup.Modify();
                end;
        end;
    end;
}

