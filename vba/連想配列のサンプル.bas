Attribute VB_Name = "Module1"
Option Explicit
'------------------------------------------------------------------------------
' 連想配列のサンプルテンプレート
'------------------------------------------------------------------------------
Const ADDR_DATA As String = "A3"    '読込データ開始位置
Const SHEET_SUMM As String = "集計" '集計シート名
Const SHEET_ITEMS As String = "商品一覧" '商品一覧シート名
Type TypeItemInf
    cd As String                    '商品コード
    name As String                  '商品名
    price As Integer                '単価
End Type
Dim mItemInf() As TypeItemInf        '商品情報
'******************************************************************************
'処理名称　主処理
'概要　　　シートのボタン押下時に初めに呼び出される
'引数　　　-
'返却値    -
'******************************************************************************
Sub 主処理()

    Dim path As String
    
    path = 入力ファイル取得()
    If VarType(path) = vbBoolean _
        Or path = "False" Then

        'ファイル選択ダイアログでキャンセルされた場合
        '処理を終える
        Exit Sub
    End If

    If ファイル取込(path) Then
        
        Call 商品情報初期化
        Call 集計(path)
        Erase mItemInf
    Else
        MsgBox "ファイル取り込みに失敗しました。", vbOKOnly
    End If
    
    '集計シートを表示
    ThisWorkbook.Sheets(SHEET_SUMM).Activate
End Sub
'******************************************************************************
'処理名称  商品初期化
'概要　　　商品一覧シートの内容を読込む
'引数　　　-
'返却値    -
'******************************************************************************
Sub 商品情報初期化()
    
    Dim i As Integer: i = 0
    
    With ThisWorkbook.Sheets(SHEET_ITEMS).Range(ADDR_DATA)
        
        'シートのデータ件数分繰返す
        Do While .Offset(i, 0).Value <> ""
        
            ReDim Preserve mItemInf(i)
            mItemInf(i).cd = CStr(.Offset(i, 0).Value)
            mItemInf(i).name = .Offset(i, 1).Value
            mItemInf(i).price = CInt(.Offset(i, 2).Value)
            
            i = i + 1
        Loop
    End With
End Sub
'******************************************************************************
'処理名称  商品情報取得
'概要　　　引数の商品コードの商品情報を返却する
'引数　　　商品コード
'返却値    商品情報
'******************************************************************************
Function 商品情報取得(cd As String) As TypeItemInf
    
    Dim i As Integer: i = 1
    
    For i = 0 To UBound(mItemInf)
    
        If mItemInf(i).cd = cd Then
        
            商品情報取得 = mItemInf(i)
            Exit Function
        End If
    Next
    
    '商品一覧にない場合
    Dim itemInf As TypeItemInf
    itemInf.cd = "-"
    itemInf.name = "その他"
    itemInf.price = 0
    商品情報取得 = itemInf
End Function
'******************************************************************************
'処理名称  入力ファイル取得
'概要　　　ファイル選択ダイアログを表示して選択されたファイルのパスを返す。
'引数　　　-
'返却値    ファイルパス
'******************************************************************************
Function 入力ファイル取得() As String
    
    Dim pathCurOrg As String: pathCurOrg = CurDir '元のカレントパス
    Dim path As String                            '選択したファイルパス
    
    ChDir ThisWorkbook.path & "\" & "data"
    path = Application.GetOpenFilename( _
         FileFilter:="csv ファイル (*.csv),*.csv", _
         MultiSelect:=False)
    
    '元のカレントディレクトリに戻す
    ChDir pathCurOrg
    
    '返却値
    入力ファイル取得 = path
