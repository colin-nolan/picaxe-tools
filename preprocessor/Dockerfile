FROM python:3

WORKDIR /usr/local/src/preprocess

ADD requirements.txt ./
RUN pip install -r requirements.txt

ADD preprocess.sh jinja2-wrapper.py ./

ENTRYPOINT ["/usr/local/src/preprocess/preprocess.sh"]
