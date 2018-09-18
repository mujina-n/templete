from django.contrib import admin

from cms.models import FileNameModel, ResultModel


class FileNameAdmin(admin.ModelAdmin):
    list_display = ('id', 'file_name', 'upload_time')
    list_display_links = ('id', 'file_name')


class ResultAdmin(admin.ModelAdmin):
    list_display = ('id', 'exec_time', 'input_name', 'model_name', 'param_name', 'rank_file',
                    'auc', 'accuracy', 'precision', 'recall', 'f1',
                    'true_negative', 'false_positive', 'false_negative', 'true_positive')
    list_display_links = ('id', 'exec_time')


admin.site.register(FileNameModel, FileNameAdmin)
admin.site.register(ResultModel, ResultAdmin)