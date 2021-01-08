{------------------------------------------------------------------------------|
| Project name: Daily Diary                                                    |
| Unit name   : bc_observer.pas                                                |
| Copyright   : (c) 2020 cdbc.dk                                               |
| Programmer  : Benny Christensen /bc                                          |
| Created     : 2020.09.30 /bc initial design and coding,(observer pattern)    |
| Updated     : 2020.09.30 /bc Setting up environment, structure and vision    |
|                          /bc refactored observer to live in his own unit     |
|                                                                              |
|                                                                              |
|                                                                              |
|------------------------------------------------------------------------------|
| Abstract:                                                                    |
|   This unit implements the observer pattern.                                 |
|   TObserved, a subject to observe                                            |
|   TObserver, one or more observers connected to the subject.                 |
|                                                                              |
|                                                                              |
-------------------------------------------------------------------------------}

unit bc_observer;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils;

const
  UnitVersion = '01.27.10.2020'; { 2.nd version }

type
  { needed broader list-notifications :-) }
  Tbc_ListNotification = (ln_Added, ln_Changed, ln_Custom, ln_Deleted, ln_Freed);
  {  }
  Tbc_ObservedChanged = procedure(aSender: TObject;anOperation: TFPObservedOperation;aData: Pointer);
  { TObserved ~ observer pattern }
  TObserved = class(TInterfacedObject,IFPObserved)
  private
    fObservers: TFPList;
  protected
    fExtra: ptrint;
  public
    constructor Create;
    destructor Destroy; override;
    Procedure FPOAttachObserver(AObserver : TObject); { attach a new observer }
    Procedure FPODetachObserver(AObserver : TObject); { detach an observer }
    procedure Notify(Ptr: Pointer;Action: Tbc_ListNotification); virtual; { base notify, calls all attached observers via: }
    Procedure FPONotifyObservers(ASender : TObject; AOperation : TFPObservedOperation; Data : Pointer); { Notify all observers of a change }
    property Extra: ptrint read fExtra write fExtra; { well, you never know :-) }
  end; { TObserved }

  { TObserver ~ observer pattern }
  TObserver = class(TInterfacedObject,IFPObserver)
  protected
    fOnAddItem: TNotifyEvent;
    fOnChangeItem: TNotifyEvent;
    fOnCustomItem: TNotifyEvent;
    fOnDeleteItem: TNotifyEvent;
    fOnFreeItem: TNotifyEvent;
  public
    Procedure FPOObservedChanged(aSender: TObject;Operation: TFPObservedOperation;Data: Pointer); virtual;
//    Procedure FPOObservedChanged(aSender: TObject;Operation: TFPObservedOperation;Data: Pointer); virtual;
    property OnAddItem: TNotifyEvent read fOnAddItem write fOnAddItem;
    property OnChangeItem: TNotifyEvent read fOnChangeItem write fOnChangeItem;
    property OnCustomItem: TNotifyEvent read fOnCustomItem write fOnCustomItem;
    property OnDeleteItem: TNotifyEvent read fOnDeleteItem write fOnDeleteItem;
    property OnFreeItem: TNotifyEvent read fOnFreeItem write fOnFreeItem;
  end; { TObserver }

implementation
uses RtlConsts;

{ *** TObserver *** }
procedure TObserver.FPOObservedChanged(aSender: TObject;Operation: TFPObservedOperation;Data: Pointer);
begin
  case Operation of
    ooAddItem   : if assigned(fOnAddItem) then fOnAddItem(TObject(Data));
    ooChange    : if assigned(fOnChangeItem) then fOnChangeItem(TObject(Data));
    ooCustom    : if assigned(fOnCustomItem) then fOnCustomItem(TObject(Data));
    ooDeleteItem: if assigned(fOnDeleteItem) then fOnDeleteItem(TObject(Data));
    ooFree      : if assigned(fOnFreeItem) then fOnFreeItem(TObject(Data));
  end;
  // TODO
end;

{ *** TObserved *** }
constructor TObserved.Create;
begin
  inherited Create;
  fObservers:= nil;
  // ???
end;

destructor TObserved.Destroy;
begin
  if assigned(fObservers) then begin
    FPONotifyObservers(Self,ooFree,Nil);
    FreeAndNil(fObservers);
  end;
  inherited Destroy;
end;

procedure TObserved.FPOAttachObserver(aObserver: TObject);
begin
  if not assigned(fObservers) then fObservers:= TFPList.Create; { lazy creation }
  fObservers.Add(pointer(aObserver));
end;

procedure TObserved.FPODetachObserver(aObserver: TObject);
begin
  if assigned(fObservers) then begin
    fObservers.Remove(pointer(aObserver));
    if (fObservers.Count = 0) then FreeAndNil(fObservers);
  end;
end;

{  }
{ Tbc_ListNotification = (ln_Added, ln_Changed, ln_Custom, ln_Deleted, ln_Freed); }
procedure TObserved.Notify(Ptr: Pointer; Action: Tbc_ListNotification);
begin
  if assigned(fObservers) then case Action of
    ln_Added  : FPONotifyObservers(Self,ooAddItem,Ptr);
    ln_Changed: FPONotifyObservers(Self,ooChange,Ptr);
    ln_Custom : FPONotifyObservers(Self,ooCustom,Ptr);
    ln_Deleted: FPONotifyObservers(Self,ooDeleteItem,Ptr);
    ln_Freed  : FPONotifyObservers(Self,ooFree,Ptr);
  end;
end;

{ notify each observer in the list of observers }
procedure TObserved.FPONotifyObservers(aSender: TObject;aOperation: TFPObservedOperation;Data: pointer);
var
  I: integer;
  Obs: TObserver;
begin
  if assigned(fObservers) then begin
    for I:= fObservers.Count-1 downto 0 do begin
      Obs:= TObserver(fObservers[I]);
      Obs.FPOObservedChanged(aSender,aOperation,Data);
      Obs:= nil;
    end;
  end;
end;

end.

