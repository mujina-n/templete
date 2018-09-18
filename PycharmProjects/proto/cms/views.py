from django.shortcuts import render, redirect, get_object_or_404
from django.template.context_processors import csrf
from django.conf import settings
from django.views.generic.list import ListView
from django.http import HttpResponse

from cms.models import FileNameModel, ResultModel
from cms.preprocess import edit

from sklearn.ensemble import RandomForestClassifier
from sklearn.externals import joblib
from sklearn.metrics import roc_curve
from sklearn.metrics import confusion_matrix
from sklearn.metrics import auc
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
from sklearn.metrics import f1_score
import pandas as pd
import sys, os, csv
import datetime as dt


UPLOAD_DIR = os.path.dirname(os.path.abspath(__file__)) + '/static/files/'
LIB_DIR = os.path.dirname(os.path.abspath(__file__)) + '/static/libs/'
FUTURE_RANK = "feature_rank_"
#clf = joblib.load(open(os.path.join(LIB_DIR, 'forest.pkl'), 'rb'))


class UploadList(ListView):
    context_object_name='files'
    template_name='cms/upload_list.html'
    paginate_by = 5

    def get(self, request, *args, **kwargs):
        files = FileNameModel.objects.all().order_by('id').reverse()
        self.object_list = files

        context = self.get_context_data(object_list=self.object_list)
        return self.render_to_response(context)


class ResultList(ListView):
    context_object_name='results'
    template_name='cms/result_list.html'
    paginate_by = 5

    def get(self, request, *args, **kwargs):
        files = ResultModel.objects.all().order_by('id').reverse()
        self.object_list = files

        context = self.get_context_data(object_list=self.object_list)
        return self.render_to_response(context)


# def upload_list(request):
#     files = FileNameModel.objects.all().order_by('id')
#     return render(request,
#                   'cms/upload_list.html',
#                   {'files': files})


def predict(request, file_id):

    # ファイル名取得
    file = get_object_or_404(FileNameModel, pk=file_id)
    # ファイル読込
    df = pd.read_csv(os.path.join(UPLOAD_DIR, file.file_name), sep=';', header=0)

    # 前処理
    df = edit(df)

    # TODO のちに削除-動作目的のため
    # ---ここから---
    # 説明変数と目的変数に分割
    label = 'y'
    y = df.loc[:, label]
    x = df.loc[:, set(df.columns) - set([label])]

    # 学習
    param = {'n_estimators': 100, 'max_depth': 5}
    clf = RandomForestClassifier()
    clf.set_params(**param)
    clf.fit(x, y)

    # 予測
    y_pred = clf.predict(x)
    y_prob = clf.predict_proba(x)[:, 1]
    fpr, tpr, thresholds = roc_curve(y, y_prob)
    acc = round(clf.score(x, y), 4)
    precision = round((precision_score(y, y_pred)), 3)
    recall = round((recall_score(y, y_pred)), 3)
    f1 = round((f1_score(y, y_pred)), 3)
    auc_ = round(auc(fpr, tpr), 4)
    matrix = confusion_matrix(y, y_pred)
    # ---ここまで---

    # 特徴量の係数および重要度ランキングファイルの出力
    tdatetime = dt.datetime.now()
    tstr = tdatetime.strftime('%Y%m%d%H%M%S')
    file_rank = FUTURE_RANK + tstr + ".csv"
    df_rank = pd.DataFrame(clf.feature_importances_).T
    df_rank.columns = list(x.columns)
    df_rank_sort = df_rank.T.reset_index(drop=False)
    df_rank_sort.columns = ["column_name", "importance"]
    df_rank_sort = df_rank_sort.sort_values(by="importance", ascending=False).reset_index(drop=True)
    df_rank_sort.to_csv(os.path.join(UPLOAD_DIR, file_rank), encoding="cp932", index=False)

    insert_data = ResultModel(
        input_name=file.file_name,
        model_name="RandomForest",
        param_name=clf,
        rank_file=file_rank,
        auc=auc_,
        accuracy=acc,
        precision=precision,
        recall=recall,
        f1=f1,
        true_negative=matrix[0][0],
        false_positive=matrix[0][1],
        false_negative=matrix[1][0],
        true_positive=matrix[1][1],
    )
    insert_data.save()
    return redirect('cms:result_list')


def upload_add(request):

    if request.method != 'POST':
        return redirect('cms:upload_list')

    file = request.FILES['file']
    path = os.path.join(UPLOAD_DIR, file.name)
    destination = open(path, 'wb')

    for chunk in file.chunks():
        destination.write(chunk)

    delete_data = FileNameModel.objects.filter(file_name=file.name)
    delete_data.delete()

    insert_data = FileNameModel(file_name = file.name)
    insert_data.save()

    return redirect('cms:upload_list')


def upload_del(request, file_id):

    file = get_object_or_404(FileNameModel, pk=file_id)
    file.delete()
    os.remove(os.path.join(UPLOAD_DIR, file.file_name))
    return redirect('cms:upload_list')


def result_del(request, result_id):

    file = get_object_or_404(ResultModel, pk=result_id)
    file.delete()
    os.remove(os.path.join(UPLOAD_DIR, file.rank_file))
    return redirect('cms:result_list')


def download(request, pk):

    file = get_object_or_404(ResultModel, pk=pk)
    filename = file.rank_file
    with open(os.path.join(UPLOAD_DIR, filename)) as f:

        response = HttpResponse(f, content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename=' + filename
    return response


def edit_join(request, file_id):
    # とりあえず定義だけ
    return redirect('cms:edit_join')
