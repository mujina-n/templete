FROM centos:6.9

MAINTAINER Taro Toyosu
ENV SUPW apadmin
ARG my_user="apadmin"
ARG my_passwd="apadmin"

# setup EPEL/remi repository
#RUN yum -y install wget
#RUN wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#RUN wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
RUN rpm -iUvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#RUN rpm -iUvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
RUN yum -y update && yum -y upgrade

# setup python
RUN yum -y install centos-release-scl-rh
RUN yum -y install python27
RUN echo 'source /opt/rh/python27/enable' > /etc/profile.d/python27.sh
RUN scl enable python27 bash
RUN yum -y install python-pip python-devel
#RUN easy_install --upgrade pip
RUN pip install numpy pandas sklearn scipy wtforms

# setup Nginx repository
ADD ./nginx/nginx.repo /etc/yum.repos.d/nginx.repo
RUN yum -y update

# setup tools
RUN yum -y groupinstall --enablerepo=epel,remi "Development Tools"
RUN yum -y install --enablerepo=nginx nginx
RUN pip install flask uwsgi==2.0.13.1 # python2.5,2.6 fix version

# create user
RUN yum -y install sudo
RUN useradd -s /bin/bash -m ${my_user}
RUN echo ${my_user}:${my_passwd} | chpasswd

# setup sudo
# OSによって最初から以下のグループが用意されている
# Debian系はsudoグループ
# CentOS系はwheelグループ
RUN usermod -G wheel ${my_user}
RUN echo "%wheel    ALL=(ALL)    NOPASSWD: ALL"        > /etc/sudoers.d/wheel
RUN echo "Defaults:%wheel !requiretty"                 >> /etc/sudoers.d/wheel
RUN echo "Defaults:%wheel env_keep += PATH"            >> /etc/sudoers.d/wheel
RUN echo "Defaults:%wheel env_keep += LD_LIBRARY_PATH" >> /etc/sudoers.d/wheel
RUN echo "Defaults:%wheel env_keep += MANPATH"         >> /etc/sudoers.d/wheel
RUN echo "Defaults:%wheel env_keep += XDG_DATA_DIRS"   >> /etc/sudoers.d/wheel
RUN echo "Defaults:%wheel env_keep += PKG_CONFIG_PATH" >> /etc/sudoers.d/wheel


# setting Nginx
RUN mkdir /etc/nginx/sites-available
ADD ./nginx/nginx.conf /etc/nginx/nginx.conf
ADD ./nginx/uwsgi.conf /etc/nginx/sites-available/uwsgi.conf
RUN ln -s /etc/nginx/sites-available /etc/nginx/sites-enabled

# app dir
RUN mkdir -p /usr/local/app
ADD ./app /usr/local/app/
RUN chown -R ${my_user}.${my_user} /usr/local/app
RUN ln -s /opt/rh/python27/root/usr/lib/python2.7/site-packages/flask /usr/local/flask
#RUN chown -R ${my_user}.${my_user} /usr/local/flask
RUN mkdir -p /var/log/uwsgi
RUN chown -R ${my_user}.${my_user} /var/log/uwsgi
ADD ./flask/uwsgi.ini /usr/local/flask/uwsgi.ini

# exec user 
WORKDIR /home/${my_user}
USER ${my_user}

# run app
ADD ./scripts/service_run.sh /home/${my_user}/service_run.sh
CMD echo ${SUPW} | sudo -S /bin/sh /home/apadmin/service_run.sh
