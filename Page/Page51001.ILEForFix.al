page 51001 "ILE For Fix"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "Item Ledger Entry";
    SourceTableView = sorting("Item No.", "Lot No.") where(Open = filter(true), Positive = filter(true));


    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                ShowCaption = false;
                field("Item No. Filter"; ItemNoFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        if ItemNoFilter <> '' then
                            Rec.SetFilter("Item No.", ItemNoFilter)
                        else
                            Rec.SetRange("Item No.");
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(EntryList)
            {
                Editable = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    ApplicationArea = All;
                }
                field(SystemModifiedAt; Rec.SystemModifiedAt)
                {
                    ApplicationArea = All;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = All;
                    StyleExpr = ILE_StyleTxt;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = All;
                    StyleExpr = ILE_StyleTxt;
                }
                field("Quantity"; Rec."Quantity")
                {
                    ApplicationArea = All;
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = All;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = All;
                }
                field("Item Ledger Entry Sum Qty"; Sum_Qty_By_Lot)
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    var
                        locILE: Record "Item Ledger Entry";
                    begin
                        SetILEFilter(locILE);
                        Page.Run(Page::"Item Ledger Entries", locILE);
                    end;
                }
                field("Item Ledger Entry Sum Remaining Qty"; Sum_Rem_Qty_By_Lot)
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    var
                        locILE: Record "Item Ledger Entry";
                    begin
                        SetILEFilter(locILE);
                        SetILERemFilter(locILE);
                        Page.Run(Page::"Item Ledger Entries", locILE);
                    end;
                }
                field("Whse. Entry Sum Qty"; WE_Sum_Qty)
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    var
                        locWE: Record "Warehouse Entry";
                    begin
                        SetWEFilter(locWE);
                        Page.Run(Page::"Warehouse Entries", locWE);
                    end;
                }
                field("Delta Item Ledger Entry Sum Qty"; Delta_Sum_Qty)
                {
                    ApplicationArea = All;
                    StyleExpr = ILE_StyleTxt;
                }
                field("Delta Item Ledger Entry vs Whse Entry"; Delta_ILE_WE)
                {
                    ApplicationArea = All;
                    StyleExpr = ILE_WE_StyleTxt;
                }
            }
        }
    }


    actions
    {
        area(Processing)
        {
            action(ActionName)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin

                end;
            }
        }
    }



    trigger OnFindRecord(Which: Text): Boolean
    var
        NextRecNotFound: Boolean;
    begin
        if not Rec.Find(Which) then
            exit(false);

        if ShowRecord() then
            exit(true);

        repeat
            NextRecNotFound := Rec.Next <= 0;
            if ShowRecord() then
                exit(true);
        until NextRecNotFound;

        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        NewStepCount: Integer;
    begin
        repeat
            NewStepCount := Rec.Next(Steps);
        until (NewStepCount = 0) or ShowRecord();

        exit(NewStepCount);
    end;

    var
        ItemNoFilter: Code[100];
        Sum_Qty_By_Lot: Decimal;
        Sum_Rem_Qty_By_Lot: Decimal;
        Delta_Sum_Qty: Decimal;
        WE_Sum_Qty: Decimal;
        Delta_ILE_WE: Decimal;
        ILE_WE_StyleTxt: Text;
        ILE_StyleTxt: Text;

    local procedure ShowRecord(): Boolean
    begin
        CalcSumsQty();
        exit((Rec.Quantity <> Rec."Remaining Quantity") and (Delta_ILE_WE <> 0));
    end;

    local procedure CalcSumsQty()
    var
        locWE: Record "Warehouse Entry";
    begin
        CalcILESums();
        CalcWESums();

        Delta_ILE_WE := Sum_Rem_Qty_By_Lot - WE_Sum_Qty;
        ILE_StyleTxt := SetStyle(Delta_Sum_Qty);
        ILE_WE_StyleTxt := SetStyle(Delta_ILE_WE);
    end;

    local procedure CalcILESums()
    var
        locILE: Record "Item Ledger Entry";
    begin
        locILE.SetCurrentKey("Item No.", "Lot No.", "Location Code");
        locILE.SetRange("Item No.", Rec."Item No.");
        locILE.SetRange("Lot No.", Rec."Lot No.");
        locILE.SetRange("Variant Code", Rec."Variant Code");
        locILE.SetRange("Location Code", Rec."Location Code");
        locILE.CalcSums(Quantity, "Remaining Quantity");
        Sum_Qty_By_Lot := locILE.Quantity;
        Sum_Rem_Qty_By_Lot := locILE."Remaining Quantity";
        Delta_Sum_Qty := Sum_Qty_By_Lot - Sum_Rem_Qty_By_Lot;
    end;

    local procedure SetILEFilter(var locILE: Record "Item Ledger Entry")
    begin
        locILE.SetCurrentKey("Item No.", "Lot No.", "Location Code");
        locILE.SetRange("Item No.", Rec."Item No.");
        locILE.SetRange("Lot No.", Rec."Lot No.");
        locILE.SetRange("Variant Code", Rec."Variant Code");
        locILE.SetRange("Location Code", Rec."Location Code");
    end;

    local procedure SetILERemFilter(var locILE: Record "Item Ledger Entry")
    begin
        locILE.SetCurrentKey("Item No.", "Lot No.", "Location Code", Open);
        locILE.SetRange(Open, true);
    end;

    local procedure CalcWESums()
    var
        locWE: Record "Warehouse Entry";
    begin
        locWE.SetCurrentKey("Item No.", "Lot No.", "Location Code");
        locWE.SetRange("Item No.", Rec."Item No.");
        locWE.SetRange("Lot No.", Rec."Lot No.");
        locWE.SetRange("Variant Code", Rec."Variant Code");
        locWE.SetRange("Location Code", Rec."Location Code");
        locWE.CalcSums("Qty. (Base)");
        WE_Sum_Qty := locWE."Qty. (Base)";
    end;

    local procedure SetWEFilter(var locWE: Record "Warehouse Entry")
    begin
        locWE.SetCurrentKey("Item No.", "Lot No.", "Location Code");
        locWE.SetRange("Item No.", Rec."Item No.");
        locWE.SetRange("Lot No.", Rec."Lot No.");
        locWE.SetRange("Variant Code", Rec."Variant Code");
        locWE.SetRange("Location Code", Rec."Location Code");
    end;

    procedure SetStyle(xDecimal: Decimal) Style: Text
    begin
        if xDecimal < 0 then
            exit('Unfavorable')
        else
            exit('Attention');
    end;
}