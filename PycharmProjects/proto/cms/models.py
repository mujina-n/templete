from django.db import models
from datetime import datetime


class FileNameModel(models.Model):
    file_name = models.CharField(max_length=50)
    upload_time = models.DateTimeField(default=datetime.now)

    def __str__(self):
        return self.name


class ResultModel(models.Model):

    exec_time = models.DateTimeField(default=datetime.now)
    input_name = models.CharField(max_length=255)
    model_name = models.CharField(max_length=32)
    param_name = models.CharField(max_length=255)
    rank_file = models.CharField(max_length=50)
    auc = models.FloatField()
    accuracy = models.FloatField()
    precision = models.FloatField()
    recall = models.FloatField()
    f1 = models.FloatField()
    true_negative = models.IntegerField()
    false_positive = models.IntegerField()
    false_negative = models.IntegerField()
    true_positive = models.IntegerField()

    def __str__(self):
        return self.name
