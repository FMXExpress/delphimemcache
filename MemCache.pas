////////////////////////////////////////////////////////////////////////////////////
//
// MemCache.pas - Delphi client for Memcached
//
// Delphi Client Version 0.0.2
// Supporting Memcached Version 1.2.6
//
// Project Homepage:
//    http://code.google.com/p/delphimemcache
//
// Memcached can be found at:
//    http://code.google.com/p/memcached
//    http://danga.com/memcached
//
// Protocol description:
//    http://code.sixapart.com/svn/memcached/trunk/server/doc/protocol.txt
//
// New BSD License
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
//  Changelog -
//    9/30/2009 - Initial release
//
//  Use:
//
//  1. MemCache := TMemCache.Create(sl);
//     Create a global instance of Memcache. Pass a string list containing a list
//     of servers.  The string list should be in the following format:
//       %%=ip:port
//     Example:
//       80=62.33.112.1:8098
//       20=62.33.112.2:11211
//     Note: the numbers to the left of the equal sign is a whole percentage that
//     must total 100 across all server entries.
//
//  2. Access the memcache via one of the following threadsafe methods:
//       procedure Store(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
//       procedure Store(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
//           Applies a value to the memcache regardless of if it previously existed.
//
//       procedure Append(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
//       procedure Append(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
//           Appends the supplied value to the existing value in the memcache.
//
//       procedure Prepend(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
//       procedure Prepend(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
//           Prepends the supplied value to the existing value in the memcache.
//
//       procedure Replace(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
//       procedure Replace(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
//           If a value for the supplied key exists in memcache the supplied value will overwrite.
//           If it does not exist, then no action is taken.
//
//       procedure Insert(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
//       procedure Insert(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
//           If a value for the supplied key does not exist in memcache the supplied value will be added.
//           If a value already exists, no action is taken.
//
//       procedure StoreSafely(Key, Value : string; SafeToken : UInt64; Expires : TDateTime = 0; Flags : Word = 0); overload;
//       procedure StoreSafely(Key : string; Value : TStream; SafeToken : UInt64; Expires : TDateTime = 0; Flags : Word = 0); overload;
//           Applies a value to the memcache regardless of if it previously existed
//           if the value has unchanged since the supplied SafeToken was generated.
//
//       function Lookup(Key : string; RequestSafeToken : boolean = false) : IMemCacheValue;
//           Retrieves a value from Memcache.  Pass true to RequestSafeToken if you would like to
//           retrieve a SafeToken to use with a future call to StoreSafely
//
//           The returning object has the following members:
//               function Value : string;
//               function Key : string;
//               function Stream : TStream;
//               function Flags : Word;
//               function SafeToken : UInt64;
//
//       function Delete(Key : string; BlockSeconds : Integer = 0) : boolean;
//           If a value for the supplied key exists, the value is deleted and the result of
//           the function will be true.
//
//       function Increment(Key : string; ByValue : integer = 1) : UInt64;
//       function Decrement(Key : string; ByValue : integer = 1) : UInt64;
//           Calling increment and decrement will perform an atomic increment or decrement
//           on a value in the memcache.  There must be a value alraedy stored for the
//           specified key
//
//  TODO:
//    - Refactor to move to a connected object pool for each server and utilize
//      the preconnected objects. Should make for a rather large performance boost.
//
////////////////////////////////////////////////////////////////////////////////////

unit MemCache;

interface

uses SysUtils, Classes, IdTCPClient, IdHashSHA1;

