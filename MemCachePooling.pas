//////////////////////////////////////////////////////////////////////////////
//
//  unit MemCachePooling.pas
//    Copyright 2003 by Arcana Technologies Incorporated
//    Copyright 2010 by Sivv LLC
//    Written By Jason Southwell
//
//  Description:
//    This unit houses a class that implementats a generic pooling manager.
//
//  Updates:
//    04/29/2010 - Forked unit from pooling.pas to include in MemCache client
//    02/18/2006 - Updates to work with Lazarus\FPC.
//    04/03/2003 - TObjectPool Released to Open Source.
//
//  License:
//    New BSD License
//    Copyright (c) 2009, by Sivv LLC
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without modification,
//    are permitted provided that the following conditions are met:
//
//        * Redistributions of source code must retain the above copyright notice,
//         this list of conditions and the following disclaimer.
//
//        * Redistributions in binary form must reproduce the above copyright notice,
//          this list of conditions and the following disclaimer in the documentation
//          and/or other materials provided with the distribution.
//
//        * Neither the name of Sivv LLC. nor the names of its
//          contributors may be used to endorse or promote products derived from this
//          software without specific prior written permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//    ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
////////////////////////////////////////////////////////////////////////////////

unit MemCachePooling;

interface

uses Classes, SysUtils, SyncObjs;

type
  TObjectEvent = procedure(Sender : TObject; var AObject : TObject) of object;

  TObjectPool = class(TObject)
  private
    CS : TCriticalSection;
    ObjList : TList;
    ObjInUse : TBits;

    FActive : boolean;
    FAutoGrow: boolean;
    FStopping : boolean;
    FGrowToSize: integer;
    FPoolSize: integer;
    FOnCreateObject: TObjectEvent;
    FOnDestroyObject: TObjectEvent;
    FUsageCount: integer;
    FRaiseExceptions: boolean;
  protected
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Start(RaiseExceptions : boolean = False); virtual;
    procedure Stop; virtual;

    function Acquire : TObject; virtual;
    procedure Release(item : TObject); virtual;

    property Active : boolean read FActive;
    property RaiseExceptions : boolean read FRaiseExceptions write FRaiseExceptions;
    property UsageCount : integer read FUsageCount;
    property PoolSize : integer read FPoolSize write FPoolSize;
    property AutoGrow : boolean read FAutoGrow write FAutoGrow;
    property GrowToSize : integer read FGrowToSize write FGrowToSize;
    property OnCreateObject : TObjectEvent read FOnCreateObject write FOnCreateObject;
    property OnDestroyObject : TObjectEvent read FOnDestroyObject write FOnDestroyObject;
  end;

implementation

{ TObjectPool }

function TObjectPool.Acquire: TObject;
var
  idx : integer;
begin
  Result := nil;
  if not FActive then
  begin
    if FRaiseExceptions then
      raise EAbort.Create('Cannot acquire an object before calling Start')
    else
      exit;
  end;
  CS.Enter;
  try
    Inc(FUsageCount);
    idx := ObjInUse.OpenBit;
    if idx < FPoolSize then // idx = FPoolSize when there are no openbits
    begin
      Result := TObject(ObjList[idx]);
      ObjInUse[idx] := True;
    end else
    begin
      // Handle the case where the pool is completely acquired.
      if not AutoGrow or (FPoolSize > FGrowToSize) then
      begin
        if FRaiseExceptions then
          raise Exception.Create('There are no available objects in the pool')
        else
          Exit;
      end;
      inc(FPoolSize);
      ObjInUse.Size := FPoolSize;
      FOnCreateObject(Self, Result);
      ObjList.Add(Result);
      ObjInUse[FPoolSize-1] := True;
    end;
  finally
    CS.Leave;
  end;
end;

constructor TObjectPool.Create;
begin
  CS := TCriticalSection.Create;
  ObjList := TList.Create;
  ObjInUse := TBits.Create;

  FActive := False;
  FAutoGrow := False;
  FGrowToSize := 20;
  FPoolSize := 20;
  FRaiseExceptions := True;
  FOnCreateObject := nil;
  FOnDestroyObject := nil;
  FStopping := false;
end;

destructor TObjectPool.Destroy;
begin
  if FActive then
    Stop;
  CS.Free;
  ObjList.Free;
  ObjInUse.Free;
  inherited;
end;

procedure TObjectPool.Release(item: TObject);
var
  idx : integer;
begin
  if (not FStopping) and (not FActive) then
  begin
    if FRaiseExceptions then
      raise Exception.Create('Cannot release an object before calling Start')
    else
      exit;
  end;
  if item = nil then
  begin
    if FRaiseExceptions then
      raise Exception.Create('Cannot release an object before calling Start')
    else
      exit;
  end;
  CS.Enter;
  try
    idx := ObjList.IndexOf(item);
    if idx < 0 then
    begin
      if FRaiseExceptions then
        raise Exception.Create('Cannot release an object that is not in the pool')
      else
        exit;
    end;
    ObjInUse[idx] := False;

    Dec(FUsageCount);
  finally
    CS.Leave;
  end;
end;

procedure TObjectPool.Start(RaiseExceptions : boolean = False);
var
  i : integer;
  o : TObject;
begin
  // Make sure events are assigned before starting the pool.
  if not Assigned(FOnCreateObject) then
    raise Exception.Create('There must be an OnCreateObject event before calling Start');
  if not Assigned(FOnDestroyObject) then
    raise Exception.Create('There must be an OnDestroyObject event before calling Start');

  // Set the TBits class to the same size as the pool.
  ObjInUse.Size := FPoolSize;

  // Call the OnCreateObject event once for each item in the pool.
  for i := 0 to FPoolSize-1 do
  begin
    o := nil;
    FOnCreateObject(Self,o);
    ObjList.Add(o);
    ObjInUse[i] := False;
  end;

  // Set the active flag to true so that the Acquire method will return values.
  FActive := True;

  // Automatically set RaiseExceptions to false by default.  This keeps
  // exceptions from being raised in threads.
  FRaiseExceptions := RaiseExceptions;
end;

procedure TObjectPool.Stop;
var
  i : integer;
  o : TObject;
begin
  // Wait until all objects have been released from the pool.  After waiting
  // 10 seconds, stop anyway.  This may cause unforseen problems, but usually
  // you only Stop a pool as the application is stopping.  40 x 250 = 10,000
  for i := 1 to 40 do
  begin
    CS.Enter;
    try
      // Setting Active to false here keeps the Acquire method from continuing to
      // retrieve objects.
      FStopping := True;
      FActive := False;
      if FUsageCount = 0 then
        break;
    finally
     CS.Leave;
    end;
    // Sleep here to allow give threads time to release their objects.
    Sleep(250);
  end;

  CS.Enter;
  try
    // Loop through all items in the pool calling the OnDestroyObject event.
    for i := 0 to FPoolSize-1 do
    begin
      o := TObject(ObjList[i]);
      if Assigned(FOnDestroyObject) then
        FOnDestroyObject(Self, o)
      else
        o.Free;
    end;

    // clear the memory used by the list object and TBits class.
    ObjList.Clear;
    ObjInUse.Size := 0;

    FRaiseExceptions := True;
  finally
    CS.Leave;
    FStopping := False;
  end;
end;

end.
