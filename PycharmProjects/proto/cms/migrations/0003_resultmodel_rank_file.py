# Generated by Django 2.1.1 on 2018-09-18 02:25

from django.db import migrations, models
import django.utils.timezone


class Migration(migrations.Migration):

    dependencies = [
        ('cms', '0002_resultmodel'),
    ]

    operations = [
        migrations.AddField(
            model_name='resultmodel',
            name='rank_file',
            field=models.CharField(max_length=50),
            preserve_default=False,
        ),
    ]