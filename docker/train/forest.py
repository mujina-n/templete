# -*- coding: utf-8 -*-
import pandas as pd
import numpy as np
from sklearn.preprocessing import Imputer
from sklearn.model_selection import train_test_split
from sklearn.model_selection import GridSearchCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import confusion_matrix
from sklearn.metrics import f1_score
from sklearn.metrics import make_scorer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import learning_curve
from sklearn.model_selection import validation_curve
import matplotlib.pyplot as plt
from seaborn import heatmap
from sklearn.externals import joblib


'''
基本操作
・行数
　print len(df)
・行列数
　print df.shape
・データフレームの情報
　print df.info
・データの件数、統計情報の確認
　print df.describe()
・文字型、数値型を判定する方法？
　type(o),isinstance(o, type)
・特定データへの名前でのアクセス
　X_default=df.ix[:,'default']
　print X_default
・データ操作
 print df.query("age > '30'")
 condition = 30
 print df.query("age > @condition")
・部分文字列検索
　selector = pd.Series(df.columns).str.contains("age")
　print df.ix[:,np.array(selector)]
・データ削除
 del df['default']
 print df
'''

# データ読込
df = pd.read_csv('bank-additional-cast.csv',sep=';',header=0)

"""
# 欠損値の割合を調査
print "--欠損値数--"
print "age\t:" + str(len(df.query("age == 'N'")))
print "job\t:" + str(len(df.query("job == 'N'")))
print "marital\t:" + str(len(df.query("marital == 'N'")))
print "education\t:" + str(len(df.query("education == 'N'")))
print "default\t:" + str(len(df.query("default == 'N'")))
print "housing\t:" + str(len(df.query("housing == 'N'")))
print "loan\t:" + str(len(df.query("loan == 'N'")))
print "contact\t:" + str(len(df.query("contact == 'N'")))
print "month\t:" + str(len(df.query("month == 'N'")))
print "day_of_week\t:" + str(len(df.query("day_of_week == 'N'")))
print "duration\t:" + str(len(df.query("duration == 'N'")))
print "campaign\t:" + str(len(df.query("campaign == 'N'")))
print "pdays\t:" + str(len(df.query("pdays == '999'")))
print "previous\t:" + str(len(df.query("previous == 'N'")))
print "poutcome\t:" + str(len(df.query("poutcome == 'N'")))
#print "emp.var.rate\t:" + str(len(df.query("emp.var.rate == 'N'")))
#print "cons.price.idx\t:" + str(len(df.query("cons.price.idx == 'N'")))
print "euribor3m\t:" + str(len(df.query("euribor3m == 'N'")))
print "y\t:" + str(len(df.query("y == 'N'")))
"""
# 欠損値の補完 
# pdaysは平均値補完
imp = Imputer(missing_values='NaN', strategy='mean', axis=0)
imp.fit(df[["pdays"]])
df["pdays"]=imp.transform(df[["pdays"]]).ravel()

# 上記以外は最頻値補完
imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)
imp.fit(df[["job"]])
df["job"]=imp.transform(df[["job"]]).ravel()

imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)
imp.fit(df[["marital"]])
df["marital"]=imp.transform(df[["marital"]]).ravel()

imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)
imp.fit(df[["education"]])
df["education"]=imp.transform(df[["education"]]).ravel()

imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)
imp.fit(df[["default"]])
df["default"]=imp.transform(df[["default"]]).ravel()

imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)
imp.fit(df[["housing"]])
df["housing"]=imp.transform(df[["housing"]]).ravel()

imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)
imp.fit(df[["loan"]])
df["loan"]=imp.transform(df[["loan"]]).ravel()

#
# 現状把握
#
# 各データ分布を表示
df.hist(figsize=(12, 12))
# 相関分析
plt.figure(figsize=(15,15))
heatmap(df.corr(), annot=True)
# 分布確認時に"default"は値が一種類しかないため項目から削除
df.drop(['default'], axis=1, inplace=True)

# 前処理後のCSV出力
df.to_csv('bank-additional-cast-comp.csv',sep=';',index=False)
 
#
# 特徴量の選択
#
# 説明変数,目的変数の抽出
X = df.ix[:,0:-1].values
y = df.iloc[:,-1].values
# 学習データとテストデータの分離
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.1, random_state=1)
# ランダムフォレストの作成
forest = RandomForestClassifier(min_samples_leaf=3, random_state=1)
forest.fit(X_train, y_train)

#評価
print('Train score: {}'.format(forest.score(X_train, y_train)))
print('Test score: {}'.format(forest.score(X_test, y_test)))
print('Confusion matrix:\n{}'.format(confusion_matrix(y_test, forest.predict(X_test))))
print('f1 score: {:.3f}'.format(f1_score(y_test, forest.predict(X_test))))

# 説明変数の重要度を表示
values, names = zip(*sorted(zip(forest.feature_importances_, df.columns)))
plt.figure(figsize=(12,12))
plt.barh(range(len(names)), values, align='center')
plt.yticks(range(len(names)), names)

