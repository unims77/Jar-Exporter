object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Jar Export Util v1.2 (UNIMS)'
  ClientHeight = 405
  ClientWidth = 614
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  Scaled = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    614
    405)
  PixelsPerInch = 96
  TextHeight = 14
  object Label1: TLabel
    Left = 11
    Top = 124
    Width = 77
    Height = 14
    Caption = 'Jar Export List'
  end
  object Label2: TLabel
    Left = 11
    Top = 351
    Width = 295
    Height = 14
    Anchors = [akLeft, akBottom]
    Caption = 'If you want individual export, select and doubleclick...'
  end
  object Label3: TLabel
    Left = 12
    Top = 101
    Width = 84
    Height = 14
    Caption = 'class out path :'
  end
  object lblClassPath: TLabel
    Left = 101
    Top = 101
    Width = 25
    Height = 14
    Caption = 'path'
  end
  object edtJarPath: TLabeledEdit
    Left = 11
    Top = 24
    Width = 505
    Height = 22
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 68
    EditLabel.Height = 14
    EditLabel.Caption = 'Jar.exe Path'
    ImeName = 'Microsoft Office IME 2007'
    ReadOnly = True
    TabOrder = 0
  end
  object btnMake: TButton
    Left = 483
    Top = 371
    Width = 120
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Export All'
    TabOrder = 1
    OnClick = btnMakeClick
  end
  object edtExportPath: TLabeledEdit
    Left = 11
    Top = 70
    Width = 505
    Height = 22
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 92
    EditLabel.Height = 14
    EditLabel.Caption = 'Jar Export Folder'
    ImeName = 'Microsoft Office IME 2007'
    ReadOnly = True
    TabOrder = 2
  end
  object lvJarList: TListBox
    Left = 11
    Top = 144
    Width = 591
    Height = 204
    Anchors = [akLeft, akTop, akRight, akBottom]
    ImeName = 'Microsoft Office IME 2007'
    ItemHeight = 14
    TabOrder = 3
    OnDblClick = lvJarListDblClick
  end
  object btnLoadConfig: TButton
    Left = 403
    Top = 371
    Width = 80
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Load Config'
    TabOrder = 4
    OnClick = btnLoadConfigClick
  end
  object MemoTemp: TMemo
    Left = 97
    Top = 171
    Width = 392
    Height = 110
    ImeName = 'Microsoft Office IME 2007'
    Lines.Strings = (
      'MemoTemp')
    TabOrder = 5
    Visible = False
    WordWrap = False
  end
  object cbxLog: TCheckBox
    Left = 11
    Top = 375
    Width = 78
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'View Log'
    TabOrder = 6
    OnClick = cbxLogClick
  end
  object cbxOpenDir: TCheckBox
    Left = 87
    Top = 375
    Width = 126
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Open Export Folder'
    TabOrder = 7
    OnClick = cbxOpenDirClick
  end
  object btnOpenConfig: TButton
    Left = 323
    Top = 371
    Width = 80
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Open Config'
    TabOrder = 8
    OnClick = btnOpenConfigClick
  end
  object btnOpenFolder: TButton
    Left = 219
    Top = 371
    Width = 104
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Open Exe Folder'
    TabOrder = 9
    OnClick = btnOpenFolderClick
  end
  object btnOpenJarFolder: TButton
    Left = 525
    Top = 21
    Width = 77
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Open Folder'
    TabOrder = 10
    OnClick = btnOpenJarFolderClick
  end
  object btnOpenExportFolder: TButton
    Left = 525
    Top = 68
    Width = 77
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Open Folder'
    TabOrder = 11
    OnClick = btnOpenExportFolderClick
  end
  object XMLDocument1: TXMLDocument
    Left = 200
    Top = 96
    DOMVendorDesc = 'MSXML'
  end
end
