from django.urls import path
from django.conf.urls import url
from cms import views


app_name = 'cms'
urlpatterns = [
    url(r'^$', views.UploadList.as_view(), name='upload_list'),
    path('upload_list/', views.UploadList.as_view(), name='upload_list'),
    path('upload_add/', views.upload_add, name='upload_add'),
    path('upload_del/<int:file_id>/', views.upload_del, name='upload_del'),
    path('predict/<int:file_id>/', views.predict, name='predict'),
    path('result_list/', views.ResultList.as_view(), name='result_list'),
    path('result_del/<int:result_id>/', views.result_del, name='result_del'),
    path('download/<int:pk>/', views.download, name='download'),
    #path('cms/edit_join/<int:file_id>/', views.edit_join, name='edit_join'),
]