#　学習曲線
pipe_lr = Pipeline([
    ('scl', StandardScaler()),
    ('clf', forest),
])
train_sizes, train_scores, test_scores = learning_curve(
    estimator=pipe_lr,
    X=X_train,
    y=y_train,
    train_sizes=np.linspace(0.1, 1.0, 10),
    cv=10,
    n_jobs=1,
)

train_mean = np.mean(train_scores, axis=1)
train_std = np.std(train_scores, axis=1)
test_mean = np.mean(test_scores, axis=1)
test_std = np.std(test_scores, axis=1)

plt.plot(
    train_sizes,
    train_mean,
    color='blue',
    marker='o',
    markersize=5,
    label='training accuracy',
)
plt.fill_between(
    train_sizes,
    train_mean + train_std,
    train_mean - train_std,
    alpha=0.15,
    color='blue',
)
plt.plot(
    train_sizes,
    test_mean,
    color='green',
    linestyle='--',
    marker='s',
    markersize=5,
    label='validation accuracy',
)
plt.fill_between(
    train_sizes,
    test_mean + test_std,
    test_mean - test_std,
    alpha=0.15,
    color='green',
)

plt.grid()
plt.xlabel('Number of training samples')
plt.ylabel('Accuracy')
plt.legend(loc='lower right')
plt.ylim([0.8, 1.0])
plt.show()


# 検証曲線
"""
param_name: 'clf__'の後に各アルゴリズムで使用するパラメータ名で指定する。
　LogisticRegression - clf__C
 SVM - clf__gamma
 RandomForestClassifier - clf__n_estimators
"""
param_range = [1,5,10,100,1000]
train_scores, test_scores = validation_curve(
    estimator=pipe_lr,
    X=X_train,
    y=y_train,
    param_name='clf__n_estimators',
    param_range=param_range,
    cv=10,
    n_jobs=1,
)

train_mean = np.mean(train_scores, axis=1)
train_std = np.std(train_scores, axis=1)
test_mean = np.mean(test_scores, axis=1)
test_std = np.std(test_scores, axis=1)

plt.plot(
    param_range,
    train_mean,
    color='blue',
    marker='o',
    markersize=5,
    label='training accuracy',
)
plt.fill_between(
    param_range,
    train_mean + train_std,
    train_mean - train_std,
    alpha=0.15,
    color='blue',
)
plt.plot(
    param_range,
    test_mean,
    color='green',
    linestyle='--',
    marker='s',
    markersize=5,
    label='validation accuracy',
)
plt.fill_between(
    param_range,
    test_mean + test_std,
    test_mean - test_std,
    alpha=0.15,
    color='green',
)

plt.grid()
plt.xscale('log')
plt.xlabel('n_estimators')
plt.ylabel('Accuracy')
plt.legend(loc='lower right')
plt.ylim([0.8, 1.0])
plt.show()

#
# グリッドサーチで最適なパラメータの探索
#
"""
 ・n_estimators:木の数(特徴量Nの場合、N^1/2がよい?)
 ・max_features:各決定木で分類に使用する説明変数の数
 ・max_depth：各決定木の深さ
 ・min_samples_leaf:決定木の葉に分類されるサンプル数

  http://ohke.hateblo.jp/entry/2017/08/04/230000
  http://d.hatena.ne.jp/shakezo/20121221/1356089207
"""
# ハイパーパラメータ
forest_grid_param = {
    'n_estimators': [225,250,260],
    'max_features': [1, 'auto', None],
    'max_depth': [1, 5, 10, None],
    'min_samples_leaf': [1, 2, 4,]
}

# スコア方法をF1に設定
f1_scoring = make_scorer(f1_score,  pos_label=1)
# グリッドサーチで学習
forest_grid_search = GridSearchCV(RandomForestClassifier(
        random_state=0, n_jobs=-1), forest_grid_param, 
scoring=f1_scoring, cv=4)
forest_grid_search.fit(X_train, y_train)

# 結果
print('Best parameters: {}'.format(forest_grid_search.best_params_))
print('Best score: {:.3f}'.format(forest_grid_search.best_score_))


#
# 再学習
# 最適パラメータ使って評価
#
best_params = forest_grid_search.best_params_
forest = RandomForestClassifier(random_state=0, n_jobs=1, 
                                max_depth=best_params['max_depth'], 
                                max_features=best_params['max_features'], 
                                min_samples_leaf=best_params['min_samples_leaf'],
                                n_estimators=best_params['n_estimators'])
forest.fit(X_train, y_train)
print('Train score: {:.3f}'.format(forest.score(X_train, y_train)))
print('Test score: {:.3f}'.format(forest.score(X_test, y_test)))
print('Confusion matrix:\n{}'.format(confusion_matrix(y_test, forest.predict(X_test))))
print('f1 score: {:.3f}'.format(f1_score(y_test, forest.predict(X_test))))

# モデル保存
joblib.dump(forest, 'forest.pkl', compress=True) 