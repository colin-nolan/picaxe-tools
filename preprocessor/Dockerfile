FROM python:3

RUN pip install 'jinja2<3,>=2'

WORKDIR /usr/local/src/preprocess

ADD preprocess.sh jinja2_wrapper.py ./

ENTRYPOINT ["/usr/local/src/preprocess/preprocess.sh"]
