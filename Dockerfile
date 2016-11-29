FROM centos:7

RUN rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro \
	&& rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-1.el7.nux.noarch.rpm

RUN yum -y update \
        && yum -y install epel-release \
        && yum -y install python-devel \
        && yum -y install python-pip \
        && yum -y install netcdf4-python \
        && yum -y install gcc-c++ \
	&& yum -y install ffmpeg \
	&& yum -y install subversion

RUN mkdir -m 775 /data
ADD requirements.txt /data/requirements.txt
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r /data/requirements.txt

RUN mkdir -p /root/.config/matplotlib \
   && echo "backend : Agg" > /root/.config/matplotlib/matplotlibrc