type
  EMemCacheException = class(Exception);

  TMemCacheServer = record
    Load : integer;
    IP : string;
    Port : integer;
  end;

  TServerRingItem = record
    IP : string;
    Port : Integer;
    Pos : UInt64;
  end;

  IMemCacheValue = interface(IUnknown)
  ['{E6E55496-BC7D-4A76-BF16-292D59FD5EF5}']
    function Value : string;
    function Key : string;
    function Stream : TStream;
    function Flags : Word;
    function SafeToken : UInt64;
  end;

  IMemCache = interface(IUnknown)
  ['{DF5EBDD9-1CDC-4875-921B-BA507C85CCA3}']
    procedure Store(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Store(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Append(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Append(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Prepend(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Prepend(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Replace(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Replace(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Insert(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Insert(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure StoreSafely(Key, Value : string; SafeToken : UInt64; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure StoreSafely(Key : string; Value : TStream; SafeToken : UInt64; Expires : TDateTime = 0; Flags : Word = 0); overload;
    function Lookup(Key : string; RequestSafeToken : boolean = false) : IMemCacheValue;
    function Delete(Key : string; BlockSeconds : Integer = 0) : boolean;
    function Increment(Key : string; ByValue : integer = 1) : UInt64;
    function Decrement(Key : string; ByValue : integer = 1) : UInt64;
  end;

  TMemCacheValue = class(TInterfacedObject,IMemCacheValue)
  private
    FStream : TStringStream;
    FFlags : Word;
    FSafeToken : UInt64;
    FKey : string;
    FCommand : string;
  public
    constructor Create(text : string); virtual;
    destructor Destroy; override;

    function Command : string;
    function Value : string;
    function Key : string;
    function Stream : TStream;
    function Flags : Word;
    function SafeToken : UInt64;
  end;

  TMemCache = class(TInterfacedObject, IMemCache)
  private
    ServerList : array of TMemCacheServer;
    ServerRing : array of TServerRingItem;
    FRegisterPosition : integer;
  protected
    function ToHash(str : string) : UInt64; virtual;
    function ExecuteCommand(key, cmd : string) : string; virtual;
    function LocateServer(key : string) : TServerRingItem; overload; virtual;
    function LocateServer(RingPosition : Int64): TServerRingItem; overload; virtual;
    procedure RegisterServer(str : string); virtual;
    procedure SortServerRing; virtual;
  public
    //
    // ConfigData is a string list of %%=ip:port where %% is the percentage of distribution.
    // for example, 80=127.0.0.1:11211 would send 80% of the load to localhost on port 11211.
    // if port = 11211 then it may be excluded.
    //
    // If ConfigData is omitted, 100=127.0.0.1:11211 is assumed.
    //
    constructor Create(ConfigData : TStrings = nil); virtual;
    destructor Destroy; override;

    procedure Store(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Store(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Append(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Append(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Prepend(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Prepend(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Replace(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Replace(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Insert(Key, Value : string; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure Insert(Key : string; Value : TStream; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure StoreSafely(Key, Value : string; SafeToken : UInt64; Expires : TDateTime = 0; Flags : Word = 0); overload;
    procedure StoreSafely(Key : string; Value : TStream; SafeToken : UInt64; Expires : TDateTime = 0; Flags : Word = 0); overload;
    function Lookup(Key : string; RequestSafeToken : boolean = false) : IMemCacheValue;
    function Delete(Key : string; BlockSeconds : Integer = 0) : boolean;
    function Increment(Key : string; ByValue : integer = 1) : UInt64;
    function Decrement(Key : string; ByValue : integer = 1) : UInt64;

    function CheckServers(RaiseException : boolean = false) : boolean;
  end;

  function MemcacheConfigFormat(Load : integer; IP : string; Port : integer = 11211) : string;

implementation

uses DateUtils;

function MemcacheConfigFormat(Load : integer; IP : string; Port : integer = 11211) : string;
begin
  Result := IntToStr(Load)+'='+IP+':'+IntToStr(Port)
end;

function StrToUInt64(const S: string): UInt64;
var
  E: Integer;
begin
  Val(S, Result, E);
  if E <> 0 then
    raise Exception.Create('Invalid UINT64');
end;

function MemCacheTime(dt : TDateTime) : string;
var
  i : UInt64;
begin
  if dt <> 0 then
  begin
    i := SecondsBetween(EncodeDate(1970,1,1),dt);
    Result := UIntToStr(i);
  end else
    Result := '0';
end;

{ TMemCache }

procedure TMemCache.Append(Key: string; Value: TStream; Expires: TDateTime = 0;
  Flags: Word = 0);
var
  s, sValue : string;
begin
  SetLength(sValue,Value.Size);
  Value.Read(sValue[1],Value.Size);

  s := ExecuteCommand(
    Key,
    'append '+Key+' '+IntToStr(Flags)+' '+MemcacheTime(Expires)+' '+IntToStr(Value.Size)+#13#10+
    sValue+#13#10
  );
  if s <> 'STORED' then
    raise EMemCacheException.Create('Error storing value: '+s);
end;

procedure TMemCache.Append(Key, Value: string; Expires: TDateTime = 0; Flags: Word = 0);
var
  s : string;
begin
  s := ExecuteCommand(
    Key,
    'append '+Key+' '+IntToStr(Flags)+' '+MemcacheTime(Expires)+' '+IntToStr(length(Value))+#13#10+
    Value+#13#10
  );
  if s <> 'STORED' then
    raise EMemCacheException.Create('Error storing value: '+s);
end;

constructor TMemCache.Create(ConfigData: TStrings);
var
  i: Integer;
begin
  inherited Create;
  FRegisterPosition := 0;
  SetLength(ServerRing,100);
  SetLength(ServerList,0);
  if (ConfigData <> nil) and (ConfigData.Count > 0) then
  begin
    for i := 0 to ConfigData.Count - 1 do
      RegisterServer(ConfigData[i]);
  end else
    RegisterServer('');
  SortServerRing;
end;

function TMemCache.Decrement(Key: string; ByValue : integer = 1): UInt64;
var
  s : string;
begin
  s := ExecuteCommand(Key, 'decr '+Key+' '+IntToStr(ByValue));
  if s = 'NOT_FOUND' then
    raise EMemCacheException.Create('The specified key does not exist.');
  Result := StrToUInt64(s);
end;

function TMemCache.Delete(Key: string; BlockSeconds: Integer = 0): boolean;
var
  s : string;
begin
  s := ExecuteCommand(Key, 'delete '+Key+' '+IntToStr(BlockSeconds));
  if s = 'NOT_FOUND' then
    raise EMemCacheException.Create('The specified key does not exist.');
  Result := s = 'DELETED';
end;

destructor TMemCache.Destroy;
var
  i: Integer;
begin
  for i := low(ServerRing) to High(ServerRing) do
    ServerRing[i].IP := '';
  for i := low(ServerList) to High(ServerList) do
    ServerList[i].IP := '';
  inherited;
end;

function TMemCache.ExecuteCommand(key, cmd: string): string;
var
  tcp : TIdTCPClient;
  server : TServerRingItem;
  s, s13, sFirstFound : string;
  bIncDec : boolean;
begin
  s := Copy(cmd,1,4);
  bIncDec := (s = 'incr') or (s = 'decr');
  // TODO: Refactor to move to a connected object pool for each server and utilize the preconnected objects.
  //       Will make for a rather large performance boost.
  tcp := TIdTCPClient.Create;
  try
    sFirstFound := '';
    repeat
      server := LocateServer(key);
      tcp.Host := server.IP;
      tcp.Port := server.Port;
      try
        tcp.Connect;
      except
        if server.IP = sFirstFound then
          raise EMemCacheException.Create('None of the registered MemCached servers are responding.');
      end;
      if sFirstFound = '' then
        sFirstFound := server.IP;
    until tcp.Connected;

    tcp.Socket.Write(cmd+#13#10);
    result := '';
    s := '';
    repeat
      s := tcp.Socket.ReadLn;
      s13 := Copy(s,1,13);
      if result <> '' then
        Result := Result+#13#10+s
      else
        Result := s;

    until bIncDec or
          (s = 'END') or
          (s = 'DELETED') or
          (s = 'STORED') or
          (s = 'ERROR') or
          (s13 = 'SERVER_ERROR') or
          (s13 = 'CLIENT_ERROR');
  finally
    tcp.Free;
  end;

  if Result <> 'ERROR'#13#10 then
  begin
    s := Copy(Result,1,13);
    if s = 'CLIENT_ERROR ' then
      raise EMemCacheException.Create('Memcache Error: Input does not conform to protocol - '+Copy(Result,14,high(Integer)))
    else if s = 'SERVER_ERROR ' then
      raise EMemCacheException.Create('Memcache Error: Server raised exception - '+Copy(Result,14,High(Integer)));
  end else
    raise EMemCacheException.Create('Memcache Error: Non Existent Command')
end;

function TMemCache.Increment(Key: string; ByValue : integer = 1): UInt64;
var
  s : string;
begin
  s := ExecuteCommand(Key, 'incr '+Key+' '+IntToStr(ByValue));
  if s = 'NOT_FOUND' then
    raise EMemCacheException.Create('The specified key does not exist.');
  Result := StrToUInt64(TrimRight(s));
end;

procedure TMemCache.Insert(Key: string; Value: TStream; Expires: TDateTime = 0;
  Flags: Word = 0);
var
  s, sValue : string;
begin
  SetLength(sValue,Value.Size);
  Value.Read(sValue[1],Value.Size);

  s := ExecuteCommand(
    Key,
    'add '+Key+' '+IntToStr(Flags)+' '+MemcacheTime(Expires)+' '+IntToStr(Value.Size)+#13#10+
    sValue+#13#10
  );
  if s <> 'STORED' then
    raise EMemCacheException.Create('Error storing value: '+s);
end;

procedure TMemCache.Insert(Key, Value: string; Expires: TDateTime = 0; Flags: Word = 0);
var
  s : string;
begin
  s := ExecuteCommand(
    Key,
    'add '+Key+' '+IntToStr(Flags)+' '+MemcacheTime(Expires)+' '+IntToStr(length(Value))+#13#10+
    Value+#13#10
  );
  if s <> 'STORED' then
    raise EMemCacheException.Create('Error storing value: '+s);
end;

function TMemCache.LocateServer(key : string): TServerRingItem;
begin
  Result := LocateServer(ToHash(key));
end;

function TMemCache.LocateServer(RingPosition : Int64): TServerRingItem;
var
  i, iFound : integer;
begin
  iFound := -1;
  for i := Low(ServerRing) to High(ServerRing) do
  begin
    if ServerRing[i].Pos > RingPosition then
    begin
      if i =low(ServerRing) then
        iFound := High(ServerRing)
      else
        iFound := i;
      break;
    end;
  end;
  if iFound < 0 then
    iFound := 0;

  Result := ServerRing[iFound];
end;

function TMemCache.Lookup(Key: string; RequestSafeToken : boolean = false): IMemCacheValue;
var
  s : string;
begin
  if RequestSafeToken then
    Result := TMemCacheValue.Create(ExecuteCommand(Key, 'gets '+Key))
  else
    Result := TMemCacheValue.Create(ExecuteCommand(Key, 'get '+Key));
end;

procedure TMemCache.Prepend(Key: string; Value: TStream; Expires: TDateTime = 0;
  Flags: Word = 0);
var
  s, sValue : string;
begin
  SetLength(sValue,Value.Size);
  Value.Read(sValue[1],Value.Size);

  s := ExecuteCommand(
    Key,
    'prepend '+Key+' '+IntToStr(Flags)+' '+MemcacheTime(Expires)+' '+IntToStr(Value.Size)+#13#10+
    sValue+#13#10
  );
  if s <> 'STORED' then
    raise EMemCacheException.Create('Error storing value: '+s);
end;

procedure TMemCache.Prepend(Key, Value: string; Expires: TDateTime = 0;
  Flags: Word = 0);
var
  s : string;
begin
  s := ExecuteCommand(
    Key,
    'prepend '+Key+' '+IntToStr(Flags)+' '+MemcacheTime(Expires)+' '+IntToStr(length(Value))+#13#10+
    Value+#13#10
  );
  if s <> 'STORED' then
    raise EMemCacheException.Create('Error storing value: '+s);
end;

procedure TMemCache.Replace(Key, Value: string; Expires: TDateTime = 0;
  Flags: Word = 0);
var
  s : string;
begin
  s := ExecuteCommand(
    Key,
    'replace '+Key+' '+IntToStr(Flags)+' '+MemcacheTime(Expires)+' '+IntToStr(length(Value))+#13#10+
    Value+#13#10
  );
  if s <> 'STORED' then
    raise EMemCacheException.Create('Error storing value: '+s);
end;

procedure TMemCache.RegisterServer(str: string);
var
  i, iPos : integer;
begin
  SetLength(ServerList,length(ServerList)+1);
  ServerList[length(ServerList)-1].Load := 100;
  ServerList[length(ServerList)-1].Port := 11211;
  ServerList[length(ServerList)-1].IP := '127.0.0.1';

  if str <> '' then
  begin
    iPos := Pos('=',str);
    if iPos > 0 then
    begin
      ServerList[length(ServerList)-1].Load := StrToInt(Copy(str,1,iPos-1));
      System.Delete(str,1,iPos);
    end;

    iPos := Pos(':',str);
    if iPos > 0 then
    begin
      ServerList[length(ServerList)-1].IP := Copy(str,1,iPos-1);
      System.Delete(str,1,iPos);
      ServerList[length(ServerList)-1].Port := StrToInt(str);
    end else
      ServerList[length(ServerList)-1].IP := str;
  end;

  for i := 1 to ServerList[length(ServerList)-1].Load do
  begin
    ServerRing[FRegisterPosition].IP := ServerList[length(ServerList)-1].IP;
    ServerRing[FRegisterPosition].Port := ServerList[length(ServerList)-1].Port;
    ServerRing[FRegisterPosition].Pos := ToHash(ServerList[length(ServerList)-1].IP+'.'+IntToStr(ServerList[length(ServerList)-1].Port)+'.'+IntToStr(i));
    inc(FRegisterPosition);
  end;
end;

procedure TMemCache.Replace(Key: string; Value: TStream; Expires: TDateTime = 0;
  Flags: Word = 0);
var
  s, sValue : string;
begin
  SetLength(sValue,Value.Size);
  Value.Read(sValue[1],Value.Size);

  s := ExecuteCommand(
    Key,
    'replace '+Key+' '+IntToStr(Flags)+' '+MemcacheTime(Expires)+' '+IntToStr(Value.Size)+#13#10+
    sValue+#13#10
  );
  if s <> 'STORED' then
    raise EMemCacheException.Create('Error storing value: '+s);
end;

procedure TMemCache.Store(Key, Value: string; Expires: TDateTime = 0; Flags: Word = 0);
var
  s : string;
begin
  s := ExecuteCommand(
    Key,
    'set '+Key+' '+IntToStr(Flags)+' '+MemcacheTime(Expires)+' '+IntToStr(length(Value))+#13#10+
    Value+#13#10
  );
  if s <> 'STORED' then
    raise EMemCacheException.Create('Error storing value: '+s);
end;

procedure TMemCache.SortServerRing;
  procedure QuickSort(var A: array of TServerRingItem; iLo, iHi: Integer) ;
  var
    Lo, Hi : Integer;
    Pivot, T : TServerRingItem;
  begin
    Lo := iLo;
    Hi := iHi;
    Pivot := A[(Lo + Hi) div 2];
    repeat
      while A[Lo].Pos < Pivot.Pos do Inc(Lo) ;
      while A[Hi].Pos > Pivot.Pos do Dec(Hi) ;
      if Lo <= Hi then
      begin
        T := A[Lo];
        A[Lo] := A[Hi];
        A[Hi] := T;
        Inc(Lo) ;
        Dec(Hi) ;
      end;
    until Lo > Hi;
    if Hi > iLo then QuickSort(A, iLo, Hi) ;
    if Lo < iHi then QuickSort(A, Lo, iHi) ;
  end;
begin
  QuickSort(ServerRing,Low(ServerRing),High(ServerRing));
end;

procedure TMemCache.Store(Key: string; Value: TStream; Expires: TDateTime = 0;
  Flags: Word = 0);
var
  s, sValue : string;
begin
  SetLength(sValue,Value.Size);
  Value.Read(sValue[1],Value.Size);

  s := ExecuteCommand(
    Key,
    'set '+Key+' '+IntToStr(Flags)+' '+MemcacheTime(Expires)+' '+IntToStr(Value.Size)+#13#10+
    sValue+#13#10
  );
  if s <> 'STORED' then
    raise EMemCacheException.Create('Error storing value: '+s);
end;

procedure TMemCache.StoreSafely(Key, Value: string; SafeToken: UInt64;
  Expires: TDateTime = 0; Flags: Word = 0);
var
  s : string;
begin
  s := ExecuteCommand(
    Key,
    'cas '+Key+' '+IntToStr(Flags)+' '+MemcacheTime(Expires)+' '+IntToStr(length(Value))+#13#10+
    Value+#13#10
  );
  if s <> 'STORED' then
    raise EMemCacheException.Create('Error storing value: '+s);
end;

procedure TMemCache.StoreSafely(Key: string; Value: TStream; SafeToken: UInt64;
  Expires: TDateTime = 0; Flags: Word = 0);
var
  s, sValue : string;
begin
  SetLength(sValue,Value.Size);
  Value.Read(sValue[1],Value.Size);

  s := ExecuteCommand(
    Key,
    'cas '+Key+' '+IntToStr(Flags)+' '+MemcacheTime(Expires)+' '+IntToStr(Value.Size)+' '+UIntToStr(SafeToken)+#13#10+
    sValue+#13#10
  );
  if s <> 'STORED' then
    raise EMemCacheException.Create('Error storing value: '+s);
end;

function TMemCache.CheckServers(RaiseException : boolean = false) : boolean;
var
  i : integer;
  tcp : TIdTCPClient;
begin
  Result := True;
  tcp := TIdTCPClient.Create;
  try
    for i := Low(ServerList) to High(ServerList) do
    begin
      tcp.Host := ServerList[i].IP;
      tcp.Port := ServerList[i].Port;
      try
        tcp.Connect;
      except
        on e: exception do
        begin
          if not raiseException then
          begin
            Result := False;
            exit;
          end else
            raise Exception(e.ClassType).Create('Error connecting with memcache on "'+ServerList[i].IP+':'+IntToStr(ServerList[i].Port)+'". '+e.Message);
        end;
      end;
    end;
  finally
    tcp.Free;
  end;
end;

function TMemCache.ToHash(str: string): UInt64;
  function HexToInt64(Hex: string): Uint64;
  const HexValues = '0123456789ABCDEF';
  var
    i: integer;
  begin
    Result := 0;
    case Length(Hex) of
      0: Result := 0;
      1..16: for i:=1 to Length(Hex) do
        Result := 16*Result + Pos(Upcase(Hex[i]), HexValues)-1;
      else for i:=1 to 16 do
        Result := 16*Result + Pos(Upcase(Hex[i]), HexValues)-1;
    end;
  end;
var
  hash : TIdHashSHA1;
begin
  hash := TIdHashSHA1.Create;
  try
    Result := HexToInt64(Copy(hash.HashStringAsHex(str),1,8));
  finally
    hash.Free;
  end;
end;

{ TMemCacheValue }

function TMemCacheValue.Command: string;
begin
  Result := FCommand;
end;

constructor TMemCacheValue.Create(text: string);
  function NextField(var str : string) : string;
  var
    i, iLen : integer;
    bOK : boolean;
  begin
    Result := '';
    bOK := False;
    iLen := Length(str);
    for i := 1 to iLen do
      case str[i] of
        ' ',#13: begin
          Result := Copy(str,1,i-1);
          if str[i] = #13 then
            Delete(str,1,i-1)
          else
            Delete(str,1,i);
          bOK := true;
          break;
        end;
      end;
    if (not bOK) and (Result = '') and (str <> '') then
    begin
      Result := str;
      str := '';
    end;
  end;
var
  s: string;
  iSize : integer;
begin
  inherited Create;
  FStream := TStringStream.Create;
  if text='END' then
  begin
    FCommand := text;
    FKey := '';
    FFlags := 0;
    FSafeToken := 0;
    FStream.Size := 0;
  end else
  begin
    FCommand := NextField(text);
    FKey := NextField(text);
    FFlags := StrToInt(NextField(text));
    iSize := StrToInt(NextField(text));
    s := NextField(text);
    if s <> '' then
      FSafeToken := StrToUInt64(s)
    else
      FSafeToken := 0;
    Delete(text,1,2);
    FStream.WriteString(Copy(text,1,iSize));
    FStream.Position := 0;
  end;
end;

destructor TMemCacheValue.Destroy;
begin
  FStream.Free;
  inherited;
end;

function TMemCacheValue.Flags: Word;
begin
  Result := FFlags;
end;

function TMemCacheValue.Key: string;
begin

end;

function TMemCacheValue.SafeToken: UInt64;
begin
  Result := FSafeToken;
end;

function TMemCacheValue.Stream: TStream;
begin
  Result := FStream;
end;

function TMemCacheValue.Value: string;
begin
  Result := FStream.DataString;
end;

end.
