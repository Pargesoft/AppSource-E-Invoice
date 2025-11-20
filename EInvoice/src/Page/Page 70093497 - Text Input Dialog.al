page 70093497 "PRG_Text Input Dialog"
{
    PageType = StandardDialog;
    Caption = 'Enter a Value';

    layout
    {
        area(content)
        {
            field(Answer; Answer)
            {
                ApplicationArea = All;
                Caption = 'Your Answer';
            }
        }
    }

    var
        Answer: Text[250];

    procedure GetText(): Text
    begin
        exit(Answer);
    end;
}