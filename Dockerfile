FROM continuumio/anaconda:5.3.0

RUN mkdir -m 775 /data
ADD requirements.txt /data/requirements.txt
RUN conda install --yes -c conda-forge --file /data/requirements.txt

RUN mkdir -p /root/.config/matplotlib \
   && echo "backend : Agg" > /root/.config/matplotlib/matplotlibrc

