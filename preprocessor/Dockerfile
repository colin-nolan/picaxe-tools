FROM python:3-slim

WORKDIR /usr/local/src/preprocess

COPY requirements.txt ./
RUN pip install -r requirements.txt

COPY preprocess.sh jinja2-wrapper.py ./

ENTRYPOINT ["/usr/local/src/preprocess/preprocess.sh"]