End Function
'******************************************************************************
'処理名称　ファイル取込
'概要      引数のパスに指定されたファイルをシートに取込む
'引数　　　入力ファイルパス
'返却値    True：成功、False：失敗
'******************************************************************************
Function ファイル取込(path As String) As Boolean

    Dim sheetNm As String                       '作成するシート名
    Dim buf As String                           'ファイルから読込んだ１行を格納
    Dim tmp() As String                         '項目ごとの文字列を格納
    Dim rowIdx As Integer, colIdx As Integer    'Excelの行、列の索引
    
    On Error GoTo エラー
    
    '入力ファイルパスより対象ファイル名のシート名を作成
    sheetNm = Mid(path, InStrRev(path, "\") + 1)
    sheetNm = Replace(sheetNm, ".csv", "")
    
    '同じシートがある場合はエラー
    Dim ws As Worksheet
    For Each ws In ThisWorkbook.Worksheets
    
        If ws.name = sheetNm Then
        
            Err.Raise 513 '0～512はシステム定義
        End If
    Next

    'シート最後尾にのシートを作成
    With ThisWorkbook
    
        .Sheets.Add after:=Worksheets(Worksheets.count)
        .ActiveSheet.name = sheetNm
        .ActiveSheet.Select
    End With
    
    '読込＆書出
    With Selection
        
        '入力ファイルパスを書き出す
        .Offset(0, 0) = path
        
        '入力ファイルを開く
        Open path For Input As #1
        
        rowIdx = 1
        Do Until EOF(1)
            
            Line Input #1, buf                  '入力ファイルの１行を取得してbufに格納
            tmp = Split(buf, ",")               'bufを","で分割してtmpに格納
            .Offset(rowIdx).NumberFormat = "@"  'ExcelのセルのA列の書式を文字列に設定(0が消えないように)
            
            For colIdx = 0 To UBound(tmp)
                
                '項目をExcelに書き出す
                .Offset(rowIdx, colIdx).Value = tmp(colIdx)
            Next colIdx
            
            rowIdx = rowIdx + 1
        Loop
        
        '入力ファイルを閉じる
        Close #1
    End With

    ファイル取込 = True
    Exit Function

エラー:
    ファイル取込 = False
End Function
'******************************************************************************
'処理名称  集計
'概要　　　取込ファイルの内容を集計シートに出力する
'引数　　　ファイルパス
'返却値    -
'******************************************************************************
Sub 集計(path As String)

    Dim sheetNm As String   '読込シート名
    Dim rangeSt As Range    '書込開始位置を保持するオブジェクト
    Dim i As Integer: i = 1 'ループカウンタ
    Dim dictItem As Object  '連想配列_集計(key=商品コード : value=連想配列_販売)
    Dim dictSale As Object  '連想配列_販売(key=販売価格 : value=販売個数)
    
    'シート名をパスより取得
    sheetNm = Mid(path, InStrRev(path, "\") + 1)
    sheetNm = Replace(sheetNm, ".csv", "")

    '--------------------------------------
    '+ 読込だ内容を連想配列に格納する
    '--------------------------------------
    '連想配列_集計の保存領域を確保する
    Set dictItem = CreateObject("Scripting.Dictionary")
    With ThisWorkbook.Sheets(sheetNm).Range(ADDR_DATA)
        
        '取込シートのデータ件数分繰返す
        Do While .Cells(i, 1) <> ""
        
            '連想配列_集計に商品コードが存在する場合
            If dictItem.Exists(CStr(.Cells(i, 1).Value)) Then
                
                '--------------------------------------
                '+ 連想配列_集計の商品の販売内容を更新
                '--------------------------------------
                '連想配列_集計より連想配列_販売を取得
                Set dictSale = dictItem(CStr(.Cells(i, 1).Value))
                
                '連想配列_販売に販売価格が存在する場合
                If dictSale.Exists(CStr(.Cells(i, 2).Value)) Then
                    
                    '販売個数を更新
                    Dim num As Integer: num = dictSale(CStr(.Cells(i, 2).Value))
                    dictSale(CStr(.Cells(i, 2).Value)) = num + .Cells(i, 3).Value
                Else
                
                    '販売価格を追加
                    dictSale.Add CStr(.Cells(i, 2).Value), .Cells(i, 3).Value
                End If
            Else
                
                '----------------------------
                '+ 連想配列_集計へ商品を追加
                '----------------------------
                Set dictSale = CreateObject("Scripting.Dictionary")
                dictSale.Add CStr(.Cells(i, 2).Value), .Cells(i, 3).Value
                dictItem.Add CStr(.Cells(i, 1).Value), dictSale
            End If
            
            'オブジェクト破棄
            Set dictSale = Nothing
            i = i + 1
        Loop
    End With
    
    '-------------------
    '+ 集計内容の書込み
    '-------------------
    With ThisWorkbook.Sheets(SHEET_SUMM)
        
        '既に記載がある最終行 + 1行を開始位置として設定する
        Dim rowLst As Long: rowLst = .UsedRange.Find("*", , xlFormulas, , xlByRows, xlPrevious).Row
        Set rangeSt = .Range("A1").Cells(rowLst + 1)
    
        rangeSt(ColumnIndex:=2) = Date      '処理日時の書込
        rangeSt(ColumnIndex:=3) = sheetNm   '対象ファイル名の書込
        
        Dim code As Variant
        i = 1
        For Each code In dictItem.Keys
            
            Dim itemInf As TypeItemInf: itemInf = 商品情報取得(CStr(code))
            rangeSt(i, 4) = itemInf.name    '商品名の書込
            
            Dim price As Variant
            Dim summ As Integer: summ = 0
            Dim numm As Integer: numm = 0
            For Each price In dictItem(CStr(code)).Keys
            
                numm = numm + CInt(dictItem(code)(price))
                summ = summ + CInt(price) * CInt(dictItem(code)(price))
            Next
            
            rangeSt(i, 5) = numm            '売上個数の書込
            rangeSt(i, 6) = summ            '売上高の書込
            
            i = i + 1
        Next
    End With

    'オブジェクト破棄
    Set rangeSt = Nothing
    Set dictItem = Nothing
End Sub
