FROM public.ecr.aws/lambda/python:3.12

RUN pip install poetry
# Install Poetry
#RUN pip install --upgrade pip && \
#    pip install poetry

COPY . ${LAMBDA_TASK_ROOT}

WORKDIR ${LAMBDA_TASK_ROOT}/backend

RUN pip3 install wheel --target "${LAMBDA_TASK_ROOT}"

RUN poetry export --without-hashes -o requirements.txt

RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

CMD ["start.handler"]
