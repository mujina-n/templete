# -*- coding: utf-8 -*-
import os
import pandas as pd
from flask import Flask, request, redirect, url_for, render_template, send_file
from werkzeug import secure_filename
from sklearn.externals import joblib
from wtforms import Form, FormField, FieldList, TextField
from wtforms.validators import Required

app = Flask(__name__)

# 定数
ALLOWED_EXTENSIONS = set(['txt', 'csv'])
CUR_DIR = os.path.dirname(__file__)
UPLOAD_DIR = 'uploads'
DWNLOAD_DIR= 'downloads'
PKL_DIR = 'pkl_objects'
DL_FILE = 'result.csv'
SEP = ';'
# 分類器
clf = joblib.load(open(os.path.join(CUR_DIR, PKL_DIR, 'forest.pkl'), 'rb'))
print clf

class ItemForm(Form):
    feature = TextField(u'feature', validators=[Required()])
    predict = TextField(u'predict', validators=[Required()])

class TblForm(Form):
    items = FieldList(FormField(ItemForm, u'Item'), min_entries=0)

def classify(df):

    # 欠損値補完(汎化のため、0補完)
    df.fillna(0)
    # 予測
    return clf.predict(df)

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1] in ALLOWED_EXTENSIONS

"""
styleシートにクエリストリングをつけるロジック
開発時にcssの内容を即時反映させ確認が必要な場合に有効
今回はhtmlのmetaデータにキャッシュを無効にする設定をしている。
@app.context_processor
def override_url_for():
    return dict(url_for=dated_url_for)

def dated_url_for(endpoint, **values):
    if endpoint == 'static':
        filename = values.get('filename', None)
        if filename:
            file_path = os.path.join(app.root_path,
                                     endpoint, filename)
            values['q'] = int(os.stat(file_path).st_mtime)
    return url_for(endpoint, **values)
"""

@app.route('/' ,methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        file = request.files['file']
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            file.save(os.path.join(CUR_DIR, UPLOAD_DIR, filename))
            return redirect(url_for('upload',
                                    filename=filename))
    return render_template('upload_form.html')

@app.route('/uploads/<filename>')
def upload(filename):

    # アップロードファイル読込
    df = pd.read_csv(os.path.join(CUR_DIR, UPLOAD_DIR, filename),sep=SEP,header=0)
    # 予測
    result = classify(df)
    # 入力ファイル内容に結果列を追加したdf作成
    df_add_col = pd.DataFrame([result]).T
    df_add_col.columns =["ret"]
    df_ret = pd.concat([df, df_add_col], axis=1)
    # 予測結果のCSV出力
    df_ret.to_csv(os.path.join(CUR_DIR, DWNLOAD_DIR, DL_FILE),sep=SEP,index=False)
    # formに登録
    i=0
    form = TblForm()
    for value in df_ret.values:
        fields=ItemForm()
        # TODO csv読込時の形式と異なる。元の値に戻す方法があるか。。
        fields.feature=SEP.join(map(str,value[0:-1]))
        fields.predict=value[-1].astype('int')
        form.items.append_entry(fields)
        i+=1
    return render_template('result.html', form=form, dlfile=DL_FILE)

@app.route('/downloads/<path>', methods=['GET'])
def download(path):
    path = DWNLOAD_DIR + '/' + path
    print 'path=' + path
    return send_file(path, as_attachment=True)

if __name__ == '__main__':
    app.debug=True
    app.run(host="0.0.0.0", port=8080)