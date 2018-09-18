import pandas as pd
from sklearn.preprocessing import Imputer


def values_count(feature):
    res = pd.DataFrame()
    for i in (range(len(feature.columns))):
        tmp = pd.DataFrame()
        tmp = feature.iloc[:, [i]]

        list01 = list()
        lis2 = tmp.columns[0]  # カラム名
        lis3 = len(pd.value_counts(tmp.values.flatten()))  # 値の種類数(NAはカウントされない)

        list01 = list([lis2, lis3])
        res1 = pd.DataFrame(list01).T
        res = pd.concat([res, res1], ignore_index=True)

    res.columns = ['name', 'count']
    col_names = list(res.columns)
    res = res.loc[:, col_names]

    return res


def edit(df):

    # 説明変数と目的変数に分割
    label = 'y'
    df_label = pd.DataFrame(df[label])
    df_label[df_label[label] == 'no'] = 0
    df_label[df_label[label] == 'yes'] = 1
    df_feature = df.loc[:, set(df.columns) - set([label])]

    # 数値型とカテゴリ変数に分割
    char_list = ['job', 'marital', 'education', 'default', 'housing', 'loan', 'contact', 'month', 'campaign', 'poutcome']
    df_num = df_feature.loc[:, set(df_feature.columns) - set(char_list)]
    df_char = df_feature.loc[:, char_list]

    # 100種類以上は除去
    summary = values_count(df_char)
    over_items = summary.query('100 < count').reset_index(drop=True)
    df_char = df_char.loc[:, set(df_char.columns) - set(over_items)]

    # ダミー変数化
    edit_char = pd.get_dummies(df_char, drop_first=True)

    return pd.concat([df_num, edit_char, df_label], axis=1)


def nan_comp(df):
    """
    欠損補完
    """
    # 欠損値の補完
    # pdaysは平均値補完
    imp = Imputer(missing_values='NaN', strategy='mean', axis=0)
    imp.fit(df[["pdays"]])
    df["pdays"] = imp.transform(df[["pdays"]]).ravel()

    # 上記以外は最頻値補完
    imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)
    imp.fit(df[["job"]])
    df["job"] = imp.transform(df[["job"]]).ravel()

    imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)
    imp.fit(df[["marital"]])
    df["marital"] = imp.transform(df[["marital"]]).ravel()

    imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)
    imp.fit(df[["education"]])
    df["education"] = imp.transform(df[["education"]]).ravel()

    imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)
    imp.fit(df[["default"]])
    df["default"] = imp.transform(df[["default"]]).ravel()

    imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)
    imp.fit(df[["housing"]])
    df["housing"] = imp.transform(df[["housing"]]).ravel()

    imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)
    imp.fit(df[["loan"]])
    df["loan"] = imp.transform(df[["loan"]]).ravel()
    return df