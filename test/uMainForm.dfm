object frmMemCacheTest: TfrmMemCacheTest
  Left = 0
  Top = 0
  Caption = 'MemCache Test'
  ClientHeight = 244
  ClientWidth = 272
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 272
    Height = 244
    ActivePage = tsFunctions
    Align = alClient
    TabOrder = 0
    ExplicitLeft = 312
    ExplicitTop = 64
    ExplicitWidth = 289
    ExplicitHeight = 193
    object tsServers: TTabSheet
      Caption = 'Servers'
      ExplicitWidth = 281
      ExplicitHeight = 165
      DesignSize = (
        264
        216)
      object Label3: TLabel
        Left = 8
        Top = 8
        Width = 163
        Height = 13
        Caption = 'Servers (default 100% localhost):'
      end
      object txtServers: TMemo
        Left = 8
        Top = 27
        Width = 245
        Height = 142
        Anchors = [akLeft, akTop, akRight, akBottom]
        Lines.Strings = (
          '100=127.0.0.1:11211')
        TabOrder = 0
      end
      object Button10: TButton
        Left = 80
        Top = 180
        Width = 75
        Height = 25
        Caption = 'Restart'
        TabOrder = 1
        OnClick = Button10Click
      end
    end
    object tsFunctions: TTabSheet
      Caption = 'Functions'
      ImageIndex = 1
      ExplicitLeft = -524
      ExplicitTop = 272
      ExplicitWidth = 281
      ExplicitHeight = 165
      object Label1: TLabel
        Left = 8
        Top = 8
        Width = 22
        Height = 13
        Caption = 'Key:'
      end
      object Label2: TLabel
        Left = 8
        Top = 56
        Width = 30
        Height = 13
        Caption = 'Value:'
      end
      object btnStore: TButton
        Left = 8
        Top = 102
        Width = 75
        Height = 25
        Caption = 'Store'
        TabOrder = 0
        OnClick = btnStoreClick
      end
      object edtKey: TEdit
        Left = 8
        Top = 27
        Width = 237
        Height = 21
        TabOrder = 1
        Text = 'testkey'
      end
      object edtValue: TEdit
        Left = 8
        Top = 75
        Width = 237
        Height = 21
        TabOrder = 2
        Text = '1'
      end
      object btnLookup: TButton
        Left = 8
        Top = 133
        Width = 75
        Height = 25
        Caption = 'Lookup'
        TabOrder = 3
        OnClick = btnLookupClick
      end
      object btnDelete: TButton
        Left = 170
        Top = 164
        Width = 75
        Height = 25
        Caption = 'Delete'
        TabOrder = 4
        OnClick = btnDeleteClick
      end
      object btnIncrement: TButton
        Left = 170
        Top = 102
        Width = 75
        Height = 25
        Caption = 'Increment'
        TabOrder = 5
        OnClick = btnIncrementClick
      end
      object btnDecrement: TButton
        Left = 170
        Top = 133
        Width = 75
        Height = 25
        Caption = 'Decrement'
        TabOrder = 6
        OnClick = btnDecrementClick
      end
      object btnAppend: TButton
        Left = 89
        Top = 102
        Width = 75
        Height = 25
        Caption = 'Append'
        TabOrder = 7
        OnClick = btnAppendClick
      end
      object btnPrepend: TButton
        Left = 89
        Top = 133
        Width = 75
        Height = 25
        Caption = 'Prepend'
        TabOrder = 8
        OnClick = btnPrependClick
      end
      object btnInsert: TButton
        Left = 8
        Top = 164
        Width = 75
        Height = 25
        Caption = 'Insert'
        TabOrder = 9
        OnClick = btnInsertClick
      end
      object btnReplace: TButton
        Left = 89
        Top = 164
        Width = 75
        Height = 25
        Caption = 'Replace'
        TabOrder = 10
        OnClick = btnReplaceClick
      end
    end
  end
end
